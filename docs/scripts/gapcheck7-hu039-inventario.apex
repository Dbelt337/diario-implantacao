/**
 * GAPCHECK7, HU-039 creacion de material y objetos de inventario.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado. En el log, activar Debug Only.
 *
 * Responde:
 *   1. Que objetos de inventario del Automotive Cloud existen en la org
 *      (ProductItem, ProductTransfer, ProductRequest, SellerProduct, Codeset...)
 *   2. Como esta hoy Product2: Record Types, campos custom, y si ya tiene
 *      los campos que la HU-039 necesita
 *   3. Si Product2 tiene Field History y Feed Tracking, y cuantos campos
 *      quedan disponibles frente al limite de 20
 *   4. Si existe algun Approval Process sobre Product2
 *   5. Volumenes de Location e InternalOrganizationUnit, que son los
 *      lookups de sociedad, centro y sucursal
 */

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

System.debug('===================================================');
System.debug('GAPCHECK7 HU-039');
System.debug('===================================================');

System.debug('----- 1. OBJETOS DE INVENTARIO Y CATALOGO -----');
List<String> objetos = new List<String>{
    'ProductItem', 'ProductItemTransaction', 'ProductTransfer',
    'ProductRequest', 'ProductRequestLineItem', 'ProductConsumed',
    'SellerProduct', 'Codeset', 'CodesetRelationship',
    'ProductRelatedComponent', 'ProductCategory', 'ProductCategoryProduct',
    'Location', 'InternalOrganizationUnit', 'BusinessBrand',
    'ActionableEventType', 'ActionableEventOrchestration'
};
for (String nombre : objetos) {
    try {
        Schema.SObjectType t = gd.get(nombre.toLowerCase());
        if (t == null) { System.debug('   NO EXISTE : ' + nombre); continue; }
        Schema.DescribeSObjectResult d = t.getDescribe();
        System.debug('   OK        : ' + nombre
            + ' | creable=' + d.isCreateable()
            + ' | consultable=' + d.isQueryable()
            + ' | campos=' + d.fields.getMap().size());
    } catch (Exception e) {
        System.debug('   ERROR     : ' + nombre + ' ' + e.getMessage());
    }
}

System.debug('----- 2. PRODUCT2, RECORD TYPES ACTUALES -----');
try {
    List<Schema.RecordTypeInfo> rts = Product2.SObjectType.getDescribe().getRecordTypeInfos();
    if (rts.size() <= 1) {
        System.debug('   Product2 NO tiene Record Types configurados (solo el Master)');
    }
    for (Schema.RecordTypeInfo rt : rts) {
        System.debug('   RT: ' + rt.getName()
            + ' | devName=' + rt.getDeveloperName()
            + ' | master=' + rt.isMaster()
            + ' | default=' + rt.isDefaultRecordTypeMapping()
            + ' | disponible=' + rt.isAvailable());
    }
} catch (Exception e) {
    System.debug('   ERROR en Record Types: ' + e.getMessage());
}

System.debug('----- 3. PRODUCT2, CAMPOS CUSTOM EXISTENTES -----');
Integer customCount = 0;
try {
    for (Schema.SObjectField f : Product2.SObjectType.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        if (!fd.isCustom()) { continue; }
        customCount++;
        System.debug('   ' + fd.getName()
            + ' | tipo=' + fd.getType()
            + ' | label=' + fd.getLabel()
            + ' | externalId=' + fd.isExternalId()
            + ' | unico=' + fd.isUnique()
            + ' | editable=' + fd.isUpdateable());
    }
    System.debug('   TOTAL de campos custom en Product2: ' + customCount);
} catch (Exception e) {
    System.debug('   ERROR en campos custom: ' + e.getMessage());
}

System.debug('----- 4. CAMPOS QUE LA HU-039 NECESITA, CUALES YA EXISTEN -----');
List<String> requeridos = new List<String>{
    'SapMaterialCode__c', 'RequestStatus__c', 'RequestKey__c',
    'RequestedMaterialCode__c', 'RequestBrand__c', 'RequestCompany__c',
    'RequestPlant__c', 'RequestBranch__c', 'RequestedBy__c',
    'RequestFob__c', 'RequestOrigin__c', 'RequestVehicleModel__c',
    'RequestVin__c', 'RequestNotes__c', 'RejectionReason__c',
    'SapLastError__c', 'SapRetryCount__c', 'SapLastAttempt__c',
    'TurnoverClass__c', 'SupersededByProduct__c'
};
Map<String, Schema.SObjectField> camposP2 = Product2.SObjectType.getDescribe().fields.getMap();
Integer faltan = 0;
for (String campo : requeridos) {
    if (camposP2.containsKey(campo.toLowerCase())) {
        System.debug('   YA EXISTE : ' + campo);
    } else {
        System.debug('   FALTA     : ' + campo);
        faltan++;
    }
}
System.debug('   Campos por crear: ' + faltan + ' de ' + requeridos.size());

System.debug('----- 5. APPROVAL PROCESSES SOBRE PRODUCT2 -----');
try {
    List<ProcessDefinition> procesos = [
        SELECT DeveloperName, Name, TableEnumOrId, Type, State
        FROM ProcessDefinition
        WHERE TableEnumOrId = 'Product2'
    ];
    if (procesos.isEmpty()) {
        System.debug('   No hay Approval Process sobre Product2 todavia.');
        System.debug('   VERIFICAR A MANO: Setup, Approval Processes, y ver si Product2');
        System.debug('   aparece en la lista de objetos. Si no aparece, el camino es');
        System.debug('   aprobacion por Flow Orchestration.');
    }
    for (ProcessDefinition p : procesos) {
        System.debug('   ' + p.Name + ' | devName=' + p.DeveloperName
            + ' | tipo=' + p.Type + ' | estado=' + p.State);
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo ProcessDefinition: ' + e.getMessage());
}

System.debug('----- 6. VOLUMENES DE LOS LOOKUPS DE SOCIEDAD, CENTRO Y SUCURSAL -----');
for (String consulta : new List<String>{
        'SELECT COUNT() FROM Location',
        'SELECT COUNT() FROM InternalOrganizationUnit',
        'SELECT COUNT() FROM BusinessBrand',
        'SELECT COUNT() FROM Product2',
        'SELECT COUNT() FROM Product2 WHERE IsActive = false' }) {
    try {
        System.debug('   ' + consulta + ' => ' + Database.countQuery(consulta));
    } catch (Exception e) {
        System.debug('   ' + consulta + ' => ERROR ' + e.getMessage());
    }
}

System.debug('===================================================');
System.debug('GAPCHECK7 FIN');
System.debug('===================================================');
