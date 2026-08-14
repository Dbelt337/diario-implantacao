/**
 * Responde de forma definitiva si se puede hacer UPSERT en PricebookEntry
 * por un campo External Id.
 *
 * Tener un campo marcado como External Id no alcanza: la API solo admite
 * usarlo como clave de upsert si el campo tiene la propiedad idLookup en
 * true. Ese es el flag que decide, y es lo que este script imprime.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 *
 * Correrlo DESPUES de desplegar el campo PriceKey__c.
 */

System.debug('===================================================');
System.debug('PRICEBOOKENTRY, CAPACIDAD DE UPSERT');
System.debug('===================================================');

Schema.DescribeSObjectResult d = PricebookEntry.SObjectType.getDescribe();
System.debug('Objeto: creable=' + d.isCreateable()
    + ' | actualizable=' + d.isUpdateable()
    + ' | campos=' + d.fields.getMap().size());

System.debug('----- CAMPOS CUSTOM Y CANDIDATOS A CLAVE DE UPSERT -----');
Boolean hayIdLookup = false;
for (Schema.SObjectField f : d.fields.getMap().values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (!fd.isCustom() && !fd.isIdLookup()) { continue; }
    System.debug(fd.getName()
        + ' | tipo=' + fd.getType()
        + ' | custom=' + fd.isCustom()
        + ' | externalId=' + fd.isExternalId()
        + ' | unico=' + fd.isUnique()
        + ' | idLookup=' + fd.isIdLookup());
    if (fd.isIdLookup() && fd.isCustom()) { hayIdLookup = true; }
}

System.debug('----- VEREDICTO -----');
if (hayIdLookup) {
    System.debug('SI se puede hacer upsert por campo custom. '
        + 'El campo con idLookup=true es la clave que MuleSoft debe usar.');
} else {
    System.debug('Todavia NO hay ningun campo custom con idLookup=true. '
        + 'Si ya se desplego PriceKey__c y sigue en false, la API no admite '
        + 'ese campo como clave de upsert y hay que ir por consulta previa '
        + 'mas insert o update separados.');
}

System.debug('----- CONTEXTO UTIL PARA EL EQUIPO DE INTEGRACION -----');
try {
    Pricebook2 estandar = [SELECT Id, Name, IsStandard, IsActive
                           FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    System.debug('Pricebook estandar: ' + estandar.Id + ' | ' + estandar.Name
        + ' | activo=' + estandar.IsActive);
} catch (Exception e) {
    System.debug('No se encontro el pricebook estandar: ' + e.getMessage());
}

for (Pricebook2 pb : [SELECT Id, Name, IsStandard, IsActive FROM Pricebook2 ORDER BY Name]) {
    System.debug('Pricebook: ' + pb.Name + ' | ' + pb.Id
        + ' | standard=' + pb.IsStandard + ' | activo=' + pb.IsActive);
}

System.debug('Entradas de precio existentes: ' + [SELECT COUNT() FROM PricebookEntry]);

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
