// 51b - SENAC SC (006V200000yiZh3IAE): segunda tentativa, 23/09. O script 51 falhou no passo 1 (update do
// FlowOrchestrationWorkItem) com UNABLE_TO_UPDATE_RECORD_LOCK: o bloqueio da oportunidade pertence a submissao de aprovacao
// e a org nao deixa mais mexer no item da orquestracao por DML. Aqui NAO ha DML direto: so a acao padrao
// reassignApprovalWorkItem (a mesma do botao Reatribuir), que move o item de aprovacao (hoje com o Hermes, que e o dono
// da oportunidade e tambem o Gerente da Conta cadastrado) para o Samuel. Se a acao falhar, nada muda; o log mostra o erro.
// Caminho seguinte, se falhar: corrigir o campo Gerente da Conta da oportunidade para o Samuel e pedir ao Hermes que
// recupere (recall) a solicitacao e reenvie para aprovacao pela tela; a orquestracao cria o item certo.
// DUAS FASES: EXECUTAR = false so lista. Filtre o log por SEN51|.
Boolean EXECUTAR = true;
Id OPP = '006V200000yiZh3IAE';
String NOVO_RESPONSAVEL = 'Samuel Helbig';

ApprovalWorkItem awi = [SELECT Id, Name, Status, AssignedToId, AssignedTo.Name, FlowOrchestrationWorkItemId,
                        FlowOrchestrationWorkItem.Status, FlowOrchestrationWorkItem.Assignee.Name
                        FROM ApprovalWorkItem WHERE RelatedRecordId = :OPP AND Status = 'Assigned' LIMIT 1];
User alvo = [SELECT Id, Name FROM User WHERE Name = :NOVO_RESPONSAVEL AND IsActive = true LIMIT 1];
System.debug('SEN51| ANTES ' + awi.Name + ' aprovacao=' + awi.AssignedTo.Name + ' (' + awi.Status + ') | orquestracao='
    + awi.FlowOrchestrationWorkItem.Assignee.Name + ' (' + awi.FlowOrchestrationWorkItem.Status + ') | alvo=' + alvo.Name);
if (!EXECUTAR) { System.debug('SEN51| FASE 1 concluida: nada alterado. Rode com EXECUTAR = true.'); return; }

Invocable.Action a = Invocable.Action.createStandardAction('reassignApprovalWorkItem');
a.setInvocationParameter('approvalWorkItemId', String.valueOf(awi.Id));
a.setInvocationParameter('assigneeId', String.valueOf(alvo.Id));
a.setInvocationParameter('comments', 'Reatribuido ao gerente da unidade (' + alvo.Name + ') pela governanca; o Gerente da Conta cadastrado era o proprio vendedor.');
List<Invocable.Action.Result> rs = a.invoke();
for (Invocable.Action.Result r : rs) { System.debug('SEN51| reassignApprovalWorkItem sucesso=' + r.isSuccess() + ' erros=' + r.getErrors()); }

ApprovalWorkItem d1 = [SELECT Status, AssignedTo.Name FROM ApprovalWorkItem WHERE Id = :awi.Id];
FlowOrchestrationWorkItem d2 = [SELECT Status, Assignee.Name FROM FlowOrchestrationWorkItem WHERE Id = :awi.FlowOrchestrationWorkItemId];
System.debug('SEN51| DEPOIS aprovacao=' + d1.AssignedTo.Name + ' (' + d1.Status + ') | orquestracao=' + d2.Assignee.Name + ' (' + d2.Status + ')');
