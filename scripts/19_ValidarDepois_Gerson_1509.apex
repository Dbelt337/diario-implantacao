// 19 - Validacao final da rodada de 15/09 sobre as works do Gerson: W-000138/139 excluidas (script 14 fase 2), nota de
// consolidacao e sprint nas W-000051/052/055 (script 17) e Details + criterios nas W-000133 a 137, 140 e 141 (scripts 18a-g).
// Somente SELECT + System.debug. Filtre o log por VAL19|. Esperado: 0 problemas.
String MARCA = '--- CONSOLIDACAO 15/09: FILHAS POR FAMILIA (Modelagem v3; absorve W-000138 e W-000139) ---';
String SPRINT = 'Sprint 1 - SysMap (15-26/09)';
Integer problemas = 0;

for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c FROM agf__ADM_Work__c WHERE Name IN ('W-000138', 'W-000139')]) {
    System.debug('VAL19| PROBLEMA: ' + w.Name + ' ainda existe | ' + w.agf__Subject__c); problemas++;
}
for (agf__ADM_Work__c w : [SELECT Name, IsDeleted FROM agf__ADM_Work__c WHERE Name IN ('W-000138', 'W-000139') AND IsDeleted = true ALL ROWS]) {
    System.debug('VAL19| OK ' + w.Name + ' na Lixeira (restauravel por 15 dias)');
}
for (agf__ADM_Work__c w : [SELECT Name, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name FROM agf__ADM_Work__c WHERE Name IN ('W-000051', 'W-000052', 'W-000055') ORDER BY Name]) {
    Boolean nota = w.agf__Details__c != null && w.agf__Details__c.contains(MARCA);
    Boolean sp = w.agf__Sprint__r.Name == SPRINT;
    if (!nota || !sp) problemas++;
    System.debug('VAL19| ' + (nota && sp ? 'OK ' : 'PROBLEMA ') + w.Name + ' | nota=' + (nota ? 'sim' : 'FALTA') + ' | sprint=' + w.agf__Sprint__r.Name + ' | time=' + w.agf__Scrum_Team__r.Name);
}
Set<String> gerson = new Set<String>{'W-000133', 'W-000134', 'W-000135', 'W-000136', 'W-000137', 'W-000140', 'W-000141'};
Map<Id, Integer> qtd = new Map<Id, Integer>();
List<agf__ADM_Work__c> wg = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name, agf__Assignee__r.Name
                             FROM agf__ADM_Work__c WHERE Name IN :gerson ORDER BY Name];
for (agf__ADM_Acceptance_Criterion__c c : [SELECT agf__Work__c FROM agf__ADM_Acceptance_Criterion__c WHERE agf__Work__c IN :wg]) {
    qtd.put(c.agf__Work__c, (qtd.containsKey(c.agf__Work__c) ? qtd.get(c.agf__Work__c) : 0) + 1);
}
for (agf__ADM_Work__c w : wg) {
    Integer det = w.agf__Details__c == null ? 0 : w.agf__Details__c.length();
    Integer nc = qtd.containsKey(w.Id) ? qtd.get(w.Id) : 0;
    Boolean ok = det > 0 && nc >= 3;
    if (!ok) problemas++;
    System.debug('VAL19| ' + (ok ? 'OK ' : 'PROBLEMA ') + w.Name + ' | details=' + det + ' | criterios=' + nc + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | ' + w.agf__Subject__c.left(70));
}
if (wg.size() != 7) { System.debug('VAL19| PROBLEMA: esperava 7 works do Gerson, achou ' + wg.size()); problemas++; }
for (agf__ADM_Work__c w : [SELECT Name, agf__Sprint__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name FROM agf__ADM_Work__c WHERE Name IN ('W-000142', 'W-000143', 'W-000144', 'W-000145') ORDER BY Name]) {
    System.debug('VAL19| INFO ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + (w.agf__Sprint__c == null ? ' (sem sprint: definir)' : ''));
}
System.debug('VAL19| RESULTADO: ' + problemas + ' problema(s). Total de works na org: ' + [SELECT COUNT() FROM agf__ADM_Work__c]);
