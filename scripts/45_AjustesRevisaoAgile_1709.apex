// 45 - Ajustes das pendencias da revisao Agile de 17/09 (docs/2026-09-17-revisao-agile-gerson.md), decisao delegada pelo
// Diego ("pode tomar a decisao, ajusta"). Criterio: a regra do Diego de 16/09 manda na sequencia (pos-venda por ultimo);
// a regua de higiene do Gerson manda no resto (prioridade = sprint, P0 em sprint, interna fora de sprint e com sufixo -i).
//  a) W-000123 (B2B-10 visao 360) e W-000124 (B2B-11 fim de degustacao): pos-venda -> Sprint 4 - SysMap, P4.
//  b) W-000132 (TEC-DEV-01 CI/CD, P0): entra na Sprint 1 - SysMap (P0 nao fica fora de sprint; par da 133 do BTP).
//  c) W-000056, 070, 102 (catalogo, P1): proxima onda = Sprint 2 - SysMap; prioridade fica P1.
//  d) W-000024, 026, 028: epico "Projetos Internos".
//  e) Internas abertas presas em sprint de junho/julho (010, 011, 018, 019, 023, 025): saem para o backlog. Fechadas ficam.
//  f) Internas (010 a 028, 18 works): sufixo " -i" no assunto, se ainda nao tiver.
// Nao mexe em time, responsavel, PO, status, tag, nem nas demais prioridades. Idempotente. DUAS FASES: EXECUTAR = false so lista.
// Filtre o log por AJ45|.
Boolean EXECUTAR = false;
Map<String, Id> sprints = new Map<String, Id>();
for (agf__ADM_Sprint__c s : [SELECT Id, Name FROM agf__ADM_Sprint__c WHERE Name LIKE 'Sprint % - SysMap%']) sprints.put(s.Name.substringBefore(' ('), s.Id);
Id s1 = sprints.get('Sprint 1 - SysMap'), s2 = sprints.get('Sprint 2 - SysMap'), s4 = sprints.get('Sprint 4 - SysMap');
if (s1 == null || s2 == null || s4 == null) { System.debug('AJ45| TRAVA: sprint nao encontrada ' + sprints.keySet() + ' - nada alterado'); return; }
List<agf__ADM_Epic__c> eps = [SELECT Id FROM agf__ADM_Epic__c WHERE Name = 'Projetos Internos' LIMIT 1];
if (eps.isEmpty()) { System.debug('AJ45| TRAVA: epico Projetos Internos nao encontrado'); return; }
Id epInt = eps[0].Id;

Map<String, Id> sprintAlvo = new Map<String, Id>{ 'W-000123' => s4, 'W-000124' => s4, 'W-000132' => s1, 'W-000056' => s2, 'W-000070' => s2, 'W-000102' => s2 };
Map<String, String> prioAlvo = new Map<String, String>{ 'W-000123' => 'P4', 'W-000124' => 'P4' };
Set<String> epicoInt = new Set<String>{ 'W-000024', 'W-000026', 'W-000028' };
Set<String> tirarSprint = new Set<String>{ 'W-000010', 'W-000011', 'W-000018', 'W-000019', 'W-000023', 'W-000025' };
Set<String> internas = new Set<String>();
for (Integer i = 10; i <= 28; i++) internas.add('W-0000' + i);
Set<String> todas = new Set<String>(); todas.addAll(sprintAlvo.keySet()); todas.addAll(epicoInt); todas.addAll(tirarSprint); todas.addAll(internas);

List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Priority__c, agf__Sprint__c, agf__Sprint__r.Name, agf__Epic__c, agf__Epic__r.Name,
                                  agf__Status__c, agf__Scrum_Team__r.Name FROM agf__ADM_Work__c WHERE Name IN :todas ORDER BY Name]) {
    List<String> mud = new List<String>();
    if (sprintAlvo.containsKey(w.Name) && w.agf__Sprint__c != sprintAlvo.get(w.Name)) {
        if (w.agf__Scrum_Team__r.Name != 'SysMap') { System.debug('AJ45| ' + w.Name + ' | TRAVA: time ' + w.agf__Scrum_Team__r.Name + ', nao entra em sprint SysMap'); }
        else { mud.add('sprint ' + (w.agf__Sprint__c == null ? '(backlog)' : w.agf__Sprint__r.Name) + ' -> ' + [SELECT Name FROM agf__ADM_Sprint__c WHERE Id = :sprintAlvo.get(w.Name)].Name); w.agf__Sprint__c = sprintAlvo.get(w.Name); }
    }
    if (prioAlvo.containsKey(w.Name) && w.agf__Priority__c != prioAlvo.get(w.Name)) { mud.add('priority ' + w.agf__Priority__c + ' -> ' + prioAlvo.get(w.Name)); w.agf__Priority__c = prioAlvo.get(w.Name); }
    if (epicoInt.contains(w.Name) && w.agf__Epic__c == null) { mud.add('epico (vazio) -> Projetos Internos'); w.agf__Epic__c = epInt; }
    if (tirarSprint.contains(w.Name) && w.agf__Sprint__c != null && w.agf__Status__c != 'Closed') { mud.add('sprint ' + w.agf__Sprint__r.Name + ' -> (backlog)'); w.agf__Sprint__c = null; }
    if (internas.contains(w.Name) && !w.agf__Subject__c.trim().endsWith('-i')) { mud.add('assunto + " -i"'); w.agf__Subject__c = w.agf__Subject__c.trim() + ' -i'; }
    System.debug('AJ45| ' + w.Name + ' | ' + w.agf__Status__c + ' | ' + (w.agf__Priority__c == null ? '-' : w.agf__Priority__c) + ' | ' + w.agf__Subject__c.left(40)
        + (mud.isEmpty() ? ' | sem mudanca' : ' | MUDA: ' + String.join(mud, '; ')));
    if (!mud.isEmpty()) upd.add(w);
}
System.debug('AJ45| a alterar: ' + upd.size() + ' work(s)');
if (!EXECUTAR) { System.debug('AJ45| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
update upd;
for (AggregateResult ar : [SELECT agf__Sprint__r.Name sp, COUNT(Id) n FROM agf__ADM_Work__c WHERE agf__Sprint__c != null GROUP BY agf__Sprint__r.Name ORDER BY agf__Sprint__r.Name])
    System.debug('AJ45| DEPOIS ' + ar.get('sp') + ': ' + ar.get('n') + ' work(s)');
System.debug('AJ45| DEPOIS P0 fora de sprint: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE agf__Priority__c = 'P0' AND agf__Sprint__c = null]);
System.debug('AJ45| DEPOIS sem epico: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE agf__Epic__c = null]);
System.debug('AJ45| DEPOIS internas abertas em sprint: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE Name IN :internas AND agf__Sprint__c != null AND agf__Status__c != 'Closed']);
System.debug('AJ45| DEPOIS internas sem -i: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE Name IN :internas AND (NOT agf__Subject__c LIKE '%-i')]);
System.debug('AJ45| concluido: ' + upd.size() + ' work(s) alterada(s).');
