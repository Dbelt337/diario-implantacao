// HU-064, parte 2: abrir por dentro as duas matrizes que ja existem. Solo lectura.
//
// No log anterior a travessia por relacionamento falhou, entao aqui nada de
// relacionamento: os Ids vem do proprio log e os campos saem de describe.
//   MatrizPisosPorRol     0lIWK0000000giQ2AQ
//   Discount_Rules_GrupoQ 0lIWK0000000eWv2AI
//
// Se essas duas ja resolverem marca, modelo, sociedade e rol, a RN4 e a RN5 da
// HU-064 nao criam Custom Metadata nenhum, e a historia encolhe.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();
List<String> ALVOS = new List<String>{'0lIWK0000000giQ2AQ', '0lIWK0000000eWv2AI'};

System.debug('=== 1. OS CAMPOS REAIS DE CADA OBJETO DO BRE ===');
Map<String, List<String>> campos = new Map<String, List<String>>();
for (String o : new List<String>{'CalculationMatrixVersion','CalculationMatrixColumn',
                                 'CalculationMatrixRow'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    List<String> ns = new List<String>();
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        ns.add(f.getDescribe().getName());
    }
    ns.sort();
    campos.put(o, ns);
    System.debug('   ' + o + ' (' + ns.size() + '): ' + String.join(ns, ', '));
}

System.debug('=== 2. AS VERSOES DAS DUAS MATRIZES ===');
Set<Id> versoes = new Set<Id>();
try {
    List<String> c = new List<String>{'Id'};
    for (String n : campos.get('CalculationMatrixVersion')) {
        String nl = n.toLowerCase();
        if (nl.contains('name') || nl.contains('status') || nl.contains('start')
            || nl.contains('end') || nl.contains('calculationmatrixid')
            || nl.contains('version') || nl.contains('type')) { c.add(n); }
    }
    for (SObject v : Database.query('SELECT ' + String.join(c, ', ')
            + ' FROM CalculationMatrixVersion WHERE CalculationMatrixId IN :ALVOS')) {
        versoes.add((Id) v.get('Id'));
        String l = '';
        for (String k : c) { if (v.get(k) != null) { l += k + '=' + v.get(k) + ' | '; } }
        System.debug('   ' + l);
    }
} catch (Exception e) { System.debug('   versoes: ' + e.getMessage()); }
System.debug('   versoes encontradas: ' + versoes.size());

System.debug('=== 3. AS COLUNAS, QUE SAO A CHAVE E A SAIDA ===');
try {
    List<String> c = new List<String>{'Id'};
    for (String n : campos.get('CalculationMatrixColumn')) {
        String nl = n.toLowerCase();
        if (nl.contains('name') || nl.contains('type') || nl.contains('sequence')
            || nl.contains('datatype') || nl.contains('sourcefield')
            || nl.contains('versionid') || nl.contains('label')) { c.add(n); }
    }
    for (SObject col : Database.query('SELECT ' + String.join(c, ', ')
            + ' FROM CalculationMatrixColumn ORDER BY Id')) {
        String l = '';
        for (String k : c) { if (col.get(k) != null) { l += k + '=' + col.get(k) + ' | '; } }
        System.debug('   ' + l);
    }
} catch (Exception e) { System.debug('   colunas: ' + e.getMessage()); }
System.debug('   PROCURAR: coluna de marca, de modelo, de sociedade e de rol.');
System.debug('   Se as quatro estiverem la, a escala da RN5 ja tem casa.');

System.debug('=== 4. AS LINHAS, QUE SAO OS PERCENTUAIS ===');
try {
    List<String> c = new List<String>{'Id'};
    for (String n : campos.get('CalculationMatrixRow')) {
        String nl = n.toLowerCase();
        if (nl.startsWith('input') || nl.startsWith('output')
            || nl.contains('versionid') || nl.contains('sequence')) { c.add(n); }
    }
    Integer total = 0;
    for (SObject r : Database.query('SELECT ' + String.join(c, ', ')
            + ' FROM CalculationMatrixRow ORDER BY Id LIMIT 60')) {
        String l = '';
        for (String k : c) { if (r.get(k) != null) { l += k + '=' + r.get(k) + ' | '; } }
        System.debug('   ' + l);
        total++;
    }
    System.debug('   linhas exibidas: ' + total);
    System.debug('   total de linhas na org: '
        + Database.countQuery('SELECT COUNT() FROM CalculationMatrixRow'));
} catch (Exception e) { System.debug('   linhas: ' + e.getMessage()); }

System.debug('=== 5. QUANTAS LINHAS A ESCALA PRECISARIA ===');
System.debug('   A RN5 configura por marca, modelo e sociedade. Isso dimensiona');
System.debug('   a decisao entre Custom Metadata e matriz.');
try {
    System.debug('   marcas: ' + Database.countQuery('SELECT COUNT() FROM BusinessBrand'));
    System.debug('   definicoes de veiculo: ' + Database.countQuery('SELECT COUNT() FROM VehicleDefinition'));
    System.debug('   sociedades: ' + Database.countQuery('SELECT COUNT() FROM Sociedad_Config__mdt'));
    for (AggregateResult a : Database.query(
            'SELECT BusinessBrand.Name b, COUNT(Id) q FROM VehicleDefinition'
            + ' GROUP BY BusinessBrand.Name ORDER BY COUNT(Id) DESC LIMIT 30')) {
        System.debug('   marca ' + a.get('b') + ' | modelos=' + a.get('q'));
    }
} catch (Exception e) { System.debug('   ' + e.getMessage()); }
System.debug('   marca x modelo x sociedade e o pior caso. Se o negocio confirmar');
System.debug('   que a escala e por marca e sociedade, o numero cai muito e Custom');
System.debug('   Metadata volta a ser viavel. Esse numero decide, nao a preferencia.');

System.debug('=== 6. O QUE JA HA DE APROVACAO EM QUOTE ===');
System.debug('   O log anterior achou DiscountApproval ATIVO em Quote, e dois');
System.debug('   processos obsoletos em Opportunity. Ver o que a HU-065 herda.');
try {
    for (SObject s : Database.query(
            'SELECT Id, ProcessDefinition.DeveloperName, Status, TargetObjectId'
            + ' FROM ProcessInstance ORDER BY CreatedDate DESC LIMIT 20')) {
        SObject pd = s.getSObject('ProcessDefinition');
        System.debug('   instancia: ' + (pd == null ? '?' : String.valueOf(pd.get('DeveloperName')))
            + ' | ' + s.get('Status') + ' | alvo=' + s.get('TargetObjectId'));
    }
} catch (Exception e) { System.debug('   ProcessInstance: ' + e.getMessage()); }
