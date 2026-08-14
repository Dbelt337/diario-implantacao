/**
 * Llena SapCompanyCode__c en las cuentas de nivel sociedad.
 *
 * Es la clave por la que MuleSoft localiza la cuenta de la sociedad. Se toma
 * de Sociedad_Config__mdt, que ya tiene las 14 sociedades con su
 * SAP_Company_Code__c, y se cruza contra Account.AccountNumber, que hoy ya
 * lleva C101 y C105.
 *
 * Correr DESPUES de desplegar deploy-account-sapcompanycode.zip.
 *
 * Corre en modo simulacion. Para aplicar, cambiar EJECUTAR a true.
 */

// ==========  CAMBIAR A true PARA APLICAR  ==========
Boolean EJECUTAR = false;
// ===================================================

Organization laOrg = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | sandbox=' + laOrg.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, no escribe nada'));

if (!Schema.getGlobalDescribe().get('account').getDescribe()
        .fields.getMap().containsKey('sapcompanycode__c')) {
    System.debug('   SapCompanyCode__c no existe todavia.');
    System.debug('   Desplegar primero deploy-account-sapcompanycode.zip.');
    return;
}

System.debug('===================================================');
System.debug('1. SOCIEDADES SEGUN LA CONFIGURACION');
System.debug('===================================================');
Map<String, String> codigoPorSociedad = new Map<String, String>();
for (Sociedad_Config__mdt s : [SELECT DeveloperName, SAP_Company_Code__c, Country_Name__c
                               FROM Sociedad_Config__mdt ORDER BY DeveloperName]) {
    codigoPorSociedad.put(s.SAP_Company_Code__c, s.Country_Name__c);
    System.debug('   ' + s.SAP_Company_Code__c + ' | ' + s.Country_Name__c);
}
System.debug('   Total configuradas: ' + codigoPorSociedad.size());

System.debug('===================================================');
System.debug('2. CUENTAS QUE COINCIDEN POR AccountNumber');
System.debug('===================================================');
Set<String> codigos = codigoPorSociedad.keySet();
List<Account> aTocar = new List<Account>();
Set<String> encontrados = new Set<String>();

for (Account a : [SELECT Id, Name, AccountNumber, SapCompanyCode__c, Parent.Name
                  FROM Account WHERE AccountNumber IN :codigos
                  ORDER BY AccountNumber]) {
    encontrados.add(a.AccountNumber);
    if (a.SapCompanyCode__c == a.AccountNumber) {
        System.debug('   OK     ' + a.AccountNumber + ' | ' + a.Name + ' | ya esta');
        continue;
    }
    System.debug('   LLENAR ' + a.AccountNumber + ' | ' + a.Name
        + ' | padre=' + a.Parent.Name
        + ' | de "' + a.SapCompanyCode__c + '" a "' + a.AccountNumber + '"');
    a.SapCompanyCode__c = a.AccountNumber;
    aTocar.add(a);
}

System.debug('===================================================');
System.debug('3. SOCIEDADES CONFIGURADAS SIN CUENTA');
System.debug('===================================================');
System.debug('   MuleSoft no va a poder resolver estas hasta que exista la');
System.debug('   cuenta. No es un error del campo, es jerarquia incompleta.');
List<String> sinCuenta = new List<String>();
for (String c : codigos) {
    if (!encontrados.contains(c)) { sinCuenta.add(c); }
}
sinCuenta.sort();
System.debug('   ' + sinCuenta);
System.debug('   Faltan ' + sinCuenta.size() + ' de ' + codigos.size());

System.debug('===================================================');
System.debug('4. RESULTADO');
System.debug('===================================================');
if (aTocar.isEmpty()) {
    System.debug('   Nada que escribir.');
} else if (!EJECUTAR) {
    System.debug('   SIMULACION. ' + aTocar.size() + ' cuentas quedarian llenas.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true.');
} else {
    List<Database.SaveResult> res = Database.update(aTocar, false);
    Integer ok = 0;
    for (Integer i = 0; i < res.size(); i++) {
        if (res[i].isSuccess()) { ok++; continue; }
        System.debug('   FALLO ' + aTocar[i].AccountNumber + ': '
            + res[i].getErrors()[0].getMessage());
    }
    System.debug('   Actualizadas ' + ok + ' de ' + aTocar.size());
    System.debug('   Volver a correr en simulacion para confirmar.');
}

System.debug('===================================================');
System.debug('5. COMO LO USA MULESOFT DESPUES DE ESTO');
System.debug('===================================================');
System.debug('   Lectura directa por la clave, sin consulta previa:');
System.debug('        GET  /services/data/vXX.X/sobjects/Account/SapCompanyCode__c/C101');
System.debug('   Y upsert por la misma clave, idempotente:');
System.debug('        PATCH /services/data/vXX.X/sobjects/Account/SapCompanyCode__c/C101');
System.debug('   Sin depender del nombre de la cuenta ni de recorrer la jerarquia.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
