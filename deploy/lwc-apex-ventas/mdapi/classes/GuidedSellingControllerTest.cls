/**
 * All countries. Tests for GuidedSellingController: the controller is a thin
 * delegation layer, so the tests assert the delegation contract (stubs throw
 * until wired) and the continuation plumbing through SapInventoryService.
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
    static void createQuoteStubThrows() {
        Boolean thrown = false;
        try {
            GuidedSellingController.createQuote(null, '{}');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Skeleton stub must signal not-implemented.');
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
