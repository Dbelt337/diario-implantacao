// Describe de Vehicle e VehicleDefinition — rodar em Anonymous Apex (Dev Console
// ou Inspector). Lista os campos CRIÁVEIS (os que você usa no carregamento),
// com tipo, se é OBRIGATÓRIO e o objeto de referência (lookups).
// Use a saída para montar o arquivo de carga com os campos e a ordem certos.

List<String> objs = new List<String>{'VehicleDefinition','Vehicle'};
for (String o : objs) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o);
    if (t == null) { System.debug('OBJETO NAO EXISTE/NAO ACESSIVEL: ' + o); continue; }
    Schema.DescribeSObjectResult d = t.getDescribe();
    System.debug('==== ' + o + ' | createable=' + d.isCreateable() + ' ====');
    for (Schema.SObjectField f : d.fields.getMap().values()) {
        Schema.DescribeFieldResult fr = f.getDescribe();
        if (!fr.isCreateable()) continue; // só campos que entram na carga
        Boolean req = !fr.isNillable() && !fr.isDefaultedOnCreate();
        String ref = fr.getReferenceTo().isEmpty() ? '' : ' -> ' + String.valueOf(fr.getReferenceTo());
        System.debug(o + ' | ' + fr.getName() + ' | ' + fr.getType()
                     + (req ? ' | OBRIGATORIO' : '') + ref);
    }
}
// Dica: no Dev Console, marque só DEBUG e filtre por "VehicleDefinition |" e "Vehicle |".
