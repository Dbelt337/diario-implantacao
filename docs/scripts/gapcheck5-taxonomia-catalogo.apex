// GAPCHECK5 — disponibilidade da taxonomia nativa de catálogo na org
// Execute Anonymous · só leitura · filtrar o log por "GAPCHECK5"
List<String> r = new List<String>();
r.add('=============== GAPCHECK5 ===============');
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
for (String obj : new List<String>{'ProductCatalog','ProductCategory','ProductCategoryProduct',
                                   'BusinessBrand','ProductClassification','CalculationMatrix','ExpressionSet'}) {
    Schema.SObjectType t = gd.get(obj.toLowerCase());
    if (t == null) { r.add('[NO]  ' + obj); continue; }
    Integer n = -1;
    try { n = Database.countQuery('SELECT COUNT() FROM ' + obj); } catch (Exception e) {}
    r.add('[SI]  ' + obj + ' · registros: ' + (n == -1 ? 'n/d' : String.valueOf(n))
        + ' · creable: ' + t.getDescribe().isCreateable());
}
// hierarquia de categoria disponível?
if (gd.get('productcategory') != null) {
    Map<String, Schema.SObjectField> f = gd.get('productcategory').getDescribe().fields.getMap();
    r.add('[INFO] ProductCategory tiene ParentCategoryId: ' + f.containsKey('parentcategoryid')
        + ' · CatalogId: ' + f.containsKey('catalogid'));
}
// campos reales de marca/modelo en VehicleDefinition
if (gd.get('vehicledefinition') != null) {
    List<String> cand = new List<String>();
    for (Schema.SObjectField f : gd.get('vehicledefinition').getDescribe().fields.getMap().values()) {
        String n2 = f.getDescribe().getName().toLowerCase();
        if (n2.contains('make') || n2.contains('model') || n2.contains('brand')
            || n2.contains('year') || n2.contains('trim')) {
            cand.add(f.getDescribe().getName());
        }
    }
    r.add('[INFO] VehicleDefinition marca/modelo/año: ' + String.join(cand, ', '));
}
r.add('=========================================');
System.debug(LoggingLevel.ERROR, '\n' + String.join(r, '\n'));
