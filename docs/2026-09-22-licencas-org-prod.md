# 22/09/2026 - Licencas e capacidades disponiveis na org de producao (btp-prod)

Fonte: PermissionSetLicense, UserLicense, PackageLicense e InstalledSubscriberPackage consultados em 22/09/2026. Serve de
base obrigatoria para o desenho das historias: toda solucao precisa caber no que esta listado aqui. O que nao esta aqui
nao pode ser assumido (ex.: DocuSign, Advanced Approvals do CPQ Steelbrick, motor de assinatura eletronica).

## Licencas de usuario

| Licenca | Total | Em uso |
|---|---|---|
| Salesforce (full) | 3.968 | 2.214 |
| Salesforce Integration (usuario de API) | 5 | 2 |
| Partner Community | 1.185 | 0 |
| Customer Community Plus Login | 24.000.000 | 0 |
| Identity | 100 | 0 |
| Guest User | 25 | 1 |
| Cloud Integration User / Sales Insights Integration User / Analytics Cloud Integration User | 1 / 1 / 2 | 1 / 1 / 0 |

## Communications Cloud (pacote Vlocity CMT Summer 2026, licenca ativa)

| Capacidade | PSL | Total | Em uso | Leitura |
|---|---|---|---|---|
| Comms Cloud Plus (EPC, Industries CPQ, Order Management, Digital Commerce, CLM/Contracts) | vlocity_cmt_CommunicationsCloudPlusPsl | 2.100 | 2.100 | licenciado, PSL esgotado nominalmente (atribuido a todos); revisar atribuicao |
| Comms Sales | CommsCloudSalesPsl | 2.100 | 261 | licenciado |
| Business Processes for Communications | CommsB2CBusinessProcessesPsl | 2.100 | 0 | licenciado, nao usado |
| Service Console for Communications | CommsB2CServiceConsolePsl | 2.100 | 0 | licenciado, nao usado |
| Document Generation (CME) | vlocity_cmt_DocGenIndCmeUserPsl | 2.100 | 646 | licenciado, em uso |
| OmniStudio Designer | OmniStudioDesigner | 2.100 | 265 | licenciado |
| Business Rules Engine Designer | BREDesigner | 2.100 | 0 | licenciado, nao usado (Decision Matrices e Expression Sets disponiveis) |
| Context Service Admin / Runtime | ContextService*Psl | 1,2M / 2,4M | 5 / 0 | licenciado |
| Industries Stage Management | IndustriesStageManagementPsl | 2.100 | 257 | em uso |
| Actionable Event Orchestration (Designer/Runtime) | ActionableEventOrch*Psl | 2.100 | 258 / 257 | em uso |
| Product Catalog Management / Unified Catalog (PCM, RLM) | ProductCatalogManagement*, UnifiedCatalog* | 1,2M / 2,4M | 5 / 3 | disponivel (catalogo unificado da plataforma, distinto do EPC) |
| Revenue Management Promotions Run Time, RLM MultiRecipient | RevPromotionsManagementPsl, RevLifecycleMgmtMultiRecipientPsl | 2.100 | 0 | disponivel |
| Actionable Relationship Center, Interaction Summary, Assessments, Document Checklist, Record Aggregation, Criteria-Based Search | IndustriesARCPsl e outros | 2.100 a 4.200 | 0 | disponiveis |
| Complaints Management, Case Referral, Care Plans, Group Membership | *Psl | 2.100 | 0 | disponiveis |

## Field Service (pacote FSL Summer 2026 + Appointment Assistant)

| Capacidade | Total | Em uso |
|---|---|---|
| Field Service Standard | 18.661.867 | 1.576 |
| Field Service Scheduling | 2.688 | 1.244 |
| Field Service Dispatcher | 1.448 | 441 |
| Field Service Mobile | 2.688 | 1.590 |
| Field Service Appointment Assistant (last mile) | 2.687 | 1.242 |
| Einstein for Field Service | 1.553 | 1.012 |
| Inventory Count Manager / User, Work Order Estimation, Service Part Return, Book Service Appointment | 2.100 | 9 / 257 / 0 / 0 / 0 |

## Marketing Cloud

Marketing Cloud Connect (et4ae5 262.0) e MarketingCloudConnectedApp instalados e ativos; conexao viva (26 mil chamadas por
mes). Jornadas, e-mail e SMS ficam do lado do Marketing Cloud Engagement. **WhatsApp e um add-on do MC Engagement, nao
visivel pela org Salesforce: confirmar no contrato/conta do MC antes de assumir.**

## Einstein / Agentforce / Data Cloud

| Capacidade | Total | Em uso |
|---|---|---|
| Agentforce (Default), Einstein Prompt Templates | 1.553 | 1.012 |
| Einstein Agent | 3.420 | 25 |
| Einstein Next Best Action (requisicoes ilimitadas), Recommendation Builder | 1.553 | 0 |
| Einstein Conversation Insights, Search, Service Replies, Work Summaries, Knowledge Creation | 1.553 a 2.000 | 0 |
| Data Cloud: Customer Data Cloud for Marketing (200.000), Remote Data Cloud, Segment Intelligence, pacotes ssot e cdpactvstrgptnr | | 0 |

Data Cloud esta provisionado (pacotes e PSLs), sem uso. Agentforce tem PSL atribuida a 1.012 usuarios sem uso conhecido.

## Plataforma (Sales/Service) relevante para as historias

Omni-Channel (roteamento de Lead, Case e objetos custom) faz parte da licenca Salesforce; Service User PSL 1.867 (11 em uso);
Sales Console 2.102; Sales Engagement Basic 100 (1); Pipeline Inspection 2.102 (1); Salesforce Forecasting 2.101; Slack
Service User 1.868 (0); Partner Cloud Access 1.185 (0); Code Builder 40; Scale Center 5; Salesforce API Integration 5 (1).
Flow Approval Orchestration (aprovacoes) e nativo da plataforma e ja esta em uso (orquestracao OpportunityApprovalSteps_B2B).

## O que NAO existe na org (nao assumir nas historias)

- **Assinatura eletronica**: nenhum pacote DocuSign, Adobe Sign ou equivalente instalado; nenhuma PSL. A integracao DocuSign
  embutida no Vlocity CLM (custom settings DocuSignReminder*, objetos vlocity_cmt__DocuSign*) so funciona com conta DocuSign
  contratada, que nao existe. Ate decisao de fornecedor, assinatura = aceite por evidencia (upload de arquivo como ContentVersion
  vinculado a Quote/Contract) ou aceite eletronico simples com registro de evidencia; qualquer motor externo entra pelo MuleSoft.
- **Advanced Approvals (Salesforce CPQ / Steelbrick)**: nao esta no stack. Aprovacoes = Flow Approval Orchestration (nativo)
  ou Approve Discounts do carrinho Industries CPQ; escolher um padrao unico.
- **Salesforce CPQ (Steelbrick), Revenue Cloud Billing, B2B Commerce**: nao instalados.
- **ESM / Enterprise Sales Management, MuleSoft Direct**: nao confirmados; nao assumir.
- **Pacote de assinatura/biometria de terceiros (unico, idwall, Datavalid)**: nao instalado.
