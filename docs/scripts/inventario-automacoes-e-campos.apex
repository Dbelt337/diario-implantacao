/**
 * INVENTARIO DE AUTOMACOES E CAMPOS CUSTOM
 *
 * Transforma "precisamos avaliar o que ja tem" numa consulta de 30 segundos
 * em vez de uma opiniao.
 *
 * Executar em Developer Console, Debug, Open Execute Anonymous Window,
 * com Open Log marcado e Debug Only ativado.
 *
 * Responde:
 *   1. Quantos flows ativos existem, por objeto e por tipo de gatilho
 *   2. Quais objetos concentram automacao, que sao os que doem no save
 *   3. Quais triggers Apex existem, por objeto
 *   4. Campos custom dos objetos do fluxo de vendas, com marcacao de
 *      rotulos repetidos, que e o sintoma de campo duplicado por equipes
 *      diferentes
 */

System.debug('===================================================');
System.debug('INVENTARIO DE AUTOMACOES E CAMPOS');
System.debug('===================================================');

// ---------------------------------------------------------------- 1. FLOWS
System.debug('----- 1. FLOWS ATIVOS POR OBJETO E GATILHO -----');
Map<String, Integer> porObjeto = new Map<String, Integer>();
Integer totalAtivos = 0;
try {
    // FlowDefinitionView nao suporta queryMore, entao a consulta tem que
    // caber num unico lote: lista com LIMIT, nunca for direto sobre a SOQL.
    List<FlowDefinitionView> flows = [
        SELECT ApiName, Label, ProcessType, TriggerType,
               TriggerObjectOrEventLabel, IsActive
        FROM FlowDefinitionView
        WHERE IsActive = true
        ORDER BY TriggerObjectOrEventLabel, TriggerType, Label
        LIMIT 1000
    ];
    for (FlowDefinitionView f : flows) {
        totalAtivos++;
        String obj = String.isBlank(f.TriggerObjectOrEventLabel)
            ? '(sem objeto, screen flow ou autolaunched)'
            : f.TriggerObjectOrEventLabel;
        porObjeto.put(obj, (porObjeto.containsKey(obj) ? porObjeto.get(obj) : 0) + 1);
        System.debug('   ' + obj
            + ' | ' + (String.isBlank(f.TriggerType) ? 'sem gatilho' : f.TriggerType)
            + ' | ' + f.Label
            + ' | tipo=' + f.ProcessType);
    }
} catch (Exception e) {
    System.debug('   ERRO lendo FlowDefinitionView: ' + e.getMessage());
}

System.debug('----- 2. CONCENTRACAO, O QUE PESA NO SAVE -----');
System.debug('   TOTAL de flows ativos: ' + totalAtivos);
System.debug('   ATENCAO ao ler este total: a maior parte sao flows entregues pela');
System.debug('   propria plataforma, screen flows e autolaunched, e NAO rodam no save.');
System.debug('   O numero que importa e a soma dos que tem objeto abaixo, que sao os');
System.debug('   record-triggered.');
List<String> objetos = new List<String>(porObjeto.keySet());
objetos.sort();
for (String obj : objetos) {
    Integer n = porObjeto.get(obj);
    String alerta = n >= 5 ? '   <<< concentracao alta' : '';
    System.debug('   ' + obj + ': ' + n + alerta);
}
System.debug('   Nota: a ordem de execucao entre flows do mesmo objeto e do mesmo');
System.debug('   gatilho so e previsivel se a Trigger Order estiver definida em cada um.');
System.debug('   Sem isso, a ordem nao e garantida e muda sem aviso.');

// -------------------------------------------------------------- 3. TRIGGERS
System.debug('----- 3. TRIGGERS APEX POR OBJETO -----');
try {
    Map<String, Integer> trigPorObjeto = new Map<String, Integer>();
    for (ApexTrigger t : [SELECT Name, TableEnumOrId, Status
                          FROM ApexTrigger
                          WHERE Status = 'Active'
                          ORDER BY TableEnumOrId, Name]) {
        trigPorObjeto.put(t.TableEnumOrId,
            (trigPorObjeto.containsKey(t.TableEnumOrId) ? trigPorObjeto.get(t.TableEnumOrId) : 0) + 1);
        System.debug('   ' + t.TableEnumOrId + ' | ' + t.Name);
    }
    for (String obj : trigPorObjeto.keySet()) {
        if (trigPorObjeto.get(obj) > 1) {
            System.debug('   ATENCAO: ' + obj + ' tem ' + trigPorObjeto.get(obj)
                + ' triggers ativas. Mais de uma trigger por objeto torna a ordem imprevisivel.');
        }
    }
} catch (Exception e) {
    System.debug('   ERRO lendo ApexTrigger: ' + e.getMessage());
}

// ---------------------------------------------------------------- 4. CAMPOS
System.debug('----- 4. CAMPOS CUSTOM E ROTULOS REPETIDOS -----');
List<String> objetosDoFluxo = new List<String>{
    'Lead', 'Account', 'Contact', 'Opportunity', 'OpportunityLineItem',
    'Quote', 'QuoteLineItem', 'Order', 'OrderItem',
    'Product2', 'Pricebook2', 'PricebookEntry', 'Vehicle', 'Asset'
};
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

for (String nombre : objetosDoFluxo) {
    Schema.SObjectType t = gd.get(nombre.toLowerCase());
    if (t == null) { continue; }

    Map<String, List<String>> porRotulo = new Map<String, List<String>>();
    Integer customs = 0;
    for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
        Schema.DescribeFieldResult fd = f.getDescribe();
        if (!fd.isCustom()) { continue; }
        customs++;
        // Campos terminados em __pc sao a variante de Person Account de um
        // campo de Contact, criados pela plataforma. Contam no total mas nunca
        // sao duplicidade de equipe, entao ficam fora da comparacao de rotulo.
        if (fd.getName().endsWith('__pc')) { continue; }
        String chave = fd.getLabel().toLowerCase().trim();
        if (!porRotulo.containsKey(chave)) { porRotulo.put(chave, new List<String>()); }
        porRotulo.get(chave).add(fd.getName());
    }
    System.debug('   ' + nombre + ': ' + customs + ' campos custom');
    for (String rotulo : porRotulo.keySet()) {
        if (porRotulo.get(rotulo).size() > 1) {
            System.debug('      DUPLICADO por rotulo "' + rotulo + '": ' + porRotulo.get(rotulo));
        }
    }
}

System.debug('===================================================');
System.debug('FIM');
System.debug('===================================================');
