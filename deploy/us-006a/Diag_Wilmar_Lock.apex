/* ============================================================================
   US-006a — DIAGNÓSTICO do erro do Wilmar (READ ONLY). Filtrar log por: WLK
   CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY em 001WK00002Osu3CYAR
   NÃO usa Approval.isLocked() (preferência de lock/unlock via Apex desligada).
   ============================================================================ */
final String P = 'WLK | ';
final Id accId = '001WK00002Osu3CYAR';

/* 1 — Aprovações na conta: Pending = conta TRAVADA (causa provável do erro) */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 1 ProcessInstance (aprovacoes) da conta ===');
    Integer pend = 0;
    for (ProcessInstance pi : [SELECT Status, ProcessDefinition.DeveloperName, ProcessDefinition.Name,
                                      CreatedDate, CompletedDate
                               FROM ProcessInstance WHERE TargetObjectId = :accId
                               ORDER BY CreatedDate DESC]) {
        System.debug(LoggingLevel.ERROR, P+'PI ['+pi.ProcessDefinition.DeveloperName+'] status='+pi.Status
            +' criada='+pi.CreatedDate+' concluida='+pi.CompletedDate);
        if (pi.Status == 'Pending') pend++;
    }
    if (pend == 0) System.debug(LoggingLevel.ERROR, P+'NENHUMA aprovacao Pending -> conta NAO esta travada por aprovacao');
    else System.debug(LoggingLevel.ERROR, P+'>>> '+pend+' aprovacao(oes) PENDING -> CONTA TRAVADA (isto causa o CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY)');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'1 ERRO: '+e.getMessage()); }

/* 2 — Passos pendentes (quem e o aprovador atual, se travada) */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2 ProcessInstanceWorkitem (aprovador atual) ===');
    Integer w = 0;
    for (ProcessInstanceWorkitem wi : [SELECT Actor.Name, ProcessInstance.ProcessDefinition.DeveloperName,
                                              ProcessInstance.Status
                                       FROM ProcessInstanceWorkitem
                                       WHERE ProcessInstance.TargetObjectId = :accId]) {
        System.debug(LoggingLevel.ERROR, P+'WORKITEM aprovador='+wi.Actor.Name
            +' AP='+wi.ProcessInstance.ProcessDefinition.DeveloperName+' status='+wi.ProcessInstance.Status);
        w++;
    }
    if (w == 0) System.debug(LoggingLevel.ERROR, P+'nenhum workitem aberto');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2 ERRO: '+e.getMessage()); }

/* 3 — Triggers Apex ativos em Account (podem lancar o mesmo erro) */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 3 ApexTriggers em Account ===');
    Integer t = 0;
    for (ApexTrigger tr : [SELECT Name, Status FROM ApexTrigger WHERE TableEnumOrId = 'Account']) {
        System.debug(LoggingLevel.ERROR, P+'TRIGGER '+tr.Name+' status='+tr.Status); t++;
    }
    if (t == 0) System.debug(LoggingLevel.ERROR, P+'nenhum ApexTrigger em Account (limpo)');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'3 ERRO: '+e.getMessage()); }

/* 4 — Estado atual dos campos-chave da conta (status) */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 4 Snapshot da conta ===');
    Account a = [SELECT Name, SensitiveChangeStatus__c FROM Account WHERE Id = :accId];
    System.debug(LoggingLevel.ERROR, P+'Name='+a.Name+' status='+a.SensitiveChangeStatus__c);
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'4 ERRO: '+e.getMessage()); }

System.debug(LoggingLevel.ERROR, P+'=== FIM WLK ===');
