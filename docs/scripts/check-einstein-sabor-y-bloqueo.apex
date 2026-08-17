/**
 * Cual de los dos Einstein tiene esta org, y si eso explica el bloqueo.
 *
 * POR QUE ESTE SCRIPT: hay DOS productos distintos con nombre parecido, y solo
 * uno funciona en sandbox.
 *
 *   a) "Sales Cloud Einstein", el add-on de pago. Funciona en sandbox;
 *   b) "Sales Cloud Einstein for Everyone", el que viene incluido en Enterprise.
 *      Su permission set NO APARECE en sandbox ni despues de un license match, y
 *      eso es comportamiento esperado, no un error (KB 000393373).
 *
 * Si esta org solo tiene el sabor (b), no hay script, ni caso, ni dato que lo
 * arregle en QA. Se prueba en produccion o no se prueba.
 *
 * El script tambien imprime Status y fecha de expiracion de cada licencia, que
 * es lo que el diagnostico anterior no mostro: una licencia puede estar listada
 * y al mismo tiempo expirada o deshabilitada.
 *
 * Solo lectura. Los campos se leen por describe antes de consultarlos, para que
 * el script no dependa de que existan.
 */

Organization laOrg = [SELECT Id, Name, IsSandbox, OrganizationType, InstanceName
                      FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | sandbox=' + laOrg.IsSandbox
    + ' | edicion=' + laOrg.OrganizationType
    + ' | instancia=' + laOrg.InstanceName);

// Se arma la lista de campos con lo que realmente existe en esta version.
Map<String, Schema.SObjectField> mapaPsl =
    PermissionSetLicense.SObjectType.getDescribe().fields.getMap();
List<String> cols = new List<String>{
    'Id', 'DeveloperName', 'MasterLabel', 'TotalLicenses', 'UsedLicenses'
};
for (String extra : new List<String>{ 'Status', 'ExpirationDate' }) {
    if (mapaPsl.containsKey(extra.toLowerCase())) { cols.add(extra); }
}

System.debug('===================================================');
System.debug('1. LOS DOS SABORES, Y CUAL HAY AQUI');
System.debug('===================================================');

Id yo = UserInfo.getUserId();
Set<Id> mias = new Set<Id>();
for (PermissionSetLicenseAssign a : [SELECT PermissionSetLicenseId
                                     FROM PermissionSetLicenseAssign
                                     WHERE AssigneeId = :yo]) {
    mias.add(a.PermissionSetLicenseId);
}

Boolean hayAddOn = false;
Boolean hayForEveryone = false;

for (SObject p : Database.query(
        'SELECT ' + String.join(cols, ', ') + ' FROM PermissionSetLicense'
        + ' ORDER BY MasterLabel LIMIT 300')) {

    String dev = String.valueOf(p.get('DeveloperName'));
    String etq = String.valueOf(p.get('MasterLabel'));
    String junto = (dev + ' ' + etq).toLowerCase();
    if (!junto.contains('einstein')) { continue; }

    Boolean esForEveryone = junto.contains('everyone') || junto.contains('foreveryone');
    if (esForEveryone) { hayForEveryone = true; }
    if (junto.contains('sales') && !esForEveryone) { hayAddOn = true; }

    // el bind necesita una variable simple, un cast en linea no compila
    Id idLic = (Id) p.get('Id');
    Integer asignadas = [SELECT COUNT() FROM PermissionSetLicenseAssign
                         WHERE PermissionSetLicenseId = :idLic];

    System.debug('   ' + etq + '  (' + dev + ')');
    System.debug('        sabor    : ' + (esForEveryone ? 'FOR EVERYONE, no sirve en sandbox'
                                                        : 'add-on, si sirve en sandbox'));
    System.debug('        asientos : total=' + p.get('TotalLicenses')
        + ' | usadas=' + p.get('UsedLicenses') + ' | asignaciones=' + asignadas);
    if (cols.contains('Status')) {
        System.debug('        estado   : ' + p.get('Status'));
    }
    if (cols.contains('ExpirationDate')) {
        Object exp = p.get('ExpirationDate');
        System.debug('        expira   : ' + (exp == null ? 'sin fecha' : String.valueOf(exp)));
    }
    System.debug('        mia      : ' + (mias.contains(idLic) ? 'SI' : 'NO'));
}

System.debug('   ---------------------------------------------');
if (hayAddOn) {
    System.debug('   Hay add-on de pago. El sandbox ESTA soportado, entonces el');
    System.debug('   bloqueo no es el sabor de licencia. Seguir al punto 3.');
} else if (hayForEveryone) {
    System.debug('   SOLO hay "for Everyone". Eso explica todo: en sandbox no');
    System.debug('   aparece por diseno. No se arregla aqui.');
} else {
    System.debug('   No hay ninguna licencia de Einstein. Se pide al account');
    System.debug('   executive, no se resuelve con configuracion.');
}

