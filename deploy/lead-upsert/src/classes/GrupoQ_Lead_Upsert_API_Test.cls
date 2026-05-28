// GrupoQ Sales Automotive - testes do endpoint REST de upsert de Leads.
// A invocacao da IP e mockada via seam GrupoQ_Lead_Upsert_API.invoker, garantindo
// cobertura deterministica sem depender da Integration Procedure estar ativa na org.
@IsTest
private class GrupoQ_Lead_Upsert_API_Test {

    private static final String EXISTING_REQ_ID = '550e8400-e29b-41d4-a716-446655440000';

    private class MockInvoker implements GrupoQ_Lead_Upsert_API.IpInvoker {
        private Map<String, Object> toReturn;
        private Boolean doThrow;
        MockInvoker(Map<String, Object> toReturn, Boolean doThrow) {
            this.toReturn = toReturn;
            this.doThrow = doThrow;
        }
        public Map<String, Object> run(String typeSubType, Map<String, Object> input, Map<String, Object> options) {
            if (doThrow) {
                throw new CalloutException('Simulated IP failure');
            }
            return toReturn;
        }
    }

    private static RestResponse invoke(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/grupoq/v1/lead/upsert';
        req.httpMethod = 'POST';
        if (jsonBody != null) {
            req.requestBody = Blob.valueOf(jsonBody);
        }
        RestContext.request = req;
        RestContext.response = new RestResponse();
        GrupoQ_Lead_Upsert_API.upsertLead();
        return RestContext.response;
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    private static Map<String, Object> bodyMap(RestResponse res) {
        return (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
    }

    @IsTest
    static void testFullUpsert_Success() {
        GrupoQ_Lead_Upsert_API.invoker = new MockInvoker(new Map<String, Object>{
            'leadId' => '00Q5h00000ABCDEF',
            'createdLineItems' => 1,
            'createdPreferredSellers' => 1
        }, false);

        String payload = JSON.serialize(new Map<String, Object>{
            'externalRequestId' => 'aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa',
            'channelCode' => 'MULESOFT_FB',
            'lead' => new Map<String, Object>{
                'firstName' => 'Juan', 'lastName' => 'Perez', 'email' => 'juan@email.com',
                'company' => 'Persona Fisica', 'leadSource' => 'WEB_FORLAND_LURUCA'
            },
            'lineItems' => new List<Object>{ new Map<String, Object>{ 'productCode' => 'FORLAND-T3-2026', 'quantity' => 1 } },
            'preferredSellers' => new List<Object>{ new Map<String, Object>{ 'dealerCode' => 'C105-LURUCA-FORLAND', 'preferredSellerType' => 'Dealer' } }
        });

        Test.startTest();
        RestResponse res = invoke(payload);
        Test.stopTest();

        System.assertEquals(201, res.statusCode, 'Esperado 201 Created');
        Map<String, Object> out = bodyMap(res);
        System.assertEquals('success', out.get('status'));
        System.assertEquals('00Q5h00000ABCDEF', out.get('leadId'));
        System.assertEquals(false, out.get('isDuplicate'));
    }

    @IsTest
    static void testCreateLeadOnly_Success() {
        GrupoQ_Lead_Upsert_API.invoker = new MockInvoker(new Map<String, Object>{
            'leadId' => '00Q5h00000ONLYLD'
        }, false);

        String payload = JSON.serialize(new Map<String, Object>{
            'externalRequestId' => 'bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb',
            'channelCode' => 'SHOWROOM',
            'lead' => new Map<String, Object>{
                'lastName' => 'Lopez', 'company' => 'Persona Fisica', 'leadSource' => 'SHOWROOM_SJO'
            }
        });

        Test.startTest();
        RestResponse res = invoke(payload);
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        Map<String, Object> out = bodyMap(res);
        System.assertEquals('success', out.get('status'));
        System.assertEquals('00Q5h00000ONLYLD', out.get('leadId'));
    }

    @IsTest
    static void testInvalidJSON() {
        Test.startTest();
        RestResponse res = invoke('{ this is not valid json ');
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> out = bodyMap(res);
        System.assertEquals('error', out.get('status'));
        System.assertEquals(GrupoQ_Lead_Upsert_API.ERR_VALIDATION, out.get('errorCode'));
    }

    @IsTest
    static void testIdempotency() {
        insert new Lead(
            LastName = 'Duplicado', Company = 'Persona Fisica',
            LeadSource = 'WEB_FORLAND_LURUCA', ExternalRequestId__c = EXISTING_REQ_ID
        );

        String payload = JSON.serialize(new Map<String, Object>{
            'externalRequestId' => EXISTING_REQ_ID,
            'channelCode' => 'MULESOFT_FB',
            'lead' => new Map<String, Object>{
                'lastName' => 'Duplicado', 'company' => 'Persona Fisica', 'leadSource' => 'WEB_FORLAND_LURUCA'
            }
        });

        Test.startTest();
        RestResponse res = invoke(payload);
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Replay deve retornar 200 OK');
        Map<String, Object> out = bodyMap(res);
        System.assertEquals('duplicate', out.get('status'));
        System.assertEquals(true, out.get('isDuplicate'));
        System.assertNotEquals(null, out.get('duplicateLeadId'));
    }

    @IsTest
    static void testMissingRequiredField() {
        String payload = JSON.serialize(new Map<String, Object>{
            'externalRequestId' => 'cccccccc-3333-4333-8333-cccccccccccc',
            'channelCode' => 'INBOT',
            'lead' => new Map<String, Object>{
                'company' => 'Persona Fisica', 'leadSource' => 'WHATSAPP_CREDIQ'
            }
        });

        Test.startTest();
        RestResponse res = invoke(payload);
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> out = bodyMap(res);
        System.assertEquals(GrupoQ_Lead_Upsert_API.ERR_VALIDATION, out.get('errorCode'));
        System.assert(((String) out.get('errorMessage')).contains('lastName'), 'Mensagem deve citar lastName');
    }

    @IsTest
    static void testDealerNotFound_LeadStillCreated() {
        // Dealer inexistente: a IP resolve resolvedAccountId=null mas ainda cria o Lead.
        GrupoQ_Lead_Upsert_API.invoker = new MockInvoker(new Map<String, Object>{
            'leadId' => '00Q5h00000NODLER',
            'createdLineItems' => 0,
            'createdPreferredSellers' => 0
        }, false);

        String payload = JSON.serialize(new Map<String, Object>{
            'externalRequestId' => 'dddddddd-4444-4444-8444-dddddddddddd',
            'channelCode' => 'LEXISNEXIS',
            'lead' => new Map<String, Object>{
                'lastName' => 'SinDealer', 'company' => 'Persona Fisica', 'leadSource' => 'LEXISNEXIS_PUSH'
            },
            'preferredSellers' => new List<Object>{ new Map<String, Object>{ 'dealerCode' => 'INEXISTENTE-999', 'preferredSellerType' => 'Dealer' } }
        });

        Test.startTest();
        RestResponse res = invoke(payload);
        Test.stopTest();

        System.assertEquals(201, res.statusCode);
        Map<String, Object> out = bodyMap(res);
        System.assertEquals('00Q5h00000NODLER', out.get('leadId'));
        System.assertEquals(0, out.get('createdPreferredSellers'));
    }

    @IsTest
    static void testInternalError() {
        GrupoQ_Lead_Upsert_API.invoker = new MockInvoker(null, true);

        String payload = JSON.serialize(new Map<String, Object>{
            'externalRequestId' => 'eeeeeeee-5555-4555-8555-eeeeeeeeeeee',
            'channelCode' => 'CYBERFUEL_WEB',
            'lead' => new Map<String, Object>{
                'lastName' => 'Falla', 'company' => 'Persona Fisica', 'leadSource' => 'CYBERFUEL'
            }
        });

        Test.startTest();
        RestResponse res = invoke(payload);
        Test.stopTest();

        System.assertEquals(500, res.statusCode);
        Map<String, Object> out = bodyMap(res);
        System.assertEquals(GrupoQ_Lead_Upsert_API.ERR_INTERNAL, out.get('errorCode'));
    }

    @IsTest
    static void testEmptyBody() {
        Test.startTest();
        RestResponse res = invoke(null);
        Test.stopTest();

        System.assertEquals(400, res.statusCode);
        Map<String, Object> out = bodyMap(res);
        System.assertEquals(GrupoQ_Lead_Upsert_API.ERR_VALIDATION, out.get('errorCode'));
    }
}
