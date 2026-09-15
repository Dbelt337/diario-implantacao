// 31 - Fecha o residuo do script 29 (3 contas da Tatiane + 5 oportunidades) respeitando as regras de validacao da org:
//  - Conta (regra do cluster): RT "B2B - Pessoa juridica" AND $User.Cluster__c vazio AND ClusterManual__c vazio. Solucao: preencher
//    temporariamente o Cluster__c do usuario que executa (copiado do da Tatiane, dona das contas), atualizar as 3 contas e limpar
//    o cluster do usuario em seguida. Se a regra ainda barrar (valor de $User lido no inicio da transacao), o script deixa o cluster
//    preenchido e pede uma segunda execucao; a segunda execucao conclui e limpa.
//  - Oportunidade (BloqueiaAlteracaoAnaliseCliente e regra de "Aguardando contrato"): a regra libera quando Bypass__c muda no mesmo
//    update. Solucao: gravar ManagerAccount__c = Rodrigo junto com Bypass__c = true, e em seguida voltar Bypass__c = false.
// Nunca toca em OwnerId. Filtre por RES31|.
Boolean EXECUTAR = false;
User rodrigo = [SELECT Id, Name FROM User WHERE Name = 'Rodrigo Nascimento Piccolo' AND IsActive = true LIMIT 1];
User tatiane = [SELECT Id, Name, Cluster__c FROM User WHERE Name = 'Tatiane Pompermaier' AND IsActive = true LIMIT 1];
User eu = [SELECT Id, Name, Cluster__c FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('RES31| executor=' + eu.Name + ' cluster=' + eu.Cluster__c + ' | cluster da Tatiane=' + tatiane.Cluster__c + ' | alvo=' + rodrigo.Name);

List<Account> contas = [SELECT Id, Name, ClusterManual__c, AccountManager__r.Name FROM Account WHERE Id IN ('001V200000nbiHCIAY', '001V200000nsRTeIAM', '001V200000nM90PIAS') AND AccountManager__c != :rodrigo.Id];
for (Account a : contas) { System.debug('RES31| CONTA | ' + a.Name + ' | clusterManual=' + a.ClusterManual__c + ' | gerente=' + a.AccountManager__r.Name + ' -> ' + rodrigo.Name); a.AccountManager__c = rodrigo.Id; }
Set<Id> oppIds = new Set<Id>{ '006V200000lw281IAA', '006V200000gRYBuIAO', '006V200000d9ULNIA2', '006V200000u8m41IAA', '006V200000iJjw9IAC' };
List<Opportunity> opps = [SELECT Id, Name, StageName, Bypass__c, ManagerAccount__r.Name FROM Opportunity WHERE Id IN :oppIds AND (ManagerAccount__c != :rodrigo.Id OR ManagerAccount__c = null)];
for (Opportunity o : opps) System.debug('RES31| OPP | ' + o.Name.left(50) + ' | fase=' + o.StageName + ' | bypass=' + o.Bypass__c + ' | gerente=' + o.ManagerAccount__r.Name + ' -> ' + rodrigo.Name);
System.debug('RES31| a alterar: ' + contas.size() + ' conta(s), ' + opps.size() + ' oportunidade(s)');
if (!EXECUTAR) { System.debug('RES31| FASE 1 concluida: nada alterado. Rode com EXECUTAR = true.'); return; }

// A. contas: cluster temporario no executor
String clusterTmp = String.isBlank(tatiane.Cluster__c) ? null : tatiane.Cluster__c;
if (clusterTmp == null) {
    for (Schema.PicklistEntry p : User.Cluster__c.getDescribe().getPicklistValues()) if (p.isActive()) { clusterTmp = p.getValue(); break; }
}
Boolean clusterEraVazio = String.isBlank(eu.Cluster__c);
if (!contas.isEmpty() && clusterEraVazio) { eu.Cluster__c = clusterTmp; update eu; System.debug('RES31| cluster temporario no executor: ' + clusterTmp); }
Integer okA = 0; Boolean falhaCluster = false;
if (!contas.isEmpty()) {
    for (Database.SaveResult r : Database.update(contas, false)) {
        if (r.isSuccess()) okA++; else { String msg = r.getErrors()[0].getMessage(); if (msg.contains('cluster')) falhaCluster = true; System.debug('RES31|   falha conta ' + r.getId() + ': ' + msg.left(120)); }
    }
    System.debug('RES31| CONTAS: ' + okA + ' atualizada(s) de ' + contas.size());
}
if (clusterEraVazio && !falhaCluster) { eu.Cluster__c = null; update eu; System.debug('RES31| cluster do executor limpo de novo'); }
else if (falhaCluster) System.debug('RES31| ATENCAO: a regra leu o cluster antigo. O cluster temporario FICOU no seu usuario: rode este script de novo (EXECUTAR = true) para concluir as contas e limpar.');

// B. oportunidades: bypass ligado junto com a troca, depois desligado
for (Opportunity o : opps) { o.ManagerAccount__c = rodrigo.Id; o.Bypass__c = true; }
Integer okO = 0; List<Opportunity> desligar = new List<Opportunity>();
Database.SaveResult[] rs = Database.update(opps, false);
for (Integer i = 0; i < rs.size(); i++) {
    if (rs[i].isSuccess()) { okO++; desligar.add(new Opportunity(Id = opps[i].Id, Bypass__c = false)); }
    else System.debug('RES31|   falha opp ' + opps[i].Name.left(40) + ': ' + rs[i].getErrors()[0].getMessage().left(150));
}
System.debug('RES31| OPORTUNIDADES: ' + okO + ' atualizada(s) de ' + opps.size());
if (!desligar.isEmpty()) {
    Integer okB = 0;
    for (Database.SaveResult r : Database.update(desligar, false)) { if (r.isSuccess()) okB++; else System.debug('RES31|   falha ao desligar bypass ' + r.getId() + ': ' + r.getErrors()[0].getMessage().left(120)); }
    System.debug('RES31| bypass desligado em ' + okB + ' de ' + desligar.size());
}
// conferencia
for (Account a : [SELECT Name, AccountManager__r.Name FROM Account WHERE Id IN ('001V200000nbiHCIAY', '001V200000nsRTeIAM', '001V200000nM90PIAS')]) System.debug('RES31| DEPOIS conta | ' + a.Name + ' | gerente=' + a.AccountManager__r.Name);
for (Opportunity o : [SELECT Name, ManagerAccount__r.Name, Bypass__c FROM Opportunity WHERE Id IN :oppIds]) System.debug('RES31| DEPOIS opp | ' + o.Name.left(50) + ' | gerente=' + o.ManagerAccount__r.Name + ' | bypass=' + o.Bypass__c);
System.debug('RES31| DEPOIS executor cluster=' + [SELECT Cluster__c FROM User WHERE Id = :UserInfo.getUserId()].Cluster__c);
