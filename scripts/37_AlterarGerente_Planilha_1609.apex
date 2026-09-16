// 37 - Alteracao do Gerente da conta (Account.AccountManager__c) e do Gerente da Conta da oportunidade (Opportunity.ManagerAccount__c)
// a partir dos arquivos gerados por tools/gerente_conta/validar_gerente.py (A_contas_update.csv e A_opps_update.csv, ja casados
// por Id com a org). Suba os dois CSVs como arquivo (ContentVersion) antes de rodar. NUNCA toca em OwnerId.
// DUAS FASES. EXECUTAR = false: le os arquivos, confere os Ids na org e lista o que faria. EXECUTAR = true: grava.
// Tecnicas herdadas dos scripts 27 e 31 (chamados SENAC e time do Rodrigo):
//  - Conta B2B sem ClusterManual__c: regra de validacao exige cluster no usuario executor -> cluster temporario no executor, limpo ao final.
//  - Oportunidade em "Analise cliente" / "Aguardando contrato": grava ManagerAccount__c junto com Bypass__c = true (o trigger devolve false).
//  - Oportunidade em aprovacao (Send4Approval__c / travada): reatribui o item "Aprovacao - Comercial" pendente ao novo gerente;
//    tenta o campo com unlock/update/lock e, se a regra barrar, deixa para depois da aprovacao (lista no log).
// Fatie por WIN_START/WIN_END se estourar limite (cada execucao = 1 transacao; 1.500 contas cabem em 3 a 4 janelas de 500).
// Filtre o log por GER37|.
Boolean EXECUTAR   = false;
String  FILE_CONTAS = 'A_contas_update';   // trecho do titulo do arquivo (LIKE)
String  FILE_OPPS   = 'A_opps_update';
Integer WIN_START = 0, WIN_END = 500;      // janela sobre as linhas de dados dos CSVs
String  CLUSTER_TMP = 'ALT/GGNET';         // valor usado no script 31; troque se o executor tiver de assumir outro cluster

// ---- leitura de CSV (aspas) do ContentVersion
List<List<String>> lerCsv(String titulo) {
    String like = '%' + titulo + '%';
    List<ContentVersion> cvs = [SELECT Title, VersionData FROM ContentVersion WHERE IsLatest = true AND (Title LIKE :like OR PathOnClient LIKE :like) ORDER BY CreatedDate DESC LIMIT 1];
    List<List<String>> rows = new List<List<String>>();
    if (cvs.isEmpty()) { System.debug('GER37| arquivo nao encontrado: ' + titulo); return rows; }
    String body = cvs[0].VersionData.toString();
    if (body.startsWith('﻿')) body = body.substring(1);
    for (String ln : body.split('\n')) {
        if (String.isBlank(ln.trim())) continue;
        List<String> f = new List<String>(); String cur = ''; Boolean q = false;
        for (Integer i = 0; i < ln.length(); i++) {
            String ch = ln.substring(i, i + 1);
            if (ch == '"') q = !q; else if (ch == ',' && !q) { f.add(cur); cur = ''; } else if (ch != '\r') cur += ch;
        }
        f.add(cur); rows.add(f);
    }
    System.debug('GER37| ' + cvs[0].Title + ': ' + (rows.size() - 1) + ' linha(s) de dados');
    return rows;
}
Map<Id, Id> alvoConta = new Map<Id, Id>(); Map<Id, Id> alvoOpp = new Map<Id, Id>();
List<List<String>> rc = lerCsv(FILE_CONTAS);
for (Integer i = Math.max(1, WIN_START + 1); i < Math.min(rc.size(), WIN_END + 1); i++) if (rc[i].size() >= 2 && rc[i][0].startsWith('001')) alvoConta.put((Id) rc[i][0].trim(), (Id) rc[i][1].trim());
List<List<String>> ro = lerCsv(FILE_OPPS);
for (Integer i = Math.max(1, WIN_START + 1); i < Math.min(ro.size(), WIN_END + 1); i++) if (ro[i].size() >= 2 && ro[i][0].startsWith('006')) alvoOpp.put((Id) ro[i][0].trim(), (Id) ro[i][1].trim());
System.debug('GER37| janela [' + WIN_START + ',' + WIN_END + '): ' + alvoConta.size() + ' conta(s), ' + alvoOpp.size() + ' oportunidade(s)');

