// 51c - SENAC SC (006V200000yiZh3IAE), 23/09. O 51b falhou: a acao padrao reassignApprovalWorkItem considera como
// responsavel atual o do item de ORQUESTRACAO (Samuel) e recusou "ja esta atribuido a ele". Aqui a mesma acao padrao e
// usada em dois passos, sem DML direto: (A) reatribuir ao Hermes (responsavel atual do item de APROVACAO): a acao ve
// Samuel -> Hermes e alinha os dois registros no Hermes; (B) reatribuir ao Samuel: Hermes -> Samuel nos dois.
// Cada passo confere o estado antes e para se algo estiver diferente do esperado. Filtre o log por SEN51|.
Id OPP = '006V200000yiZh3IAE';
Id SAMUEL = '005V200000JWLWDIA5';

ApprovalWorkItem awi = [SELECT Id, Name, Status, AssignedToId, AssignedTo.Name, FlowOrchestrationWorkItemId,
                        FlowOrchestrationWorkItem.AssigneeId, FlowOrchestrationWorkItem.Assignee.Name
                        FROM ApprovalWorkItem WHERE RelatedRecordId = :OPP AND Status = 'Assigned' LIMIT 1];
Id HERMES = awi.AssignedToId;
System.debug('SEN51| ANTES ' + awi.Name + ' aprovacao=' + awi.AssignedTo.Name + ' | orquestracao=' + awi.FlowOrchestrationWorkItem.Assignee.Name);
if (awi.FlowOrchestrationWorkItem.AssigneeId != SAMUEL || HERMES == SAMUEL) {
    System.debug('SEN51| estado diferente do esperado (orquestracao deveria estar com o Samuel e aprovacao com outra pessoa). Nada feito.');
    return;
}

// Passo A: alinhar no Hermes
Invocable.Action a = Invocable.Action.createStandardAction('reassignApprovalWorkItem');
a.setInvocationParameter('approvalWorkItemId', String.valueOf(awi.Id));
a.setInvocationParameter('assigneeId', String.valueOf(HERMES));
a.setInvocationParameter('comments', 'Realinhamento tecnico pela governanca (passo 1 de 2).');
Invocable.Action.Result ra = a.invoke()[0];
System.debug('SEN51| passo A (alinhar no ' + awi.AssignedTo.Name + ') sucesso=' + ra.isSuccess() + ' erros=' + ra.getErrors());
ApprovalWorkItem m1 = [SELECT AssignedTo.Name, AssignedToId, FlowOrchestrationWorkItem.AssigneeId, FlowOrchestrationWorkItem.Assignee.Name FROM ApprovalWorkItem WHERE Id = :awi.Id];
System.debug('SEN51| apos A: aprovacao=' + m1.AssignedTo.Name + ' | orquestracao=' + m1.FlowOrchestrationWorkItem.Assignee.Name);
if (!ra.isSuccess() || m1.AssignedToId != m1.FlowOrchestrationWorkItem.AssigneeId) {
    System.debug('SEN51| passo A nao alinhou os dois registros. Parando aqui; nada mais sera feito.');
    return;
}

// Passo B: reatribuir ao Samuel pelo mecanismo padrao
Invocable.Action b = Invocable.Action.createStandardAction('reassignApprovalWorkItem');
b.setInvocationParameter('approvalWorkItemId', String.valueOf(awi.Id));
b.setInvocationParameter('assigneeId', String.valueOf(SAMUEL));
b.setInvocationParameter('comments', 'Reatribuido ao gerente da unidade (Samuel Helbig) pela governanca; o Gerente da Conta cadastrado era o proprio vendedor.');
Invocable.Action.Result rb = b.invoke()[0];
System.debug('SEN51| passo B (Samuel) sucesso=' + rb.isSuccess() + ' erros=' + rb.getErrors());
ApprovalWorkItem m2 = [SELECT Status, AssignedTo.Name, FlowOrchestrationWorkItem.Status, FlowOrchestrationWorkItem.Assignee.Name FROM ApprovalWorkItem WHERE Id = :awi.Id];
System.debug('SEN51| DEPOIS aprovacao=' + m2.AssignedTo.Name + ' (' + m2.Status + ') | orquestracao=' + m2.FlowOrchestrationWorkItem.Assignee.Name + ' (' + m2.FlowOrchestrationWorkItem.Status + ')');
