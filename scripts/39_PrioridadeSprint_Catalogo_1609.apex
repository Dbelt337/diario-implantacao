// 39 - Fecha os pontos da "Validacao do Retorno do Especialista" do Gerson (16/09, v1) apos o script 38 (13 works de catalogo
// passaram a SysMap): (a) Priority nas works que estavam sem ("a setar"); (b) W-000053 e W-000054 estavam na "Sprint 1 - Brasil
// TecPar" com time SysMap: movem para a sprint da SysMap; (c) itens do criterio fora da Sprint 1 (056, 070, 102): entram na
// Sprint 1 so se PUXAR_PARA_SPRINT1 = true. Nao mexe em time, tag, epico, responsavel nem status. Nao toca nas works do
// Gerson (133 a 137, Brasil TecPar). DUAS FASES: EXECUTAR = false so lista. Idempotente. Filtre o log por PRI39|.
Boolean EXECUTAR = false;
Boolean PUXAR_PARA_SPRINT1 = false;                       // true = 056, 070 e 102 entram na Sprint 1 - SysMap
String  SPRINT_SYSMAP = 'Sprint 1 - SysMap (15-26/09)';
String  SPRINT_BTP    = 'Sprint 1 - Brasil TecPar (15-26/09)';

// work => { prioridade, sprint } ; sprint: 'S1' = Sprint 1 - SysMap, 'BACKLOG' = sem sprint (nao altera se ja estiver em alguma da SysMap), '' = nao mexe
Map<String, List<String>> plano = new Map<String, List<String>>{
    'W-000053' => new List<String>{ 'P1', 'S1' },        // EPC-05 Product Specifications da Onda 1 (fundacao; estava na sprint BTP)
    'W-000054' => new List<String>{ 'P2', 'S1' },        // EPC-09 compilacao/batch jobs (estava na sprint BTP)
    'W-000102' => new List<String>{ 'P2', 'BACKLOG' },   // CAT-TPL-01 template de carga (depende da decisao do metodo de carga)
    'W-000056' => new List<String>{ 'P2', 'BACKLOG' },   // QUAL-01 (ja P2)
    'W-000070' => new List<String>{ 'P2', 'BACKLOG' },   // EPC-10 (ja P2)
    'W-000103' => new List<String>{ 'P3', '' },          // CAT-MIG-01 migracao da base legada
    'W-000104' => new List<String>{ 'P3', '' },          // CAT-TAG-01 Service Tag
    'W-000108' => new List<String>{ 'P3', '' },          // CAT-PRC-01 desconto combos
    'W-000111' => new List<String>{ 'P3', '' },          // CAT-FAM-01 Movel/Streaming/Camera
    'W-000112' => new List<String>{ 'P3', '' },          // CAT-CHD-01 produtos filhos
    'W-000113' => new List<String>{ 'P3', '' },          // CAT-API-01 cache das APIs
    'W-000114' => new List<String>{ 'P3', '' },          // CAT-ZON-01 zonas IBGE
    'W-000121' => new List<String>{ 'P3', '' },          // CAT-CPX-01 Taxa Unica
    'W-000127' => new List<String>{ 'P3', '' },          // CAT-EQP-01 CPE
    'W-000128' => new List<String>{ 'P3', '' }           // CAT-RET-01 promotions de retencao
};

// valores validos de Priority na org
Set<String> prios = new Set<String>();
for (Schema.PicklistEntry p : agf__ADM_Work__c.agf__Priority__c.getDescribe().getPicklistValues()) if (p.isActive()) prios.add(p.getValue());
System.debug('PRI39| valores de Priority: ' + prios);
Map<String, agf__ADM_Sprint__c> sprints = new Map<String, agf__ADM_Sprint__c>();
for (agf__ADM_Sprint__c s : [SELECT Id, Name, agf__Scrum_Team__r.Name FROM agf__ADM_Sprint__c WHERE Name IN (:SPRINT_SYSMAP, :SPRINT_BTP)]) sprints.put(s.Name, s);
if (!sprints.containsKey(SPRINT_SYSMAP)) { System.debug('PRI39| SPRINT NAO ENCONTRADA: ' + SPRINT_SYSMAP + ' - nada alterado'); return; }
Id s1 = sprints.get(SPRINT_SYSMAP).Id;
Id sbtp = sprints.containsKey(SPRINT_BTP) ? sprints.get(SPRINT_BTP).Id : null;

List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Priority__c, agf__Sprint__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN :plano.keySet() ORDER BY Name]) {
    List<String> p = plano.get(w.Name);
    String prio = p[0], regra = p[1];
    List<String> mud = new List<String>();
    if (w.agf__Scrum_Team__r.Name != 'SysMap') { System.debug('PRI39| ' + w.Name + ' | TRAVA: time=' + w.agf__Scrum_Team__r.Name + ' (rode o script 38 antes) - nao alterada'); continue; }
    if (String.isNotBlank(prio) && !prios.contains(prio)) { System.debug('PRI39| ' + w.Name + ' | TRAVA: prioridade ' + prio + ' nao existe na picklist'); continue; }
    if (String.isNotBlank(prio) && w.agf__Priority__c != prio) { mud.add('priority ' + w.agf__Priority__c + ' -> ' + prio); w.agf__Priority__c = prio; }
    Boolean naSprintBtp = sbtp != null && w.agf__Sprint__c == sbtp;
    if (regra == 'S1' || (regra == 'BACKLOG' && PUXAR_PARA_SPRINT1)) {
        if (w.agf__Sprint__c != s1) { mud.add('sprint ' + w.agf__Sprint__r.Name + ' -> ' + SPRINT_SYSMAP); w.agf__Sprint__c = s1; }
    } else if (naSprintBtp) {
        mud.add('sprint ' + w.agf__Sprint__r.Name + ' -> (backlog): sprint de outro time'); w.agf__Sprint__c = null;
    }
    System.debug('PRI39| ' + w.Name + ' | ' + w.agf__Subject__c.left(55) + ' | priority=' + w.agf__Priority__c + ' | sprint=' + w.agf__Sprint__r.Name
        + (mud.isEmpty() ? ' | sem mudanca' : ' | MUDA: ' + String.join(mud, '; ')));
    if (!mud.isEmpty()) upd.add(w);
}
System.debug('PRI39| a alterar: ' + upd.size() + ' work(s)');
if (!EXECUTAR) { System.debug('PRI39| FASE 1 concluida: nada alterado. Confira o plano e rode com EXECUTAR = true.'); return; }
update upd;
for (agf__ADM_Work__c w : [SELECT Name, agf__Priority__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name FROM agf__ADM_Work__c WHERE Name IN :plano.keySet() ORDER BY Name])
    System.debug('PRI39| DEPOIS ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | priority=' + w.agf__Priority__c + ' | sprint=' + w.agf__Sprint__r.Name);
System.debug('PRI39| concluido: ' + upd.size() + ' work(s) alterada(s).');
