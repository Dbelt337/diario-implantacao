// HU-046 rodada 4 (última do wire B) — a marca vive no Product2?
// Lista campos custom + Family/marca/brand do Product2 e mostra o produto ligado ao VehicleDefinition dos testes.
// Mandar só as linhas USER_DEBUG.
Map<String, Schema.SObjectField> fm = Schema.SObjectType.Product2.fields.getMap();
for (String f : fm.keySet()) {
    Schema.DescribeFieldResult d = fm.get(f).getDescribe();
    String n = d.getName();
    if (d.isCustom() || n == 'Family' || n.containsIgnoreCase('marca') || n.containsIgnoreCase('brand') || n.containsIgnoreCase('make')) {
        System.debug(n + ' : ' + d.getType());
    }
}
VehicleDefinition vd = [SELECT Id, Name, ModelCode, VariantName, ProductId FROM VehicleDefinition WHERE Id = '1PqWK0000000MoX0AU'];
System.debug('VD: ' + JSON.serialize(vd));
if (vd.ProductId != null) {
    System.debug('PROD: ' + JSON.serialize([SELECT Id, Name, Family, ProductCode FROM Product2 WHERE Id = :vd.ProductId]));
}
