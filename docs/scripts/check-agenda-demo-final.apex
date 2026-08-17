// Fecha as cinco perguntas abertas da agenda do veiculo demo. Solo lectura.
// 1 onde o veiculo vive no agendamento  2 FLS do cliente  3 mapeamento de
// Status Category, que e o bloqueio de cancelamento  4 compartilhamento
// 5 se ja ha agendamento com recurso de ativo, que confirma o end-to-end.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();
Map<String, Schema.SObjectField> sa;
try { sa = g.get('serviceappointment').getDescribe().fields.getMap(); }
catch (Exception e) { System.debug('ServiceAppointment nao existe'); return; }

System.debug('=== 1. ONDE O VEICULO VIVE ===');
for (Schema.SObjectField f : sa.values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (d.getType() != Schema.DisplayType.REFERENCE) { continue; }
    List<String> alvos = new List<String>();
    for (Schema.SObjectType t : d.getReferenceTo()) { alvos.add(t.getDescribe().getName()); }
    Boolean rel = d.isCustom() || d.getName() == 'ParentRecordId'
        || alvos.contains('Vehicle') || alvos.contains('Asset');
    if (rel) { System.debug('   ' + d.getName() + ' -> ' + alvos + ' | custom=' + d.isCustom()); }
}
System.debug('   Se nao houver lookup para Asset nem Vehicle, o veiculo esta so');
System.debug('   em AssignedResource, que e filho, e formula NAO alcanca:');
System.debug('   o rotulo tem que ser campo texto estampado por flow.');

System.debug('=== 2. DA PARA ESCONDER O CLIENTE POR FLS ===');
for (String n : new List<String>{ 'ContactId', 'ParentRecordId', 'AccountId',
                                  'Subject', 'Status', 'SchedStartTime', 'OwnerId' }) {
    Schema.SObjectField f = sa.get(n.toLowerCase());
    if (f == null) { System.debug('   ' + n + ': nao existe'); continue; }
    Schema.DescribeFieldResult d = f.getDescribe();
    System.debug('   ' + n + ' | permissionable=' + d.isPermissionable()
        + ' | acessivel=' + d.isAccessible() + ' | obrigatorio=' + !d.isNillable());
}
System.debug('   permissionable=false significa que FLS nao desliga o campo.');

System.debug('=== 3. STATUS CATEGORY, O BLOQUEIO DE CANCELAMENTO ===');
String objSt = null;
for (String k : g.keySet()) {
    if (k.contains('serviceappointmentstatus')) { objSt = g.get(k).getDescribe().getName(); }
}
System.debug('   objeto de mapeamento: ' + (objSt == null ? 'NAO existe' : objSt));
if (objSt != null) {
    try {
        Map<String, Schema.SObjectField> mf = g.get(objSt.toLowerCase()).getDescribe().fields.getMap();
        List<String> cols = new List<String>();
        for (String k : mf.keySet()) {
            String nm = mf.get(k).getDescribe().getName(); String nl = nm.toLowerCase();
            if (nl.contains('label') || nl.contains('category') || nl.contains('sort')
                || nl.contains('apiname') || nl.contains('status') || nl == 'id') { cols.add(nm); }
        }
        for (SObject s : Database.query('SELECT ' + String.join(cols, ', ') + ' FROM ' + objSt + ' LIMIT 60')) {
            String l = '';
            for (String c : cols) { if (s.get(c) != null) { l += c + '=' + s.get(c) + ' | '; } }
            System.debug('   ' + l);
        }
        System.debug('   PROCURAR: valor de cancelamento com categoria None ou errada.');
        System.debug('   Categoria Canceled LIBERA o recurso atribuido. Categoria None');
        System.debug('   remove o recurso e reseta o agendamento. Se estiver errado, o');
        System.debug('   sintoma e exatamente nao conseguir cancelar com recurso primario.');
    } catch (Exception e) { System.debug('   erro: ' + e.getMessage()); }
}
System.debug('   --- valores do Status no agendamento ---');
for (Schema.PicklistEntry pe : ServiceAppointment.Status.getDescribe().getPicklistValues()) {
    System.debug('   ' + (pe.isActive() ? 'ATIVO   ' : 'INATIVO ') + pe.getValue() + ' | ' + pe.getLabel());
}

System.debug('=== 4. COMPARTILHAMENTO ===');
for (String o : new List<String>{ 'ServiceAppointmentShare', 'ServiceResource',
                                  'ServiceTerritory', 'AssignedResource', 'ServiceReport' }) {
    System.debug('   ' + o + ': ' + (g.containsKey(o.toLowerCase()) ? 'existe' : 'NAO existe'));
}

System.debug('=== 5. O END-TO-END JA RODA COM VEICULO ===');
System.debug('   tipos de recurso, com rotulo, para saber o que S e T significam:');
for (Schema.PicklistEntry pe : ServiceResource.ResourceType.getDescribe().getPicklistValues()) {
    System.debug('   valor=' + pe.getValue() + ' | label=' + pe.getLabel()
        + ' | ativo=' + pe.isActive());
}
for (ServiceResource r : [SELECT Name, ResourceType, IsActive, RelatedRecordId
                          FROM ServiceResource ORDER BY ResourceType, Name LIMIT 50]) {
    System.debug('   ' + r.ResourceType + ' | ' + r.Name + ' | ativo=' + r.IsActive
        + ' | usuario=' + r.RelatedRecordId);
}
System.debug('   agendamentos: ' + [SELECT COUNT() FROM ServiceAppointment]);
try {
    System.debug('   recursos atribuidos: ' + Database.countQuery('SELECT COUNT() FROM AssignedResource'));
    for (AggregateResult a : Database.query(
            'SELECT ServiceResource.ResourceType t, COUNT(Id) q FROM AssignedResource'
            + ' GROUP BY ServiceResource.ResourceType')) {
        System.debug('   atribuicoes do tipo ' + a.get('t') + ' | ' + a.get('q'));
    }
    for (SObject ar : Database.query(
            'SELECT ServiceAppointment.AppointmentNumber, ServiceResource.Name,'
            + ' ServiceResource.ResourceType FROM AssignedResource ORDER BY CreatedDate DESC LIMIT 10')) {
        SObject ap = ar.getSObject('ServiceAppointment'); SObject rs = ar.getSObject('ServiceResource');
        System.debug('   ' + (ap == null ? '-' : ap.get('AppointmentNumber'))
            + ' <- ' + (rs == null ? '-' : rs.get('Name'))
            + ' (' + (rs == null ? '-' : rs.get('ResourceType')) + ')');
    }
    System.debug('   Se aparecer recurso que e um VEICULO aqui, o Tiago esta certo e');
    System.debug('   eu retiro o meu ponto de que nenhum veiculo e agendavel.');
} catch (Exception e) { System.debug('   AssignedResource: ' + e.getMessage()); }
