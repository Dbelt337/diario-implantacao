/**
 * Que son tecnicamente los campos de "Reserva y Pago" en Opportunity.
 *
 * Responde por que aparecen sin control de edicion en el modal, que puede
 * ser por tres razones distintas y solo una es un problema:
 *   a) son formula o roll-up, entonces nunca se editan y esta bien;
 *   b) son campos normales pero el perfil los tiene en solo lectura por FLS;
 *   c) son campos normales y editables, y el problema es otro.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

System.debug('===================================================');
System.debug('CAMPOS DE RESERVA Y PAGO EN OPPORTUNITY');
System.debug('===================================================');

System.debug('----- 1. DEFINICION TECNICA DE CADA CAMPO -----');
List<String> apiNames = new List<String>();
for (Schema.SObjectField f : Opportunity.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult fd = f.getDescribe();
    String label = fd.getLabel().toLowerCase();
    if (!label.contains('reserva') && !label.contains('pago') && !label.contains('vigencia')) {
        continue;
    }
    apiNames.add(fd.getName());
    System.debug('   ' + fd.getName());
    System.debug('        label      : ' + fd.getLabel());
    System.debug('        tipo       : ' + fd.getType());
    System.debug('        custom     : ' + fd.isCustom());
    System.debug('        calculado  : ' + fd.isCalculated()
        + '   <- si es true, es formula y nunca se edita');
    System.debug('        creable    : ' + fd.isCreateable());
    System.debug('        editable   : ' + fd.isUpdateable()
        + '   <- si es false para un admin, no es FLS, es la definicion');
    System.debug('        accesible  : ' + fd.isAccessible());
    if (fd.getType() == Schema.DisplayType.PICKLIST) {
        List<String> vals = new List<String>();
        for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
            if (pe.isActive()) { vals.add(pe.getValue()); }
        }
        System.debug('        valores    : ' + vals);
    }
}

if (apiNames.isEmpty()) {
    System.debug('   No se encontro ningun campo con esas etiquetas.');
    return;
}

System.debug('----- 2. FLS POR PERFIL, SOLO DONDE HAY DIFERENCIA -----');
System.debug('   Si un perfil tiene PermissionsEdit en false y PermissionsRead en');
System.debug('   true, el campo se ve pero no se edita, y eso explica el modal.');
try {
    Set<String> campos = new Set<String>();
    for (String a : apiNames) { campos.add('Opportunity.' + a); }

    for (FieldPermissions fp : [
            SELECT Field, PermissionsRead, PermissionsEdit,
                   Parent.Profile.Name, Parent.Label, Parent.IsOwnedByProfile
            FROM FieldPermissions
            WHERE Field IN :campos
            ORDER BY Field, Parent.Profile.Name NULLS LAST]) {
        String origen = fp.Parent.IsOwnedByProfile
            ? 'perfil ' + fp.Parent.Profile.Name
            : 'permission set ' + fp.Parent.Label;
        System.debug('   ' + fp.Field + ' | ' + origen
            + ' | leer=' + fp.PermissionsRead + ' | editar=' + fp.PermissionsEdit);
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo FieldPermissions: ' + e.getMessage());
}

System.debug('----- 3. AUTOMATIZACION QUE ESCRIBE ESOS CAMPOS -----');
System.debug('   Si los campos son editables pero nadie los llena a mano, la');
System.debug('   definicion tecnica es que los escribe un proceso. Revisar en');
System.debug('   Flow Trigger Explorer los flows de Opportunity y buscar cual');
System.debug('   asigna estos campos.');
try {
    List<FlowDefinitionView> flows = [
        SELECT ApiName, Label, TriggerType
        FROM FlowDefinitionView
        WHERE IsActive = true AND TriggerObjectOrEventLabel = 'Opportunity'
        ORDER BY TriggerType, Label
        LIMIT 200
    ];
    System.debug('   Flows activos sobre Opportunity: ' + flows.size());
    for (FlowDefinitionView f : flows) {
        System.debug('   ' + f.TriggerType + ' | ' + f.Label);
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
