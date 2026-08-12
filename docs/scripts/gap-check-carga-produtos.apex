// ============================================================================
// GAP CHECK — carga de productos, precios, stock e inventario (12/08/2026)
// Execute Anonymous (Developer Console). Solo LEE: describe + counts, cero DML.
// Compara la org contra el modelo oficial del Automotive Cloud Developer Guide
// (cadena Product2 -> VehicleDefinition -> Vehicle/Asset + Pricebook nativo)
// y contra lo que nuestros flujos (venta guiada / HU-043 / US-021) consumen.
// Leer el resultado en el debug log filtrando por "GAPCHECK".
// ============================================================================

Map<String, List<String>> alvo = new Map<String, List<String>>{
    // catálogo
    'Product2'                 => new List<String>{'ProductCode','SapMaterialCode__c','Family','IsActive','Description'},
    // precios (Standard primero: regla de plataforma)
    'Pricebook2'               => new List<String>{'IsStandard','IsActive','Description'},
    'PricebookEntry'           => new List<String>{'UnitPrice','CurrencyIsoCode','UseStandardPrice','IsActive'},
    // kits (GQ-PV-02-029)
    'ProductRelationshipType'  => new List<String>{'MainProductRole','AssociatedProductRole'},
    'ProductRelatedComponent'  => new List<String>{'ParentProductId','ChildProductId','Quantity','ProductRelationshipTypeId'},
    // vehículos (Automotive: VehicleDefinition.ProductId -> Product2)
    'VehicleDefinition'        => new List<String>{'ProductId','Name'},
    'Vehicle'                  => new List<String>{'VehicleDefinitionId','Status','AssetId','LocationId'},
    'Asset'                    => new List<String>{'Product2Id','AccountId','SerialNumber','Status','PurchaseDate'},
    // inventario multi-tienda / Inventory Search
    'Location'                 => new List<String>{'LocationType','ExternalReference','IsInventoryLocation'},
    'VehicleSearchableField'   => new List<String>{},
    // nuestros campos del flujo (HU-043)
    'QuoteLineItem'            => new List<String>{'AvailabilityStatus__c','AvailabilityDetail__c'},
    'Order'                    => new List<String>{'SapStatus__c','SapOrderNumber__c','SapInvoiceNumber__c','SapInvoiceDate__c'}
};

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
List<String> lineas = new List<String>();
lineas.add('==================== GAPCHECK ====================');

for (String obj : alvo.keySet()) {
    Schema.SObjectType tipo = gd.get(obj);
    if (tipo == null) {
        lineas.add('[FALTA OBJETO] ' + obj + ' — no existe/no habilitado en la org');
        continue;
    }
    Schema.DescribeSObjectResult d = tipo.getDescribe();
    Map<String, Schema.SObjectField> campos = d.fields.getMap();
    List<String> faltan = new List<String>();
    for (String c : alvo.get(obj)) {
        if (!campos.containsKey(c.toLowerCase())) { faltan.add(c); }
    }
    Integer n = -1;
    try { n = Database.countQuery('SELECT COUNT() FROM ' + obj); } catch (Exception e) { /* sin permiso/soporte */ }
    lineas.add((faltan.isEmpty() ? '[OK]   ' : '[GAP]  ') + obj
        + ' | registros: ' + (n == -1 ? 'n/d' : String.valueOf(n))
        + (faltan.isEmpty() ? '' : ' | CAMPOS FALTANTES: ' + String.join(faltan, ', ')));
}

// --- detalles que deciden la carga ---

// 1. VIN: nombre real del campo en Vehicle (varía la etiqueta; buscar por 'identification')
if (gd.containsKey('Vehicle')) {
    List<String> vinCand = new List<String>();
    for (Schema.SObjectField f : gd.get('Vehicle').getDescribe().fields.getMap().values()) {
        String api = f.getDescribe().getName();
        if (api.toLowerCase().contains('identification') || api.toLowerCase().contains('vin')) {
            vinCand.add(api);
        }
    }
    lineas.add('[INFO] Vehicle — candidatos a VIN: ' + String.join(vinCand, ', '));
}

// 2. Tipos de relación de kit disponibles (para el seed de ProductRelatedComponent)
if (gd.containsKey('ProductRelationshipType')) {
    List<String> roles = new List<String>();
    for (Schema.PicklistEntry pe :
            gd.get('ProductRelationshipType').getDescribe().fields.getMap()
              .get('MainProductRole').getDescribe().getPicklistValues()) {
        roles.add(pe.getValue());
    }
    lineas.add('[INFO] ProductRelationshipType.MainProductRole valores: ' + String.join(roles, ', '));
}

// 3. Monedas activas (multi-moneda: cada PricebookEntry lleva CurrencyIsoCode)
try {
    List<String> monedas = new List<String>();
    for (SObject c : Database.query('SELECT IsoCode FROM CurrencyType WHERE IsActive = true')) {
        monedas.add((String) c.get('IsoCode'));
    }
    lineas.add('[INFO] Monedas activas: ' + String.join(monedas, ', '));
} catch (Exception e) {
    lineas.add('[INFO] Org SIN multi-moneda habilitada (CurrencyType no consultable).');
}

// 4. Estado del backfill del external id (garantía anti-duplicado de la BD)
if (gd.containsKey('Product2')
        && gd.get('Product2').getDescribe().fields.getMap().containsKey('sapmaterialcode__c')) {
    Integer sinCodigo = Database.countQuery(
        'SELECT COUNT() FROM Product2 WHERE IsActive = true AND SapMaterialCode__c = null');
    lineas.add('[DATO] Product2 activos SIN SapMaterialCode__c (backfill pendiente): ' + sinCodigo);
}

// 5. VehicleDefinition huérfanas (rompen los subqueries del flujo — bug 3 de la suite)
if (gd.containsKey('VehicleDefinition')) {
    Integer huerfanas = Database.countQuery('SELECT COUNT() FROM VehicleDefinition WHERE ProductId = null');
    lineas.add('[DATO] VehicleDefinition con ProductId NULO (cargar siempre con ProductId): ' + huerfanas);
}

// 6. Productos sin entrada Standard (bloquea el insert en listas custom)
try {
    Id stdId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
    Integer sinStd = Database.countQuery(
        'SELECT COUNT() FROM Product2 WHERE IsActive = true AND Id NOT IN '
        + '(SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = \'' + stdId + '\')');
    lineas.add('[DATO] Product2 activos SIN entrada en la lista Standard: ' + sinStd);
} catch (Exception e) {
    lineas.add('[DATO] No fue posible medir productos sin entrada Standard: ' + e.getMessage());
}

lineas.add('==================================================');
System.debug(LoggingLevel.ERROR, '\n' + String.join(lineas, '\n'));
