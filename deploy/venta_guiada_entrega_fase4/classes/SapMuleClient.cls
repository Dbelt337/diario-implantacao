/**
 * All countries. FACHADA ÚNICA de los servicios SAP del ciclo cotizar/pedido
 * (doc del equipo SAP, sesión 22/07) detrás del gateway MuleSoft. Un método
 * por RFC/IDoc, TODOS construidos y MOCKEADOS: mockMode=true devuelve
 * respuestas deterministas para que la suite funcione de punta a punta sin
 * SAP; cuando el contrato Experience API cierre con integración (Flavio),
 * mockMode=false enruta cada método a su endpoint del Named Credential
 * MuleGateway — las firmas y DTOs NO cambian.
 *
 * MAPA RFC -> MÉTODO -> ENDPOINT (rutas = PROPUESTA de contrato con Mule):
 *  VEHÍCULOS (familia ZQEV, ciclo Z301 -> Z300):
 *   ZQEV_ASIG_CLIENTE        -> asigCliente()          POST /api/v1/customers/assignment
 *   ZQEV_MONEDA_CLIENTE      -> monedaCliente()        POST /api/v1/customers/currency
 *   ZQEV_SSA_CREA_ORD_VEH    -> crearOrdenVehiculo()   POST /api/v1/orders           (Z301 = oferta/reserva; payload lleva CENTRO)
 *   ZQEV_SSA_MOD_ORD_VEH     -> modificarOrdenVehiculo() PATCH /api/v1/orders/{doc}
 *   ZQEV_SSA_COPIA_ORD_VEH   -> copiarOrdenVehiculo()  POST /api/v1/orders/{doc}/copy (Z301 -> Z300)
 *  PA (SD standard):
 *   ZHYB_SD_PARAM_CLIENTE    -> paramCliente()         POST /api/v1/customers/params
 *   cod_salesorder_simulate  -> simulateSalesOrder()   POST /api/v1/orders/simulate  (SÍNCRONO: el precio lo calcula el SD; SF exhibe y CONGELA)
 *  REPUESTOS (DBM):
 *   ZHYB/ZQEV CONSULTA_MATERIALES (modo MASIVO) -> consultaMateriales() POST /api/v1/materials/query
 *     (saldo = TDET_SALDOS = PISO - RESERVA, PUEDE SER NEGATIVO — se devuelve tal cual)
 *   ZHYB_DBM_TEXTO_EXISTENCIA_RFC -> incluido en consultaMateriales() (campo textoExistencia)
 *   ZHYB_DBM_COTIZA_REP_RFC  -> cotizarRepuestos()     POST /api/v1/parts-quotes
 *   ZHYB_DBM_MOD_DET_ORDEN / ZHYB_DBMPOSICIONES -> modificarPosicionesOrden() PATCH /api/v1/parts-orders/{doc}/lines
 *   ZHYB_DBM_DESCUENTO_DE_VENDEDOR -> descuentoVendedor() GET /api/v1/seller-discounts (cadencia scheduler vs por pedido = decisión ABIERTA)
 *  Los IDocs de retorno (réplica de orden, confirmación, factura) NO viven
 *  aquí: entran por SapOrderResponse__e (Mule publica) y por update inbound
 *  del pedido (factura) — flows SAP_Order_Response_Handler / Order_Facturado_Handler.
 */
