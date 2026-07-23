/**
 * Tests for SapInventoryService using Test.setContinuationResponse —
 * no real SAP/MuleSoft needed (GUIA standard).
 */
@isTest
private class SapInventoryServiceTest {

    @isTest
    static void getPricesAndInventoryReturnsContinuation() {
        String requestJson = '{"productCode":"MAT-001","companyCode":"C101",' +
                             '"plant":"C101","quantity":1}';

        Test.startTest();
        Continuation continuation =
            (Continuation) SapInventoryService.getPricesAndInventory(requestJson);
        Test.stopTest();

        Assert.isNotNull(continuation, 'A continuation must be returned to the UI');
    }

    @isTest
    static void processResponseReturnsBody() {
        String requestJson = '{"productCode":"MAT-001","companyCode":"C101",' +
                             '"plant":"C101","quantity":1}';
        Continuation continuation =
            (Continuation) SapInventoryService.getPricesAndInventory(requestJson);
        String requestLabel = ((Map<String, HttpRequest>) continuation.getRequests())
            .keySet().iterator().next();

        HttpResponse fakeResponse = new HttpResponse();
        fakeResponse.setBody(SapCalloutMockFactory.priceInventoryBody());
        Test.setContinuationResponse(requestLabel, fakeResponse);

        String body = SapInventoryService.processResponse(
            new List<String>{ requestLabel }, requestLabel);

        Assert.isTrue(body.contains('MAT-001'), 'Response body must reach the callback');
    }
}
