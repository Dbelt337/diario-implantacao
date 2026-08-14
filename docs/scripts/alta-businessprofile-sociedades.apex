/**
 * Alta del BusinessProfile de nivel sociedad para C101 y C105.
 *
 * Lo que el describe ya confirmo:
 *   - el vinculo es BusinessProfile.AccountId, obligatorio, y NO existe
 *     ningun lookup desde Account hacia BusinessProfile;
 *   - BusinessPartnerType es una lista RESTRINGIDA y "Sociedad" NO es uno de
 *     sus valores, asi que no se puede escribir hasta darlo de alta en Setup;
 *   - existe ademas un campo custom BusinessType__c, que puede ser el lugar
 *     correcto para una clasificacion propia de Grupo Q.
 *
 * Por eso el script valida el valor ANTES de escribir. Si el valor elegido no
 * existe o no esta activo, lo dice y no intenta nada.
 *
 * Corre en modo simulacion. Para aplicar, cambiar EJECUTAR a true.
 */

// ==========  CONFIGURACION  ==========
Boolean EJECUTAR = false;

// Cual campo lleva la clasificacion. Dos opciones y la decision no es tecnica:
//   'BusinessPartnerType' -> estandar de Automotive, lista restringida.
//                            Exige dar de alta el valor nuevo en Setup.
//   'BusinessType__c'     -> campo propio, no ensucia el estandar.
String CAMPO = 'BusinessPartnerType';
String VALOR = 'Sociedad';

List<String> CUENTAS = new List<String>{ 'C101', 'C105' };
// =====================================

Organization org = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + org.Name + ' | sandbox=' + org.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, no escribe nada'));
System.debug('CAMPO: ' + CAMPO + ' | VALOR: ' + VALOR);

Schema.DescribeSObjectResult bp =
    Schema.getGlobalDescribe().get('businessprofile').getDescribe();

System.debug('===================================================');
System.debug('0. VALORES DISPONIBLES EN LOS DOS CAMPOS CANDIDATOS');
System.debug('===================================================');
for (String api : new List<String>{ 'BusinessPartnerType', 'BusinessType__c' }) {
    Schema.SObjectField f = bp.fields.getMap().get(api);
    if (f == null) { System.debug('   ' + api + ' no existe'); continue; }
    Schema.DescribeFieldResult fd = f.getDescribe();
    System.debug('   ' + api + ' | restringido=' + fd.isRestrictedPicklist());
    for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
        System.debug('        ' + pe.getValue() + ' | activo=' + pe.isActive());
    }
}

System.debug('===================================================');
System.debug('1. VALIDACION DEL VALOR ELEGIDO');
System.debug('===================================================');
Schema.SObjectField refCampo = bp.fields.getMap().get(CAMPO);
if (refCampo == null) {
    System.debug('   El campo ' + CAMPO + ' no existe. Nada que hacer.');
    return;
}
Boolean valorValido = false;
for (Schema.PicklistEntry pe : refCampo.getDescribe().getPicklistValues()) {
    if (pe.getValue() == VALOR && pe.isActive()) { valorValido = true; }
}
if (!valorValido) {
    System.debug('   "' + VALOR + '" NO es un valor activo de ' + CAMPO + '.');
    System.debug('   Apex no crea valores de lista de seleccion. Hay que darlo');
    System.debug('   de alta primero en Setup, Object Manager, Business Profile,');
    System.debug('   Fields, ' + CAMPO + ', New value. Despues volver a correr.');
    System.debug('   Alternativa sin tocar el estandar: usar BusinessType__c.');
    return;
}
System.debug('   Valor valido. Se puede escribir.');

