/**
 * All countries. US-021 (creación de código inexistente): capa de negocio del
 * alta de material SAP, invocada desde el flujo guiado vía
 * GuidedSellingController.createSapMaterial por sus dos caminos de entrada —
 * búsqueda sin resultado (captura individual) y línea sinCatalogo del grid
 * (carga masiva). Llama ZQEV_DBM_CREACION_MATERIALES vía la fachada
 * SapMuleClient (mock hasta cerrar el contrato Mule).
 *
 * Comportamiento:
 *  - Éxito SAP: upsert del Product2 local por SapMaterialCode__c (external
 *    id único — atómico ante concurrencia) y, si se informa
 *    el pricebook de la venta, alta de PricebookEntry (standard + lista de
 *    la cotización) con precio 0 — el precio real de repuestos viene de SAP
 *    en la consulta (el catálogo de precios es US-024/US-025).
 *  - Rechazo SAP (MENSAJE de error): se levanta Case al área con el mensaje
 *    tal cual (regla de la US-021); no se crea nada local.
 *  - Gobernanza: exige la custom permission CreateSapMaterial (permission
 *    set PS_Create_SAP_Material) en cualquiera de las puertas.
 */
public with sharing class MaterialCreationService {

    /** Seam de test (mismo patrón que SapMuleClient.mockMode). */
    @TestVisible private static Boolean bypassPermissionCheck = false;

    public static Result crearMaterial(Request req) {
        if (!bypassPermissionCheck && !FeatureManagement.checkPermission('CreateSapMaterial')) {
            throw new MaterialCreationException(
                'Sin permiso para crear materiales SAP (custom permission CreateSapMaterial).');
        }
        validar(req);

        SapMuleClient.MaterialCreateRequest sapReq = new SapMuleClient.MaterialCreateRequest();
        sapReq.material = req.material.trim();
        sapReq.sociedad = req.sociedad.trim();
        sapReq.canal = req.canal.trim();
        sapReq.serie = req.serie.trim();
        sapReq.verDefault = req.verDefault == true;

        SapMuleClient.MaterialCreateResult sap = SapMuleClient.creacionMateriales(sapReq);

        Result r = new Result();
        r.ok = sap != null && sap.ok == true;
        r.mensaje = sap == null ? 'Sin respuesta del gateway.' : sap.mensaje;
        if (r.ok) {
            r.productId = upsertProducto(sapReq.material);
            if (req.pricebookId != null) {
                asegurarEntradas(r.productId, req.pricebookId, req.currencyIsoCode);
            }
        } else {
            r.caseId = abrirCaso(sapReq, r.mensaje);
        }
        return r;
    }

    // ---------- helpers ----------

    private static void validar(Request req) {
        if (req == null || String.isBlank(req.material) || String.isBlank(req.sociedad)
                || String.isBlank(req.canal) || String.isBlank(req.serie)) {
            // regla del doc SAP: MATERIAL, SOCIEDAD, CANAL y SERIE obligatorios
            // (los ZREP exigen serie); se valida ANTES de llamar al gateway
            throw new MaterialCreationException(
                'MATERIAL, SOCIEDAD, CANAL y SERIE son obligatorios para crear el material.');
        }
    }

    /**
     * Un solo Product2 por material, garantizado por la BASE DE DATOS y no
     * por un chequeo en Apex: SapMaterialCode__c es único + External ID, y
     * Database.upsert por ese campo es atómico — dos usuarios creando el
     * mismo código a la vez convergen en el MISMO registro (el patrón
     * query-luego-insert tenía una ventana de carrera que duplicaba
     * productos). Los productos legados de la réplica (solo ProductCode)
     * se reutilizan y se les rellena el código SAP.
     */
    private static Id upsertProducto(String materialCode) {
        List<Product2> existentes = [
            SELECT Id, IsActive, SapMaterialCode__c FROM Product2
            WHERE SapMaterialCode__c = :materialCode OR ProductCode = :materialCode
            ORDER BY SapMaterialCode__c NULLS LAST
            LIMIT 1
        ];
        if (!existentes.isEmpty()) {
            Product2 existente = existentes[0];
            Boolean cambio = false;
            if (existente.SapMaterialCode__c == null) {
                existente.SapMaterialCode__c = materialCode;
                cambio = true;
            }
            if (!existente.IsActive) {
                existente.IsActive = true;
                cambio = true;
            }
            if (cambio) { update existente; }
            return existente.Id;
        }
        Product2 producto = new Product2(
            Name = materialCode,
            ProductCode = materialCode,
            SapMaterialCode__c = materialCode,
            IsActive = true,
            Description = 'Material creado en SAP vía ZQEV_DBM_CREACION_MATERIALES (US-021). '
                + 'Nombre y ficha llegan por la réplica de catálogo.'
        );
        Database.UpsertResult resultado = Database.upsert(producto, Product2.SapMaterialCode__c, false);
        if (resultado.isSuccess()) {
            return resultado.getId();
        }
        // perdió la carrera contra otra transacción (DUPLICATE_VALUE):
        // el registro ya existe — se reutiliza
        return [SELECT Id FROM Product2 WHERE SapMaterialCode__c = :materialCode LIMIT 1].Id;
    }

    /**
     * Entradas de catálogo local para que la línea del grid HU-043 deje de
     * estar sinCatalogo. Precio 0: el precio de repuestos lo informa SAP en
     * la consulta de la línea; la lista local es soporte del modelo nativo
     * (toda QuoteLineItem apunta a un PricebookEntry).
     */
    private static void asegurarEntradas(Id productId, Id pricebookId, String currencyIsoCode) {
        Id estandarId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        List<PricebookEntry> existentes = [
            SELECT Id, Pricebook2Id FROM PricebookEntry
            WHERE Product2Id = :productId AND CurrencyIsoCode = :currencyIsoCode
              AND (Pricebook2Id = :estandarId OR Pricebook2Id = :pricebookId)
        ];
        Boolean hayEstandar = false;
        Boolean hayLista = false;
        for (PricebookEntry pbe : existentes) {
            if (pbe.Pricebook2Id == estandarId) { hayEstandar = true; }
            if (pbe.Pricebook2Id == pricebookId) { hayLista = true; }
        }
        if (!hayEstandar) {
            insert new PricebookEntry(Pricebook2Id = estandarId, Product2Id = productId,
                UnitPrice = 0, IsActive = true, CurrencyIsoCode = currencyIsoCode);
        }
        if (!hayLista && pricebookId != estandarId) {
            insert new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productId,
                UnitPrice = 0, IsActive = true, UseStandardPrice = false,
                CurrencyIsoCode = currencyIsoCode);
        }
    }

    /** US-021: "si no se puede crear, se levanta caso al área" — con el MENSAJE SAP tal cual. */
    private static Id abrirCaso(SapMuleClient.MaterialCreateRequest req, String mensajeSap) {
        try {
            Case caso = new Case(
                Subject = ('Creación de material SAP rechazada: ' + req.material).abbreviate(255),
                Description = 'Solicitud de creación de material rechazada por SAP.\n'
                    + 'Material: ' + req.material + '\nSociedad: ' + req.sociedad
                    + '\nCanal: ' + req.canal + '\nSerie: ' + req.serie
                    + '\nVER_DEFAULT: ' + (req.verDefault == true ? 'X' : '-')
                    + '\n\nMENSAJE SAP: ' + mensajeSap
            );
            insert caso;
            return caso.Id;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Caso de rechazo no creado: ' + e.getMessage());
            return null;
        }
    }

    // ---------- DTOs ----------

    public class Request {
        @AuraEnabled public String material;
        @AuraEnabled public String sociedad;
        @AuraEnabled public String canal;
        @AuraEnabled public String serie;
        @AuraEnabled public Boolean verDefault;
        @AuraEnabled public Id pricebookId;
        @AuraEnabled public String currencyIsoCode;
    }

    public class Result {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String mensaje;
        @AuraEnabled public Id productId;
        @AuraEnabled public Id caseId;
    }

    public class MaterialCreationException extends Exception {}
}
