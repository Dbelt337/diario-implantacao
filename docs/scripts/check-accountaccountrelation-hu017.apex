/**
 * Verificacion de las premisas de la HU-017 sobre AccountAccountRelation.
 *
 * La RN-05 y la RN-35 se apoyan en tres afirmaciones sobre ese objeto:
 *   a) admite campos personalizados, donde vive el Grupo de Clientes;
 *   b) tiene historial de campos propio, que es lo que exige la RN-24;
 *   c) tiene comparticion propia, que es sobre lo que se apoya la RN-25.
 *
 * Ninguna de las tres se puede confirmar desde la documentacion publica sin
 * acceso a developer.salesforce.com, y las tres cambian la regla si son
 * falsas. Este script las responde de forma determinista.
 *
 * La prueba de (b) es la existencia del objeto AccountAccountRelationHistory:
 * Salesforce solo lo crea para objetos que soportan historial.
 * La prueba de (c) es la existencia de AccountAccountRelationShare.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

Organization org = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + org.Name + ' | ' + org.Id
    + ' | instancia=' + org.InstanceName + ' | sandbox=' + org.IsSandbox);

System.debug('===================================================');
System.debug('PREMISAS DE LA HU-017 SOBRE AccountAccountRelation');
System.debug('===================================================');

Map<String, Schema.SObjectType> esquema = Schema.getGlobalDescribe();

System.debug('----- 1. EXISTENCIA DE LOS OBJETOS -----');
List<String> aVerificar = new List<String>{
    'AccountAccountRelation',
    'AccountAccountRelationHistory',   // prueba de historial de campos
    'AccountAccountRelationShare',     // prueba de comparticion por registro
    'AccountAccountRelationFeed',
    'PartyRoleRelation',
    'AccountContactRelation',
    'InternalOrganizationUnit'
};
for (String api : aVerificar) {
    Boolean existe = esquema.containsKey(api.toLowerCase());
    System.debug('   ' + (existe ? 'SI ' : 'NO ') + api);
}

System.debug('----- 2. LECTURA DE LAS TRES PREMISAS -----');
Boolean hayObjeto  = esquema.containsKey('accountaccountrelation');
Boolean hayHistory = esquema.containsKey('accountaccountrelationhistory');
Boolean hayShare   = esquema.containsKey('accountaccountrelationshare');

System.debug('   a) Campos personalizados  => ver punto 3');
System.debug('   b) Historial de campos    => ' + (hayHistory
    ? 'SOPORTADO. La RN-24 sobre este atributo es viable.'
    : 'NO SOPORTADO. La RN-35 no puede exigir historial aqui.'));
System.debug('   c) Comparticion por registro => ' + (hayShare
    ? 'SOPORTADA. La RN-25 puede apoyarse en la relacion.'
    : 'NO SOPORTADA. La visibilidad por sociedad necesita otro mecanismo.'));

if (!hayObjeto) {
    System.debug('   El objeto no existe en esta org. Sin el, la RN-05 completa');
    System.debug('   necesita otro modelo. Verificar habilitacion en Setup.');
    return;
}

System.debug('----- 3. CAMPOS DEL OBJETO -----');
Schema.DescribeSObjectResult d = esquema.get('accountaccountrelation').getDescribe();
System.debug('   etiqueta   : ' + d.getLabel());
System.debug('   creable    : ' + d.isCreateable());
System.debug('   consultable: ' + d.isQueryable());
System.debug('   accesible  : ' + d.isAccessible());

Integer personalizados = 0;
for (Schema.SObjectField f : d.fields.getMap().values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (fd.isCustom()) {
        personalizados++;
        System.debug('   CUSTOM  ' + fd.getName() + ' | ' + fd.getLabel()
            + ' | ' + fd.getType());
    }
}
System.debug('   Campos personalizados existentes: ' + personalizados);
System.debug('   Si es 0, no significa que no admita: significa que nadie creo');
System.debug('   ninguno todavia. Confirmar el boton New en Setup, Object Manager.');

System.debug('   Campos estandar relevantes:');
for (String api : new List<String>{ 'AccountId', 'RelatedAccountId', 'Relation',
        'RelationshipType', 'StartDate', 'EndDate', 'IsActive' }) {
    Schema.SObjectField f = d.fields.getMap().get(api);
    if (f != null) {
        System.debug('        ' + api + ' | ' + f.getDescribe().getType()
            + ' | editable=' + f.getDescribe().isUpdateable());
    }
}

System.debug('----- 4. VOLUMEN ACTUAL -----');
try {
    System.debug('   Registros: ' + Database.countQuery(
        'SELECT COUNT() FROM AccountAccountRelation'));
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('----- 5. REPORTABILIDAD -----');
System.debug('   La vista de relaciones sin Grupo de Clientes propuesta para la');
System.debug('   RN-35 depende de poder reportar sobre este objeto.');
try {
    for (EntityDefinition ed : [
            SELECT QualifiedApiName, IsCustomizable, IsFeedEnabled,
                   IsQueryable, IsSearchable, IsCustomSetting
            FROM EntityDefinition
            WHERE QualifiedApiName IN ('AccountAccountRelation', 'PartyRoleRelation')]) {
        System.debug('   ' + ed.QualifiedApiName
            + ' | personalizable=' + ed.IsCustomizable
            + ' | consultable=' + ed.IsQueryable
            + ' | buscable=' + ed.IsSearchable);
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo EntityDefinition: ' + e.getMessage());
}
System.debug('   Si no aparece como tipo de informe estandar, hace falta un');
System.debug('   Custom Report Type. Es trabajo menor, pero hay que preverlo.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
