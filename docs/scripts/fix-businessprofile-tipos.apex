/**
 * Deja BusinessPartnerType consistente en una sola pasada.
 *
 * Hace tres cosas:
 *   1. Muestra como esta hoy, contando perfiles por tipo;
 *   2. Detecta perfiles con un valor que NO esta en la lista activa, que es lo
 *      que queda si el valor viejo se borro con Del en vez de con Replace, y
 *      los pasa a "Concesionario de ventas";
 *   3. Crea o corrige el BusinessProfile de las cuentas de nivel sociedad con
 *      "GroupCompany".
 *
 * Las cuentas de sociedad se eligen por POSICION EN LA JERARQUIA, nietas de la
 * cuenta raiz, no por AccountNumber, porque GrupoQ Nicaragua N105 no tiene
 * codigo y con un cruce por codigo quedaba afuera.
 *
 * Corre en modo simulacion. Para aplicar, cambiar EJECUTAR a true.
 */

// ==========  CAMBIAR A true PARA APLICAR  ==========
Boolean EJECUTAR = false;
// ===================================================

String CAMPO         = 'BusinessPartnerType';
String VALOR_DEALER   = 'Concesionario de ventas';
String VALOR_SOCIEDAD = 'GroupCompany';

Organization laOrg = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | sandbox=' + laOrg.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, no escribe nada'));

Schema.DescribeSObjectResult bp =
    Schema.getGlobalDescribe().get('businessprofile').getDescribe();
Schema.SObjectField refCampo = bp.fields.getMap().get(CAMPO);

Set<String> activos = new Set<String>();
for (Schema.PicklistEntry pe : refCampo.getDescribe().getPicklistValues()) {
    if (pe.isActive()) { activos.add(pe.getValue()); }
}
System.debug('===================================================');
System.debug('0. VALORES ACTIVOS DE LA LISTA');
System.debug('===================================================');
System.debug('   ' + activos);
if (!activos.contains(VALOR_SOCIEDAD)) {
    System.debug('   FALTA "' + VALOR_SOCIEDAD + '". Crearlo en Setup y volver.');
    return;
}
if (!activos.contains(VALOR_DEALER)) {
    System.debug('   FALTA "' + VALOR_DEALER + '". Revisar el nombre exacto.');
    return;
}

System.debug('===================================================');
System.debug('1. COMO ESTA HOY');
System.debug('===================================================');
for (AggregateResult ar : [SELECT BusinessPartnerType t, COUNT(Id) q
                           FROM BusinessProfile GROUP BY BusinessPartnerType]) {
    String t = String.valueOf(ar.get('t'));
    Boolean valido = t == null || activos.contains(t);
    System.debug('   ' + (valido ? '      ' : 'HUERFANO ') + t + ' | ' + ar.get('q'));
}
System.debug('   HUERFANO significa que el valor no esta en la lista activa.');
System.debug('   Si aparece "Sales Dealer", el Replace no se hizo y se uso Del.');

// Cuentas de nivel sociedad
Map<Id, Account> sociedades = new Map<Id, Account>([
    SELECT Id, Name, AccountNumber, Parent.Name
    FROM Account
    WHERE ParentId != null AND Parent.ParentId != null
      AND Parent.Parent.ParentId = null
    ORDER BY Parent.Name, Name
]);
Set<Id> idsSociedades = sociedades.keySet();

System.debug('===================================================');
System.debug('2. CUENTAS DE NIVEL SOCIEDAD');
System.debug('===================================================');
for (Account a : sociedades.values()) {
    System.debug('   ' + (String.isBlank(a.AccountNumber) ? '(sin codigo)' : a.AccountNumber)
        + ' | ' + a.Name + ' | pais=' + a.Parent.Name);
}
System.debug('   Total: ' + sociedades.size());

