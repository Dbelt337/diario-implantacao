/**
 * Corrige el prefijo de cola copiado del vecino en Sociedad_Config__mdt.
 *
 *   G105 -> Default_Queue_Prefix__c = Leads_G101, deberia ser Leads_G105
 *   P103 -> Default_Queue_Prefix__c = Leads_P105, deberia ser Leads_P103
 *
 * Custom Metadata NO se modifica con DML normal: hay que desplegarlo con
 * Metadata.Operations.enqueueDeployment, que es asincrono. Por eso este script
 * lee el registro completo, copia TODOS sus campos personalizados actuales y
 * solo cambia el prefijo, para no perder ningun valor en el camino.
 *
 * Corre en modo simulacion. Para aplicar de verdad, cambiar EJECUTAR a true.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

// ==========  CAMBIAR A true PARA APLICAR  ==========
Boolean EJECUTAR = false;
// ===================================================

Organization org = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + org.Name + ' | ' + org.Id
    + ' | instancia=' + org.InstanceName + ' | sandbox=' + org.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR CAMBIOS' : 'SIMULACION, no escribe nada'));

Map<String, String> correcciones = new Map<String, String>{
    'G105' => 'Leads_G105',
    'P103' => 'Leads_P103'
};

// Todos los campos personalizados del tipo, para re-enviarlos intactos.
Schema.DescribeSObjectResult d =
    Schema.getGlobalDescribe().get('sociedad_config__mdt').getDescribe();
List<String> camposCustom = new List<String>();
for (Schema.SObjectField f : d.fields.getMap().values()) {
    String n = f.getDescribe().getName();
    if (n.endsWith('__c')) { camposCustom.add(n); }
}
camposCustom.sort();

// El bind de SOQL dinamico solo acepta una variable simple, no una llamada a
// metodo: :correcciones.keySet() no compila.
Set<String> nombres = correcciones.keySet();

List<SObject> registros = Database.query(
    'SELECT DeveloperName, MasterLabel, ' + String.join(camposCustom, ', ')
    + ' FROM Sociedad_Config__mdt WHERE DeveloperName IN :nombres');

System.debug('===================================================');
System.debug('LO QUE VA A CAMBIAR');
System.debug('===================================================');

Metadata.DeployContainer contenedor = new Metadata.DeployContainer();
Integer aCambiar = 0;

for (SObject r : registros) {
    String nombre = (String) r.get('DeveloperName');
    String actual = (String) r.get('Default_Queue_Prefix__c');
    String nuevo = correcciones.get(nombre);

    if (actual == nuevo) {
        System.debug('   ' + nombre + ' ya esta correcto (' + actual + '), se omite');
        continue;
    }
    aCambiar++;
    System.debug('   ' + nombre + ' | Default_Queue_Prefix__c');
    System.debug('        de : ' + actual);
    System.debug('        a  : ' + nuevo);

    Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
    cm.fullName = 'Sociedad_Config__mdt.' + nombre;
    cm.label = (String) r.get('MasterLabel');

    // Se reenvian TODOS los campos personalizados con su valor actual, y solo
    // el prefijo cambia. Asi ningun valor se pierde en el despliegue.
    for (String campo : camposCustom) {
        Object valor = campo == 'Default_Queue_Prefix__c' ? (Object) nuevo : r.get(campo);
        if (valor == null) { continue; }
        Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
        v.field = campo;
        v.value = valor;
        cm.values.add(v);
    }
    contenedor.addMetadata(cm);
}

if (aCambiar == 0) {
    System.debug('   Nada que cambiar.');
} else if (!EJECUTAR) {
    System.debug('---------------------------------------------------');
    System.debug('   SIMULACION. No se escribio nada.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true y volver a correr.');
} else {
    try {
        Id jobId = Metadata.Operations.enqueueDeployment(contenedor, null);
        System.debug('---------------------------------------------------');
        System.debug('   Despliegue encolado. Job: ' + jobId);
        System.debug('   Es ASINCRONO. Verificar en Setup, Deployment Status,');
        System.debug('   y despues volver a correr este script en simulacion');
        System.debug('   para confirmar que quedo en el valor nuevo.');
    } catch (Exception e) {
        System.debug('   ERROR en el despliegue: ' + e.getMessage());
        System.debug('   Si falla, son dos campos: se corrigen a mano en Setup,');
        System.debug('   Custom Metadata Types, Sociedad Config, Manage Records.');
    }
}

System.debug('===================================================');
System.debug('LO QUE ESTE SCRIPT NO TOCA, Y POR QUE');
System.debug('===================================================');
System.debug('   Las monedas GTQ, HNL y NIO que faltan en la org NO se activan');
System.debug('   aqui a proposito. Activarlas o decidir que los seis paises');
System.debug('   operan en USD es una decision de negocio, no un arreglo. Y');
System.debug('   una vez activada, una moneda no se puede eliminar.');
System.debug('   Se hace en Setup, Manage Currencies, con la tasa de cada una.');
System.debug('   Estado actual:');
try {
    for (CurrencyType c : [SELECT IsoCode, IsCorporate, IsActive, ConversionRate
                           FROM CurrencyType ORDER BY IsCorporate DESC, IsoCode]) {
        System.debug('        ' + c.IsoCode + (c.IsCorporate ? '  <<< CORPORATIVA' : '')
            + ' | activa=' + c.IsActive + ' | tasa=' + c.ConversionRate);
    }
} catch (Exception e) {
    System.debug('        ERROR: ' + e.getMessage());
}
System.debug('   Monedas que el Sociedad_Config__mdt necesita y no existen:');
Set<String> activas = new Set<String>();
for (CurrencyType c : [SELECT IsoCode FROM CurrencyType WHERE IsActive = true]) {
    activas.add(c.IsoCode);
}
Set<String> faltantes = new Set<String>();
for (Sociedad_Config__mdt s : [SELECT DeveloperName, Currency_Code__c
                               FROM Sociedad_Config__mdt]) {
    if (s.Currency_Code__c != null && !activas.contains(s.Currency_Code__c)) {
        faltantes.add(s.Currency_Code__c);
        System.debug('        ' + s.DeveloperName + ' pide ' + s.Currency_Code__c);
    }
}
System.debug('   Total de monedas faltantes: ' + faltantes.size() + ' ' + faltantes);
System.debug('   Mientras falten, el primer lead de esas sociedades falla.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
