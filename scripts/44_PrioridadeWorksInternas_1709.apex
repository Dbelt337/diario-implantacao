// 44 - Prioridade das 8 works internas antigas do BTP que estavam sem Priority (revisao de 17/09, item 5).
// Decisao do Diego em 17/09: "prioridade baixa" = P4 (menor valor ativo da picklist agf__Priority__c).
// Works: 010, 011, 018, 019, 023, 025, 028 (Brasil TecPar) e 021 (GOVERNANCA). So preenche se estiver vazia; nao mexe em
// sprint, epico, PO, responsavel nem status (as 6 presas em sprint de junho/julho ficam como estao ate o Gerson decidir).
// DUAS FASES: EXECUTAR = false so lista. Filtre o log por PRI44|.
Boolean EXECUTAR = false;
String  PRIO = 'P4';
Set<String> works = new Set<String>{ 'W-000010', 'W-000011', 'W-000018', 'W-000019', 'W-000021', 'W-000023', 'W-000025', 'W-000028' };
Set<String> prios = new Set<String>();
for (Schema.PicklistEntry p : agf__ADM_Work__c.agf__Priority__c.getDescribe().getPicklistValues()) if (p.isActive()) prios.add(p.getValue());
System.debug('PRI44| valores ativos de Priority: ' + prios);
if (!prios.contains(PRIO)) { System.debug('PRI44| TRAVA: ' + PRIO + ' nao existe na picklist - nada alterado'); return; }
List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Priority__c, agf__Status__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN :works ORDER BY Name]) {
    String linha = 'PRI44| ' + w.Name + ' | ' + w.agf__Scrum_Team__r.Name + ' | ' + w.agf__Status__c + ' | sprint=' + (w.agf__Sprint__c == null ? '(backlog)' : w.agf__Sprint__r.Name) + ' | ' + w.agf__Subject__c.left(45);
    if (String.isNotBlank(w.agf__Priority__c)) { System.debug(linha + ' | ja tem priority ' + w.agf__Priority__c + ' - nao sobrescreve'); continue; }
    System.debug(linha + ' | MUDA: priority (vazio) -> ' + PRIO);
    w.agf__Priority__c = PRIO; upd.add(w);
}
System.debug('PRI44| a alterar: ' + upd.size() + ' work(s)');
if (!EXECUTAR) { System.debug('PRI44| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
update upd;
for (agf__ADM_Work__c w : [SELECT Name, agf__Priority__c, agf__Status__c FROM agf__ADM_Work__c WHERE Name IN :works ORDER BY Name])
    System.debug('PRI44| DEPOIS ' + w.Name + ' | priority=' + w.agf__Priority__c + ' | ' + w.agf__Status__c);
System.debug('PRI44| DEPOIS works abertas sem priority na org: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE agf__Priority__c = null AND agf__Status__c != 'Closed']);
System.debug('PRI44| concluido: ' + upd.size() + ' work(s) alterada(s).');
