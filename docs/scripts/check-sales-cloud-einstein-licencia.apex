/**
 * Por que Einstein Lead Scoring no habilita, cuando los datos ya cumplen.
 *
 * Verificado el 15/08 contra la pagina oficial de consideraciones: los tres
 * umbrales ya se cumplen en esta org, 1448 leads creados en 200 dias, 608
 * convertidos y 507 con oportunidad. Entonces el problema no es el dato.
 *
 * La pagina dice "Available with Sales Cloud Einstein", que es una permission
 * set license aparte. Este script verifica si esta provisionada en la org y si
 * esta asignada al usuario, que es la causa mas probable de que la pantalla de
 * setup no concluya sin dar un error claro.
 *
 * Solo lectura.
 */

Organization laOrg = [SELECT Id, Name, InstanceName, IsSandbox, OrganizationType
                      FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | instancia=' + laOrg.InstanceName
    + ' | sandbox=' + laOrg.IsSandbox
    + ' | edicion=' + laOrg.OrganizationType);
System.debug('   La pagina exige Performance o Unlimited, o Enterprise con');
System.debug('   costo adicional. Si la edicion no es una de esas, se explica solo.');

System.debug('===================================================');
System.debug('1. PERMISSION SET LICENSES DE LA ORG');
System.debug('===================================================');
System.debug('   Buscando cualquiera que suene a Einstein o Sales Cloud.');
Id yo = UserInfo.getUserId();
Set<Id> mias = new Set<Id>();
try {
    for (PermissionSetLicenseAssign a : [SELECT PermissionSetLicenseId
                                         FROM PermissionSetLicenseAssign
                                         WHERE AssigneeId = :yo]) {
        mias.add(a.PermissionSetLicenseId);
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo asignaciones: ' + e.getMessage());
}

Boolean hayEinstein = false;
try {
    for (PermissionSetLicense p : [SELECT Id, MasterLabel, DeveloperName,
                                          TotalLicenses, UsedLicenses, Status
                                   FROM PermissionSetLicense
                                   ORDER BY MasterLabel]) {
        String n = (p.MasterLabel == null ? '' : p.MasterLabel.toLowerCase())
                 + ' ' + (p.DeveloperName == null ? '' : p.DeveloperName.toLowerCase());
        Boolean relevante = n.contains('einstein') || n.contains('sales cloud')
                         || n.contains('salescloud');
        if (!relevante) { continue; }
        hayEinstein = true;
        System.debug('   ' + p.MasterLabel + '  (' + p.DeveloperName + ')');
        System.debug('        total=' + p.TotalLicenses
            + ' | usadas=' + p.UsedLicenses
            + ' | estado=' + p.Status
            + ' | ASIGNADA A MI=' + (mias.contains(p.Id) ? 'SI' : 'NO'));
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo PermissionSetLicense: ' + e.getMessage());
}
if (!hayEinstein) {
    System.debug('   NO aparece ninguna licencia de Einstein en esta org.');
    System.debug('   Esa es la respuesta: sin provisionar, la pantalla no concluye.');
    System.debug('   Se pide al account executive de Salesforce, no se resuelve aqui.');
}

System.debug('===================================================');
System.debug('2. TODAS LAS PERMISSION SET LICENSES, PARA NO ADIVINAR');
System.debug('===================================================');
try {
    for (PermissionSetLicense p : [SELECT MasterLabel, DeveloperName,
                                          TotalLicenses, UsedLicenses
                                   FROM PermissionSetLicense
                                   ORDER BY MasterLabel LIMIT 200]) {
        System.debug('   ' + p.MasterLabel + ' | total=' + p.TotalLicenses
            + ' | usadas=' + p.UsedLicenses);
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('3. EL CAMPO Y LOS OBJETOS QUE EINSTEIN CREA');
System.debug('===================================================');
System.debug('   Si Einstein Lead Scoring ya se habilito alguna vez, aparecen.');
Map<String, Schema.SObjectType> esquema = Schema.getGlobalDescribe();
Integer encontrados = 0;
for (String api : esquema.keySet()) {
    if (api.contains('score') || api.contains('einstein')) {
        System.debug('   objeto: ' + esquema.get(api).getDescribe().getName());
        encontrados++;
    }
}
Schema.SObjectField si = Lead.SObjectType.getDescribe()
    .fields.getMap().get('ScoreIntelligenceId');
System.debug('   Lead.ScoreIntelligenceId: ' + (si == null ? 'NO existe' : 'existe'));
if (encontrados == 0 && si == null) {
    System.debug('   Nada. Einstein Lead Scoring nunca completo la habilitacion');
    System.debug('   en esta org.');
}

System.debug('===================================================');
System.debug('4. LOS DATOS, CONFIRMANDO QUE NO SON EL PROBLEMA');
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
System.debug('   ');
System.debug('   NO TOCAR LAS FECHAS. CreatedDate no se actualiza por DML, y los');
System.debug('   umbrales ya se cumplen. Cambiar dato aqui no resuelve nada y');
System.debug('   destruye la base de prueba.');

System.debug('===================================================');
System.debug('5. LO OTRO QUE PUEDE SER, Y NO ES ERROR');
System.debug('===================================================');
System.debug('   La habilitacion es ASINCRONA. Salesforce avisa cuando termina,');
System.debug('   y despues reanaliza los leads aproximadamente cada 10 dias. Si');
System.debug('   se habilito hoy, no hay puntaje en pantalla todavia y eso es');
System.debug('   comportamiento normal, no falla.');
System.debug('   ');
System.debug('   Y los representantes necesitan acceso de lectura a Company,');
System.debug('   Phone y Email en Lead. Sin eso el puntaje no se muestra.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