// ---- gerentes alvo: ativos
Set<Id> gerIds = new Set<Id>(); gerIds.addAll(alvoConta.values()); gerIds.addAll(alvoOpp.values());
Map<Id, User> gerentes = new Map<Id, User>([SELECT Id, Name, IsActive FROM User WHERE Id IN :gerIds]);
for (Id gid : gerIds) if (!gerentes.containsKey(gid) || !gerentes.get(gid).IsActive) System.debug('GER37| ERRO: gerente alvo inexistente ou inativo: ' + gid);

// ---- contas
List<Account> contas = new List<Account>(); Integer nCluster = 0;
for (Account a : [SELECT Id, Name, AccountManager__c, AccountManager__r.Name, ClusterManual__c, RecordType.Name FROM Account WHERE Id IN :alvoConta.keySet()]) {
    Id novo = alvoConta.get(a.Id);
    if (a.AccountManager__c == novo) { System.debug('GER37| CONTA sem mudanca | ' + a.Name.left(50)); continue; }
    if (!gerentes.containsKey(novo) || !gerentes.get(novo).IsActive) continue;
    Boolean precisaCluster = String.isBlank(a.ClusterManual__c) && a.RecordType.Name != null && a.RecordType.Name.startsWith('B2B');
    if (precisaCluster) nCluster++;
    System.debug('GER37| CONTA | ' + a.Name.left(50) + ' | gerente ' + (a.AccountManager__c == null ? '(vazio)' : a.AccountManager__r.Name) + ' -> ' + gerentes.get(novo).Name + (precisaCluster ? ' | precisa cluster no executor' : ''));
    a.AccountManager__c = novo; contas.add(a);
}
for (Id cid : alvoConta.keySet()) { Boolean achou = false; for (Account a : contas) if (a.Id == cid) achou = true; }
System.debug('GER37| contas a alterar: ' + contas.size() + ' (' + nCluster + ' dependem de cluster no executor)');

