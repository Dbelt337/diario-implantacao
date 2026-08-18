// HU-119, integracao SAP. O que o Cotizador ja entrega e o que falta. Solo lectura.
// Fecha T05, T10, T12 e T30 da planilha, e o teto de entidades de CDC.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. O ESTADO DE INTEGRACAO DE HOJE ===');
System.debug('   A RN-07 pede picklist filtravel com sete estados. Texto nao serve.');
for (String o : new List<String>{'Order','Quote','QuoteLineItem','OrderItem','Vehicle','Account'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { System.debug('   ' + o + ': NAO existe'); continue; }
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        if (!d.isCustom()) { continue; }
        String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
        if (n.contains('sap') || n.contains('sync') || n.contains('integra')
            || n.contains('correl') || n.contains('mule') || n.contains('error')
            || n.contains('retry') || n.contains('reintent')) {
            System.debug('   ' + o + '.' + d.getName() + ' | ' + d.getType()
                + ' | unico=' + d.isUnique() + ' | extId=' + d.isExternalId()
                + ' | ' + d.getLabel());
        }
    }
}

System.debug('=== 2. OS EXTERNAL ID, QUE DECIDEM O UPSERT ===');
System.debug('   Sem External Id nao ha upsert idempotente nem consulta seletiva.');
for (String o : new List<String>{'Vehicle','Account','Order','Product2','PricebookEntry',
                                 'Quote','Asset'}) {
    Schema.SObjectType t = g.get(o.toLowerCase());
    if (t == null) { continue; }
    List<String> ids = new List<String>();
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        if (d.isExternalId() || d.isUnique()) {
            ids.add(d.getName() + (d.isExternalId() ? ' extId' : '') + (d.isUnique() ? ' unico' : ''));
        }
    }
    System.debug('   ' + o + ': ' + (ids.isEmpty() ? 'NENHUM, upsert nao e possivel' : String.valueOf(ids)));
}

System.debug('=== 3. OS PLATFORM EVENTS DA ORG ===');
for (String k : g.keySet()) {
    if (!k.endsWith('__e')) { continue; }
    Schema.DescribeSObjectResult d = g.get(k).getDescribe();
    System.debug('   ' + d.getName() + ' | campos=' + d.fields.getMap().size()
        + ' | criavel=' + d.isCreateable());
    for (Schema.SObjectField f : d.fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        if (fd.isCustom()) { System.debug('      ' + fd.getName() + ' | ' + fd.getType()); }
    }
}
System.debug('   Volume e comportamento de publicacao nao vem por describe.');
System.debug('   Ver em Setup, Platform Events, no proprio evento.');

System.debug('=== 4. CHANGE DATA CAPTURE, O TETO DE CINCO ENTIDADES ===');
try {
    Integer n = 0;
    for (SObject s : Database.query(
            'SELECT DeveloperName, SelectedEntity FROM PlatformEventChannelMember LIMIT 50')) {
        System.debug('   canal ' + s.get('DeveloperName') + ' | entidade ' + s.get('SelectedEntity'));
        n++;
    }
    System.debug('   entidades em canal: ' + n);
} catch (Exception e) { System.debug('   PlatformEventChannelMember: ' + e.getMessage()); }
try {
    for (SObject s : Database.query('SELECT DeveloperName, ChannelType FROM PlatformEventChannel LIMIT 20')) {
        System.debug('   PlatformEventChannel: ' + s.get('DeveloperName') + ' | ' + s.get('ChannelType'));
    }
} catch (Exception e) { System.debug('   PlatformEventChannel: ' + e.getMessage()); }
System.debug('   O padrao de CDC sem add on e cinco entidades. Esta HU precisa de oito.');

System.debug('=== 5. AS CREDENCIAIS E O MOCK MODE ===');
try {
    for (SObject nc : Database.query('SELECT DeveloperName, Endpoint FROM NamedCredential')) {
        System.debug('   NamedCredential: ' + nc.get('DeveloperName') + ' | ' + nc.get('Endpoint'));
    }
} catch (Exception e) { System.debug('   NamedCredential: ' + e.getMessage()); }
System.debug('   SapMuleClient.mockMode nao aparece em describe. Abrir a classe e');
System.debug('   confirmar de onde vem o valor: constante, Custom Setting ou metadata.');
for (String k : g.keySet()) {
    if (!k.endsWith('__mdt') && !k.endsWith('__c')) { continue; }
    String n = k.toLowerCase();
    if (n.contains('mule') || n.contains('integra') || n.contains('sap')
        || n.contains('mock') || n.contains('endpoint')) {
        System.debug('   config candidata: ' + g.get(k).getDescribe().getName());
    }
}

System.debug('=== 6. OS FLOWS DE INTEGRACAO E A ORDEM ===');
try {
    for (SObject f : Database.query(
            'SELECT ApiName, Label, TriggerType, TriggerObjectOrEventLabel, ProcessType,'
            + ' TriggerOrder, IsActive FROM FlowDefinitionView'
            + ' WHERE IsActive = true AND TriggerType != null'
            + ' ORDER BY TriggerObjectOrEventLabel, TriggerOrder')) {
        System.debug('   ' + f.get('TriggerObjectOrEventLabel') + ' | ' + f.get('ApiName')
            + ' | ' + f.get('TriggerType') + ' | ordem=' + f.get('TriggerOrder'));
    }
} catch (Exception e) { System.debug('   FlowDefinitionView: ' + e.getMessage()); }
System.debug('   Ordem nula em objeto com mais de um flow e comportamento imprevisivel.');

System.debug('=== COMO LER ===');
System.debug('   a) se nao houver campo de correlation id, o reprocesso do Escenario 7');
System.debug('      duplica documento no SAP. E o furo mais caro;');
System.debug('   b) se SapStatus__c for texto, a RN-07 nao e filtravel nem reportavel;');
System.debug('   c) objeto sincronizado sem External Id nao aceita upsert idempotente;');
System.debug('   d) mais de cinco entidades em canal de CDC significa add on comprado,');
System.debug('      ou entao a saida tem que ser Platform Event proprio.');
