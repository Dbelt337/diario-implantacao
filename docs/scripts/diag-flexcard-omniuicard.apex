/**
 * DIAGNOSTICO, error de FlexCard:
 *   "No such column 'PropertySetConfig' on entity 'OmniUiCard'"
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 *
 * IMPORTANTE: ejecutarlo DOS veces, una como administrador y otra como el
 * usuario que ve el error, o usar System.runAs si no se puede. La diferencia
 * entre las dos corridas es el diagnostico.
 *
 * Como leer el resultado:
 *   A) El campo NO aparece en la lista  -> el objeto de la org no tiene ese
 *      campo. Es un desfase de version de OmniStudio, no es permisos.
 *   B) El campo aparece con accesible=false -> es FLS. Salesforce responde
 *      "No such column" cuando el campo existe pero el usuario no puede
 *      leerlo, justamente para no revelar que existe.
 *   C) El campo aparece con accesible=true para el usuario que ve el error
 *      -> el problema no es ni schema ni FLS, es la definicion de la
 *      FlexCard o el runtime de OmniStudio.
 */

System.debug('===================================================');
System.debug('DIAGNOSTICO FLEXCARD / OMNIUICARD');
System.debug('Usuario: ' + UserInfo.getUserName() + ' | Perfil Id: ' + UserInfo.getProfileId());
System.debug('===================================================');

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

System.debug('----- 1. OBJETOS DE OMNISTUDIO EN LA ORG -----');
for (String nombre : new List<String>{
        'OmniUiCard', 'OmniProcess', 'OmniDataTransform',
        'OmniProcessElement', 'OmniScriptEmbedded' }) {
    Schema.SObjectType t = gd.get(nombre.toLowerCase());
    if (t == null) {
        System.debug('   NO EXISTE : ' + nombre);
        continue;
    }
    Schema.DescribeSObjectResult d = t.getDescribe();
    System.debug('   OK        : ' + nombre
        + ' | accesible=' + d.isAccessible()
        + ' | consultable=' + d.isQueryable()
        + ' | campos=' + d.fields.getMap().size());
}

System.debug('----- 2. CAMPOS DE OMNIUICARD Y SU ACCESIBILIDAD -----');
Boolean encontrado = false;
try {
    Schema.SObjectType t = gd.get('omniuicard');
    if (t == null) {
        System.debug('   OmniUiCard no existe para este usuario. '
            + 'Puede ser falta de acceso al objeto o que OmniStudio no este habilitado.');
    } else {
        for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fd = f.getDescribe();
            System.debug('   ' + fd.getName()
                + ' | tipo=' + fd.getType()
                + ' | accesible=' + fd.isAccessible());
            if (fd.getName() == 'PropertySetConfig') { encontrado = true; }
        }
        System.debug('   >>> PropertySetConfig presente en el schema: ' + encontrado);
    }
} catch (Exception e) {
    System.debug('   ERROR describiendo OmniUiCard: ' + e.getMessage());
}

System.debug('----- 3. PRUEBA REAL DE LA CONSULTA QUE FALLA -----');
try {
    List<sObject> filas = Database.query(
        'SELECT Id, Name, PropertySetConfig, IsActive, AuthorName FROM OmniUiCard LIMIT 1');
    System.debug('   La consulta FUNCIONA para este usuario. Filas: ' + filas.size());
} catch (Exception e) {
    System.debug('   La consulta FALLA para este usuario: ' + e.getMessage());
}

System.debug('----- 4. LA FLEXCARD DEL ERROR -----');
try {
    for (sObject c : Database.query(
            'SELECT Id, Name, IsActive FROM OmniUiCard '
            + 'WHERE Name LIKE \'%ServiceExcellence%\' LIMIT 20')) {
        System.debug('   Card: ' + c.get('Name') + ' | activa=' + c.get('IsActive'));
    }
} catch (Exception e) {
    System.debug('   No se pudo listar: ' + e.getMessage());
}

System.debug('----- 5. PERMISSION SETS DE OMNISTUDIO Y SERVICE EXCELLENCE -----');
try {
    for (PermissionSet ps : [SELECT Name, Label, IsOwnedByProfile
                             FROM PermissionSet
                             WHERE (Name LIKE '%Omni%' OR Label LIKE '%Omni%'
                                    OR Label LIKE '%Service Excellence%')
                               AND IsOwnedByProfile = false
                             ORDER BY Label]) {
        System.debug('   ' + ps.Label + ' | apiName=' + ps.Name);
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo PermissionSet: ' + e.getMessage());
}

System.debug('----- 6. LO QUE ESTE USUARIO TIENE ASIGNADO -----');
try {
    for (PermissionSetAssignment a : [SELECT PermissionSet.Label
                                      FROM PermissionSetAssignment
                                      WHERE AssigneeId = :UserInfo.getUserId()
                                        AND (PermissionSet.Label LIKE '%Omni%'
                                             OR PermissionSet.Label LIKE '%Service Excellence%')]) {
        System.debug('   asignado: ' + a.PermissionSet.Label);
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
