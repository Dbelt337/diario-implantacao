// 51d - SENAC SC (006V200000yiZh3IAE), 23/09. Reatribuir nao e mais possivel (51, 51b, 51c): o bloqueio da oportunidade
// ficou orfao depois da alteracao direta do item de orquestracao em 15/09, e tanto o DML quanto a acao padrao
// reassignApprovalWorkItem falham com UNABLE_TO_UPDATE_RECORD_LOCK. Caminho: encerrar a solicitacao travada e reenviar limpo.
//   1. Cancelar a instancia da orquestracao 00022847 (mesmo mecanismo dos scripts 48/50): o item de orquestracao vira Completed.
//   2. Recuperar (recall) a submissao de aprovacao pela acao padrao, para o item de aprovacao sair da lista do Hermes.
//   3. Destravar o registro (Approval.unlock) e preparar a oportunidade: Send4Approval = false e Gerente da Conta = Samuel,
//      para que o reenvio crie a aprovacao comercial no nome certo.
//   4. Fora deste script: o Hermes reenvia para aprovacao pela tela (o mesmo caminho de sempre). A orquestracao dispara de
//      novo (gatilho: Send4Approval = true) e cria o item para o Samuel. Nada de arquitetura e refeito: a fase continua
//      "Aprovacao comercial" e ArchitectureApproved__c continua marcado.
// Cada passo e tolerante a falha e registra o resultado. DUAS FASES: EXECUTAR = false so lista. Filtre o log por SEN51|.
Boolean EXECUTAR = true;
Id OPP = '006V200000yiZh3IAE';
Id ORQ = '0jEV2000002yw3BMAQ';
Id SUBMISSAO = '9iPV2000000BzcrMAC';
Id SAMUEL = '005V200000JWLWDIA5';

Opportunity o = [SELECT Id, Name, StageName, Send4Approval__c, ArchitectureApproved__c, ManagerAccount__r.Name, Owner.Name FROM Opportunity WHERE Id = :OPP];
FlowOrchestrationInstance oi = [SELECT Id, Name, Status FROM FlowOrchestrationInstance WHERE Id = :ORQ];
ApprovalSubmission sub = [SELECT Id, Status, SubmittedBy.Name FROM ApprovalSubmission WHERE Id = :SUBMISSAO];
List<ApprovalWorkItem> awis = [SELECT Id, Name, Status, AssignedTo.Name FROM ApprovalWorkItem WHERE ApprovalSubmissionId = :SUBMISSAO AND Status = 'Assigned'];
System.debug('SEN51| ANTES opp=' + o.Name.left(50) + ' | fase=' + o.StageName + ' | Send4Approval=' + o.Send4Approval__c + ' | ArchitectureApproved=' + o.ArchitectureApproved__c
    + ' | gerente da conta=' + o.ManagerAccount__r.Name + ' | dono=' + o.Owner.Name);
System.debug('SEN51| ANTES orquestracao ' + oi.Name + '=' + oi.Status + ' | submissao=' + sub.Status + ' (' + sub.SubmittedBy.Name + ') | itens de aprovacao abertos=' + awis.size()
    + (awis.isEmpty() ? '' : ' com ' + awis[0].AssignedTo.Name));
if (o.StageName != 'Aprovação comercial' || oi.Status != 'InProgress') { System.debug('SEN51| estado diferente do esperado. Nada feito.'); return; }
if (!EXECUTAR) { System.debug('SEN51| FASE 1 concluida: nada alterado. Rode com EXECUTAR = true.'); return; }

// 1. cancelar a orquestracao
try {
    update new FlowOrchestrationInstance(Id = ORQ, Status = 'Canceled');
    System.debug('SEN51| passo 1 orquestracao cancelada: ' + [SELECT Status FROM FlowOrchestrationInstance WHERE Id = :ORQ].Status
        + ' | item de orquestracao: ' + [SELECT Status FROM FlowOrchestrationWorkItem WHERE Id = '0jfV20000007worIAA'].Status);
} catch (Exception e) { System.debug('SEN51| passo 1 FALHOU: ' + e.getMessage()); }

// 2. recuperar a submissao (acao padrao)
try {
    Invocable.Action r = Invocable.Action.createStandardAction('recallApprovalSubmission');
    r.setInvocationParameter('approvalSubmissionId', String.valueOf(SUBMISSAO));
    r.setInvocationParameter('comments', 'Solicitacao encerrada pela governanca para reenvio ao gerente correto.');
    Invocable.Action.Result rr = r.invoke()[0];
    System.debug('SEN51| passo 2 recall sucesso=' + rr.isSuccess() + ' erros=' + rr.getErrors());
} catch (Exception e) { System.debug('SEN51| passo 2 FALHOU (acao indisponivel ou recusada): ' + e.getMessage()); }
System.debug('SEN51| apos 2: submissao=' + [SELECT Status FROM ApprovalSubmission WHERE Id = :SUBMISSAO].Status
    + ' | itens de aprovacao ainda abertos=' + [SELECT COUNT() FROM ApprovalWorkItem WHERE ApprovalSubmissionId = :SUBMISSAO AND Status = 'Assigned']);

// 3. destravar e preparar a oportunidade
try {
    List<Approval.UnlockResult> ul = Approval.unlock(new List<Id>{ OPP }, false);
    System.debug('SEN51| passo 3a unlock sucesso=' + ul[0].isSuccess() + (ul[0].isSuccess() ? '' : ' erros=' + ul[0].getErrors()));
} catch (Exception e) { System.debug('SEN51| passo 3a unlock FALHOU: ' + e.getMessage()); }
try {
    update new Opportunity(Id = OPP, Send4Approval__c = false, ManagerAccount__c = SAMUEL);
    System.debug('SEN51| passo 3b oportunidade preparada: Send4Approval=false, Gerente da Conta=Samuel Helbig');
} catch (Exception e) { System.debug('SEN51| passo 3b FALHOU: ' + e.getMessage()); }

Opportunity d = [SELECT StageName, Send4Approval__c, ArchitectureApproved__c, ManagerAccount__r.Name FROM Opportunity WHERE Id = :OPP];
System.debug('SEN51| DEPOIS fase=' + d.StageName + ' | Send4Approval=' + d.Send4Approval__c + ' | ArchitectureApproved=' + d.ArchitectureApproved__c + ' | gerente da conta=' + d.ManagerAccount__r.Name);
System.debug('SEN51| proximo passo (fora do script): Hermes reenvia para aprovacao pela tela; conferir que o item de aprovacao nasce com o Samuel.');
