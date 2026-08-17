/**
 * HU-024, cierre de oportunidad ganada o perdida con registro de motivo.
 * Que hay construido HOY, medido en Repuestos y PA.
 *
 * LO QUE APEX SI PUEDE LEER, y este script lee:
 *   - las etapas de OpportunityStage, con IsClosed y IsWon;
 *   - los valores del campo de motivo, activos e inactivos;
 *   - la politica de inactividad, porque InactivityPolicy__mdt es consultable;
 *   - el USO REAL: cuantas oportunidades hay por etapa, cuantas cerradas
 *     perdidas SIN motivo, y si la automatizacion de cierre ya viene actuando,
 *     que se ve en las tareas que ella misma crea;
 *   - si la etapa a la que la automatizacion cierra existe de verdad.
 *
 * LO QUE APEX NO PUEDE LEER, y por eso NO alcanza con un script:
 *   - que etapas pertenecen a cada Record Type. Eso es el Sales Process, y es
 *     METADATO, no dato. Se ve con un retrieve de BusinessProcess, o en
 *     Object Manager, Record Types;
 *   - que valores de picklist estan asignados a cada Record Type, misma razon;
 *   - las validation rules y los flows.
 *
 * Solo lectura.
 */

Organization laOrg = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | instancia=' + laOrg.InstanceName + ' | sandbox=' + laOrg.IsSandbox);
System.debug('   Correrlo en la MISMA org donde QA vio el bug GQAUT-326.');

// ---------- Record Type de Repuestos ----------
Id rtRep = null;
System.debug('===================================================');
System.debug('1. RECORD TYPES DE OPPORTUNITY');
System.debug('===================================================');
for (Schema.RecordTypeInfo ri : Opportunity.SObjectType.getDescribe().getRecordTypeInfos()) {
    if (ri.isMaster()) { continue; }
    System.debug('   ' + ri.getDeveloperName() + '  (' + ri.getName() + ')'
        + ' | activo=' + ri.isActive() + ' | disponible para mi=' + ri.isAvailable());
    if (ri.getDeveloperName() == 'GQOpportunitiesRepuestosPA') { rtRep = ri.getRecordTypeId(); }
}
if (rtRep == null) {
    System.debug('   NO se encontro GQOpportunitiesRepuestosPA. Revisar el nombre y volver.');
    return;
}
System.debug('   Repuestos y PA: ' + rtRep);

// ---------- Etapas ----------
System.debug('===================================================');
System.debug('2. ETAPAS DE LA ORG, CON CIERRE Y GANADA');
System.debug('===================================================');
System.debug('   Esto es de toda la org. Cual de estas pertenece a Repuestos');
System.debug('   depende del Sales Process, que Apex no ve. Ver punto 8.');

Map<String, Schema.SObjectField> camposEtapa =
    OpportunityStage.SObjectType.getDescribe().fields.getMap();
List<String> colsEtapa = new List<String>{ 'MasterLabel', 'IsActive', 'IsClosed', 'IsWon' };
for (String extra : new List<String>{ 'ApiName', 'DefaultProbability',
                                      'ForecastCategoryName', 'SortOrder' }) {
    if (camposEtapa.containsKey(extra.toLowerCase())) { colsEtapa.add(extra); }
}

Set<String> etapasPerdidas = new Set<String>();
Set<String> etapasGanadas  = new Set<String>();
Set<String> etapasCerradas = new Set<String>();
for (SObject s : Database.query('SELECT ' + String.join(colsEtapa, ', ')
        + ' FROM OpportunityStage ORDER BY SortOrder NULLS LAST')) {
    String etiqueta = String.valueOf(s.get('MasterLabel'));
    Boolean cerrada = s.get('IsClosed') == true;
    Boolean ganada  = s.get('IsWon') == true;
    if (cerrada) { etapasCerradas.add(etiqueta); }
    if (cerrada && ganada)  { etapasGanadas.add(etiqueta); }
    if (cerrada && !ganada) { etapasPerdidas.add(etiqueta); }
    System.debug('   ' + etiqueta
        + ' | activa=' + s.get('IsActive')
        + ' | cerrada=' + cerrada + ' | ganada=' + ganada
        + (colsEtapa.contains('DefaultProbability') ? ' | prob=' + s.get('DefaultProbability') : '')
        + (colsEtapa.contains('ForecastCategoryName') ? ' | forecast=' + s.get('ForecastCategoryName') : ''));
}
System.debug('   Etapas de PERDIDA: ' + etapasPerdidas);
System.debug('   Etapas de GANADA : ' + etapasGanadas);
System.debug('   Si hay mas de una etapa de perdida, el motivo puede estar');
System.debug('   modelado como etapa Y como campo a la vez, que es duplicidad.');

