// HU-064, motor de descuentos. O que a org JA TEM antes de propor. Solo lectura.
//
// O log de 18/08 mostrou duas matrizes que a HU nao menciona: Discount_Rules_GrupoQ
// e MatrizPisosPorRol. A HU propoe Custom Metadata Type para a escala e para o rango
// do rol, e diz que o uso de Decision Matrix exige confirmar a disponibilidade na org.
// Ela esta disponivel e ja tem duas matrizes de desconto construidas. Isso decide o
// desenho, e nao pode ser resolvido por opiniao.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. AS MATRIZES DE DESCONTO QUE JA EXISTEM ===');
try {
    for (SObject m : Database.query(
            'SELECT Id, Name FROM CalculationMatrix ORDER BY Name')) {
        System.debug('   matriz: ' + m.get('Name') + ' | ' + m.get('Id'));
    }
    for (SObject c : Database.query(
            'SELECT Name, CalculationMatrixVersion.CalculationMatrix.Name m'
            + ' FROM CalculationMatrixColumn'
            + ' WHERE CalculationMatrixVersion.CalculationMatrix.Name IN'
            + ' (\'Discount_Rules_GrupoQ\', \'MatrizPisosPorRol\')'
            + ' ORDER BY CalculationMatrixVersion.CalculationMatrix.Name')) {
        SObject v = c.getSObject('CalculationMatrixVersion');
        System.debug('   coluna | ' + (v == null ? '?' : String.valueOf(v.getSObject('CalculationMatrix').get('Name')))
            + ' -> ' + c.get('Name'));
    }
    for (AggregateResult a : Database.query(
            'SELECT CalculationMatrixVersion.CalculationMatrix.Name m, COUNT(Id) q'
            + ' FROM CalculationMatrixRow GROUP BY CalculationMatrixVersion.CalculationMatrix.Name')) {
        System.debug('   linhas na matriz ' + a.get('m') + ': ' + a.get('q'));
    }
} catch (Exception e) { System.debug('   ' + e.getMessage()); }
System.debug('   SE Discount_Rules_GrupoQ e MatrizPisosPorRol ja cobrirem marca,');
System.debug('   modelo, sociedade e rol, a HU nao cria Custom Metadata nenhum.');

System.debug('=== 2. ONDE O DESCONTO MORA HOJE NO DOCUMENTO ===');
for (String o : new List<String>{'Quote','QuoteLineItem','Order','OrderItem','Opportunity','OpportunityLineItem'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    List<String> achados = new List<String>();
    Integer custom = 0;
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        if (d.isCustom()) { custom++; }
        String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
        if (n.contains('discount') || n.contains('descuento') || n.contains('cashback')
            || n.contains('margin') || n.contains('margen') || n.contains('cost')) {
            achados.add(d.getName() + (d.isCustom() ? ' (custom)' : ''));
        }
    }
    System.debug('   ' + o + ': ' + custom + ' custom | ' + String.valueOf(achados));
}

System.debug('=== 3. A BASE DE CALCULO DA ESCALA ===');
System.debug('   RN5: todos os niveis se calculam sobre o Precio Minimo de Asesor.');
Map<String, Schema.SObjectField> pbe = PricebookEntry.SObjectType.getDescribe().fields.getMap();
for (String c : new List<String>{'PrecioMinimoAsesor__c','PrecioExoneradoMinimo__c',
                                 'PrecioExonerado__c','Gastos__c'}) {
    System.debug('   PricebookEntry.' + c + ': ' + (pbe.containsKey(c.toLowerCase()) ? 'existe' : 'NAO existe'));
}
List<String> cash = new List<String>();
for (Schema.SObjectField f : pbe.values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (!d.isCustom()) { continue; }
    String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
    if (n.contains('cashback') || n.contains('bono') || n.contains('vigen')) { cash.add(d.getName()); }
}
System.debug('   PricebookEntry, campos de cashback ou vigencia: '
    + (cash.isEmpty() ? 'NENHUM, a RN11 nao tem onde morar' : String.valueOf(cash)));

