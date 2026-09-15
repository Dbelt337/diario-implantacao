// 10 - VALIDACAO ANTES DE CRIAR as works B2B-13 a B2B-16 (historias novas 26-29 de 10/09). Rodar PRIMEIRO.
// Somente SELECT + System.debug. Filtre o log por VAL10| e mande todas as linhas.
// O que verifica: (1) se alguma das 4 works ja existe (por prefixo e por palavra-chave); (2) a work de
// referencia W-000122 (B2B-09) para copiar RecordType/Time/Product Tag/Epic; (3) works criadas depois do
// export de 11/09 (W-000133 em diante, ex.: filhas de Conectividade das 51/52/55); (4) o objeto de
// Acceptance Criteria e seus campos, para o script 12 usar os nomes certos.

// --- 1. as 4 works desta rodada (prefixo do Subject) e palavras-chave para achar criacao sob outro codigo
Map<String, List<String>> alvo = new Map<String, List<String>>{
    'US B2B-13%' => new List<String>{ '%efideliza%pura%', '%enova%sem altera%' },
    'US B2B-14%' => new List<String>{ '%viso pr%vio%', '%orte autom%' },
    'US B2B-15%' => new List<String>{ '%ntervalo%cobran%', '%ondi%especia%fatura%' },
    'US B2B-16%' => new List<String>{ '%ad%ncia%assinatura%', '%otifica%assinatura%' }
};
for (String prefixo : alvo.keySet()) {
    List<agf__ADM_Work__c> ws = [SELECT Name, agf__Subject__c, agf__Status__c FROM agf__ADM_Work__c
                                 WHERE agf__Subject__c LIKE :prefixo];
    System.debug('VAL10| PREFIXO | ' + prefixo + ' | ' + (ws.isEmpty() ? 'NAO EXISTE (pode criar)' : 'JA EXISTE x' + ws.size()));
    for (agf__ADM_Work__c w : ws) System.debug('VAL10|    ' + w.Name + ' | ' + w.agf__Status__c + ' | ' + w.agf__Subject__c);
    for (String kw : alvo.get(prefixo)) {
        for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c FROM agf__ADM_Work__c
                                   WHERE agf__Subject__c LIKE :kw AND (NOT agf__Subject__c LIKE :prefixo) LIMIT 10]) {
            System.debug('VAL10| PALAVRA-CHAVE | ' + prefixo + ' | possivel duplicata: ' + w.Name + ' | ' + w.agf__Subject__c);
        }
    }
}

// --- 2. referencia B2B (mesmo epic/time/tag das works B2B-07 a B2B-12)
for (agf__ADM_Work__c r : [SELECT Name, agf__Subject__c, RecordTypeId, RecordType.Name, agf__Scrum_Team__r.Name,
                                  agf__Product_Tag__r.Name, agf__Assignee__r.Name, agf__Epic__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN ('W-000122','W-000125','W-000101')]) {
    System.debug('VAL10| REF | ' + r.Name + ' | rt=' + r.RecordType.Name + ' | time=' + r.agf__Scrum_Team__r.Name
        + ' | tag=' + r.agf__Product_Tag__r.Name + ' | assignee=' + r.agf__Assignee__r.Name + ' | epic=' + r.agf__Epic__r.Name);
}

// --- 3. works criadas depois do export de 11/09 (ultimo numero do export: W-000132)
for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c, agf__Status__c, agf__Epic__r.Name, CreatedDate, CreatedBy.Name
                           FROM agf__ADM_Work__c WHERE Name > 'W-000132' ORDER BY Name]) {
    System.debug('VAL10| POS-EXPORT | ' + w.Name + ' | ' + w.agf__Status__c + ' | ' + w.agf__Epic__r.Name + ' | '
        + w.CreatedDate.format('dd/MM HH:mm') + ' | ' + w.CreatedBy.Name + ' | ' + w.agf__Subject__c);
}
System.debug('VAL10| TOTAL DE WORKS NA ORG: ' + [SELECT COUNT() FROM agf__ADM_Work__c]);

// --- 4. objeto de Acceptance Criteria (lista relacionada "Acceptance Criteria" da work)
for (String api : Schema.getGlobalDescribe().keySet()) {
    if (!api.startsWith('agf__')) continue;
    if (!(api.contains('accept') || api.contains('criter'))) continue;
    Schema.DescribeSObjectResult d = Schema.getGlobalDescribe().get(api).getDescribe();
    System.debug('VAL10| AC-OBJETO | ' + d.getName() + ' | label=' + d.getLabel() + ' | createable=' + d.isCreateable());
    for (String f : d.fields.getMap().keySet()) {
        Schema.DescribeFieldResult fd = d.fields.getMap().get(f).getDescribe();
        if (!fd.isCreateable() && fd.getType() != Schema.DisplayType.ID) continue;
        String pl = '';
        if (fd.getType() == Schema.DisplayType.PICKLIST) {
            for (Schema.PicklistEntry pe : fd.getPicklistValues()) pl += pe.getValue() + ';';
        }
        System.debug('VAL10| AC-CAMPO | ' + d.getName() + ' | ' + fd.getName() + ' | ' + fd.getType()
            + (fd.getType() == Schema.DisplayType.REFERENCE ? ' -> ' + fd.getReferenceTo() : '')
            + (pl == '' ? '' : ' | valores=' + pl) + (fd.isNillable() ? '' : ' | OBRIGATORIO'));
    }
}
// contagem de criterios ja cadastrados nas works B2B e na W-000087 (tela mostrou 3)
try {
    for (AggregateResult ar : Database.query('SELECT agf__Work__r.Name n, COUNT(Id) c FROM agf__ADM_Acceptance_Criterion__c '
            + 'WHERE agf__Work__r.Name IN (\'W-000087\',\'W-000096\',\'W-000097\',\'W-000098\',\'W-000099\',\'W-000100\',\'W-000101\','
            + '\'W-000119\',\'W-000120\',\'W-000122\',\'W-000123\',\'W-000124\',\'W-000125\') GROUP BY agf__Work__r.Name')) {
        System.debug('VAL10| AC-EXISTENTES | ' + ar.get('n') + ' | ' + ar.get('c') + ' criterio(s)');
    }
} catch (Exception e) {
    System.debug('VAL10| AC-EXISTENTES | objeto agf__ADM_Acceptance_Criterion__c nao encontrado com esse nome: ' + e.getMessage()
        + ' | usar o nome listado em AC-OBJETO no script 12');
}
System.debug('VAL10| FIM');
