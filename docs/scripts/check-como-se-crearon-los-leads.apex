/**
 * Como se crearon los 1448 leads de esta org, y si alguien ya retrocedio fechas
 * aqui antes.
 *
 * Contexto: el diario del proyecto NO tiene ningun registro de una carga de
 * leads con fecha retroactiva. Lo unico que hay anotado es el seed del catalogo
 * de repuestos del 12/08. Entonces, antes de repetir un ejercicio que puede no
 * haber existido, se mira la org y ella responde.
 *
 * Lo que distingue una carga con fecha retroactiva de datos que nacieron con el
 * tiempo: si alguien inserto con CreatedDate fijado a mano, el CreatedDate
 * queda repartido en meses pero el SystemModstamp queda apretado en el dia de
 * la carga. Dato que nacio con el tiempo tiene las dos cosas repartidas.
 *
 * Solo lectura. No escribe nada.
 */

Organization laOrg = [SELECT Id, Name, IsSandbox, CreatedDate FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id + ' | sandbox=' + laOrg.IsSandbox);

System.debug('===================================================');
System.debug('1. LA PREFERENCIA Y EL PERMISO DE AUDIT FIELDS');
System.debug('===================================================');
System.debug('   Es el UNICO mecanismo que existe para fijar CreatedDate. Si esta');
System.debug('   apagado y nadie lo prendio, entonces aqui nunca se retrocedio');
System.debug('   ninguna fecha, y la memoria de haberlo hecho es de otra org.');
System.debug('   ');
System.debug('   El campo PermissionsSetAuditFields solo aparece en el esquema');
System.debug('   despues de marcar la preferencia. Que no exista ya es respuesta.');

Boolean existeElPermiso = true;
Boolean loTengoYo = false;
List<String> quienLoTiene = new List<String>();
try {
    for (SObject p : Database.query(
            'SELECT Id, Name, PermissionsSetAuditFields FROM Profile'
            + ' WHERE PermissionsSetAuditFields = true')) {
        quienLoTiene.add('perfil ' + p.get('Name'));
    }
    for (SObject ps : Database.query(
            'SELECT Id, Label, PermissionsSetAuditFields FROM PermissionSet'
            + ' WHERE PermissionsSetAuditFields = true')) {
        quienLoTiene.add('permission set ' + ps.get('Label'));
    }
    for (SObject p : Database.query(
            'SELECT PermissionsSetAuditFields FROM Profile WHERE Id = \''
            + UserInfo.getProfileId() + '\'')) {
        if (p.get('PermissionsSetAuditFields') == true) { loTengoYo = true; }
    }
    for (SObject a : Database.query(
            'SELECT PermissionSet.PermissionsSetAuditFields FROM PermissionSetAssignment'
            + ' WHERE AssigneeId = \'' + UserInfo.getUserId() + '\'')) {
        SObject ps = a.getSObject('PermissionSet');
        if (ps != null && ps.get('PermissionsSetAuditFields') == true) { loTengoYo = true; }
    }
} catch (Exception e) {
    existeElPermiso = false;
}

System.debug('   Preferencia de Setup activa : ' + (existeElPermiso ? 'SI' : 'NO'));
if (existeElPermiso) {
    System.debug('   Lo tengo yo                 : ' + (loTengoYo ? 'SI' : 'NO'));
    System.debug('   Quien lo tiene hoy          : '
        + (quienLoTiene.isEmpty() ? 'nadie' : String.join(quienLoTiene, ', ')));
    System.debug('   Si esta activa, es senal de que alguien la prendio para algo.');
} else {
    System.debug('   Apagada. Nadie puede fijar CreatedDate en esta org hoy, y');
    System.debug('   probablemente nunca se hizo aqui.');
}

