/* ============================================================================
   US-004 Lead_BS_ObligatoriedadMotos — FASE 0 (READ ONLY). Filtrar log por: OM
   ============================================================================ */
final String P = 'OM | ';

/* 2.1 Lead.Status — confirmar que 'En contacto' e o API value do gate */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.1 Lead.Status ===');
    for (Schema.PicklistEntry pe : Lead.Status.getDescribe().getPicklistValues())
        System.debug(LoggingLevel.ERROR, P+'STATUS value=['+pe.getValue()+'] label=['+pe.getLabel()+']');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.1 ERRO: '+e.getMessage()); }

/* 2.2 Custom Permission Bypass_Gates_Automacao ja existe? */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.2 CustomPermission ===');
    Integer c = 0;
    for (CustomPermission cp : [SELECT DeveloperName, MasterLabel FROM CustomPermission WHERE DeveloperName='Bypass_Gates_Automacao']) {
        System.debug(LoggingLevel.ERROR, P+'JA EXISTE: '+cp.DeveloperName+' ('+cp.MasterLabel+') -> REMOVER do pacote'); c++;
    }
    if (c==0) System.debug(LoggingLevel.ERROR, P+'NAO existe -> o pacote cria (manter no zip)');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.2 ERRO: '+e.getMessage()); }

/* 2.4 Lead.Industry — 'Motos' existe? quais os outros (p/ T7)? */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.4 Lead.Industry ===');
    for (Schema.PicklistEntry pe : Lead.Industry.getDescribe().getPicklistValues())
        System.debug(LoggingLevel.ERROR, P+'INDUSTRY value=['+pe.getValue()+'] label=['+pe.getLabel()+']');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.4 ERRO: '+e.getMessage()); }

/* 2.5 Flow — versao ativa (rollback) */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.5 Flow Lead_BS_ObligatoriedadMotos ===');
    for (FlowDefinitionView f : [SELECT ApiName, Label, ActiveVersionId, IsActive, TriggerType, RecordTriggerType, TriggerObjectOrEventLabel
                                 FROM FlowDefinitionView WHERE ApiName='Lead_BS_ObligatoriedadMotos'])
        System.debug(LoggingLevel.ERROR, P+'FLOW active='+f.IsActive+' activeVerId='+f.ActiveVersionId
            +' trig='+f.TriggerType+'/'+f.RecordTriggerType+' obj='+f.TriggerObjectOrEventLabel);
    System.debug(LoggingLevel.ERROR, P+'(anote o numero da versao ativa no Flow Builder p/ rollback)');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.5 ERRO: '+e.getMessage()); }

/* 2.3 pista — usuarios de integracao ativos + seus permission sets */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.3 candidatos Integration User + PS ===');
    List<User> us = [SELECT Id, Name, Username FROM User
                     WHERE IsActive=true AND (Name LIKE '%ntegra%' OR Username LIKE '%integ%' OR Username LIKE '%mule%' OR Name LIKE '%API%')];
    if (us.isEmpty()) System.debug(LoggingLevel.ERROR, P+'nenhum candidato obvio - identificar manualmente o user do MuleSoft');
    for (User u : us) {
        System.debug(LoggingLevel.ERROR, P+'USER '+u.Name+' | '+u.Username);
        for (PermissionSetAssignment psa : [SELECT PermissionSet.Name FROM PermissionSetAssignment
                                            WHERE AssigneeId=:u.Id AND PermissionSet.IsOwnedByProfile=false])
            System.debug(LoggingLevel.ERROR, P+'   PS: '+psa.PermissionSet.Name);
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.3 ERRO: '+e.getMessage()); }

System.debug(LoggingLevel.ERROR, P+'=== FIM OM FASE 0 ===');
