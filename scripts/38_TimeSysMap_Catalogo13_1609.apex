// 38 - Muda o Scrum Team das 13 works de catalogo que estavam como time Salesforce (W-000053, 054, 102, 103, 104, 108, 111, 112,
// 113, 114, 121, 127, 128) para SysMap, decisao do Diego em 16/09: a SysMap cobre catalogo, B2B e B2C; so as 5 works do Gerson
// (W-000133 a 137) ficam em Brasil TecPar. Mesmo mecanismo do script 21: copia time E Product Tag da work de referencia W-000122
// (SysMap, tag Salesforce) e reconsulta depois. Nao mexe em sprint nem responsavel. Idempotente. Filtre o log por TIM38|.
agf__ADM_Work__c ref = [SELECT agf__Scrum_Team__c, agf__Scrum_Team__r.Name, agf__Product_Tag__c, agf__Product_Tag__r.Name
                        FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];
if (ref.agf__Scrum_Team__r.Name != 'SysMap') { System.debug('TIM38| referencia W-000122 nao e SysMap (' + ref.agf__Scrum_Team__r.Name + ') - nada alterado'); return; }
System.debug('TIM38| referencia W-000122 | time=' + ref.agf__Scrum_Team__r.Name + ' | tag=' + ref.agf__Product_Tag__r.Name);

List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Scrum_Team__c, agf__Scrum_Team__r.Name, agf__Product_Tag__c, agf__Product_Tag__r.Name,
                                  agf__Sprint__r.Name, agf__Assignee__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN ('W-000053', 'W-000054', 'W-000102', 'W-000103', 'W-000104', 'W-000108', 'W-000111', 'W-000112', 'W-000113', 'W-000114', 'W-000121', 'W-000127', 'W-000128') ORDER BY Name]) {
    System.debug('TIM38| ' + w.Name + ' | antes: time=' + w.agf__Scrum_Team__r.Name + ' | tag=' + w.agf__Product_Tag__r.Name
        + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name);
    if (w.agf__Scrum_Team__c == ref.agf__Scrum_Team__c && w.agf__Product_Tag__c == ref.agf__Product_Tag__c) { System.debug('TIM38| ' + w.Name + ' | ja e SysMap'); continue; }
    w.agf__Scrum_Team__c = ref.agf__Scrum_Team__c;
    w.agf__Product_Tag__c = ref.agf__Product_Tag__c;
    upd.add(w);
}
if (!upd.isEmpty()) update upd;
Integer ok = 0;
for (agf__ADM_Work__c w : [SELECT Name, agf__Scrum_Team__r.Name, agf__Product_Tag__r.Name, agf__Sprint__r.Name FROM agf__ADM_Work__c WHERE Name IN ('W-000053', 'W-000054', 'W-000102', 'W-000103', 'W-000104', 'W-000108', 'W-000111', 'W-000112', 'W-000113', 'W-000114', 'W-000121', 'W-000127', 'W-000128') ORDER BY Name]) {
    Boolean bateu = w.agf__Scrum_Team__r.Name == 'SysMap';
    if (bateu) ok++;
    System.debug('TIM38| DEPOIS ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | tag=' + w.agf__Product_Tag__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + (bateu ? '' : ' | PROBLEMA: time nao mudou (trigger do pacote?)'));
}
System.debug('TIM38| concluido: ' + upd.size() + ' atualizada(s), ' + ok + ' de 13 com time SysMap.');
