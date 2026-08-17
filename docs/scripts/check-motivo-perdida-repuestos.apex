/**
 * GQAUT-326, HU-024. Por que el campo de Motivo de Perdida muestra 5 valores y
 * no los 9 configurados, en Repuestos y PA.
 *
 * Hay CUATRO causas posibles y cada una tiene otro dueno y otro arreglo. Este
 * script dice cual es, en una sola pasada, sin tocar nada.
 *
 *   A. Los 4 valores NO EXISTEN en el campo. Nunca se crearon, solo estan en el
 *      documento de la HU. Arreglo: crearlos.
 *   B. Existen pero estan INACTIVOS. Arreglo: reactivarlos.
 *   C. Existen y estan activos, pero NO ESTAN ASIGNADOS al Record Type de
 *      Repuestos. Es la causa mas frecuente y la mas invisible, porque en la
 *      pantalla del campo se ven los 9 y en el registro se ven 5. Arreglo:
 *      Object Manager, Record Types, el Record Type, editar la picklist y pasar
 *      los valores de Available a Selected.
 *   D. El campo es DEPENDIENTE de otro. Entonces los valores existen, estan
 *      activos y asignados, y aun asi no aparecen porque el valor del campo
 *      controlador no los habilita. Arreglo: el mapa de dependencia.
 *
 * El script tambien cuenta si algun valor ya esta EN USO, porque eso decide
 * entre Replace y Del: borrar o cambiar un valor en uso sin Replace deja
 * registros huerfanos, que es lo que paso con los cuatro Sales Dealer de
 * BusinessProfile.
 *
 * Solo lectura. No sabe el nombre del campo: lo busca por describe.
 */

Organization laOrg = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | instancia=' + laOrg.InstanceName + ' | sandbox=' + laOrg.IsSandbox);
System.debug('   OJO: correrlo en la MISMA org donde QA vio el bug. QA es');
System.debug('   00DWJ000008GgDB2A0 y UAT es 00DWK000005VF7x2AG, y ya vimos que');
System.debug('   las dos tienen configuracion distinta de picklists en Lead.');

System.debug('===================================================');
System.debug('1. LOS RECORD TYPES DE OPPORTUNITY');
System.debug('===================================================');
Id rtRepuestos = null;
for (Schema.RecordTypeInfo ri :
        Opportunity.SObjectType.getDescribe().getRecordTypeInfos()) {
    if (ri.isMaster()) { continue; }
    System.debug('   ' + ri.getDeveloperName() + '  (' + ri.getName() + ')'
        + ' | activo=' + ri.isActive()
        + ' | disponible para mi=' + ri.isAvailable()
        + ' | por defecto=' + ri.isDefaultRecordTypeMapping());
    if (ri.getDeveloperName() == 'GQOpportunitiesRepuestosPA') {
        rtRepuestos = ri.getRecordTypeId();
    }
}
System.debug('   Record Type de Repuestos: '
    + (rtRepuestos == null ? 'NO ENCONTRADO, revisar el DeveloperName' : String.valueOf(rtRepuestos)));
System.debug('   Si "disponible para mi" es false, el problema puede ser del');
System.debug('   perfil de quien probo, no del campo.');

System.debug('===================================================');
System.debug('2. LOS CAMPOS QUE PUEDEN SER EL DE MOTIVO DE PERDIDA');
System.debug('===================================================');
Map<String, Schema.SObjectField> campos =
    Opportunity.SObjectType.getDescribe().fields.getMap();

List<Schema.DescribeFieldResult> candidatos = new List<Schema.DescribeFieldResult>();
for (Schema.SObjectField f : campos.values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    if (fd.getType() != Schema.DisplayType.PICKLIST
        && fd.getType() != Schema.DisplayType.MULTIPICKLIST) { continue; }
    String texto = (fd.getName() + ' ' + fd.getLabel()).toLowerCase();
    if (texto.contains('loss') || texto.contains('lost') || texto.contains('perdid')
        || texto.contains('perda') || texto.contains('motiv') || texto.contains('reason')) {
        candidatos.add(fd);
    }
}
if (candidatos.isEmpty()) {
    System.debug('   NINGUNO. Entonces el campo del bug no existe en Opportunity');
    System.debug('   en esta org, y la causa es A: nunca se creo. Puede tambien');
    System.debug('   estar en Quote o en otro objeto, revisar donde QA lo vio.');
}

