// HU-024 parte 2: el cierre automatico. Solo lectura.
//
// Politica leida el 17/08 (InactivityPolicy__mdt, registro Default):
//   DaysToAlert__c = 27 | DaysToClose__c = 30
//   LostStageName__c = 'Closed Lost'
//   AlertTaskSubject__c = 'Aviso: oportunidad sera cerrada por inactividad'
//   CloseReasonValue__c = 'Cierre automatico por inactividad'
//
// El flow CloseInactiveOpportunities solo escribe StageName. CloseReasonValue__c
// existe en la politica y NUNCA se escribe. Este script prueba las dos cosas que
// eso rompe.

String ETAPA  = 'Closed Lost';
String MOTIVO = 'Cierre automático por inactividad';
String ASUNTO = 'Aviso: oportunidad será cerrada por inactividad';

Id rt = null;
for (Schema.RecordTypeInfo ri : Opportunity.SObjectType.getDescribe().getRecordTypeInfos()) {
    if (ri.getDeveloperName() == 'GQOpportunitiesRepuestosPA') { rt = ri.getRecordTypeId(); }
}
if (rt == null) { System.debug('SIN RT GQOpportunitiesRepuestosPA'); return; }

System.debug('--- 1. LA ETAPA DESTINO EXISTE ---');
List<OpportunityStage> es = [SELECT MasterLabel, IsActive, IsClosed, IsWon
                             FROM OpportunityStage WHERE MasterLabel = :ETAPA];
if (es.isEmpty()) {
    System.debug('DEFECTO GRAVE: no existe etapa "' + ETAPA + '". El flow programado');
    System.debug('escribe un valor invalido y falla cada manana sin que nadie lo vea.');
    System.debug('Etapas de cierre que SI existen:');
    for (OpportunityStage s : [SELECT MasterLabel, IsWon FROM OpportunityStage
                               WHERE IsClosed = true]) {
        System.debug('   ' + s.MasterLabel + ' | ganada=' + s.IsWon);
    }
} else {
    OpportunityStage s = es[0];
    System.debug(ETAPA + ' | act=' + s.IsActive + ' | cerr=' + s.IsClosed + ' | gan=' + s.IsWon);
    if (!s.IsClosed || s.IsWon) { System.debug('DEFECTO: no es una etapa de perdida'); }
}

System.debug('--- 2. EL MOTIVO DE LA POLITICA EXISTE COMO VALOR ---');
Boolean hallado = false;
for (Schema.SObjectField f : Opportunity.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (d.getType() != Schema.DisplayType.PICKLIST) { continue; }
    String t = (d.getName() + ' ' + d.getLabel()).toLowerCase();
    if (!(t.contains('loss') || t.contains('perdid') || t.contains('motiv')
          || t.contains('reason') || t.contains('cierre'))) { continue; }
    for (Schema.PicklistEntry pe : d.getPicklistValues()) {
        if (pe.getValue() == MOTIVO || pe.getLabel() == MOTIVO) {
            hallado = true;
            System.debug('EXISTE en ' + d.getName() + ' | activo=' + pe.isActive());
        }
    }
}
if (!hallado) {
    System.debug('NO EXISTE el valor "' + MOTIVO + '" en ningun campo de motivo.');
    System.debug('Entonces aunque el flow lo escribiera, fallaria por valor invalido');
    System.debug('si la picklist es restringida. Y no esta entre los 9 de la HU:');
    System.debug('el mas cercano es "Sin respuesta del cliente". DECIDIR eso antes');
    System.debug('de crear un valor nuevo.');
}

System.debug('--- 3. LA AUTOMATIZACION YA ACTUA ---');
System.debug('tareas de alerta: ' + [SELECT COUNT() FROM Task WHERE Subject = :ASUNTO]);
Set<Id> conTarea = new Set<Id>();
for (Task t : [SELECT WhatId, CreatedDate FROM Task
               WHERE Subject = :ASUNTO AND WhatId != null
               ORDER BY CreatedDate DESC LIMIT 2000]) {
    conTarea.add(t.WhatId);
}
for (Task t : [SELECT Subject, WhatId, CreatedDate FROM Task
               WHERE Subject = :ASUNTO ORDER BY CreatedDate DESC LIMIT 5]) {
    System.debug('   ' + t.CreatedDate + ' | ' + t.WhatId);
}

System.debug('--- 4. CIERRE REPETIDO AL REABRIR ---');
if (conTarea.isEmpty()) {
    System.debug('ninguna oportunidad con tarea de alerta');
} else {
    List<Opportunity> ops = [SELECT Id, Name, StageName FROM Opportunity
                             WHERE Id IN :conTarea AND IsClosed = false
                               AND RecordTypeId = :rt LIMIT 50];
    System.debug('ABIERTAS de Repuestos con tarea de alerta: ' + ops.size());
    for (Opportunity o : ops) { System.debug('   ' + o.Id + ' | ' + o.StageName + ' | ' + o.Name); }
    System.debug('El flow busca la tarea por Subject. Si quedo la vieja, la cierra');
    System.debug('de nuevo manana 06:00 UTC. Son estas las candidatas.');
}

System.debug('--- 5. CRITERIO 04, COTIZACION VENCIDA ---');
System.debug('cotizaciones vencidas en oportunidad ABIERTA: '
    + [SELECT COUNT() FROM Quote WHERE ExpirationDate < TODAY
       AND Opportunity.RecordTypeId = :rt AND Opportunity.IsClosed = false]);
System.debug('El flow mide inactividad de TAREAS a 30 dias, no vencimiento de');
System.debug('cotizacion. Y la reapertura que GrupoQ acepta es de 8 dias B2C:');
System.debug('dos relojes distintos que hay que conciliar.');

System.debug('FIN PARTE 2');
