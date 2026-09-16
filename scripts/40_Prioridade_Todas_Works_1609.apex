// 40 - Reordena a Priority de TODAS as works do pacote validado (93) pela regra do Diego (16/09, v2): P0 licenciamento, ambiente
// e esteira de CI/CD; P1 fundacao + catalogo (ha squad de catalogo) + integracoes de base (correm em paralelo); P2 lead e
// oportunidade; P3 cotacao, pedido, contrato, ativacao e instalacao; P4 pos-venda (retencao, cancelamento, MACD, 360, dashboards). Nao mexe em sprint, time, tag, epico, responsavel
// nem status. INCLUIR_BTP = false deixa as 5 works do Gerson (133 a 137) de fora. DUAS FASES: EXECUTAR = false so lista.
// Idempotente. Filtre o log por PRI40|.
Boolean EXECUTAR = false;
Boolean INCLUIR_BTP = true;

Map<String, String> plano = new Map<String, String>();
void p(String prio, List<String> ws) { for (String w : ws) plano.put(w, prio); }
// P0 - licenciamento, ambiente e esteira de CI/CD
p('P0', new List<String>{ 'W-000134',                          // licenciamento OM e sandboxes (Gerson)
                          'W-000140',                          // habilitar integracao B2B para testes (urgente)
                          'W-000132', 'W-000133' });           // esteira CI/CD (TEC-DEV-01 e Gerson)
// P1 - fundacao + catalogo (squad de catalogo) + integracoes de base (em paralelo)
p('P1', new List<String>{ 'W-000051', 'W-000052', 'W-000053', 'W-000054', 'W-000055',   // EPC-01/04/05/09/03
                          'W-000102', 'W-000117',                                     // CAT-TPL-01 template; CAT-ACC-01 modelo de contas
                          'W-000087', 'W-000090', 'W-000092', 'W-000086',             // TEC-B2C-04 integracoes, -07 seguranca, -09 MKT Cloud, -03 esqueleto OmniScript
                          'W-000070', 'W-000056', 'W-000085', 'W-000107',             // EPC-10, QUAL-01, TEC-B2C-02 modelagem EPC B2C, CPQ-BRE-01
                          'W-000103', 'W-000104', 'W-000108', 'W-000111', 'W-000112', 'W-000113', 'W-000114', 'W-000121', 'W-000127', 'W-000128',
                          'W-000105', 'W-000110', 'W-000130', 'W-000131',             // TEC-INT-01 a 04
                          'W-000135', 'W-000136', 'W-000137',                         // MuleSoft, APIs B2B, camada tecnica catalogo/OM (Gerson)
                          'W-000141' });                                              // historias B2B / onboarding
// P2 - lead e oportunidade
p('P2', new List<String>{ 'W-000057', 'W-000058', 'W-000059', 'W-000060', 'W-000062', 'W-000064', 'W-000066', 'W-000067',   // B2C-01,02,03,04,06,08,10,11
                          'W-000071', 'W-000072', 'W-000073', 'W-000074', 'W-000083', 'W-000091',                           // B2C-14,15,16,17,26; TEC-B2C-08 roteamento
                          'W-000096', 'W-000097', 'W-000119', 'W-000120' });                                                // B2B-01,02,07,08
// P3 - cotacao, pedido, contrato, ativacao e instalacao
p('P3', new List<String>{ 'W-000084', 'W-000069', 'W-000065', 'W-000068', 'W-000075', 'W-000076', 'W-000077', 'W-000078',   // create cart, selecao guiada, resumo, taxa, touchless, emissao, pagamento, baixa
                          'W-000080', 'W-000081', 'W-000082', 'W-000088', 'W-000089', 'W-000093', 'W-000094', 'W-000063',   // ativacao, faturamento, minuta, OM, docgen, provisionamento, work order, field service
                          'W-000098', 'W-000101', 'W-000106', 'W-000115', 'W-000118', 'W-000122', 'W-000144', 'W-000145' }); // B2B-03, B2B-06, templates contrato, tipos sem faturamento, TEC-OM-01, B2B-09, B2B-15, B2B-16
// P4 - pos-venda (retencao, cancelamento, MACD, visao 360, dashboards e relatorios)
p('P4', new List<String>{ 'W-000099', 'W-000100', 'W-000109', 'W-000116', 'W-000123', 'W-000124', 'W-000125', 'W-000126',
                          'W-000129', 'W-000142', 'W-000143', 'W-000061', 'W-000079', 'W-000095' });
if (!INCLUIR_BTP) for (String w : new List<String>{ 'W-000133', 'W-000134', 'W-000135', 'W-000136', 'W-000137' }) plano.remove(w);
System.debug('PRI40| plano: ' + plano.size() + ' works');

Set<String> prios = new Set<String>();
for (Schema.PicklistEntry pe : agf__ADM_Work__c.agf__Priority__c.getDescribe().getPicklistValues()) if (pe.isActive()) prios.add(pe.getValue());
List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
Map<String, Integer> porPrio = new Map<String, Integer>(); Set<String> achadas = new Set<String>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Priority__c, agf__Scrum_Team__r.Name, agf__Sprint__r.Name FROM agf__ADM_Work__c WHERE Name IN :plano.keySet() ORDER BY Name]) {
    achadas.add(w.Name);
    String novo = plano.get(w.Name);
    if (!prios.contains(novo)) { System.debug('PRI40| ' + w.Name + ' | TRAVA: prioridade ' + novo + ' nao existe'); continue; }
    porPrio.put(novo, (porPrio.containsKey(novo) ? porPrio.get(novo) : 0) + 1);
    if (w.agf__Priority__c == novo) { System.debug('PRI40| ' + w.Name + ' | ' + novo + ' | sem mudanca | ' + w.agf__Subject__c.left(50)); continue; }
    System.debug('PRI40| ' + w.Name + ' | ' + w.agf__Priority__c + ' -> ' + novo + ' | time=' + w.agf__Scrum_Team__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + ' | ' + w.agf__Subject__c.left(50));
    w.agf__Priority__c = novo; upd.add(w);
}
for (String n : plano.keySet()) if (!achadas.contains(n)) System.debug('PRI40| ' + n + ' | NAO ENCONTRADA');
System.debug('PRI40| por prioridade: ' + porPrio + ' | a alterar: ' + upd.size());
if (!EXECUTAR) { System.debug('PRI40| FASE 1 concluida: nada alterado. Rode com EXECUTAR = true.'); return; }
update upd;
Map<String, Integer> depois = new Map<String, Integer>();
for (AggregateResult ar : [SELECT agf__Priority__c pr, COUNT(Id) n FROM agf__ADM_Work__c WHERE Name IN :plano.keySet() GROUP BY agf__Priority__c]) depois.put(String.valueOf(ar.get('pr')), (Integer) ar.get('n'));
System.debug('PRI40| DEPOIS por prioridade: ' + depois);
System.debug('PRI40| concluido: ' + upd.size() + ' work(s) alterada(s).');
