/**
 * Asigna la licencia Sales Cloud Einstein al usuario que corre el script.
 *
 * Diagnostico del 15/08 en la org 00DWJ000008GgDB2A0, QA:
 *   - los tres umbrales de datos YA SE CUMPLEN, 1448 creados en 200 dias,
 *     608 convertidos, 507 con oportunidad;
 *   - Lead.ScoreIntelligenceId NO existe, o sea la habilitacion nunca completo;
 *   - la licencia Sales Cloud Einstein existe, 80 asientos, 2 en uso, y NO
 *     estaba asignada al usuario.
 *
 * Por eso el bloqueo no es dato y no hay ninguna fecha que cambiar. Es la
 * licencia. CreatedDate ademas no se puede actualizar por DML: solo se puede
 * fijar al INSERTAR, y unicamente con el permiso de audit fields habilitado.
 *
 * Corre en modo simulacion. Para aplicar, cambiar EJECUTAR a true.
 */

// ==========  CAMBIAR A true PARA APLICAR  ==========
Boolean EJECUTAR = false;
// ===================================================

String LICENCIA = 'SalesCloudEinsteinPsl';

Organization laOrg = [SELECT Id, Name, IsSandbox, OrganizationType
                      FROM Organization LIMIT 1];
Id yo = UserInfo.getUserId();
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | sandbox=' + laOrg.IsSandbox + ' | edicion=' + laOrg.OrganizationType);
System.debug('USUARIO: ' + UserInfo.getName() + ' | ' + yo);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, no escribe nada'));

System.debug('===================================================');
System.debug('1. LA LICENCIA');
System.debug('===================================================');
List<PermissionSetLicense> lics = [SELECT Id, MasterLabel, DeveloperName,
                                          TotalLicenses, UsedLicenses, Status
                                   FROM PermissionSetLicense
                                   WHERE DeveloperName = :LICENCIA];
if (lics.isEmpty()) {
    System.debug('   No existe ' + LICENCIA + ' en esta org. Nada que hacer.');
    return;
}
PermissionSetLicense lic = lics[0];
System.debug('   ' + lic.MasterLabel + ' | total=' + lic.TotalLicenses
    + ' | usadas=' + lic.UsedLicenses + ' | estado=' + lic.Status);
if (lic.UsedLicenses >= lic.TotalLicenses) {
    System.debug('   SIN ASIENTOS LIBRES. Hay que liberar uno o pedir mas.');
    return;
}

Boolean yaTengo = ![SELECT Id FROM PermissionSetLicenseAssign
                    WHERE AssigneeId = :yo
                      AND PermissionSetLicenseId = :lic.Id].isEmpty();
System.debug('   Ya asignada a mi: ' + (yaTengo ? 'SI' : 'NO'));

System.debug('===================================================');
System.debug('2. LOS PERMISSION SETS QUE DEPENDEN DE ELLA');
System.debug('===================================================');
System.debug('   La licencia sola habilita, pero el acceso viene del');
System.debug('   permission set asociado. Los dos hacen falta.');
List<PermissionSet> setsDeLic = new List<PermissionSet>();
try {
    setsDeLic = [SELECT Id, Name, Label FROM PermissionSet
                 WHERE LicenseId = :lic.Id ORDER BY Label];
    for (PermissionSet ps : setsDeLic) {
        Boolean tengo = ![SELECT Id FROM PermissionSetAssignment
                          WHERE AssigneeId = :yo AND PermissionSetId = :ps.Id].isEmpty();
        System.debug('   ' + ps.Label + '  (' + ps.Name + ')'
            + ' | asignado a mi=' + (tengo ? 'SI' : 'NO'));
    }
    if (setsDeLic.isEmpty()) {
        System.debug('   Ninguno. Solo hace falta la licencia.');
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo PermissionSet: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('3. LO QUE VA A PASAR');
System.debug('===================================================');
List<SObject> aInsertar = new List<SObject>();
if (!yaTengo) {
    aInsertar.add(new PermissionSetLicenseAssign(
        AssigneeId = yo, PermissionSetLicenseId = lic.Id));
    System.debug('   ASIGNAR licencia ' + lic.MasterLabel);
}
for (PermissionSet ps : setsDeLic) {
    Boolean tengo = ![SELECT Id FROM PermissionSetAssignment
                      WHERE AssigneeId = :yo AND PermissionSetId = :ps.Id].isEmpty();
    if (!tengo) {
        aInsertar.add(new PermissionSetAssignment(
            AssigneeId = yo, PermissionSetId = ps.Id));
        System.debug('   ASIGNAR permission set ' + ps.Label);
    }
}
if (aInsertar.isEmpty()) {
    System.debug('   Nada que asignar, ya esta todo.');
}

System.debug('===================================================');
System.debug('4. RESULTADO');
System.debug('===================================================');
if (aInsertar.isEmpty()) {
    System.debug('   Sin cambios. Si el score sigue sin aparecer, ver el punto 5.');
} else if (!EJECUTAR) {
    System.debug('   SIMULACION. ' + aInsertar.size() + ' asignaciones pendientes.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true y correr de nuevo.');
} else {
    List<Database.SaveResult> r = Database.insert(aInsertar, false);
    Integer ok = 0;
    for (Integer i = 0; i < r.size(); i++) {
        if (r[i].isSuccess()) { ok++; }
        else { System.debug('   FALLO: ' + r[i].getErrors()[0].getMessage()); }
    }
    System.debug('   Asignadas ' + ok + ' de ' + aInsertar.size());
}

System.debug('===================================================');
System.debug('5. DESPUES DE ESTO, EN ESTE ORDEN');
System.debug('===================================================');
System.debug('   1. Setup, Einstein Sales, Einstein Lead Scoring, y habilitar;');
System.debug('   2. Esperar el aviso de que la habilitacion termino. Es');
System.debug('      ASINCRONO y no es inmediato;');
System.debug('   3. Confirmar que Lead.ScoreIntelligenceId ya existe, con este');
System.debug('      describe. Mientras no exista, no hay score que mostrar:');
System.debug('         Lead.SObjectType.getDescribe().fields.getMap()');
System.debug('             .containsKey(\'ScoreIntelligenceId\')');
System.debug('   4. Dar lectura a Company, Phone y Email en Lead al perfil que');
System.debug('      va a ver el puntaje. Sin eso no se muestra;');
System.debug('   5. Einstein reanaliza cada 10 dias aproximadamente.');
System.debug('   ');
System.debug('   Y no hay ninguna fecha que cambiar. Los umbrales ya se cumplen,');
System.debug('   y CreatedDate no se actualiza por DML en ningun caso.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