System.debug('=== 4. MARCA E MODELO, AS CHAVES DA ESCALA ===');
for (String o : new List<String>{'BusinessBrand','VehicleDefinition','ProductCategory'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    Integer q = -1;
    try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) {}
    System.debug('   ' + o + ': existe | registros=' + (q < 0 ? 'sem acesso' : String.valueOf(q)));
}
Map<String, Schema.SObjectField> p2 = Product2.SObjectType.getDescribe().fields.getMap();
for (String c : new List<String>{'BusinessBrandId','Family','ProductCode','Cost__c'}) {
    System.debug('   Product2.' + c + ': ' + (p2.containsKey(c.toLowerCase()) ? 'existe' : 'nao existe'));
}

System.debug('=== 5. O NIVEL DO USUARIO, QUE A HU NAO DEFINE ===');
System.debug('   A RN5 tem Gerente de Ventas, Gerente de Marca, Director e');
System.debug('   Vicepresidencia. A HU nao diz de onde sai o nivel do usuario logado.');
try {
    for (AggregateResult a : Database.query(
            'SELECT Name n, COUNT(Id) q FROM UserRole GROUP BY Name ORDER BY Name LIMIT 40')) {
        System.debug('   UserRole: ' + a.get('n'));
    }
} catch (Exception e) { System.debug('   UserRole: ' + e.getMessage()); }
try {
    for (SObject ps : Database.query(
            'SELECT Label FROM PermissionSet WHERE IsOwnedByProfile = false'
            + ' AND (Label LIKE \'%escuento%\' OR Label LIKE \'%iscount%\''
            + ' OR Label LIKE \'%prob%\' OR Label LIKE \'%erente%\') ORDER BY Label')) {
        System.debug('   PermissionSet: ' + ps.get('Label'));
    }
} catch (Exception e) { System.debug('   PermissionSet: ' + e.getMessage()); }

System.debug('=== 6. O QUE JA HA DE APROVACAO E DE METADATA DE DESCONTO ===');
for (String s : new List<String>{'ProcessDefinition','EntityDefinition'}) {
    System.debug('   ' + s + ': ' + (g.containsKey(s.toLowerCase()) ? 'consultavel' : 'nao'));
}
try {
    for (SObject pd : Database.query(
            'SELECT DeveloperName, TableEnumOrId, Type, State FROM ProcessDefinition'
            + ' WHERE Type = \'Approval\' ORDER BY TableEnumOrId')) {
        System.debug('   aprovacao: ' + pd.get('DeveloperName') + ' | objeto=' + pd.get('TableEnumOrId')
            + ' | estado=' + pd.get('State'));
    }
} catch (Exception e) { System.debug('   ProcessDefinition: ' + e.getMessage()); }
for (String k : g.keySet()) {
    if (!k.endsWith('__mdt')) { continue; }
    String n = k.toLowerCase();
    if (n.contains('descuento') || n.contains('discount') || n.contains('piso')
        || n.contains('rol') || n.contains('aprob') || n.contains('approv')) {
        System.debug('   Custom Metadata ja existente: ' + g.get(k).getDescribe().getName());
    }
}

System.debug('=== COMO LER ===');
System.debug('   a) se as duas matrizes ja tiverem as colunas de marca, modelo,');
System.debug('      sociedade e rol, a proposta de Custom Metadata da RN4 e da RN5');
System.debug('      vira duplicidade e nao se empacota;');
System.debug('   b) se PricebookEntry nao tiver campo de cashback, a RN11 depende da');
System.debug('      HU-038 acrescentar, e isso e dependencia e nao tarefa desta HU;');
System.debug('   c) se nao houver origem clara do nivel do usuario, esse e o buraco');
System.debug('      real da historia: sem nivel nao ha rango do rol para validar.');
