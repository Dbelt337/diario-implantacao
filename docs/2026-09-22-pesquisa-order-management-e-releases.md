# 22/09/2026 - Pesquisa: Order Management do Communications Cloud e releases Spring '26 / Summer '26

Objetivo: fundamentar as historias no que a plataforma tem de mais atual. Duas perguntas: (1) o que o Order Management
(OM) do Communications Cloud faz hoje e para onde esta indo; (2) o que mudou nas duas ultimas releases que altera o desenho
das historias. Fontes oficiais citadas no fim; onde a fonte oficial nao pode ser aberta pela sessao, esta indicado.

## 1. Order Management: o que existe e o que e "moderno"

### 1.1 O que a org tem hoje

Pacote Vlocity CMT Summer 2026 (managed package), com Comms Cloud Plus licenciado (EPC, Industries CPQ, Order Management,
Digital Commerce, CLM). O OM em uso e o **Industries Order Management** do pacote (tambem chamado XOM): decomposicao comercial
-> tecnica, plano de orquestracao gerado dinamicamente, itens de orquestracao (auto task, callout, manual task, milestone,
push event), filas de fallout, regras de retentativa de conexao, alteracoes em voo (amend, cancel, supplemental) ate o ponto de
nao retorno, jeopardy (SLA por item). Ja existem na org System Interfaces do OM apontando para o MuleSoft (Customer Assets e
Inicio do Faturamento) e a classe BTecparOMCustomSystemInterface.

### 1.2 Como o OM nativo resolve o que as historias pedem

| Necessidade das historias | Mecanismo nativo do OM | Observacao |
|---|---|---|
| Ativar/provisionar o pedido no Customer Core, SAP e Voalle (W-000088, 093, 094, 118, 164) | Decomposition Relationships (1:1, 1:N, N:1, por classe de produto) geram Fulfilment Request e Fulfilment Request Lines; o plano de orquestracao executa callouts por System Interface | O adapter customizado so cabe onde o formato do parceiro nao e TMF |
| Chamadas externas com robustez | Item do tipo callout com regras de retentativa (connection retry rules), fila de fallout para intervencao manual, jeopardy por SLA | Sincrono dentro do item, assincrono no plano: o usuario nunca espera callout na tela |
| Pedidos grandes (multi-site B2B, W-000119, 098) | OrderSubmitMode em modo fila (submissao assincrona) e OMOrderViewLoadingMode | Configuracao, nao codigo |
| Upgrade, downgrade, swap, cancelamento (W-000100, 116, 125, 129, 165, 166, 171, 172) | Change orders (MACD) decompostos e orquestrados; supplemental orders para alterar pedido em voo; amend e cancel ate o ponto de nao retorno, com plano de rollback | As historias devem nomear "supplemental order" e "ponto de nao retorno" em vez de "cancelar e recriar" |
| Eventos de parceiro (rede neutra, campo) | Push events do plano + TMF622/TMF641 outbound notification | Entrada continua via Apex REST TMF (ja existe) |

### 1.3 Para onde a Salesforce esta indo

- **Dynamic Revenue Orchestrator (DRO)**, Spring '26: orquestracao de fulfillment no Core (Agentforce Revenue Management),
  pre-integrado ao Industries CPQ, com Enhanced Decomposition Workspace alinhado ao TM Forum SID, suporte a Move e Change of
  Plan, aplicavel a qualquer tipo de transacao e com painel de metricas de fulfillment. A Salesforce o apresenta como "primeiro
  passo pratico" de migracao do managed package para o Core.
- **Communications Cloud on Core**, Summer '26: Consumer Sales APIs (carrinho sem cotacao, navegacao anonima), Billing
  Accounts, multi-subscriber, Sales Transaction Line Editor, Agentforce for Enterprise Quoting. So para clientes no Core.
- **Managed package**: continua evoluindo (CPQ mixed mode para migracao gradual das cart APIs, cart templates, trim mode,
  deep clone, availability/eligibility interfaces, promocoes de 100 mil linhas, OmniStudio hybrid e Migration Assistant CLI).
  Deprecacoes anunciadas: Billing & Usage Assistant e Einstein Quick Quote for ESM.
- **Sem release notes de OM/XOM do pacote no Summer '26** (fonte Stratus Carta): o investimento novo esta no DRO.

### 1.4 Recomendacao para a Brasil Tecpar (trade-off)

- **Plan A (recomendado para este programa)**: Industries OM do pacote, configurado a fundo: decomposicao por classe,
  planos com callouts e retentativa, OrderSubmitMode em fila, supplemental orders para MACD, ponto de nao retorno definido por
  familia, jeopardy com SLA. Motivo: licenca vigente, System Interfaces e adapters ja em producao, equipe SysMap treinada no
  pacote, e as cart APIs "Standard" com mixed mode permitem migrar por partes sem big bang.
