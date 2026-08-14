/**
 * Que hace falta para marcar las cuentas de sociedad con BusinessProfile.
 *
 * La jerarquia es holding -> pais -> sociedad -> dealer, y hoy el
 * BusinessProfile existe por dealer con BusinessPartnerType = Sales Dealer.
 * Falta el nivel de sociedad, empezando por C101 y C105.
 *
 * Tres cosas no se pueden adivinar y este script las responde:
 *   a) de que lado vive el vinculo, si BusinessProfile apunta a Account o al
 *      reves. Se detecta recorriendo los campos de referencia de los dos;
 *   b) si "Sociedad" ya es un valor valido de BusinessPartnerType, o si hay
 *      que darlo de alta en la lista de seleccion antes de poder escribirlo;
 *   c) que campos son obligatorios para crear el registro.
 *
 * No escribe nada. Es solo lectura.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

Organization org = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + org.Name + ' | ' + org.Id
    + ' | instancia=' + org.InstanceName + ' | sandbox=' + org.IsSandbox);

System.debug('===================================================');
System.debug('BusinessProfile PARA EL NIVEL DE SOCIEDAD');
System.debug('===================================================');

Map<String, Schema.SObjectType> esquema = Schema.getGlobalDescribe();

if (!esquema.containsKey('businessprofile')) {
    System.debug('   BusinessProfile NO existe en esta org. Verificar Setup.');
    return;
}

System.debug('----- 1. EL VINCULO, DE QUE LADO ESTA -----');
Schema.DescribeSObjectResult bp = esquema.get('businessprofile').getDescribe();
System.debug('   BusinessProfile: creable=' + bp.isCreateable()
    + ' | actualizable=' + bp.isUpdateable());

System.debug('   Referencias DESDE BusinessProfile:');
for (Schema.SObjectField f : bp.fields.getMap().values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (fd.getType() == Schema.DisplayType.REFERENCE) {
        List<String> destinos = new List<String>();
        for (Schema.SObjectType t : fd.getReferenceTo()) {
            destinos.add(t.getDescribe().getName());
        }
        System.debug('        ' + fd.getName() + ' -> ' + destinos
            + ' | obligatorio=' + (!fd.isNillable() && fd.isCreateable()));
    }
}

System.debug('   Referencias DESDE Account hacia BusinessProfile:');
Schema.DescribeSObjectResult ac = esquema.get('account').getDescribe();
for (Schema.SObjectField f : ac.fields.getMap().values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (fd.getType() != Schema.DisplayType.REFERENCE) { continue; }
    for (Schema.SObjectType t : fd.getReferenceTo()) {
        if (t.getDescribe().getName() == 'BusinessProfile') {
            System.debug('        Account.' + fd.getName()
                + ' | actualizable=' + fd.isUpdateable());
        }
    }
}

System.debug('----- 2. CAMPOS DE BusinessProfile -----');
System.debug('   Los marcados OBLIGATORIO hay que llenarlos al crear.');
for (Schema.SObjectField f : bp.fields.getMap().values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (!fd.isCreateable()) { continue; }
    Boolean obligatorio = !fd.isNillable() && !fd.isDefaultedOnCreate();
    System.debug('   ' + (obligatorio ? 'OBLIGATORIO ' : '            ')
        + fd.getName() + ' | ' + fd.getType()
        + (fd.isCustom() ? ' | custom' : ''));
}

System.debug('----- 3. VALORES DE BusinessPartnerType -----');
System.debug('   Si "Sociedad" no aparece, hay que darlo de alta en la lista');
System.debug('   de seleccion ANTES de poder escribirlo. Eso es Setup, no Apex.');
Schema.SObjectField campoTipo = bp.fields.getMap().get('BusinessPartnerType');
if (campoTipo == null) {
    System.debug('   El campo BusinessPartnerType no existe con ese nombre.');
    System.debug('   Buscar arriba en la lista de campos cual es el correcto.');
} else {
    Schema.DescribeFieldResult fd = campoTipo.getDescribe();
    System.debug('   tipo=' + fd.getType() + ' | restringido=' + fd.isRestrictedPicklist());
    for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
        System.debug('        ' + pe.getValue() + ' | activo=' + pe.isActive()
            + ' | etiqueta=' + pe.getLabel());
    }
}

System.debug('----- 4. BusinessProfile QUE YA EXISTEN -----');
try {
    List<SObject> perfiles = Database.query(
        'SELECT Id, Name, BusinessPartnerType FROM BusinessProfile '
        + 'ORDER BY BusinessPartnerType, Name LIMIT 200');
    System.debug('   Total: ' + perfiles.size());
    Map<String, Integer> porTipo = new Map<String, Integer>();
    for (SObject p : perfiles) {
        String t = String.valueOf(p.get('BusinessPartnerType'));
        porTipo.put(t, porTipo.containsKey(t) ? porTipo.get(t) + 1 : 1);
        System.debug('        ' + t + ' | ' + p.get('Name'));
    }
    System.debug('   Resumen por tipo: ' + porTipo);
} catch (Exception e) {
    System.debug('   ERROR consultando BusinessProfile: ' + e.getMessage());
}

System.debug('----- 5. LA JERARQUIA DE CUENTAS -----');
System.debug('   Para ver que nivel es cada una y cuales son las sociedades.');
try {
    List<String> campos = new List<String>{
        'Id', 'Name', 'AccountNumber', 'Parent.Name', 'Parent.Parent.Name'
    };
    if (ac.fields.getMap().containsKey('AccountLevel__c')) {
        campos.add('AccountLevel__c');
        System.debug('   AccountLevel__c existe y se incluye.');
    }
    for (Schema.SObjectField f : ac.fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        for (Schema.SObjectType t : fd.getReferenceTo()) {
            if (t.getDescribe().getName() == 'BusinessProfile') {
                campos.add(fd.getName());
            }
        }
    }
    for (SObject a : Database.query(
            'SELECT ' + String.join(campos, ', ') + ' FROM Account '
            + 'ORDER BY Parent.Parent.Name NULLS FIRST, Parent.Name NULLS FIRST, Name '
            + 'LIMIT 200')) {
        System.debug('   ' + a);
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('----- 6. LAS DOS CUENTAS OBJETIVO -----');
try {
    for (Account a : [SELECT Id, Name, AccountNumber, Parent.Name
                      FROM Account WHERE AccountNumber IN ('C101', 'C105')]) {
        System.debug('   ' + a.AccountNumber + ' | ' + a.Name
            + ' | padre=' + a.Parent.Name + ' | Id=' + a.Id);
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('CON ESTE LOG SE ESCRIBE EL SCRIPT DE ALTA');
System.debug('   Falta saber: el nombre del campo de vinculo, si Sociedad ya');
System.debug('   es valor valido, y que campos son obligatorios. Los tres');
System.debug('   estan arriba.');
System.debug('===================================================');
