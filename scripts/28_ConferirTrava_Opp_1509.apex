// 28 - Pos-correcao da Opportunity 006V200000yiZh3IAE (script 27, fase 2, 15/09 ~18h): o item de orquestracao "Aprovacao -
// Comercial" foi reatribuido ao Samuel Helbig; o ApprovalWorkItem nao aceita update (campos padrao somente leitura); o campo
// ManagerAccount__c nao pode ser gravado por regra de validacao ("nao e possivel ao usuario 'Vendedor/GR' editar ... enquanto o
// registro esta em aprovacao"). Efeito colateral: o Approval.unlock rodou e o update falhou antes do Approval.lock, entao a
// oportunidade pode ter ficado DESTRAVADA. Este script confere e, com RELOCK = true, trava de novo. Filtre por CHK28|.
Boolean RELOCK = false;
Id oppId = '006V200000yiZh3IAE';
Boolean travada = Approval.isLocked(oppId);
System.debug('CHK28| oportunidade travada pela aprovacao? ' + travada);
for (FlowOrchestrationWorkItem i : [SELECT Label, Status, Assignee.Name, LastModifiedDate FROM FlowOrchestrationWorkItem WHERE RelatedRecordId = :oppId AND Status = 'Assigned']) {
    System.debug('CHK28| item de orquestracao | ' + i.Label + ' | ' + i.Status + ' | designado=' + i.Assignee.Name + ' | alterado ' + i.LastModifiedDate.format('dd/MM HH:mm'));
}
for (ApprovalWorkItem a : [SELECT Name, Status, AssignedTo.Name, ApprovalConditionName, LastModifiedDate FROM ApprovalWorkItem WHERE RelatedRecordId = :oppId AND Status = 'Assigned']) {
    System.debug('CHK28| item de aprovacao | ' + a.Name + ' | ' + a.ApprovalConditionName + ' | designado=' + a.AssignedTo.Name + ' | alterado ' + a.LastModifiedDate.format('dd/MM HH:mm'));
}
Opportunity o = [SELECT Name, StageName, ManagerAccount__r.Name, Send4Approval__c, LastModifiedBy.Name, LastModifiedDate FROM Opportunity WHERE Id = :oppId];
System.debug('CHK28| ' + o.Name + ' | fase=' + o.StageName + ' | gerente na opp=' + o.ManagerAccount__r.Name + ' | Send4Approval=' + o.Send4Approval__c + ' | ultima alteracao ' + o.LastModifiedBy.Name + ' ' + o.LastModifiedDate.format('dd/MM HH:mm'));
if (!travada && RELOCK) {
    Approval.LockResult r = Approval.lock(oppId);
    System.debug('CHK28| relock: ' + (r.isSuccess() ? 'OK, travada de novo' : 'FALHOU: ' + r.getErrors()));
    System.debug('CHK28| travada agora? ' + Approval.isLocked(oppId));
} else if (!travada) System.debug('CHK28| DESTRAVADA: rode com RELOCK = true para restaurar a trava da aprovacao');
