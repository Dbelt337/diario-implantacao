/**
 * Alta del BusinessProfile de nivel sociedad.
 *
 * Decidido el 14/08: se crea un valor propio en BusinessPartnerType para las
 * cuentas de sociedad, y los cuatro perfiles huerfanos con "Sales Dealer" se
 * corrigen con Replace hacia "Concesionario de ventas". El Replace es en
 * Setup y no lo hace este script.
 *
 * ANTES DE CORRER:
 *   1. Setup, Object Manager, Business Profile, Fields, Business Partner Type,
 *      boton Replace: Sales Dealer  ->  Concesionario de ventas;
 *   2. Mismo lugar, boton New: crear el valor para sociedad. Ver VALOR abajo;
 *   3. Recien entonces correr esto, primero en simulacion.
 *
 * Las cuentas se eligen por POSICION EN LA JERARQUIA, nietas de la cuenta
 * raiz, y no por AccountNumber. GrupoQ Nicaragua N105 no tiene codigo y con un
 * cruce por codigo quedaba afuera.
 */

// ==========  CONFIGURACION  ==========
Boolean EJECUTAR = false;

String CAMPO = 'BusinessPartnerType';

// Este valor tiene que existir y estar activo en la lista, si no el script
// para en el paso 2 y no escribe nada.
String VALOR = 'GroupCompany';
// =====================================

Organization laOrg = [SELECT Id, Name, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | sandbox=' + laOrg.IsSandbox);
System.debug('MODO: ' + (EJECUTAR ? 'APLICAR' : 'SIMULACION, no escribe nada'));
System.debug('CAMPO: ' + CAMPO + ' | VALOR: ' + VALOR);

Schema.DescribeSObjectResult bp =
    Schema.getGlobalDescribe().get('businessprofile').getDescribe();

System.debug('===================================================');
System.debug('1. VALORES ACTIVOS DE ' + CAMPO);
System.debug('===================================================');
Schema.SObjectField refCampo = bp.fields.getMap().get(CAMPO);
Boolean valorValido = false;
for (Schema.PicklistEntry pe : refCampo.getDescribe().getPicklistValues()) {
    System.debug('   ' + pe.getValue() + ' | activo=' + pe.isActive());
    if (pe.getValue() == VALOR && pe.isActive()) { valorValido = true; }
}

System.debug('===================================================');
System.debug('2. VALIDACION');
System.debug('===================================================');
if (!valorValido) {
    System.debug('   "' + VALOR + '" no existe o no esta activo.');
    System.debug('   Crearlo en Setup, Object Manager, Business Profile,');
    System.debug('   Fields, ' + CAMPO + ', New. Despues volver a correr.');
    return;
}
System.debug('   Valor valido, se puede escribir.');

System.debug('===================================================');
System.debug('3. CUENTAS DE NIVEL SOCIEDAD');
System.debug('===================================================');
System.debug('   Nietas de la cuenta raiz. Incluye las que no tienen codigo.');
Map<Id, Account> sociedades = new Map<Id, Account>([
    SELECT Id, Name, AccountNumber, Parent.Name
    FROM Account
    WHERE ParentId != null AND Parent.ParentId != null
      AND Parent.Parent.ParentId = null
    ORDER BY Parent.Name, Name
]);
for (Account a : sociedades.values()) {
    System.debug('   ' + (String.isBlank(a.AccountNumber) ? '(sin codigo)' : a.AccountNumber)
        + ' | ' + a.Name + ' | pais=' + a.Parent.Name);
}
System.debug('   Total: ' + sociedades.size());
if (sociedades.isEmpty()) { return; }

Set<Id> idsSociedades = sociedades.keySet();
Map<Id, SObject> perfilPorCuenta = new Map<Id, SObject>();
for (SObject p : Database.query(
        'SELECT Id, Name, AccountId, ' + CAMPO
        + ' FROM BusinessProfile WHERE AccountId IN :idsSociedades')) {
    perfilPorCuenta.put((Id) p.get('AccountId'), p);
}

System.debug('===================================================');
System.debug('4. LO QUE VA A PASAR');
System.debug('===================================================');
List<SObject> aInsertar = new List<SObject>();
List<SObject> aActualizar = new List<SObject>();

for (Account a : sociedades.values()) {
    String etiqueta = (String.isBlank(a.AccountNumber) ? a.Name : a.AccountNumber);
    SObject existente = perfilPorCuenta.get(a.Id);
    if (existente == null) {
        SObject nuevo = Schema.getGlobalDescribe().get('BusinessProfile').newSObject();
        nuevo.put('AccountId', a.Id);
        nuevo.put(CAMPO, VALOR);
        aInsertar.add(nuevo);
        System.debug('   CREAR       ' + etiqueta + ' con ' + CAMPO + ' = ' + VALOR);
    } else if (String.valueOf(existente.get(CAMPO)) != VALOR) {
        String anterior = String.valueOf(existente.get(CAMPO));
        existente.put(CAMPO, VALOR);
        aActualizar.add(existente);
        System.debug('   ACTUALIZAR  ' + etiqueta + ' | ' + existente.get('Name')
            + ' | de "' + anterior + '" a "' + VALOR + '"');
    } else {
        System.debug('   OK          ' + etiqueta + ' ya esta correcto');
    }
}

System.debug('===================================================');
System.debug('5. RESULTADO');
System.debug('===================================================');
if (aInsertar.isEmpty() && aActualizar.isEmpty()) {
    System.debug('   Nada que hacer.');
} else if (!EJECUTAR) {
    System.debug('   SIMULACION. Crear ' + aInsertar.size()
        + ', actualizar ' + aActualizar.size() + '.');
    System.debug('   Para aplicar: cambiar EJECUTAR a true.');
} else {
    if (!aInsertar.isEmpty()) {
        List<Database.SaveResult> r = Database.insert(aInsertar, false);
        Integer ok = 0;
        for (Integer i = 0; i < r.size(); i++) {
            if (r[i].isSuccess()) { ok++; }
            else { System.debug('   FALLO insert: ' + r[i].getErrors()[0].getMessage()); }
        }
        System.debug('   Insertados ' + ok + ' de ' + aInsertar.size());
    }
    if (!aActualizar.isEmpty()) {
        List<Database.SaveResult> r = Database.update(aActualizar, false);
        Integer ok = 0;
        for (Integer i = 0; i < r.size(); i++) {
            if (r[i].isSuccess()) { ok++; }
            else { System.debug('   FALLO update: ' + r[i].getErrors()[0].getMessage()); }
        }
        System.debug('   Actualizados ' + ok + ' de ' + aActualizar.size());
    }
    System.debug('   Volver a correr en simulacion para confirmar.');
}

System.debug('===================================================');
System.debug('6. ESTADO DE TODOS LOS BusinessProfile');
System.debug('===================================================');
try {
    for (AggregateResult ar : [SELECT BusinessPartnerType t, COUNT(Id) q
                               FROM BusinessProfile GROUP BY BusinessPartnerType]) {
        System.debug('   ' + ar.get('t') + ' | ' + ar.get('q'));
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}
System.debug('   Si todavia aparece "Sales Dealer", falta el Replace en Setup.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
