// ============================================================================
// GAP CHECK v2 — carga de productos, precios, stock e inventario (12/08/2026)
// Execute Anonymous (Developer Console). Solo LEE: describe + counts, cero DML.
// v2: cada sección protegida por try/catch — una falla puntual se reporta
// como línea [ERRO] y el resto del informe SIEMPRE sale (la v1 moría entera
// con un NullPointerException si un campo esperado no existía).
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

// --- 1. objetos y campos ---
for (String obj : alvo.keySet()) {
    try {
        Schema.SObjectType tipo = gd.get(obj.toLowerCase());
        if (tipo == null) {
            lineas.add('[FALTA OBJETO] ' + obj + ' — no existe/no habilitado en la org');
            continue;
        }
        Map<String, Schema.SObjectField> campos = tipo.getDescribe().fields.getMap();
        List<String> faltan = new List<String>();
        for (String c : alvo.get(obj)) {
            if (!campos.containsKey(c.toLowerCase())) { faltan.add(c); }
        }
        Integer n = -1;
        try { n = Database.countQuery('SELECT COUNT() FROM ' + obj); } catch (Exception e) { /* sin permiso/soporte */ }
        lineas.add((faltan.isEmpty() ? '[OK]   ' : '[GAP]  ') + obj
            + ' | registros: ' + (n == -1 ? 'n/d' : String.valueOf(n))
            + (faltan.isEmpty() ? '' : ' | CAMPOS FALTANTES: ' + String.join(faltan, ', ')));
    } catch (Exception e) {
        lineas.add('[ERRO] ' + obj + ': ' + e.getMessage());
    }
}

// --- 2. VIN: nombre real del campo en Vehicle ---
try {
    if (gd.get('vehicle') != null) {
        List<String> vinCand = new List<String>();
        for (Schema.SObjectField f : gd.get('vehicle').getDescribe().fields.getMap().values()) {
            String api = f.getDescribe().getName();
            String low = api.toLowerCase();
            if (low.contains('identification') || low.contains('vin')) { vinCand.add(api); }
        }
        lineas.add('[INFO] Vehicle — candidatos a VIN: '
            + (vinCand.isEmpty() ? '(ninguno con "vin"/"identification" en el nombre)' : String.join(vinCand, ', ')));
    }
} catch (Exception e) { lineas.add('[ERRO] VIN: ' + e.getMessage()); }

// --- 3. roles de kit disponibles (seed del ProductRelatedComponent) ---
try {
    if (gd.get('productrelationshiptype') != null) {
        Map<String, Schema.SObjectField> prt = gd.get('productrelationshiptype').getDescribe().fields.getMap();
        Schema.SObjectField rol = prt.get('mainproductrole');
        if (rol == null) {
            // el campo esperado no existe: listar los campos reales para decidir
            lineas.add('[INFO] ProductRelationshipType SIN campo MainProductRole. Campos reales: '
                + String.join(new List<String>(prt.keySet()), ', '));
        } else {
            List<String> roles = new List<String>();
            for (Schema.PicklistEntry pe : rol.getDescribe().getPicklistValues()) {
                roles.add(pe.getValue() + (pe.isActive() ? '' : ' (inactivo)'));
            }
            lineas.add('[INFO] ProductRelationshipType.MainProductRole valores: '
                + (roles.isEmpty() ? '(picklist vacía — es texto libre o sin valores)' : String.join(roles, ', ')));
        }
    }
} catch (Exception e) { lineas.add('[ERRO] roles kit: ' + e.getMessage()); }

// --- 4. monedas activas (multi-moneda: la moneda vive en cada PricebookEntry) ---
try {
    List<String> monedas = new List<String>();
    for (SObject c : Database.query('SELECT IsoCode FROM CurrencyType WHERE IsActive = true')) {
        monedas.add((String) c.get('IsoCode'));
    }
    lineas.add('[INFO] Monedas activas: ' + String.join(monedas, ', '));
} catch (Exception e) {
    lineas.add('[INFO] Org SIN multi-moneda habilitada (CurrencyType no consultable).');
}

// --- 5. backfill del external id (garantía anti-duplicado de la BD) ---
try {
    if (gd.get('product2') != null
            && gd.get('product2').getDescribe().fields.getMap().containsKey('sapmaterialcode__c')) {
        Integer sinCodigo = Database.countQuery(
            'SELECT COUNT() FROM Product2 WHERE IsActive = true AND SapMaterialCode__c = null');
        lineas.add('[DATO] Product2 activos SIN SapMaterialCode__c (backfill pendiente): ' + sinCodigo);
    }
} catch (Exception e) { lineas.add('[ERRO] backfill: ' + e.getMessage()); }

// --- 6. VehicleDefinition huérfanas (rompen subqueries del flujo — bug 3 de la suite) ---
try {
    if (gd.get('vehicledefinition') != null) {
        Integer huerfanas = Database.countQuery('SELECT COUNT() FROM VehicleDefinition WHERE ProductId = null');
        lineas.add('[DATO] VehicleDefinition con ProductId NULO (cargar siempre con ProductId): ' + huerfanas);
    }
} catch (Exception e) { lineas.add('[ERRO] VehicleDefinition: ' + e.getMessage()); }

// --- 7. productos sin entrada Standard (bloquean el insert en listas custom) ---
try {
    List<Pricebook2> std = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    if (std.isEmpty()) {
        lineas.add('[DATO] La org no expone lista Standard por SOQL (revisar permisos).');
    } else {
        Integer sinStd = Database.countQuery(
            'SELECT COUNT() FROM Product2 WHERE IsActive = true AND Id NOT IN '
            + '(SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id = \'' + std[0].Id + '\')');
        lineas.add('[DATO] Product2 activos SIN entrada en la lista Standard: ' + sinStd);
    }
} catch (Exception e) { lineas.add('[ERRO] entrada Standard: ' + e.getMessage()); }

lineas.add('==================================================');
System.debug(LoggingLevel.ERROR, '\n' + String.join(lineas, '\n'));
