// 50 - Fecha os itens "Aprovacao - Arquitetura" pendentes de oportunidades ABERTAS que ja sairam das fases tecnicas
// (Viabilidade e desenho da solucao / Validacao tecnica): a orquestracao disparou e a oportunidade voltou de fase sem a
// aprovacao terminar, entao o item fica na fila sem ninguem para tratar. Mesmo mecanismo do script 48 (cancelar a
// FlowOrchestrationInstance; o item vira Completed). Se a oportunidade voltar a Validacao tecnica, a orquestracao
// [Oportunidade] Controle de filas aprovacao dispara de novo (gatilho em Update com Send4Approval = true).
// Levantamento 21/09: 224 pendentes, 204 em Viabilidade, 19 em Validacao tecnica, 1 em Em negociacao.
// Nao toca em oportunidade nas fases tecnicas nem fechada (fechadas sao do script 48). Idempotente. DUAS FASES.
// Filtre o log por CAN50|.
Boolean EXECUTAR = true;
Integer LIMITE = 50;
Set<String> FASES_TECNICAS = new Set<String>{'Viabilidade e desenho da solução', 'Validação técnica'};

Map<Id, Id> orchPorOpp = new Map<Id, Id>(); Map<Id, Integer> itensPorOpp = new Map<Id, Integer>();
for (FlowOrchestrationWorkItem i : [SELECT Id, RelatedRecordId, StepInstance.OrchestrationInstanceId FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned' AND RelatedRecordId != null]) {
    if (i.StepInstance == null || i.StepInstance.OrchestrationInstanceId == null) continue;
    orchPorOpp.put(i.RelatedRecordId, i.StepInstance.OrchestrationInstanceId);
    itensPorOpp.put(i.RelatedRecordId, (itensPorOpp.containsKey(i.RelatedRecordId) ? itensPorOpp.get(i.RelatedRecordId) : 0) + 1);
}
List<FlowOrchestrationInstance> cancelar = new List<FlowOrchestrationInstance>(); Set<Id> oppsProc = new Set<Id>(); Integer tecnicas = 0, fechadas = 0;
for (Opportunity o : [SELECT Id, Name, StageName, IsClosed, LastStageChangeDate FROM Opportunity WHERE Id IN :orchPorOpp.keySet() ORDER BY LastStageChangeDate]) {
    if (o.IsClosed) { fechadas++; continue; }
    if (FASES_TECNICAS.contains(o.StageName)) { tecnicas++; continue; }
    if (cancelar.size() >= LIMITE) { System.debug('CAN50| ' + o.Name.left(45) + ' | ' + o.StageName + ' | (fora do limite)'); continue; }
    cancelar.add(new FlowOrchestrationInstance(Id = orchPorOpp.get(o.Id), Status = 'Canceled')); oppsProc.add(o.Id);
    System.debug('CAN50| ' + o.Name.left(45) + ' | fase atual ' + o.StageName + ' desde ' + o.LastStageChangeDate + ' | ' + itensPorOpp.get(o.Id) + ' item(ns) | CANCELAR orquestracao ' + orchPorOpp.get(o.Id));
}
System.debug('CAN50| opps com item pendente: ' + orchPorOpp.size() + ' | nas fases tecnicas (nao mexe): ' + tecnicas + ' | fechadas (script 48): ' + fechadas + ' | abertas fora das fases a cancelar: ' + cancelar.size());
if (!EXECUTAR) { System.debug('CAN50| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
Database.SaveResult[] rc = Database.update(cancelar, false);
Integer ok = 0; for (Integer k = 0; k < rc.size(); k++) { if (rc[k].isSuccess()) ok++; else System.debug('CAN50|   falha orquestracao ' + cancelar[k].Id + ': ' + rc[k].getErrors()[0].getMessage().left(200)); }
System.debug('CAN50| orquestracoes canceladas: ' + ok + ' de ' + cancelar.size());
System.debug('CAN50| DEPOIS itens ainda Assigned nas opps processadas: ' + [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned' AND RelatedRecordId IN :oppsProc]);
System.debug('CAN50| DEPOIS total pendentes na fila de Arquitetura: ' + [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned']);
System.debug('CAN50| concluido.');
