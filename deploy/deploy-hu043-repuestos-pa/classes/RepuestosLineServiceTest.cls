/**
 * All countries. Tests for RepuestosLineService (HU-043): availability per
 * line against the massive SAP query (SapMuleClient mock mode — no callouts),
 * status derivation (Disponible/Parcial/No Disponible incl. negative TDET
 * saldo), quote line sync (create/update/delete), Venta Perdida tracing on
 * the quote, catalog-miss handling (US-021 out of scope) and revalidation.
 * No SeeAllData; pricebook = standard via Test.getStandardPricebookId().
 */
@isTest
private class RepuestosLineServiceTest {

    @TestSetup
    static void setup() {
        Account customer = VentasTestDataFactory.createAccount();
        Opportunity opp = VentasTestDataFactory.createOpportunity(customer.Id);
        // catalogo local de repuestos: REP-001 y REP-002 con entrada standard
        Product2 filtro = VentasTestDataFactory.createProduct('Filtro de aceite', 'REP-001');
        VentasTestDataFactory.createStandardEntry(filtro.Id, 15000);
        Product2 bujia = VentasTestDataFactory.createProduct('Bujia iridium', 'REP-002');
        VentasTestDataFactory.createStandardEntry(bujia.Id, 8000);
        insert new Quote(Name = 'Cotizacion Repuestos', OpportunityId = opp.Id,
            Pricebook2Id = opp.Pricebook2Id);
    }

    private static Quote getQuote() {
        return [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote LIMIT 1];
    }

    private static String buildRequest(List<Map<String, Object>> lineas) {
        Quote q = getQuote();
        return JSON.serialize(new Map<String, Object>{
            'companyCode' => 'C101', 'plant' => 'URUCA',
            'pricebookId' => q.Pricebook2Id, 'currencyIsoCode' => q.CurrencyIsoCode,
            'lineas' => lineas
        });
    }

    @isTest
    static void consultarDisponibilidadDerivaEstadosYCatalogo() {
        // mock masivo determinista: saldo decrece por posicion y se vuelve
        // negativo (TDET_SALDOS = PISO - RESERVA) — cubre los tres estados
        String req = buildRequest(new List<Map<String, Object>>{
            new Map<String, Object>{ 'productCode' => 'REP-001', 'cantidad' => 1 },
            new Map<String, Object>{ 'productCode' => 'REP-002', 'cantidad' => 20 },
            new Map<String, Object>{ 'productCode' => 'REP-XXX', 'cantidad' => 1 }
        });

        Test.startTest();
        List<RepuestosLineService.LineaResult> lineas =
            RepuestosLineService.consultarDisponibilidad(req);
        Test.stopTest();

        Assert.areEqual(3, lineas.size(), 'Una respuesta por línea consultada.');
        Assert.areEqual('Disponible', lineas[0].status,
            'Saldo 10 cubre cantidad 1. Saldo: ' + lineas[0].saldoDisponible);
        Assert.isFalse(lineas[0].sinCatalogo, 'REP-001 existe en el catálogo local.');
        Assert.isNotNull(lineas[0].unitPrice, 'La línea con catálogo trae precio de lista.');
        Assert.areEqual('Parcial', lineas[1].status,
            'Saldo positivo que no cubre la cantidad pedida es Parcial. Saldo: ' + lineas[1].saldoDisponible);
        Assert.isTrue(lineas[2].sinCatalogo,
            'Material sin Product2/PricebookEntry local se marca sinCatalogo (US-021).');
        Assert.isNotNull(lineas[0].textoExistencia, 'La leyenda de SAP viaja a la UI.');
        Assert.isNotNull(lineas[0].piso, 'Piso visible (GQ-PV-03-023).');
        Assert.isNotNull(lineas[0].reserva, 'Reserva visible como lectura (GQ-PV-03-023).');
    }

