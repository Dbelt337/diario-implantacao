/**
 * All countries. HU-043 (Repuestos & PA): selección, carga masiva y
 * modificación dinámica de líneas de material con verificación de
 * disponibilidad contra SAP vía MuleSoft (CONSULTA_MATERIALES masivo,
 * SapMuleClient — una sola llamada por lote, RN-18). SAP es el maestro del
 * inventario: esta clase consulta y refleja, nunca calcula stock.
 *
 * Decisiones de diseño (planilla HU-043):
 *  - Estado por línea en QuoteLineItem.AvailabilityStatus__c (+ detalle en
 *    AvailabilityDetail__c): Disponible / Parcial / Otro Centro /
 *    Otra Sociedad / No Disponible.
 *  - Venta Perdida NO genera línea: queda trazada en la Description de la
 *    cotización (el modelo completo de Venta Perdida vive en US-040/US-057;
 *    aquí solo se marca/deriva, como delimita la HU). Así el pedido generado
 *    desde la cotización nunca arrastra líneas perdidas.
 *  - Kits/combos (GQ-PV-02-029): expansión vía ProductRelatedComponent
 *    resuelta DINÁMICAMENTE (el paquete no depende del objeto; si la org no
 *    lo tiene habilitado, los kits se tratan como líneas simples).
 *  - Material sin entrada de catálogo local: se devuelve marcado
 *    sinCatalogo=true y NO se guarda (la creación de código es US-021).
 */