- **Plan B (fallback)**: manter orquestracao no MuleSoft (order-papi) para os parceiros que nao aceitam contrato TMF, com o OM
  do pacote so publicando eventos; e o que ja acontece hoje para SAP e Voalle e nao deve crescer.
- **Plan C (roadmap)**: avaliacao do DRO/Core em 2027, comecando pelo catalogo (a org ja tem as PSLs de Product Catalog
  Management e Unified Catalog atribuidas, 1,2 milhao, 5 em uso), com o Migration Assistant do OmniStudio e o mixed mode do CPQ
  como trilha. Decisao a registrar com o presidente por implicar novo licenciamento (Agentforce Revenue Management).

## 2. Spring '26 e Summer '26: o que muda nas historias

| Mudanca (release) | Impacto nas historias | Works |
|---|---|---|
| Flow Orchestration sem limite de uso, feature padrao (Spring '26 / Summer '26) | Orquestracoes de aprovacao e de etapas humanas podem crescer sem custo por execucao; padrao unico de aprovacao = Flow Approval Orchestration | todas com aprovacao (098, 115, 129, 160, 163, 165, 166, 169) |
| Flow Approvals: componente Request Approval com escolha do primeiro aprovador; tipos Autolaunched e Record-Triggered Approval Orchestration (Spring '26); aprovacao unanime em grupos e visibilidade de dependencias (Summer '26) | Alcadas por valor e desconto sem Apex nem Advanced Approvals; aprovacao de cortesia e de condicoes especiais como record-triggered approval | 098, 144, 160, 163, 165, 169 |
| Apex em user mode por padrao a partir da API 67.0 (Summer '26) | Classes novas e atualizadas (adapters, Apex REST TMF641/Delivery/Rede Neutra, invocaveis) passam a respeitar objeto, campo e sharing; revisar `with sharing`/`inherited sharing` e FLS nos payloads | 087, 105, 110, 130, 131, 132 e todo adapter existente |
| Retirada da autenticacao legada (SOAP login, usuario/senha OAuth) e Connected Apps caminhando para External Client Apps (Winter '27) | Usuarios de integracao com External Client App e client credentials; MuleSoft, Marketing Cloud Connect e BI precisam migrar | 087, 105, 130, 131; inventario de integracoes de 21/09 |
| MFA obrigatoria em producao e sandbox; step-up em acoes sensiveis (download de relatorio) | Perfis de campo e integracao; teste com Priscila e Tayza ja esbarrou em MFA | 090, 091 |
| Retirada das APIs 31 a 40 (Summer '27 deprecia, Summer '28 retira) | Pacotes e integracoes antigas do Mule/BI devem apontar para versoes atuais | inventario de integracoes |
| BRE: 100 mil linhas por Decision Table, 10 versoes, 500 tabelas, versionamento com lock, Decision Explainer, chamada direta de Decision Tables por Integration Procedure sem Apex (Summer '26) | Regras de preco, multa, elegibilidade e alcada em Decision Tables versionadas e chamadas do OmniScript/IP; sem classes de calculo | 107, 108, 109, 121, 128, 165, 171, 172 |
| Context Service: 80 nos, 1.600 atributos, transformacao via DPE, geracao de Apex (Summer '26) | Contexto de elegibilidade e qualificacao do catalogo escala sem objeto custom de contexto | 056, 113, 114 |
| Document Generation: componente Generate Document em paginas e flows sem LWC wrapper, marca d'agua, sumario automatico, lotes (Summer '26); Contracts com documentos localizados e tokens preservados para plataformas que nao sao DocuSign | Minuta, aditivo e contrato gerados por acao padrao; tokens preservados viabilizam assinatura por outro fornecedor | 082, 089, 106, 122, 126 |
| OmniStudio: hybrid runtime, Migration Assistant (CLI), DataMapper com versionamento e ativacao controlada, resume entre usuarios (Summer '26) | Versionar DataMappers da jornada B2C; jornada retomavel entre convidado e vendedor; preparar migracao para runtime standard | 084, 086, 093, 094 |
| Industries CPQ: mixed mode Standard/Classic nas cart APIs, cart templates, trim mode para carrinhos grandes, deep clone de cotacao/pedido, availability & eligibility interfaces, promocoes grandes (Summer '26) | Multi-site e cotacao filha por deep clone; carrinhos grandes com trim mode; elegibilidade por interface nativa | 098, 119, 056, 114, 128 |
| Scheduled flows com tamanho de lote configuravel (1 a 200) e 20 operadores de data em decisoes (Summer '26) | Reguas de lembrete, expiracao e fim de degustacao em flow agendado sem Apex batch | 066, 077, 124, 143, 145 |
| Data Processing Engine: joins por lookup, hierarquia, on-demand, preview (Summer '26) | Relatorios de auditoria e consolidacoes (cortesia/swap, instalacoes nao realizadas) sem objeto custom de apoio | 061, 079, 168 |
| Field Service: sem mudanca estrutural nas duas releases relevante para as historias; Einstein for Field Service ja atribuido | manter | 063, 094, 131 |

## 3. O que entra nas historias por causa desta pesquisa

1. Nas historias de OM: nomear os mecanismos nativos (Decomposition Relationship, Fulfilment Request, Orchestration Plan,
   item callout com retry, fallout queue, OrderSubmitMode em fila, supplemental order, ponto de nao retorno, jeopardy) e
   deixar claro que a tela nunca espera callout.
2. Nas historias com Apex: registrar que a partir da API 67 o codigo roda em user mode; sharing e FLS explicitos.
3. Nas historias de integracao e seguranca: External Client App com client credentials; nada de usuario/senha.
4. Nas historias de regra (preco, multa, alcada, elegibilidade): Decision Tables versionadas chamadas por IP.
5. Nas historias de documento: componente Generate Document padrao; assinatura sem DocuSign, tokens preservados.
6. Registrar o Plan A/B/C do OM como decisao de arquitetura e levar o Plan C ao presidente.

## Referencias

- Industries Order Management (visao geral): https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5
- Order Decomposition: https://help.salesforce.com/s/articleView?id=ind.comms_t_order_decomposition_229652.htm&language=en_US&type=5
- Order Decomposition Configuration: https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5
- Order Orchestration (nao abriu pela sessao, erro de CSS na pagina; conferir no navegador): https://help.salesforce.com/s/articleView?id=ind.comms_t_order_orchestration_231022.htm&type=5
- Trailhead, IOM Orchestration Foundations: https://trailhead.salesforce.com/content/learn/modules/industries-order-management-orchestration-foundations/meet-industries-order-management-orchestration
- Trailhead, IOM Decomposition Foundations: https://trailhead.salesforce.com/content/learn/modules/industries-order-management-decomposition-foundations/meet-industries-order-management-decomposition
- Trailhead, Complex Order Decomposition and Orchestration with Agentforce Revenue Management (DRO): https://trailhead.salesforce.com/content/learn/modules/complex-order-decomposition-and-orchestration-with-revenue-cloud
- TM Forum APIs do Communications Cloud (TMF622 v4/v5 inbound e outbound, TMF641): https://developer.salesforce.com/docs/industries/communications/guide/TMF622v5.html , https://developer.salesforce.com/docs/industries/communications/guide/TMF622_outbound.html (403 pela sessao), https://developer.salesforce.com/docs/industries/communications/references/tmf641
- Salesforce Summer '26 Release Notes: https://help.salesforce.com/s/articleView?language=en_US&id=release-notes.salesforce_release_notes.htm&release=262&type=5
- Salesforce Spring '26 Release Notes: https://help.salesforce.com/s/articleView?id=release-notes.salesforce_release_notes.htm&language=en_US&release=260&type=5
- Trailhead, Summer '26 Release Highlights: https://trailhead.salesforce.com/content/learn/modules/summer-26-release-highlights
- Developer's Guide to the Summer '26 Release: https://developer.salesforce.com/blogs/2026/06/the-salesforce-developers-guide-to-the-summer-26-release
- Comunicado Spring '26 (DRO, Enhanced Decomposition Workspace): https://www.salesforce.com/news/stories/spring-2026-product-release-announcement/
- Resumo CME/CPQ/OM Summer '26 (Stratus Carta): https://www.stratuscarta.com/post/communications-media-and-energy-clouds-omnistudio-industries-cpq-om-summer-26-262-release
- Resumo Communications Cloud Spring '26 (Slalom, 403 pela sessao): https://medium.com/slalom-blog/salesforce-communications-cloud-spring-26-release-c6a79f57a423
- Flow Summer '26 (Salesforce Break): https://salesforcebreak.com/2026/04/25/summer-26-flow-updates/
- Spring '26 admins/devs (Salesforce Break): https://salesforcebreak.com/2026/01/06/salesforce-spring-26-release-notes/
- Summer '26 seguranca (SFDC Penguin): https://sfdcpenguin.com/blog/salesforce-summer-26-release-notes-the-agentic-enterprise-meets-enforced-security/
