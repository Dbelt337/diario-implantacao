# 21/09/2026 - Aprovacao C-Level (Revisao Diretoria) na oportunidade B2B: retrieve x preprod x prod

Analise somente leitura (nenhum deploy, nenhum DML). Fontes: retrieve `org/retrieves/clevel-09SHZ00000GVgY32AL/unpackaged`
(commit 31aa41f), retrieves de comparacao em `org/tmp/prod` e `org/tmp/staging` (fora do git), consultas em btp-prod
(00DHu00000FcxIgMAJ) e btp-staging (00DHZ000006zyyM2AQ, preprod-brasiltecpar--staging), docs de 15/09 e 16/09.

**Origem do retrieve**: o Id 09SHZ00000GVgY32AL tem a chave de instancia "HZ", a mesma do Id da preprod (00DHZ...).
Veio da preprod/staging. Mas nao e o estado atual dela: o retrieve corresponde as versoes de **19/08** (flow Encaminhar para
C-Level v8, processo de fases v20, ambas do Diego), enquanto a staging hoje esta em **v9 e v22 (25/08, Diego)**, com tres
ajustes a mais (secao 4). A prod esta em **v3 e v8 (03/07, Iago Gomes Tognolli)**.

## 1. A demanda, pelo que o codigo mostra

Um vendedor ou BKO, com a oportunidade B2B parada na fila de Arquitetura, pode pedir uma **revisao da diretoria** antes da
decisao tecnica: escolhe Head ou C-Level, anexa a avaliacao financeira (arquivo obrigatorio com nome `AVAL-FINANCEIRA_...`),
escreve um comentario, e o item de aprovacao que estava na fila Arquitetura e **reatribuido ao diretor**. Enquanto o diretor
nao decide, a oportunidade fica travada para edicao (regra de validacao) e o campo Equipe responsavel marca Head ou
C-Level. O diretor decide pelo item de aprovacao (componente "Itens de aprovacao" na pagina da oportunidade). Se aprova, a
responsabilidade volta para Arquitetura; se rejeita, a oportunidade volta para Em negociacao com o vendedor, como em
qualquer rejeicao tecnica. O Head e escolhido pelo papel `B2B_Head_<Tipo da oportunidade>`; o C-Level pelo papel `CLevel`.

Precisa de confirmacao do Diego:
- **Em que fase a revisao acontece.** Na prod (03/07) o botao "Revisao Diretoria" aparece e o resultado e tratado na fase
  **Viabilidade e desenho da solucao**; no retrieve e na staging (agosto) tudo mudou para **Validacao tecnica**. Os dados
  seguem cada versao: prod tem 20 oportunidades em revisao (18 Head, 2 C-Level), todas em Viabilidade; staging tem 5
  C-Level em Validacao tecnica. Qual e a regra de negocio? Foi a diretoria que pediu a mudanca de fase ou foi correcao?
- **O que o Head aprova**: viabilidade comercial da proposta (avaliacao financeira) ou a solucao tecnica? Pelo anexo
  obrigatorio, e financeira, mas o item reatribuido e o de "Aprovacao - Arquitetura", entao a decisao do diretor **substitui**
  a do arquiteto (o item some da fila; ver risco 1).
- **Head por tipo**: existem papeis B2B_Head_B2B, B2S, B2W, Blink e SEMPRE; nao existe B2B_Head_B2G nem para Tipo vazio.
  Oportunidades B2G (668 abertas) e sem Tipo (732) nao podem pedir Head? Ou falta papel?
- **Quem pode acionar**: o botao esta na pagina B2B para todos; nao ha restricao por perfil.

## 2. O que foi construido, componente a componente

