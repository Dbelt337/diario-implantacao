// 48 - Fecha os itens "Aprovacao - Arquitetura" pendentes de oportunidades ja FECHADAS (ganha ou perdida), cancelando a
// orquestracao de aprovacao (FlowOrchestrationInstance.Status = 'Canceled'). Mecanismo provado pelo script 47 em 17/09:
// recolher a ApprovalSubmission pela API e proibido ("User cannot edit Approval Submission Standard Fields"), mas cancelar a
// orquestracao funciona e deixa o item da fila como Completed (4 orfaos limpos assim). Levantamento: 43 opps Fechado/Perdido.
// Nao toca em oportunidade aberta nem em orquestracao de outro estagio. Idempotente. DUAS FASES: EXECUTAR = false so lista.
// Filtre o log por CAN48|.
Boolean EXECUTAR = false;
Integer LIMITE = 100;

Map<Id, Id> orchPorOpp = new Map<Id, Id>(); Map<Id, Integer> itensPorOpp = new Map<Id, Integer>();
for (FlowOrchestrationWorkItem i : [SELECT Id, RelatedRecordId, CreatedDate, StepInstance.OrchestrationInstanceId FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned' AND RelatedRecordId != null]) {
    if (i.StepInstance == null || i.StepInstance.OrchestrationInstanceId == null) continue;
    orchPorOpp.put(i.RelatedRecordId, i.StepInstance.OrchestrationInstanceId);
    itensPorOpp.put(i.RelatedRecordId, (itensPorOpp.containsKey(i.RelatedRecordId) ? itensPorOpp.get(i.RelatedRecordId) : 0) + 1);
}
List<FlowOrchestrationInstance> cancelar = new List<FlowOrchestrationInstance>(); Set<Id> oppsProc = new Set<Id>(); Integer abertas = 0;
for (Opportunity o : [SELECT Id, Name, StageName, IsClosed, IsWon, CloseDate FROM Opportunity WHERE Id IN :orchPorOpp.keySet() ORDER BY CloseDate]) {
    if (!o.IsClosed) { abertas++; continue; }
    if (cancelar.size() >= LIMITE) { System.debug('CAN48| ' + o.Name.left(45) + ' | ' + o.StageName + ' | (fora do limite)'); continue; }
    cancelar.add(new FlowOrchestrationInstance(Id = orchPorOpp.get(o.Id), Status = 'Canceled')); oppsProc.add(o.Id);
    System.debug('CAN48| ' + o.Name.left(45) + ' | ' + o.StageName + (o.IsWon ? ' (ganha)' : '') + ' fechada em ' + o.CloseDate + ' | ' + itensPorOpp.get(o.Id) + ' item(ns) | CANCELAR orquestracao ' + orchPorOpp.get(o.Id));
}
System.debug('CAN48| opps com item pendente: ' + orchPorOpp.size() + ' | abertas (nao mexe): ' + abertas + ' | fechadas a cancelar: ' + cancelar.size());
if (!EXECUTAR) { System.debug('CAN48| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
Database.SaveResult[] rc = Database.update(cancelar, false);
Integer ok = 0; for (Integer k = 0; k < rc.size(); k++) { if (rc[k].isSuccess()) ok++; else System.debug('CAN48|   falha orquestracao ' + cancelar[k].Id + ': ' + rc[k].getErrors()[0].getMessage().left(200)); }
System.debug('CAN48| orquestracoes canceladas: ' + ok + ' de ' + cancelar.size());
System.debug('CAN48| DEPOIS itens ainda Assigned nas opps fechadas processadas: ' + [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned' AND RelatedRecordId IN :oppsProc]);
System.debug('CAN48| DEPOIS total pendentes na fila de Arquitetura: ' + [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned']);
System.debug('CAN48| concluido.');
