/**
 * Que columnas de Product2 ya existen antes de crear 18 nuevas.
 *
 * La decision de gobernanza del 14/08 dice: nada nuevo sin antes verificar lo
 * que ya hay. El paquete de la HU-039 crea 18 campos y ese chequeo no se hizo
 * al armarlo. Este script lo hace.
 *
 * Imprime los campos estandar utilizables, los custom que ya existen, y cruza
 * los 18 propuestos contra un candidato estandar cuando lo hay.
 *
 * Solo lectura.
 */

Organization laOrg = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | sandbox=' + laOrg.IsSandbox);

Schema.DescribeSObjectResult p =
    Schema.getGlobalDescribe().get('product2').getDescribe();
Map<String, Schema.SObjectField> mapa = p.fields.getMap();

System.debug('===================================================');
System.debug('1. CAMPOS CUSTOM QUE YA EXISTEN EN Product2');
System.debug('===================================================');
Integer custom = 0;
for (Schema.SObjectField f : mapa.values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (!fd.isCustom()) { continue; }
    custom++;
    System.debug('   ' + fd.getName() + ' | ' + fd.getType()
        + ' | ' + fd.getLabel());
}
System.debug('   Total custom hoy: ' + custom);

System.debug('===================================================');
System.debug('2. CAMPOS ESTANDAR ESCRIBIBLES, LOS CANDIDATOS');
System.debug('===================================================');
for (Schema.SObjectField f : mapa.values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (fd.isCustom() || !fd.isCreateable()) { continue; }
    System.debug('   ' + fd.getName() + ' | ' + fd.getType()
        + ' | long=' + fd.getLength() + ' | ' + fd.getLabel());
}

System.debug('===================================================');
System.debug('3. LOS 18 PROPUESTOS CONTRA UN CANDIDATO ESTANDAR');
System.debug('===================================================');
Map<String, String> candidato = new Map<String, String>{
    'RequestStatus__c'         => 'sin equivalente, hace falta',
    'RequestKey__c'            => 'sin equivalente, es la clave unica del disenio',
    'RequestedMaterialCode__c' => 'ProductCode, ver nota A',
    'RequestCompany__c'        => 'sin equivalente, parte de la clave',
    'RequestPlant__c'          => 'sin equivalente, parte de la clave',
    'RequestBranch__c'         => 'sin equivalente, parte de la clave',
    'RequestedBy__c'           => 'CreatedById, ver nota B',
    'RequestFob__c'            => 'sin equivalente',
    'RequestOrigin__c'         => 'sin equivalente',
    'RequestVehicleModel__c'   => 'contexto de la venta, ver nota C',
    'RequestVin__c'            => 'contexto de la venta, ver nota C',
    'RequestNotes__c'          => 'Description ya se usa para la ficha, hace falta',
    'RejectionReason__c'       => 'sin equivalente, hace falta',
    'SapLastError__c'          => 'Nebula Logger esta instalado, ver nota D',
    'SapRetryCount__c'         => 'ver nota D',
    'SapLastAttempt__c'        => 'lo usa la vista de trabadas, hace falta',
    'TurnoverClass__c'         => 'sin equivalente',
    'SupersededByProduct__c'   => 'sin equivalente, resuelve el duplicado'
};
for (String c : new List<String>(candidato.keySet())) {
    Boolean yaExiste = mapa.containsKey(c.toLowerCase());
    System.debug('   ' + (yaExiste ? 'YA EXISTE  ' : 'A CREAR    ') + c);
    System.debug('        ' + candidato.get(c));
}

System.debug('===================================================');
System.debug('4. LAS CUATRO NOTAS');
System.debug('===================================================');
System.debug('   A. ProductCode es estandar y hoy queda libre, porque el codigo');
System.debug('      definitivo del SAP vive en SapMaterialCode__c. Como la');
System.debug('      solicitud y el material son el MISMO registro, ProductCode');
System.debug('      puede llevar el codigo solicitado desde el principio.');
System.debug('   B. CreatedById es estandar, siempre viene lleno, y la vista');
System.debug('      "Mis solicitudes" filtra igual de bien con el. Solo hace');
System.debug('      falta un campo propio si quien solicita puede ser distinto');
System.debug('      de quien crea el registro, por ejemplo si crea la integracion.');
System.debug('   C. VIN y modelo son contexto de UNA venta, no atributos del');
System.debug('      material. El material despues queda en el catalogo y lo usa');
System.debug('      todo el mundo, arrastrando para siempre el VIN de la primera');
System.debug('      solicitud. Ese dato pertenece a la linea de la cotizacion.');
System.debug('   D. Con Nebula Logger instalado, el texto del error y el conteo');
System.debug('      de intentos pueden vivir en el log referenciando el registro.');
System.debug('      En el producto alcanza con el estado y la fecha del ultimo');
System.debug('      intento, que es lo que la vista de trabadas necesita filtrar.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