    @isTest
    static void derivarStatusUsaLeyendaConSaldoNegativo() {
        SapMuleClient.MaterialSaldo saldo = new SapMuleClient.MaterialSaldo();
        saldo.saldoDisponible = -2;
        saldo.textoExistencia = 'Existencia en OTRO CENTRO: Liberia';
        Assert.areEqual('Otro Centro', RepuestosLineService.derivarStatus(1, saldo),
            'Sin saldo local, la leyenda define la ubicación.');
        saldo.textoExistencia = 'Disponible en OTRA SOCIEDAD (S101)';
        Assert.areEqual('Otra Sociedad', RepuestosLineService.derivarStatus(1, saldo));
        saldo.textoExistencia = 'sin saldo — piso comprometido por reservas';
        Assert.areEqual('No Disponible', RepuestosLineService.derivarStatus(1, saldo));
        Assert.areEqual('No Disponible', RepuestosLineService.derivarStatus(1, null),
            'Sin respuesta de SAP la línea no se confirma (Esc.7).');
    }

    @isTest
    static void guardarLineasCreaActualizaEliminaYTrazaVentaPerdida() {
        Quote cotizacion = getQuote();

        // 1a sincronizacion: dos lineas
        String lineas1 = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'productCode' => 'REP-001', 'cantidad' => 2,
                'status' => 'Disponible', 'detalle' => 'MOCK: disponible' },
            new Map<String, Object>{ 'productCode' => 'REP-002', 'cantidad' => 4,
                'status' => 'Parcial', 'detalle' => 'MOCK: parcial' }
        });
        Test.startTest();
        RepuestosLineService.GuardarResult r1 =
            RepuestosLineService.guardarLineas(cotizacion.Id, lineas1);

        // 2a sincronizacion (modificacion dinamica): REP-001 cambia cantidad,
        // REP-002 sale, REP-XXX sin catalogo, y una Venta Perdida trazada
        String lineas2 = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'productCode' => 'REP-001', 'cantidad' => 5,
                'status' => 'Disponible', 'detalle' => 'MOCK: disponible' },
            new Map<String, Object>{ 'productCode' => 'REP-XXX', 'cantidad' => 1,
                'status' => 'No Disponible' },
            new Map<String, Object>{ 'productCode' => 'REP-PERD', 'cantidad' => 3,
                'ventaPerdida' => true, 'detalle' => 'Cliente no espera traslado' }
        });
        RepuestosLineService.GuardarResult r2 =
            RepuestosLineService.guardarLineas(cotizacion.Id, lineas2);
        Test.stopTest();

        Assert.areEqual(2, r1.creadas, 'Primera sincronización crea las dos líneas.');
        Assert.areEqual(1, r2.actualizadas, 'REP-001 se actualiza.');
        Assert.areEqual(1, r2.eliminadas, 'REP-002 sale de la selección y se elimina.');
        Assert.areEqual(1, r2.ventasPerdidas, 'REP-PERD queda como Venta Perdida.');
        Assert.areEqual(new List<String>{ 'REP-XXX' }, r2.sinCatalogo,
            'Material sin catálogo no se guarda (US-021).');

        List<QuoteLineItem> qlis = [
            SELECT Quantity, AvailabilityStatus__c, Product2.ProductCode
            FROM QuoteLineItem WHERE QuoteId = :cotizacion.Id
        ];
        Assert.areEqual(1, qlis.size(), 'Queda solo la línea vigente.');
        Assert.areEqual('REP-001', qlis[0].Product2.ProductCode);
        Assert.areEqual(5, qlis[0].Quantity, 'Cantidad actualizada en la modificación.');
        Assert.areEqual('Disponible', qlis[0].AvailabilityStatus__c,
            'Estado persistido en la línea.');

        Quote refreshed = [SELECT Description FROM Quote WHERE Id = :cotizacion.Id];
        Assert.isTrue(refreshed.Description.contains('[Venta Perdida] REP-PERD'),
            'La Venta Perdida queda trazada en la cotización. Description: ' + refreshed.Description);
    }

    @isTest
    static void revalidarActualizaEstadoDeLasLineas() {
        Quote cotizacion = getQuote();
        RepuestosLineService.guardarLineas(cotizacion.Id, JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'productCode' => 'REP-001', 'cantidad' => 1, 'status' => 'No Disponible' }
        }));

        Test.startTest();
        List<RepuestosLineService.LineaResult> lineas =
            RepuestosLineService.revalidarLineas(cotizacion.Id, 'C101', 'URUCA');
        Test.stopTest();

        Assert.areEqual(1, lineas.size(), 'Una línea revalidada.');
        Assert.areEqual('Disponible', lineas[0].status,
            'El mock devuelve saldo 10 para la primera posición.');
        QuoteLineItem qli = [
            SELECT AvailabilityStatus__c, AvailabilityDetail__c
            FROM QuoteLineItem WHERE QuoteId = :cotizacion.Id LIMIT 1
        ];
        Assert.areEqual('Disponible', qli.AvailabilityStatus__c,
            'La revalidación actualiza el estado persistido (GQ-PV-02-019).');
        Assert.isNotNull(qli.AvailabilityDetail__c, 'La leyenda queda en la línea.');
    }

    @isTest
    static void erroresDeEntradaSonClaros() {
        try {
            RepuestosLineService.consultarDisponibilidad('esto no es json');
            Assert.fail('Request ilegible debe lanzar excepción.');
        } catch (RepuestosLineService.RepuestosLineServiceException e) {
            Assert.isTrue(e.getMessage().contains('ilegible'), 'Mensaje claro: ' + e.getMessage());
        }
        try {
            RepuestosLineService.guardarLineas(null, '[]');
            Assert.fail('QuoteId nulo debe lanzar excepción.');
        } catch (RepuestosLineService.RepuestosLineServiceException e) {
            Assert.isTrue(e.getMessage().contains('QuoteId'), 'Mensaje claro: ' + e.getMessage());
        }
        try {
            RepuestosLineService.revalidarLineas(null, 'C101', null);
            Assert.fail('QuoteId nulo debe lanzar excepción.');
        } catch (RepuestosLineService.RepuestosLineServiceException e) {
            Assert.isTrue(e.getMessage().contains('QuoteId'), 'Mensaje claro: ' + e.getMessage());
        }
    }

    @isTest
    static void controllerEntriesDelegateAndWrapErrors() {
        Quote cotizacion = getQuote();
        String req = buildRequest(new List<Map<String, Object>>{
            new Map<String, Object>{ 'productCode' => 'REP-001', 'cantidad' => 1 }
        });

        Test.startTest();
        List<RepuestosLineService.LineaResult> consulta =
            GuidedSellingController.checkRepuestosAvailability(req);
        RepuestosLineService.GuardarResult guardado =
            GuidedSellingController.saveRepuestosLines(cotizacion.Id, JSON.serialize(new List<Object>{
                new Map<String, Object>{ 'productCode' => 'REP-001', 'cantidad' => 1, 'status' => 'Disponible' }
            }));
        List<RepuestosLineService.LineaResult> revalidacion =
            GuidedSellingController.revalidateRepuestosLines(cotizacion.Id, 'C101', 'URUCA');
        Test.stopTest();

        Assert.areEqual(1, consulta.size(), 'Controller devuelve la consulta del servicio.');
        Assert.areEqual(1, guardado.creadas, 'Controller persiste vía el servicio.');
        Assert.areEqual(1, revalidacion.size(), 'Controller revalida vía el servicio.');

        try {
            GuidedSellingController.checkRepuestosAvailability(null);
            Assert.fail('Errores del servicio deben llegar como AuraHandledException.');
        } catch (AuraHandledException e) {
            Assert.isTrue(true, 'La UI nunca recibe stack trace crudo.');
        }
    }
}
