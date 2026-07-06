/* US-006a — valores validos de SensitiveChangeStatus__c + apply flows ativos. Filtro: SST */
final String P = 'SST | ';
for (Schema.PicklistEntry pe : Account.SensitiveChangeStatus__c.getDescribe().getPicklistValues())
    System.debug(LoggingLevel.ERROR, P+'VAL ['+pe.getValue()+'] label=['+pe.getLabel()+'] active='+pe.isActive());
System.debug(LoggingLevel.ERROR, P+'=== flows apply/status ativos ===');
for (FlowDefinitionView f : [SELECT ApiName, ActiveVersionId, IsActive, TriggerType, RecordTriggerType
                             FROM FlowDefinitionView WHERE TriggerObjectOrEventLabel='Account' AND TriggerType!=null])
    System.debug(LoggingLevel.ERROR, P+'FLOW '+f.ApiName+' active='+f.IsActive+' verId='+f.ActiveVersionId+' '+f.TriggerType+'/'+f.RecordTriggerType);
System.debug(LoggingLevel.ERROR, P+'=== FIM SST ===');
