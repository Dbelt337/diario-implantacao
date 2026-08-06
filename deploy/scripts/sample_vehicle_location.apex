// HU-046 rodada 3 — os campos Location* do Vehicle carregam o NOME da sucursal do excel de cupos?
// Lista os campos Location* e imprime os valores de até 5 Vehicles reais. Mandar só as linhas USER_DEBUG.
Map<String, Schema.SObjectField> fm = Schema.SObjectType.Vehicle.fields.getMap();
List<String> locFields = new List<String>();
for (String f : fm.keySet()) {
    Schema.DescribeFieldResult d = fm.get(f).getDescribe();
    if (d.getName().containsIgnoreCase('location') && d.getType() != Schema.DisplayType.LOCATION) {
        locFields.add(d.getName());
    }
}
System.debug('LOCATION FIELDS: ' + String.join(locFields, ', '));
String q = 'SELECT Id, Name, Status, VehicleDefinitionId' + (locFields.isEmpty() ? '' : ', ' + String.join(locFields, ', ')) + ' FROM Vehicle LIMIT 5';
for (SObject s : Database.query(q)) System.debug(JSON.serialize(s));
