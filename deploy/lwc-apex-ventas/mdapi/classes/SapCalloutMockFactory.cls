/**
 * All countries. Factory of HttpCalloutMock responses for the MuleSoft
 * integration tests (price/stock, order confirmation, invoice return).
 * Used together with Test.setContinuationResponse for continuation coverage.
 */
@isTest
public class SapCalloutMockFactory implements HttpCalloutMock {

    private final Integer statusCode;
    private final String body;

    public SapCalloutMockFactory(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body = body;
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setHeader('Content-Type', 'application/json');
        response.setBody(body);
        return response;
    }

    /** Canonical price/stock payload for happy-path tests. */
    public static String priceInventoryBody() {
        return '{"productCode":"MAT-001","unitPrice":150.00,"currencyIsoCode":"USD",' +
               '"availableQuantity":12,"plant":"C101"}';
    }
}