System.debug('===================================================');
System.debug('2. LOS PERMISSION SETS DE ESAS LICENCIAS');
System.debug('===================================================');
System.debug('   La licencia habilita, el permission set da el acceso. Faltando');
System.debug('   uno de los dos, la pantalla de setup no concluye.');
for (PermissionSet ps : [SELECT Id, Name, Label, LicenseId, License.MasterLabel
                         FROM PermissionSet
                         WHERE LicenseId != null
                         ORDER BY Label LIMIT 300]) {
    String n = (ps.Label + ' ' + ps.Name).toLowerCase();
    if (!n.contains('einstein')) { continue; }
    Boolean tengo = ![SELECT Id FROM PermissionSetAssignment
                      WHERE AssigneeId = :yo AND PermissionSetId = :ps.Id].isEmpty();
    System.debug('   ' + ps.Label + '  (' + ps.Name + ')');
    System.debug('        licencia=' + ps.License.MasterLabel
        + ' | asignado a mi=' + (tengo ? 'SI' : 'NO'));
}

System.debug('===================================================');
System.debug('3. SI LA HABILITACION YA TERMINO');
System.debug('===================================================');
Schema.SObjectField si = Lead.SObjectType.getDescribe()
    .fields.getMap().get('ScoreIntelligenceId');
System.debug('   Lead.ScoreIntelligenceId: ' + (si == null ? 'NO existe' : 'existe'));
System.debug('   Mientras no exista, la habilitacion no concluyo. Y OJO: la');
System.debug('   documentacion dice que la creacion del primer modelo tarda');
System.debug('   DE 24 A 72 HORAS, no 24. Si se habilito el 15, el 17 todavia');
System.debug('   esta dentro de la ventana normal.');

Map<String, Schema.SObjectType> esquema = Schema.getGlobalDescribe();
for (String api : esquema.keySet()) {
    if (api.contains('scoreintelligence') || api.contains('leadinsight')
        || api.contains('einstein')) {
        System.debug('   objeto que aparecio: ' + esquema.get(api).getDescribe().getName());
    }
}

System.debug('===================================================');
System.debug('4. EL DATO, QUE NO ES EL BLOQUEO');
System.debug('===================================================');
System.debug('   La propia documentacion dice que si no hay dato suficiente,');
System.debug('   Einstein usa el MODELO GLOBAL, anonimo, de muchos clientes. O');
System.debug('   sea, falta de dato NUNCA impide habilitar, degrada la calidad.');
System.debug('   Con eso, crear leads no desbloquea nada. Se confirma abajo solo');
System.debug('   para poder escribirlo en el caso de Support.');
Datetime hace200 = System.now().addDays(-200);
Datetime hace180 = System.now().addDays(-180);
System.debug('   creados en 200 dias : '
    + [SELECT COUNT() FROM Lead WHERE CreatedDate >= :hace200] + '  (minimo 1000)');
System.debug('   convertidos         : '
    + [SELECT COUNT() FROM Lead WHERE CreatedDate >= :hace200 AND IsConverted = true]
    + '  (minimo 120)');
System.debug('   con oportunidad     : '
    + [SELECT COUNT() FROM Lead WHERE CreatedDate >= :hace180 AND IsConverted = true
        AND ConvertedOpportunityId != null] + '  (opcional 120)');

System.debug('===================================================');
System.debug('5. QUE HACER, EN ESTE ORDEN');
System.debug('===================================================');
System.debug('   1. Setup, Company Information, Match Production Licenses. Lleva');
System.debug('      las licencias de produccion al sandbox sin refresh. Pide');
System.debug('      Modify All Data y que sandbox y produccion esten en la MISMA');
System.debug('      release. Es gratis y es un minuto;');
System.debug('   2. Volver a Setup, Sales Cloud Einstein, Setup Assistant, y');
System.debug('      entrar por ahi a Einstein Lead Scoring, no por la busqueda;');
System.debug('   3. Esperar hasta 72 horas contadas desde la ultima habilitacion;');
System.debug('   4. Si pasadas las 72 horas ScoreIntelligenceId sigue sin existir,');
System.debug('      es el known issue "Einstein Lead Scoring is stuck. It has been');
System.debug('      more than 24 hours", W-9138919. La salida oficial es caso de');
System.debug('      Support, citando el known issue y el Id de esta org.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