// ---- oportunidades
List<Opportunity> oppsLivres = new List<Opportunity>(); List<Opportunity> oppsAprov = new List<Opportunity>();
for (Opportunity o : [SELECT Id, Name, OwnerId, StageName, Bypass__c, Send4Approval__c, ManagerAccount__c, ManagerAccount__r.Name FROM Opportunity WHERE Id IN :alvoOpp.keySet()]) {
    Id novo = alvoOpp.get(o.Id);
    if (o.ManagerAccount__c == novo) { System.debug('GER37| OPP sem mudanca | ' + o.Name.left(50)); continue; }
    if (!gerentes.containsKey(novo) || !gerentes.get(novo).IsActive) continue;
    Boolean travada = Approval.isLocked(o.Id);
    System.debug('GER37| OPP | ' + o.Name.left(50) + ' | fase=' + o.StageName + ' | em aprovacao=' + o.Send4Approval__c + ' | travada=' + travada
        + ' | gerente ' + (o.ManagerAccount__c == null ? '(vazio)' : o.ManagerAccount__r.Name) + ' -> ' + gerentes.get(novo).Name);
    o.ManagerAccount__c = novo;
    if (travada || o.Send4Approval__c == true) oppsAprov.add(o); else oppsLivres.add(o);
}
System.debug('GER37| oportunidades: ' + oppsLivres.size() + ' livre(s) (bypass junto), ' + oppsAprov.size() + ' em aprovacao (reatribuir item)');
if (!EXECUTAR) { System.debug('GER37| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }

// ---- A. contas, com cluster temporario se preciso
User eu = [SELECT Id, Cluster__c FROM User WHERE Id = :UserInfo.getUserId()];
Boolean clusterEraVazio = String.isBlank(eu.Cluster__c);
if (nCluster > 0 && clusterEraVazio) { eu.Cluster__c = CLUSTER_TMP; update eu; System.debug('GER37| cluster temporario no executor: ' + CLUSTER_TMP); }
Integer okA = 0; Boolean falhaCluster = false;
if (!contas.isEmpty()) {
    Database.SaveResult[] ra = Database.update(contas, false);
    for (Integer i = 0; i < ra.size(); i++) {
        if (ra[i].isSuccess()) okA++;
        else { String msg = ra[i].getErrors()[0].getMessage(); if (msg.containsIgnoreCase('cluster')) falhaCluster = true; System.debug('GER37|   falha conta ' + contas[i].Name.left(40) + ' (' + contas[i].Id + '): ' + msg.left(140)); }
    }
}
System.debug('GER37| CONTAS: ' + okA + ' atualizada(s) de ' + contas.size());
if (nCluster > 0 && clusterEraVazio) {
    if (!falhaCluster) { eu.Cluster__c = null; update eu; System.debug('GER37| cluster do executor limpo'); }
    else System.debug('GER37| ATENCAO: a regra leu o cluster antigo; o cluster temporario FICOU no executor. Rode de novo com EXECUTAR = true para concluir e limpar.');
}

// ---- B. oportunidades livres: bypass junto com a troca (o trigger devolve Bypass__c = false no proprio save)
for (Opportunity o : oppsLivres) o.Bypass__c = true;
Integer okO = 0;
if (!oppsLivres.isEmpty()) {
    Database.SaveResult[] rs = Database.update(oppsLivres, false);
    for (Integer i = 0; i < rs.size(); i++) { if (rs[i].isSuccess()) okO++; else System.debug('GER37|   falha opp ' + oppsLivres[i].Name.left(40) + ': ' + rs[i].getErrors()[0].getMessage().left(150)); }
}
System.debug('GER37| OPORTUNIDADES livres: ' + okO + ' atualizada(s) de ' + oppsLivres.size());

// ---- C. oportunidades em aprovacao: reatribui o item pendente e tenta o campo
for (Opportunity o : oppsAprov) {
    Id novo = o.ManagerAccount__c;
    List<FlowOrchestrationWorkItem> itens = [SELECT Id, AssigneeId FROM FlowOrchestrationWorkItem WHERE RelatedRecordId = :o.Id AND Status = 'Assigned' AND Label = 'Aprovação - Comercial' AND AssigneeId != :novo];
    List<ApprovalWorkItem> awis = [SELECT Id, AssignedToId FROM ApprovalWorkItem WHERE RelatedRecordId = :o.Id AND Status = 'Assigned' AND ApprovalConditionName = 'Aprovação - Comercial' AND AssignedToId != :novo];
    for (FlowOrchestrationWorkItem i : itens) i.AssigneeId = novo;
    for (ApprovalWorkItem w : awis) w.AssignedToId = novo;
    try { if (!itens.isEmpty()) update itens; System.debug('GER37| ' + o.Name.left(40) + ' | ' + itens.size() + ' item(ns) de orquestracao reatribuido(s)'); }
    catch (Exception e) { System.debug('GER37| ' + o.Name.left(40) + ' | falha ao reatribuir orquestracao: ' + e.getMessage().left(160)); }
    try { if (!awis.isEmpty()) update awis; System.debug('GER37| ' + o.Name.left(40) + ' | ' + awis.size() + ' item(ns) de aprovacao reatribuido(s)'); }
    catch (Exception e) { System.debug('GER37| ' + o.Name.left(40) + ' | item de aprovacao espelho nao editavel pela API (esperado): ' + e.getMessage().left(100)); }
    Boolean travada = Approval.isLocked(o.Id);
    try {
        if (travada) Approval.unlock(o.Id);
        update o;
        if (travada) Approval.lock(o.Id);
        System.debug('GER37| ' + o.Name.left(40) + ' | ManagerAccount__c atualizado' + (travada ? ' com unlock/lock' : ''));
    } catch (Exception e) {
        if (travada && !Approval.isLocked(o.Id)) { try { Approval.lock(o.Id); } catch (Exception e2) {} }
        System.debug('GER37| ' + o.Name.left(40) + ' | campo NAO atualizado (' + e.getMessage().left(120) + '): ajustar apos a aprovacao. Item ja reatribuido. Travada de novo=' + Approval.isLocked(o.Id));
    }
}
// ---- conferencia
System.debug('GER37| DEPOIS contas ainda sem o gerente alvo: ' + [SELECT COUNT() FROM Account WHERE Id IN :alvoConta.keySet() AND AccountManager__c NOT IN :gerIds]);
System.debug('GER37| DEPOIS opps ainda sem o gerente alvo: ' + [SELECT COUNT() FROM Opportunity WHERE Id IN :alvoOpp.keySet() AND ManagerAccount__c NOT IN :gerIds]);
for (FlowOrchestrationWorkItem i : [SELECT RelatedRecordId, Label, Assignee.Name FROM FlowOrchestrationWorkItem WHERE RelatedRecordId IN :alvoOpp.keySet() AND Status = 'Assigned'])
    System.debug('GER37| DEPOIS item pendente | ' + i.RelatedRecordId + ' | ' + i.Label + ' | designado=' + i.Assignee.Name);
System.debug('GER37| DEPOIS executor cluster=' + [SELECT Cluster__c FROM User WHERE Id = :UserInfo.getUserId()].Cluster__c);
System.debug('GER37| concluido');
