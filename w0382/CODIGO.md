# W0382 | Leitura do codigo (retrieve pre-deploy, API 63.0)

Fonte: `retrieve_09SV2000002t1rxMAA.zip`. E o estado **anterior** ao deploy --
o `OpportunitySendCLevelApproval_B2B` nao tem `FailNoApproverScreen` nem
`AprovadorEncontrado`.

## Correcao: os dois alertas que levantei pelo print estavam errados

O `booleanFilter` da acao `Opportunity.ReassignCLevelApproval` no
`OpportunityRecordPageB2B` e:

```
1 AND 2 AND 3 AND NOT(4) AND (5 OR 6)

1  Record.StageName                        = Viabilidade e desenho da solucao
2  Record.ArchitectureApproved__c          = false
3  Record.ResponsibleTeam__c               = Arquitetura
4  $Permission.CustomPermission.SalesmanGR = true
5  Record.Type                             = B2B
6  Record.Type                             = B2G
```

- O `(5 OR 6)` **ja existe e ja esta parentetizado**. Nao ha contradicao entre
  os filtros de Tipo.
- O `NOT(4)` **ja esconde do vendedor**, como o LEIAME dizia. O App Builder
  mostra o criterio cru (`SalesmanGR Igual true`); a negacao vive na logica de
  filtro, que a tela so revela rolando ate o final.

Nenhuma das duas precisa de acao. Ficam registradas porque a tela do App
Builder nao permite concluir isso -- so o XML permite.

## A cadeia que quebra o B2G

`OpportunitySendCLevelApproval_B2B`, formula `DirectorValueSelected`:

```
IF({!AttachmentSelectedOption} = 'Head',
   {!GetOpportunity.RecordTypeName__c} + '_' + {!AttachmentSelectedOption}
   + '_' + TEXT({!GetOpportunity.Type}),
   'CLevel')
```

Com `RecordTypeName__c = 'B2B'`:

| Escolha | Type | DeveloperName gerado | Existe? |
|---|---|---|---|
| C-Level | qualquer | `CLevel`         | sim, 1 usuario ativo |
| Head    | B2B      | `B2B_Head_B2B`   | sim, 2 usuarios ativos |
| Head    | B2G      | `B2B_Head_B2G`   | **nao** |

Confirmado por codigo, nao mais por hipotese. E confirma o diagnostico de
HIERARQUIA.md: a formula trata canal de venda e Type de negocio como a mesma
dimensao. Efeito colateral: `B2B_Head_B2W`, `B2B_Head_Blink`, `B2B_Head_SEMPRE`
e `B2B_Head_B2S` sao **inalcancaveis** por esta formula -- 6 usuarios em papeis
de Head que nenhum caminho do flow consegue enderecar.

## O B2G pode nao estar falhando em silencio -- pode estar acertando a pessoa errada

```
GetDirectorRole   UserRole  WHERE DeveloperName = {!DirectorValueSelected}
                  getFirstRecordOnly = true
                  assignNullValuesIfNoRecordsFound = false     -> Id fica null

GetDirectorUser   User      WHERE UserRoleId = {!GetDirectorRole.Id}   (null)
                  getFirstRecordOnly = true

ReassignApprovalWorkItemRecord   assigneeId = {!GetDirectorUser.Id}
```

Sem papel encontrado, o filtro vira `UserRoleId = null` -- que **casa com todos
os usuarios sem papel** (integracao, admins, service accounts). Com
`getFirstRecordOnly`, o flow pega um qualquer e reatribui o item de aprovacao
para ele. E o `UpdateOpportunity` ja gravou `ResponsibleTeam__c = 'Head'`
antes disso, entao a Oportunidade parece escalada corretamente.

**VERIFICAR EM PRODUCAO** quem esta com os work items das Oportunidades B2G que
passaram por "Revisao Diretoria":

```sql
SELECT Id, OpportunityName__c, Assignee__c, Assignee__r.Name,
       Assignee__r.UserRoleId, CreatedDate
FROM ApprovalWorkItem__c
WHERE ...
```
(ajustar para o objeto real de work item do org)

Se houver itens com aprovador sem papel, o problema deixa de ser "nao envia" e
passa a ser "enviou para quem nao devia" -- muda a severidade e muda a conversa
com a Priscila.

## Requisito x implantado

- `ResponsibleTeam__c` tem exatamente os valores do requisito (Vendedor/GR,
  Arquitetura, C-Level, Head, Gerencia, Backoffice) mais um extra, `Viabilidade`.
- `UpdateOpportunity` grava `ResponsibleTeam__c = AttachmentSelectedOption`
  ('C-Level' ou 'Head'). Confere com o requisito.
- O requisito pede, apos a aprovacao, "uma nova solicitacao de aprovacao ao
  usuario de Arquitetura **definido no comeco do processo**". Hoje volta para a
  fila `Arquitetura`, nao para o usuario. O LEIAME ja listava isso como fora do
  pacote -- o requisito confirma que e lacuna, nao escolha.

### Conflito: a fase do botao

O requisito descreve a Fase 2 como **'Viabilidade e desenho da solucao'**, do
titulo ao detalhamento, e **nunca menciona 'Validacao tecnica'**. O retrieve
mostra o botao exatamente nessa fase.

A mudanca central da W0382 move o botao para `Validacao tecnica`. Os dois
valores existem na picklist `StageName` e sao fases distintas -- a regra do
`Opportunity.FileUpload` referencia ambas separadamente. Nao e renomeacao.

**Precisa de resposta antes de producao:** houve decisao posterior mudando a
fase, ou a mudanca esta contrariando o requisito escrito?
