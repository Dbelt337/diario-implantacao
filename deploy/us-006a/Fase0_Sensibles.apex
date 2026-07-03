/* ============================================================================
   US-006a Circuito Datos Sensibles — FASE 0 (READ ONLY). Filtrar log por: S6
   ============================================================================ */
final String P = 'S6 | ';
Map<String, Schema.SObjectField> af = Schema.SObjectType.Account.fields.getMap();

/* 1.1 — Apex indevido (Sensitive/Approval/Submitter) a limpar */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 1.1 Apex classes suspeitas (Sensitive/Approval/Submitter) ===');
    Integer c = 0;
    for (ApexClass a : [SELECT Name, CreatedDate, CreatedBy.Name FROM ApexClass
                        WHERE Name LIKE '%Sensitive%' OR Name LIKE '%Approval%' OR Name LIKE '%Submitter%'
                        ORDER BY CreatedDate DESC]) {
        System.debug(LoggingLevel.ERROR, P+'APEX ['+a.Name+'] criada '+a.CreatedDate+' por '+a.CreatedBy.Name+' -> avaliar destructiveChanges');
        c++;
    }
    if (c==0) System.debug(LoggingLevel.ERROR, P+'nenhuma classe Apex suspeita (limpo)');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'1.1 ERRO: '+e.getMessage()); }

/* 2.1 — campos esperados (existencia + API name exato) */
System.debug(LoggingLevel.ERROR, P+'=== 2.1 campos esperados em Account ===');
for (String f : new List<String>{
        'ProposedName__c','ProposedDocumentType__c','ProposedDocumentNumber__c','ProposedBillingEmail__c',
        'SensitiveChangeStatus__c','DocumentType__c','DocumentNumber__c','BillingEmail__c'}) {
    System.debug(LoggingLevel.ERROR, P + f + ' -> ' + (af.containsKey(f.toLowerCase()) ? 'EXISTE' : 'FALTA'));
}

/* 2.1b — candidatos (pega divergencia de nome: espanhol RazonSocialPropuesta__c etc.) */
System.debug(LoggingLevel.ERROR, P+'=== 2.1b candidatos (proposed/propuesta/document/sensib/razonsocial/billingemail/changestatus) ===');
for (String k : af.keySet()) {
    Schema.DescribeFieldResult d = af.get(k).getDescribe(); String n = d.getName().toLowerCase();
    if (n.contains('proposed')||n.contains('propuesta')||n.contains('document')||n.contains('sensitive')
        ||n.contains('sensible')||n.contains('razonsocial')||n.contains('billingemail')||n.contains('changestatus'))
        System.debug(LoggingLevel.ERROR, P+'CAND '+d.getName()+' | label='+d.getLabel()+' | type='+d.getType());
}

/* 2.1c — valores da picklist de status */
System.debug(LoggingLevel.ERROR, P+'=== 2.1c SensitiveChangeStatus__c valores ===');
if (af.containsKey('sensitivechangestatus__c')) {
    for (Schema.PicklistEntry pe : af.get('sensitivechangestatus__c').getDescribe().getPicklistValues())
        System.debug(LoggingLevel.ERROR, P+'STATUSVAL ['+pe.getValue()+'] label=['+pe.getLabel()+']');
} else System.debug(LoggingLevel.ERROR, P+'SensitiveChangeStatus__c NAO existe (ver candidatos)');

/* 2.2 / 2.3 — Approval Processes em Account */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.2/2.3 Approval Processes (ProcessDefinition) Account ===');
    Integer ativos = 0;
    for (ProcessDefinition pd : [SELECT DeveloperName, Name, State, Type FROM ProcessDefinition
                                 WHERE TableEnumOrId='Account' AND Type='Approval']) {
        System.debug(LoggingLevel.ERROR, P+'AP ['+pd.DeveloperName+'] name='+pd.Name+' state='+pd.State);
        if (pd.State=='Active') ativos++;
    }
    System.debug(LoggingLevel.ERROR, P+'APs ATIVOS em Account = '+ativos
        + (ativos>1 ? '  -> FIXAR processDefinitionNameOrId no Submit_Approval' : '')
        + (ativos==0 ? '  -> AP NAO EXISTE: parar/reportar (construcao do Wilmar)' : ''));
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.2 ERRO: '+e.getMessage()); }

/* 2.4 — CustomPermission */
try {
    Integer cp = [SELECT COUNT() FROM CustomPermission WHERE DeveloperName='CanEditSensitiveAccountFields'];
    System.debug(LoggingLevel.ERROR, P+'=== 2.4 CanEditSensitiveAccountFields === '
        + (cp>0 ? 'JA EXISTE -> REMOVER do pacote' : 'nao existe -> pacote cria'));
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.4 ERRO: '+e.getMessage()); }

/* 2.7 — pipeline record-triggered de Account (para a banda de TriggerOrder) */
try {
    System.debug(LoggingLevel.ERROR, P+'=== 2.7 flows record-triggered em Account ===');
    for (FlowDefinitionView f : [SELECT ApiName, TriggerType, RecordTriggerType, IsActive
                                 FROM FlowDefinitionView WHERE TriggerObjectOrEventLabel='Account' AND TriggerType!=null])
        System.debug(LoggingLevel.ERROR, P+'FLOW '+f.ApiName+' | '+f.TriggerType+'/'+f.RecordTriggerType+' | active='+f.IsActive);
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P+'2.7 ERRO: '+e.getMessage()); }

System.debug(LoggingLevel.ERROR, P+'=== FIM S6 FASE 0 (2.5 CDC e 2.6 FLS: checar no Setup) ===');
