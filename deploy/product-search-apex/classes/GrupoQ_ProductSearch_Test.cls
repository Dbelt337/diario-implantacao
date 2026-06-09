@isTest
private class GrupoQ_ProductSearch_Test {
    @isTest static void testSearchFindsActiveProduct() {
        insert new Product2(Name='Honda Test CR-V', ProductCode='HC-TEST-1', Family='Autos', IsActive=true);
        insert new Product2(Name='Inactivo Test', ProductCode='IN-TEST-1', Family='Autos', IsActive=false);

        GrupoQ_ProductSearch svc = new GrupoQ_ProductSearch();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>{
            'input'  => new Map<String, Object>{ 'searchText' => 'Honda', 'limit' => 10 },
            'output' => output,
            'options'=> new Map<String, Object>()
        };
        Test.startTest();
        Object res = svc.call('searchProducts', args);
        Test.stopTest();

        System.assertEquals(true, res);
        System.assertEquals(1, output.get('totalFound'), 'So o produto ativo deve voltar');
    }

    @isTest static void testNoResultAndShortTerm() {
        GrupoQ_ProductSearch svc = new GrupoQ_ProductSearch();
        Map<String, Object> out1 = new Map<String, Object>();
        svc.call('searchProducts', new Map<String, Object>{ 'input' => new Map<String, Object>{ 'searchText' => 'zzzznope' }, 'output' => out1 });
        System.assertEquals(0, out1.get('totalFound'));

        Map<String, Object> out2 = new Map<String, Object>();
        svc.call('searchProducts', new Map<String, Object>{ 'input' => new Map<String, Object>{ 'searchText' => 'a' }, 'output' => out2 });
        System.assertEquals(0, out2.get('totalFound'), 'Menos de 2 chars nao busca');
    }
}
