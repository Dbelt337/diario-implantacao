/**
 * All countries. Tests for QuoteOrderService: quote creation from the guided
 * flow (existing lines, fallback by selection, payload parsing, description
 * tracing) and the quote->order->SAP leg (creation, idempotency, error paths).
 * No SeeAllData; pricebook = standard via Test.getStandardPricebookId();
 * callouts never happen (SapMuleClient runs in mock mode).
 */
@isTest
private class QuoteOrderServiceTest {

    @TestSetup
    static void setup() {
        VentasTestDataFactory.createGuidedSellingScenario();
    }

    private static Opportunity getOpp() {
        return [SELECT Id, Name, Pricebook2Id FROM Opportunity LIMIT 1];
    }

    private static PricebookEntry getEntry(String productCode) {
        return [
            SELECT Id, UnitPrice, Product2Id FROM PricebookEntry
            WHERE Product2.ProductCode = :productCode LIMIT 1
        ];
    }

    private static String buildPayload() {
        Map<String, Object> financiamiento = new Map<String, Object>{
            'optionId' => 'OP-TRAD', 'entidad' => 'CrediQ', 'producto' => 'Tradicional',
            'tasaAnual' => 9.5, 'plazoMeses' => 60, 'cuotaMensual' => 246982,
            'montoFinanciado' => 11760000
        };
        return JSON.serialize(new Map<String, Object>{
            'ventaTipo' => 'nuevo',
            'descuento' => 500000,
            'descuentoRequiereAprobacion' => true,
            'descuentoAprobado' => false,
            'formaPago' => 'financiado',
            'prima' => 5040000,
            'vigenciaDias' => 10,
            'financiamiento' => financiamiento,
            'accesoriosPorVehiculo' => new List<Object>{
                new Map<String, Object>{
                    'modelo' => 'Creta',
                    'items' => new List<Object>{
                        // en catálogo (ACC-001): línea por MATCH con el pricebook
                        new Map<String, Object>{ 'id' => 'a1', 'nombre' => 'Barra antivuelco', 'precio' => 250000 },
                        // fuera de catálogo: línea por AUTO-PROVISIÓN
                        new Map<String, Object>{ 'id' => 'a2', 'nombre' => 'Alfombra Premium', 'precio' => 50000 }
                    }
                }
            }
        });
    }

