// HU-042 T01 — describe de la linea de cotizacion y campos de color.
// Objetivo: confirmar si QuoteLineItem/OpportunityLineItem tienen lookup
// NATIVO a Vehicle (Automotive Cloud) y donde viven color exterior/interior,
// ANTES de crear cualquier campo custom (T08 depende de este resultado).
// Ejecutar como Anonymous Apex (Developer Console / Workbench) y revisar el log.
List<String> objetos = new List<String>{
    'QuoteLineItem', 'OpportunityLineItem', 'Quote', 'OpportunityLineItemVehicle', 'QuoteLineItemVehicle'
};
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
for (String o : objetos) {
    Schema.SObjectType t = gd.get(o.toLowerCase());
    if (t == null) {
        System.debug('NO EXISTE EN LA ORG: ' + o);
        continue;
    }
    System.debug('=== ' + o + ' ===');
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        for (Schema.SObjectType ref : d.getReferenceTo()) {
            String refName = String.valueOf(ref);
            if (refName == 'Vehicle' || refName == 'VehicleDefinition' || refName == 'Asset') {
                System.debug('  LOOKUP ' + d.getName() + ' -> ' + refName);
            }
        }
        if (d.getName().toLowerCase().contains('color')) {
            System.debug('  CAMPO COLOR: ' + d.getName() + ' (' + d.getType() + ')');
        }
    }
}