public with sharing class RepuestosLineService {

    private static final String STATUS_DISPONIBLE    = 'Disponible';
    private static final String STATUS_PARCIAL       = 'Parcial';
    private static final String STATUS_OTRO_CENTRO   = 'Otro Centro';
    private static final String STATUS_OTRA_SOCIEDAD = 'Otra Sociedad';
    private static final String STATUS_NO_DISPONIBLE = 'No Disponible';

    /**
     * Verifica disponibilidad de un lote de líneas (GQ-PV-03-028/03-023).
     * Una sola llamada masiva a SAP; enriquece con el catálogo local
     * (Product2/PricebookEntry por ProductCode) para precio y guardado.
     * @param requestJson {companyCode, plant, pricebookId, currencyIsoCode,
     *                     lineas:[{productCode, cantidad}]}
     * @return líneas con piso/reserva/saldo, leyenda, estado y datos de catálogo
     */
    public static List<LineaResult> consultarDisponibilidad(String requestJson) {
        ConsultaRequest req = parseRequest(requestJson);

        List<String> codigos = new List<String>();
        for (LineaInput l : req.lineas) {
            if (String.isNotBlank(l.productCode)) {
                codigos.add(l.productCode.trim());
            }
        }
        if (codigos.isEmpty()) {
            return new List<LineaResult>();
        }

        // catalogo local por codigo (precio de la lista de la cotizacion)
        Map<String, PricebookEntry> pbePorCodigo = catalogoPorCodigo(codigos, req.pricebookId, req.currencyIsoCode);

        // UNA llamada masiva (RN-18); los kits expanden antes de consultar.
        // Lista ORDENADA (no Set): el orden de las posiciones se preserva
        // en la consulta a SAP
        Map<String, List<Componente>> kits = expandirKits(codigos);
        List<String> codigosConsulta = new List<String>();
        Set<String> vistos = new Set<String>();
        for (String code : codigos) {
            if (vistos.add(code)) { codigosConsulta.add(code); }
        }
        for (List<Componente> comps : kits.values()) {
            for (Componente c : comps) {
                if (vistos.add(c.productCode)) { codigosConsulta.add(c.productCode); }
            }
        }
        Map<String, SapMuleClient.MaterialSaldo> saldoPorCodigo = new Map<String, SapMuleClient.MaterialSaldo>();
        for (SapMuleClient.MaterialSaldo m : SapMuleClient.consultaMateriales(
                codigosConsulta, req.companyCode, req.plant)) {
            saldoPorCodigo.put(m.productCode, m);
        }

        List<LineaResult> results = new List<LineaResult>();
        for (LineaInput l : req.lineas) {
            String code = l.productCode == null ? '' : l.productCode.trim();
            LineaResult r = buildResult(code, l.cantidad, saldoPorCodigo.get(code), pbePorCodigo.get(code));
            if (kits.containsKey(code)) {
                r.esKit = true;
                r.componentes = new List<LineaResult>();
                for (Componente c : kits.get(code)) {
                    Decimal cantComp = (l.cantidad == null ? 1 : l.cantidad) * (c.cantidad == null ? 1 : c.cantidad);
                    r.componentes.add(buildResult(c.productCode, cantComp,
                        saldoPorCodigo.get(c.productCode), pbePorCodigo.get(c.productCode)));
                }
            }
            results.add(r);
        }
        return results;
    }

    /**
     * Sincroniza las líneas de la cotización con lo decidido por el asesor
     * (GQ-PV-02-023-1 / 02-019): crea, actualiza y elimina QuoteLineItems.
     * Las líneas marcadas ventaPerdida no generan línea: quedan trazadas en
     * la Description. Devuelve el resumen de lo aplicado.
     * @param quoteId cotización de Repuestos & PA en elaboración
     * @param lineasJson [{productCode, cantidad, status, detalle, ventaPerdida}]
     */
    public static GuardarResult guardarLineas(Id quoteId, String lineasJson) {
        if (quoteId == null) {
            throw new RepuestosLineServiceException('QuoteId es requerido.');
        }
        List<LineaInput> lineas = (List<LineaInput>) JSON.deserialize(
            lineasJson == null ? '[]' : lineasJson, List<LineaInput>.class);

        // LOCK (FOR UPDATE): dos asesores guardando la MISMA cotización se
        // serializan — sin el lock, el sync crear/actualizar/eliminar de
        // abajo se intercala y pierde líneas (race de lectura+escritura)
        List<Quote> bloqueo = [SELECT Id FROM Quote WHERE Id = :quoteId FOR UPDATE];

        List<Quote> quotes = [
            SELECT Id, Description, Pricebook2Id, CurrencyIsoCode,
                   (SELECT Id, Quantity, UnitPrice, Product2.ProductCode FROM QuoteLineItems)
            FROM Quote WHERE Id = :quoteId WITH USER_MODE
        ];
        if (quotes.isEmpty()) {
            throw new RepuestosLineServiceException('No se encontró la cotización.');
        }
        Quote cotizacion = quotes[0];

        Map<String, LineaInput> porCodigo = new Map<String, LineaInput>();
        List<String> codigos = new List<String>();
        for (LineaInput l : lineas) {
            if (String.isNotBlank(l.productCode)) {
                String code = l.productCode.trim();
                porCodigo.put(code, l);
                codigos.add(code);
            }
        }
        Map<String, PricebookEntry> pbePorCodigo = catalogoPorCodigo(
            codigos, cotizacion.Pricebook2Id, cotizacion.CurrencyIsoCode);

        GuardarResult resultado = new GuardarResult();
        Map<String, QuoteLineItem> existentesPorCodigo = new Map<String, QuoteLineItem>();
        for (QuoteLineItem qli : cotizacion.QuoteLineItems) {
            existentesPorCodigo.put(qli.Product2.ProductCode, qli);
        }

        List<QuoteLineItem> paraInsertar = new List<QuoteLineItem>();
        List<QuoteLineItem> paraActualizar = new List<QuoteLineItem>();
        List<QuoteLineItem> paraBorrar = new List<QuoteLineItem>();
        List<String> trazasPerdida = new List<String>();

        for (String code : porCodigo.keySet()) {
            LineaInput l = porCodigo.get(code);
            QuoteLineItem existente = existentesPorCodigo.get(code);

            if (l.ventaPerdida == true) {
                // se marca/deriva; el registro completo es US-040/US-057
                trazasPerdida.add('[Venta Perdida] ' + code + ' x' + fmt(l.cantidad)
                    + (String.isBlank(l.detalle) ? '' : ' — ' + l.detalle));
                if (existente != null) {
                    paraBorrar.add(existente);
                }
                resultado.ventasPerdidas++;
                continue;
            }

            PricebookEntry pbe = pbePorCodigo.get(code);
            if (pbe == null) {
                // sin catalogo local: no se puede crear la linea (US-021)
                resultado.sinCatalogo.add(code);
                continue;
            }
            if (existente == null) {
                paraInsertar.add(new QuoteLineItem(
                    QuoteId = cotizacion.Id,
                    PricebookEntryId = pbe.Id,
                    Product2Id = pbe.Product2Id,
                    Quantity = l.cantidad == null || l.cantidad <= 0 ? 1 : l.cantidad,
                    UnitPrice = pbe.UnitPrice,
                    AvailabilityStatus__c = l.status,
                    AvailabilityDetail__c = trunc(l.detalle)
                ));
                resultado.creadas++;
            } else {
                existente.Quantity = l.cantidad == null || l.cantidad <= 0 ? 1 : l.cantidad;
                existente.AvailabilityStatus__c = l.status;
                existente.AvailabilityDetail__c = trunc(l.detalle);
                paraActualizar.add(existente);
                resultado.actualizadas++;
            }
        }
        // modificacion dinamica: lo que salio de la seleccion se elimina
        for (String code : existentesPorCodigo.keySet()) {
            if (!porCodigo.containsKey(code)) {
                paraBorrar.add(existentesPorCodigo.get(code));
                resultado.eliminadas++;
            }
        }

        if (!paraInsertar.isEmpty()) { insert paraInsertar; }
        if (!paraActualizar.isEmpty()) { update paraActualizar; }
        if (!paraBorrar.isEmpty()) { delete paraBorrar; }

        if (!trazasPerdida.isEmpty()) {
            String bloque = String.join(trazasPerdida, '\n');
            String descripcion = cotizacion.Description == null ? '' : cotizacion.Description + '\n';
            update new Quote(Id = cotizacion.Id, Description = (descripcion + bloque).abbreviate(32000));
        }
        return resultado;
    }

    /**
     * Revalida la disponibilidad de TODAS las líneas vigentes de la
     * cotización (GQ-PV-02-019: agregar/quitar/cambiar, incluso en fecha
     * posterior) y actualiza estado y detalle en cada línea.
     */
    public static List<LineaResult> revalidarLineas(Id quoteId, String companyCode, String plant) {
        if (quoteId == null) {
            throw new RepuestosLineServiceException('QuoteId es requerido.');
        }
        List<QuoteLineItem> qlis = [
            SELECT Id, Quantity, Product2.ProductCode, Product2.Name
            FROM QuoteLineItem WHERE QuoteId = :quoteId WITH USER_MODE
        ];
        if (qlis.isEmpty()) {
            return new List<LineaResult>();
        }
        List<String> codigos = new List<String>();
        for (QuoteLineItem qli : qlis) {
            codigos.add(qli.Product2.ProductCode);
        }
        Map<String, SapMuleClient.MaterialSaldo> saldoPorCodigo = new Map<String, SapMuleClient.MaterialSaldo>();
        for (SapMuleClient.MaterialSaldo m : SapMuleClient.consultaMateriales(codigos, companyCode, plant)) {
            saldoPorCodigo.put(m.productCode, m);
        }

        List<LineaResult> results = new List<LineaResult>();
        List<QuoteLineItem> paraActualizar = new List<QuoteLineItem>();
        for (QuoteLineItem qli : qlis) {
            LineaResult r = buildResult(qli.Product2.ProductCode, qli.Quantity,
                saldoPorCodigo.get(qli.Product2.ProductCode), null);
            r.name = qli.Product2.Name;
            results.add(r);
            paraActualizar.add(new QuoteLineItem(
                Id = qli.Id,
                AvailabilityStatus__c = r.status,
                AvailabilityDetail__c = trunc(r.textoExistencia)
            ));
        }
        update paraActualizar;
        return results;
    }

    // ---------- helpers ----------

    private static ConsultaRequest parseRequest(String requestJson) {
        if (String.isBlank(requestJson)) {
            throw new RepuestosLineServiceException('Request de disponibilidad vacío.');
        }
        ConsultaRequest req;
        try {
            req = (ConsultaRequest) JSON.deserialize(requestJson, ConsultaRequest.class);
        } catch (Exception e) {
            throw new RepuestosLineServiceException('Request de disponibilidad ilegible: ' + e.getMessage());
        }
        if (req == null || req.lineas == null) {
            throw new RepuestosLineServiceException('Request sin líneas.');
        }
        return req;
    }

    /** Estado por línea a partir del saldo informado por SAP y la leyenda. */
    @TestVisible
    private static String derivarStatus(Decimal cantidad, SapMuleClient.MaterialSaldo saldo) {
        if (saldo == null || saldo.saldoDisponible == null) {
            return STATUS_NO_DISPONIBLE;
        }
        Decimal pedida = cantidad == null || cantidad <= 0 ? 1 : cantidad;
        if (saldo.saldoDisponible >= pedida) {
            return STATUS_DISPONIBLE;
        }
        if (saldo.saldoDisponible > 0) {
            return STATUS_PARCIAL;
        }
        String texto = saldo.textoExistencia == null ? '' : saldo.textoExistencia.toLowerCase();
        if (texto.contains('otro centro')) { return STATUS_OTRO_CENTRO; }
        if (texto.contains('otra sociedad')) { return STATUS_OTRA_SOCIEDAD; }
        return STATUS_NO_DISPONIBLE;
    }

    private static LineaResult buildResult(String code, Decimal cantidad,
            SapMuleClient.MaterialSaldo saldo, PricebookEntry pbe) {
        LineaResult r = new LineaResult();
        r.productCode = code;
        r.cantidad = cantidad == null || cantidad <= 0 ? 1 : cantidad;
        if (saldo != null) {
            r.name = saldo.name;
            r.piso = saldo.piso;
            r.reserva = saldo.reserva;
            r.saldoDisponible = saldo.saldoDisponible;
            r.textoExistencia = saldo.textoExistencia;
        }
        r.status = derivarStatus(cantidad, saldo);
        if (pbe != null) {
            r.productId = pbe.Product2Id;
            r.pricebookEntryId = pbe.Id;
            r.unitPrice = pbe.UnitPrice;
            if (r.name == null) { r.name = pbe.Product2.Name; }
        } else {
            r.sinCatalogo = true;
        }
        return r;
    }

    private static Map<String, PricebookEntry> catalogoPorCodigo(List<String> codigos, Id pricebookId, String currencyIsoCode) {
        Map<String, PricebookEntry> porCodigo = new Map<String, PricebookEntry>();
        if (codigos.isEmpty() || pricebookId == null) {
            return porCodigo;
        }
        for (PricebookEntry pbe : [
                SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebookId AND IsActive = true
                  AND CurrencyIsoCode = :currencyIsoCode
                  AND Product2.ProductCode IN :codigos
                WITH USER_MODE]) {
            porCodigo.put(pbe.Product2.ProductCode, pbe);
        }
        return porCodigo;
    }

    /**
     * Kits/combos por ProductRelatedComponent, resuelto en dinámico: si el
     * objeto no está habilitado en la org, devuelve vacío y las líneas se
     * tratan como simples (el paquete no depende del feature).
     */
    @TestVisible
    private static Map<String, List<Componente>> expandirKits(List<String> codigos) {
        Map<String, List<Componente>> kits = new Map<String, List<Componente>>();
        if (!Schema.getGlobalDescribe().containsKey('ProductRelatedComponent')) {
            return kits;
        }
        try {
            for (SObject rec : Database.query(
                    'SELECT ParentProduct.ProductCode, ChildProduct.ProductCode, Quantity '
                    + 'FROM ProductRelatedComponent '
                    + 'WHERE ParentProduct.ProductCode IN :codigos')) {
                SObject parent = rec.getSObject('ParentProduct');
                SObject child = rec.getSObject('ChildProduct');
                if (parent == null || child == null) { continue; }
                String parentCode = (String) parent.get('ProductCode');
                Componente c = new Componente();
                c.productCode = (String) child.get('ProductCode');
                c.cantidad = (Decimal) rec.get('Quantity');
                if (!kits.containsKey(parentCode)) {
                    kits.put(parentCode, new List<Componente>());
                }
                kits.get(parentCode).add(c);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Kits no expandidos (feature no disponible): ' + e.getMessage());
            kits.clear();
        }
        return kits;
    }

    private static String trunc(String s) {
        return s == null ? null : s.abbreviate(255);
    }

    private static String fmt(Decimal d) {
        return d == null ? '1' : String.valueOf(d);
    }

    // ---------- DTOs ----------

    public class ConsultaRequest {
        @AuraEnabled public String companyCode;
        @AuraEnabled public String plant;
        @AuraEnabled public Id pricebookId;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public List<LineaInput> lineas;
    }

    public class LineaInput {
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal cantidad;
        @AuraEnabled public String status;
        @AuraEnabled public String detalle;
        @AuraEnabled public Boolean ventaPerdida;
    }

    public class Componente {
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal cantidad;
    }

    public class LineaResult {
        @AuraEnabled public String productCode;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal cantidad;
        @AuraEnabled public Decimal piso;
        @AuraEnabled public Decimal reserva;
        @AuraEnabled public Decimal saldoDisponible;
        @AuraEnabled public String textoExistencia;
        @AuraEnabled public String status;
        @AuraEnabled public Id productId;
        @AuraEnabled public Id pricebookEntryId;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Boolean sinCatalogo = false;
        @AuraEnabled public Boolean esKit = false;
        @AuraEnabled public List<LineaResult> componentes;
    }

    public class GuardarResult {
        @AuraEnabled public Integer creadas = 0;
        @AuraEnabled public Integer actualizadas = 0;
        @AuraEnabled public Integer eliminadas = 0;
        @AuraEnabled public Integer ventasPerdidas = 0;
        @AuraEnabled public List<String> sinCatalogo = new List<String>();
    }

    public class RepuestosLineServiceException extends Exception {}
}
