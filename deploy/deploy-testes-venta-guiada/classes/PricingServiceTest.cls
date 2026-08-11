/**
 * All countries. Tests for PricingService. The service is still a documented
 * skeleton (PricebookEntry + BRE pending), so the tests freeze the CONTRACT:
 * a never-null PricingResult whose fields the UI can render safely, ready to
 * grow asserts when the BRE decision matrix lands.
 */
@isTest
private class PricingServiceTest {

    @isTest
    static void getReferencePricingReturnsContractResult() {
        Test.startTest();
        PricingService.PricingResult result = PricingService.getReferencePricing(null, null);
        Test.stopTest();

        Assert.isNotNull(result, 'El contrato exige un PricingResult, nunca null.');
        Assert.isNull(result.listPrice, 'Skeleton: sin precio hasta conectar PricebookEntry.');
        Assert.isNull(result.referenceTaxRate, 'Skeleton: sin tasa hasta conectar el BRE.');
    }

    @isTest
    static void pricingResultCarriesAuraFields() {
        PricingService.PricingResult result = new PricingService.PricingResult();
        result.listPrice = 16800000;
        result.expenses = 250000;
        result.minimumPrice = 15900000;
        result.referenceTaxRate = 13;
        result.referenceTaxAmount = 2184000;
        result.referenceTotal = 19234000;

        Assert.areEqual(19234000, result.referenceTotal,
            'El DTO conserva los montos que la UI exhibe (SAP sigue siendo la autoridad fiscal).');
    }
}