| Componente | O que faz | Observacoes |
|---|---|---|
| Flow de tela `OpportunitySendCLevelApproval_B2B` "[Oportunidade] Encaminhar para C-Level" | Le a oportunidade; tela 1 escolhe Head ou C-Level; tela 2 upload de 1 arquivo; filtra nomes que comecam com `AVAL-FINANCEIRA_` (senao apaga o arquivo e volta a tela); tela 3 comentario; busca a fila Arquitetura, o ApprovalWorkItem Assigned a ela para a oportunidade, o papel (`DirectorValueSelected`) e o primeiro usuario ativo do papel; grava `ResponsibleTeam__c` = Head/C-Level; acao `reassignApprovalWorkItem` para o diretor com o comentario | Roda em modo sistema sem compartilhamento. Sem verificacao de fase (a fase e limitada so pela visibilidade do botao). Sem decisao "item encontrado" |
| Flow autolaunched `OpportunityStageApprovalProcess_B2B` (processo de fases) | Chamado pela orquestracao `OpportunityApprovalSteps_B2B` depois de cada decisao, com `oppStage` e `ApprovalProcessReturn`. Regra nova "Aprovacao diretoria": fase = Validacao tecnica (prod: Viabilidade) e equipe = C-Level ou Head; aprovado -> `ResponsibleTeam__c` = Arquitetura (staging v22 tambem `Bypass__c` = true e `Send4Approval__c` = true); rejeitado -> mesmo caminho da rejeicao tecnica (ArchitectureApproved false, BackofficeForm false, Bypass true, ExpressViability false, equipe Vendedor/GR, Send4Approval false, fase Em negociacao); notificacao ao gerente da conta ou ao dono | A decisao "Approval Phases" **nao tem caminho padrao**: se a fase nao casar com nenhuma regra, o flow termina sem gravar nada (risco 2) |
| Regra de validacao `BloqueiaAlteracaoRevisaoDiretoria` (nova, ativa) | B2B, nao novo, equipe C-Level ou Head, equipe nao alterada, sem Bypass: bloqueia qualquer edicao ("atue apenas no item de aprovacao") | Nao existe na prod |
| Quick action `Opportunity.ReassignCLevelApproval` "Revisao Diretoria" | Botao que abre o flow de tela | Igual em prod, retrieve e staging |
| Flexipage `OpportunityRecordPageB2B` | Botao visivel so na fase Validacao tecnica (prod: Viabilidade); componente LWC de itens de aprovacao | A versao da prod tem o campo SDR__c na pagina, que o retrieve e a staging nao tem |
| Apex `ApprovalWorkItemsController` + teste | `getApprovalWorkItems(recordId)`: lista os ApprovalWorkItem da oportunidade (with sharing, sem cacheable, LIMIT 200, erro propagado com mensagem) | Prod tem a versao antiga (sem LIMIT, erro engolido: tabela vazia). Teste: 2 metodos, passam na staging, **cobertura 55%** |
| LWC `approvalWorkItems` | Tabela com nome (link), status traduzido, revisado por, atribuido a, comentarios, data; botao atualizar | **Identico** em prod e staging; nao esta no retrieve |
| Objeto Opportunity | Campos usados ja existem nas duas orgs: `ResponsibleTeam__c` (valores Vendedor/GR, Arquitetura, Backoffice, Gerencia, Head, C-Level), `Bypass__c`, `Send4Approval__c`, `ArchitectureApproved__c`, `BackofficeForm__c` | Nenhum campo novo e necessario para a funcionalidade |
| Filas e papeis (`*`) | Vieram por curinga no package.xml | **Nao fazem parte da funcionalidade**: fila Arquitetura no retrieve esta sem os 20+ membros da prod; papel B2B_Head_B2B tem pai diferente na prod. Deploy deles apagaria membros e mudaria a hierarquia |
| Permission sets | Acesso a classe `ApprovalWorkItemsController` ja existe na prod em Approvers, ApproversNoGR, ArquiteturaB2B, BackofficeB2B, GeneralPermissionsB2B e SalesmanGR | Nada a implantar |

## 3. Onde esta implantado

| Item | Prod (btp-prod) | Preprod/staging | Retrieve |
|---|---|---|---|
| Encaminhar para C-Level | v3 ativa, 03/07/2026, Iago | v9 ativa, 25/08/2026, Diego (v5 Thiago Almeida 06/08; v6-v8 Diego 19/08) | = v8 (19/08) |
| Processo de fases | v8 ativa, 03/07/2026, Iago | v22 ativa, 25/08/2026, Diego (v14-18 Thiago jul/ago; v19-21 Diego) | = v20 (19/08) |
| Orquestracao OpportunityApprovalSteps_B2B | v5 ativa, 09/02/2026, Iago | v9 ativa, 25/08/2026, Diego | nao esta no retrieve |
| ApprovalWorkItemsController | versao antiga (sem LIMIT, erro engolido); cobertura 4/6 linhas | versao nova = retrieve; cobertura 55% (rodado hoje) | nova |
| VR BloqueiaAlteracaoRevisaoDiretoria | **nao existe** | existe, ativa | existe |
| Flexipage | botao em Viabilidade; tem SDR__c | botao em Validacao tecnica; sem SDR__c | = staging |
| LWC approvalWorkItems | igual | igual | ausente |
| Uso real | 20 opps em revisao (18 Head, 2 C-Level); 90 dias: Paul Nabih Raad (Head B2B) 110 itens concluidos + 18 pendentes, Gilmar Balbinot (CLevel) 12 + 2 | 5 opps C-Level em Validacao tecnica (testes) | - |

