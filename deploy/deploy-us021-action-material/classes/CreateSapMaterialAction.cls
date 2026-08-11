/**
 * All countries. US-021: puerta DECLARATIVA del alta de material SAP —
 * expone MaterialCreationService como acción invocable para Flow / Screen
 * Flow / Quick Action del dominio de catálogo (el flujo de venta usa el
 * botón del grid HU-043; esta acción es para el backoffice). Bulk-safe:
 * un Result por Request, en el mismo orden; una fila con error NUNCA rompe
 * el lote (fault path del flow decide con ok/mensaje/caseId).
 */
public with sharing class CreateSapMaterialAction {

    @InvocableMethod(label='Crear material SAP (US-021)'
        description='Crea el material en SAP vía ZQEV_DBM_CREACION_MATERIALES (gateway MuleGateway); en éxito hace upsert del Product2 local, en rechazo levanta Case al área con el MENSAJE de SAP.'
        category='Repuestos y PA')
    public static List<Result> crear(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            try {
                MaterialCreationService.Request svcReq = new MaterialCreationService.Request();
                svcReq.material = req.material;
                svcReq.sociedad = req.sociedad;
                svcReq.canal = req.canal;
                svcReq.serie = req.serie;
                svcReq.verDefault = req.verDefault;
                svcReq.pricebookId = req.pricebookId;
                svcReq.currencyIsoCode = req.currencyIsoCode;

                MaterialCreationService.Result r = MaterialCreationService.crearMaterial(svcReq);
                res.ok = r.ok;
                res.mensaje = r.mensaje;
                res.productId = r.productId;
                res.caseId = r.caseId;
            } catch (Exception e) {
                res.ok = false;
                res.mensaje = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Código de material (MATNR)' required=true)
        public String material;
        @InvocableVariable(label='Sociedad (BUKRS)' required=true)
        public String sociedad;
        @InvocableVariable(label='Canal de distribución (VTWEG)' required=true)
        public String canal;
        @InvocableVariable(label='Serie (obligatoria para ZREP)' required=true)
        public String serie;
        @InvocableVariable(label='Versión por defecto (VER_DEFAULT = X)')
        public Boolean verDefault;
        @InvocableVariable(label='Pricebook destino (opcional, para la entrada local)')
        public Id pricebookId;
        @InvocableVariable(label='Moneda ISO (con el pricebook)')
        public String currencyIsoCode;
    }

    public class Result {
        @InvocableVariable(label='Éxito')
        public Boolean ok;
        @InvocableVariable(label='Mensaje (SAP o validación)')
        public String mensaje;
        @InvocableVariable(label='Id del Product2 local')
        public Id productId;
        @InvocableVariable(label='Id del Case (cuando SAP rechaza)')
        public Id caseId;
    }
}
