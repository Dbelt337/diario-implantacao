// 47 - Limpeza da fila de Arquitetura: encerra as aprovacoes "Aprovacao - Arquitetura" ainda pendentes de oportunidades ja
// FECHADAS (Fechado/Perdido ou Instalado) e os itens orfaos (sem RelatedRecordId). Levantamento de 17/09: 290 itens pendentes,
// 43 de opp Fechado/Perdido (idade mediana 129 dias) e 4 orfaos (281 dias). Mecanismo: ApprovalSubmission.Status = 'Recalled'
// (o mesmo do botao "Recolher" da tela; ja ha 1 Recalled na org) e, para orfaos, FlowOrchestrationInstance.Status = 'Canceled'.
// Se a plataforma recusar o DML, o log mostra o erro e nada mais e tentado. Comece com LIMITE = 1 (teste) e confira na tela.
// Nao toca em oportunidade aberta. Idempotente. DUAS FASES: EXECUTAR = false so lista. Filtre o log por FEC47|.
Boolean EXECUTAR = false;
Integer LIMITE = 1;                       // quantas submissoes/orfaos processar nesta execucao (1 = teste; 100 = tudo)
Boolean INCLUIR_ORFAOS = false;

// 1) itens pendentes de Arquitetura e suas oportunidades
Map<Id, FlowOrchestrationWorkItem> itens = new Map<Id, FlowOrchestrationWorkItem>();
Set<Id> oppIds = new Set<Id>(); List<FlowOrchestrationWorkItem> orfaos = new List<FlowOrchestrationWorkItem>();
for (FlowOrchestrationWorkItem i : [SELECT Id, RelatedRecordId, CreatedDate, StepInstance.OrchestrationInstanceId FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned' ORDER BY CreatedDate]) {
    if (i.RelatedRecordId == null) { orfaos.add(i); continue; }
    itens.put(i.Id, i); oppIds.add(i.RelatedRecordId);
}
Map<Id, Opportunity> opps = new Map<Id, Opportunity>([SELECT Id, Name, StageName, IsClosed, IsWon, CloseDate FROM Opportunity WHERE Id IN :oppIds]);
Set<Id> fechadas = new Set<Id>();
for (Id oid : oppIds) if (opps.containsKey(oid) && opps.get(oid).IsClosed) fechadas.add(oid);
System.debug('FEC47| pendentes: ' + (itens.size() + orfaos.size()) + ' | opps abertas: ' + (oppIds.size() - fechadas.size()) + ' | opps FECHADAS com item pendente: ' + fechadas.size() + ' | orfaos: ' + orfaos.size());

// 2) submissoes em andamento dessas opps fechadas
List<ApprovalSubmission> subs = [SELECT Id, RelatedRecordId, Status, FlowOrchestrationInstanceId, FlowOrchestrationInstance.Status, CreatedDate FROM ApprovalSubmission WHERE RelatedRecordId IN :fechadas AND Status = 'InProgress' ORDER BY CreatedDate];
List<ApprovalSubmission> recolher = new List<ApprovalSubmission>();
for (ApprovalSubmission s : subs) {
    Opportunity o = opps.get(s.RelatedRecordId);
    String linha = 'FEC47| ' + o.Name.left(45) + ' | ' + o.StageName + ' fechada em ' + o.CloseDate + ' | submissao de ' + s.CreatedDate.date() + ' | orch=' + s.FlowOrchestrationInstance.Status;
    if (recolher.size() < LIMITE) { recolher.add(s); System.debug(linha + ' | RECOLHER'); } else System.debug(linha + ' | (fora do limite desta execucao)');
}
List<FlowOrchestrationInstance> cancelar = new List<FlowOrchestrationInstance>();
if (INCLUIR_ORFAOS) for (FlowOrchestrationWorkItem i : orfaos) {
    if (cancelar.size() >= LIMITE) break;
    if (i.StepInstance != null && i.StepInstance.OrchestrationInstanceId != null) { cancelar.add(new FlowOrchestrationInstance(Id = i.StepInstance.OrchestrationInstanceId, Status = 'Canceled')); System.debug('FEC47| orfao ' + i.Id + ' de ' + i.CreatedDate.date() + ' | CANCELAR orquestracao ' + i.StepInstance.OrchestrationInstanceId); }
}
System.debug('FEC47| nesta execucao: recolher ' + recolher.size() + ' submissao(oes), cancelar ' + cancelar.size() + ' orquestracao(oes) orfa(s)');
if (!EXECUTAR) { System.debug('FEC47| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true (comece com LIMITE = 1).'); return; }

for (ApprovalSubmission s : recolher) s.Status = 'Recalled';
Database.SaveResult[] rs = Database.update(recolher, false);
Integer ok = 0; for (Integer k = 0; k < rs.size(); k++) { if (rs[k].isSuccess()) ok++; else System.debug('FEC47|   falha submissao ' + recolher[k].Id + ': ' + rs[k].getErrors()[0].getMessage().left(200)); }
System.debug('FEC47| submissoes recolhidas: ' + ok + ' de ' + recolher.size());
if (!cancelar.isEmpty()) {
    Database.SaveResult[] rc = Database.update(cancelar, false);
    Integer okc = 0; for (Integer k = 0; k < rc.size(); k++) { if (rc[k].isSuccess()) okc++; else System.debug('FEC47|   falha orquestracao ' + cancelar[k].Id + ': ' + rc[k].getErrors()[0].getMessage().left(200)); }
    System.debug('FEC47| orquestracoes orfas canceladas: ' + okc + ' de ' + cancelar.size());
}
// 3) conferencia: o item da fila sumiu?
Set<Id> oppsProc = new Set<Id>(); for (ApprovalSubmission s : recolher) oppsProc.add(s.RelatedRecordId);
System.debug('FEC47| DEPOIS itens ainda Assigned nas opps processadas: ' + [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned' AND RelatedRecordId IN :oppsProc]);
for (ApprovalSubmission s : [SELECT Id, Status, FlowOrchestrationInstance.Status FROM ApprovalSubmission WHERE Id IN :recolher]) System.debug('FEC47| DEPOIS submissao ' + s.Id + ' status=' + s.Status + ' | orch=' + s.FlowOrchestrationInstance.Status);
System.debug('FEC47| DEPOIS total pendentes na fila de Arquitetura: ' + [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Assigned']);
System.debug('FEC47| concluido.');
