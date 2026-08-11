/**
 * All countries. Tests for SapOrderService (Queueable + AllowsCallouts):
 * mock-mode happy path (no callout, deterministic Z301), real-mode paths with
 * HttpCalloutMock (success, HTTP error, functional NOK from ZQEV_ASIG_CLIENTE)
 * and the missing-order early return. Every path must leave a coherent
 * Order.SapStatus__c — the UI depends on it via SapOrderResponse__e.
 */
@isTest
private class SapOrderServiceTest {

    @TestSetup
    static void setup() {
        Opportunity opp = VentasTestDataFactory.createGuidedSellingScenario();
        PricebookEntry vehicleEntry = [
            SELECT Id, UnitPrice, Product2Id FROM PricebookEntry
            WHERE Product2.ProductCode = 'VEH-001' LIMIT 1
        ];
        Quote quotation = VentasTestDataFactory.createQuoteWithLine(opp, vehicleEntry);
        QuoteOrderService.createOrderFromQuote(quotation.Id);
    }

    private static Id orderId() {
        return [SELECT Id FROM Order LIMIT 1].Id;
    }

    @isTest
    static void mockModeConfirmsOrderAndStoresSapNumber() {
        Id pedidoId = orderId();

        Test.startTest();
        System.enqueueJob(new SapOrderService(pedidoId));
        Test.stopTest();

        Order pedido = [SELECT SapStatus__c, SapOrderNumber__c FROM Order WHERE Id = :pedidoId];
        Assert.areEqual('Confirmado SAP', pedido.SapStatus__c,
            'Mock determinista con documento -> Confirmado SAP.');
        Assert.isTrue(pedido.SapOrderNumber__c.startsWith('Z301-'),
            'El número de la Z301 queda en el pedido: ' + pedido.SapOrderNumber__c);
    }

    @isTest
    static void realModeSuccessConfirmsOrder() {
        Id pedidoId = orderId();
        SapMuleClient.mockMode = false;
        // un solo body sirve para las 3 llamadas (Ack, CurrencyResult y
        // OrderDocResult ignoran los campos que no les pertenecen)
        Test.setMock(HttpCalloutMock.class, new SapCalloutMockFactory(200,
            '{"ok":true,"currencyIsoCode":"CRC","docType":"Z301","sapDocNumber":"Z301-777","message":"ok"}'));

        Test.startTest();
        System.enqueueJob(new SapOrderService(pedidoId));
        Test.stopTest();

        Order pedido = [SELECT SapStatus__c, SapOrderNumber__c FROM Order WHERE Id = :pedidoId];
        Assert.areEqual('Confirmado SAP', pedido.SapStatus__c, 'Gateway OK -> Confirmado SAP.');
        Assert.areEqual('Z301-777', pedido.SapOrderNumber__c, 'Documento SAP persistido.');
    }

    @isTest
    static void realModeHttpErrorMarksErrorSap() {
        Id pedidoId = orderId();
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class, new SapCalloutMockFactory(500, '{"error":"gateway caido"}'));

        Test.startTest();
        System.enqueueJob(new SapOrderService(pedidoId));
        Test.stopTest();

        Order pedido = [SELECT SapStatus__c, SapOrderNumber__c FROM Order WHERE Id = :pedidoId];
        Assert.areEqual('Error SAP', pedido.SapStatus__c,
            'Error HTTP nunca puede dejar el pedido en un estado intermedio.');
        Assert.isNull(pedido.SapOrderNumber__c, 'Sin documento SAP en error.');
    }

    @isTest
    static void realModeFunctionalNokMarksErrorSap() {
        Id pedidoId = orderId();
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class, new SapCalloutMockFactory(200,
            '{"ok":false,"message":"cliente no existe en la sociedad"}'));

        Test.startTest();
        System.enqueueJob(new SapOrderService(pedidoId));
        Test.stopTest();

        Order pedido = [SELECT SapStatus__c FROM Order WHERE Id = :pedidoId];
        Assert.areEqual('Error SAP', pedido.SapStatus__c,
            'ZQEV_ASIG_CLIENTE con ok=false debe marcar Error SAP.');
    }

    @isTest
    static void missingOrderReturnsWithoutFailing() {
        Order fantasma = new Order(
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            SapStatus__c = 'Borrador'
        );
        insert fantasma;
        Id fantasmaId = fantasma.Id;
        delete fantasma;

        Test.startTest();
        System.enqueueJob(new SapOrderService(fantasmaId));
        Test.stopTest();

        // sin excepción = el job terminó limpio con pedido inexistente
        Assert.areEqual(1, [SELECT COUNT() FROM Order], 'Solo queda el pedido del setup.');
    }
}
