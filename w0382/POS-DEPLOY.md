# W0382 | Verificacao do estado pos-deploy (sandbox Staging)

Fonte: `retrieve_09SHZ00000GVgY32AL.zip`.

## Confirmado OK

| Item | Estado |
|---|---|
| `B2B_Head_B2G` | **nao foi criado** -- correto |
| FlexiPage, criterio 1 | `StageName = Validacao tecnica` -- a edicao pelo App Builder foi salva |
| FlexiPage, booleanFilter | `1 AND 2 AND 3 AND NOT(4) AND (5 OR 6)` -- intacto apos a edicao manual |
| `BloqueiaAlteracaoRevisaoDiretoria` | `active=true` |
| `ObrigaTipoEmNegociacao` | `active=false` -- inativa de proposito, como planejado |
| `GetDirectorUser` | ganhou o filtro `IsActive = true` |
| `AprovadorEncontrado` + `FailNoApproverScreen` | presentes no flow |

A edicao manual da FlexiPage nao danificou a logica de filtro. Era o risco de
mexer numa pagina de 61 KB pela tela, e nao se concretizou.

## PROBLEMA: a rede de seguranca provavelmente nunca dispara

A decisao `AprovadorEncontrado` testa `GetDirectorUser.Id`, **depois** do
lookup de usuario. Mas o lookup anterior nao foi protegido:

```
GetDirectorRole   UserRole WHERE DeveloperName = 'B2B_Head_B2G'
                  assignNullValuesIfNoRecordsFound = false   -> Id fica NULL

GetDirectorUser   User WHERE UserRoleId = {!GetDirectorRole.Id}   (NULL)
                       AND IsActive = true
                  getFirstRecordOnly = true

AprovadorEncontrado   GetDirectorUser.Id IsNull = false ?
```

`UserRoleId = null` **casa com todo usuario ativo sem papel** -- admins,
usuarios de integracao, service accounts. Se existir ao menos um, o
`getFirstRecordOnly` devolve esse usuario, `GetDirectorUser.Id` nao e nulo, a
decisao responde "Sim" e o fluxo segue para `UpdateOpportunity` e
`ReassignApprovalWorkItemRecord`.

Ou seja: o `FailNoApproverScreen` so protege o org em que **nao existe nenhum
usuario ativo sem papel** -- situacao rara. O `IsActive = true` que foi
adicionado reduziu o conjunto de candidatos, mas nao fechou o buraco.

### Teste que decide

```sql
SELECT COUNT() FROM User WHERE IsActive = true AND UserRoleId = null
```

- Retorno **0** -> a protecao funciona; B2G cai na tela de erro.
- Retorno **> 0** -> a protecao nao dispara, e a aprovacao de diretoria de uma
  Oportunidade B2G esta sendo reatribuida a um desses usuarios. Rodar tambem em
  producao e conferir quem esta com os work items.

### Correcao

Testar o **papel**, nao o usuario. Inserir a decisao entre `GetDirectorRole` e
`GetDirectorUser`:

```
GetDirectorRole -> [GetDirectorRole.Id IsNull?]
                      Sim -> FailNoApproverScreen
                      Nao -> GetDirectorUser -> AprovadorEncontrado -> ...
```

Manter tambem o `AprovadorEncontrado` atual: ele passa a cobrir o caso legitimo
de papel que existe mas esta sem usuario ativo -- que e o caso de
`B2B_Head_B2S` (0 usuarios), `B2C_Head` (0) e `Head` (0).

## As filas ja existem, e resolvem o roteamento do Head

O retrieve trouxe, entre outras:

```
queues/Viabilidade_B2B.queue    "Viabilidade - B2B"
queues/Viabilidade_B2G.queue    "Viabilidade - B2G"
queues/Viabilidade_B2W.queue    "Viabilidade - B2W"
queues/Arquitetura.queue        "Arquitetura"   (6 membros)
```

Todas com `FlowOrchestrationWorkItem` e `ApprovalSubmission` entre os objetos
suportados -- exatamente o que o `reassignApprovalWorkItem` precisa.

Isso resolve a tensao que estava em aberto entre o requisito e a hierarquia:

- O requisito trata `Type` como parametro de roteamento da diretoria.
- A hierarquia de papeis nao tem Head de B2G, e criar um quebraria o Head B2B.
- **Mas o org ja segmenta B2B / B2G / B2W por FILA**, nao por papel. O padrao
  existe, esta em producao e e o mesmo trio de valores.

Entao a saida nao e inventar papel nem contrariar o requisito: e seguir o
padrao `Viabilidade_*` e criar as filas de diretoria, passando o Id da fila em
`assigneeId` (a acao padrao aceita fila). Resolve de uma vez o B2G, o desempate
dos 2 usuarios de `B2B_Head_B2B` e o caso dos papeis Head vazios.

Falta apenas a decisao de negocio de quem entra em cada fila -- que e uma
pergunta muito mais facil de responder do que "quem vira o Head de B2G".

## Pendencia que o retrieve nao resolve

O conflito de fase continua de pe: o requisito descreve a Fase 2 como
'Viabilidade e desenho da solucao' e nunca cita 'Validacao tecnica'. O deploy
mudou o botao para 'Validacao tecnica' e o retrieve confirma que essa mudanca
esta salva na sandbox. Precisa de resposta antes de producao.
