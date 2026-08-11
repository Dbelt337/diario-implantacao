/**
 * All countries. Creates quotations and orders on the native model
 * (Quote and Order Capture, Standalone Orders) according to the Record Type
 * of the business line (Venta Vehículo / Contraventa Repuestos / PA / Usados).
 * Bulkified DML; no SOQL or DML inside loops. Order lifecycle: Borrador ->
 * Enviado a SAP -> Confirmado SAP -> Facturado (assetization only on Facturado).
 */
public with sharing class QuoteOrderService {

    public static List<Quote> createQuotesSingleVehicle(Id opportunityId, String quotePayloadJson, String selectedVehicles) {

        if (opportunityId == null) {
            throw new QuoteOrderServiceException('OpportunityId is required.');
        }

        QuotePayload payload = parsePayload(quotePayloadJson);

        //Query Opportunity + OpportunityLineItems
        // WITH USER_MODE en TODAS las queries de la clase: FLS/CRUD/sharing del
        // usuario aplicados por la plataforma (recomendacion actual Salesforce)
        Opportunity[] opps = [
            SELECT Id, Name, AccountId, Pricebook2Id, CurrencyIsoCode
            FROM Opportunity
            WHERE Id = :opportunityId
            WITH USER_MODE
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
        // ProductId != null en el subquery: un VehicleDefinition sin producto
        // envenena el NOT IN (semántica SOQL de null) y vacía la query entera
        List<OpportunityLineItem> accessories = [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
              AND (NOT Product2Id IN (SELECT ProductId FROM VehicleDefinition WHERE ProductId != null))
            WITH USER_MODE
        ];

        List<OpportunityLineItem> vehicles = [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND (Product2Id IN (SELECT ProductId FROM VehicleDefinition))
            WITH USER_MODE
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
                WITH USER_MODE
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
        // catalogo de accesorios del pricebook de la oportunidad (no vehiculos);
        // ProductId != null en el subquery: un VehicleDefinition sin producto
        // envenena el NOT IN (semántica SOQL de null) y vacía el catálogo
        List<PricebookEntry> pbes = [
            SELECT Id, UnitPrice, Product2Id, Product2.Name FROM PricebookEntry
            WHERE Pricebook2Id = :opp.Pricebook2Id AND IsActive = true
              AND CurrencyIsoCode = :opp.CurrencyIsoCode
              AND (NOT Product2Id IN (SELECT ProductId FROM VehicleDefinition WHERE ProductId != null))
            WITH USER_MODE
            LIMIT 500
        ];
        List<AccesorioDTO> pendientes = new List<AccesorioDTO>();
        List<Integer> quoteIdxPorPendiente = new List<Integer>();
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
                    // accesorio elegido en la UI sin entrada de catalogo: se
                    // auto-provisiona abajo — la linea SIEMPRE se crea
                    pendientes.add(a);
                    quoteIdxPorPendiente.add(quoteIdx);
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
        lineas.addAll(provisionAccessoriesAndBuildLines(opp, pendientes, quoteIdxPorPendiente, quotes));
        return lineas;
    }

    /*
      public static List<Quote> createMultiQutoes(Id opportunityId, String quotePayloadJson, String selectedVehicles) {
       
        if (opportunityId == null) {
            throw new QuoteOrderServiceException('OpportunityId is required.');
        }

        QuotePayload payload = parsePayload(quotePayloadJson);

        List<VehicleDTO> vehiclesDTO = String.isBlank(selectedVehicles)
            ? new List<VehicleDTO>()
            : (List<VehicleDTO>) JSON.deserialize(selectedVehicles, List<VehicleDTO>.class);

        if (vehiclesDTO.isEmpty()) {
            throw new QuoteOrderServiceException('No se seleccionaron vehículos');
        }

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

        // vigencia: alimenta Flag_Expired_Quotes (alerta de cotizacion vencida
        // en la oportunidad) — sin ExpirationDate la cotizacion nunca vence
        Date vigencia = Date.today().addDays(payload.vigenciaDias != null ? payload.vigenciaDias : 15);

        List<Quote> quotes = new List<Quote>();
        
        List<String> vehicleProductIds = new List<String>(); // não implementado corretamente; o produtoId possívelmente não vai vir diretamente do DTO / precisamos mapear como vai vir

        //Quote por vehicle
        for (VehicleDTO v : vehiclesDTO) {
            String quoteStatus = (v.stockCentral != 0 || v.stockDealer != 0) ? 'Draft' :
                (v.disponibilidad?.cantidad == null || v.disponibilidad?.cantidad == 0 ? 'Pedido futuro' : 'En tránsito');
            v.quote = new Quote(
                Name = (opp.Name + ' ' + v.modelo),
                OpportunityId = opp.Id,
                Pricebook2Id = opp.Pricebook2Id,
                CurrencyIsoCode = opp.CurrencyIsoCode,
                ExpirationDate = vigencia,
                Description = buildQuoteDescription(payload, v.modelo),
                Status = quoteStatus
            );
            
            if (v.quote.Name.length() > 80) {
                v.quote.Name = v.quote.Name.substring(0, 80);



            }

            if (v.productId != null) vehicleProductIds.add(v.productId); //temporario/não implementado corretamente; o produtoId possívelmente não vai vir diretamente do DTO / precisamos mapear como vai vir

            quotes.add(v.quote);
        }

        if (!quotes.isEmpty()) {
            insert quotes;
        }

        //QuoteLineItem por vehicle
        List<QuoteLineItem> quoteLines = new List<QuoteLineItem>();

        List<String> vehicleAndAccessoryProductIds = new List<String>();
        vehicleAndAccessoryProductIds.addAll(vehicleProductIds);
        
        for (VehiculoAccesoriosDTO va : payload.accesoriosPorVehiculo) {
            if (va.items != null && !va.items.isEmpty()) {
                for (AccesorioDTO a : va.items) {
                    vehicleAndAccessoryProductIds.add(a.productId);
                }
            }
        }

        List<PricebookEntry> pbes = [
            SELECT Id, UnitPrice, Product2Id, Product2.Name FROM PricebookEntry
            WHERE Pricebook2Id = :opp.Pricebook2Id AND IsActive = true
              AND CurrencyIsoCode = :opp.CurrencyIsoCode
              AND Product2Id IN :vehicleAndAccessoryProductIds
        ];

        Map<String, PricebookEntry> pbeByProductId = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : pbes) {
            pbeByProductId.put(pbe.Product2Id, pbe);
        }

        for (VehicleDTO v : vehiclesDTO) {
            PricebookEntry pbe = pbeByProductId.get(v.productId);
            if (pbe == null) continue;

            quoteLines.add(new QuoteLineItem(
                QuoteId = v.quote.Id,
                Quantity = 1,
                UnitPrice = pbe.UnitPrice,
                PricebookEntryId = pbe.Id,
                Product2Id = pbe.Product2Id
            ));

            for (VehiculoAccesoriosDTO va : payload.accesoriosPorVehiculo) {
                if (va.items == null || va.items.isEmpty()) continue;

                for (AccesorioDTO a : va.items) {
                    PricebookEntry pbeAccesorio = pbeByProductId.get(a.productId); //não implementado corretamente; o produtoId possívelmente não vai vir diretamente do DTO / precisamos mapear como vai vir
                    if (pbeAccesorio == null) continue;
                    quoteLines.add(new QuoteLineItem(
                        QuoteId = v.quote.Id,
                        Quantity = 1,
                        UnitPrice = pbeAccesorio.UnitPrice,
                        PricebookEntryId = pbeAccesorio.Id,
                        Product2Id = pbeAccesorio.Product2Id
                    ));
                    
                }
                
            }
            
        }

        if (!quoteLines.isEmpty()) {
            insert quoteLines;
        }

        // descuento fuera del margen: entra al Approval Process nativo; si el
        // proceso aun no esta configurado en la org, la cotizacion queda con el
        // descuento trazado en Description y el envio se reintenta manualmente
        if (payload.descuentoRequiereAprobacion) {
            submitDiscountApproval(quotes, payload);
        }





        return quotes;


    }
    */


    /**
     * Auto-provisión LOCAL de accesorios elegidos en la UI que no existen en
     * el catálogo: crea Product2 + PricebookEntry (estándar y del pricebook de
     * la oportunidad, en la moneda de la venta) y devuelve una QuoteLineItem
     * por accesorio — la línea SIEMPRE nace (regla nativa: toda línea apunta a
     * un PricebookEntry, por eso hay que crear la entrada primero). Accesorios
     * NO son materiales SAP: la regla "el flujo de venta no crea materiales"
     * aplica al maestro SAP (MaterialSearchService); el catálogo local de
     * accesorios sí se extiende aquí. Precio = el de la UI (no hay precio de
     * catálogo aún). Cuando el paso Accesorios lea el pricebook (BFF real),
     * este camino tiende a cero.
     */
    private static List<QuoteLineItem> provisionAccessoriesAndBuildLines(Opportunity opp,
            List<AccesorioDTO> pendientes, List<Integer> quoteIdxPorPendiente, List<Quote> quotes) {
        List<QuoteLineItem> lineas = new List<QuoteLineItem>();
        if (pendientes.isEmpty()) {
            return lineas;
        }

        // dedup por nombre: el mismo accesorio en dos vehiculos = UN producto
        Map<String, Product2> productoPorLlave = new Map<String, Product2>();
        Map<String, Decimal> precioPorLlave = new Map<String, Decimal>();
        for (AccesorioDTO a : pendientes) {
            String llave = a.nombre == null ? '' : a.nombre.trim().toLowerCase();
            if (llave == '') continue;
            if (!productoPorLlave.containsKey(llave)) {
                productoPorLlave.put(llave, new Product2(
                    Name = a.nombre.trim().left(255),
                    ProductCode = String.isBlank(a.id) ? null : ('VG-ACC-' + a.id),
                    IsActive = true,
                    Description = 'Accesorio creado por la venta guiada (auto-provisión de catálogo local).'
                ));
                precioPorLlave.put(llave, a.precio == null ? 0 : a.precio);
            }
        }
        if (productoPorLlave.isEmpty()) {
            return lineas;
        }
        insert productoPorLlave.values();

        // el pricebook estándar NO es consultable por SOQL en contexto de
        // test sin SeeAllData (comportamiento documentado — de ahí
        // Test.getStandardPricebookId); en runtime la query sigue siendo la
        // fuente
        Id estandarId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        // multimoneda: la entrada nace en la moneda de la oportunidad
        List<PricebookEntry> entradasEstandar = new List<PricebookEntry>();
        for (String llave : productoPorLlave.keySet()) {
            entradasEstandar.add(new PricebookEntry(
                Pricebook2Id = estandarId,
                Product2Id = productoPorLlave.get(llave).Id,
                UnitPrice = precioPorLlave.get(llave),
                IsActive = true,
                CurrencyIsoCode = opp.CurrencyIsoCode
            ));
        }
        insert entradasEstandar;

        Map<String, PricebookEntry> entradaFinalPorLlave = new Map<String, PricebookEntry>();
        if (opp.Pricebook2Id != estandarId) {
            List<String> llaves = new List<String>(productoPorLlave.keySet());
            List<PricebookEntry> entradasCustom = new List<PricebookEntry>();
            for (String llave : llaves) {
                entradasCustom.add(new PricebookEntry(
                    Pricebook2Id = opp.Pricebook2Id,
                    Product2Id = productoPorLlave.get(llave).Id,
                    UnitPrice = precioPorLlave.get(llave),
                    IsActive = true,
                    UseStandardPrice = false,
                    CurrencyIsoCode = opp.CurrencyIsoCode
                ));
            }
            insert entradasCustom;
            for (Integer i = 0; i < llaves.size(); i++) {
                entradaFinalPorLlave.put(llaves[i], entradasCustom[i]);
            }
        } else {
            List<String> llaves = new List<String>(productoPorLlave.keySet());
            for (Integer i = 0; i < llaves.size(); i++) {
                entradaFinalPorLlave.put(llaves[i], entradasEstandar[i]);
            }
        }

        for (Integer i = 0; i < pendientes.size(); i++) {
            String llave = pendientes[i].nombre == null ? '' : pendientes[i].nombre.trim().toLowerCase();
            PricebookEntry pbe = entradaFinalPorLlave.get(llave);
            if (pbe == null) continue;
            lineas.add(new QuoteLineItem(
                QuoteId = quotes[quoteIdxPorPendiente[i]].Id,
                Quantity = 1,
                UnitPrice = precioPorLlave.get(llave),
                PricebookEntryId = pbe.Id,
                Product2Id = productoPorLlave.get(llave).Id
            ));
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
            WITH USER_MODE
            ORDER BY Name LIMIT 1
        ];
        if (pbs.isEmpty()) {
            pbs = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true WITH USER_MODE LIMIT 1];
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
            WITH USER_MODE
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
     * Converts an accepted quote into an order in Borrador state: native
     * quote-to-order (Order + one OrderItem per QuoteLineItem, same
     * pricebook/currency). The SAP lifecycle lives in Order.SapStatus__c
     * (Borrador -> Enviado a SAP -> Confirmado SAP -> Facturado); the native
     * Status stays Draft until back-office activates. Idempotent: an order
     * already generated for the quote is returned, never duplicated (the SAP
     * document must exist once per quote). Assetization only on Facturado —
     * owned by the Facturado leg, never here.
     * @param quoteId accepted quote
     * @return created (or existing) Order Id
     */
    public static Id createOrderFromQuote(Id quoteId) {
        if (quoteId == null) {
            throw new QuoteOrderServiceException('QuoteId is required.');
        }

        List<Quote> quotes = [
            SELECT Id, Name, Status, OpportunityId, Opportunity.AccountId,
                   Pricebook2Id, CurrencyIsoCode,
                   (SELECT Id, PricebookEntryId, Quantity, UnitPrice, Product2Id FROM QuoteLineItems)
            FROM Quote
            WHERE Id = :quoteId
            WITH USER_MODE
        ];
        if (quotes.isEmpty()) {
            throw new QuoteOrderServiceException('No se encontró la cotización.');
        }
        Quote cotizacion = quotes[0];
        if (cotizacion.QuoteLineItems.isEmpty()) {
            throw new QuoteOrderServiceException('La cotización no tiene líneas; no es posible generar el pedido.');
        }

        // invariante del sistema (un documento SAP por cotización): la
        // verificación corre en modo sistema a propósito — con USER_MODE la
        // query falla en runtime para perfiles sin FLS sobre Order.QuoteId
        // ("No such column 'QuoteId' on entity 'Order'"), y la idempotencia
        // no puede depender del perfil del vendedor
        List<Order> existentes = [
            SELECT Id FROM Order WHERE QuoteId = :quoteId LIMIT 1
        ];
        if (!existentes.isEmpty()) {
            return existentes[0].Id;
        }

        Order pedido = new Order(
            AccountId = cotizacion.Opportunity.AccountId,
            OpportunityId = cotizacion.OpportunityId,
            QuoteId = cotizacion.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = cotizacion.Pricebook2Id,
            // multimoneda: el pedido hereda la moneda de la cotizacion (misma
            // regla nativa Opportunity->Quote); SAP factura en esa moneda
            CurrencyIsoCode = cotizacion.CurrencyIsoCode,
            SapStatus__c = 'Borrador'
        );
        insert pedido;

        List<OrderItem> lineas = new List<OrderItem>();
        for (QuoteLineItem qli : cotizacion.QuoteLineItems) {
            lineas.add(new OrderItem(
                OrderId = pedido.Id,
                PricebookEntryId = qli.PricebookEntryId,
                Quantity = qli.Quantity,
                UnitPrice = qli.UnitPrice
            ));
        }
        insert lineas;

        return pedido.Id;
    }

    /**
     * Sends the order to SAP in background (the seller never waits): enqueues
     * SapOrderService, which owns the transition Borrador -> Enviado a SAP /
     * Confirmado SAP / Error SAP and publishes SapOrderResponse__e for the UI.
     * @param orderId order in Borrador (or Error SAP, for retry)
     * @return queueable job Id
     */
    public static Id sendOrderToSap(Id orderId) {
        if (orderId == null) {
            throw new QuoteOrderServiceException('OrderId is required.');
        }
        return System.enqueueJob(new SapOrderService(orderId));
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