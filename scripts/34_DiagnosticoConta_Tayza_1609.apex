// 34 - Chamado da Tayza (16/09): "nao consigo ver esta opp", link da CONTA 001V200000lodzIIAQ. Somente leitura: existe? esta
// na Lixeira? dono, record type, cluster; oportunidades da conta (inclusive excluidas); acesso da Tayza a conta e a cada
// oportunidade (UserRecordAccess); ultimas alteracoes. Filtre por CTA34|.
// v3: corpo dentro de um metodo (o parser do Execute Anonymous rejeitou declaracoes/atribuicoes no nivel raiz apos os loops).
void run() {
    Id accId = '001V200000lodzIIAQ';
    User tayza = [SELECT Id, Name, Profile.Name, UserRole.Name, Cluster__c FROM User WHERE Name = 'Tayza Apollo' AND IsActive = true LIMIT 1];
    System.debug('CTA34| usuaria=' + tayza.Name + ' | perfil=' + tayza.Profile.Name + ' | papel=' + tayza.UserRole.Name + ' | cluster=' + tayza.Cluster__c);

    List<Account> accs = [SELECT Id, Name, IsDeleted, Owner.Name, Owner.IsActive, RecordType.Name, AccountManager__r.Name, Cluster__c, ClusterManual__c,
                                 CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Account WHERE Id = :accId ALL ROWS];
    if (accs.isEmpty()) { System.debug('CTA34| CONTA NAO EXISTE (nem na Lixeira): ' + accId); return; }
    Account conta = accs[0];
    String donoAtivo = conta.Owner.IsActive ? '' : ' (INATIVO)';
    System.debug('CTA34| CONTA | ' + conta.Name + ' | excluida=' + conta.IsDeleted + ' | dono=' + conta.Owner.Name + donoAtivo + ' | rt=' + conta.RecordType.Name
        + ' | gerente=' + conta.AccountManager__r.Name + ' | cluster=' + conta.Cluster__c + '/' + conta.ClusterManual__c + ' | criada ' + conta.CreatedDate.format('dd/MM/yy') + ' por ' + conta.CreatedBy.Name
        + ' | alterada ' + conta.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + conta.LastModifiedBy.Name);
    List<UserRecordAccess> acessos = [SELECT RecordId, HasReadAccess, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :tayza.Id AND RecordId = :accId];
    for (UserRecordAccess u : acessos) {
        System.debug('CTA34| acesso da Tayza a conta: leitura=' + u.HasReadAccess + ' | edicao=' + u.HasEditAccess + ' | nivel=' + u.MaxAccessLevel);
    }

    // oportunidades da conta, inclusive na Lixeira
    List<Opportunity> opps = [SELECT Id, Name, IsDeleted, StageName, IsClosed, Owner.Name, Owner.IsActive, RecordType.Name, ManagerAccount__r.Name, Send4Approval__c,
                                     CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Opportunity WHERE AccountId = :accId ALL ROWS ORDER BY CreatedDate DESC];
    System.debug('CTA34| oportunidades da conta (inclusive excluidas): ' + opps.size());
    Set<Id> ids = new Set<Id>();
    for (Opportunity o : opps) {
        ids.add(o.Id);
        String estado = o.IsDeleted ? 'NA LIXEIRA' : 'ativa';
        String dono = o.Owner.IsActive ? '' : ' (INATIVO)';
        String travada = o.IsDeleted ? '-' : String.valueOf(Approval.isLocked(o.Id));
        System.debug('CTA34| OPP | ' + o.Id + ' | ' + o.Name.left(60) + ' | ' + estado + ' | fase=' + o.StageName + ' | fechada=' + o.IsClosed
            + ' | dono=' + o.Owner.Name + dono + ' | rt=' + o.RecordType.Name + ' | gerente=' + o.ManagerAccount__r.Name
            + ' | em aprovacao=' + o.Send4Approval__c + ' | travada=' + travada
            + ' | criada ' + o.CreatedDate.format('dd/MM/yy') + ' | alterada ' + o.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + o.LastModifiedBy.Name);
    }
    if (!ids.isEmpty()) {
        List<UserRecordAccess> acessosOpp = [SELECT RecordId, HasReadAccess, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId = :tayza.Id AND RecordId IN :ids];
        for (UserRecordAccess u : acessosOpp) {
            System.debug('CTA34| acesso da Tayza a opp ' + u.RecordId + ': leitura=' + u.HasReadAccess + ' | edicao=' + u.HasEditAccess + ' | nivel=' + u.MaxAccessLevel);
        }
    }
    // cotacoes e contratos ligados (componentes da pagina que podem quebrar)
    Integer nQuotes = 0;
    if (!ids.isEmpty()) nQuotes = [SELECT COUNT() FROM Quote WHERE OpportunityId IN :ids];
    Integer nContratos = [SELECT COUNT() FROM Contract WHERE AccountId = :accId];
    System.debug('CTA34| cotacoes das opps: ' + nQuotes + ' | contratos da conta: ' + nContratos);
    System.debug('CTA34| fim');
}
run();
