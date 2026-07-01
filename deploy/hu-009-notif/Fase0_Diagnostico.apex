/* ============================================================================
   HU-009 — FASE 0 (READ ONLY, SEM DML) — Notificação "Cliente chegou"
   Rodar em: Setup > Developer Console > Debug > Open Execute Anonymous Window
   Marcar "Open Log". Depois filtrar o log por: HU009
   Nenhuma alteração é feita (só SELECT/describe). Cada bloco é isolado.
   ============================================================================ */
final String P = 'HU009 | ';
Map<String, Schema.SObjectField> saFields = Schema.SObjectType.ServiceAppointment.fields.getMap();

/* ---- 3.1 ServiceAppointment.Status (valor de API real da "chegada") ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.1 ServiceAppointment.Status =====');
    for (Schema.PicklistEntry pe : ServiceAppointment.Status.getDescribe().getPicklistValues()) {
        System.debug(LoggingLevel.ERROR, P + 'STATUS value=[' + pe.getValue() + '] label=[' + pe.getLabel() + '] active=' + pe.isActive());
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.1 ERRO: ' + e.getMessage()); }

/* ---- 3.1b StatusCategory (se existir) ---- */
try {
    if (saFields.containsKey('StatusCategory')) {
        System.debug(LoggingLevel.ERROR, P + '===== 3.1b ServiceAppointment.StatusCategory =====');
        for (Schema.PicklistEntry pe : saFields.get('StatusCategory').getDescribe().getPicklistValues()) {
            System.debug(LoggingLevel.ERROR, P + 'CATEGORY value=[' + pe.getValue() + '] label=[' + pe.getLabel() + ']');
        }
    } else { System.debug(LoggingLevel.ERROR, P + '3.1b StatusCategory NAO existe neste org'); }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.1b ERRO: ' + e.getMessage()); }

/* ---- 3.2a ParentRecordId aponta para quê? ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.2a ParentRecordId referenceTo =====');
    if (saFields.containsKey('ParentRecordId')) {
        for (Schema.SObjectType ref : saFields.get('ParentRecordId').getDescribe().getReferenceTo()) {
            System.debug(LoggingLevel.ERROR, P + 'ParentRecordId -> ' + ref.getDescribe().getName());
        }
    } else { System.debug(LoggingLevel.ERROR, P + 'ParentRecordId NAO existe'); }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.2a ERRO: ' + e.getMessage()); }

/* ---- 3.2a2 Qualquer campo do SA que seja lookup para Opportunity ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.2a2 Lookups SA -> Opportunity =====');
    Boolean achou = false;
    for (String fn : saFields.keySet()) {
        Schema.DescribeFieldResult d = saFields.get(fn).getDescribe();
        if (d.getType() == Schema.DisplayType.REFERENCE) {
            for (Schema.SObjectType ref : d.getReferenceTo()) {
                if (ref.getDescribe().getName() == 'Opportunity') {
                    System.debug(LoggingLevel.ERROR, P + 'LOOKUP ' + d.getName() + ' -> Opportunity'); achou = true;
                }
            }
        }
    }
    if (!achou) System.debug(LoggingLevel.ERROR, P + 'nenhum lookup direto SA->Opportunity');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.2a2 ERRO: ' + e.getMessage()); }

/* ---- 3.2a3 Amostra real: prefixos de ParentRecordId em SAs existentes ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.2a3 Amostra ParentRecordId (006=Opp, 001=Account, 0WO=WorkOrder) =====');
    Map<String,Integer> pref = new Map<String,Integer>();
    for (ServiceAppointment sa : [SELECT ParentRecordId FROM ServiceAppointment WHERE ParentRecordId != null LIMIT 300]) {
        String k = String.valueOf(sa.ParentRecordId).substring(0,3);
        pref.put(k, (pref.containsKey(k)?pref.get(k):0)+1);
    }
    System.debug(LoggingLevel.ERROR, P + 'prefixos=' + pref);
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.2a3 ERRO: ' + e.getMessage()); }

/* ---- 3.3 CustomNotificationType existentes (evitar duplicar) ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.3 CustomNotificationType existentes =====');
    for (CustomNotificationType t : [SELECT Id, CustomNotifTypeName, MasterLabel FROM CustomNotificationType ORDER BY CustomNotifTypeName]) {
        System.debug(LoggingLevel.ERROR, P + 'NOTIFTYPE name=[' + t.CustomNotifTypeName + '] label=[' + t.MasterLabel + '] Id=' + t.Id);
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.3 ERRO (tentar so DeveloperName): ' + e.getMessage()); }

/* ---- 3.4 Flows record-triggered / automações no ServiceAppointment ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.4 Flows (todos os record-triggered; filtre Appointment) =====');
    for (FlowDefinitionView f : [SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel, IsActive
                                 FROM FlowDefinitionView
                                 WHERE TriggerType != null ORDER BY TriggerObjectOrEventLabel]) {
        if (f.TriggerObjectOrEventLabel != null && f.TriggerObjectOrEventLabel.containsIgnoreCase('Appointment')) {
            System.debug(LoggingLevel.ERROR, P + 'FLOW ' + f.ApiName + ' | obj=' + f.TriggerObjectOrEventLabel + ' | ' + f.ProcessType + ' | trig=' + f.TriggerType + ' | active=' + f.IsActive);
        }
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.4 ERRO: ' + e.getMessage()); }

/* ---- 3.4b Apex triggers no ServiceAppointment ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 3.4b Apex triggers SA =====');
    for (ApexTrigger tr : [SELECT Name, Status FROM ApexTrigger WHERE TableEnumOrId = 'ServiceAppointment']) {
        System.debug(LoggingLevel.ERROR, P + 'TRIGGER ' + tr.Name + ' | ' + tr.Status);
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '3.4b ERRO: ' + e.getMessage()); }

/* ---- 4.4 Merge fields candidatos (cliente / sucursal / oportunidad) ---- */
try {
    System.debug(LoggingLevel.ERROR, P + '===== 4.4 Opportunity: campos candidatos =====');
    Map<String, Schema.SObjectField> oppF = Schema.SObjectType.Opportunity.fields.getMap();
    for (String fn : oppF.keySet()) {
        Schema.DescribeFieldResult d = oppF.get(fn).getDescribe();
        String n = d.getName().toLowerCase();
        if (n.contains('sucursal')||n.contains('sede')||n.contains('branch')||n.contains('cliente')||n.contains('nombre')||n.contains('showroom')||n.contains('tienda')||n.contains('dealer')||n.contains('territor'))
            System.debug(LoggingLevel.ERROR, P + 'OPP ' + d.getName() + ' | label=' + d.getLabel() + ' | type=' + d.getType());
    }
    System.debug(LoggingLevel.ERROR, P + '(Opportunity.Name e Opportunity.Account.Name sempre existem para nome da oportunidade / cliente)');
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '4.4 ERRO: ' + e.getMessage()); }

try {
    System.debug(LoggingLevel.ERROR, P + '===== 4.4b ServiceAppointment: campos candidatos =====');
    for (String fn : saFields.keySet()) {
        Schema.DescribeFieldResult d = saFields.get(fn).getDescribe();
        String n = d.getName().toLowerCase();
        if (n.contains('sucursal')||n.contains('sede')||n.contains('branch')||n.contains('cliente')||n.contains('nombre')||n.contains('showroom')||n.contains('tienda')||n.contains('territor'))
            System.debug(LoggingLevel.ERROR, P + 'SA ' + d.getName() + ' | label=' + d.getLabel() + ' | type=' + d.getType());
    }
} catch (Exception e) { System.debug(LoggingLevel.ERROR, P + '4.4b ERRO: ' + e.getMessage()); }

System.debug(LoggingLevel.ERROR, P + '===== FIM HU009 FASE 0 =====');
