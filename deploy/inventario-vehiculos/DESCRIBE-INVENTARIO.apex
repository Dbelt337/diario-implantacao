// Inventario SAP -> SF: describe de Product2 / VehicleDefinition / Vehicle
// Ejecutar en Anonymous Apex (ventana anonima o Workbench) y filtrar USER_DEBUG.
// Objetivo: trabar API names nativos (VIN, make, type, status), obligatorios,
// tipos/tamanos y picklists para completar el MAPEO-RFC-INVENTARIO-SF.md.
// Bloques independientes: se puede correr por objeto si el log crece mucho.

for (String o : new List<String>{'Product2', 'VehicleDefinition', 'Vehicle'}) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o);
    if (t == null) { System.debug('=== ' + o + ' -> NO EXISTE en esta org'); continue; }
    Schema.DescribeSObjectResult d = t.getDescribe();
    System.debug('==================================================');
    System.debug('OBJ ' + o + ' | createable=' + d.isCreateable()
        + ' | totalFields=' + d.fields.getMap().size());
    for (String fn : new List<String>(d.fields.getMap().keySet())) {
        Schema.DescribeFieldResult f = d.fields.getMap().get(fn).getDescribe();
        Boolean req = (!f.isNillable() && f.isCreateable() && !f.isDefaultedOnCreate());
        String tipo = String.valueOf(f.getType());
        String tam = '';
        if (f.getType() == Schema.DisplayType.STRING
            || f.getType() == Schema.DisplayType.TEXTAREA) {
            tam = ' len=' + f.getLength();
        } else if (f.getType() == Schema.DisplayType.CURRENCY
            || f.getType() == Schema.DisplayType.DOUBLE) {
            tam = ' prec=' + f.getPrecision() + ',' + f.getScale();
        }
        String extra = '';
        if (f.getType() == Schema.DisplayType.REFERENCE) {
            extra = ' ->' + String.join(f.getReferenceTo(), ',');
        }
        System.debug((req ? '[OBRIG] ' : '        ')
            + (f.isCalculated() ? '[FORMULA] ' : '')
            + (f.isExternalId() ? '[EXTID] ' : '')
            + (f.isCustom() ? '[CUSTOM] ' : '')
            + f.getName() + ' (' + tipo + tam + ')' + extra
            + ' | label="' + f.getLabel() + '"');
    }
}

// ===== Picklists clave (correr aparte si el log anterior quedo grande) =====
for (String par : new List<String>{
        'Vehicle:Status', 'VehicleDefinition:VehicleType',
        'Product2:Family'}) {
    String obj = par.split(':')[0];
    String campo = par.split(':')[1];
    Schema.SObjectType t2 = Schema.getGlobalDescribe().get(obj);
    if (t2 == null) continue;
    Schema.SObjectField sf = t2.getDescribe().fields.getMap().get(campo);
    if (sf == null) { System.debug(par + ' -> campo NO existe (buscar equivalente en el bloque anterior)'); continue; }
    Schema.DescribeFieldResult f2 = sf.getDescribe();
    System.debug('===== PICKLIST ' + par + ' | restricted=' + f2.isRestrictedPicklist());
    for (Schema.PicklistEntry pe : f2.getPicklistValues()) {
        System.debug('   ' + pe.getValue() + ' | ' + pe.getLabel() + ' | active=' + pe.isActive());
    }
}

/* ===== Validation rules de los 3 objetos (Query Editor CON Tooling API) =====
SELECT Id, ValidationName, Active, ErrorMessage, EntityDefinition.DeveloperName
FROM ValidationRule
WHERE EntityDefinition.DeveloperName IN ('Product2','VehicleDefinition','Vehicle')
*/