Conclusao: a funcionalidade **ja esta em producao desde 03/07 na versao do Iago** e esta sendo usada (Paul e Gilmar). O que
esta na staging e uma **segunda versao** (Thiago, depois Diego, agosto), com correcoes e com a mudanca de fase. O retrieve e
uma foto intermediaria dessa segunda versao.

## 4. Diferencas

**Retrieve x prod** (o que a prod nao tem):
- Encaminhar: decisao "Aprovador encontrado?" + tela de falha "nao foi encontrado aprovador ativo" + filtro `IsActive` na busca
  do usuario. Na prod, sem esses, o flow reatribui ao primeiro usuario do papel, ativo ou nao.
- Processo de fases: regra da diretoria muda de Viabilidade para Validacao tecnica (1 linha).
- Flexipage: visibilidade do botao muda de Viabilidade para Validacao tecnica; prod tem SDR__c a mais.
- Apex: LIMIT 200, erro propagado, teste reescrito.
- Opportunity: VR nova BloqueiaAlteracaoRevisaoDiretoria. Fora do escopo C-Level, o retrieve tambem traz VRs
  BloqueiaAlteracaoContaVendedor, BloqueiaAlteracaoTipoNegociacao e ObrigaTipoEmNegociacao (nao existem na prod),
  BloqueiaAlteracaoAguardandoContrato alterada (Stage__c) e **BloqueiaAlteracaoManualFase inativa** (na prod esta ativa).
  Campo ResponsibleTeam__c: prod tem o valor inativo "Viabilidade" e a picklist restrita; retrieve nao. Prod tem campos que
  a staging nao tem: DeliveryTerm__c, SDR__c, SLATechValidArch__c.
- Fila Arquitetura sem membros; papel B2B_Head_B2B com pai B2B_Delivery (prod: B2B_BackofficeArchitect).

**Retrieve x staging** (o que a staging ganhou depois, 25/08):
- Encaminhar v9: decisao "Papel encontrado?" (se o papel nao existe, tela de falha em vez de buscar usuario com papel nulo);
  filtro do item aceita Assigned a fila Arquitetura **ou ao proprio usuario** (`1 AND 2 AND (3 OR 4)`).
- Processo de fases v22: falha de notificacao engolida (SwallowNotificationFault); `Bypass__c` = true nas gravacoes; na
  aprovacao da diretoria tambem `Send4Approval__c` = true (reenvia a orquestracao para a Arquitetura decidir de novo).
- Opportunity: staging tem `SolutionArchitect__c` (lookup User, "arquiteto da solucao") e LastSyncTime, que o retrieve nao tem.
  Esse campo interessa aos relatorios de arquitetura (item 1, opcao ii, do plano de 18/09).
- Classe, teste, flexipage, quick action, fila e papeis: iguais.

**Prod x staging fora do pacote**: orquestracao v5 (prod) x v9 (staging); LWC identico.

## 5. Riscos e lacunas

1. **A decisao do diretor consome o item da Arquitetura.** O item reatribuido e o "Aprovacao - Arquitetura"; quando o Head
   aprova, a orquestracao segue como se a arquitetura tivesse aprovado. Na prod (v8) o processo de fases so grava
   ResponsibleTeam = Arquitetura e notifica; a viabilidade tecnica nunca e feita por um arquiteto. A staging v22 corrige com
   Send4Approval = true (reenvia), mas isso gera **nova submissao** e o item anterior fica Completed; confirmar que a
   orquestracao dispara de novo com a oportunidade travada. E tambem por isso que Paul Nabih Raad aparece com 110 itens
   "concluidos" e 18 pendentes nos relatorios de Arquitetura: sao revisoes de Head, nao trabalho de arquiteto.
2. **Fase sem caminho padrao no processo de fases.** Se o item for reatribuido numa fase e decidido em outra (a
   oportunidade pode mudar de fase por outro caminho), ou se a prod receber a versao nova enquanto ha 20 revisoes abertas em
   Viabilidade, a decisao do diretor cai no "Return approval step" sem conector: nada e gravado, ResponsibleTeam continua
   Head/C-Level, a VR nova mantem a oportunidade travada para sempre (so Bypass destrava).
3. **Head para tipo sem papel (B2G e Tipo vazio, 1.400 oportunidades abertas).** `DirectorValueSelected` monta
   `B2B_Head_B2G`, que nao existe. Na prod (v3) e no retrieve (v8) o papel vem nulo e a busca de usuario vira "papel = nulo":
   o flow pega o primeiro dos **1.734 usuarios ativos sem papel** e reatribui o item de aprovacao a ele. Nos ultimos 90 dias
   isso nao aconteceu (so Paul, Gilmar e 1 item do Iago), mas e questao de alguem escolher Head numa B2G. A staging v9
   corrige (Papel encontrado?).
