# W0382 | fix2 — retorno ao arquiteto específico

Fecha a última lacuna funcional do requisito: "gerando uma nova solicitação de
aprovação ao usuário de Arquitetura **definido no começo do processo**". Hoje a
aprovação pós-diretoria volta para a fila `Arquitetura`; com este pacote volta
para o arquiteto que escalou.

Deploy: Workbench > Migration > Deploy > zip > Single Package. Sem test level
em sandbox.

## O mecanismo, em 4 peças

1. **Campo novo** `Opportunity.SolutionArchitect__c` (Lookup > User), espelho do
   `ManagerAccount__c`. Guarda quem disparou a Revisão Diretoria.

2. **`OpportunitySendCLevelApproval_B2B`** (contém também o `PapelEncontrado`
   já deployado — este arquivo é o acumulado):
   - `UpdateOpportunity` grava `SolutionArchitect__c = $User.Id` (o arquiteto
     que está clicando) e `Send4Approval__c = false`;
   - `GetApprovalWorkItem` passa a `1 AND 2 AND (3 OR 4)`: acha o work item na
     fila **ou** com o próprio arquiteto — sem isso a segunda escalação
     (C-Level aprova, arquiteto quer mandar para o Head) não encontra o item.

3. **`OpportunityStageApprovalProcess_B2B`**:
   `UpdateApproved_AprovacaoTecnica_CLevel` agora grava também
   `Send4Approval__c = true`. Com o false na escalação, o aprovado produz a
   transição false→true que **garante** o re-disparo da orquestração — o passo
   5 deixa de depender de semântica de trigger.

4. **`OpportunityApprovalSteps_B2B`** (orquestração): os steps de Arquitetura
   ganham condição de entrada sobre `SolutionArchitect__c`:
   - nulo  → `ApprovalStep_Arquitetura` (fila, comportamento atual);
   - preenchido → `ApprovalStep_Arquiteto` novo, assignee
     `$Record.SolutionArchitect__r.Username` — mesmo padrão que o passo
     Comercial já usa com `ManagerAccount__r.Username`.
   O background step foi espelhado do mesmo jeito (`UpdateRecord_Arquiteto`),
   porque o `ApprovalProcessReturn` referencia os Outputs do step que rodou.

## Comportamentos que decorrem do desenho

- **Primeira chegada em Viabilidade/Validação técnica**: campo vazio → fila,
  como hoje. Nada muda para quem nunca escalou.
- **Após C-Level/Head aprovar**: run nova da orquestração → campo preenchido →
  item nasce direto para o arquiteto. Requisito atendido.
- **Reprovação total** (volta a Em negociação): o campo NÃO é limpo. Se o
  vendedor reencaminhar, a aprovação vai ao mesmo arquiteto, não à fila. Achamos
  defensável ("definido no começo do processo"); se o negócio preferir voltar à
  fila, é preciso limpar o campo no `UpdateRejected_AprovacaoTecnica`.
- **Durante a revisão da diretoria** `Send4Approval__c` fica false; o critério
  10 do botão FileUpload (`Send4Approval__c = false` em Validação técnica) faz
  o botão de anexo aparecer para o vendedor nesse intervalo. A VR bloqueia
  edição do registro; anexar arquivo não é edição. Cosmético, registrado.

## Teste (Oportunidade NOVA — runs em andamento continuam na versão antiga)

1. B2B/B2G em Validação técnica, `BackofficeForm__c = true` → item na fila.
2. Arquiteto clica Revisão Diretoria, escolhe C-Level → conferir
   `SolutionArchitect__c` preenchido com o arquiteto e `Send4Approval__c` false.
3. C-Level aprova → `ResponsibleTeam__c = Arquitetura`, `Send4Approval__c` true
   e **item novo atribuído ao arquiteto** (não à fila).
4. No item novo, o arquiteto clica Revisão Diretoria de novo (Head, B2B) →
   deve funcionar (é o filtro 4 do GetApprovalWorkItem).
5. B2G + Head → continua caindo na tela de erro (PapelEncontrado preservado).
