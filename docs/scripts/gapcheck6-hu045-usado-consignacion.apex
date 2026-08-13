/**
 * GAPCHECK6, HU-045 vehiculo usado y consignacion.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado. En el log, activar Debug Only.
 *
 * Responde:
 *   1. Que objetos del modelo de avaluo, titularidad y busqueda existen en la org
 *   2. Si Appraisal.PurposeType es picklist restringida y con que valores
 *   3. Que valores admite el tipo de hito de AssetMilestone (existe Resale?)
 *   4. Que campos de Vehicle son calculados o no editables
 *   5. Que campos custom ya existen en Vehicle y en Asset
 *   6. Si AppraisalItem.MakeName, ModelName y ModelYear son restringidas
 */

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

List<String> objetos = new List<String>{
    'Appraisal', 'AppraisalItem', 'AppraisalAdjustment', 'AppraisalItemAddOn', 'AppraisalItemProviderVal',
    'AssetTitle', 'AssetTitleParty', 'AssetAccountParticipant', 'AssetContactParticipant', 'AssetMilestone',
    'VehicleSearchableField', 'VehDefSearchableField', 'DealerVehDefSearchableField', 'SellerProduct',
    'Vehicle', 'VehicleDefinition', 'Asset', 'Location', 'Contract'
};

System.debug('===================================================');
System.debug('GAPCHECK6 HU-045, vehiculo usado y consignacion');
System.debug('===================================================');

System.debug('----- 1. DISPONIBILIDAD DE OBJETOS -----');
for (String nombre : objetos) {
    try {
        Schema.SObjectType t = gd.get(nombre.toLowerCase());
        if (t == null) {
            System.debug('NO EXISTE          : ' + nombre);
            continue;
        }
        Schema.DescribeSObjectResult d = t.getDescribe();
        System.debug('OK                 : ' + nombre
            + ' | label=' + d.getLabel()
            + ' | createable=' + d.isCreateable()
            + ' | queryable=' + d.isQueryable()
            + ' | campos=' + d.fields.getMap().size());
    } catch (Exception e) {
        System.debug('ERROR al describir ' + nombre + ': ' + e.getMessage());
    }
}

// Helper inline: imprime una picklist con su condicion de restringida
List<String> picklistsAInspeccionar = new List<String>{
    'Appraisal.PurposeType',
    'Appraisal.Status',
    'AppraisalItem.MakeName',
    'AppraisalItem.ModelName',
    'AppraisalItem.ModelYear',
    'AppraisalItem.ItemType',
    'AppraisalItem.RegistrationState',
    'AssetMilestone.MilestoneType',
    'AssetMilestone.Type',
    'AssetMilestone.Status',
    'AssetTitle.Status',
    'AssetTitle.TitleType',
    'AssetAccountParticipant.Role',
    'Vehicle.Status',
    'Vehicle.VehicleType'
};

System.debug('----- 2. PICKLISTS CLAVE, VALORES Y SI SON RESTRINGIDAS -----');
for (String ruta : picklistsAInspeccionar) {
    try {
        String obj = ruta.substringBefore('.');
        String campo = ruta.substringAfter('.');
        Schema.SObjectType t = gd.get(obj.toLowerCase());
        if (t == null) { System.debug('omitido, objeto inexistente: ' + ruta); continue; }
        Schema.SObjectField f = t.getDescribe().fields.getMap().get(campo.toLowerCase());
        if (f == null) { System.debug('NO EXISTE el campo : ' + ruta); continue; }
        Schema.DescribeFieldResult fd = f.getDescribe();
        if (fd.getType() != Schema.DisplayType.PICKLIST && fd.getType() != Schema.DisplayType.MULTIPICKLIST) {
            System.debug(ruta + ' NO es picklist, tipo=' + fd.getType());
            continue;
        }
        List<String> valores = new List<String>();
        for (Schema.PicklistEntry pe : fd.getPicklistValues()) {
            if (pe.isActive()) { valores.add(pe.getValue()); }
        }
        System.debug(ruta
            + ' | restringida=' + fd.isRestrictedPicklist()
            + ' | editable=' + fd.isUpdateable()
            + ' | valores=' + valores);
    } catch (Exception e) {
        System.debug('ERROR en picklist ' + ruta + ': ' + e.getMessage());
    }
}

System.debug('----- 3. VEHICLE, CAMPOS CALCULADOS O NO EDITABLES -----');
try {
    for (Schema.SObjectField f : Vehicle.SObjectType.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        Boolean soloLectura = fd.isCalculated() || (!fd.isCreateable() && !fd.isUpdateable());
        if (!soloLectura) { continue; }
        if (fd.getName().endsWith('Id') || fd.getName() == 'Id') { continue; }
        System.debug('solo lectura : ' + fd.getName()
            + ' | tipo=' + fd.getType()
            + ' | calculado=' + fd.isCalculated());
    }
} catch (Exception e) {
    System.debug('ERROR en Vehicle: ' + e.getMessage());
}

System.debug('----- 4. CAMPOS CUSTOM YA EXISTENTES EN VEHICLE Y ASSET -----');
for (String nombre : new List<String>{ 'Vehicle', 'Asset' }) {
    try {
        Schema.SObjectType t = gd.get(nombre.toLowerCase());
        if (t == null) { continue; }
        for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fd = f.getDescribe();
            if (!fd.isCustom()) { continue; }
            System.debug(nombre + '.' + fd.getName()
                + ' | tipo=' + fd.getType()
                + ' | label=' + fd.getLabel()
                + ' | externalId=' + fd.isExternalId()
                + ' | unico=' + fd.isUnique());
        }
    } catch (Exception e) {
        System.debug('ERROR en campos custom de ' + nombre + ': ' + e.getMessage());
    }
}

System.debug('----- 5. CAMPOS DE VEHICLESEARCHABLEFIELD, BASE DE LA BUSQUEDA DE INVENTARIO -----');
try {
    Schema.SObjectType t = gd.get('vehiclesearchablefield');
    if (t == null) {
        System.debug('VehicleSearchableField no existe en la org, revisar habilitacion de Automotive Cloud');
    } else {
        for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fd = f.getDescribe();
            System.debug('VSF.' + fd.getName() + ' | tipo=' + fd.getType() + ' | label=' + fd.getLabel());
        }
    }
} catch (Exception e) {
    System.debug('ERROR en VehicleSearchableField: ' + e.getMessage());
}

System.debug('----- 6. VOLUMENES Y RECORD TYPES -----');
for (String consulta : new List<String>{
        'SELECT COUNT() FROM VehicleDefinition',
        'SELECT COUNT() FROM Vehicle',
        'SELECT COUNT() FROM Asset',
        'SELECT COUNT() FROM Location',
        'SELECT COUNT() FROM Contract' }) {
    try {
        System.debug(consulta + ' => ' + Database.countQuery(consulta));
    } catch (Exception e) {
        System.debug(consulta + ' => ERROR ' + e.getMessage());
    }
}
try {
    for (Schema.RecordTypeInfo rt : Contract.SObjectType.getDescribe().getRecordTypeInfos()) {
        System.debug('Contract RecordType: ' + rt.getName() + ' | devName=' + rt.getDeveloperName()
            + ' | disponible=' + rt.isAvailable());
    }
} catch (Exception e) {
    System.debug('ERROR en RecordTypes de Contract: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('GAPCHECK6 FIN');
System.debug('===================================================');
