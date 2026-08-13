/**
 * POST DEPLOY HU-039, paso obligatorio despues de desplegar los Record Types.
 *
 * Product2 no tenia Record Types (verificado con GAPCHECK7 el 13/08). Al crear
 * los tres, los 281 productos que ya existen NO quedan asignados al Record Type
 * Material solos: hay que asignarlos. Si esto no se corre, los productos del
 * catalogo aparecen sin Record Type y las List Views por Record Type de la
 * RN-62 no los muestran.
 *
 * Es idempotente: se puede correr las veces que haga falta.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

Id rtMaterial;
try {
    rtMaterial = Product2.SObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('Material')
        .getRecordTypeId();
} catch (Exception e) {
    System.debug('ERROR: no se encontro el Record Type Material. '
        + 'Desplegar primero deploy-hu039-solicitud-material.zip. ' + e.getMessage());
    return;
}
System.debug('Record Type Material: ' + rtMaterial);

// Solo los que NO estan ya en Material. Los Record Types de solicitud se
// respetan: si algun registro ya nacio como solicitud, no se toca.
List<Product2> pendientes = [
    SELECT Id, Name, RecordTypeId
    FROM Product2
    WHERE RecordTypeId != :rtMaterial
    LIMIT 10000
];

System.debug('Productos a reasignar: ' + pendientes.size());
if (pendientes.isEmpty()) {
    System.debug('Nada por hacer, todos los productos ya estan en el Record Type Material.');
    return;
}

for (Product2 p : pendientes) {
    p.RecordTypeId = rtMaterial;
}

Integer ok = 0;
Integer fallo = 0;
List<Database.SaveResult> resultados = Database.update(pendientes, false);
for (Integer i = 0; i < resultados.size(); i++) {
    if (resultados[i].isSuccess()) {
        ok++;
    } else {
        fallo++;
        System.debug('FALLO en ' + pendientes[i].Name + ': ' + resultados[i].getErrors()[0].getMessage());
    }
}
System.debug('Reasignados: ' + ok + ' | Con error: ' + fallo);
System.debug('FIN. Recordar el paso manual: asignar los Record Types a los perfiles '
    + 'en Setup, Profiles, Record Type Settings, si no los usuarios no los ven.');
