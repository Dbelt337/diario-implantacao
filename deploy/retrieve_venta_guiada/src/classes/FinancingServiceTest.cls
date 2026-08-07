/**
 * All countries. Tests for FinancingService (mock mode) and the
 * GuidedSellingController.getFinancingOptions entry the LWC calls.
 */
@isTest
private class FinancingServiceTest {

    private static FinancingService.FinancingRequest buildRequest() {
        FinancingService.FinancingRequest req = new FinancingService.FinancingRequest();
        req.montoFinanciar = 11760000;
        req.prima = 5040000;
        req.plazoMeses = 60;
        req.monedaIso = 'CRC';
        req.descripcionVehiculo = 'Hyundai Creta GL 1.5 2026';
        return req;
    }

    @isTest
    static void getOptionsReturnsCrediQProducts() {
        List<FinancingService.FinancingOption> options =
            FinancingService.getOptions(buildRequest());

        System.assertEquals(3, options.size(), 'Mock must return the three CrediQ products.');
        for (FinancingService.FinancingOption op : options) {
            System.assertEquals('CrediQ', op.entidad, 'Mock options are CrediQ products.');
            System.assert(op.cuotaMensual > 0, 'French annuity must yield a positive cuota.');
            System.assertEquals(11760000, op.montoFinanciado,
                'Financed amount echoes the request.');
        }
        System.assertEquals(72, options[2].plazoMeses,
            'Cuota Flex extends the term to 72 months.');
        System.assert(options[2].cuotaMensual < options[0].cuotaMensual,
            '72-month option must have a lower cuota than the 60-month one.');
    }

    @isTest
    static void getOptionsRejectsMissingAmount() {
        Boolean thrown = false;
        try {
            FinancingService.getOptions(new FinancingService.FinancingRequest());
        } catch (IllegalArgumentException e) {
            thrown = true;
        }
        System.assert(thrown, 'Missing montoFinanciar must be rejected.');
    }

    @isTest
    static void cuotaFrancesaMatchesReference() {
        // 11.760.000 al 9,5% anual a 60 meses ~ 246.982 (referencia de la UI)
        Decimal cuota = FinancingService.cuotaFrancesa(11760000, 9.5, 60);
        System.assert(cuota > 246000 && cuota < 248000,
            'Annuity out of expected range: ' + cuota);
    }

    @isTest
    static void controllerEntryDeserializesAndDelegates() {
        String requestJson = JSON.serialize(buildRequest());

        Test.startTest();
        List<FinancingService.FinancingOption> options =
            GuidedSellingController.getFinancingOptions(requestJson);
        Test.stopTest();

        System.assertEquals(3, options.size(),
            'Controller must return the options built by FinancingService.');
    }

    @isTest
    static void controllerEntryWrapsErrorsAsAuraHandled() {
        Boolean thrown = false;
        try {
            GuidedSellingController.getFinancingOptions('{"montoFinanciar":0}');
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Controller must wrap service errors for the UI.');
    }
}