4. **Item ja assumido por uma pessoa.** O flow busca o item Assigned a fila Arquitetura (staging: ou ao proprio usuario). Se um
   arquiteto ja reatribuiu o item para si (a pratica combinada com o Vilson em 18/09), o Get retorna vazio e a acao de
   reatribuir recebe Id nulo: erro generico de flow, sem tela de falha propria. Nao ha decisao "item encontrado?".
5. **Cobertura 55%** no ApprovalWorkItemsController: deploy para prod com RunSpecifiedTests exige 75% por classe. Ou o
   teste cobre o catch (hoje impossivel sem massa de ApprovalWorkItem), ou o deploy roda RunLocalTests (cobertura geral da
   prod), ou a classe muda (tirar o try/catch e deixar o erro subir; o LWC ja trata).
6. **Pacote com curingas.** Queue `*` e Role `*` no package.xml: um deploy desse pacote como esta apagaria os membros da fila
   Arquitetura na prod e moveria papeis. Opportunity.object inteiro desativaria BloqueiaAlteracaoManualFase e traria 3 VRs
   de outra demanda. Flexipage tiraria o campo SDR__c da pagina.
7. **Ativos/inativos**: prod v3 nao filtra usuario ativo (Gilmar Balbinot e o unico CLevel; se sair, o flow reatribui a um
   inativo). Corrigido a partir da v8.
8. **Sem restricao de quem aciona** e sem registro de quem pediu (o comentario vai no item, o anexo fica na oportunidade).
9. Relatorios de 18/09: nao usam ResponsibleTeam__c e o campo nao tem historico (trackHistory false). O tempo com a
   diretoria entra como tempo de arquitetura nos itens (o item continua "Aprovacao - Arquitetura") e no historico de fases.
   Para expurgar, precisa de historico do campo ou de um carimbo de data no envio e no retorno.

## 6. Roteiro de teste na preprod (staging v9/v22)

Usuarios: CLevel ativos = Alex Patrik da Silva (Admin Acesso) e Priscila Lima (sysadmin). **Nenhum Head ativo** na staging
(Erika Sutto B2B_Head_B2S, Matheus Rancan Blink, Paul/Marcos/Matheus GeneralDirector, todos inativos): para o caso
"diretor encontrado" com Head, ativar um usuario de teste no papel B2B_Head_B2B antes. Oportunidade base: B2B, Tipo B2B,
Send4Approval marcado, em Validacao tecnica com item "Aprovacao - Arquitetura" Assigned a fila Arquitetura.

| # | Caso | Passos | Esperado |
|---|---|---|---|
| 1 | Diretor encontrado (C-Level) | Botao Revisao Diretoria > C-Level > arquivo `AVAL-FINANCEIRA_teste.pdf` > comentario > concluir | ResponsibleTeam = C-Level; item com Alex ou Priscila (o primeiro ativo do papel) com o comentario; oportunidade bloqueada para edicao (mensagem "em revisao pela diretoria"); arquivo anexado |
| 2 | Sem papel | Oportunidade Tipo B2G > Head | Tela "nao foi encontrado aprovador ativo"; nada gravado; item continua na fila |
| 3 | Sem usuario ativo no papel | Tipo B2B > Head (sem Head ativo na staging) | Mesma tela de falha; nada gravado |
| 4 | Sem anexo ou nome errado | Arquivo `proposta.pdf` | Tela "arquivo valido", arquivo apagado, volta ao upload; com nome certo segue |
| 5 | Item ja com pessoa | Antes, reatribuir o item a um arquiteto; rodar o botao com outro usuario | Hoje: erro generico de flow (confirmar); esperado depois de corrigir: tela informando que o item ja foi assumido |
| 6 | Item com o proprio usuario | Reatribuir o item ao usuario que vai acionar o botao (staging v9) | Encontra e reatribui ao diretor |
| 7 | Aprovacao do diretor | Logar como o CLevel, aprovar no item | ResponsibleTeam = Arquitetura, Bypass = true, Send4Approval = true; **nova** submissao com item "Aprovacao - Arquitetura" na fila; notificacao ao gerente da conta ou dono; oportunidade destravada |
| 8 | Rejeicao do diretor | Rejeitar no item | Fase Em negociacao, ResponsibleTeam Vendedor/GR, Send4Approval false, ArchitectureApproved false, notificacao |
| 9 | Fase trocada no meio | Reatribuir na Validacao tecnica, mover a oportunidade para outra fase (com Bypass) e decidir | Confirmar o comportamento do caminho padrao (risco 2) |
| 10 | Componente Itens de aprovacao | Abrir a oportunidade dos casos 1, 7 e 8 | Tabela lista os itens com status traduzido; botao atualizar reflete a mudanca sem recarregar |

