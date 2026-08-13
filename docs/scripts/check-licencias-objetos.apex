/**
 * CHECK DE LICENCIAS Y DISPONIBILIDAD DE OBJETOS
 *
 * Responde, sin ambiguedad y para esta org:
 *   1. Que licencias de usuario y que permission set licenses tiene contratadas la org
 *   2. Cuales tiene asignadas el usuario que ejecuta el script
 *   3. Que objetos del diseno existen y son accesibles, agrupados por bloque funcional
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado. En el log, activar Debug Only.
 *
 * Lectura del resultado: si un objeto figura como NO EXISTE, la funcionalidad
 * no esta habilitada o la licencia no esta provisionada. Si figura OK pero con
 * accesible=false, la licencia esta pero falta permiso o permission set license
 * en el usuario.
 */

System.debug('===================================================');
System.debug('CHECK DE LICENCIAS Y OBJETOS');
System.debug('===================================================');

System.debug('----- 1. LICENCIAS DE USUARIO DE LA ORG -----');
try {
    for (UserLicense ul : [SELECT Name, Status, TotalLicenses, UsedLicenses
                           FROM UserLicense ORDER BY Name]) {
        if (ul.TotalLicenses == 0) { continue; }
        System.debug(ul.Name + ' | estado=' + ul.Status
            + ' | total=' + ul.TotalLicenses + ' | usadas=' + ul.UsedLicenses);
    }
} catch (Exception e) {
    System.debug('ERROR leyendo UserLicense: ' + e.getMessage());
}

System.debug('----- 2. PERMISSION SET LICENSES CONTRATADAS -----');
try {
    for (PermissionSetLicense psl : [SELECT MasterLabel, DeveloperName, Status,
                                            TotalLicenses, UsedLicenses, ExpirationDate
                                     FROM PermissionSetLicense ORDER BY MasterLabel]) {
        if (psl.TotalLicenses == 0) { continue; }
        System.debug(psl.MasterLabel + ' | devName=' + psl.DeveloperName
            + ' | estado=' + psl.Status
            + ' | total=' + psl.TotalLicenses + ' | usadas=' + psl.UsedLicenses
            + ' | vence=' + psl.ExpirationDate);
    }
} catch (Exception e) {
    System.debug('ERROR leyendo PermissionSetLicense: ' + e.getMessage());
}

System.debug('----- 3. PERMISSION SET LICENSES ASIGNADAS AL USUARIO QUE EJECUTA -----');
try {
    List<PermissionSetLicenseAssign> asignadas = [
        SELECT PermissionSetLicense.MasterLabel
        FROM PermissionSetLicenseAssign
        WHERE AssigneeId = :UserInfo.getUserId()
        ORDER BY PermissionSetLicense.MasterLabel
    ];
    if (asignadas.isEmpty()) {
        System.debug('El usuario ' + UserInfo.getUserName() + ' no tiene ninguna permission set license asignada');
    }
    for (PermissionSetLicenseAssign a : asignadas) {
        System.debug('asignada: ' + a.PermissionSetLicense.MasterLabel);
    }
} catch (Exception e) {
    System.debug('ERROR leyendo PermissionSetLicenseAssign: ' + e.getMessage());
}

System.debug('----- 4. OBJETOS POR BLOQUE FUNCIONAL -----');

Map<String, List<String>> bloques = new Map<String, List<String>>();
bloques.put('A. Sales Cloud y plataforma, sin licencia adicional', new List<String>{
    'Product2', 'Pricebook2', 'PricebookEntry', 'Opportunity', 'OpportunityLineItem',
    'Quote', 'QuoteLineItem', 'Order', 'OrderItem', 'Asset', 'Location', 'Contract', 'Account', 'Contact'
});
bloques.put('B. Automotive Cloud, nucleo', new List<String>{
    'Vehicle', 'VehicleDefinition', 'AssetMilestone', 'VehicleSearchableField',
    'AssetAccountParticipant', 'AssetContactParticipant', 'LeadLineItem', 'OpportunityPreferredSeller'
});
bloques.put('C. Automotive Cloud, avaluos y titularidad', new List<String>{
    'Appraisal', 'AppraisalItem', 'AppraisalAdjustment', 'AppraisalItemAddOn', 'AppraisalItemProviderVal',
    'AssetTitle', 'AssetTitleParty'
});
bloques.put('D. Automotive Cloud, financiamiento y lending', new List<String>{
    'FinancialAccount', 'FinancialAccountParty', 'VehDefSearchableField', 'PartyFinancialAsset'
});
bloques.put('E. Taxonomia de catalogo, requiere licencia Commerce o Revenue Cloud', new List<String>{
    'ProductCatalog', 'ProductCategory', 'ProductCategoryProduct', 'ProductRelatedComponent',
    'ProductClassification', 'BusinessBrand'
});

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
List<String> ordenBloques = new List<String>(bloques.keySet());
ordenBloques.sort();

for (String bloque : ordenBloques) {
    System.debug('   ');
    System.debug('>>> ' + bloque);
    for (String nombre : bloques.get(bloque)) {
        try {
            Schema.SObjectType t = gd.get(nombre.toLowerCase());
            if (t == null) {
                System.debug('   NO EXISTE   : ' + nombre);
                continue;
            }
            Schema.DescribeSObjectResult d = t.getDescribe();
            System.debug('   OK          : ' + nombre
                + ' | accesible=' + d.isAccessible()
                + ' | creable=' + d.isCreateable()
                + ' | consultable=' + d.isQueryable()
                + ' | campos=' + d.fields.getMap().size());
        } catch (Exception e) {
            System.debug('   ERROR       : ' + nombre + ' ' + e.getMessage());
        }
    }
}

System.debug('===================================================');
System.debug('FIN DEL CHECK');
System.debug('===================================================');
