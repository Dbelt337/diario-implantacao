// HU-046 rodada 3 — describe completo de VehicleDefinition (wire B: onde vive a marca?)
// Executar em Developer Console > Execute Anonymous. Mandar só as linhas USER_DEBUG.
Map<String, Schema.SObjectField> fm = Schema.SObjectType.VehicleDefinition.fields.getMap();
for (String f : fm.keySet()) {
    Schema.DescribeFieldResult d = fm.get(f).getDescribe();
    String refs = '';
    for (Schema.SObjectType t : d.getReferenceTo()) refs += t.getDescribe().getName() + ' ';
    System.debug(d.getName() + ' : ' + d.getType() + (refs == '' ? '' : ' -> (' + refs.trim() + ')'));
}
