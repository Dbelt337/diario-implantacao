/**
 * Crea leads de prueba con CreatedDate distribuido en el tiempo, en QA.
 *
 * POR QUE CREAR Y NO ACTUALIZAR: CreatedDate no se actualiza por DML nunca. Se
 * puede fijar SOLO al insertar, y solo con el permiso de audit fields. Los 1448
 * leads que ya existen no se pueden retroceder.
 *
 * POR QUE DISTRIBUIR Y NO EMPUJAR ATRAS: el criterio de Einstein cuenta los
 * ultimos 200 dias. Un lead creado hace mas de 200 dias deja de contar. Lo que
 * falta hoy en esta org no es cantidad, es distribucion: 607 de 608
 * conversiones estan en un solo mes.
 *
 * ANTES DE CORRER, DOS COSAS EN SETUP:
 *   1. Setup, User Interface, marcar "Enable Set Audit Fields upon Record
 *      Creation and Update Records with Inactive Owners User Permissions";
 *   2. Dar el permiso "Set Audit Fields upon Record Creation" al usuario, por
 *      permission set. Sin eso el insert con CreatedDate falla.
 *
 * El script verifica las dos y avisa si falta alguna.
 *
 * Corre en modo simulacion, que inserta de verdad y hace rollback, asi los
 * errores reales aparecen sin dejar basura. Para aplicar, EJECUTAR = true.
 */

// ==========  CONFIGURACION  ==========
Boolean EJECUTAR = false;

Integer CUANTOS       = 300;   // leads a crear
Integer DESDE_DIAS    = 190;   // el mas viejo, dentro de los 200
Integer HASTA_DIAS    = 30;    // el mas nuevo
Integer PCT_CONVERTIR = 40;    // porcentaje a convertir

// Marca para poder borrarlos despues. NO CAMBIAR sin anotar donde.
String MARCA = 'SEED-EINSTEIN';
// =====================================

Organization laOrg = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id + ' | sandbox=' + laOrg.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, inserta y hace rollback'));
if (!laOrg.IsSandbox) {
    System.debug('   NO ES SANDBOX. Este script no debe correr en produccion.');
    return;
}

System.debug('===================================================');
System.debug('1. EL PERMISO DE AUDIT FIELDS');
System.debug('===================================================');
// OJO: la consulta va DINAMICA a proposito. El campo PermissionsSetAuditFields
// no existe en la org mientras la preferencia de Setup este desmarcada, y con
// SOQL estatica el script no compilaria, que es antes de que el try pueda
// atrapar nada.
Boolean puedeAudit = false;
Boolean existeElPermiso = true;
try {
    for (SObject p : Database.query(
            'SELECT PermissionsSetAuditFields FROM Profile WHERE Id = \''
            + UserInfo.getProfileId() + '\'')) {
        if (p.get('PermissionsSetAuditFields') == true) { puedeAudit = true; }
    }
    if (!puedeAudit) {
        for (SObject a : Database.query(
                'SELECT PermissionSet.PermissionsSetAuditFields FROM PermissionSetAssignment'
                + ' WHERE AssigneeId = \'' + UserInfo.getUserId() + '\'')) {
            SObject ps = a.getSObject('PermissionSet');
            if (ps != null && ps.get('PermissionsSetAuditFields') == true) { puedeAudit = true; }
        }
    }
} catch (Exception e) {
    existeElPermiso = false;
    System.debug('   El campo del permiso NO existe en la org: ' + e.getMessage());
}
System.debug('   Preferencia de Setup activa: ' + (existeElPermiso ? 'SI' : 'NO'));
System.debug('   Set Audit Fields en mi usuario: ' + (puedeAudit ? 'SI' : 'NO'));
if (!existeElPermiso || !puedeAudit) {
    System.debug('   Sin eso el insert con CreatedDate se ignora en silencio: la');
    System.debug('   fecha sale de hoy y el ejercicio no sirve. Habilitar primero');
    System.debug('   la preferencia en Setup, User Interface, y despues asignar el');
    System.debug('   permiso por permission set.');
    System.debug('   NO SEGUIR sin eso, seria crear 300 leads de hoy para nada.');
    return;
}

System.debug('===================================================');
System.debug('2. VALORES QUE LOS CAMPOS OBLIGATORIOS EXIGEN');
System.debug('===================================================');
// Se leen de la org para no inventar: hay validation rules en Lead que exigen
// metodo de contacto, y el status tiene valores en espanhol e ingles mezclados.
Map<String, Schema.SObjectField> campos = Lead.SObjectType.getDescribe().fields.getMap();

String estado = null;
for (Schema.PicklistEntry pe : campos.get('Status').getDescribe().getPicklistValues()) {
    if (!pe.isActive()) { continue; }
    if (pe.getValue() == 'Nuevo') { estado = pe.getValue(); }
    if (estado == null) { estado = pe.getValue(); }
}
System.debug('   Status a usar: ' + estado);

String metodo = null;
if (campos.containsKey('preferredcontactmethod__c')) {
    for (Schema.PicklistEntry pe :
            campos.get('preferredcontactmethod__c').getDescribe().getPicklistValues()) {
        if (pe.isActive() && metodo == null) { metodo = pe.getValue(); }
    }
}
System.debug('   PreferredContactMethod__c a usar: ' + metodo);

Id rtAutos = null;
for (Schema.RecordTypeInfo ri : Lead.SObjectType.getDescribe().getRecordTypeInfos()) {
    if (ri.getDeveloperName() == 'GQLeadsAutos') { rtAutos = ri.getRecordTypeId(); }
}
System.debug('   Record Type GQLeadsAutos: ' + (rtAutos == null ? 'NO existe' : 'ok'));

