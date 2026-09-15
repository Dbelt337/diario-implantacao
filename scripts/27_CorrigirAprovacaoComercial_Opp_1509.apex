// 27 - Correcao da aprovacao comercial B2B que caiu no proprio dono (chamado da Tayza, 15/09). Diagnostico (scripts 24-26):
// a aprovacao e a orquestracao OpportunityApprovalSteps_B2B; o item "Aprovacao - Comercial" e designado ao campo
// Opportunity.ManagerAccount__c (Gerente da Conta), que estava com o dono. Correcao, por oportunidade da lista:
//   1. ManagerAccount__c da oportunidade <- AccountManager__c da conta (se o registro estiver travado pela aprovacao,
//      tenta Approval.unlock / update / Approval.lock; se nao conseguir, avisa e segue: o campo so importa no proximo envio);
//   2. reatribui o item pendente: FlowOrchestrationWorkItem.AssigneeId e ApprovalWorkItem.AssignedToId <- gerente da conta.
// DUAS FASES: EXECUTAR = false so mostra o que faria. Travas: so mexe em item com Status Assigned, Label "Aprovacao - Comercial"
// e designado igual ao dono; o novo designado precisa ser usuario ativo e diferente do dono. Filtre o log por FIX27|.
Boolean EXECUTAR = false;
Set<Id> opps = new Set<Id>{ '006V200000yiZh3IAE' };   // SENAC SC. Para incluir PATRUS, acrescente o Id dela aqui.

for (Opportunity o : [SELECT Id, Name, OwnerId, Owner.Name, ManagerAccount__c, ManagerAccount__r.Name, Account.Name,
                             Account.AccountManager__c, Account.AccountManager__r.Name, Account.AccountManager__r.IsActive
                      FROM Opportunity WHERE Id IN :opps]) {
    Id novo = o.Account.AccountManager__c;
    System.debug('FIX27| ' + o.Name + ' | dono=' + o.Owner.Name + ' | gerente na opp=' + o.ManagerAccount__r.Name + ' | gerente na conta=' + o.Account.AccountManager__r.Name);
    if (novo == null || novo == o.OwnerId || o.Account.AccountManager__r.IsActive != true) {
        System.debug('FIX27| ' + o.Name + ' | TRAVA: gerente da conta vazio, igual ao dono ou inativo - nada feito'); continue;
    }
    // itens pendentes da aprovacao comercial designados ao dono
    List<FlowOrchestrationWorkItem> itens = [SELECT Id, Label, Status, AssigneeId FROM FlowOrchestrationWorkItem
                                             WHERE RelatedRecordId = :o.Id AND Status = 'Assigned' AND Label = 'Aprovação - Comercial' AND AssigneeId = :o.OwnerId];
    List<ApprovalWorkItem> awis = [SELECT Id, Name, Status, AssignedToId, ApprovalConditionName FROM ApprovalWorkItem
                                   WHERE RelatedRecordId = :o.Id AND Status = 'Assigned' AND ApprovalConditionName = 'Aprovação - Comercial' AND AssignedToId = :o.OwnerId];
    System.debug('FIX27| ' + o.Name + ' | itens de orquestracao a reatribuir=' + itens.size() + ' | itens de aprovacao a reatribuir=' + awis.size() + ' | novo designado=' + o.Account.AccountManager__r.Name);
    if (!EXECUTAR) continue;

    // 1. campo Gerente da Conta na oportunidade
    if (o.ManagerAccount__c != novo) {
        o.ManagerAccount__c = novo;
        try { update o; System.debug('FIX27| ' + o.Name + ' | ManagerAccount__c atualizado'); }
        catch (Exception e1) {
            System.debug('FIX27| ' + o.Name + ' | update direto falhou (' + e1.getMessage().left(120) + '); tentando unlock/update/lock');
            try {
                Approval.unlock(o.Id); update o; Approval.lock(o.Id);
                System.debug('FIX27| ' + o.Name + ' | ManagerAccount__c atualizado com unlock/lock');
            } catch (Exception e2) { System.debug('FIX27| ' + o.Name + ' | NAO foi possivel atualizar o campo: ' + e2.getMessage().left(150) + ' (ajustar manualmente; a reatribuicao segue)'); }
        }
    }
    // 2. reatribuicao dos itens pendentes
    for (FlowOrchestrationWorkItem i : itens) i.AssigneeId = novo;
    for (ApprovalWorkItem a : awis) a.AssignedToId = novo;
    try { if (!itens.isEmpty()) update itens; System.debug('FIX27| ' + o.Name + ' | ' + itens.size() + ' item(ns) de orquestracao reatribuido(s)'); }
    catch (Exception e) { System.debug('FIX27| ' + o.Name + ' | falha ao reatribuir orquestracao: ' + e.getMessage().left(200)); }
    try { if (!awis.isEmpty()) update awis; System.debug('FIX27| ' + o.Name + ' | ' + awis.size() + ' item(ns) de aprovacao reatribuido(s)'); }
    catch (Exception e) { System.debug('FIX27| ' + o.Name + ' | falha ao reatribuir item de aprovacao: ' + e.getMessage().left(200)); }
}
// conferencia
for (FlowOrchestrationWorkItem i : [SELECT RelatedRecordId, Label, Status, Assignee.Name, ElapsedTimeSinceAsgntInSec FROM FlowOrchestrationWorkItem WHERE RelatedRecordId IN :opps AND Status = 'Assigned']) {
    System.debug('FIX27| DEPOIS | ' + i.RelatedRecordId + ' | ' + i.Label + ' | designado=' + i.Assignee.Name);
}
for (Opportunity o : [SELECT Name, ManagerAccount__r.Name FROM Opportunity WHERE Id IN :opps]) System.debug('FIX27| DEPOIS | ' + o.Name + ' | gerente na opp=' + o.ManagerAccount__r.Name);
System.debug('FIX27| concluido (EXECUTAR=' + EXECUTAR + ')');
