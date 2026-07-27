/**
 * All countries. Single Apex entry point for the guided-selling UI (venta
 * guiada LWCs). Thin @AuraEnabled methods only: sharing enforcement, input
 * validation and DTO shaping — every business rule is delegated to the
 * service layer (MaterialSearchService, SapInventoryService, PricingService,
 * QuoteOrderService), which stays UI-agnostic and reusable by flows, batch
 * and tests. Continuation entry points live here because the class the LWC
 * calls must own the @AuraEnabled(continuation=true) method.
 */
public with sharing class GuidedSellingController {

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
     * Creates the native quote for the current opportunity with the lines,
     * traced discount and trade-in chosen in the guided flow. Always a NEW
     * quote on the SAME opportunity (model change never creates a new
     * opportunity); discount approval state travels in the payload.
     * @param opportunityId current opportunity
     * @param quotePayloadJson serialized quote draft built by the UI
     * @return created Quote Id
     */
    @AuraEnabled
    public static Id createQuote(Id opportunityId, String quotePayloadJson) {
        // TODO: delegate to QuoteOrderService.createQuote
        throw new AuraHandledException('Not implemented: skeleton stub.');
    }
}