System.debug('===================================================');
System.debug('2. CUENTAS Y PERFILES EXISTENTES');
System.debug('===================================================');
Map<Id, Account> mapaCuentas = new Map<Id, Account>([
    SELECT Id, Name, AccountNumber, Parent.Name
    FROM Account WHERE AccountNumber IN :CUENTAS
]);
for (Account a : mapaCuentas.values()) {
    System.debug('   ' + a.AccountNumber + ' | ' + a.Name + ' | ' + a.Id);
}
if (mapaCuentas.size() != CUENTAS.size()) {
    System.debug('   ATENCION: se esperaban ' + CUENTAS.size()
        + ' cuentas y se encontraron ' + mapaCuentas.size());
}

// Dos trampas de Apex en el mismo lugar: el bind de SOQL dinamico solo acepta
// variable simple, nunca una llamada a metodo; y los identificadores son
// insensibles a mayusculas, asi que CUENTAS y cuentas serian la misma.
Set<Id> idsCuentas = mapaCuentas.keySet();

Map<Id, SObject> perfilPorCuenta = new Map<Id, SObject>();
for (SObject p : Database.query(
        'SELECT Id, Name, AccountId, ' + CAMPO
        + ' FROM BusinessProfile WHERE AccountId IN :idsCuentas')) {
    perfilPorCuenta.put((Id) p.get('AccountId'), p);
}

System.debug('===================================================');
System.debug('3. LO QUE VA A PASAR');
System.debug('===================================================');
List<SObject> aInsertar = new List<SObject>();
List<SObject> aActualizar = new List<SObject>();

for (Account a : mapaCuentas.values()) {
    SObject existente = perfilPorCuenta.get(a.Id);
    if (existente == null) {
        SObject nuevo = Schema.getGlobalDescribe().get('BusinessProfile').newSObject();
        nuevo.put('AccountId', a.Id);
        nuevo.put(CAMPO, VALOR);
        aInsertar.add(nuevo);
        System.debug('   CREAR  perfil para ' + a.AccountNumber
            + ' con ' + CAMPO + ' = ' + VALOR);
    } else if (String.valueOf(existente.get(CAMPO)) != VALOR) {
        // Leer el valor viejo ANTES de sobreescribirlo, si no el log muestra
        // el nuevo en los dos lados.
        String anterior = String.valueOf(existente.get(CAMPO));
        existente.put(CAMPO, VALOR);
        aActualizar.add(existente);
        System.debug('   ACTUALIZAR perfil ' + existente.get('Name')
            + ' de ' + a.AccountNumber
            + ': ' + CAMPO + ' de "' + anterior + '" a "' + VALOR + '"');
    } else {
        System.debug('   OK     ' + a.AccountNumber + ' ya esta correcto');
    }
}

if (!EJECUTAR) {
    System.debug('   SIMULACION. No se escribio nada.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true.');
} else {
    if (!aInsertar.isEmpty()) {
        insert aInsertar;
        System.debug('   Insertados: ' + aInsertar.size());
    }
    if (!aActualizar.isEmpty()) {
        update aActualizar;
        System.debug('   Actualizados: ' + aActualizar.size());
    }
    if (aInsertar.isEmpty() && aActualizar.isEmpty()) {
        System.debug('   Nada que hacer.');
    }
}

System.debug('===================================================');
System.debug('4. DEUDA QUE ESTE SCRIPT NO ARREGLA');
System.debug('===================================================');
System.debug('   Hay perfiles con BusinessPartnerType = "Sales Dealer", que ya');
System.debug('   NO figura entre los valores de la lista, y otros en null.');
System.debug('   Son datos huerfanos de cuando la lista estaba en ingles.');
System.debug('   Estado actual:');
try {
    for (AggregateResult ar : [SELECT BusinessPartnerType t, COUNT(Id) q
                               FROM BusinessProfile
                               GROUP BY BusinessPartnerType]) {
        System.debug('        ' + ar.get('t') + ' | ' + ar.get('q'));
    }
} catch (Exception e) {
    System.debug('        ERROR: ' + e.getMessage());
}
System.debug('   Se corrigen con Replace en Setup sobre la lista, no aqui.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
