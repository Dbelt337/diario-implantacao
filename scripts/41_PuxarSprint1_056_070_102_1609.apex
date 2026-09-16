// 41 - Decisao pendente do script 39 (item c): W-000056 (QUAL-01), W-000070 (EPC-10) e W-000102 (CAT-TPL-01) entram na
// "Sprint 1 - SysMap (15-26/09)". So mexe em Sprint. NAO mexe em Priority (o script 40 v2 ja colocou o catalogo em P1;
// rodar o 39 de novo reverteria para P2/P3), nem em time, tag, epico, responsavel ou status. Trava se a work nao for do
// time SysMap. DUAS FASES: EXECUTAR = false so lista. Idempotente. Filtre o log por SPR41|.
Boolean EXECUTAR = false;
String  SPRINT_SYSMAP = 'Sprint 1 - SysMap (15-26/09)';
Set<String> works = new Set<String>{ 'W-000056', 'W-000070', 'W-000102' };

List<agf__ADM_Sprint__c> sp = [SELECT Id, Name, agf__Scrum_Team__r.Name FROM agf__ADM_Sprint__c WHERE Name = :SPRINT_SYSMAP LIMIT 1];
if (sp.isEmpty()) { System.debug('SPR41| SPRINT NAO ENCONTRADA: ' + SPRINT_SYSMAP + ' - nada alterado'); return; }
Id s1 = sp[0].Id;
System.debug('SPR41| sprint alvo: ' + sp[0].Name + ' (time ' + sp[0].agf__Scrum_Team__r.Name + ') | works ja na sprint: '
    + [SELECT COUNT() FROM agf__ADM_Work__c WHERE agf__Sprint__c = :s1]);

List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Priority__c, agf__Sprint__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name, agf__Status__c
                           FROM agf__ADM_Work__c WHERE Name IN :works ORDER BY Name]) {
    String linha = 'SPR41| ' + w.Name + ' | ' + w.agf__Subject__c.left(55) + ' | priority=' + w.agf__Priority__c + ' | status=' + w.agf__Status__c
        + ' | sprint=' + (w.agf__Sprint__c == null ? '(backlog)' : w.agf__Sprint__r.Name);
    if (w.agf__Scrum_Team__r.Name != 'SysMap') { System.debug(linha + ' | TRAVA: time=' + w.agf__Scrum_Team__r.Name + ' - nao alterada'); continue; }
    if (w.agf__Sprint__c == s1) { System.debug(linha + ' | sem mudanca'); continue; }
    System.debug(linha + ' | MUDA: sprint -> ' + SPRINT_SYSMAP);
    w.agf__Sprint__c = s1; upd.add(w);
}
System.debug('SPR41| a alterar: ' + upd.size() + ' work(s)');
if (!EXECUTAR) { System.debug('SPR41| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
update upd;
for (agf__ADM_Work__c w : [SELECT Name, agf__Priority__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name FROM agf__ADM_Work__c WHERE Name IN :works ORDER BY Name])
    System.debug('SPR41| DEPOIS ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | priority=' + w.agf__Priority__c + ' | sprint=' + w.agf__Sprint__r.Name);
System.debug('SPR41| DEPOIS works na sprint: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE agf__Sprint__c = :s1]);
System.debug('SPR41| concluido: ' + upd.size() + ' work(s) alterada(s).');