// ---------- Campo de motivo ----------
System.debug('===================================================');
System.debug('3. EL CAMPO DE MOTIVO DE CIERRE');
System.debug('===================================================');
Map<String, Schema.SObjectField> campos = Opportunity.SObjectType.getDescribe().fields.getMap();
List<String> camposMotivo = new List<String>();
for (Schema.SObjectField f : campos.values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (fd.getType() != Schema.DisplayType.PICKLIST
        && fd.getType() != Schema.DisplayType.MULTIPICKLIST
        && fd.getType() != Schema.DisplayType.TEXTAREA
        && fd.getType() != Schema.DisplayType.STRING) { continue; }
    String t = (fd.getName() + ' ' + fd.getLabel()).toLowerCase();
    if (t.contains('loss') || t.contains('lost') || t.contains('perdid')
        || t.contains('motiv') || t.contains('reason') || t.contains('cierre')) {
        camposMotivo.add(fd.getName());
        System.debug('   ---------------------------------------------');
        System.debug('   ' + fd.getName() + '  (label: ' + fd.getLabel() + ')');
        System.debug('        tipo=' + fd.getType() + ' | custom=' + fd.isCustom()
            + ' | restringida=' + fd.isRestrictedPicklist()
            + ' | dependiente=' + fd.isDependentPicklist()
            + ' | requerido=' + !fd.isNillable());
        if (fd.isDependentPicklist()) {
            Schema.SObjectField c = fd.getController();
            System.debug('        CONTROLADA POR ' + (c == null ? '?' : c.getDescribe().getName())
                + '. Los valores pueden existir y no aparecer por el mapa de dependencia.');
        }
        Integer act = 0, inact = 0;
        for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
            System.debug('          ' + (pe.isActive() ? 'ACTIVO  ' : 'INACTIVO')
                + ' | ' + pe.getValue() + '  (label: ' + pe.getLabel() + ')');
            if (pe.isActive()) { act++; } else { inact++; }
        }
        System.debug('        ' + act + ' activos, ' + inact + ' inactivos');
    }
}
if (camposMotivo.isEmpty()) {
    System.debug('   NINGUN campo de motivo en Opportunity. Entonces la HU-024 no');
    System.debug('   esta construida en la parte de registro de motivo.');
}

// ---------- Uso real en Repuestos ----------
System.debug('===================================================');
System.debug('4. USO REAL EN REPUESTOS Y PA');
System.debug('===================================================');
Integer totalRep = [SELECT COUNT() FROM Opportunity WHERE RecordTypeId = :rtRep];
System.debug('   Oportunidades de Repuestos y PA: ' + totalRep);
for (AggregateResult ar : [SELECT StageName s, COUNT(Id) q FROM Opportunity
                           WHERE RecordTypeId = :rtRep
                           GROUP BY StageName ORDER BY COUNT(Id) DESC]) {
    System.debug('   ' + ar.get('s') + ' | ' + ar.get('q'));
}
System.debug('   Las etapas que aparecen aqui son las que el negocio USA. Si');
System.debug('   sobran etapas en el punto 2 que no aparecen aca, el Sales');
System.debug('   Process de Repuestos esta mas ancho que la realidad.');

