# W0382 — Scripts de teste (Execute Anonymous) — staging

Uso: Developer Console → Debug → Execute Anonymous, com usuário admin (não usar Login As).
Pré-requisitos: orquestração `OpportunityApprovalSteps_B2B` **V9**, fluxo de status **V22**, botão **V9**, PS `FunilB2B_CamposAprovacao` atribuído.

Fatos do metadado que os scripts respeitam:
- Gatilho da orquestração: **update** com `Send4Approval__c=true` AND `RecordTypeName__c='B2B'` (insert não dispara).
- Fase técnica: `StageName='Viabilidade e desenho da solução'` OR (`StageName='Validação técnica'` AND `BackofficeForm__c=true`).
- Fila Arquitetura recebe quando `SolutionArchitect__c` é nulo; com arquiteto preenchido o step "Arquiteto da solução" assume.
- Reatribuição: ação padrão `reassignApprovalWorkItem` (`approvalWorkItemId`, `assigneeId`, `comments`) — a mesma do botão.
- Usuários ativos em staging (há duplicados inativos!): Tayza `005HZ00000HDbCzYAL`, Alex `005V200000JRvaLIAT`, Priscila `005HZ00000NXuDFYA1`. `ManagerAccount__c` inativo quebra notificação (defeito 7) e o approval step Comercial.

## Script 1 — criar opp e disparar aprovação (item na fila Arquitetura)

```apex
Id b2bRt = [SELECT Id FROM RecordType
            WHERE SObjectType = 'Opportunity' AND DeveloperName = 'B2B' LIMIT 1].Id;
Account acc = [SELECT Id FROM Account WHERE Name LIKE 'LOGITECH DO BRASIL%' LIMIT 1];
Id tayza = '005HZ00000HDbCzYAL';

Opportunity opp = new Opportunity(
    Name = 'Teste Sr Vilson Parte 21 - script',
    AccountId = acc.Id,
    RecordTypeId = b2bRt,
    Type = 'B2B',
    StageName = 'Validação técnica',
    CloseDate = Date.today().addDays(30),
    Amount = 15,
    OwnerId = tayza,
    ManagerAccount__c = UserInfo.getUserId(),
    ResponsibleTeam__c = 'Arquitetura',
    BackofficeForm__c = true,
    ArchitectureApproved__c = false,
    Send4Approval__c = false,
    Bypass__c = true
);
insert opp;
opp.Send4Approval__c = true;
opp.Bypass__c = true;
update opp;
System.debug('>>> OPP CRIADA: ' + opp.Id);
```

Aguardar ~1 minuto (item nasce assíncrono).

## Script 2 — papel do botão: reatribuir o item ao Alex (C-Level)

```apex
Id oppId = 'COLE_AQUI_O_ID_DA_OPP';
Id alexAtivo = '005V200000JRvaLIAT';
Id priscilaAtiva = '005HZ00000NXuDFYA1';

List<ApprovalWorkItem> itens = [
    SELECT Id, Status, AssignedToId
    FROM ApprovalWorkItem
    WHERE ApprovalSubmission.RelatedRecordId = :oppId AND Status = 'Assigned'
    ORDER BY CreatedDate DESC LIMIT 1
];

if (itens.isEmpty()) {
    System.debug('>>> Item ainda nao criado. Espere 1 minuto e rode de novo.');
} else {
    update new Opportunity(
        Id = oppId,
        ResponsibleTeam__c = 'C-Level',
        SolutionArchitect__c = priscilaAtiva,
        Bypass__c = true
    );
    Invocable.Action acao = Invocable.Action.createStandardAction('reassignApprovalWorkItem');
    acao.setInvocationParameter('approvalWorkItemId', itens[0].Id);
    acao.setInvocationParameter('assigneeId', alexAtivo);
    acao.setInvocationParameter('comments', 'Reatribuido via script de teste W0382');
    System.debug('>>> Reassign: ' + acao.invoke());
}
```

Fallback se `RelatedRecordId` não existir na org: trocar o WHERE por
`WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 1`.

## Resultados esperados

- **Rejeição na fila** (só script 1; rejeitar como membro da fila): opp → "Em negociação", equipe "Vendedor/GR", `Send4Approval=false`, sem resíduo em Paused/Failed.
- **Ciclo C-Level** (scripts 1+2; decidir como Alex ativo):
  - Aprovar → `Bypass=true`, equipe "Arquitetura", `Send4Approval=true` (rearme para a arquitetura).
  - Rejeitar → mesmo resultado da rejeição na fila.
- O update do script 2 (como o clique real) re-dispara a orquestração e gera 1 run extra que morre em `UNABLE_TO_LOCK` + e-mail — ruído conhecido, ignorar (pendência de ajuste do gatilho com o PO).
