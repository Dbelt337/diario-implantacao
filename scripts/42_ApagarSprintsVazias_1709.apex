// 42 - Apaga as 5 sprints antigas do Agile Accelerator que ficaram vazias (revisao de 17/09 para o Gerson, item 7):
// 4 sem nenhuma work e 1 com data invertida (Julho/2026-Time SysMap-1a e 2a Sem: inicio 01/07, fim 15/06).
// Trava: so apaga se a sprint tiver ZERO works (inclusive fechadas). Nao toca nas sprints com works
// (Junho/2026-Time Salesforce, Julho/2026-Time Salesforce, Sprint 1 a 4). Idempotente: se ja nao existir, pula.
// DUAS FASES: EXECUTAR = false so lista. Filtre o log por SPR42|.
Boolean EXECUTAR = false;
Set<String> alvo = new Set<String>{
    'Junho/2026-Time SysMap-3a e 4a Sem',
    'Julho/2026-Time SysMap-1a e 2a Sem',
    'Julho/2026-Time SysMap-3a e 4a Sem',
    'Sprint Catálogo - 1a e 2a Semana',
    'Sprint Catálogo - 3 e 4 Semana'
};
List<agf__ADM_Sprint__c> apagar = new List<agf__ADM_Sprint__c>();
Set<String> achadas = new Set<String>();
for (agf__ADM_Sprint__c s : [SELECT Id, Name, agf__Scrum_Team__r.Name, agf__Start_Date__c, agf__End_Date__c,
                              (SELECT Id, Name FROM agf__Work__r) FROM agf__ADM_Sprint__c WHERE Name IN :alvo ORDER BY Name]) {
    achadas.add(s.Name);
    Integer n = s.agf__Work__r.size();
    String linha = 'SPR42| ' + s.Name + ' | ' + s.agf__Scrum_Team__r.Name + ' | ' + s.agf__Start_Date__c + ' a ' + s.agf__End_Date__c + ' | works=' + n;
    if (n > 0) { System.debug(linha + ' | TRAVA: tem work, nao apaga'); continue; }
    System.debug(linha + ' | APAGAR');
    apagar.add(s);
}
for (String nm : alvo) if (!achadas.contains(nm)) System.debug('SPR42| ' + nm + ' | ja nao existe');
System.debug('SPR42| a apagar: ' + apagar.size() + ' sprint(s)');
if (!EXECUTAR) { System.debug('SPR42| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
delete apagar;
System.debug('SPR42| DEPOIS sprints restantes: ' + [SELECT COUNT() FROM agf__ADM_Sprint__c]);
for (agf__ADM_Sprint__c s : [SELECT Name FROM agf__ADM_Sprint__c ORDER BY agf__Start_Date__c]) System.debug('SPR42| DEPOIS ' + s.Name);
System.debug('SPR42| concluido: ' + apagar.size() + ' sprint(s) apagada(s) (ficam 15 dias na lixeira).');