public with sharing class SapMuleClient {

    /** true = respuestas deterministas sin callout (contrato Mule pendiente). */
    @TestVisible public static Boolean mockMode = true;

    private static final String BASE = 'callout:MuleGateway';
    private static final Integer TIMEOUT_MILLIS = 60000;

    // ---------- VEHÍCULOS (ZQEV) ----------

    /** ZQEV_ASIG_CLIENTE — pre-requisito obligatorio antes de cualquier orden. */
    public static Ack asigCliente(String customerCode, String companyCode) {
        if (mockMode) {
            Ack a = new Ack(); a.ok = true; a.message = 'MOCK: cliente ' + customerCode + ' asignado en ' + companyCode;
            return a;
        }
        return (Ack) send('POST', '/api/v1/customers/assignment',
            new Map<String, Object>{ 'customerCode' => customerCode, 'companyCode' => companyCode }, Ack.class);
    }

    /** ZQEV_MONEDA_CLIENTE — pre-requisito obligatorio (moneda del cliente). */
    public static CurrencyResult monedaCliente(String customerCode, String companyCode) {
        if (mockMode) {
            CurrencyResult r = new CurrencyResult(); r.ok = true; r.currencyIsoCode = 'CRC';
            return r;
        }
        return (CurrencyResult) send('POST', '/api/v1/customers/currency',
            new Map<String, Object>{ 'customerCode' => customerCode, 'companyCode' => companyCode }, CurrencyResult.class);
    }

    /** ZQEV_SSA_CREA_ORD_VEH — crea la Z301 (oferta/reserva). El payload lleva CENTRO (WERKS), no almacén. */
    public static OrderDocResult crearOrdenVehiculo(OrderDocRequest req) {
        if (mockMode) {
            OrderDocResult r = new OrderDocResult();
            r.ok = true; r.docType = 'Z301'; r.sapDocNumber = 'Z301-' + (String.isBlank(req.reference) ? 'MOCK' : req.reference);
            r.message = 'MOCK: oferta/reserva creada';
            return r;
        }
        return (OrderDocResult) send('POST', '/api/v1/orders', req, OrderDocResult.class);
    }

    /** ZQEV_SSA_MOD_ORD_VEH — modifica Z301/Z300. */
    public static OrderDocResult modificarOrdenVehiculo(String sapDocNumber, OrderDocRequest req) {
        if (mockMode) {
            OrderDocResult r = new OrderDocResult();
            r.ok = true; r.sapDocNumber = sapDocNumber; r.message = 'MOCK: documento modificado';
            return r;
        }
        return (OrderDocResult) send('PATCH', '/api/v1/orders/' + sapDocNumber, req, OrderDocResult.class);
    }

    /** ZQEV_SSA_COPIA_ORD_VEH — copia Z301 -> Z300 (pedido de venta, cierre). */
    public static OrderDocResult copiarOrdenVehiculo(String z301Number) {
        if (mockMode) {
            OrderDocResult r = new OrderDocResult();
            r.ok = true; r.docType = 'Z300';
            r.sapDocNumber = z301Number == null ? 'Z300-MOCK' : z301Number.replace('Z301', 'Z300');
            r.message = 'MOCK: pedido de venta creado por copia';
            return r;
        }
        return (OrderDocResult) send('POST', '/api/v1/orders/' + z301Number + '/copy', null, OrderDocResult.class);
    }

    // ---------- PA (SD standard) ----------

    /** ZHYB_SD_PARAM_CLIENTE — parámetros del cliente pre-pedido. */
    public static ClientParams paramCliente(String customerCode, String companyCode) {
        if (mockMode) {
            ClientParams p = new ClientParams(); p.ok = true; p.paymentTerms = 'CONTADO'; p.channel = 'PA';
            return p;
        }
        return (ClientParams) send('POST', '/api/v1/customers/params',
            new Map<String, Object>{ 'customerCode' => customerCode, 'companyCode' => companyCode }, ClientParams.class);
    }

    /**
     * cod_salesorder_simulate (SOAP síncrono detrás de Mule) — el SD calcula
     * impuestos/descuentos/redondeo; SF EXHIBE Y CONGELA, nunca recalcula.
     * Mock: total = suma de líneas + IVA 13% (CR) para que la UI tenga cifras.
     */
    public static SimulationResult simulateSalesOrder(SimulationRequest req) {
        if (mockMode) {
            SimulationResult r = new SimulationResult();
            r.ok = true; r.currencyIsoCode = req.currencyIsoCode;
            Decimal neto = 0;
            if (req.lines != null) {
                for (SimulationLine l : req.lines) {
                    Decimal qty = l.quantity == null ? 1 : l.quantity;
                    neto += (l.unitPrice == null ? 0 : l.unitPrice) * qty;
                }
            }
            r.netAmount = neto;
            r.taxAmount = (neto * 0.13).setScale(2, RoundingMode.HALF_UP);
            r.totalAmount = neto + r.taxAmount;
            return r;
        }
        return (SimulationResult) send('POST', '/api/v1/orders/simulate', req, SimulationResult.class);
    }

    // ---------- REPUESTOS (DBM) ----------

    /**
     * CONSULTA_MATERIALES (modo MASIVO — HU-047 RN-18) + TEXTO_EXISTENCIA.
     * saldoDisponible = TDET_SALDOS = PISO - RESERVA; PUEDE SER NEGATIVO y se
     * devuelve tal cual (la exhibición del negativo es decisión de la HU-047).
     */
    public static List<MaterialSaldo> consultaMateriales(List<String> codigos, String companyCode, String plant) {
        List<MaterialSaldo> saldos = new List<MaterialSaldo>();
        if (mockMode) {
            Integer i = 0;
            for (String codigo : codigos == null ? new List<String>() : codigos) {
                MaterialSaldo m = new MaterialSaldo();
                m.productCode = codigo;
                m.name = 'Material ' + codigo;
                m.piso = 10 - i;            // determinista: decrece por posición
                m.reserva = 2 * i;          // ... y la reserva crece
                m.saldoDisponible = m.piso - m.reserva; // negativo a partir del 4º
                m.textoExistencia = m.saldoDisponible > 0
                    ? 'MOCK: disponible en ' + (plant == null ? 'centro' : plant)
                    : 'MOCK: sin saldo — piso comprometido por reservas';
                saldos.add(m);
                i++;
            }
            return saldos;
        }
        String body = JSON.serialize(new Map<String, Object>{
            'productCodes' => codigos, 'companyCode' => companyCode, 'plant' => plant, 'massive' => true });
        HttpResponse res = rawSend('POST', '/api/v1/materials/query', body);
        return (List<MaterialSaldo>) JSON.deserialize(res.getBody(), List<MaterialSaldo>.class);
    }

    /** ZHYB_DBM_COTIZA_REP_RFC — cotización de repuestos en el DBM. */
    public static RepQuoteResult cotizarRepuestos(RepQuoteRequest req) {
        if (mockMode) {
            RepQuoteResult r = new RepQuoteResult();
            r.ok = true; r.sapQuoteNumber = 'DBMCOT-' + (String.isBlank(req.reference) ? 'MOCK' : req.reference);
            Decimal total = 0;
            if (req.lines != null) {
                for (SimulationLine l : req.lines) {
                    total += (l.unitPrice == null ? 0 : l.unitPrice) * (l.quantity == null ? 1 : l.quantity);
                }
            }
            r.totalAmount = total;
            return r;
        }
        return (RepQuoteResult) send('POST', '/api/v1/parts-quotes', req, RepQuoteResult.class);
    }

    /** ZHYB_DBM_MOD_DET_ORDEN / ZHYB_DBMPOSICIONES — posiciones de la orden DBM. */
    public static Ack modificarPosicionesOrden(String sapDocNumber, List<SimulationLine> lines) {
        if (mockMode) {
            Ack a = new Ack(); a.ok = true; a.message = 'MOCK: posiciones actualizadas en ' + sapDocNumber;
            return a;
        }
        return (Ack) send('PATCH', '/api/v1/parts-orders/' + sapDocNumber + '/lines',
            new Map<String, Object>{ 'lines' => lines }, Ack.class);
    }

    /** ZHYB_DBM_DESCUENTO_DE_VENDEDOR — tope de descuento del vendedor (cadencia: decisión abierta). */
    public static DiscountResult descuentoVendedor(String sellerCode) {
        if (mockMode) {
            DiscountResult d = new DiscountResult(); d.ok = true; d.maxDiscountPercent = 5;
            return d;
        }
        return (DiscountResult) send('GET', '/api/v1/seller-discounts?sellerCode=' + EncodingUtil.urlEncode(sellerCode == null ? '' : sellerCode, 'UTF-8'), null, DiscountResult.class);
    }

    // ---------- transporte ----------

    private static Object send(String method, String path, Object body, Type resultType) {
        HttpResponse res = rawSend(method, path, body == null ? null : JSON.serialize(body));
        return JSON.deserialize(res.getBody(), resultType);
    }

    private static HttpResponse rawSend(String method, String path, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE + path);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MILLIS);
        req.setHeader('Content-Type', 'application/json');
        if (body != null) {
            req.setBody(body);
        }
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new SapMuleClientException('HTTP ' + res.getStatusCode() + ' en ' + path);
        }
        return res;
    }

    // ---------- DTOs (contrato con Mule; los nombres NO cambian al salir del mock) ----------

    public class Ack { @AuraEnabled public Boolean ok; @AuraEnabled public String message; }

    public class CurrencyResult { @AuraEnabled public Boolean ok; @AuraEnabled public String currencyIsoCode; }

    public class ClientParams {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String paymentTerms;
        @AuraEnabled public String channel;
    }

    public class OrderDocRequest {
        @AuraEnabled public String reference;        // OrderNumber SF (correlación)
        @AuraEnabled public String customerCode;
        @AuraEnabled public String companyCode;      // sociedad C101/C105
        @AuraEnabled public String plant;            // CENTRO (WERKS) — lo que pide la interfaz de reserva
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public List<SimulationLine> lines;
    }

    public class OrderDocResult {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String docType;          // Z301 | Z300
        @AuraEnabled public String sapDocNumber;
        @AuraEnabled public String message;
    }

    public class SimulationRequest {
        @AuraEnabled public String customerCode;
        @AuraEnabled public String companyCode;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public List<SimulationLine> lines;
    }

    public class SimulationLine {
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal unitPrice;
    }

    public class SimulationResult {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public Decimal netAmount;
        @AuraEnabled public Decimal taxAmount;
        @AuraEnabled public Decimal totalAmount;
    }

    public class MaterialSaldo {
        @AuraEnabled public String productCode;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal piso;
        @AuraEnabled public Decimal reserva;
        @AuraEnabled public Decimal saldoDisponible;  // PISO - RESERVA, puede ser negativo
        @AuraEnabled public String textoExistencia;
    }

    public class RepQuoteRequest {
        @AuraEnabled public String reference;
        @AuraEnabled public String customerCode;
        @AuraEnabled public String companyCode;
        @AuraEnabled public List<SimulationLine> lines;
    }

    public class RepQuoteResult {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String sapQuoteNumber;
        @AuraEnabled public Decimal totalAmount;
    }

    public class DiscountResult { @AuraEnabled public Boolean ok; @AuraEnabled public Decimal maxDiscountPercent; }

    public class SapMuleClientException extends Exception {}
}
