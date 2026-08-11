/**
 * All countries. Tests for the invocable GenerateSapOrderAction (Flow entry
 * of the pedido leg): bulk contract (one Result per Request, order preserved),
 * happy path creating the order + enqueueing the SAP send, and the error path
 * captured per-row (a bad row NEVER breaks the batch — flow fault handling
 * depends on it).
 */
@isTest
private class GenerateSapOrderActionTest {

    @TestSetup
    static void setup() {
        Opportunity opp = VentasTestDataFactory.createGuidedSellingScenario();
        PricebookEntry vehicleEntry = [
            SELECT Id, UnitPrice, Product2Id FROM PricebookEntry
            WHERE Product2.ProductCode = 'VEH-001' LIMIT 1
        ];
        VentasTestDataFactory.createQuoteWithLine(opp, vehicleEntry);
    }

    @isTest
    static void bulkRequestsReturnPerRowResults() {
        Quote quotation = [SELECT Id FROM Quote LIMIT 1];

        GenerateSapOrderAction.Request valida = new GenerateSapOrderAction.Request();
        valida.quoteId = quotation.Id;
        GenerateSapOrderAction.Request invalida = new GenerateSapOrderAction.Request();
        invalida.quoteId = null;

        Test.startTest();
        List<GenerateSapOrderAction.Result> results = GenerateSapOrderAction.generate(
            new List<GenerateSapOrderAction.Request>{ valida, invalida });
        Test.stopTest(); // ejecuta el Queueable de envío a SAP (mock, sin callout)

        Assert.areEqual(2, results.size(), 'Un Result por Request, en el mismo orden.');

        Assert.isTrue(results[0].success, 'La fila válida debe crear el pedido.');
        Assert.isNotNull(results[0].orderId, 'El Id del pedido vuelve al flow.');
        Order pedido = [SELECT SapStatus__c, QuoteId FROM Order WHERE Id = :results[0].orderId];
        Assert.areEqual(quotation.Id, pedido.QuoteId, 'Pedido nace de la cotización enviada.');
        Assert.areEqual('Confirmado SAP', pedido.SapStatus__c,
            'El envío encolado corre al cierre del test (mock determinista).');

        Assert.isFalse(results[1].success, 'La fila inválida falla SOLA, sin romper el lote.');
        Assert.isNull(results[1].orderId, 'Sin pedido en la fila con error.');
        Assert.isTrue(String.isNotBlank(results[1].errorMessage),
            'El mensaje de error viaja al flow para el fault path.');
    }

    @isTest
    static void repeatInvocationReusesExistingOrder() {
        Quote quotation = [SELECT Id FROM Quote LIMIT 1];
        GenerateSapOrderAction.Request req = new GenerateSapOrderAction.Request();
        req.quoteId = quotation.Id;

        Test.startTest();
        List<GenerateSapOrderAction.Result> primera = GenerateSapOrderAction.generate(
            new List<GenerateSapOrderAction.Request>{ req });
        List<GenerateSapOrderAction.Result> segunda = GenerateSapOrderAction.generate(
            new List<GenerateSapOrderAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(primera[0].orderId, segunda[0].orderId,
            'Idempotencia de QuoteOrderService preservada por la acción.');
        Assert.areEqual(1, [SELECT COUNT() FROM Order WHERE QuoteId = :quotation.Id],
            'Nunca se duplica el pedido de una cotización.');
    }
}
