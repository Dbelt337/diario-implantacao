// 35 - Chamado da Tayza (16/09), continuacao do 34: a conta SAMAE (001V200000lodzIIAQ) existe, a Tayza tem acesso total, mas a
// conta NAO tem nenhuma oportunidade (nem na Lixeira), nem cotacao, nem contrato. Hipoteses: a oportunidade esta em outra conta
// SAMAE (duplicada), foi excluida em definitivo (Lixeira esvaziada) ou nunca foi salva. Somente leitura. Filtre por SAM35|.
void run() {
    // 1. contas parecidas (duplicatas), com quantidade de oportunidades
    Map<Id, Account> contas = new Map<Id, Account>([SELECT Id, Name, Owner.Name, IsDeleted, RecordType.Name, CreatedDate FROM Account WHERE Name LIKE '%SAMAE%' OR Name LIKE '%AUTONOMO MUNICIPAL DE AGUA%' OR Name LIKE '%AUTÔNOMO MUNICIPAL DE ÁGUA%' ORDER BY CreatedDate ALL ROWS]);
    Map<Id, Integer> qtd = new Map<Id, Integer>();
    if (!contas.isEmpty()) for (AggregateResult ar : [SELECT AccountId a, COUNT(Id) n FROM Opportunity WHERE AccountId IN :contas.keySet() GROUP BY AccountId]) qtd.put((Id) ar.get('a'), (Integer) ar.get('n'));
    for (Account c : contas.values()) System.debug('SAM35| CONTA | ' + c.Id + ' | ' + c.Name + ' | dono=' + c.Owner.Name + ' | rt=' + c.RecordType.Name + (c.IsDeleted ? ' | NA LIXEIRA' : '') + ' | opps=' + (qtd.containsKey(c.Id) ? qtd.get(c.Id) : 0) + ' | criada ' + c.CreatedDate.format('dd/MM/yy'));
    System.debug('SAM35| contas parecidas: ' + contas.size());
    // 2. oportunidades com SAMAE no nome, em qualquer conta, inclusive na Lixeira
    for (Opportunity o : [SELECT Id, Name, Account.Name, Owner.Name, StageName, IsDeleted, CreatedBy.Name, CreatedDate, LastModifiedDate FROM Opportunity WHERE Name LIKE '%SAMAE%' ORDER BY CreatedDate DESC ALL ROWS]) {
        System.debug('SAM35| OPP | ' + o.Id + ' | ' + o.Name.left(60) + ' | conta=' + o.Account.Name + ' | dono=' + o.Owner.Name + ' | fase=' + o.StageName + (o.IsDeleted ? ' | NA LIXEIRA' : '') + ' | criada ' + o.CreatedDate.format('dd/MM/yy') + ' por ' + o.CreatedBy.Name + ' | alterada ' + o.LastModifiedDate.format('dd/MM HH:mm'));
    }
    // 3. ultimas oportunidades que a Tayza criou ou alterou (caso o nome nao tenha SAMAE)
    User tayza = [SELECT Id FROM User WHERE Name = 'Tayza Apollo' AND IsActive = true LIMIT 1];
    for (Opportunity o : [SELECT Id, Name, Account.Name, Owner.Name, StageName, IsDeleted, CreatedDate, LastModifiedDate FROM Opportunity WHERE (CreatedById = :tayza.Id OR LastModifiedById = :tayza.Id) AND LastModifiedDate = LAST_N_DAYS:7 ORDER BY LastModifiedDate DESC LIMIT 15 ALL ROWS]) {
        System.debug('SAM35| OPP DA TAYZA (7 dias) | ' + o.Id + ' | ' + o.Name.left(60) + ' | conta=' + o.Account.Name + ' | dono=' + o.Owner.Name + ' | fase=' + o.StageName + (o.IsDeleted ? ' | NA LIXEIRA' : '') + ' | alterada ' + o.LastModifiedDate.format('dd/MM HH:mm'));
    }
    System.debug('SAM35| fim');
}
run();
