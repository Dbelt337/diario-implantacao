/**
 * All countries. Tests for GuidedSellingController: the controller is a thin
 * delegation layer, so the tests assert the delegation contract (stubs throw
 * until wired), the continuation plumbing through SapInventoryService and the
 * wired paths createQuote / createOrderFromQuote (AuraHandledException on
 * failure — the LWC never sees a raw stack trace).
 */
@isTest
private class GuidedSellingControllerTest {

    @isTest
    static void searchVehiclesStubThrows() {
        Boolean thrown = false;
        try {
            GuidedSellingController.searchVehicles('Tucson', 'nuevo');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Skeleton stub must signal not-implemented.');
    }

    @isTest
    static void selectionPageDataStubThrows() {
        Boolean thrown = false;
        try {
            GuidedSellingController.getSelectionPageData('Tucson', 'nuevo');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Skeleton stub must signal not-implemented.');
    }

    @isTest
    static void pricePageDataStubThrows() {
        Boolean thrown = false;
        try {
            GuidedSellingController.getPricePageData('SPW5K2G1U_D_D529', 'C101', null, null, 1);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Skeleton stub must signal not-implemented.');
    }

    @isTest
    static void createQuoteWrapsServiceErrorsAsAuraHandled() {
        Boolean thrown = false;
        try {
            GuidedSellingController.createQuote(null, '{}', null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Errores del servicio deben llegar a la UI como AuraHandledException.');
    }

    @isTest
    static void createQuoteDelegatesToQuoteOrderService() {
        Opportunity opp = VentasTestDataFactory.createGuidedSellingScenario();
        PricebookEntry vehicleEntry = [
            SELECT Id, UnitPrice FROM PricebookEntry
            WHERE Product2.ProductCode = 'VEH-001' LIMIT 1
        ];
        VentasTestDataFactory.addOpportunityLine(opp.Id, vehicleEntry.Id, 1, vehicleEntry.UnitPrice);

        Test.startTest();
        List<Quote> quotes = GuidedSellingController.createQuote(opp.Id, '{}', null);
        Test.stopTest();

        System.assertEquals(1, quotes.size(),
            'El controller devuelve las cotizaciones creadas por QuoteOrderService.');
        System.assertEquals(opp.Id, [SELECT OpportunityId FROM Quote WHERE Id = :quotes[0].Id].OpportunityId,
            'La cotización nace sobre la MISMA oportunidad (cambio de modelo nunca crea otra).');
    }

    @isTest
    static void createOrderFromQuoteDelegatesAndEnqueuesSend() {
        Opportunity opp = VentasTestDataFactory.createGuidedSellingScenario();
        PricebookEntry vehicleEntry = [
            SELECT Id, UnitPrice, Product2Id FROM PricebookEntry
            WHERE Product2.ProductCode = 'VEH-001' LIMIT 1
        ];
        Quote quotation = VentasTestDataFactory.createQuoteWithLine(opp, vehicleEntry);

        Test.startTest();
        Id orderId = GuidedSellingController.createOrderFromQuote(quotation.Id);
        Test.stopTest(); // ejecuta el envío a SAP encolado (mock determinista)

        System.assertNotEquals(null, orderId, 'El Id del pedido vuelve a la UI (filtro empApi).');
        Order pedido = [SELECT SapStatus__c FROM Order WHERE Id = :orderId];
        System.assertEquals('Confirmado SAP', pedido.SapStatus__c,
            'El pedido termina confirmado por el mock al cerrar el test.');
    }

    @isTest
    static void createOrderFromQuoteWrapsErrorsAsAuraHandled() {
        Boolean thrown = false;
        try {
            GuidedSellingController.createOrderFromQuote(null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Errores del pedido llegan a la UI como AuraHandledException.');
    }

    @isTest
    static void continuationDelegatesToService() {
        String requestJson = JSON.serialize(new Map<String, Object>{
            'productCode' => 'MAT-001',
            'companyCode' => 'C101',
            'plant' => 'URUCA',
            'quantity' => 1
        });

        Test.startTest();
        Continuation continuation =
            (Continuation) GuidedSellingController.getPricesAndInventory(requestJson);
        Test.stopTest();

        System.assertNotEquals(null, continuation,
            'Controller must return the Continuation built by SapInventoryService.');
    }
}