// Todos los perfiles, para separar huerfanos de los de sociedad
List<SObject> perfiles = Database.query(
    'SELECT Id, Name, AccountId, Account.Name, ' + CAMPO + ' FROM BusinessProfile LIMIT 2000');

Map<Id, SObject> perfilPorSociedad = new Map<Id, SObject>();
List<SObject> aArreglar = new List<SObject>();

System.debug('===================================================');
System.debug('3. LO QUE VA A CAMBIAR');
System.debug('===================================================');

for (SObject p : perfiles) {
    Id acc = (Id) p.get('AccountId');
    String tipo = String.valueOf(p.get(CAMPO));

    if (idsSociedades.contains(acc)) {
        perfilPorSociedad.put(acc, p);
        if (tipo != VALOR_SOCIEDAD) {
            System.debug('   SOCIEDAD  ' + p.get('Name') + ' | ' + p.getSObject('Account').get('Name')
                + ' | de "' + tipo + '" a "' + VALOR_SOCIEDAD + '"');
            p.put(CAMPO, VALOR_SOCIEDAD);
            aArreglar.add(p);
        }
        continue;
    }
    if (tipo != null && !activos.contains(tipo)) {
        System.debug('   HUERFANO  ' + p.get('Name') + ' | ' + p.getSObject('Account').get('Name')
            + ' | de "' + tipo + '" a "' + VALOR_DEALER + '"');
        p.put(CAMPO, VALOR_DEALER);
        aArreglar.add(p);
    }
}

List<SObject> aCrear = new List<SObject>();
for (Account a : sociedades.values()) {
    if (perfilPorSociedad.containsKey(a.Id)) { continue; }
    SObject nuevo = Schema.getGlobalDescribe().get('BusinessProfile').newSObject();
    nuevo.put('AccountId', a.Id);
    nuevo.put(CAMPO, VALOR_SOCIEDAD);
    aCrear.add(nuevo);
    System.debug('   CREAR     perfil para ' + a.Name + ' con ' + VALOR_SOCIEDAD);
}

if (aArreglar.isEmpty() && aCrear.isEmpty()) {
    System.debug('   Nada que cambiar, ya esta todo consistente.');
}

System.debug('===================================================');
System.debug('4. RESULTADO');
System.debug('===================================================');
if (!EJECUTAR) {
    System.debug('   SIMULACION. Crear ' + aCrear.size()
        + ', corregir ' + aArreglar.size() + '. No se escribio nada.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true arriba y correr de nuevo.');
} else {
    if (!aCrear.isEmpty()) {
        List<Database.SaveResult> r = Database.insert(aCrear, false);
        Integer ok = 0;
        for (Integer i = 0; i < r.size(); i++) {
            if (r[i].isSuccess()) { ok++; }
            else { System.debug('   FALLO insert: ' + r[i].getErrors()[0].getMessage()); }
        }
        System.debug('   Creados ' + ok + ' de ' + aCrear.size());
    }
    if (!aArreglar.isEmpty()) {
        List<Database.SaveResult> r = Database.update(aArreglar, false);
        Integer ok = 0;
        for (Integer i = 0; i < r.size(); i++) {
            if (r[i].isSuccess()) { ok++; }
            else { System.debug('   FALLO update: ' + r[i].getErrors()[0].getMessage()); }
        }
        System.debug('   Corregidos ' + ok + ' de ' + aArreglar.size());
    }
    System.debug('   Correr una vez mas en simulacion para confirmar.');
}

System.debug('===================================================');
System.debug('5. COMO QUEDO');
System.debug('===================================================');
for (AggregateResult ar : [SELECT BusinessPartnerType t, COUNT(Id) q
                           FROM BusinessProfile GROUP BY BusinessPartnerType]) {
    System.debug('   ' + ar.get('t') + ' | ' + ar.get('q'));
}
System.debug('   Esperado al final: Concesionario de ventas con los dealers,');
System.debug('   GroupCompany con las cuentas de sociedad, y ningun huerfano.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