System.debug('===================================================');
System.debug('2. COMO SE REPARTEN LAS FECHAS DE CREACION');
System.debug('===================================================');
Datetime hace400 = System.now().addDays(-400);
for (AggregateResult ar : [SELECT CALENDAR_YEAR(CreatedDate) a,
                                  CALENDAR_MONTH(CreatedDate) m, COUNT(Id) q
                           FROM Lead
                           WHERE CreatedDate >= :hace400
                           GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
                           ORDER BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)]) {
    System.debug('   ' + ar.get('a') + '-' + String.valueOf(ar.get('m')).leftPad(2, '0')
        + '  creados: ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('3. Y COMO SE REPARTE LA ULTIMA MODIFICACION DEL SISTEMA');
System.debug('===================================================');
System.debug('   Esta es la prueba. SystemModstamp NO se puede fijar de ninguna');
System.debug('   forma, ni con el permiso de audit fields.');
System.debug('   Si el punto 2 esta repartido en meses y este esta concentrado en');
System.debug('   uno o dos dias, hubo carga con fecha retroactiva.');
for (AggregateResult ar : [SELECT CALENDAR_YEAR(SystemModstamp) a,
                                  CALENDAR_MONTH(SystemModstamp) m, COUNT(Id) q
                           FROM Lead
                           WHERE CreatedDate >= :hace400
                           GROUP BY CALENDAR_YEAR(SystemModstamp), CALENDAR_MONTH(SystemModstamp)
                           ORDER BY CALENDAR_YEAR(SystemModstamp), CALENDAR_MONTH(SystemModstamp)]) {
    System.debug('   ' + ar.get('a') + '-' + String.valueOf(ar.get('m')).leftPad(2, '0')
        + '  modificados: ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('4. QUIEN LOS CREO');
System.debug('===================================================');
System.debug('   Una carga masiva deja casi todo a nombre de un solo usuario.');
for (AggregateResult ar : [SELECT CreatedBy.Name n, COUNT(Id) q
                           FROM Lead
                           WHERE CreatedDate >= :hace400
                           GROUP BY CreatedBy.Name
                           ORDER BY COUNT(Id) DESC
                           LIMIT 15]) {
    System.debug('   ' + ar.get('n') + ' | ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('5. DE DONDE DICEN QUE VIENEN');
System.debug('===================================================');
System.debug('   Un LeadSource inventado del tipo SEED o TEST delata el ejercicio.');
for (AggregateResult ar : [SELECT LeadSource s, COUNT(Id) q
                           FROM Lead
                           WHERE CreatedDate >= :hace400
                           GROUP BY LeadSource
                           ORDER BY COUNT(Id) DESC
                           LIMIT 25]) {
    System.debug('   ' + ar.get('s') + ' | ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('6. LAS CONVERSIONES');
System.debug('===================================================');
System.debug('   ConvertedDate no se puede retroceder por ningun medio. Si las 608');
System.debug('   conversiones caen todas en el mismo mes, fueron hechas en lote, y');
System.debug('   eso si es rastro de un ejercicio de habilitacion.');
for (AggregateResult ar : [SELECT CALENDAR_YEAR(ConvertedDate) a,
                                  CALENDAR_MONTH(ConvertedDate) m, COUNT(Id) q
                           FROM Lead
                           WHERE IsConverted = true
                           GROUP BY CALENDAR_YEAR(ConvertedDate), CALENDAR_MONTH(ConvertedDate)
                           ORDER BY CALENDAR_YEAR(ConvertedDate), CALENDAR_MONTH(ConvertedDate)]) {
    System.debug('   ' + ar.get('a') + '-' + String.valueOf(ar.get('m')).leftPad(2, '0')
        + '  convertidos: ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('7. LOS TRES UMBRALES, OTRA VEZ, PARA CERRAR');
System.debug('===================================================');
Datetime hace200 = System.now().addDays(-200);
Datetime hace180 = System.now().addDays(-180);
Integer creados200 = [SELECT COUNT() FROM Lead WHERE CreatedDate >= :hace200];
Integer conv200    = [SELECT COUNT() FROM Lead
                      WHERE CreatedDate >= :hace200 AND IsConverted = true];
Integer conOpp180  = [SELECT COUNT() FROM Lead
                      WHERE CreatedDate >= :hace180 AND IsConverted = true
                        AND ConvertedOpportunityId != null];
System.debug('   creados en 200 dias : ' + creados200 + '  (minimo 1000)  '
    + (creados200 >= 1000 ? 'CUMPLE' : 'NO CUMPLE'));
System.debug('   convertidos         : ' + conv200 + '  (minimo 120)   '
    + (conv200 >= 120 ? 'CUMPLE' : 'NO CUMPLE'));
System.debug('   con oportunidad     : ' + conOpp180 + '  (opcional 120) '
    + (conOpp180 >= 120 ? 'CUMPLE' : 'NO CUMPLE'));

Schema.SObjectField si = Lead.SObjectType.getDescribe()
    .fields.getMap().get('ScoreIntelligenceId');
System.debug('   Lead.ScoreIntelligenceId: ' + (si == null ? 'NO existe' : 'existe'));

System.debug('===================================================');
System.debug('8. COMO LEER ESTO');
System.debug('===================================================');
System.debug('   a) Punto 1 apagado y punto 3 repartido igual que el punto 2:');
System.debug('      aqui nunca se retrocedio nada, el dato es el que vino con el');
System.debug('      refresh del sandbox. No hay receta anterior que repetir;');
System.debug('   b) Punto 1 activo, o punto 3 concentrado en pocos dias: si hubo');
System.debug('      carga, y el script crear-leads-historicos-qa.apex repite el');
System.debug('      mismo mecanismo;');
System.debug('   c) En los dos casos, el punto 7 ya cumple los tres umbrales. La');
System.debug('      habilitacion sigue trabada por otra cosa, no por el dato, y');
System.debug('      crear mas leads no la desbloquea.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
