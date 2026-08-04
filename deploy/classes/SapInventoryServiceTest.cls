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
    static void processResponseMapsSuccessPayload() {
        String requestJson = '{"productCode":"MAT-001","companyCode":"C101",' +
                             '"plant":"C101","quantity":1}';
        Continuation continuation =
            (Continuation) SapInventoryService.getPricesAndInventory(requestJson);
        String requestLabel = ((Map<String, HttpRequest>) continuation.getRequests())
            .keySet().iterator().next();

        HttpResponse fakeResponse = new HttpResponse();
        fakeResponse.setStatusCode(200);
        fakeResponse.setBody(SapCalloutMockFactory.priceInventoryBody());
        Test.setContinuationResponse(requestLabel, fakeResponse);

        String body = SapInventoryService.processResponse(
            new List<String>{ requestLabel }, requestLabel);

        SapInventoryService.PriceInventoryResponse result =
            (SapInventoryService.PriceInventoryResponse) JSON.deserialize(
                body, SapInventoryService.PriceInventoryResponse.class);
        Assert.areEqual('MAT-001', result.productCode, 'Product code must be mapped');
        Assert.areEqual(150.00, result.unitPrice, 'Unit price must be mapped');
        Assert.isNull(result.errorMessage, 'No error expected on HTTP 200');
    }

    @isTest
    static void processResponseFlagsHttpError() {
        String requestJson = '{"productCode":"MAT-001","companyCode":"C101",' +
                             '"plant":"C101","quantity":1}';
        Continuation continuation =
            (Continuation) SapInventoryService.getPricesAndInventory(requestJson);
        String requestLabel = ((Map<String, HttpRequest>) continuation.getRequests())
            .keySet().iterator().next();

        HttpResponse fakeResponse = new HttpResponse();
        fakeResponse.setStatusCode(503);
        fakeResponse.setBody('{"error":"backend down"}');
        Test.setContinuationResponse(requestLabel, fakeResponse);

        String body = SapInventoryService.processResponse(
            new List<String>{ requestLabel }, requestLabel);

        SapInventoryService.PriceInventoryResponse result =
            (SapInventoryService.PriceInventoryResponse) JSON.deserialize(
                body, SapInventoryService.PriceInventoryResponse.class);
        Assert.isNotNull(result.errorMessage, 'HTTP errors must surface a friendly message');
        Assert.isTrue(result.errorMessage.contains('503'), 'Status code helps support triage');
    }
}
