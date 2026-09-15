// 25 - Fase 2 do diagnostico da Opportunity 006V200000yiZh3IAE (producao). O script 24 mostrou: NENHUM processo de aprovacao
// (ProcessInstance) na oportunidade e NENHUMA definicao ativa de aprovacao em Opportunity; a fase e "Aprovacao comercial" desde
// 03/09 e o campo ManagerAccount__c (lookup de usuario) aponta para o proprio dono (Hermes). Este script descobre o mecanismo:
// de onde vem o ManagerAccount__c (conta), quem consome (flows ativos de Opportunity, tasks, alertas), historico de fase e
// aprovacoes em cotacoes da oportunidade. Somente leitura. Filtre o log por APR25|.
Id oppId = '006V200000yiZh3IAE';
Opportunity o = [SELECT Id, Name, StageName, OwnerId, Owner.Name, AccountId, Account.Name, Account.OwnerId, Account.Owner.Name, ManagerAccount__c, ManagerAccount__r.Name, CreatedDate FROM Opportunity WHERE Id = :oppId];
Schema.DescribeFieldResult df = Schema.SObjectType.Opportunity.fields.getMap().get('ManagerAccount__c').getDescribe();
System.debug('APR25| CAMPO ManagerAccount__c | rotulo="' + df.getLabel() + '" | formula=' + df.isCalculated() + ' | ajuda=' + df.getInlineHelpText());
System.debug('APR25| OPP | ' + o.Name + ' | fase=' + o.StageName + ' | dono=' + o.Owner.Name + ' | ManagerAccount__c=' + o.ManagerAccount__r.Name
    + ' | conta=' + o.Account.Name + ' | dono da conta=' + o.Account.Owner.Name + ' | criada ' + o.CreatedDate.format('dd/MM HH:mm'));

// campos de usuario da CONTA (origem provavel do ManagerAccount__c)
Map<String, Schema.SObjectField> fm = Schema.SObjectType.Account.fields.getMap();
List<String> uf = new List<String>();
for (String f : fm.keySet()) {
    Schema.DescribeFieldResult d = fm.get(f).getDescribe();
    if (d.getType() == Schema.DisplayType.REFERENCE && !d.getReferenceTo().isEmpty() && d.getReferenceTo()[0] == User.SObjectType) uf.add(d.getName());
}
if (o.AccountId != null) {
    Id accId = o.AccountId;
    SObject a = Database.query('SELECT ' + String.join(uf, ', ') + ' FROM Account WHERE Id = :accId');
    for (String f : uf) { Id v = (Id) a.get(f); if (v != null) System.debug('APR25| CONTA CAMPO USUARIO | ' + f + ' (' + fm.get(f).getDescribe().getLabel() + ') = ' + [SELECT Name FROM User WHERE Id = :v].Name + (v == o.OwnerId ? ' (= dono da opp)' : '')); }
}
// historico de fases e do campo (se rastreado)
for (OpportunityHistory h : [SELECT StageName, Amount, CreatedBy.Name, CreatedDate FROM OpportunityHistory WHERE OpportunityId = :oppId ORDER BY CreatedDate]) {
    System.debug('APR25| FASE | ' + h.CreatedDate.format('dd/MM HH:mm') + ' | ' + h.StageName + ' | por ' + h.CreatedBy.Name);
}
try {
    for (OpportunityFieldHistory h : Database.query('SELECT Field, OldValue, NewValue, CreatedBy.Name, CreatedDate FROM OpportunityFieldHistory WHERE OpportunityId = :oppId ORDER BY CreatedDate')) {
        System.debug('APR25| HIST CAMPO | ' + h.CreatedDate.format('dd/MM HH:mm') + ' | ' + h.Field + ' | ' + h.OldValue + ' -> ' + h.NewValue + ' | ' + h.CreatedBy.Name);
    }
} catch (Exception e) { System.debug('APR25| historico de campos indisponivel: ' + e.getMessage().left(100)); }
// tasks e eventos ligados a oportunidade (a "aprovacao" pode ser uma tarefa atribuida)
for (Task t : [SELECT Subject, Status, Owner.Name, CreatedBy.Name, CreatedDate, ActivityDate FROM Task WHERE WhatId = :oppId ORDER BY CreatedDate]) {
    System.debug('APR25| TASK | ' + t.CreatedDate.format('dd/MM HH:mm') + ' | ' + t.Subject + ' | ' + t.Status + ' | dono=' + t.Owner.Name + ' | criada por ' + t.CreatedBy.Name);
}
// cotacoes da oportunidade e processos de aprovacao nelas
Set<Id> ids = new Set<Id>();
for (Quote q : [SELECT Id, Name, Status, Owner.Name FROM Quote WHERE OpportunityId = :oppId]) { ids.add(q.Id); System.debug('APR25| COTACAO | ' + q.Name + ' | ' + q.Status + ' | dono=' + q.Owner.Name + ' | ' + q.Id); }
for (ProcessInstance pi : [SELECT TargetObjectId, Status, ProcessDefinition.Name, SubmittedBy.Name, CreatedDate, (SELECT Actor.Name, OriginalActor.Name FROM Workitems), (SELECT ProcessNodeName, NodeStatus, LastActor.Name FROM Nodes) FROM ProcessInstance WHERE TargetObjectId IN :ids]) {
    System.debug('APR25| APROVACAO COTACAO | ' + pi.ProcessDefinition.Name + ' | ' + pi.Status + ' | por ' + pi.SubmittedBy.Name + ' em ' + pi.CreatedDate.format('dd/MM HH:mm'));
    for (ProcessInstanceNode n : pi.Nodes) System.debug('APR25|   NO | ' + n.ProcessNodeName + ' | ' + n.NodeStatus + ' | ' + n.LastActor.Name);
    for (ProcessInstanceWorkitem w : pi.Workitems) System.debug('APR25|   PENDENTE | ' + w.Actor.Name + ' | original=' + w.OriginalActor.Name);
}
// todas as definicoes de aprovacao ativas da org (qualquer objeto) e flows ativos disparados por Opportunity
for (ProcessDefinition pd : [SELECT Name, DeveloperName, TableEnumOrId FROM ProcessDefinition WHERE State = 'Active' ORDER BY TableEnumOrId]) System.debug('APR25| DEF APROVACAO ATIVA | ' + pd.TableEnumOrId + ' | ' + pd.Name);
try {
    for (FlowDefinitionView fv : Database.query('SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel, IsActive, LastModifiedDate FROM FlowDefinitionView WHERE IsActive = true AND (TriggerObjectOrEventLabel = \'Opportunity\' OR TriggerObjectOrEventLabel = \'Oportunidade\' OR Label LIKE \'%provac%\' OR Label LIKE \'%Opp%\') ORDER BY Label')) {
        System.debug('APR25| FLOW ATIVO | ' + fv.Label + ' (' + fv.ApiName + ') | ' + fv.ProcessType + ' | ' + fv.TriggerType + ' | objeto=' + fv.TriggerObjectOrEventLabel + ' | alterado ' + fv.LastModifiedDate);
    }
} catch (Exception e) { System.debug('APR25| FlowDefinitionView indisponivel: ' + e.getMessage().left(120)); }
System.debug('APR25| fim');
