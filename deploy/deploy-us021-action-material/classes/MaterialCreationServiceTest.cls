/**
 * All countries. Tests for MaterialCreationService and its two invocation
 * doors (US-021): SAP success with local Product2 upsert + catalog entries,
 * idempotent re-run, SAP rejection opening a Case with the raw MENSAJE,
 * input validation without Case, permission gate, invocable bulk contract
 * and the controller entry. Callouts never happen (SapMuleClient mock /
 * HttpCalloutMock).
 */
@isTest
private class MaterialCreationServiceTest {

    private static MaterialCreationService.Request buildRequest(String material) {
        MaterialCreationService.Request req = new MaterialCreationService.Request();
        req.material = material;
        req.sociedad = 'C101';
        req.canal = 'Q1';
        req.serie = 'D22';
        req.verDefault = false;
        return req;
    }

    @isTest
    static void exitoCreaProductoYEntradasYEsIdempotente() {
        MaterialCreationService.bypassPermissionCheck = true;
        MaterialCreationService.Request req = buildRequest('0014-17-411');
        req.pricebookId = Test.getStandardPricebookId();
        req.currencyIsoCode = UserInfo.getDefaultCurrency();

        Test.startTest();
        MaterialCreationService.Result r1 = MaterialCreationService.crearMaterial(req);
        MaterialCreationService.Result r2 = MaterialCreationService.crearMaterial(req);
        Test.stopTest();

        Assert.isTrue(r1.ok, 'El mock SAP crea con los cuatro obligatorios. Mensaje: ' + r1.mensaje);
        Assert.isNotNull(r1.productId, 'Éxito SAP genera el Product2 local.');
        Assert.isNull(r1.caseId, 'Sin rechazo no hay Case.');
        Assert.areEqual(r1.productId, r2.productId,
            'Idempotencia: el mismo código reutiliza el MISMO Product2, nunca duplica.');
        Assert.areEqual(1, [SELECT COUNT() FROM Product2 WHERE ProductCode = '0014-17-411'],
            'Un solo producto por código de material.');
        Assert.areEqual(1, [SELECT COUNT() FROM PricebookEntry
                            WHERE Product2Id = :r1.productId],
            'Entrada del pricebook standard creada una sola vez (precio 0 placeholder).');
    }

    @isTest
    static void rechazoSapAbreCasoConMensajeCrudo() {
        MaterialCreationService.bypassPermissionCheck = true;
        SapMuleClient.mockMode = false;
        Test.setMock(HttpCalloutMock.class, new SapCalloutMockFactory(200,
            '{"ok":false,"mensaje":"Material rechazado: no existe partida arancelaria"}'));

        Test.startTest();
        MaterialCreationService.Result r =
            MaterialCreationService.crearMaterial(buildRequest('0014-99-999'));
        Test.stopTest();

        Assert.isFalse(r.ok, 'Rechazo SAP no crea nada local.');
        Assert.isNotNull(r.caseId, 'US-021: el rechazo levanta Case al área.');
        Case caso = [SELECT Subject, Description FROM Case WHERE Id = :r.caseId];
        Assert.isTrue(caso.Subject.contains('0014-99-999'), 'El caso identifica el material.');
        Assert.isTrue(caso.Description.contains('partida arancelaria'),
            'El MENSAJE de SAP viaja tal cual al caso: ' + caso.Description);
        Assert.areEqual(0, [SELECT COUNT() FROM Product2 WHERE ProductCode = '0014-99-999'],
            'Sin éxito SAP no hay producto local.');
    }

    @isTest
    static void validacionDeEntradaNoAbreCaso() {
        MaterialCreationService.bypassPermissionCheck = true;
        MaterialCreationService.Request sinSerie = buildRequest('0014-17-411');
        sinSerie.serie = null;
        try {
            MaterialCreationService.crearMaterial(sinSerie);
            Assert.fail('Faltar un obligatorio debe lanzar excepción de validación.');
        } catch (MaterialCreationService.MaterialCreationException e) {
            Assert.isTrue(e.getMessage().contains('SERIE'), 'Mensaje claro: ' + e.getMessage());
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Case],
            'La validación local NO es rechazo SAP: no levanta Case.');
    }

    @isTest
    static void sinCustomPermissionBloquea() {
        // bypass en default (false): el gate exige CreateSapMaterial
        try {
            MaterialCreationService.crearMaterial(buildRequest('0014-17-411'));
            Assert.fail('Sin la custom permission la creación debe bloquearse.');
        } catch (MaterialCreationService.MaterialCreationException e) {
            Assert.isTrue(e.getMessage().contains('CreateSapMaterial'),
                'El mensaje nombra el permiso requerido: ' + e.getMessage());
        }
    }

    @isTest
    static void invocableDevuelveUnResultadoPorFilaSinRomperElLote() {
        MaterialCreationService.bypassPermissionCheck = true;
        CreateSapMaterialAction.Request valida = new CreateSapMaterialAction.Request();
        valida.material = '0014-17-411'; valida.sociedad = 'C101';
        valida.canal = 'Q1'; valida.serie = 'D22';
        CreateSapMaterialAction.Request invalida = new CreateSapMaterialAction.Request();
        invalida.material = '0014-17-412'; invalida.sociedad = 'C101'; invalida.canal = 'Q1';

        Test.startTest();
        List<CreateSapMaterialAction.Result> results = CreateSapMaterialAction.crear(
            new List<CreateSapMaterialAction.Request>{ valida, invalida });
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Un Result por Request, en el mismo orden.');
        Assert.isTrue(results[0].ok, 'La fila válida crea. Mensaje: ' + results[0].mensaje);
        Assert.isNotNull(results[0].productId, 'El Id del producto vuelve al flow.');
        Assert.isFalse(results[1].ok, 'La fila sin serie falla SOLA, sin romper el lote.');
        Assert.isTrue(String.isNotBlank(results[1].mensaje),
            'El mensaje de error viaja al fault path del flow.');
    }

    @isTest
    static void controllerEntryDelegaYEnvuelveErrores() {
        MaterialCreationService.bypassPermissionCheck = true;
        String requestJson = JSON.serialize(buildRequest('0014-17-411'));

        Test.startTest();
        MaterialCreationService.Result r = GuidedSellingController.createSapMaterial(requestJson);
        Test.stopTest();

        Assert.isTrue(r.ok, 'El controller devuelve el resultado del servicio.');
        try {
            GuidedSellingController.createSapMaterial('esto no es json');
            Assert.fail('Errores deben llegar a la UI como AuraHandledException.');
        } catch (AuraHandledException e) {
            Assert.isTrue(true, 'La UI nunca recibe stack trace crudo.');
        }
    }
}
