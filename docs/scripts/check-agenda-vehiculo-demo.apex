// Requisito do Tiago: agenda do veiculo de demo com veiculo, data, hora, status
// e responsavel pela reserva, SEM o nome do cliente.
//
// O que ja existe: Generate_Test_Drive_Authorization trabalha em
// ServiceAppointment e gera o PDF por ServiceReport. ManageDemoVehicle e
// ExecuteDemoRequest mexem em Vehicle.Status e em Task. Nenhum deles e agenda.
//
// Este script responde as tres perguntas que decidem a solucao. Solo lectura.

System.debug('=== 1. COMO O VEICULO SE LIGA AO AGENDAMENTO ===');
System.debug('ParentRecordId aceita Lead, Account, Opportunity, e com Field');
System.debug('Service tambem WorkOrder, WorkOrderLineItem e Asset. NAO aceita');
System.debug('Vehicle. Entao a ligacao tem que ser campo proprio ou via');
System.debug('Opportunity.Vehiculo__c, que existe.');

Map<String, Schema.SObjectField> sa;
try {
    sa = Schema.getGlobalDescribe().get('ServiceAppointment').getDescribe().fields.getMap();
} catch (Exception e) {
    System.debug('ServiceAppointment NAO existe nesta org: ' + e.getMessage());
    return;
}
for (Schema.SObjectField f : sa.values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (d.getType() != Schema.DisplayType.REFERENCE) { continue; }
    List<String> alvos = new List<String>();
    for (Schema.SObjectType t : d.getReferenceTo()) { alvos.add(t.getDescribe().getName()); }
    if (d.isCustom() || alvos.contains('Vehicle') || d.getName() == 'ParentRecordId') {
        System.debug('   ' + d.getName() + ' -> ' + alvos + ' | custom=' + d.isCustom());
    }
}

System.debug('=== 2. DA PARA ESCONDER O CLIENTE POR FLS ===');
System.debug('Se isPermissionable=false, FLS NAO desliga o campo e esconder');
System.debug('coluna nao e privacidade nenhuma.');
for (String n : new List<String>{ 'ContactId', 'ParentRecordId', 'AccountId', 'Subject',
                                  'Status', 'SchedStartTime', 'SchedEndTime', 'OwnerId' }) {
    Schema.SObjectField f = sa.get(n.toLowerCase());
    if (f == null) { System.debug('   ' + n + ': nao existe'); continue; }
    Schema.DescribeFieldResult d = f.getDescribe();
    System.debug('   ' + n + ' | permissionable=' + d.isPermissionable()
        + ' | acessivel=' + d.isAccessible() + ' | obrigatorio=' + !d.isNillable());
}

System.debug('=== 3. O COMPARTILHAMENTO ===');
System.debug('Se ServiceAppointmentShare existe, a OWD nao e publica e ha');
System.debug('visibilidade por registro, que e o unico jeito de fazer valer.');
Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();
for (String o : new List<String>{ 'ServiceAppointmentShare', 'ServiceResource', 'ServiceTerritory',
                                  'WorkType', 'WorkTypeGroup', 'AssignedResource',
                                  'AppointmentTopicTimeSlot', 'ServiceReport', 'Vehicle' }) {
    System.debug('   ' + o + ': ' + (g.containsKey(o.toLowerCase()) ? 'existe' : 'NAO existe'));
}

System.debug('=== 4. O QUE JA HA DE DADO ===');
System.debug('agendamentos: ' + [SELECT COUNT() FROM ServiceAppointment]);
for (AggregateResult a : [SELECT Status s, COUNT(Id) q FROM ServiceAppointment
                          GROUP BY Status ORDER BY COUNT(Id) DESC]) {
    System.debug('   status ' + a.get('s') + ' | ' + a.get('q'));
}
for (ServiceAppointment s : [SELECT Id, AppointmentNumber, Subject, Status,
                                    SchedStartTime, SchedEndTime, ParentRecordId,
                                    ContactId, Owner.Name, WorkType.Name
                             FROM ServiceAppointment
                             ORDER BY CreatedDate DESC LIMIT 5]) {
    System.debug('   ' + s.AppointmentNumber + ' | ' + s.Subject
        + ' | ' + s.Status + ' | ' + s.SchedStartTime
        + ' | pai=' + s.ParentRecordId
        + ' | contato=' + s.ContactId
        + ' | dono=' + s.Owner.Name
        + ' | tipo=' + (s.WorkType == null ? '-' : s.WorkType.Name));
    if (s.ParentRecordId != null) {
        System.debug('        o pai e um ' + s.ParentRecordId.getSObjectType().getDescribe().getName());
    }
}

System.debug('=== 5. O VEICULO COMO RECURSO AGENDAVEL ===');
try {
    for (AggregateResult a : Database.query(
            'SELECT ResourceType t, COUNT(Id) q FROM ServiceResource GROUP BY ResourceType')) {
        System.debug('   ServiceResource tipo ' + a.get('t') + ' | ' + a.get('q'));
    }
    System.debug('   Se houver tipo Asset, o veiculo pode ser recurso agendavel e');
    System.debug('   a disponibilidade sai nativa, sem expor cliente.');
} catch (Exception e) { System.debug('   ' + e.getMessage()); }
try {
    for (AggregateResult a : Database.query(
            'SELECT Status s, COUNT(Id) q FROM Vehicle GROUP BY Status ORDER BY COUNT(Id) DESC')) {
        System.debug('   Vehicle status ' + a.get('s') + ' | ' + a.get('q'));
    }
} catch (Exception e) { System.debug('   Vehicle: ' + e.getMessage()); }

System.debug('=== COMO DECIDIR ===');
System.debug('a) se ContactId e ParentRecordId sao permissionable, FLS esconde os');
System.debug('   campos, mas o consultor que abre o registro ainda ve o pai pelo');
System.debug('   nome relacionado. Serve para relatorio, nao para privacidade;');
System.debug('b) se ServiceAppointmentShare existe, o caminho firme e OWD privada');
System.debug('   mais uma tela propria que consulta without sharing e devolve SO');
System.debug('   veiculo, data, hora, status e dono. E o unico que faz valer;');
System.debug('c) se o veiculo for ServiceResource de tipo Asset, a disponibilidade');
System.debug('   ja sai nativa por Scheduler, sem nome de cliente em lugar nenhum.');
