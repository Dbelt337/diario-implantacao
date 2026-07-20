// HU-036 Avalúo — describe da família nativa Appraisal
// Rodar em Anonymous Apex (Dev Console / Inspector) e olhar o Debug Log.
// Objetivo: travar os API names reais dos campos do formulário do avalúo
// e descobrir se FinalAppraisalValue é calculado (formula/rollup) ou editável.

List<String> objs = new List<String>{
    'Appraisal',
    'AppraisalItem',
    'AppraisalItemAddon',
    'AppraisalItemProviderVal',
    'AppraisalAdjustment',
    'AppraisalComment'
};

for (String o : objs) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o);
    if (t == null) { System.debug('=== ' + o + ' -> NÃO EXISTE nesta org (feature não habilitada?)'); continue; }
    Map<String, Schema.SObjectField> fields = t.getDescribe().fields.getMap();
    System.debug('======================================================');
    System.debug('OBJ ' + o + '  (createable=' + t.getDescribe().isCreateable() + ')  totalFields=' + fields.size());
    for (String fn : new List<String>(fields.keySet())) {
        Schema.DescribeFieldResult f = fields.get(fn).getDescribe();
        // Só o que importa pro form: obrigatórios, lookups, calculados
        Boolean req = (!f.isNillable() && f.isCreateable() && !f.isDefaultedOnCreate());
        Boolean isLookup = (f.getType() == Schema.DisplayType.REFERENCE);
        Boolean calc = f.isCalculated(); // formula
        if (req || isLookup || calc || f.getName().containsIgnoreCase('Value')
            || f.getName().containsIgnoreCase('Appraisal')) {
            System.debug(
               (req ? '[OBRIG] ' : '        ')
             + (calc ? '[FORMULA] ' : '')
             + (isLookup ? '[LOOKUP->' + String.join(f.getReferenceTo(), ',') + '] ' : '')
             + f.getName() + '  (' + f.getType() + ')  updateable=' + f.isUpdateable()
             + '  label="' + f.getLabel() + '"');
        }
    }
}