System.debug('===================================================');
System.debug('3. LO QUE VA A CREAR');
System.debug('===================================================');
List<Lead> nuevos = new List<Lead>();
Integer rango = DESDE_DIAS - HASTA_DIAS;
for (Integer i = 0; i < CUANTOS; i++) {
    // distribucion deterministica en el rango, sin Math.random
    Integer diasAtras = HASTA_DIAS + ((i * rango) / CUANTOS);
    Lead l = new Lead(
        LastName  = MARCA + '-' + String.valueOf(i).leftPad(4, '0'),
        FirstName = 'Seed',
        Company   = MARCA + ' Cia ' + String.valueOf(i),
        Status    = estado,
        LeadSource = MARCA,
        CreatedDate = System.now().addDays(-diasAtras)
    );
    if (rtAutos != null) { l.RecordTypeId = rtAutos; }
    if (metodo != null) { l.put('PreferredContactMethod__c', metodo); }
    nuevos.add(l);
}
System.debug('   ' + CUANTOS + ' leads, de hace ' + DESDE_DIAS
    + ' dias hasta hace ' + HASTA_DIAS + ' dias');
System.debug('   Todos con LastName y LeadSource marcados como ' + MARCA);
System.debug('   Para borrarlos despues: DELETE FROM Lead WHERE LeadSource = \''
    + MARCA + '\'');
System.debug('   Convertir ' + PCT_CONVERTIR + ' por ciento de ellos');

System.debug('===================================================');
System.debug('4. INSERCION');
System.debug('===================================================');
System.debug('   Se saltan las reglas de asignacion y se permiten duplicados,');
System.debug('   si no las 14 automatizaciones de Lead y las reglas de duplicado');
System.debug('   pelean con la carga.');

Savepoint sp = Database.setSavepoint();
Boolean ok = true;
try {
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.assignmentRuleHeader.useDefaultRule = false;
    dml.DuplicateRuleHeader.AllowSave = true;
    dml.optAllOrNone = false;

    List<Database.SaveResult> res = Database.insert(nuevos, dml);
    Integer creados = 0;
    Map<String, Integer> errores = new Map<String, Integer>();
    for (Integer i = 0; i < res.size(); i++) {
        if (res[i].isSuccess()) { creados++; continue; }
        String msg = res[i].getErrors()[0].getMessage();
        errores.put(msg, errores.containsKey(msg) ? errores.get(msg) + 1 : 1);
    }
    System.debug('   Insertados: ' + creados + ' de ' + CUANTOS);
    for (String m : errores.keySet()) {
        System.debug('   ERROR x' + errores.get(m) + ': ' + m);
    }
    if (creados == 0) { ok = false; }

    if (creados > 0) {
        System.debug('   Verificando que CreatedDate quedo retroactivo:');
        for (Lead l : [SELECT LastName, CreatedDate FROM Lead
                       WHERE LeadSource = :MARCA
                       ORDER BY CreatedDate LIMIT 3]) {
            System.debug('        ' + l.LastName + ' | ' + l.CreatedDate);
        }
        System.debug('   Si la fecha salio de hoy, el permiso de audit fields no');
        System.debug('   esta activo y el ejercicio no sirve.');
    }

    // conversion
    Integer aConvertir = (creados * PCT_CONVERTIR) / 100;
    if (creados > 0 && aConvertir > 0) {
        LeadStatus convertido = [SELECT MasterLabel FROM LeadStatus
                                 WHERE IsConverted = true LIMIT 1];
        List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
        for (Lead l : [SELECT Id FROM Lead WHERE LeadSource = :MARCA
                       AND IsConverted = false LIMIT :aConvertir]) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertido.MasterLabel);
            lc.setDoNotCreateOpportunity(false);
            lcs.add(lc);
        }
        List<Database.LeadConvertResult> lr = Database.convertLead(lcs, false);
        Integer conv = 0;
        Map<String, Integer> errConv = new Map<String, Integer>();
        for (Database.LeadConvertResult r : lr) {
            if (r.isSuccess()) { conv++; continue; }
            String m = r.getErrors()[0].getMessage();
            errConv.put(m, errConv.containsKey(m) ? errConv.get(m) + 1 : 1);
        }
        System.debug('   Convertidos: ' + conv + ' de ' + lcs.size());
        for (String m : errConv.keySet()) {
            System.debug('   ERROR conversion x' + errConv.get(m) + ': ' + m);
        }
        System.debug('   OJO: ConvertedDate queda HOY para todos. Eso no se puede');
        System.debug('   retroceder de ninguna forma.');
    }
} catch (Exception e) {
    ok = false;
    System.debug('   EXCEPCION: ' + e.getTypeName() + ' | ' + e.getMessage());
}

if (!EJECUTAR) {
    Database.rollback(sp);
    System.debug('===================================================');
    System.debug('   ROLLBACK HECHO. No quedo nada en la org.');
    System.debug('   Los errores de arriba son reales, no simulados.');
    System.debug('   Para aplicar de verdad: EJECUTAR = true.');
} else if (!ok) {
    Database.rollback(sp);
    System.debug('   Fallo todo, se hizo rollback para no dejar a medias.');
} else {
    System.debug('   APLICADO.');
}

System.debug('===================================================');
System.debug('5. LO QUE ESTO NO RESUELVE');
System.debug('===================================================');
System.debug('   Los tres umbrales de Einstein YA se cumplian antes de esto.');
System.debug('   Y la habilitacion sigue sin completar 72 horas despues, con');
System.debug('   licencia y permission set asignados. Sumar dato distribuido');
System.debug('   mejora el modelo SI algun dia entrena, pero no desbloquea la');
System.debug('   habilitacion. Ese punto sigue siendo caso de Support.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
