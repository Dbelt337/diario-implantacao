// HU-105 parte 3: a frente de Sales. Catalogo e venda guiada. Solo lectura.
//
// Os logs de 18/08 mostraram que o modelo fiscal nativo NAO esta na org, mas
// mostraram outra coisa: as matrizes Price Book Entries V2, Volume Discount
// Entries, Attribute Discount Entries, Derived Pricing Entries e Contract
// Pricing Entries. Essas sao as lookup tables padrao do Salesforce Pricing.
// Se o motor de precos estiver ligado, o imposto NAO e um Expression Set
// separado chamado por Apex: e um elemento dentro do pricing procedure, que
// a documentacao descreve como sendo ele mesmo um Expression Set.
// Isso apaga uma classe Apex inteira da HU-105, entao tem que ser verificado.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. O MOTOR DE PRECOS DO SALES ESTA LIGADO ===');
for (String o : new List<String>{
        'ContextDefinition','ExpressionSetDefinition','PricingProcedure',
        'PriceAdjustmentSchedule','PriceAdjustmentTier','AttributeBasedAdjustment',
        'ProductSellingModel','ProductClassification','ProductAttributeDefinition',
        'ProductRelatedComponent','ProductCategory','ProductCategoryProduct'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    Integer q = -1;
    try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) { q = -1; }
    System.debug('   ' + o + ': existe | criavel=' + t.getDescribe().isCreateable()
        + ' | registros=' + (q < 0 ? 'sem acesso' : String.valueOf(q)));
}

System.debug('=== 2. O DESGLOSE JA TEM CASA NATIVA ===');
System.debug('   Se QuoteLineDetail existir, o desglose da RN-19 pode nao virar');
System.debug('   sete campos custom em QuoteLineItem.');
for (String o : new List<String>{
        'QuoteLineDetail','QuoteLinePriceAdjustment','QuoteLineRateAdjustment',
        'OrderItemDetail','OrderAdjustmentGroup'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    System.debug('   ' + o + ': existe | criavel=' + t.getDescribe().isCreateable()
        + ' | campos=' + t.getDescribe().fields.getMap().size());
}
System.debug('   --- campos de preco que o motor escreve na linha ---');
Map<String, Schema.SObjectField> qli = QuoteLineItem.SObjectType.getDescribe().fields.getMap();
for (String c : new List<String>{'NetUnitPrice','TotalLineAmount','TotalPrice','Subtotal',
                                 'AdjustmentAmount','PricebookEntryId','ProductSellingModelId'}) {
    System.debug('   QuoteLineItem.' + c + ': ' + (qli.containsKey(c.toLowerCase()) ? 'existe' : 'nao existe'));
}
System.debug('   total de campos em QuoteLineItem: ' + qli.size());

System.debug('=== 3. A MATRIZ DE IMPOSTOS QUE JA EXISTE ===');
System.debug('   MatrizImpuestosReferencia apareceu no log de 18/08. Antes de');
System.debug('   desenhar tabela de tasas, ver o que ela ja tem dentro.');
try {
    Map<String, Schema.SObjectField> cm = g.get('calculationmatrix').getDescribe().fields.getMap();
    List<String> cols = new List<String>{'Id','Name'};
    for (String k : cm.keySet()) {
        String nm = cm.get(k).getDescribe().getName(); String nl = nm.toLowerCase();
        if (nl.contains('status') || nl.contains('type') || nl.contains('start')
            || nl.contains('end') || nl.contains('description')) { cols.add(nm); }
    }
    for (SObject m : Database.query('SELECT ' + String.join(cols, ', ')
            + ' FROM CalculationMatrix ORDER BY Name')) {
        String l = '';
        for (String c : cols) { if (m.get(c) != null) { l += c + '=' + m.get(c) + ' | '; } }
        System.debug('   ' + l);
    }
} catch (Exception e) { System.debug('   CalculationMatrix: ' + e.getMessage()); }
try {
    for (SObject c : Database.query(
            'SELECT Name, CalculationMatrixVersion.CalculationMatrix.Name'
            + ' FROM CalculationMatrixColumn'
            + ' WHERE CalculationMatrixVersion.CalculationMatrix.Name LIKE \'%mpuesto%\'')) {
        System.debug('   coluna da matriz de impostos: ' + c.get('Name'));
    }
} catch (Exception e) { System.debug('   colunas: ' + e.getMessage()); }

System.debug('=== 4. OS EXPRESSION SETS E OS PRICING PROCEDURES ===');
try {
    Map<String, Schema.SObjectField> es = g.get('expressionset').getDescribe().fields.getMap();
    List<String> cols = new List<String>{'Id','Name'};
    for (String k : es.keySet()) {
        String nm = es.get(k).getDescribe().getName(); String nl = nm.toLowerCase();
        if (nl.contains('usage') || nl.contains('type') || nl.contains('status')
            || nl.contains('interface') || nl.contains('context')) { cols.add(nm); }
    }
    for (SObject e : Database.query('SELECT ' + String.join(cols, ', ')
            + ' FROM ExpressionSet ORDER BY Name')) {
        String l = '';
        for (String c : cols) { if (e.get(c) != null) { l += c + '=' + e.get(c) + ' | '; } }
        System.debug('   ' + l);
    }
} catch (Exception e) { System.debug('   ExpressionSet: ' + e.getMessage()); }
System.debug('   PROCURAR: um expression set com uso de Pricing. Se houver, o');
System.debug('   imposto entra como elemento nele, e nao como classe Apex nova.');

System.debug('=== 5. O CATALOGO ===');
try {
    for (AggregateResult a : Database.query(
            'SELECT Family f, COUNT(Id) q FROM Product2 GROUP BY Family ORDER BY COUNT(Id) DESC LIMIT 20')) {
        System.debug('   familia ' + a.get('f') + ' | ' + a.get('q'));
    }
} catch (Exception e) { System.debug('   Product2: ' + e.getMessage()); }
try {
    for (SObject p : Database.query('SELECT Name, IsActive FROM Pricebook2 ORDER BY Name LIMIT 30')) {
        System.debug('   price book: ' + p.get('Name') + ' | ativo=' + p.get('IsActive'));
    }
} catch (Exception e) { System.debug('   Pricebook2: ' + e.getMessage()); }

System.debug('=== COMO LER ===');
System.debug('   a) ContextDefinition existindo, todo campo fiscal novo precisa ser');
System.debug('      declarado no contexto para o motor enxergar. E tarefa que nao');
System.debug('      estava em nenhuma lista e sem ela o campo nao chega no calculo;');
System.debug('   b) QuoteLineDetail existindo, o desglose da RN-19 pode ser nativo;');
System.debug('   c) MatrizImpuestosReferencia com colunas de pais e tasa ja e a');
System.debug('      tabela da RN-02, e nesse caso nao se cria nenhuma;');
System.debug('   d) expression set com uso de Pricing e o lugar do imposto, e ai');
System.debug('      TaxDeterminationService deixa de existir.');