    @isTest
    static void createQuotesHappyPathBuildsQuoteLinesAndDescription() {
        Opportunity opp = getOpp();
        PricebookEntry vehicleEntry = getEntry('VEH-001');
        // los accesorios viajan por el PAYLOAD (flujo real de la venta guiada);
        // la oportunidad solo trae la línea del vehículo
        VentasTestDataFactory.addOpportunityLine(opp.Id, vehicleEntry.Id, 1, vehicleEntry.UnitPrice);
        String selectedVehicles = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'modelo' => 'Creta', 'stockCentral' => 1, 'stockDealer' => 0 }
        });

        Test.startTest();
        List<Quote> quotes = QuoteOrderService.createQuotesSingleVehicle(opp.Id, buildPayload(), selectedVehicles);
        Test.stopTest();

        Assert.areEqual(1, quotes.size(), 'Debe crearse una cotización por vehículo.');
        Quote created = [
            SELECT Id, ExpirationDate, Description, Pricebook2Id,
                   (SELECT Id, Product2.Name FROM QuoteLineItems)
            FROM Quote WHERE Id = :quotes[0].Id
        ];
        Assert.areEqual(Date.today().addDays(10), created.ExpirationDate,
            'vigenciaDias del payload define la vigencia.');
        Assert.isTrue(created.Description.contains('Descuento solicitado'),
            'El descuento debe quedar trazado. Description: ' + created.Description);
        Assert.isTrue(created.Description.contains('Financiado CrediQ Tradicional'),
            'El financiamiento elegido debe quedar trazado. Description: ' + created.Description);
        Assert.isTrue(created.Description.contains('Accesorios (2)'),
            'Los accesorios del vehículo deben quedar trazados. Description: ' + created.Description);
        List<String> lineNames = new List<String>();
        for (QuoteLineItem qli : created.QuoteLineItems) {
            lineNames.add(qli.Product2.Name);
        }
        String lineas = String.join(lineNames, ' | ');
        // tres líneas con nombres DISTINTOS; los asserts por pierna corren
        // ANTES del conteo para que una falla identifique la pierna exacta
        Assert.isTrue(lineas.contains('Hyundai Creta'),
            'FALTA linea del VEHICULO. Hay: ' + lineas);
        Assert.isTrue(lineas.contains('Barra antivuelco'),
            'FALTA linea del accesorio en CATALOGO (match pricebook). Hay: ' + lineas);
        Assert.isTrue(lineas.contains('Alfombra Premium'),
            'FALTA linea del accesorio AUTO-PROVISIONADO. Hay: ' + lineas);
        Assert.areEqual(3, created.QuoteLineItems.size(),
            'Sobran lineas duplicadas. Hay: ' + lineas);
        Assert.areEqual(opp.Pricebook2Id, created.Pricebook2Id,
            'La cotización hereda el pricebook de la oportunidad.');
    }

    @isTest
    static void createQuotesIgnoresUnreadablePayload() {
        Opportunity opp = getOpp();
        PricebookEntry vehicleEntry = getEntry('VEH-001');
        VentasTestDataFactory.addOpportunityLine(opp.Id, vehicleEntry.Id, 1, vehicleEntry.UnitPrice);

        Test.startTest();
        List<Quote> quotes = QuoteOrderService.createQuotesSingleVehicle(opp.Id, 'esto no es json', null);
        Test.stopTest();

        Assert.areEqual(1, quotes.size(), 'Payload ilegible se ignora, la cotización nace igual.');
        Quote created = [SELECT ExpirationDate FROM Quote WHERE Id = :quotes[0].Id];
        Assert.areEqual(Date.today().addDays(15), created.ExpirationDate,
            'Sin vigenciaDias aplica el default de 15 días.');
    }

    @isTest
    static void createQuotesFallbackBuildsVehicleLineFromSelection() {
        Opportunity opp = getOpp();
        String selectedVehicles = JSON.serialize(new List<Object>{
            new Map<String, Object>{ 'modelo' => 'Creta', 'stockCentral' => 0, 'stockDealer' => 0 },
            new Map<String, Object>{ 'modelo' => 'ModeloInexistente', 'stockCentral' => 0, 'stockDealer' => 0 }
        });

        Test.startTest();
        List<Quote> quotes = QuoteOrderService.createQuotesSingleVehicle(opp.Id, null, selectedVehicles);
        Test.stopTest();

        List<OpportunityLineItem> lines = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        Assert.isFalse(lines.isEmpty(),
            'El fallback debe crear la línea de vehículo en la oportunidad.');
        Assert.isFalse(quotes.isEmpty(), 'La cotización nace sobre la línea creada.');
    }

    @isTest
    static void createQuotesRequiresOpportunityId() {
        try {
            QuoteOrderService.createQuotesSingleVehicle(null, null, null);
            Assert.fail('OpportunityId nulo debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('OpportunityId'), 'Mensaje claro: ' + e.getMessage());
        }
    }

    @isTest
    static void createQuotesFailsWhenOpportunityMissing() {
        Opportunity ghost = VentasTestDataFactory.createOpportunity(
            [SELECT Id FROM Account LIMIT 1].Id);
        Id ghostId = ghost.Id;
        delete ghost;
        try {
            QuoteOrderService.createQuotesSingleVehicle(ghostId, null, null);
            Assert.fail('Oportunidad inexistente debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('No se encontraron'), 'Mensaje claro: ' + e.getMessage());
        }
    }

    @isTest
    static void createQuotesResolvesDefaultPricebookAndFailsWithoutVehicles() {
        Pricebook2 vacio = new Pricebook2(Name = 'Catalogo Vacio', IsActive = true);
        insert vacio;
        Opportunity sinCatalogo = VentasTestDataFactory.createOpportunityNoPricebook(
            [SELECT Id FROM Account LIMIT 1].Id);

        try {
            QuoteOrderService.createQuotesSingleVehicle(sinCatalogo.Id, null, null);
            Assert.fail('Pricebook sin vehículos debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('no tiene vehiculos activos'),
                'Mensaje claro: ' + e.getMessage());
        }
        Opportunity refreshed = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :sinCatalogo.Id];
        Assert.areEqual(vacio.Id, refreshed.Pricebook2Id,
            'resolveDefaultPricebookId asigna el primer pricebook custom activo.');
    }

    @isTest
    static void createOrderFromQuoteCreatesOrderAndIsIdempotent() {
        Opportunity opp = getOpp();
        Quote quotation = VentasTestDataFactory.createQuoteWithLine(opp, getEntry('VEH-001'));

        Test.startTest();
        Id orderId = QuoteOrderService.createOrderFromQuote(quotation.Id);
        Id secondCall = QuoteOrderService.createOrderFromQuote(quotation.Id);
        Test.stopTest();

        Assert.areEqual(orderId, secondCall,
            'Idempotencia: la segunda llamada devuelve el mismo pedido, nunca duplica.');
        Assert.areEqual(1, [SELECT COUNT() FROM Order WHERE QuoteId = :quotation.Id],
            'Un pedido por cotización, siempre.');
        Order pedido = [
            SELECT Status, SapStatus__c, QuoteId, OpportunityId, AccountId,
                   (SELECT Id FROM OrderItems)
            FROM Order WHERE Id = :orderId
        ];
        Assert.areEqual('Borrador', pedido.SapStatus__c, 'El ciclo SAP nace en Borrador.');
        Assert.areEqual(1, pedido.OrderItems.size(), 'Una OrderItem por QuoteLineItem.');
        Assert.areEqual(opp.Id, pedido.OpportunityId, 'El pedido referencia la oportunidad.');
        Assert.isNotNull(pedido.Status, 'El pedido nace con el status inicial nativo. Actual: ' + pedido.Status);
    }

    @isTest
    static void createOrderFromQuoteErrorPaths() {
        try {
            QuoteOrderService.createOrderFromQuote(null);
            Assert.fail('QuoteId nulo debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('QuoteId'), 'Mensaje claro: ' + e.getMessage());
        }

        Opportunity opp = getOpp();
        Quote sinLineas = new Quote(
            Name = 'Sin Lineas', OpportunityId = opp.Id, Pricebook2Id = opp.Pricebook2Id);
        insert sinLineas;
        try {
            QuoteOrderService.createOrderFromQuote(sinLineas.Id);
            Assert.fail('Cotización sin líneas debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('no tiene líneas'), 'Mensaje claro: ' + e.getMessage());
        }

        Id borradaId = sinLineas.Id;
        delete sinLineas;
        try {
            QuoteOrderService.createOrderFromQuote(borradaId);
            Assert.fail('Cotización inexistente debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('No se encontró'), 'Mensaje claro: ' + e.getMessage());
        }
    }

    @isTest
    static void sendOrderToSapEnqueuesAndConfirmsInMockMode() {
        Opportunity opp = getOpp();
        Quote quotation = VentasTestDataFactory.createQuoteWithLine(opp, getEntry('VEH-001'));
        Id orderId = QuoteOrderService.createOrderFromQuote(quotation.Id);

        Test.startTest();
        Id jobId = QuoteOrderService.sendOrderToSap(orderId);
        Test.stopTest();

        Assert.isNotNull(jobId, 'Debe encolarse el job de envío a SAP.');
        Order pedido = [SELECT SapStatus__c, SapOrderNumber__c FROM Order WHERE Id = :orderId];
        Assert.areEqual('Confirmado SAP', pedido.SapStatus__c,
            'El mock determinista devuelve documento y confirma. Actual: ' + pedido.SapStatus__c);
        Assert.isTrue(pedido.SapOrderNumber__c != null && pedido.SapOrderNumber__c.startsWith('Z301'),
            'La Z301 queda registrada en el pedido. Actual: ' + pedido.SapOrderNumber__c);
    }

    @isTest
    static void sendOrderToSapRequiresOrderId() {
        try {
            QuoteOrderService.sendOrderToSap(null);
            Assert.fail('OrderId nulo debe lanzar excepción.');
        } catch (QuoteOrderService.QuoteOrderServiceException e) {
            Assert.isTrue(e.getMessage().contains('OrderId'), 'Mensaje claro: ' + e.getMessage());
        }
    }
}
