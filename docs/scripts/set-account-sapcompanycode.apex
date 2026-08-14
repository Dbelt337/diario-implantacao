/**
 * Llena SapCompanyCode__c en las cuentas de nivel sociedad.
 *
 * Es la clave por la que MuleSoft localiza la cuenta de la sociedad. Se toma
 * de Sociedad_Config__mdt, que ya tiene las 14 sociedades con su
 * SAP_Company_Code__c, y se cruza contra Account.AccountNumber.
 *
 * TODO el acceso al campo es DINAMICO a proposito. El SOQL estatico compila
 * antes de que corra la primera linea, asi que una guarda del tipo "si el
 * campo no existe, salir" no sirve de nada: el script ni siquiera llega a
 * ejecutarse. Con Database.query y get/put el script corre igual y avisa.
 *
 * Correr DESPUES de desplegar deploy-account-sapcompanycode.zip.
 *
 * Corre en modo simulacion. Para aplicar, cambiar EJECUTAR a true.
 */

// ==========  CAMBIAR A true PARA APLICAR  ==========
Boolean EJECUTAR = false;
// ===================================================

String CLAVE = 'SapCompanyCode__c';

Organization laOrg = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | sandbox=' + laOrg.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, no escribe nada'));

Boolean hayCampo = Schema.getGlobalDescribe().get('account').getDescribe()
    .fields.getMap().containsKey(CLAVE.toLowerCase());
System.debug('CAMPO ' + CLAVE + ': ' + (hayCampo ? 'existe' : 'TODAVIA NO EXISTE'));
if (!hayCampo) {
    System.debug('   Desplegar primero deploy-account-sapcompanycode.zip.');
    System.debug('   El resto del diagnostico corre igual, sin escribir.');
}

System.debug('===================================================');
System.debug('1. SOCIEDADES SEGUN LA CONFIGURACION');
System.debug('===================================================');
Map<String, String> paisPorCodigo = new Map<String, String>();
for (Sociedad_Config__mdt s : [SELECT DeveloperName, SAP_Company_Code__c, Country_Name__c
                               FROM Sociedad_Config__mdt ORDER BY DeveloperName]) {
    paisPorCodigo.put(s.SAP_Company_Code__c, s.Country_Name__c);
}
System.debug('   Configuradas: ' + paisPorCodigo.size() + ' ' + paisPorCodigo.keySet());

System.debug('===================================================');
System.debug('2. CUENTAS DE NIVEL SOCIEDAD SEGUN LA JERARQUIA');
System.debug('===================================================');
System.debug('   Nivel sociedad = nieta de la cuenta raiz, sin importar si');
System.debug('   tiene codigo. Asi aparece N105, que hoy esta sin AccountNumber.');

String campos = 'Id, Name, AccountNumber, Parent.Name'
    + (hayCampo ? ', ' + CLAVE : '');

List<SObject> nivelSociedad = Database.query(
    'SELECT ' + campos + ' FROM Account '
    + 'WHERE ParentId != null AND Parent.ParentId != null '
    + 'AND Parent.Parent.ParentId = null '
    + 'ORDER BY Parent.Name, Name');

List<SObject> aTocar = new List<SObject>();
Set<String> conCuenta = new Set<String>();
Integer sinCodigo = 0;

for (SObject a : nivelSociedad) {
    String num = (String) a.get('AccountNumber');
    String nombre = (String) a.get('Name');
    if (String.isBlank(num)) {
        sinCodigo++;
        System.debug('   SIN CODIGO  ' + nombre + ' | Id=' + a.get('Id'));
        System.debug('        Llenar AccountNumber primero, si no el Mule no la ubica.');
        continue;
    }
    conCuenta.add(num);
    if (!paisPorCodigo.containsKey(num)) {
        System.debug('   HUERFANA    ' + num + ' | ' + nombre
            + ' | no esta en Sociedad_Config__mdt');
        continue;
    }
    String actual = hayCampo ? (String) a.get(CLAVE) : null;
    if (actual == num) {
        System.debug('   OK          ' + num + ' | ' + nombre);
    } else {
        System.debug('   LLENAR      ' + num + ' | ' + nombre
            + ' | de "' + actual + '" a "' + num + '"');
        if (hayCampo) {
            a.put(CLAVE, num);
            aTocar.add(a);
        }
    }
}
System.debug('   Cuentas de nivel sociedad: ' + nivelSociedad.size()
    + ', de las cuales ' + sinCodigo + ' sin codigo');

System.debug('===================================================');
System.debug('3. SOCIEDADES CONFIGURADAS SIN CUENTA');
System.debug('===================================================');
List<String> faltan = new List<String>();
for (String c : paisPorCodigo.keySet()) {
    if (!conCuenta.contains(c)) { faltan.add(c + ' (' + paisPorCodigo.get(c) + ')'); }
}
faltan.sort();
for (String f : faltan) { System.debug('   FALTA  ' + f); }
System.debug('   Faltan ' + faltan.size() + ' de ' + paisPorCodigo.size());
System.debug('   Sin cuenta, no hay nada que el Mule pueda localizar. Esto es');
System.debug('   mas grande que el campo clave.');

System.debug('===================================================');
System.debug('4. RESULTADO');
System.debug('===================================================');
if (!hayCampo) {
    System.debug('   El campo no existe todavia, no se escribio nada.');
} else if (aTocar.isEmpty()) {
    System.debug('   Nada que escribir.');
} else if (!EJECUTAR) {
    System.debug('   SIMULACION. ' + aTocar.size() + ' cuentas quedarian llenas.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true.');
} else {
    List<Database.SaveResult> res = Database.update(aTocar, false);
    Integer ok = 0;
    for (Integer i = 0; i < res.size(); i++) {
        if (res[i].isSuccess()) { ok++; continue; }
        System.debug('   FALLO ' + aTocar[i].get('AccountNumber') + ': '
            + res[i].getErrors()[0].getMessage());
    }
    System.debug('   Actualizadas ' + ok + ' de ' + aTocar.size());
}

System.debug('===================================================');
System.debug('5. COMO LO USA MULESOFT DESPUES DE ESTO');
System.debug('===================================================');
System.debug('        GET   /services/data/vXX.X/sobjects/Account/' + CLAVE + '/C101');
System.debug('        PATCH /services/data/vXX.X/sobjects/Account/' + CLAVE + '/C101');
System.debug('   Sin consulta previa, sin depender del nombre y sin recorrer');
System.debug('   la jerarquia. Y el nombre importa: hay una cuenta con dos');
System.debug('   espacios seguidos, asi que el cruce por nombre no es opcion.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
