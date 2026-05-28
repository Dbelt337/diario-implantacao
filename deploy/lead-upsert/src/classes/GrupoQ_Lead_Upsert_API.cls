// GrupoQ Sales Automotive - REST endpoint para criacao/upsert de Leads via canais externos.
// Standard Runtime: a IP e invocada via omnistudio.IntegrationProcedureService.
// DESVIO/NOTA: a assinatura omnistudio.IntegrationProcedureService.runIntegrationService(Type_SubType, input, options)
// foi confirmada para OmniStudio Standard Runtime; validar em DevSales pois a doc oficial nao
// pode ser consultada no ambiente de build. A invocacao da IP fica atras de um seam (IpInvoker)
// para permitir testes deterministicos sem depender da IP ativa.
@RestResource(urlMapping='/grupoq/v1/lead/upsert')
global with sharing class GrupoQ_Lead_Upsert_API {

    @TestVisible
    private static final String IP_TYPE_SUBTYPE = 'GrupoQ_LeadUpsert';

    public static final String ERR_VALIDATION = 'VALIDATION_FAILED';
    public static final String ERR_DEALER_NOT_FOUND = 'DEALER_NOT_FOUND';
    public static final String ERR_INTERNAL = 'INTERNAL_ERROR';
    public static final String ERR_IDEMPOTENCY = 'IDEMPOTENCY_REPLAY';

    // Test seam: substituivel em testes para evitar invocar a IP real.
    @TestVisible
    private static IpInvoker invoker = new StandardRuntimeInvoker();

    @HttpPost
    global static void upsertLead() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        String body = (req != null && req.requestBody != null) ? req.requestBody.toString() : null;
        if (String.isBlank(body)) {
            writeError(res, 400, ERR_VALIDATION, 'Request body is empty', null);
            return;
        }

        Map<String, Object> inputMap;
        try {
            inputMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        } catch (Exception e) {
            writeError(res, 400, ERR_VALIDATION, 'Invalid JSON payload: ' + e.getMessage(), null);
            return;
        }

        String externalRequestId = asString(inputMap.get('externalRequestId'));

        String validationError = validate(inputMap);
        if (validationError != null) {
            writeError(res, 400, ERR_VALIDATION, validationError, externalRequestId);
            return;
        }

        // Idempotency: checa duplicidade ANTES de chamar a IP (resposta limpa em vez de DML exception).
        List<Lead> existing = [
            SELECT Id FROM Lead WHERE ExternalRequestId__c = :externalRequestId LIMIT 1
        ];
        if (!existing.isEmpty()) {
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'status' => 'duplicate',
                'leadId' => null,
                'externalRequestId' => externalRequestId,
                'isDuplicate' => true,
                'duplicateLeadId' => existing[0].Id
            }));
            return;
        }

        // Roteamento da IP por eventName (default: fullUpsert).
        if (!inputMap.containsKey('eventName') || String.isBlank(asString(inputMap.get('eventName')))) {
            inputMap.put('eventName', 'fullUpsert');
        }

        try {
            Map<String, Object> ipResult = invoker.run(
                IP_TYPE_SUBTYPE,
                inputMap,
                new Map<String, Object>{ 'isDebug' => false, 'chainable' => false }
            );
            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(normalizeSuccess(ipResult, externalRequestId)));
        } catch (Exception e) {
            writeError(res, 500, ERR_INTERNAL, e.getMessage(), externalRequestId);
        }
    }

    private static String validate(Map<String, Object> inputMap) {
        if (String.isBlank(asString(inputMap.get('externalRequestId')))) {
            return 'Field \'externalRequestId\' is required';
        }
        if (String.isBlank(asString(inputMap.get('channelCode')))) {
            return 'Field \'channelCode\' is required';
        }
        Object leadObj = inputMap.get('lead');
        if (!(leadObj instanceof Map<String, Object>)) {
            return 'Field \'lead\' is required';
        }
        Map<String, Object> lead = (Map<String, Object>) leadObj;
        if (String.isBlank(asString(lead.get('lastName')))) {
            return 'Field \'lastName\' is required';
        }
        if (String.isBlank(asString(lead.get('company')))) {
            return 'Field \'company\' is required';
        }
        if (String.isBlank(asString(lead.get('leadSource')))) {
            return 'Field \'leadSource\' is required';
        }
        return null;
    }

    // Garante que a resposta de sucesso carregue os campos do contrato, complementando a saida da IP.
    private static Map<String, Object> normalizeSuccess(Map<String, Object> ipResult, String externalRequestId) {
        Map<String, Object> out = (ipResult != null) ? new Map<String, Object>(ipResult) : new Map<String, Object>();
        out.put('status', 'success');
        out.put('externalRequestId', externalRequestId);
        if (!out.containsKey('isDuplicate')) {
            out.put('isDuplicate', false);
        }
        if (!out.containsKey('duplicateLeadId')) {
            out.put('duplicateLeadId', null);
        }
        return out;
    }

    private static void writeError(
        RestResponse res, Integer statusCode, String errorCode, String message, String externalRequestId
    ) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'status' => 'error',
            'errorCode' => errorCode,
            'errorMessage' => message,
            'externalRequestId' => externalRequestId
        }));
    }

    private static String asString(Object value) {
        return (value == null) ? null : String.valueOf(value);
    }

    public interface IpInvoker {
        Map<String, Object> run(String typeSubType, Map<String, Object> input, Map<String, Object> options);
    }

    private class StandardRuntimeInvoker implements IpInvoker {
        public Map<String, Object> run(String typeSubType, Map<String, Object> input, Map<String, Object> options) {
            return (Map<String, Object>) omnistudio.IntegrationProcedureService.runIntegrationService(
                typeSubType, input, options
            );
        }
    }
}