System.debug('   CERRADAS PERDIDAS Y SI TIENEN MOTIVO:');
if (etapasPerdidas.isEmpty()) {
    System.debug('   No hay etapa marcada como cerrada y no ganada.');
} else {
    Integer perdidas = Database.countQuery(
        'SELECT COUNT() FROM Opportunity WHERE RecordTypeId = \'' + rtRep
        + '\' AND StageName IN (\'' + String.join(new List<String>(etapasPerdidas), '\',\'') + '\')');
    System.debug('   Cerradas perdidas: ' + perdidas);
    for (String campo : camposMotivo) {
        try {
            Integer sinMotivo = Database.countQuery(
                'SELECT COUNT() FROM Opportunity WHERE RecordTypeId = \'' + rtRep
                + '\' AND StageName IN (\'' + String.join(new List<String>(etapasPerdidas), '\',\'') + '\')'
                + ' AND ' + campo + ' = null');
            System.debug('   ' + campo + ' vacio en ' + sinMotivo + ' de ' + perdidas);
            if (perdidas > 0 && sinMotivo == perdidas) {
                System.debug('        NINGUNA tiene motivo. El campo existe y no se usa,');
                System.debug('        o no es obligatorio al cerrar. Eso es la HU-024.');
            }
        } catch (Exception e) {
            System.debug('   ' + campo + ': no se pudo contar, ' + e.getMessage());
        }
        try {
            for (AggregateResult ar : Database.query(
                    'SELECT ' + campo + ' v, COUNT(Id) q FROM Opportunity'
                    + ' WHERE RecordTypeId = \'' + rtRep + '\''
                    + ' AND StageName IN (\'' + String.join(new List<String>(etapasPerdidas), '\',\'') + '\')'
                    + ' GROUP BY ' + campo + ' ORDER BY COUNT(Id) DESC')) {
                System.debug('        ' + ar.get('v') + ' | ' + ar.get('q')
                    + '   <- valor EN USO, no se renombra sin Replace');
            }
        } catch (Exception e) { /* multipicklist no agrupa */ }
    }
}

// ---------- Politica de inactividad ----------
System.debug('===================================================');
System.debug('5. LA POLITICA DE CIERRE AUTOMATICO, InactivityPolicy__mdt');
System.debug('===================================================');
System.debug('   El flow CloseInactiveOpportunities es SCHEDULED, ACTIVO, corre');
System.debug('   DIARIO 06:00 UTC desde 24/07 sobre Opportunity con IsClosed=false,');
System.debug('   y lo unico que escribe es StageName = LostStageName__c. NO escribe');
System.debug('   motivo. Ese es el hallazgo central para la HU-024.');
Set<String> asuntos = new Set<String>();
String etapaDestino = null;
try {
    Map<String, Schema.SObjectField> cm =
        Schema.getGlobalDescribe().get('InactivityPolicy__mdt').getDescribe().fields.getMap();
    List<String> colsCm = new List<String>();
    for (String k : cm.keySet()) { colsCm.add(cm.get(k).getDescribe().getName()); }
    for (SObject p : Database.query('SELECT ' + String.join(colsCm, ', ')
            + ' FROM InactivityPolicy__mdt LIMIT 50')) {
        System.debug('   --- registro: ' + p.get('DeveloperName'));
        for (String c : colsCm) {
            Object v = p.get(c);
            if (v == null) { continue; }
            System.debug('        ' + c + ' = ' + v);
            String cl = c.toLowerCase();
            if (cl.contains('subject')) { asuntos.add(String.valueOf(v)); }
            if (cl.contains('loststage')) { etapaDestino = String.valueOf(v); }
        }
    }
} catch (Exception e) {
    System.debug('   No se pudo leer InactivityPolicy__mdt: ' + e.getMessage());
}
if (etapaDestino != null) {
    Boolean existe = etapasCerradas.contains(etapaDestino);
    System.debug('   Etapa destino del cierre automatico: "' + etapaDestino + '"');
    System.debug('        existe como etapa cerrada: ' + (existe ? 'SI' : 'NO'));
    if (!existe) {
        System.debug('        DEFECTO. El flow escribe una etapa que no es de cierre,');
        System.debug('        o que no existe. En un flow programado eso falla sin que');
        System.debug('        nadie vea el error.');
    }
}

