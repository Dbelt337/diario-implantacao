/**
 * All countries. Synchronous price and stock lookup against SAP through MuleSoft,
 * using Continuation so the request never blocks a server thread (guided selling UI).
 * Endpoint and credentials live in the MuleSoft Named Credential — never in code.
 * Business rules do not belong here: reference price/tax rules live in the BRE.
 *
 * INTEGRATION MAP (Davi):
 *  - The Named Credential MuleGateway (+ External Credential
 *    MuleSoft_EC, OAuth client credentials) is deployed with this package.
 *    The Mule endpoint URL and the client id/secret are set in Setup by an
 *    admin — code never changes between environments.
 *  - Transactional price/stock (THIS class): POST prices-and-inventory,
 *    request/response DTOs below ARE the contract agreed with MuleSoft
 *    (RN-18 family / RFC Get_Price_ZGQREF behind Mule). Never cache: the
 *    price shown is the price SAP answered for this quote.
 *  - Catalog browse/search is NOT here: MaterialSearchService owns it
 *    (separate endpoint, cacheable server-side).
 */
public with sharing class SapInventoryService {

    // Named Credential configured per environment; single prices-and-inventory endpoint
    private static final String PRICES_INVENTORY_ENDPOINT =
        'callout:MuleGateway/api/v1/prices-and-inventory';
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
     * Always returns a serialized PriceInventoryResponse — on transport or
     * HTTP errors the errorMessage field carries a user-facing Spanish text
     * and the UI decides how to render it (never a raw stack trace).
     * @param labels continuation request labels
     * @param state label stored when the request was added
     * @return PriceInventoryResponse serialized for the LWC
     */
    @AuraEnabled(cacheable=true)
    public static String processResponse(List<String> labels, Object state) {
        HttpResponse response = Continuation.getResponse((String) state);
        PriceInventoryResponse result = new PriceInventoryResponse();

        if (response.getStatusCode() == 200) {
            try {
                result = (PriceInventoryResponse) JSON.deserialize(
                    response.getBody(), PriceInventoryResponse.class);
            } catch (JSONException parseError) {
                result.errorMessage =
                    'Respuesta inesperada del servicio de precios. Contacte al administrador.';
            }
        } else {
            result.errorMessage =
                'Servicio de precios no disponible en este momento (HTTP '
                + response.getStatusCode() + '). Intente de nuevo.';
        }
        return JSON.serialize(result);
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