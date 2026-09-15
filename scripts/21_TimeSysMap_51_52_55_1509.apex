// 21 - Muda o Scrum Team das works-mae de catalogo (W-000051, W-000052, W-000055) de Brasil TecPar para SysMap, decisao do
// Diego em 15/09 (as tres estao na "Sprint 1 - SysMap (15-26/09)" e o responsavel e o Davi, SysMap). No Agile Accelerator o
// time da work e amarrado ao Product Tag, por isso copia time E tag da work de referencia W-000122 (SysMap, tag Salesforce),
// e reconsulta depois do update para confirmar que o pacote nao devolveu o time antigo. Idempotente. Filtre o log por TIM21|.
agf__ADM_Work__c ref = [SELECT agf__Scrum_Team__c, agf__Scrum_Team__r.Name, agf__Product_Tag__c, agf__Product_Tag__r.Name
                        FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];
if (ref.agf__Scrum_Team__r.Name != 'SysMap') { System.debug('TIM21| referencia W-000122 nao e SysMap (' + ref.agf__Scrum_Team__r.Name + ') - nada alterado'); return; }
System.debug('TIM21| referencia W-000122 | time=' + ref.agf__Scrum_Team__r.Name + ' | tag=' + ref.agf__Product_Tag__r.Name);

List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Scrum_Team__c, agf__Scrum_Team__r.Name, agf__Product_Tag__c, agf__Product_Tag__r.Name,
                                  agf__Sprint__r.Name, agf__Assignee__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN ('W-000051', 'W-000052', 'W-000055') ORDER BY Name]) {
    System.debug('TIM21| ' + w.Name + ' | antes: time=' + w.agf__Scrum_Team__r.Name + ' | tag=' + w.agf__Product_Tag__r.Name
        + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name);
    if (w.agf__Scrum_Team__c == ref.agf__Scrum_Team__c && w.agf__Product_Tag__c == ref.agf__Product_Tag__c) { System.debug('TIM21| ' + w.Name + ' | ja e SysMap'); continue; }
    w.agf__Scrum_Team__c = ref.agf__Scrum_Team__c;
    w.agf__Product_Tag__c = ref.agf__Product_Tag__c;
    upd.add(w);
}
if (!upd.isEmpty()) update upd;
Integer ok = 0;
for (agf__ADM_Work__c w : [SELECT Name, agf__Scrum_Team__r.Name, agf__Product_Tag__r.Name, agf__Sprint__r.Name FROM agf__ADM_Work__c WHERE Name IN ('W-000051', 'W-000052', 'W-000055') ORDER BY Name]) {
    Boolean bateu = w.agf__Scrum_Team__r.Name == 'SysMap';
    if (bateu) ok++;
    System.debug('TIM21| DEPOIS ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | tag=' + w.agf__Product_Tag__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + (bateu ? '' : ' | PROBLEMA: time nao mudou (trigger do pacote?)'));
}
System.debug('TIM21| concluido: ' + upd.size() + ' atualizada(s), ' + ok + ' de 3 com time SysMap.');
