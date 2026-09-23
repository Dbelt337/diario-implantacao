// 51e - SENAC SC (006V200000yiZh3IAE), 23/09. Os passos 1 e 2 do 51d ja aconteceram (orquestracao 00022847 = Canceled,
// submissao = Recalled, 0 itens de aprovacao abertos). Faltou o passo 3: destravar a oportunidade e prepara-la para o
// reenvio (Send4Approval = false, Gerente da Conta = Samuel Helbig). Este script faz so isso, com guarda de estado.
// DUAS FASES: EXECUTAR = false so lista. Filtre o log por SEN51|.
Boolean EXECUTAR = true;
Id OPP = '006V200000yiZh3IAE';
Id ORQ = '0jEV2000002yw3BMAQ';
Id SUBMISSAO = '9iPV2000000BzcrMAC';
Id SAMUEL = '005V200000JWLWDIA5';

Opportunity o = [SELECT Id, Name, StageName, Send4Approval__c, ArchitectureApproved__c, ManagerAccount__r.Name FROM Opportunity WHERE Id = :OPP];
String orqStatus = [SELECT Status FROM FlowOrchestrationInstance WHERE Id = :ORQ].Status;
String subStatus = [SELECT Status FROM ApprovalSubmission WHERE Id = :SUBMISSAO].Status;
Integer abertos = [SELECT COUNT() FROM ApprovalWorkItem WHERE RelatedRecordId = :OPP AND Status = 'Assigned'];
Integer orqAbertos = [SELECT COUNT() FROM FlowOrchestrationWorkItem WHERE RelatedRecordId = :OPP AND Status = 'Assigned'];
System.debug('SEN51| ANTES fase=' + o.StageName + ' | Send4Approval=' + o.Send4Approval__c + ' | ArchitectureApproved=' + o.ArchitectureApproved__c
    + ' | gerente da conta=' + o.ManagerAccount__r.Name + ' | orquestracao=' + orqStatus + ' | submissao=' + subStatus + ' | itens de aprovacao abertos=' + abertos + ' | itens de orquestracao abertos=' + orqAbertos);
if (orqStatus != 'Canceled' || subStatus != 'Recalled' || abertos != 0 || orqAbertos != 0) { System.debug('SEN51| estado diferente do esperado. Nada feito.'); return; }
if (!EXECUTAR) { System.debug('SEN51| FASE 1 concluida: nada alterado. Rode com EXECUTAR = true.'); return; }

try {
    List<Approval.UnlockResult> ul = Approval.unlock(new List<Id>{ OPP }, false);
    System.debug('SEN51| unlock sucesso=' + ul[0].isSuccess() + (ul[0].isSuccess() ? '' : ' erros=' + ul[0].getErrors()));
} catch (Exception e) { System.debug('SEN51| unlock FALHOU: ' + e.getMessage()); }
try {
    update new Opportunity(Id = OPP, Send4Approval__c = false, ManagerAccount__c = SAMUEL);
    System.debug('SEN51| oportunidade preparada: Send4Approval=false, Gerente da Conta=Samuel Helbig');
} catch (Exception e) { System.debug('SEN51| preparacao FALHOU: ' + e.getMessage()); }

Opportunity d = [SELECT StageName, Send4Approval__c, ArchitectureApproved__c, ManagerAccount__r.Name FROM Opportunity WHERE Id = :OPP];
System.debug('SEN51| DEPOIS fase=' + d.StageName + ' | Send4Approval=' + d.Send4Approval__c + ' | ArchitectureApproved=' + d.ArchitectureApproved__c + ' | gerente da conta=' + d.ManagerAccount__r.Name);
System.debug('SEN51| proximo passo: Hermes reenvia para aprovacao pela tela; conferir que o item de aprovacao nasce com o Samuel.');
