@isTest
private class GrupoQ_CrearCotizacionTest {

    private static Map<String, Object> run(String contextId) {
        Map<String, Object> input  = new Map<String, Object>();
        if (contextId != null) input.put('ContextId', contextId);
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input'   => input,
            'output'  => output,
            'options' => new Map<String, Object>()
        };
        Object res = new GrupoQ_CrearCotizacion().call('crearCotizacion', args);
        output.put('__res', res);
        return output;
    }

    @isTest
    static void creaDesdeCuenta() {
        // Business account; el path 001 es el mismo que usa Person Account.
        Account a = new Account(Name = 'Cuenta Test');
        insert a;

        Test.startTest();
        Map<String, Object> out = run(a.Id);
        Test.stopTest();

        System.assertEquals(true, out.get('__res'), (String) out.get('error'));
        Id quoteId = (Id) out.get('quoteId');
        System.assertNotEquals(null, quoteId);
        Quote q = [SELECT AccountId, Status FROM Quote WHERE Id = :quoteId];
        System.assertEquals(a.Id, q.AccountId);
        System.assertEquals('Draft', q.Status);
    }

    @isTest
    static void creaDesdeOportunidad() {
        Account a = new Account(Name = 'Cuenta Test 2');
        insert a;
        Opportunity o = new Opportunity(
            Name = 'Op Test', AccountId = a.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(15));
        insert o;

        Test.startTest();
        Map<String, Object> out = run(o.Id);
        Test.stopTest();

        System.assertEquals(true, out.get('__res'), (String) out.get('error'));
        Quote q = [SELECT OpportunityId, AccountId FROM Quote WHERE Id = :((Id) out.get('quoteId'))];
        System.assertEquals(o.Id, q.OpportunityId);
        System.assertEquals(a.Id, q.AccountId); // derivado de la Opp
    }

    @isTest
    static void contextoInvalido() {
        // Un Id de usuario (prefijo 005) no es Cuenta ni Oportunidad.
        Map<String, Object> out = run(UserInfo.getUserId());
        System.assertEquals(false, out.get('__res'));
        System.assertNotEquals(null, out.get('error'));
    }

    @isTest
    static void faltaContext() {
        Map<String, Object> out = run(null);
        System.assertEquals(false, out.get('__res'));
        System.assertNotEquals(null, out.get('error'));
    }

    @isTest
    static void metodoNoSoportado() {
        Map<String, Object> output = new Map<String, Object>();
        Boolean res = new GrupoQ_CrearCotizacion().invokeMethod(
            'noExiste', new Map<String, Object>(), output, new Map<String, Object>());
        System.assertEquals(false, res);
        System.assertNotEquals(null, output.get('error'));
    }
}
