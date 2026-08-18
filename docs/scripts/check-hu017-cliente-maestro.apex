// HU-017, cliente maestro. O que a plataforma e a org JA entregam. Solo lectura.
// Logs anteriores ja deram: as duas aprovacoes de dado sensivel em Account estao
// ATIVAS, Account.Sociedad__c e TEXTAREA, e TaxID__c convive com
// BusinessProfile.BusinessTaxIdentifier. Este fecha o resto.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. MODELO DE CONTA E TIPOS DE CLIENTE ===');
Schema.DescribeSObjectResult ad = Account.SObjectType.getDescribe();
System.debug('   Person Account habilitado: '
    + ad.fields.getMap().containsKey('ispersonaccount'));
for (Schema.RecordTypeInfo ri : ad.getRecordTypeInfos()) {
    if (ri.getDeveloperName() == 'Master') { continue; }
    System.debug('   Account RT: ' + ri.getDeveloperName() + ' | ' + ri.getName()
        + ' | ativo=' + ri.isActive() + ' | disponivel=' + ri.isAvailable());
}
try {
    for (AggregateResult a : Database.query(
            'SELECT RecordType.DeveloperName rt, IsPersonAccount p, COUNT(Id) q'
            + ' FROM Account GROUP BY RecordType.DeveloperName, IsPersonAccount'
            + ' ORDER BY COUNT(Id) DESC')) {
        System.debug('   RT ' + a.get('rt') + ' | pessoal=' + a.get('p') + ' | ' + a.get('q'));
    }
} catch (Exception e) { System.debug('   ' + e.getMessage()); }

System.debug('=== 2. RELACAO CLIENTE x CONTATO E CLIENTE x SOCIEDADE ===');
for (String o : new List<String>{'AccountContactRelation','AccountAccountRelation',
                                 'PartyRoleRelation','ContactContactRelation'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    Integer q = -1;
    try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) {}
    System.debug('   ' + o + ': existe | criavel=' + t.getDescribe().isCreateable()
        + ' | campos=' + t.getDescribe().fields.getMap().size()
        + ' | registros=' + (q < 0 ? 'sem acesso' : String.valueOf(q)));
}
System.debug('=== 3. DOCUMENTO DE IDENTIDADE, A CHAVE DA RN-02 ===');
for (String o : new List<String>{'IdentityDocument','PartyIdentification',
                                 'IdentityVerification','TaxIdentification'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    Integer q = -1;
    try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) {}
    System.debug('   ' + o + ': existe | criavel=' + t.getDescribe().isCreateable()
        + ' | registros=' + (q < 0 ? '?' : String.valueOf(q)));
    if (o == 'IdentityDocument') {
        for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult d = f.getDescribe();
            System.debug('      ' + d.getName() + ' | ' + d.getType()
                + (d.getType() == Schema.DisplayType.REFERENCE
                   ? ' -> ' + d.getReferenceTo() : ''));
        }
    }
}

System.debug('=== 4. CANAIS DE CONTATO E CONSENTIMENTO ===');
for (String o : new List<String>{'Individual','ContactPointEmail','ContactPointPhone',
                                 'ContactPointAddress','ContactPointTypeConsent',
                                 'ContactPointConsent','AuthorizationFormConsent',
                                 'DataUsePurpose','PartyConsent'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    Integer q = -1;
    if (t != null) { try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) {} }
    System.debug('   ' + o + ': ' + (t == null ? 'NAO existe'
        : 'existe | criavel=' + t.getDescribe().isCreateable()
          + ' | registros=' + (q < 0 ? '?' : String.valueOf(q))));
}

System.debug('=== 5. UNICIDADE E DUPLICADOS ===');
List<String> unicos = new List<String>();
for (Schema.SObjectField f : ad.fields.getMap().values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (d.isUnique() || d.isExternalId()) {
        unicos.add(d.getName() + (d.isUnique() ? ' UNICO' : '') + (d.isExternalId() ? ' EXTID' : ''));
    }
}
System.debug('   Account, campos unicos ou External Id: '
    + (unicos.isEmpty() ? 'NENHUM, a CA-01 nao tem garantia hoje' : String.valueOf(unicos)));
try {
    for (SObject d : Database.query('SELECT DeveloperName, IsActive, SobjectType FROM DuplicateRule')) {
        System.debug('   DuplicateRule: ' + d.get('DeveloperName') + ' | ' + d.get('SobjectType')
            + ' | ativa=' + d.get('IsActive'));
    }
} catch (Exception e) { System.debug('   DuplicateRule: ' + e.getMessage()); }
try {
    System.debug('   DuplicateRecordSet: ' + Database.countQuery('SELECT COUNT() FROM DuplicateRecordSet'));
} catch (Exception e) {}

System.debug('=== 6. VISIBILIDADE POR SOCIEDADE ===');
for (String o : new List<String>{'AccountShare','AccountTeamMember','Territory2',
                                 'ObjectTerritory2Association','UserTerritory2Association'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    Integer q = -1;
    if (t != null) { try { q = Database.countQuery('SELECT COUNT() FROM ' + o); } catch (Exception e) {} }
    System.debug('   ' + o + ': ' + (t == null ? 'NAO existe' : 'existe | registros='
        + (q < 0 ? '?' : String.valueOf(q))));
}

System.debug('=== 7. AUDITORIA, ARQUIVO E CAMPOS QUE JA EXISTEM ===');
System.debug('   AccountHistory: ' + (g.containsKey('accounthistory') ? 'existe' : 'NAO existe'));
System.debug('   Account, total de campos: ' + ad.fields.getMap().size());
Integer custom = 0;
for (Schema.SObjectField f : ad.fields.getMap().values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (!d.isCustom()) { continue; }
    custom++;
    String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
    if (n.contains('sociedad') || n.contains('document') || n.contains('tax')
        || n.contains('pais') || n.contains('country') || n.contains('sap')
        || n.contains('sync') || n.contains('activ') || n.contains('estado')) {
        System.debug('   Account.' + d.getName() + ' | ' + d.getType() + ' | ' + d.getLabel());
    }
}
System.debug('   Account, campos custom: ' + custom);

System.debug('=== COMO LER ===');
System.debug('   a) sem campo unico em Account, a CA-01 depende so de Duplicate Rule,');
System.debug('      que a API sabe burlar. E o unico ponto sem garantia da HU;');
System.debug('   b) IdentityDocument criavel resolve a RN-02 sem criar objeto, e ainda');
System.debug('      resolve o principal mais complementar do estrangeiro;');
System.debug('   c) ContactPointEmail existindo, a RN-13 nao vira campo novo;');
System.debug('   d) AccountShare e o unico caminho de visibilidade por sociedade que');
System.debug('      nao contradiz a RN-05.');
