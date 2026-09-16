// 34 - Chamado da Tayza (16/09): "nao consigo ver esta opp", link da CONTA 001V200000lodzIIAQ. Somente leitura: existe? esta
// na Lixeira? dono, record type, cluster; oportunidades da conta (inclusive excluidas); acesso da Tayza a conta e a cada
// oportunidade (UserRecordAccess); ultimas alteracoes. Filtre por CTA34|.
Id accId = '001V200000lodzIIAQ';
User tayza = [SELECT Id, Name, Profile.Name, UserRole.Name, Cluster__c FROM User WHERE Name = 'Tayza Apollo' AND IsActive = true LIMIT 1];
System.debug('CTA34| usuaria=' + tayza.Name + ' | perfil=' + tayza.Profile.Name + ' | papel=' + tayza.UserRole.Name + ' | cluster=' + tayza.Cluster__c);

List<Account> accs = [SELECT Id, Name, IsDeleted, Owner.Name, Owner.IsActive, RecordType.Name, AccountManager__r.Name, Cluster__c, ClusterManual__c,
                             CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Account WHERE Id = :accId ALL ROWS];
if (accs.isEmpty()) { System.debug('CTA34| CONTA NAO EXISTE (nem na Lixeira): ' + accId); return; }
Account a = accs[0];
System.debug('CTA34| CONTA | ' + a.Name + ' | excluida=' + a.IsDeleted + ' | dono=' + a.Owner.Name + (a.Owner.IsActive ? '' : ' (INATIVO)') + ' | rt=' + a.RecordType.Name
    + ' | gerente=' + a.AccountManager__r.Name + ' | cluster=' + a.Cluster__c + '/' + a.ClusterManual__c + ' | criada ' + a.CreatedDate.format('dd/MM/yy') + ' por ' + a.CreatedBy.Name
    + ' | alterada ' + a.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + a.LastModifiedBy.Name);
for (UserRecordAccess u : [SELECT RecordId, HasReadAccess, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :tayza.Id AND RecordId = :accId]) {
    System.debug('CTA34| acesso da Tayza a conta: leitura=' + u.HasReadAccess + ' | edicao=' + u.HasEditAccess + ' | nivel=' + u.MaxAccessLevel);
}
// oportunidades da conta, inclusive na Lixeira
List<Opportunity> opps = [SELECT Id, Name, IsDeleted, StageName, IsClosed, Owner.Name, Owner.IsActive, RecordType.Name, ManagerAccount__r.Name, Send4Approval__c,
                                 CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Opportunity WHERE AccountId = :accId ALL ROWS ORDER BY CreatedDate DESC];
System.debug('CTA34| oportunidades da conta (inclusive excluidas): ' + opps.size());
Set<Id> ids = new Set<Id>();
for (Opportunity o : opps) {
    ids.add(o.Id);
    System.debug('CTA34| OPP | ' + o.Id + ' | ' + o.Name.left(60) + ' | ' + (o.IsDeleted ? 'NA LIXEIRA' : 'ativa') + ' | fase=' + o.StageName + ' | fechada=' + o.IsClosed
        + ' | dono=' + o.Owner.Name + (o.Owner.IsActive ? '' : ' (INATIVO)') + ' | rt=' + o.RecordType.Name + ' | gerente=' + o.ManagerAccount__r.Name
        + ' | em aprovacao=' + o.Send4Approval__c + ' | travada=' + (o.IsDeleted ? '-' : String.valueOf(Approval.isLocked(o.Id)))
        + ' | criada ' + o.CreatedDate.format('dd/MM/yy') + ' | alterada ' + o.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + o.LastModifiedBy.Name);
}
if (!ids.isEmpty()) {
    for (UserRecordAccess u : [SELECT RecordId, HasReadAccess, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :tayza.Id AND RecordId IN :ids]) {
        System.debug('CTA34| acesso da Tayza a opp ' + u.RecordId + ': leitura=' + u.HasReadAccess + ' | edicao=' + u.HasEditAccess + ' | nivel=' + u.MaxAccessLevel);
    }
}
// cotacoes e contratos ligados (componentes da pagina que podem quebrar)
System.debug('CTA34| cotacoes das opps: ' + (ids.isEmpty() ? 0 : [SELECT COUNT() FROM Quote WHERE OpportunityId IN :ids])
    + ' | contratos da conta: ' + [SELECT COUNT() FROM Contract WHERE AccountId = :accId]);
System.debug('CTA34| fim');
