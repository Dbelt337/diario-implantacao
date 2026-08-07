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


}