for (Schema.DescribeFieldResult fd : candidatos) {
    System.debug('   ---------------------------------------------');
    System.debug('   CAMPO: ' + fd.getName() + '  (label: ' + fd.getLabel() + ')');
    System.debug('        custom     : ' + fd.isCustom());
    System.debug('        restringida: ' + fd.isRestrictedPicklist());
    System.debug('        dependiente: ' + fd.isDependentPicklist());
    if (fd.isDependentPicklist()) {
        Schema.SObjectField ctrl = fd.getController();
        System.debug('        CONTROLADA POR: '
            + (ctrl == null ? 'no se pudo leer' : ctrl.getDescribe().getName()));
        System.debug('        ES LA CAUSA D. Los valores pueden existir y estar');
        System.debug('        asignados, y no aparecer porque el valor del campo');
        System.debug('        controlador no los habilita. Se revisa en el mapa de');
        System.debug('        dependencia, en Field Dependencies.');
    }
    System.debug('        accesible  : ' + fd.isAccessible()
        + ' | actualizable=' + fd.isUpdateable());
    if (!fd.isAccessible() || !fd.isUpdateable()) {
        System.debug('        SIN PERMISO. Antes de mirar valores, revisar FLS.');
    }

    System.debug('        VALORES DEL CAMPO, a nivel de campo, no de Record Type:');
    Integer activos = 0, inactivos = 0;
    for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
        System.debug('          ' + (pe.isActive() ? 'ACTIVO  ' : 'INACTIVO')
            + ' | valor=' + pe.getValue()
            + ' | label=' + pe.getLabel()
            + (pe.isDefaultValue() ? ' | POR DEFECTO' : ''));
        if (pe.isActive()) { activos++; } else { inactivos++; }
    }
    System.debug('        Total: ' + activos + ' activos, ' + inactivos + ' inactivos');
    System.debug('        ');
    System.debug('        COMO LEER ESTO:');
    System.debug('        - si aqui NO aparecen los 4 valores que faltan, causa A,');
    System.debug('          no existen, hay que crearlos;');
    System.debug('        - si aparecen como INACTIVO, causa B, reactivar;');
    System.debug('        - si aparecen ACTIVO y aun asi el usuario ve 5, causa C:');
    System.debug('          no estan asignados al Record Type de Repuestos. Apex no');
    System.debug('          puede leer la asignacion por Record Type, se verifica en');
    System.debug('          Object Manager, Record Types, editar la picklist.');

    System.debug('        USO REAL EN REPUESTOS Y PA:');
    if (rtRepuestos == null) {
        System.debug('          sin Record Type no se puede contar');
    } else {
        try {
            String q = 'SELECT ' + fd.getName() + ' v, COUNT(Id) q FROM Opportunity'
                + ' WHERE RecordTypeId = \'' + rtRepuestos + '\''
                + ' GROUP BY ' + fd.getName() + ' ORDER BY COUNT(Id) DESC';
            for (AggregateResult ar : Database.query(q)) {
                System.debug('          ' + ar.get('v') + ' | ' + ar.get('q'));
            }
        } catch (Exception e) {
            System.debug('          no se pudo agrupar: ' + e.getMessage());
        }
        System.debug('          Un valor CON registros no se borra ni se renombra sin');
        System.debug('          Replace, o los registros quedan huerfanos.');
    }
}

System.debug('===================================================');
System.debug('3. VALORES QUE EL BUG PIDE, PARA CRUZAR A OJO');
System.debug('===================================================');
System.debug('   Presentes segun QA : Comprado en la competencia, Precio no');
System.debug('   competitivo, El cliente desistio, Sin respuesta del cliente, Otros');
System.debug('   FALTAN segun QA    : Producto no disponible, Plazo de entrega no');
System.debug('   aceptado, Compra postergada, Oportunidad duplicada');
System.debug('   ');
System.debug('   Los 5 que aparecen son los genericos y los 4 que faltan son los');
System.debug('   propios de repuestos. Ese patron apunta a que los 4 se agregaron');
System.debug('   despues, o se documentaron y nunca se agregaron.');

System.debug('===================================================');
System.debug('4. ANTES DE CREAR NADA');
System.debug('===================================================');
System.debug('   Regla del proyecto: no se crea valor de picklist sin verificar');
System.debug('   primero. Dos cosas concretas aqui:');
System.debug('   - "Oportunidad duplicada" no es un motivo de perdida comercial,');
System.debug('     es un problema de calidad de dato. Conviene decidir si va como');
System.debug('     valor o si esa oportunidad se elimina o se fusiona;');
System.debug('   - los valores deben nacer en INGLES por la convencion GRPQM, con');
System.debug('     la traduccion al espanol por Translation Workbench. El bug esta');
System.debug('     escrito en portugues, y si los valores se crearon asi, hay que');
System.debug('     corregirlo AHORA y no despues, porque cambiar el valor de una');
System.debug('     picklist en uso obliga a Replace.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
