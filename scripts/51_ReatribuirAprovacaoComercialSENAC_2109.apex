// 51 - SENAC SC (B2B-0011692, 006V200000yiZh3IAE): corrige o item "Aprovacao - Comercial" que ficou DESALINHADO em 15/09.
// O script 27 reatribuiu o item da orquestracao (FlowOrchestrationWorkItem 0jfV20000007worIAA) para o Samuel Helbig, mas o
// espelho ApprovalWorkItem AWI-000011685 continuou com o Hermes (a API nao deixa editar). Quando alguem tenta aprovar, a
// plataforma valida o evento contra os dois registros e rejeita: "Evento do orquestrador: o valor da carga util do evento e
// invalido: StepInstanceId". Correcao: (1) devolver o item da orquestracao ao Hermes, para os dois registros baterem de novo;
// (2) reatribuir pelo mecanismo PADRAO (acao invocavel reassignApprovalWorkItem, a mesma do botao Reatribuir e do flow de
// C-Level), que atualiza os dois. Testado na staging em 21/09 (item 00000192: espelho e orquestracao mudaram juntos).
// DUAS FASES: EXECUTAR = false so lista. Filtre o log por SEN51|.
Boolean EXECUTAR = false;
Id OPP = '006V200000yiZh3IAE';
String NOVO_RESPONSAVEL = 'Samuel Helbig';

ApprovalWorkItem awi = [SELECT Id, Name, Status, AssignedToId, AssignedTo.Name, FlowOrchestrationWorkItemId,
                        FlowOrchestrationWorkItem.Status, FlowOrchestrationWorkItem.AssigneeId, FlowOrchestrationWorkItem.Assignee.Name,
                        FlowOrchestrationWorkItem.StepInstance.Status
                        FROM ApprovalWorkItem WHERE RelatedRecordId = :OPP AND Status = 'Assigned' LIMIT 1];
User alvo = [SELECT Id, Name FROM User WHERE Name = :NOVO_RESPONSAVEL AND IsActive = true LIMIT 1];
System.debug('SEN51| ANTES ' + awi.Name + ' espelho=' + awi.AssignedTo.Name + ' | orquestracao=' + awi.FlowOrchestrationWorkItem.Assignee.Name
    + ' (' + awi.FlowOrchestrationWorkItem.Status + ', passo ' + awi.FlowOrchestrationWorkItem.StepInstance.Status + ') | alvo=' + alvo.Name);
Boolean desalinhado = awi.AssignedToId != awi.FlowOrchestrationWorkItem.AssigneeId;
System.debug('SEN51| desalinhado=' + desalinhado);
if (!EXECUTAR) { System.debug('SEN51| FASE 1 concluida: nada alterado. Rode com EXECUTAR = true.'); return; }

if (desalinhado) {
    update new FlowOrchestrationWorkItem(Id = awi.FlowOrchestrationWorkItemId, AssigneeId = awi.AssignedToId);
    System.debug('SEN51| passo 1: item da orquestracao devolvido a ' + awi.AssignedTo.Name + ' (alinhado ao espelho)');
}
Invocable.Action a = Invocable.Action.createStandardAction('reassignApprovalWorkItem');
a.setInvocationParameter('approvalWorkItemId', String.valueOf(awi.Id));
a.setInvocationParameter('assigneeId', String.valueOf(alvo.Id));
a.setInvocationParameter('comments', 'Reatribuido ao gerente da conta (' + alvo.Name + ') pela governanca, correcao do item de 03/09.');
List<Invocable.Action.Result> rs = a.invoke();
for (Invocable.Action.Result r : rs) { System.debug('SEN51| passo 2 reassignApprovalWorkItem sucesso=' + r.isSuccess() + ' erros=' + r.getErrors()); }

ApprovalWorkItem d1 = [SELECT Status, AssignedTo.Name FROM ApprovalWorkItem WHERE Id = :awi.Id];
FlowOrchestrationWorkItem d2 = [SELECT Status, Assignee.Name FROM FlowOrchestrationWorkItem WHERE Id = :awi.FlowOrchestrationWorkItemId];
System.debug('SEN51| DEPOIS espelho=' + d1.AssignedTo.Name + ' (' + d1.Status + ') | orquestracao=' + d2.Assignee.Name + ' (' + d2.Status + ')');
System.debug('SEN51| concluido. Agora o ' + alvo.Name + ' aprova pelo item de aprovacao na oportunidade.');
