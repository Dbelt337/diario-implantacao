// Modelagem de veículo demo/exposição — describe de status/condição/uso.
// Rodar em Anonymous Apex e ler o Debug Log. Mostra campos de estado e seus
// valores de picklist (para modelar o "bloqueio" nativamente).

List<String> objs = new List<String>{'Vehicle','SerializedProduct','ProductItem','Asset'};

for (String o : objs) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o);
    if (t == null) { System.debug('=== ' + o + ' NAO EXISTE'); continue; }
    Map<String, Schema.SObjectField> fields = t.getDescribe().fields.getMap();
    System.debug('====================== ' + o + ' ======================');
    for (String fn : fields.keySet()) {
        Schema.DescribeFieldResult f = fields.get(fn).getDescribe();
        String n = f.getName();
        Boolean relevante = n.containsIgnoreCase('Status') || n.containsIgnoreCase('Condition')
            || n.containsIgnoreCase('Usage') || n.containsIgnoreCase('Type')
            || n.containsIgnoreCase('State') || n.containsIgnoreCase('Demo')
            || n.containsIgnoreCase('Available') || n.containsIgnoreCase('Allocated')
            || n.containsIgnoreCase('Block') || n.containsIgnoreCase('Reserve')
            || n.containsIgnoreCase('Stage') || n.containsIgnoreCase('Lifecycle');
        if (!relevante) continue;
        String line = n + ' (' + f.getType() + ') label="' + f.getLabel() + '"'
                      + (f.isCustom() ? ' [CUSTOM]' : '');
        System.debug(line);
        if (f.getType() == Schema.DisplayType.PICKLIST) {
            List<String> vals = new List<String>();
            for (Schema.PicklistEntry pe : f.getPicklistValues()) {
                if (pe.isActive()) vals.add(pe.getValue());
            }
            System.debug('    VALORES: ' + String.join(vals, ' | '));
        }
    }
}
