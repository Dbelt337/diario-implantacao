/**
 * All countries. Creates quotations and orders on the native model
 * (Quote and Order Capture, Standalone Orders) according to the Record Type
 * of the business line (Venta Vehículo / Contraventa Repuestos / PA / Usados).
 * Bulkified DML; no SOQL or DML inside loops. Order lifecycle: Borrador ->
 * Enviado a SAP -> Confirmado SAP -> Facturado (assetization only on Facturado).
 */
public with sharing class QuoteOrderService {

    //future developement note: flow changed -> only a single quote will be created here and by using the interface the user must create a new quote and follow the same process for each vehicle (one quote per vehicle
    public static List<Quote> createQuotesSingleVehicle(Id opportunityId, String quotePayloadJson, String selectedVehicles) {

        if (opportunityId == null) {
            throw new QuoteOrderServiceException('OpportunityId is required.');
        }

        QuotePayload payload = parsePayload(quotePayloadJson);

        //Query Opportunity + OpportunityLineItems
        Opportunity[] opps = [
            SELECT Id, Name, AccountId, Pricebook2Id, CurrencyIsoCode
            FROM Opportunity
            WHERE Id = :opportunityId
        ];

        if (opps.isEmpty()) {
            throw new QuoteOrderServiceException('No se encontraron oportunidades');
        }

        Opportunity opp = opps[0];

        if (opp.Pricebook2Id == null) {
            // TODO: resolve by sociedad map (pending catalog decision with GrupoQ)
            opp.Pricebook2Id = resolveDefaultPricebookId();
            update opp;
        }

        //include custom field mapping to vehicle here (Vehicle__c) -> accessory X belong to the vehicle Y
        List<OpportunityLineItem> accessories = [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND (NOT Product2Id IN (SELECT ProductId FROM VehicleDefinition))
        ];

        List<OpportunityLineItem> vehicles = [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND (Product2Id IN (SELECT ProductId FROM VehicleDefinition))
        ];

        List<VehicleDTO> vehiclesDTO = String.isBlank(selectedVehicles)
            ? new List<VehicleDTO>()
            : (List<VehicleDTO>) JSON.deserialize(selectedVehicles, List<VehicleDTO>.class);

        if (vehicles.isEmpty()) {
            List<OpportunityLineItem> vehicleLines = buildVehicleLinesFromSelection(opp, vehiclesDTO);
            insert vehicleLines;
            vehicles = [
                SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
                FROM OpportunityLineItem
                WHERE Id IN :vehicleLines
            ];
        }

        // vigencia: alimenta Flag_Expired_Quotes (alerta de cotizacion vencida
        // en la oportunidad) — sin ExpirationDate la cotizacion nunca vence
        Date vigencia = Date.today().addDays(payload.vigenciaDias != null ? payload.vigenciaDias : 15);

        List<Quote> quotes = new List<Quote>();
        Map<Id, Integer> quoteIndexByVehicleProduct = new Map<Id, Integer>();

        for (OpportunityLineItem vehicle : vehicles) {
            // DTO del vehiculo de ESTA quote: estado por disponibilidad (HU-044)
            // y accesorios/descripcion por vehiculo; safeQuoteStatus evita el
            // INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST mientras el picklist no
            // tenga los valores nuevos (TODO Davi en Setup > Quote Statuses)
            VehicleDTO v = matchDto(vehiclesDTO, vehicle.Product2.Name);
            String quoteStatus = (v == null) ? null : safeQuoteStatus(
                (v.stockCentral != 0 || v.stockDealer != 0) ? 'Pendiente' :
                (v.disponibilidad?.fuente == 'recepcion_futura' ? 'Pedido futuro' : 'En tránsito'));

            Quote quote = new Quote(
                Name = (opp.Name + ' ' + vehicle.Product2.Name),
                OpportunityId = opp.Id,
                Pricebook2Id = opp.Pricebook2Id,
                // multimoneda: la Quote debe tener la MISMA moneda de la
                // Opportunity (regla nativa); explicito para no depender del
                // default de moneda del usuario de integracion
                CurrencyIsoCode = opp.CurrencyIsoCode,
                ExpirationDate = vigencia,
                Description = buildQuoteDescription(payload, v == null ? vehicle.Product2.Name : v.modelo)
            );
            if (quoteStatus != null) {
                quote.Status = quoteStatus;
            }
            if (quote.Name.length() > 80) {
                quote.Name = quote.Name.substring(0, 80);
            }
            quoteIndexByVehicleProduct.put(vehicle.Product2Id, quotes.size());
            quotes.add(quote);
        }

        insert quotes;

        // lineas por cotizacion: el vehiculo va a SU quote (mapa por Product2);
        // los accesorios van a la quote del vehiculo seleccionado en la UI —
        // flujo actual es un vehiculo por corrida; el mapeo por Vehicle__c en
        // la OpportunityLineItem queda para la matriz de compatibilidad
        List<QuoteLineItem> quoteLines = new List<QuoteLineItem>();
        for (OpportunityLineItem vehicle : vehicles) {
            quoteLines.add(new QuoteLineItem(
                QuoteId = quotes[quoteIndexByVehicleProduct.get(vehicle.Product2Id)].Id,
                Quantity = vehicle.Quantity,
                UnitPrice = vehicle.UnitPrice,
                PricebookEntryId = vehicle.PricebookEntryId,
                Product2Id = vehicle.Product2Id
            ));
        }
        for (OpportunityLineItem accessory : accessories) {
            quoteLines.add(new QuoteLineItem(
                QuoteId = quotes[0].Id,
                Quantity = accessory.Quantity,
                UnitPrice = accessory.UnitPrice,
                PricebookEntryId = accessory.PricebookEntryId,
                Product2Id = accessory.Product2Id
            ));
        }
        // accesorios elegidos en la venta guiada: UNA linea por producto en la
        // quote de SU vehiculo (modelo de datos nativo — cada QuoteLineItem
        // apunta a su PricebookEntry)
        quoteLines.addAll(buildAccessoryLinesFromPayload(opp, payload, quotes, vehicles, quoteIndexByVehicleProduct));
        if (!quoteLines.isEmpty()) {
            insert quoteLines;
        }

        // descuento fuera del margen: entra al Approval Process nativo; si el
        // proceso aun no esta configurado en la org, la cotizacion queda con el
        // descuento trazado en Description y el envio se reintenta manualmente
        if (payload.descuentoRequiereAprobacion == true) {
            submitDiscountApproval(quotes, payload);
        }

        return quotes;
    }

    private static QuotePayload parsePayload(String quotePayloadJson) {
        if (String.isBlank(quotePayloadJson)) {
            return new QuotePayload();
        }
        try {
            QuotePayload parsed = (QuotePayload) JSON.deserialize(quotePayloadJson, QuotePayload.class);
            return parsed == null ? new QuotePayload() : parsed;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Payload de cotizacion ilegible, se ignora: ' + e.getMessage());
            return new QuotePayload();
        }
    }

    /**
     * Matches the DTO of the vehicle backing one quote by model name
     * (contains, both directions) — mock stage correlation until the real
     * flow carries Product2Id/VehicleDefinitionId end to end.
     */
    private static VehicleDTO matchDto(List<VehicleDTO> vehiclesDTO, String productName) {
        if (vehiclesDTO == null || vehiclesDTO.isEmpty()) {
            return null;
        }
        String nombre = productName == null ? '' : productName.toLowerCase();
        for (VehicleDTO dto : vehiclesDTO) {
            String modelo = dto.modelo == null ? '' : dto.modelo.toLowerCase();
            if (modelo != '' && (nombre.contains(modelo) || modelo.contains(nombre))) {
                return dto;
            }
        }
        return vehiclesDTO.get(0);
    }

    /**
     * Trazabilidad comercial en la propia cotizacion: descuento (y su estado),
     * forma de pago y accesorios DEL VEHICULO de esta quote. Sustituye al
     * campo custom mientras el modelo de descuento (HU-038) no se cierre.
     */
    private static String buildQuoteDescription(QuotePayload payload, String modelo) {
        List<String> lineas = new List<String>{ 'Venta guiada' + (String.isBlank(payload.ventaTipo) ? '' : ' — ' + payload.ventaTipo) };
        if (payload.descuento != null && payload.descuento > 0) {
            String estado = payload.descuentoRequiereAprobacion == true
                ? (payload.descuentoAprobado == true ? 'enviado a aprobación del Gerente' : 'PENDIENTE de aprobación')
                : 'dentro del margen';
            lineas.add('Descuento solicitado (total de la venta): ' + payload.descuento.format() + ' (' + estado + ')');
        }
        if (String.isNotBlank(payload.formaPago)) {
            String pago;
            if (payload.formaPago == 'financiado' && payload.financiamiento != null) {
                // opcion ELEGIDA por el cliente en la pantalla de pago (oferta
                // de la frente financiera via FinancingService); persistencia
                // en campos propios de la Quote = decision pendiente con la
                // frente financiera — mientras tanto queda trazada aqui
                FinanciamientoDTO f = payload.financiamiento;
                pago = 'Financiado ' + f.entidad + ' ' + f.producto
                    + ' — tasa ' + f.tasaAnual + '% anual, plazo ' + f.plazoMeses
                    + ' meses, cuota ' + (f.cuotaMensual == null ? '-' : f.cuotaMensual.format())
                    + ', prima ' + (payload.prima == null ? '-' : payload.prima.format());
            } else if (payload.formaPago == 'financiado') {
                pago = 'Financiado CrediQ — plazo ' + payload.plazo + ' meses, prima ' + (payload.prima == null ? '-' : payload.prima.format());
            } else {
                pago = 'Contado';
            }
            lineas.add('Forma de pago: ' + pago);
        }
        VehiculoAccesoriosDTO delVehiculo = null;
        if (payload.accesoriosPorVehiculo != null && String.isNotBlank(modelo)) {
            for (VehiculoAccesoriosDTO va : payload.accesoriosPorVehiculo) {
                if (va.modelo != null && (modelo.containsIgnoreCase(va.modelo) || va.modelo.containsIgnoreCase(modelo))) {
                    delVehiculo = va;
                    break;
                }
            }
        }
        if (delVehiculo != null && delVehiculo.items != null && !delVehiculo.items.isEmpty()) {
            List<String> nombres = new List<String>();
            for (AccesorioDTO a : delVehiculo.items) {
                nombres.add(a.nombre);
            }
            lineas.add('Accesorios (' + nombres.size() + '): ' + String.join(nombres, ', '));
        }
        return String.join(lineas, '\n');
    }

    /**
     * One QuoteLineItem PER accessory picked in the guided flow, on the quote
     * of ITS vehicle. The accessory resolves to a PricebookEntry of the
     * opportunity pricebook by product name (contains, both directions —
     * same mock-stage correlation as matchDto; the compatibility matrix will
     * carry Product2Id end to end). Price: the PricebookEntry price (native
     * catalog), NOT the mock price from the UI. An accessory with no active
     * entry in the pricebook/currency CANNOT be a QuoteLineItem (native rule:
     * every line points to a PricebookEntry) — it stays traced in the quote
     * Description and is logged for the catalog team.
     */
    private static List<QuoteLineItem> buildAccessoryLinesFromPayload(Opportunity opp,
            QuotePayload payload, List<Quote> quotes, List<OpportunityLineItem> vehicles,
            Map<Id, Integer> quoteIndexByVehicleProduct) {
        List<QuoteLineItem> lineas = new List<QuoteLineItem>();
        if (payload.accesoriosPorVehiculo == null || payload.accesoriosPorVehiculo.isEmpty()) {
            return lineas;
        }
        Boolean hayItems = false;
        for (VehiculoAccesoriosDTO va : payload.accesoriosPorVehiculo) {
            if (va.items != null && !va.items.isEmpty()) { hayItems = true; break; }
        }
        if (!hayItems) {
            return lineas;
        }
        // catalogo de accesorios del pricebook de la oportunidad (no vehiculos)
        List<PricebookEntry> pbes = [
            SELECT Id, UnitPrice, Product2Id, Product2.Name FROM PricebookEntry
            WHERE Pricebook2Id = :opp.Pricebook2Id AND IsActive = true
              AND CurrencyIsoCode = :opp.CurrencyIsoCode
              AND (NOT Product2Id IN (SELECT ProductId FROM VehicleDefinition))
            LIMIT 500
        ];
        for (VehiculoAccesoriosDTO va : payload.accesoriosPorVehiculo) {
            if (va.items == null || va.items.isEmpty()) continue;
            // quote destino: la del vehiculo del bloque (match por modelo,
            // mismo criterio de matchDto); fallback a la primera
            Integer quoteIdx = 0;
            for (OpportunityLineItem vehicle : vehicles) {
                String nombre = vehicle.Product2.Name;
                if (va.modelo != null && nombre != null
                        && (nombre.containsIgnoreCase(va.modelo) || va.modelo.containsIgnoreCase(nombre))) {
                    quoteIdx = quoteIndexByVehicleProduct.get(vehicle.Product2Id);
                    break;
                }
            }
            for (AccesorioDTO a : va.items) {
                PricebookEntry pbe = null;
                for (PricebookEntry candidato : pbes) {
                    String nombre = candidato.Product2.Name;
                    if (a.nombre != null && nombre != null
                            && (nombre.containsIgnoreCase(a.nombre) || a.nombre.containsIgnoreCase(nombre))) {
                        pbe = candidato;
                        break;
                    }
                }
                if (pbe == null) {
                    System.debug(LoggingLevel.WARN, 'Accesorio sin PricebookEntry activo en ' +
                        opp.CurrencyIsoCode + ', queda solo en Description: ' + a.nombre);
                    continue;
                }
                lineas.add(new QuoteLineItem(
                    QuoteId = quotes[quoteIdx].Id,
                    Quantity = 1,
                    UnitPrice = pbe.UnitPrice,
                    PricebookEntryId = pbe.Id,
                    Product2Id = pbe.Product2Id
                ));
            }
        }
        return lineas;
    }

    /**
     * Default pricebook when the opportunity has none: first active custom
     * pricebook (sociedad catalog), standard as fallback. The seller never
     * chooses a catalog; the sociedad->pricebook map replaces this default
     * once GrupoQ defines the catalog per sociedad.
     */
    private static Id resolveDefaultPricebookId() {
        List<Pricebook2> pbs = [
            SELECT Id FROM Pricebook2
            WHERE IsActive = true AND IsStandard = false
            ORDER BY Name LIMIT 1
        ];
        if (pbs.isEmpty()) {
            pbs = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1];
        }
        if (pbs.isEmpty()) {
            throw new QuoteOrderServiceException('No hay Pricebook activo en la org.');
        }
        return pbs[0].Id;
    }

    /**
     * Fallback when the opportunity has no vehicle line yet: builds ONE line
     * per vehicle selected in the guided flow. Single query for the active
     * vehicle entries of the pricebook, in-memory match by model name
     * (contains, both directions); first unused entry as last resort so a
     * multi-selection never collapses into one product. Currency must match
     * the opportunity (multicurrency org).
     */
    private static List<OpportunityLineItem> buildVehicleLinesFromSelection(Opportunity opp, List<VehicleDTO> vehiclesDTO) {
        List<PricebookEntry> pbes = [
            SELECT Id, UnitPrice, Product2.Name FROM PricebookEntry
            WHERE Pricebook2Id = :opp.Pricebook2Id AND IsActive = true
              AND CurrencyIsoCode = :opp.CurrencyIsoCode
              AND Product2Id IN (SELECT ProductId FROM VehicleDefinition)
            LIMIT 200
        ];
        if (pbes.isEmpty()) {
            throw new QuoteOrderServiceException(
                'El pricebook de la oportunidad no tiene vehiculos activos en la moneda ' + opp.CurrencyIsoCode + '.');
        }

        Integer lineasNecesarias = (vehiclesDTO == null || vehiclesDTO.isEmpty()) ? 1 : vehiclesDTO.size();
        Set<Id> usados = new Set<Id>();
        List<OpportunityLineItem> lineas = new List<OpportunityLineItem>();

        for (Integer i = 0; i < lineasNecesarias; i++) {
            String modelo = (vehiclesDTO != null && i < vehiclesDTO.size() && vehiclesDTO[i].modelo != null)
                ? vehiclesDTO[i].modelo : '';
            PricebookEntry elegido = null;
            for (PricebookEntry pbe : pbes) {
                if (usados.contains(pbe.Id)) continue;
                if (modelo != '' && pbe.Product2.Name != null
                        && (pbe.Product2.Name.containsIgnoreCase(modelo) || modelo.containsIgnoreCase(pbe.Product2.Name))) {
                    elegido = pbe;
                    break;
                }
            }
            if (elegido == null) {
                for (PricebookEntry pbe : pbes) {
                    if (!usados.contains(pbe.Id)) { elegido = pbe; break; }
                }
            }
            if (elegido == null) break; // mas vehiculos seleccionados que productos activos
            usados.add(elegido.Id);
            lineas.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = elegido.Id,
                Quantity = 1,
                UnitPrice = elegido.UnitPrice
            ));
        }
        return lineas;
    }

    /**
     * Applies the availability->status mapping ONLY when the value exists in
     * the active Quote.Status picklist: the org still ships the default
     * statuses (Draft, Presented, Accepted...), so writing an unknown value
     * fails the insert with INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST.
     * TODO (Davi): add En tránsito / Pedido futuro / Pendiente in Setup >
     * Quote Statuses + Record Types NewVehicle/UsedVehicle; this guard then
     * becomes a no-op and the mapping takes effect without redeploy.
     */
    private static String safeQuoteStatus(String candidate) {
        for (Schema.PicklistEntry pe : Quote.Status.getDescribe().getPicklistValues()) {
            if (pe.isActive() && pe.getValue() == candidate) {
                return candidate;
            }
        }
        System.debug('Quote.Status "' + candidate + '" no existe en el picklist activo; se deja el default.');
        return null;
    }

    /**
     * Converts an accepted quote into an order in Borrador state.
     * @param quoteId accepted quote
     * @return created Order Id
     */
    public static Id createOrderFromQuote(Id quoteId) {
        // TODO: native quote-to-order; Record Type from the quote business line
        return null;
    }

    /**
     * Submits the created quotes to the native discount Approval Process.
     * Guarded: while the process is not configured in the org (HU-038 in
     * definition) Approval.process throws NO_APPLICABLE_PROCESS — the quote
     * stays created with the discount traced in Description and the submit
     * is logged, never blocking the seller.
     */
    private static void submitDiscountApproval(List<Quote> quotes, QuotePayload payload) {
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for (Quote q : quotes) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(q.Id);
            req.setComments('Descuento de venta guiada: ' + (payload.descuento == null ? '-' : payload.descuento.format()));
            req.setSubmitterId(UserInfo.getUserId());
            requests.add(req);
        }
        try {
            Approval.process(requests);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'Approval de descuento no enviado (proceso aun no configurado?): ' + e.getMessage());
        }
    }

    public class QuotePayload {
        public String ventaTipo { get; set; }
        public Decimal descuento { get; set; }
        public Boolean descuentoRequiereAprobacion { get; set; }
        public Boolean descuentoAprobado { get; set; }
        public String formaPago { get; set; }
        public Decimal prima { get; set; }
        public String plazo { get; set; }
        public Integer vigenciaDias { get; set; }
        public List<VehiculoAccesoriosDTO> accesoriosPorVehiculo { get; set; }
        public FinanciamientoDTO financiamiento { get; set; }
    }

    /** Opcion de financiamiento ELEGIDA en la UI (FinancingService.FinancingOption). */
    public class FinanciamientoDTO {
        public String optionId { get; set; }
        public String entidad { get; set; }
        public String producto { get; set; }
        public Decimal tasaAnual { get; set; }
        public Integer plazoMeses { get; set; }
        public Decimal cuotaMensual { get; set; }
        public Decimal montoFinanciado { get; set; }
    }

    public class VehiculoAccesoriosDTO {
        public String vehicleId { get; set; }
        public String modelo { get; set; }
        public List<AccesorioDTO> items { get; set; }
    }

    public class AccesorioDTO {
        public String id { get; set; }
        public String nombre { get; set; }
        public Decimal precio { get; set; }
    }

    public class VehicleDTO {

        public String id { get; set; }
        public String modelo { get; set; }
        public String anio { get; set; }
        public String color { get; set; }
        public String precio { get; set; }
        public Integer stockCentral { get; set; }
        public Integer stockDealer { get; set; }

        public Disponibilidad disponibilidad { get; set; }


    }

    public class Disponibilidad {
        public Integer cantidad { get; set; }
        public String eta { get; set; }
        public String fuente { get; set; }
    }


    //custom exception
    public class QuoteOrderServiceException extends Exception {
    }

}