// ---------- Evidencia de que la automatizacion actua ----------
System.debug('===================================================');
System.debug('6. LA AUTOMATIZACION YA VIENE ACTUANDO');
System.debug('===================================================');
System.debug('   Se mide por las tareas que el propio flow crea.');
if (asuntos.isEmpty()) {
    System.debug('   Sin asuntos leidos de la politica, no se puede cruzar.');
} else {
    for (String asunto : asuntos) {
        Integer q = [SELECT COUNT() FROM Task WHERE Subject = :asunto];
        System.debug('   "' + asunto + '" : ' + q + ' tareas');
    }
    for (Task t : [SELECT Subject, WhatId, CreatedDate, ActivityDate, Status
                   FROM Task WHERE Subject IN :asuntos
                   ORDER BY CreatedDate DESC LIMIT 5]) {
        System.debug('        ' + t.CreatedDate + ' | ' + t.Subject + ' | ' + t.WhatId);
    }
    System.debug('   REAPERTURA, EL RIESGO CONCRETO: oportunidades ABIERTAS que ya');
    System.debug('   tienen tarea del flow. Si se reabrio una cerrada y la tarea de');
    System.debug('   alerta sigue ahi, el flow la encuentra por Subject y puede');
    System.debug('   cerrarla de nuevo a la manana siguiente.');
    Set<Id> conTarea = new Set<Id>();
    for (Task t : [SELECT WhatId FROM Task WHERE Subject IN :asuntos AND WhatId != null LIMIT 2000]) {
        conTarea.add(t.WhatId);
    }
    if (!conTarea.isEmpty()) {
        Integer abiertasConTarea = [SELECT COUNT() FROM Opportunity
                                    WHERE Id IN :conTarea AND IsClosed = false
                                      AND RecordTypeId = :rtRep];
        System.debug('   Abiertas de Repuestos con tarea del flow: ' + abiertasConTarea);
        if (abiertasConTarea > 0) {
            System.debug('        REVISAR ESTAS. Son las candidatas a cierre repetido.');
        }
    }
}

// ---------- Cotizacion vencida, el criterio 04 ----------
System.debug('===================================================');
System.debug('7. COTIZACION VENCIDA, QUE ES EL CRITERIO 04 DE LA HU');
System.debug('===================================================');
System.debug('   GrupoQ dijo: se pierde cuando la cotizacion expiro Y ADEMAS no');
System.debug('   hubo respuesta. El flow de hoy mide INACTIVIDAD DE TAREAS, no');
System.debug('   vencimiento de cotizacion. Son dos cosas distintas.');
try {
    Integer vencidas = [SELECT COUNT() FROM Quote
                        WHERE ExpirationDate < TODAY
                          AND Opportunity.RecordTypeId = :rtRep
                          AND Opportunity.IsClosed = false];
    System.debug('   Cotizaciones vencidas en oportunidades ABIERTAS: ' + vencidas);
    System.debug('   Cada una es un caso que el criterio 04 dice cerrar y hoy no');
    System.debug('   se cierra por esa via.');
} catch (Exception e) {
    System.debug('   No se pudo contar: ' + e.getMessage());
}

// ---------- Lo que falta mirar fuera de Apex ----------
System.debug('===================================================');
System.debug('8. LO QUE ESTE SCRIPT NO PUEDE VER');
System.debug('===================================================');
System.debug('   Apex no lee metadato de configuracion. Falta un retrieve con:');
System.debug('     BusinessProcess   -> el Sales Process, que etapas tiene');
System.debug('                          Repuestos y PA. ES LA PREGUNTA DE FONDO;');
System.debug('     RecordType        -> que valores de picklist estan asignados;');
System.debug('     ValidationRule    -> si se puede volver atras de una etapa');
System.debug('                          cerrada, que es la reapertura del punto 3;');
System.debug('     Flow              -> CloseInactiveOpportunities y los de etapa.');
System.debug('   Todo eso sale de un solo retrieve del objeto Opportunity.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
