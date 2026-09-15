// 13 - VALIDACAO FINAL das works B2B-13 a B2B-16 (rodar por ultimo). Esperado: 4 works OK e 32 criterios (9+8+7+8).
// Somente SELECT + System.debug. Filtre o log por VAL13| e mande as linhas + RESULTADO.
String OBJ = 'agf__ADM_Acceptance_Criterion__c';   // mesmo nome usado no script 12
String F_WORK = 'agf__Work__c';

Map<String, Integer> esperado = new Map<String, Integer>{ 'US B2B-13%' => 9, 'US B2B-14%' => 8, 'US B2B-15%' => 7, 'US B2B-16%' => 8 };
Map<String, List<String>> marcas = new Map<String, List<String>>{
    'US B2B-13%' => new List<String>{ 'RN-12', 'Amend Frame Agreement', 'Contract State Model', 'Repricing Batch Processor' },
    'US B2B-14%' => new List<String>{ 'RN-11', 'Point of No Return', 'scheduled path', 'case Salesforce 473919801' },
    'US B2B-15%' => new List<String>{ 'RN-09', 'pricing variable', 'Billing Frequency', 'record lock' },
    'US B2B-16%' => new List<String>{ 'RN-12', 'DocuSignReminderEnabled', 'Salesforce Data Event', 'Re-entry only after exiting', 'Organization-Wide Email Address' }
};
agf__ADM_Work__c ref = [SELECT agf__Epic__c, agf__Scrum_Team__c, RecordTypeId FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];

Integer ok = 0, falta = 0, dup = 0;
for (String prefixo : esperado.keySet()) {
    List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Status__c, agf__Details__c, RecordTypeId,
                                        agf__Epic__c, agf__Epic__r.Name, agf__Scrum_Team__c, agf__Scrum_Team__r.Name,
                                        agf__Product_Tag__r.Name, agf__Assignee__r.Name
                                 FROM agf__ADM_Work__c WHERE agf__Subject__c LIKE :prefixo];
    if (ws.isEmpty()) { System.debug('VAL13| ' + prefixo + ' | FALTA | work nao criada'); falta++; continue; }
    if (ws.size() > 1) { System.debug('VAL13| ' + prefixo + ' | DUPLICADO x' + ws.size()); dup++; }
    agf__ADM_Work__c w = ws[0];
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    Boolean camposOk = w.agf__Epic__c == ref.agf__Epic__c && w.agf__Scrum_Team__c == ref.agf__Scrum_Team__c
        && w.RecordTypeId == ref.RecordTypeId && det.length() > 4000;
    System.debug('VAL13| ' + prefixo + ' | ' + (camposOk ? 'OK' : 'INCOMPLETA') + ' | ' + w.Name + ' | epic=' + w.agf__Epic__r.Name
        + ' | time=' + w.agf__Scrum_Team__r.Name + ' | tag=' + w.agf__Product_Tag__r.Name + ' | assignee=' + w.agf__Assignee__r.Name
        + ' | status=' + w.agf__Status__c + ' | details=' + det.length() + ' chars');
    if (camposOk) ok++; else falta++;
    for (String m : marcas.get(prefixo)) {
        Boolean tem = det.contains(m);
        System.debug('VAL13|    ' + w.Name + ' | ' + (tem ? 'OK' : 'FALTA') + ' | conteudo: ' + m);
        if (tem) ok++; else falta++;
    }
    Integer n = 0;
    try {
        n = Database.countQuery('SELECT COUNT() FROM ' + OBJ + ' WHERE ' + F_WORK + ' = \'' + w.Id + '\'');
        for (SObject c : Database.query('SELECT Name FROM ' + OBJ + ' WHERE ' + F_WORK + ' = \'' + w.Id + '\' ORDER BY Name')) {
            System.debug('VAL13|    ' + w.Name + ' | criterio | ' + c.get('Name'));
        }
    } catch (Exception e) { System.debug('VAL13|    ' + w.Name + ' | ERRO ao ler criterios: ' + e.getMessage()); }
    String r = n == esperado.get(prefixo) ? 'OK' : (n < esperado.get(prefixo) ? 'FALTA' : 'DUPLICADO');
    System.debug('VAL13|    ' + w.Name + ' | ' + r + ' | criterios=' + n + ' esperado=' + esperado.get(prefixo));
    if (r == 'OK') ok++; else if (r == 'FALTA') falta++; else dup++;
}
System.debug('VAL13| RESULTADO: ' + ok + ' OK, ' + falta + ' FALTANDO, ' + dup + ' DUPLICADOS (esperado 25 OK)');
