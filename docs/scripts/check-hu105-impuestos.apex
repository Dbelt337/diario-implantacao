// HU-105, impuestos. O que a org ja tem para cobrir a determinacao, a
// visualizacao e o congelamento. Solo lectura.
//
// Tres respostas mudam o desenho inteiro:
//   1. existem objetos NATIVOS de imposto, do Revenue Cloud ou do Billing? Se
//      sim, a tabela de tasas pode nao precisar de Decision Matrix;
//   2. o BRE esta habilitado? A HU-038 ja decidiu Decision Matrix para a tabela
//      de tasas, e a HU-105 consome. Sem BRE, cai tudo;
//   3. onde mora hoje o percentual de imposto da unidade e a condicao fiscal do
//      cliente? A RN-03 depende do cruzamento dos dois.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. OBJETOS NATIVOS DE IMPOSTO ===');
System.debug('   Se existirem, a tabela de tasas pode ser nativa em vez de matriz.');
for (String o : new List<String>{
        'TaxPolicy','TaxTreatment','TaxRate','TaxEngineProvider','TaxTransactionLog',
        'OrderItemTaxLineItem','InvoiceLineTax','CreditMemoLineTax',
        'OrderAdjustmentGroup','OrderDeliveryGroup','ProductTaxPolicy'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    System.debug('   ' + o + ': ' + (t == null ? 'NAO existe'
        : 'existe | consultavel=' + t.getDescribe().isQueryable()
          + ' | campos=' + t.getDescribe().fields.getMap().size()));
}

System.debug('=== 2. BUSINESS RULES ENGINE ===');
for (String o : new List<String>{
        'CalculationMatrix','CalculationMatrixVersion','CalculationMatrixColumn',
        'CalculationMatrixRow','ExpressionSet','ExpressionSetVersion',
        'ExpressionSetDefinition','DecisionMatrixDefinition'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    System.debug('   ' + o + ': ' + (t == null ? 'NAO existe' : 'existe'));
}
try {
    for (SObject m : Database.query('SELECT Name FROM CalculationMatrix LIMIT 20')) {
        System.debug('   matriz ja criada: ' + m.get('Name'));
    }
} catch (Exception e) { System.debug('   sem matrizes ou sem acesso: ' + e.getMessage()); }

System.debug('=== 3. A CONDICAO FISCAL DA UNIDADE ===');
System.debug('   RN-03: o percentual vem do maestro de inventario de SAP.');
for (String o : new List<String>{'Vehicle','VehicleDefinition','Product2','Asset'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    List<String> achados = new List<String>();
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
        if (n.contains('tax') || n.contains('impuesto') || n.contains('iva')
            || n.contains('exoner') || n.contains('fiscal')) {
            achados.add(d.getName() + ' (' + d.getType() + ')');
        }
    }
    System.debug('   ' + o + ': ' + (achados.isEmpty() ? 'NENHUM campo fiscal' : String.valueOf(achados)));
}

System.debug('=== 4. A CONDICAO FISCAL DO CLIENTE ===');
System.debug('   RN-15: a relacao fiscal e cliente x SOCIEDAD, nao cliente x pais.');
for (String o : new List<String>{'Account','BusinessProfile','AccountAccountRelation',
                                 'PartyRoleRelation','TaxIdentification','IdentityDocument'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    List<String> achados = new List<String>();
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
        if (n.contains('tax') || n.contains('impuesto') || n.contains('exoner')
            || n.contains('fiscal') || n.contains('nif') || n.contains('retenc')
            || n.contains('withhold')) {
            achados.add(d.getName());
        }
    }
    System.debug('   ' + o + ': ' + t.getDescribe().fields.getMap().size() + ' campos | fiscais: '
        + (achados.isEmpty() ? 'nenhum' : String.valueOf(achados)));
}

System.debug('=== 5. ONDE O DESGLOSE VAI SER PERSISTIDO ===');
System.debug('   RN-19: o desglose se grava na LINHA, para congelar e para o PDF.');
for (String o : new List<String>{'QuoteLineItem','OrderItem','OpportunityLineItem'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { continue; }
    Integer custom = 0; List<String> fiscais = new List<String>();
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        if (d.isCustom()) { custom++; }
        String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
        if (n.contains('tax') || n.contains('impuesto') || n.contains('retenc')) {
            fiscais.add(d.getName());
        }
    }
    System.debug('   ' + o + ': ' + custom + ' campos custom | fiscais: '
        + (fiscais.isEmpty() ? 'nenhum' : String.valueOf(fiscais)));
}

System.debug('=== 6. O QUE A HU-038 JA PROVE, PARA NAO REPETIR ===');
try {
    Map<String, Schema.SObjectField> pbe = PricebookEntry.SObjectType.getDescribe().fields.getMap();
    for (String c : new List<String>{'PrecioExonerado__c','PrecioExoneradoMinimo__c',
                                     'Gastos__c','PrecioMinimoAsesor__c'}) {
        System.debug('   PricebookEntry.' + c + ': '
            + (pbe.containsKey(c.toLowerCase()) ? 'existe' : 'NAO existe'));
    }
} catch (Exception e) { System.debug('   ' + e.getMessage()); }

System.debug('=== COMO LER ===');
System.debug('   a) se TaxPolicy e TaxTreatment existirem, ha modelo fiscal nativo e a');
System.debug('      tabela de tasas pode sair da matriz para eles. Vale comparar antes');
System.debug('      de construir, pela regra de nao criar sem verificar;');
System.debug('   b) se CalculationMatrix nao existir, o desenho da HU-038 nao para de pe');
System.debug('      e a HU-105 cai junto, porque ela consome a mesma tabela;');
System.debug('   c) se Vehicle nao tiver campo fiscal, falta o destino do percentual que');
System.debug('      a RN-03 diz vir do maestro de inventario de SAP.');
