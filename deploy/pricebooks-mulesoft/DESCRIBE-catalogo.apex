// De-para do catálogo — describe dos objetos para travar os API names reais.
// Rodar em Anonymous Apex (Dev Console / Inspector) e ler o Debug Log.
// Objetivo: campos obrigatórios, lookups e campos custom já existentes, para
// montar o contrato do MuleSoft (o que preencher e enviar).

List<String> objs = new List<String>{
    'Product2',            // produto vendável (Price Book)
    'VehicleDefinition',   // ficha técnica (marca/modelo/versão/ano/specs)
    'Vehicle',             // unidade física (VIN/placa) — inventário/usados
    'Pricebook2',          // catálogo de preço (já criado C101)
    'PricebookEntry',      // preço por sociedade
    'BusinessBrand',       // marca
    'ProductCategory',     // categoria (se disponível sem EPC)
    'ProductCatalog',      // catálogo (se disponível sem EPC)
    'Location',            // local/sucursal (inventário)
    'ProductItem',         // estoque por local
    'SerializedProduct'    // unidade serializada (VIN)
};

for (String o : objs) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o);
    if (t == null) { System.debug('=== ' + o + ' -> NAO EXISTE nesta org (feature/licença?)'); continue; }
    Map<String, Schema.SObjectField> fields = t.getDescribe().fields.getMap();
    System.debug('======================================================');
    System.debug('OBJ ' + o + '  createable=' + t.getDescribe().isCreateable()
                 + '  totalFields=' + fields.size());
    for (String fn : new List<String>(fields.keySet())) {
        Schema.DescribeFieldResult f = fields.get(fn).getDescribe();
        Boolean req = (!f.isNillable() && f.isCreateable() && !f.isDefaultedOnCreate());
        Boolean isLookup = (f.getType() == Schema.DisplayType.REFERENCE);
        Boolean isCustom = f.isCustom();
        Boolean extId = f.isExternalId();
        // mostrar: obrigatórios, lookups, external ids, custom, e campos-chave de catálogo/preço
        String n = f.getName();
        Boolean keyword = n.containsIgnoreCase('Price') || n.containsIgnoreCase('Code')
            || n.containsIgnoreCase('Make') || n.containsIgnoreCase('Model')
            || n.containsIgnoreCase('Year') || n.containsIgnoreCase('VIN')
            || n.containsIgnoreCase('Vehicle') || n.containsIgnoreCase('Engine')
            || n.containsIgnoreCase('Brand') || n.containsIgnoreCase('Condition')
            || n.containsIgnoreCase('Registration') || n.containsIgnoreCase('Country')
            || n.containsIgnoreCase('Quantity') || n.containsIgnoreCase('Serial');
        if (req || isLookup || isCustom || extId || keyword) {
            System.debug(
                (req ? '[OBRIG] ' : '        ')
                + (extId ? '[EXTID] ' : '')
                + (isLookup ? '[LOOKUP->' + String.join(f.getReferenceTo(), ',') + '] ' : '')
                + (isCustom ? '[CUSTOM] ' : '')
                + n + ' (' + f.getType() + ') len=' + f.getLength()
                + ' label="' + f.getLabel() + '"');
        }
    }
}