## 7. Plano de deploy para prod (se a decisao for levar a versao da staging)

Antes: decidir a fase (Viabilidade x Validacao tecnica) e o que fazer com as 20 revisoes abertas na prod em Viabilidade
(concluir antes do deploy, ou manter na prod as duas regras de fase no processo de fases, o que e a opcao segura).

Ordem, com package.xml **explicito** (sem curingas), sempre check-only antes:

1. `ApexClass` ApprovalWorkItemsController + ApprovalWorkItemsControllerTest (resolver a cobertura antes, risco 5).
2. `CustomObject` Opportunity **so** a `ValidationRule` `Opportunity.BloqueiaAlteracaoRevisaoDiretoria` (tipo ValidationRule no
   package, nao o objeto inteiro).
3. `Flow` OpportunityStageApprovalProcess_B2B (versao da staging v22, com a regra de fase decidida) e
   OpportunitySendCLevelApproval_B2B (v9). Se a orquestracao v9 da staging tambem mudou por causa disso, incluir
   OpportunityApprovalSteps_B2B; conferir o diff v5 x v9 antes.
4. `FlexiPage` OpportunityRecordPageB2B: **mesclar** a mao (visibilidade do botao) sobre a versao da prod, para nao perder
   SDR__c. `QuickAction` e LWC nao mudam.
5. Fora do pacote: Queue, Role, demais VRs e campos do objeto.

```xml
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types><members>ApprovalWorkItemsController</members><members>ApprovalWorkItemsControllerTest</members><name>ApexClass</name></types>
  <types><members>Opportunity.BloqueiaAlteracaoRevisaoDiretoria</members><name>ValidationRule</name></types>
  <types><members>OpportunitySendCLevelApproval_B2B</members><members>OpportunityStageApprovalProcess_B2B</members><name>Flow</name></types>
  <types><members>OpportunityRecordPageB2B</members><name>FlexiPage</name></types>
  <version>63.0</version>
</Package>
```

Depois do deploy: rodar os casos 1, 7 e 8 na prod com uma oportunidade de teste; conferir que as 20 revisoes abertas
continuam decidiveis; atualizar os relatorios de Arquitetura para tirar Paul e Gilmar da fila pendente (sao revisoes de
diretoria, nao arquitetura).

## 23/09: SENAC SC (006V200000yiZh3IAE), aprovacao comercial presa, e causa raiz das aprovacoes que nao chegam ao gerente

Causa raiz (vale para a org toda): a aprovacao comercial vai para o campo Gerente da Conta (ManagerAccount__c) da
oportunidade. Em 303 oportunidades B2B abertas esse campo e o proprio dono (64 na equipe B2G do Samuel Helbig); nelas a
solicitacao nasce no nome do vendedor e o gerente nunca ve. Na SENAC o Gerente da Conta era o Hermes (dono); o script 27
(15/09) moveu so o item de orquestracao para o Samuel e os dois registros descolaram, com bloqueio orfao na oportunidade.

Tentativas 23/09: script 51 (DML no item de orquestracao) e 51b/51c (acao padrao reassignApprovalWorkItem, direta e em dois
passos) falharam com UNABLE_TO_UPDATE_RECORD_LOCK. Solucao: 51d cancelou a orquestracao 00022847 e recuperou a submissao
(recall pela acao padrao recallApprovalSubmission); 51e destravou a oportunidade (Approval.unlock) e a preparou
(Send4Approval = false, Gerente da Conta = Samuel), com a permissao "Administrativo / Validacao B2B" atribuida ao Diego so
durante a execucao (a regra BloqueiaAlteracaoAprovacaoComercial exige $Permission.SalesManager) e removida em seguida.
Fase continua "Aprovacao comercial" e ArchitectureApproved__c preservado. Proximo passo: Hermes reenvia pela tela; conferir
que o item nasce com o Samuel.

Pendente: corrigir o Gerente da Conta nas 303 oportunidades (planilha para os gerentes validarem em
org/tmp/gerente_conta/, fora do git; 182 vendedores sem gerente na hierarquia de usuarios) e trava para o vendedor nao ser
o proprio Gerente da Conta. Licao: reatribuicao de aprovacao so pelo botao Reatribuir; nunca alterar o item de orquestracao.
