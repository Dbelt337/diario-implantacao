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
     * PricebookEntry reference columns (list/exonerado, gastos, minimo),
     * cashback, the TRADE-IN operand of the opportunity (frozen appraisal
     * value + validity flag) and the BRE reference tax (service TODO).
     * The authoritative SAP half (precio ZGQREF, stock, disponibilidad
     * futura) arrives through the getPricesAndInventory continuation the
     * LWC prefetched at selection time; the screen merges both and feeds
     * the operands to resumenFinanciero (never a precomputed net).
     * @param materialCode SAP material/SKU of the selected vehicle
     * @param sociedad selling company (C101/C105/N101/N105)
     * @param canal channel for Repuestos & PA list selection (null for vehicles)
     * @param clienteId SAP customer code when known (customer-specific price)
     * @param cantidad quantity for volume scales (default 1)
     * @param opportunityId current opportunity (pricebook + trade-in context)
     * @return serialized PricingService.PricingResult (local part)
     */
    @AuraEnabled(cacheable=true)
    public static String getPricePageData(String materialCode, String sociedad,
            String canal, String clienteId, Integer cantidad, Id opportunityId) {
        try {
            Id pricebookEntryId;
            Id accountId;
            if (opportunityId != null) {
                List<Opportunity> opps = [
                    SELECT AccountId, Pricebook2Id
                    FROM Opportunity
                    WHERE Id = :opportunityId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (!opps.isEmpty()) {
                    accountId = opps[0].AccountId;
                    // The opportunity pricebook IS the sociedad selection
                    // (one pricebook per sociedad); without it there is no
                    // local reference price - same guard as createQuote.
                    if (opps[0].Pricebook2Id != null
                            && String.isNotBlank(materialCode)) {
                        List<PricebookEntry> pbes = [
                            SELECT Id
                            FROM PricebookEntry
                            WHERE Pricebook2Id = :opps[0].Pricebook2Id
                                AND Product2.ProductCode = :materialCode
                                AND IsActive = true
                            WITH SECURITY_ENFORCED
                            LIMIT 1
                        ];
                        if (!pbes.isEmpty()) {
                            pricebookEntryId = pbes[0].Id;
                        }
                    }
                }
            }
            // PricingResult still carries the trade-in operand even when the
            // material has no local entry (e.g. usados priced by management).
            return JSON.serialize(
                PricingService.getReferencePricing(pricebookEntryId, accountId,
                    opportunityId));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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


}
