/* ============================================================================
   Lead.Country__c — FASE 0 (READ ONLY, SEM DML)
   Execute Anonymous + Open Log. Filtrar o log por: CTRY
   ============================================================================ */
final String P = 'CTRY | ';

/* ---- 0.1 Account.Country__c: valores EXATOS (clone byte a byte) ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 0.1 Account.Country__c =====');
    Schema.DescribeFieldResult d = Account.Country__c.getDescribe();
    System.debug(LoggingLevel.ERROR, P + 'restricted=' + d.isRestrictedPicklist() + ' | dependent=' + d.isDependentPicklist() + ' | type=' + d.getType());
    for (Schema.PicklistEntry pe : d.getPicklistValues()) {
        System.debug(LoggingLevel.ERROR, P + 'ACCVAL value=[' + pe.getValue() + '] label=[' + pe.getLabel() + '] active=' + pe.isActive() + ' default=' + pe.isDefaultValue());
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '0.1 ERRO: ' + e.getMessage()); }

/* ---- 0.1b Lead.Country__c ja existe? ---- */
try {
    Map<String,Schema.SObjectField> lf = Schema.SObjectType.Lead.fields.getMap();
    if (lf.containsKey('country__c')) {
        System.debug(LoggingLevel.ERROR, P + '0.1b Lead.Country__c JA EXISTE:');
        for (Schema.PicklistEntry pe : Lead.Country__c.getDescribe().getPicklistValues())
            System.debug(LoggingLevel.ERROR, P + 'LEADVAL value=[' + pe.getValue() + '] label=[' + pe.getLabel() + ']');
    } else { System.debug(LoggingLevel.ERROR, P + '0.1b Lead.Country__c NAO existe (sera criado)'); }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '0.1b ERRO: ' + e.getMessage()); }

/* ---- 0.2 Flows de Lead (achar o derivador ATIVO) ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 0.2 Flows Lead (before-save / record-triggered) =====');
    for (FlowDefinitionView f : [SELECT ApiName, Label, ProcessType, TriggerType, RecordTriggerType, TriggerObjectOrEventLabel, IsActive, ActiveVersionId
                                 FROM FlowDefinitionView
                                 WHERE TriggerObjectOrEventLabel = 'Lead' ORDER BY ApiName]) {
        System.debug(LoggingLevel.ERROR, P + 'FLOW ' + f.ApiName + ' | trig=' + f.TriggerType + '/' + f.RecordTriggerType + ' | active=' + f.IsActive + ' | activeVer=' + f.ActiveVersionId);
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '0.2 ERRO (tentar sem RecordTriggerType): ' + e.getMessage()); }

/* ---- 0.3 Sociedad_Config__mdt: campos + 17 registros + campo de pais/formato ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 0.3a Sociedad_Config__mdt campos =====');
    Map<String,Schema.SObjectField> f = Schema.SObjectType.Sociedad_Config__mdt.fields.getMap();
    List<String> cols = new List<String>{'DeveloperName'};
    for (String k : f.keySet()) if (k.endsWith('__c')) cols.add(f.get(k).getDescribe().getName());
    System.debug(LoggingLevel.ERROR, P + 'FIELDS = ' + cols);

    System.debug(LoggingLevel.ERROR, P + '===== 0.3b Registros (DeveloperName + campos de pais) =====');
    String q = 'SELECT ' + String.join(cols, ',') + ' FROM Sociedad_Config__mdt ORDER BY DeveloperName';
    for (SObject r : Database.query(q)) {
        String line = String.valueOf(r.get('DeveloperName'));
        for (String c : cols) {
            String cl = c.toLowerCase();
            if (cl.contains('country') || cl.contains('pais') || cl.contains('sociedad') || cl.contains('company') || cl.contains('name'))
                line += ' | ' + c + '=[' + r.get(c) + ']';
        }
        System.debug(LoggingLevel.ERROR, P + 'CMT ' + line);
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '0.3 ERRO: ' + e.getMessage()); }

/* ---- 0.5 Contagem para backfill ---- */
try {
    Integer total = [SELECT COUNT() FROM Lead WHERE IsConverted = false AND Sociedad__c != null];
    System.debug(LoggingLevel.ERROR, P + '===== 0.5 Backfill: leads nao convertidos com Sociedad != null = ' + total);
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '0.5 ERRO: ' + e.getMessage()); }

/* ---- 0.5b subset ja com Country preenchido (se o campo existir) ---- */
try {
    Integer semPais = [SELECT COUNT() FROM Lead WHERE IsConverted = false AND Sociedad__c != null AND Country__c = null];
    System.debug(LoggingLevel.ERROR, P + '0.5b desses, com Country__c NULO = ' + semPais);
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '0.5b (Country__c ainda nao existe): ' + e.getMessage()); }

System.debug(LoggingLevel.ERROR, P + '===== FIM CTRY FASE 0 =====');
