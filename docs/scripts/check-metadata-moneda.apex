/**
 * Que Custom Metadata de moneda existe ya en la org.
 *
 * Antes de aceptar un CountryCurrency__mdt nuevo hay que ver que ya tiene el
 * Sociedad_Config__mdt, que existe y que el flow Lead_BS_DeriveSociedad ya usa
 * para asignar CurrencyIsoCode. Si los dos describen moneda, son dos fuentes
 * para un mismo significado, que es justo lo que la decision de gobernanza
 * del 14/08 prohibe.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

Organization org = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + org.Name + ' | ' + org.Id
    + ' | instancia=' + org.InstanceName + ' | sandbox=' + org.IsSandbox);

System.debug('===================================================');
System.debug('CUSTOM METADATA RELACIONADO A MONEDA');
System.debug('===================================================');

Map<String, Schema.SObjectType> global = Schema.getGlobalDescribe();

System.debug('----- 1. TODOS LOS TIPOS __mdt DE LA ORG -----');
List<String> tipos = new List<String>();
for (String api : global.keySet()) {
    if (api.endsWith('__mdt')) { tipos.add(api); }
}
tipos.sort();
for (String api : tipos) {
    System.debug('   ' + global.get(api).getDescribe().getName());
}
System.debug('   Total: ' + tipos.size());

System.debug('----- 2. CAMPOS DE CADA UNO QUE SUENE A MONEDA O PAIS -----');
for (String api : tipos) {
    Schema.DescribeSObjectResult d = global.get(api).getDescribe();
    List<String> interesantes = new List<String>();
    for (Schema.SObjectField f : d.fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        String n = fd.getName().toLowerCase();
        if (n.contains('curren') || n.contains('moneda') || n.contains('moeda')
            || n.contains('country') || n.contains('pais') || n.contains('iso')
            || n.contains('sociedad') || n.contains('company')) {
            interesantes.add(fd.getName() + ' (' + fd.getType() + ')');
        }
    }
    if (!interesantes.isEmpty()) {
        System.debug('   ' + d.getName());
        for (String s : interesantes) { System.debug('        ' + s); }
    }
}

System.debug('----- 3. CONTENIDO DE Sociedad_Config__mdt -----');
System.debug('   Es el que el flow Lead_BS_DeriveSociedad ya usa.');
try {
    Schema.DescribeSObjectResult d = global.get('sociedad_config__mdt').getDescribe();
    List<String> campos = new List<String>();
    for (Schema.SObjectField f : d.fields.getMap().values()) {
        campos.add(f.getDescribe().getName());
    }
    campos.sort();
    System.debug('   Campos: ' + campos);

    List<SObject> filas = Database.query(
        'SELECT ' + String.join(campos, ', ') + ' FROM Sociedad_Config__mdt '
        + 'ORDER BY DeveloperName LIMIT 50');
    System.debug('   Registros: ' + filas.size());
    for (SObject s : filas) { System.debug('   ' + s); }
} catch (Exception e) {
    System.debug('   No existe o no es consultable => ' + e.getMessage());
}

System.debug('----- 4. EXISTE YA UN CountryCurrency__mdt -----');
System.debug('   ' + (global.containsKey('countrycurrency__mdt')
    ? 'SI existe. Ver si duplica lo de arriba.'
    : 'NO existe en esta org.'));

System.debug('----- 5. MONEDAS ACTIVAS DE LA ORG -----');
try {
    for (CurrencyType c : [SELECT IsoCode, IsCorporate, IsActive, ConversionRate
                           FROM CurrencyType ORDER BY IsCorporate DESC, IsoCode]) {
        System.debug('   ' + c.IsoCode + (c.IsCorporate ? '  <<< CORPORATIVA' : '')
            + ' | activa=' + c.IsActive + ' | tasa=' + c.ConversionRate);
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('----- 6. QUE MONEDA USA HOY CADA SOCIEDAD EN LOS DATOS -----');
System.debug('   Lo que esta cargado manda mas que lo que dice la regla.');
for (String obj : new List<String>{ 'Opportunity', 'Lead', 'Quote' }) {
    try {
        for (AggregateResult ar : Database.query(
                'SELECT CurrencyIsoCode m, COUNT(Id) q FROM ' + obj
                + ' GROUP BY CurrencyIsoCode ORDER BY CurrencyIsoCode')) {
            System.debug('   ' + obj + ' | ' + ar.get('m') + ' | ' + ar.get('q'));
        }
    } catch (Exception e) {
        System.debug('   ' + obj + ' => ' + e.getMessage());
    }
}

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
