# W0382 | O que falta para atender o requisito

Estado: pacote publicado em preprod a partir do retrieve de producao, aguardando
teste de usuario. Verificado item a item contra o requisito.

A fase `Validacao tecnica` **e decisao da Priscila**, nao divergencia. Fica
registrado que o texto da work ainda diz 'Viabilidade e desenho da solucao' --
ver item 7.

## Ja atende o requisito (verificado no XML do preprod)

| Requisito | Onde |
|---|---|
| Processo so para Tipo B2B ou B2G | `booleanFilter ... AND (5 OR 6)` |
| Botao escondido do vendedor | `NOT(4)` sobre `SalesmanGR` |
| Escolha entre C-Level e Head | choices `CLevel` / `Head` |
| Descricao no pedido de aprovacao | `SendApproval_MessageTextArea` -> `comments` |
| Equipe responsavel atualizada na transferencia | `UpdateOpportunity` grava `ResponsibleTeam__c` |
| Valores de Equipe responsavel | picklist tem os 6 do requisito |
| Aprovador nao edita a Oportunidade | VR `BloqueiaAlteracaoRevisaoDiretoria` (active) |
| Reprovado volta p/ 'Em negociacao' + 'Vendedor/GR' | `UpdateRejected_AprovacaoTecnica` |
| Aprovado grava Equipe responsavel = Arquitetura | `UpdateApproved_AprovacaoTecnica_CLevel` |

## 1. BLOQUEADOR -- o teste do B2G vai dar falso positivo

`GetDirectorRole` nao encontra `B2B_Head_B2G` e deixa `Id` nulo. O
`GetDirectorUser` filtra `UserRoleId = null AND IsActive = true`, que casa com
os **12 usuarios ativos sem papel** confirmados por query. O
`getFirstRecordOnly` devolve o de menor Id, `AprovadorEncontrado` responde
"Sim" e a aprovacao e reatribuida a esse usuario.

Quem testar vai ver a tela de sucesso e marcar o item como OK.

**Correcao:** testar o papel, nao o usuario. Decisao entre `GetDirectorRole` e
`GetDirectorUser`:

```
GetDirectorRole -> [GetDirectorRole.Id IsNull?]
                      Sim -> FailNoApproverScreen
                      Nao -> GetDirectorUser -> AprovadorEncontrado -> ...
```

Manter o `AprovadorEncontrado` atual: ele passa a cobrir papel existente sem
usuario ativo -- o caso de `B2B_Head_B2S`, `B2C_Head` e `Head`, todos com 0.

Fazer pelo Flow Builder. Editar o XML a mao arrisca o problema de ordenacao de
elementos por XSD que ja custou um commit neste repo.

## 2. BLOQUEADOR -- o nome do arquivo tem underscore

Requisito: arquivo de nome **`AVAL-FINANCEIRA`**.
Codigo (`FilterNameFile`): `StartsWith 'AVAL-FINANCEIRA_'`.

Um arquivo chamado `AVAL-FINANCEIRA.pdf` **nao passa**. So passa
`AVAL-FINANCEIRA_algo.pdf`.

Decidir: ou relaxar o filtro para `AVAL-FINANCEIRA`, ou instruir o usuario. Se
ninguem decidir, o teste trava aqui e vira "bug" que nao e bug.

## 3. DECISAO DE NEGOCIO -- roteamento do Head (resolve o B2G)

O org **ja segmenta B2B / B2G / B2W por fila**: `Viabilidade_B2B`,
`Viabilidade_B2G`, `Viabilidade_B2W`, todas aceitando
`FlowOrchestrationWorkItem` e `ApprovalSubmission`.

Seguir esse padrao e criar as filas de diretoria, passando o Id da fila em
`assigneeId`. Resolve de uma vez:

- B2G, sem inventar papel e sem mexer na hierarquia;
- o desempate dos 2 usuarios de `B2B_Head_B2B`;
- os papeis Head vazios;
- o `CLevel` com 1 usuario, hoje deterministico por acidente.

Pergunta unica para o negocio: **quem entra em cada fila.**

## 4. LACUNA DE REQUISITO -- volta ao arquiteto do inicio

Requisito, na aprovacao da diretoria: "gerando uma nova solicitacao de aprovacao
ao usuario de Arquitetura **definido no comeco do processo**".

Hoje volta para a fila `Arquitetura` (6 membros), nao para o usuario. Exige
campo novo na Oportunidade guardando o arquiteto inicial + mudanca na
orquestracao. Estava listado como fora do pacote; o requisito confirma que e
lacuna, nao escolha de escopo.

## 5. TESTE -- o re-disparo (passo 5)

`UpdateApproved_AprovacaoTecnica_CLevel` grava **so** `ResponsibleTeam__c =
Arquitetura`. Todos os outros `UpdateApproved_*` e `UpdateRejected_*` do mesmo
flow tocam `Send4Approval__c`; este e o unico que nao toca.

O re-disparo depende da orquestracao reagir a um update feito dentro dela
mesma. So o teste diz. Se travar, setar `Send4Approval__c` explicitamente.

## 6. PRE-PRODUCAO

- `ObrigaTipoEmNegociacao` esta inativa. Rodar o `COUNT()` de Oportunidades B2B
  em 'Em negociacao' sem `Type`, fazer o backfill, so entao ativar.
- O deploy rodou com `numTestsRun: 0`. Rodar o `ApprovalWorkItemsControllerTest`
  antes da janela de producao.
- A FlexiPage foi editada pelo App Builder e **nao viaja com o manifest**.
  Refazer a mao em producao.

## 7. DOCUMENTACAO

O texto da work descreve a Fase 2 como 'Viabilidade e desenho da solucao' e
nunca cita 'Validacao tecnica'. A decisao da Priscila mudou o comportamento mas
o requisito nao foi atualizado. Quem testar seguindo o texto nao acha o botao.
