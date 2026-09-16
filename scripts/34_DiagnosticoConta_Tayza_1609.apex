// 34 - Chamado da Tayza (16/09): "nao consigo ver esta opp", link da CONTA 001V200000lodzIIAQ. Somente leitura: existe? esta
// na Lixeira? dono, record type, cluster; oportunidades da conta (inclusive excluidas); acesso da Tayza a conta e a cada
// oportunidade (UserRecordAccess); ultimas alteracoes. Filtre por CTA34|.
// v2: declaracoes de colecoes no topo (o parser do Execute Anonymous rejeitou "List<...>" depois de um bloco for).
Id accId = '001V200000lodzIIAQ';
Set<Id> ids = new Set<Id>();
Account[] accs;
Opportunity[] opps;
UserRecordAccess[] acessos;
User tayza = [SELECT Id, Name, Profile.Name, UserRole.Name, Cluster__c FROM User WHERE Name = 'Tayza Apollo' AND IsActive = true LIMIT 1];
System.debug('CTA34| usuaria=' + tayza.Name + ' | perfil=' + tayza.Profile.Name + ' | papel=' + tayza.UserRole.Name + ' | cluster=' + tayza.Cluster__c);

accs = [SELECT Id, Name, IsDeleted, Owner.Name, Owner.IsActive, RecordType.Name, AccountManager__r.Name, Cluster__c, ClusterManual__c,
               CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Account WHERE Id = :accId ALL ROWS];
if (accs.isEmpty()) { System.debug('CTA34| CONTA NAO EXISTE (nem na Lixeira): ' + accId); return; }
Account conta = accs[0];
System.debug('CTA34| CONTA | ' + conta.Name + ' | excluida=' + conta.IsDeleted + ' | dono=' + conta.Owner.Name + (conta.Owner.IsActive ? '' : ' (INATIVO)') + ' | rt=' + conta.RecordType.Name
    + ' | gerente=' + conta.AccountManager__r.Name + ' | cluster=' + conta.Cluster__c + '/' + conta.ClusterManual__c + ' | criada ' + conta.CreatedDate.format('dd/MM/yy') + ' por ' + conta.CreatedBy.Name
    + ' | alterada ' + conta.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + conta.LastModifiedBy.Name);
acessos = [SELECT RecordId, HasReadAccess, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :tayza.Id AND RecordId = :accId];
for (UserRecordAccess u : acessos) System.debug('CTA34| acesso da Tayza a conta: leitura=' + u.HasReadAccess + ' | edicao=' + u.HasEditAccess + ' | nivel=' + u.MaxAccessLevel);

// oportunidades da conta, inclusive na Lixeira
opps = [SELECT Id, Name, IsDeleted, StageName, IsClosed, Owner.Name, Owner.IsActive, RecordType.Name, ManagerAccount__r.Name, Send4Approval__c,
               CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Opportunity WHERE AccountId = :accId ALL ROWS ORDER BY CreatedDate DESC];
System.debug('CTA34| oportunidades da conta (inclusive excluidas): ' + opps.size());
for (Opportunity o : opps) {
    ids.add(o.Id);
    System.debug('CTA34| OPP | ' + o.Id + ' | ' + o.Name.left(60) + ' | ' + (o.IsDeleted ? 'NA LIXEIRA' : 'ativa') + ' | fase=' + o.StageName + ' | fechada=' + o.IsClosed
        + ' | dono=' + o.Owner.Name + (o.Owner.IsActive ? '' : ' (INATIVO)') + ' | rt=' + o.RecordType.Name + ' | gerente=' + o.ManagerAccount__r.Name
        + ' | em aprovacao=' + o.Send4Approval__c + ' | travada=' + (o.IsDeleted ? '-' : String.valueOf(Approval.isLocked(o.Id)))
        + ' | criada ' + o.CreatedDate.format('dd/MM/yy') + ' | alterada ' + o.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + o.LastModifiedBy.Name);
}
if (!ids.isEmpty()) {
    acessos = [SELECT RecordId, HasReadAccess, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :tayza.Id AND RecordId IN :ids];
    for (UserRecordAccess u : acessos) System.debug('CTA34| acesso da Tayza a opp ' + u.RecordId + ': leitura=' + u.HasReadAccess + ' | edicao=' + u.HasEditAccess + ' | nivel=' + u.MaxAccessLevel);
}
// cotacoes e contratos ligados (componentes da pagina que podem quebrar)
Integer nQuotes = ids.isEmpty() ? 0 : [SELECT COUNT() FROM Quote WHERE OpportunityId IN :ids];
Integer nContratos = [SELECT COUNT() FROM Contract WHERE AccountId = :accId];
System.debug('CTA34| cotacoes das opps: ' + nQuotes + ' | contratos da conta: ' + nContratos);
System.debug('CTA34| fim');
