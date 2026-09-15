// 20 - Aloca as quatro works B2B novas (W-000142 a W-000145, criadas em 15/09) na sprint da squad SysMap, condicao do Gerson
// ("fique na sprint e alocada a Squad certa"). Idempotente: so altera quem estiver fora da sprint; nao mexe em time, epico,
// responsavel nem status. Travas: sprint precisa existir; work precisa ser do time SysMap e ter Subject comecando com "US B2B-1".
// Para outra sprint, troque so a constante SPRINT. Filtre o log por SPR20|.
String SPRINT = 'Sprint 1 - SysMap (15-26/09)';
Set<String> alvo = new Set<String>{'W-000142', 'W-000143', 'W-000144', 'W-000145'};

List<agf__ADM_Sprint__c> sps = [SELECT Id, Name, agf__Scrum_Team__r.Name, agf__Start_Date__c, agf__End_Date__c FROM agf__ADM_Sprint__c WHERE Name = :SPRINT LIMIT 1];
if (sps.isEmpty()) { System.debug('SPR20| SPRINT NAO ENCONTRADA: ' + SPRINT + ' - nada alterado'); return; }
System.debug('SPR20| sprint ' + sps[0].Name + ' | time da sprint=' + sps[0].agf__Scrum_Team__r.Name + ' | ' + sps[0].agf__Start_Date__c + ' a ' + sps[0].agf__End_Date__c);

List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
Integer achadas = 0;
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Sprint__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name, agf__Assignee__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN :alvo ORDER BY Name]) {
    achadas++;
    Boolean timeOk = w.agf__Scrum_Team__r.Name == 'SysMap';
    Boolean subjOk = w.agf__Subject__c != null && w.agf__Subject__c.startsWith('US B2B-1');
    if (!timeOk || !subjOk) { System.debug('SPR20| ' + w.Name + ' | TRAVA: time=' + w.agf__Scrum_Team__r.Name + ' | ' + w.agf__Subject__c + ' - nao alterada'); continue; }
    if (w.agf__Sprint__c == sps[0].Id) { System.debug('SPR20| ' + w.Name + ' | ja esta na sprint ' + SPRINT); continue; }
    System.debug('SPR20| ' + w.Name + ' | sprint antes=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | ALOCA');
    w.agf__Sprint__c = sps[0].Id; upd.add(w);
}
if (achadas != 4) System.debug('SPR20| ATENCAO: esperava 4 works, achou ' + achadas);
if (!upd.isEmpty()) update upd;
for (agf__ADM_Work__c w : [SELECT Name, agf__Sprint__r.Name, agf__Scrum_Team__r.Name FROM agf__ADM_Work__c WHERE Name IN :alvo ORDER BY Name]) {
    System.debug('SPR20| DEPOIS ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | sprint=' + w.agf__Sprint__r.Name);
}
System.debug('SPR20| concluido: ' + upd.size() + ' work(s) alocada(s).');
