// HU-064: quais colunas PADRAO ja servem, para nao criar campo a toa. Solo lectura.
// Imprime nome, tipo, se e calculado e se e gravavel. Calculado ou nao gravavel
// significa que nao serve para o motor escrever, e ai sim falta campo.

for (String o : new List<String>{'Quote','QuoteLineItem','Order','OrderItem'}) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o.toLowerCase());
    if (t == null) { System.debug('=== ' + o + ': NAO existe'); continue; }
    System.debug('=== ' + o + ' ===');
    List<String> ns = new List<String>();
    Map<String, Schema.SObjectField> m = t.getDescribe().fields.getMap();
    for (String k : m.keySet()) { ns.add(m.get(k).getDescribe().getName()); }
    ns.sort();
    for (String n : ns) {
        Schema.DescribeFieldResult d = m.get(n.toLowerCase()).getDescribe();
        if (d.isCustom()) { continue; }
        String nl = n.toLowerCase();
        Boolean interessa = nl.contains('price') || nl.contains('discount')
            || nl.contains('amount') || nl.contains('total') || nl.contains('subtotal')
            || nl.contains('quantity') || nl.contains('tax') || nl.contains('status')
            || nl.contains('cost') || nl.contains('margin') || nl == 'description';
        if (!interessa) { continue; }
        System.debug('   ' + n + ' | ' + d.getType()
            + ' | calculado=' + d.isCalculated()
            + ' | gravavel=' + d.isUpdateable()
            + ' | criavel=' + d.isCreateable());
    }
}

System.debug('=== VALORES DE Quote.Status, ANTES DE CRIAR CAMPO DE AUTORIZACAO ===');
System.debug('   Se ja houver um valor que sirva para "requiere autorizacion",');
System.debug('   nao se cria checkbox. Restrita significa que acrescentar valor');
System.debug('   proprio faz a funcionalidade padrao ver algo que nao conhece.');
Schema.DescribeFieldResult st = Quote.Status.getDescribe();
System.debug('   restrita=' + st.isRestrictedPicklist() + ' | gravavel=' + st.isUpdateable());
for (Schema.PicklistEntry pe : st.getPicklistValues()) {
    System.debug('   ' + (pe.isActive() ? 'ATIVO   ' : 'INATIVO ')
        + pe.getValue() + ' | ' + pe.getLabel() + (pe.isDefaultValue() ? ' | PADRAO' : ''));
}

System.debug('=== ONDE MORA O CUSTO, PARA A MARGEM DA RN10 ===');
for (String o : new List<String>{'Product2','PricebookEntry','Vehicle','Asset','QuoteLineItem'}) {
    Schema.SObjectType t = Schema.getGlobalDescribe().get(o.toLowerCase());
    if (t == null) { continue; }
    List<String> ach = new List<String>();
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult d = f.getDescribe();
        String n = (d.getName() + ' ' + d.getLabel()).toLowerCase();
        if (n.contains('cost') || n.contains('costo') || n.contains('margen')
            || n.contains('margin')) { ach.add(d.getName()); }
    }
    System.debug('   ' + o + ': ' + (ach.isEmpty() ? 'NENHUM campo de custo' : String.valueOf(ach)));
}

System.debug('=== O QUE O PRICEBOOKENTRY JA CARREGA ===');
for (Schema.SObjectField f : PricebookEntry.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    if (!d.isCustom()) { continue; }
    System.debug('   ' + d.getName() + ' | ' + d.getType() + ' | ' + d.getLabel());
}

System.debug('=== COMO LER ===');
System.debug('   a) campo padrao com gravavel=true serve e nao se cria nada;');
System.debug('   b) calculado=true significa somente leitura: Quote.Discount e');
System.debug('      derivado das linhas, entao nao recebe desconto de cabecalho;');
System.debug('   c) se OrderItem nao tiver Discount, o pedido do Escenario 17 nao');
System.debug('      tem onde guardar o percentual e ai sim falta campo.');
