/**
 * All countries. Synchronous price and stock lookup against SAP through MuleSoft,
 * using Continuation so the request never blocks a server thread (guided selling UI).
 * Endpoint and credentials live in the MuleSoft Named Credential — never in code.
 * Business rules do not belong here: reference price/tax rules live in the BRE.
 */
public with sharing class SapInventoryService {

    // Named Credential configured per environment; single prices-and-inventory endpoint
    private static final String PRICES_INVENTORY_ENDPOINT =
        'callout:MuleSoftPricesInventory/api/v1/prices-and-inventory';
    private static final Integer TIMEOUT_SECONDS = 60;

    /**
     * Starts the continuation with the SAP price/inventory request.
     * @param requestJson serialized PriceInventoryRequest coming from the LWC
     * @return Continuation routed to processResponse
     */
    @AuraEnabled(continuation=true cacheable=true)
    public static Object getPricesAndInventory(String requestJson) {
        PriceInventoryRequest request =
            (PriceInventoryRequest) JSON.deserialize(requestJson, PriceInventoryRequest.class);

        Continuation continuation = new Continuation(TIMEOUT_SECONDS);
        continuation.continuationMethod = 'processResponse';

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint(PRICES_INVENTORY_ENDPOINT);
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setBody(JSON.serialize(request));

        continuation.state = continuation.addHttpRequest(httpRequest);
        return continuation;
    }

    /**
     * Continuation callback: parses the MuleSoft response for the UI.
     * @param labels continuation request labels
     * @param state label stored when the request was added
     * @return PriceInventoryResponse serialized for the LWC
     */
    @AuraEnabled(cacheable=true)
    public static String processResponse(List<String> labels, Object state) {
        HttpResponse response = Continuation.getResponse((String) state);
        // TODO: map MuleSoft payload to PriceInventoryResponse and handle non-200 statuses
        return response.getBody();
    }

    /** Request payload: what the UI knows when asking SAP. */
    public class PriceInventoryRequest {
        @AuraEnabled public String productCode;   // SAP material
        @AuraEnabled public String companyCode;   // sociedad (C101/C105)
        @AuraEnabled public String plant;         // centro/sucursal
        @AuraEnabled public String customerCode;  // for customer-specific PA lists
        @AuraEnabled public Integer quantity;
    }

    /** Response payload: what SAP answers (price is displayed, never recalculated). */
    public class PriceInventoryResponse {
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public String currencyIsoCode;
        @AuraEnabled public Decimal availableQuantity;
        @AuraEnabled public String plant;
        @AuraEnabled public String errorMessage;
    }
}
