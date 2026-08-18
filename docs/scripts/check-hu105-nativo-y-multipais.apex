// HU-105 parte 2: o que a plataforma JA MODELA de imposto, e se o desenho
// aguenta o segundo pais. Solo lectura. Roda depois do check-hu105-impuestos.
//
// A pesquisa de 18/08 achou um modelo fiscal nativo que nao e do Automotive e
// sim do Commerce e do Revenue: LegalEntity, TaxPolicy, TaxTreatment e TaxRate.
// Nesse modelo a TaxRate e por codigo de imposto E PAIS, e a TaxTreatment
// aponta para a LegalEntity. Isso e literalmente a RN-15, tasa por sociedade,
// e a RN-02, tasa por pais. Se estiver disponivel na org, nao se cria matriz
// nem campo de exoneracao por produto sem antes comparar.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. O MODELO FISCAL NATIVO ESTA DISPONIVEL ===');
for (String o : new List<String>{
        'LegalEntity','TaxPolicy','TaxTreatment','TaxRate','ProductTaxPolicy',
        'OrderItemTaxLineItem','OrderItemTaxLineItemSummary','TaxEngineProvider'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    Schema.DescribeSObjectResult d = t.getDescribe();
    Integer q = 0;
    try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) { q = -1; }
    System.debug('   ' + o + ': existe | criavel=' + d.isCreateable()
        + ' | consultavel=' + d.isQueryable() + ' | campos=' + d.fields.getMap().size()
        + ' | registros=' + (q < 0 ? 'sem acesso' : String.valueOf(q)));
}
System.debug('   LEITURA: existe e criavel = candidato real, comparar antes de');
System.debug('   construir. Existe e NAO criavel = objeto de sistema, so leitura,');
System.debug('   nao serve de tabela de manutencao.');

System.debug('=== 2. O PRODUTO JA TEM POLITICA FISCAL NATIVA ===');
System.debug('   Se Product2.TaxPolicyId existir, a RN-10, exoneracao por marca,');
System.debug('   modelo e versao, sai de campo custom para dado nativo.');
for (String c : new List<String>{'TaxPolicyId','TaxPolicy','LegalEntityId'}) {
    System.debug('   Product2.' + c + ': '
        + (Product2.SObjectType.getDescribe().fields.getMap().containsKey(c.toLowerCase())
           ? 'EXISTE, avaliar antes de criar IsTaxExempt__c' : 'nao existe'));
}
try {
    for (SObject p : Database.query('SELECT Id, Name FROM TaxPolicy LIMIT 10')) {
        System.debug('   TaxPolicy ja cadastrada: ' + p.get('Name'));
    }
} catch (Exception e) { System.debug('   TaxPolicy: ' + e.getMessage()); }

System.debug('=== 3. A SOCIEDADE, ONDE ELA VIVE HOJE ===');
System.debug('   RN-15 quer cliente x SOCIEDAD. Antes de criar qualquer coisa,');
System.debug('   ver quantas fontes de sociedade a org ja tem.');
try {
    Integer n = 0;
    for (SObject s : Database.query('SELECT MasterLabel FROM Sociedad_Config__mdt ORDER BY MasterLabel')) {
        System.debug('   Sociedad_Config__mdt: ' + s.get('MasterLabel')); n++;
    }
    System.debug('   total de sociedades configuradas: ' + n);
} catch (Exception e) { System.debug('   Sociedad_Config__mdt: ' + e.getMessage()); }
if (g.containsKey('legalentity')) {
    try {
        for (SObject l : Database.query('SELECT Name FROM LegalEntity LIMIT 30')) {
            System.debug('   LegalEntity: ' + l.get('Name'));
        }
    } catch (Exception e) { System.debug('   LegalEntity: ' + e.getMessage()); }
}
for (Schema.SObjectField f : Account.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
    if (n.contains('sociedad') || n.contains('company code') || n.contains('legalentity')) {
        System.debug('   Account.' + d.getName() + ' (' + d.getType() + ')');
    }
}

System.debug('=== 4. O DESENHO AGUENTA O SEGUNDO PAIS ===');
System.debug('   A implantacao e Costa Rica, mas sao seis paises e doze sociedades.');
List<String> ativas = new List<String>();
try {
    for (SObject c : Database.query(
            'SELECT IsoCode, IsActive, IsCorporate FROM CurrencyType ORDER BY IsoCode')) {
        System.debug('   moeda ' + c.get('IsoCode') + ' | ativa=' + c.get('IsActive')
            + ' | corporativa=' + c.get('IsCorporate'));
        if (c.get('IsActive') == true) { ativas.add(String.valueOf(c.get('IsoCode'))); }
    }
} catch (Exception e) { System.debug('   multimoeda desligada: ' + e.getMessage()); }
for (String m : new List<String>{'CRC','USD','GTQ','HNL','NIO','PAB'}) {
    if (!ativas.contains(m)) {
        System.debug('   FALTA a moeda ' + m + ': as sociedades desse pais nao cotizam');
    }
}
System.debug('   --- metadado com pais no nome, que a convencao GRPQM proibe ---');
Integer suspeitos = 0;
for (Schema.SObjectType t : new List<Schema.SObjectType>{
        Account.SObjectType, Product2.SObjectType, Quote.SObjectType, PricebookEntry.SObjectType}) {
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        if (!d.isCustom()) { continue; }
        String n = d.getName().toLowerCase();
        if (n.contains('costarica') || n.contains('_cr_') || n.contains('guatemala')
            || n.contains('honduras') || n.contains('nicaragua') || n.contains('panama')
            || n.contains('salvador')) {
            System.debug('   SUSPEITO ' + t.getDescribe().getName() + '.' + d.getName());
            suspeitos++;
        }
    }
}
System.debug('   campos com pais cravado no nome: ' + suspeitos
    + ' (a convencao GRPQM proibe referencia a pais no API name)');

System.debug('=== COMO LER ===');
System.debug('   a) LegalEntity criavel mais TaxRate criavel: a tabela de tasas pode');
System.debug('      ser nativa e por sociedade, e a Decision Matrix vira so a regra');
System.debug('      que o nativo nao expressa, gravame parcial e retencao;');
System.debug('   b) Product2.TaxPolicyId existindo, nao se cria IsTaxExempt__c;');
System.debug('   c) mais de uma fonte de sociedade e o mesmo defeito da moeda em');
System.debug('      14/08. Escolher uma antes de amarrar imposto nela;');
System.debug('   d) moeda faltando nao bloqueia Costa Rica, bloqueia o pais dela.');
