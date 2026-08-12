/**
 * All countries. Single Apex entry point for the guided-selling UI (venta
 * guiada LWCs). Thin @AuraEnabled methods only: sharing enforcement, input
 * validation and DTO shaping — every business rule is delegated to the
 * service layer (MaterialSearchService, SapInventoryService, PricingService,
 * FinancingService, QuoteOrderService), which stays UI-agnostic and reusable
 * by flows, batch and tests. Continuation entry points live here because the
 * class the LWC calls must own the @AuraEnabled(continuation=true) method.
 */
public with sharing class GuidedSellingController {

    /**
     * BFF entry for the SELECTION screen — one screen, one call. Returns a
     * single ViewModel with EVERYTHING the screen renders: the vehicle list
     * (nuevo: local catalog + last known price via MaterialSearchService;
     * usado: own inventory Vehicle SOQL + ficha) plus the accessory list of
     * the sociedad pricebook, prefetched here so the Accesorios step renders
     * with zero extra calls. The SAP price/stock query is NOT in this path:
     * the LWC fires getPricesAndInventory in background on vehicle selection
     * (prefetch window = the Accesorios step).
     * @param searchTerm model, version or VIN fragment typed by the seller
     * @param saleType 'nuevo' or 'usado' (router Record Type in real flow)
     * @return serialized SelectionPageData ViewModel
     */
    @AuraEnabled(cacheable=true)
    public static String getSelectionPageData(String searchTerm, String saleType) {
        // TODO: aggregate MaterialSearchService/Vehicle SOQL + accessory
        // PricebookEntries into ONE payload (BFF rule: never let the screen
        // assemble the puzzle with several calls)
        throw new AuraHandledException('Not implemented: skeleton stub.');
    }

    /**
     * BFF entry for the PRICE screen — the LOCAL half of the ViewModel:
     * price breakdown scaffolding (PricebookEntry reference, gastos,
     * BRE reference tax via PricingService) ready to render instantly.
     * The authoritative SAP half (precio ZGQREF, stock, disponibilidad
     * futura) arrives through the getPricesAndInventory continuation the
     * LWC prefetched at selection time; the screen merges both.
     * @param materialCode SAP material/SKU of the selected vehicle
     * @param sociedad selling company (C101/C105/N101/N105)
     * @param canal channel for Repuestos & PA list selection (null for vehicles)
     * @param clienteId SAP customer code when known (customer-specific price)
     * @param cantidad quantity for volume scales (default 1)
     * @return serialized PricePageData ViewModel (local part)
     */
    @AuraEnabled(cacheable=true)
    public static String getPricePageData(String materialCode, String sociedad,
            String canal, String clienteId, Integer cantidad) {
        // TODO: delegate to PricingService (local breakdown + BRE); never
        // block on SAP here — the continuation owns that leg
        throw new AuraHandledException('Not implemented: skeleton stub.');
    }

    /**
     * Searches sellable vehicles/materials for the selection step.
     * New vehicles resolve through MaterialSearchService (local -> SAP);
     * used vehicles resolve from the OWN inventory (Vehicle records, SOQL).
     * @param searchTerm model, version or VIN fragment typed by the seller
     * @param saleType 'nuevo' or 'usado' (router Record Type in real flow)
     * @return serialized search results for the UI table
     */
    @AuraEnabled(cacheable=true)
    public static String searchVehicles(String searchTerm, String saleType) {
        // TODO: delegate to MaterialSearchService (nuevo) / Vehicle SOQL (usado)
        throw new AuraHandledException('Not implemented: skeleton stub.');
    }

    /**
     * Continuation entry for the SAP price and inventory lookup (new
     * vehicles and Repuestos & PA). Delegates request building and response
     * parsing to SapInventoryService.
     * @param requestJson serialized PriceInventoryRequest from the LWC
     * @return Continuation routed to processPricesAndInventory
     */
    @AuraEnabled(continuation=true cacheable=true)
    public static Object getPricesAndInventory(String requestJson) {
        return SapInventoryService.getPricesAndInventory(requestJson);
    }

    /**
     * Continuation callback for getPricesAndInventory.
     * @param labels continuation request labels
     * @param state label stored when the request was added
     * @return PriceInventoryResponse serialized for the LWC
     */
    @AuraEnabled(cacheable=true)
    public static String processPricesAndInventory(List<String> labels, Object state) {
        return SapInventoryService.processResponse(labels, state);
    }

    /**
     * Financing options for the payment step (Financiado CrediQ): the UI
     * sends monto a financiar, prima and plazo; the customer picks ONE of
     * the returned options and the selection travels in the createQuote
     * payload (block "financiamiento"). Delegates to FinancingService — the
     * CONTRACT with the financial workstream lives there (INTEGRATION MAP).
     * NOT cacheable: rates are live. When the financial front wires an
     * external CrediQ/bureau callout, convert this entry to a Continuation
     * like getPricesAndInventory (the LWC call site stays the same).
     * @param requestJson serialized FinancingService.FinancingRequest
     * @return financing options for the customer to choose from
     */
    @AuraEnabled
    public static List<FinancingService.FinancingOption> getFinancingOptions(String requestJson) {
        try {
            FinancingService.FinancingRequest req = (FinancingService.FinancingRequest)
                JSON.deserialize(requestJson, FinancingService.FinancingRequest.class);
            return FinancingService.getOptions(req);
        } catch (Exception e) {
            throw new AuraHandledException(
                'No fue posible consultar las opciones de financiamiento: ' + e.getMessage());
        }
    }

    /**
     * Creates the native quote for the current opportunity with the lines,
     * traced discount and trade-in chosen in the guided flow. Always a NEW
     * quote on the SAME opportunity (model change never creates a new
     * opportunity); discount approval state travels in the payload.
     * @param opportunityId current opportunity
     * @param quotePayloadJson serialized quote draft built by the UI
     * @return created Quote Id
     */
    @AuraEnabled
    public static List<Quote> createQuote(Id opportunityId, String quotePayloadJson, String selectedVehicles) {
        // TODO: delegate to QuoteOrderService.createQuote
        // plan (Davi):
        // query opportunity + line item
        // create Quote
        // create QuoteLineItem (vehiculo + accesorios del pricebook)
        // create discount approval (cuando el descuento supera el margen)
        try {
            return QuoteOrderService.createQuotesSingleVehicle(opportunityId, quotePayloadJson, selectedVehicles);
        } catch (Exception e) {
            System.debug(
'Error creating quote: ' + e.getMessage() + ' ' + e.getStackTraceString()
            );
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    /**
     * Pedido leg for the guided-selling UI (future wiring in
     * cotizacionConfirmModal): creates the native order from the accepted
     * quote (Borrador) and sends it to SAP in background. The UI listens to
     * SapOrderResponse__e via empApi filtered by the returned Order Id;
     * invoicing arrives later by inbound update on the order (never empApi).
     * @param quoteId accepted quote
     * @return created (or existing) Order Id
     */
    @AuraEnabled
    public static Id createOrderFromQuote(Id quoteId) {
        try {
            Id orderId = QuoteOrderService.createOrderFromQuote(quoteId);
            QuoteOrderService.sendOrderToSap(orderId);
            return orderId;
        } catch (Exception e) {
            throw new AuraHandledException('No fue posible generar el pedido: ' + e.getMessage());
        }
    }

    /**
     * HU-043 (Repuestos & PA): verificación de disponibilidad de un lote de
     * líneas contra SAP vía MuleSoft — CONSULTA_MATERIALES masivo, una sola
     * llamada por lote (GQ-PV-03-028 / 03-023). NO cacheable: la existencia
     * es en tiempo/casi tiempo real y SAP es el maestro del inventario.
     * @param requestJson RepuestosLineService.ConsultaRequest serializado
     * @return líneas con saldo, leyenda de ubicación y estado derivado
     */
    @AuraEnabled
    public static List<RepuestosLineService.LineaResult> checkRepuestosAvailability(String requestJson) {
        try {
            return RepuestosLineService.consultarDisponibilidad(requestJson);
        } catch (Exception e) {
            throw new AuraHandledException(
                'No fue posible consultar la disponibilidad: ' + e.getMessage());
        }
    }

    /**
     * HU-043: sincroniza las líneas de la cotización con la selección del
     * asesor (crear/actualizar/eliminar; GQ-PV-02-023-1 / 02-019). Las
     * líneas Venta Perdida no generan línea: quedan trazadas en la
     * cotización (modelo completo en US-040/US-057).
     */
    @AuraEnabled
    public static RepuestosLineService.GuardarResult saveRepuestosLines(Id quoteId, String lineasJson) {
        try {
            return RepuestosLineService.guardarLineas(quoteId, lineasJson);
        } catch (Exception e) {
            throw new AuraHandledException(
                'No fue posible guardar las líneas: ' + e.getMessage());
        }
    }

    /**
     * HU-043: revalida la disponibilidad de las líneas vigentes de la
     * cotización (modificación dinámica, incluso en fecha posterior —
     * GQ-PV-02-019 / US-090) y actualiza estado y detalle por línea.
     */
    @AuraEnabled
    public static List<RepuestosLineService.LineaResult> revalidateRepuestosLines(Id quoteId,
            String companyCode, String plant) {
        try {
            return RepuestosLineService.revalidarLineas(quoteId, companyCode, plant);
        } catch (Exception e) {
            throw new AuraHandledException(
                'No fue posible revalidar la disponibilidad: ' + e.getMessage());
        }
    }

    /**
     * HU-043 / US-021: búsqueda de materiales para el grid de Repuestos & PA
     * DENTRO del flujo guiado — el asesor teclea y ve sugerencias del
     * catálogo local (SOSL vía MaterialSearchService); si la búsqueda NO
     * encuentra, la UI ofrece "Solicitar creación de material" (US-021) sin
     * salir del flujo. cacheable=true es correcto HOY porque la pierna es
     * 100% local (sin callout y sin stock — la existencia la da
     * checkRepuestosAvailability); cuando se cablee la pierna SAP de
     * MaterialSearchService (callout Mule), este entry DEBE dejar de ser
     * cacheable o migrar a Continuation (callouts prohibidos en cacheable).
     * @param searchTerm texto tecleado (mínimo 3 caracteres, regla del servicio)
     * @param companyCode sociedad del contexto comercial
     * @param plant centro/sucursal
     */
    @AuraEnabled(cacheable=true)
    public static List<MaterialSearchService.MaterialMatch> searchMaterials(String searchTerm,
            String companyCode, String plant) {
        try {
            return MaterialSearchService.search(searchTerm, companyCode, plant);
        } catch (Exception e) {
            throw new AuraHandledException(
                'No fue posible buscar materiales: ' + e.getMessage());
        }
    }

    /**
     * US-021: puerta IMPERATIVA del alta de material SAP — botón "Crear
     * material" de la línea sinCatalogo del grid HU-043. Gobernado por la
     * custom permission CreateSapMaterial; en éxito el material queda en el
     * catálogo local y la línea puede consultarse/guardarse de inmediato.
     * @param requestJson MaterialCreationService.Request serializado
     */
    @AuraEnabled
    public static MaterialCreationService.Result createSapMaterial(String requestJson) {
        try {
            MaterialCreationService.Request req = (MaterialCreationService.Request)
                JSON.deserialize(requestJson, MaterialCreationService.Request.class);
            return MaterialCreationService.crearMaterial(req);
        } catch (Exception e) {
            throw new AuraHandledException(
                'No fue posible crear el material: ' + e.getMessage());
        }
    }

}