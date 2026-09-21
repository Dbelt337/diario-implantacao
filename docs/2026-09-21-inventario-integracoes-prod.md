# 21/09/2026 - Inventario de integracoes da org de producao (btp-prod)

Somente leitura. Fontes: listagem de metadados, retrieve completo de Apex (1.088 classes, 60 triggers), flows (91),
custom metadata (211 registros), Named/External Credentials e Remote Sites em `org/tmp/prod_code` (fora do git), consultas
em LoginHistory (30 dias), OmniProcess/OmniProcessElement, Vlocity SystemInterface, CronTrigger, User, ConnectedApplication.
Pedido do Diego: "levantar todas as integracoes do ambiente", incluindo o metadado IntegrationConfig.

## 1. Mapa por sistema externo

| Sistema | Papel | Como conversa com a org | Situacao |
|---|---|---|---|
| **MuleSoft** (api01-mulesoft-prd.brasiltecpar.com.br) | Barramento. Praticamente toda integracao de negocio passa por ele (app `btp-salesforce-eapi-prod`, `btp-tmf-service`, `btp-keycloak-api`) | Saida: Named Credential `MuleCallout` (OAuth client credentials no Keycloak via Mule) usada por Apex, OmniStudio e Vlocity OM. Entrada: Apex REST TMF641 e Delivery, usuario de integracao pelo connected app `IntegracoesBrasilTecpar` | ativo |
| **SAP** | Cliente/conta (BP code), materiais e estoque do tecnico, movimentacao patrimonial, faturamento | Via Mule: `get-base-account`, `person-material-handling`, `create-material-movement`, `create-technical-operational-movement`, `protocol-closure`, `customer`, `create-contract`, `get-credit-analysis` | ativo (contas, estoque, ordens de servico); patrimonio REQ-6 desligado por flag |
| **Voalle** (ERP/provisionamento) | Composicao e baixa de servico, status de solicitacao | Via Mule: `tickets/send-to-voalle`, `customer/{id}/assets`, `solicitation/{id}`; de-para de status em `Status_DePara__mdt` (15) | parcial: consulta ativa, baixa (REQ-7) desligada por flag |
| **Zendesk** | Atendimento; ordem de servico manual, comentarios, status | Via Mule: Named Credential `ZendeskStatusIntegration` (mesmo Keycloak), rotas `tickets/send-to-zendesk`, `solicitation/{id}`; `IdUserZendesk__mdt` (assignee 42146904356244, grupo 41309959551252) | ativo, com flag de seguranca em `CustomerServiceCommentCallout` ("manter false ate validacao") |
| **Ozmap** (rede/GIS) | Rota externa e liberacao de rede | Via Mule: `external-route/ozmap`, `asset-recovery/ozmap-release` | desligado por flag (`OzmapSyncEnabled__c` = false) |
| **CCD / Cobranca** | Evento de cobranca na recuperacao de ativo | Via Mule: `asset-recovery/ccd-charge` | desligado por flag |
| **Customer Core** | Sincronizacao de cliente e alteracao interna | Via Mule: `customer`, `customer/internal-alteration`; entrada TMF641 ServiceOrder (Customer Core -> Mule -> Apex REST) | saida desligada por flag; entrada publicada |
| **V.tal (Rede Neutra, REQ-8)** | Viabilidade, agenda, pedido e tracking do parceiro (TM Forum 622/645/646/673/697) | Via Mule: 11 endpoints em `NeutralNetworkEndpoint__mdt`, parceiro `NeutralNetworkPartner__mdt.Vtal` (base `/neutral-network/vtal`), entrada `NeutralNetworkInboundRestResource` | **rascunho**: contrato "draft", descricao diz "nao ativar sem OpenAPI oficial" |
| **Marketing Cloud** (Marketing Cloud Connect, et4ae5) | Jornadas, e-mail, eventos | Connected app "Salesforce Marketing Cloud": **26.307 logins em 30 dias pelo usuario Alan Cesar Honorio** (perfil Field Service Admin); 3 eventos de plataforma `et4ae5__JB_*__e`; 60+ remote sites do pacote | ativo |
| **Okta** | SSO SAML (`Okta_Brasil_TecPar`, certificado `BTP_SAML_ReqSign_2026`) | 10.485 logins SAML em 30 dias; connected app Okta com 126 logins | ativo |
| **BTP Governanca Hub** | Connected app do Gerson (criado 24/08) | 8.324 logins em 30 dias, usuario Gerson Da Silva Pereira | ativo; **finalidade a confirmar** |
| **Tableau / Data Analytics** ("Data Analytics PCP", "Data Analytics - INT6") | Extracao para BI | 246 logins, usuario Guilherme Elsas Ferreira De Carvalho (sysadmin) | ativo |
| **BrasilAPI** (brasilapi.com.br) | CEP | Remote site + Rest Action no OmniScript `BTecParPF/AddressAndClientData`; External Services `GetAddress`/`GetAddress3` (Named Credential GetAddress aponta para o Mule) | ativo |
| **cnpj.ws** (comercial.cnpj.ws) | Dados de CNPJ | Named Credential `CNPJPublicAPI` (Apex `CnpjWsService`, flow `Get_CNPJ_Details` via External Service `GetCnpjDetails`) | ativo; **chave de API gravada no metadado da credencial** (ver achados) |
| **Field Service mobile** | App do tecnico (Android/iOS) | 12.356 logins; remote site Google Maps (`sf_fieldservice__FSL_Google_Maps_API`) | ativo |
| **Data Cloud** (pacotes `ssot`, `cdpactvstrgptnr`, 11 auth providers de conectores) | Presente por pacote | Nenhum uso encontrado em Apex/flow | a confirmar se esta em uso |
| **Sales Insights** (OIQ), Agile Accelerator (agf) | Pacotes internos | Usuario `Insights Integration`; connected app `OIQ_Integration` | padrao |
| **Site publico "Rastreio de Atendimento"** | Consulta de atendimento por cliente (Experience/Site, usuario convidado) | Entrada sem login | ativo desde 02/07 |
| **Email-to-Salesforce** | Servico de e-mail padrao | `EmailServicesFunction` EmailToSalesforce | padrao |

Nao existem: Salesforce Connect (External Data Source), Outbound Messages, Change Data Capture configurado, Apex SOAP, handlers de e-mail de entrada.

## 2. Credenciais, endpoints e certificados

| Tipo | Nome | Destino | Autenticacao | Ultima alteracao |
|---|---|---|---|---|
| Named Credential | MuleCallout | https://api01-mulesoft-prd.brasiltecpar.com.br | External Credential MuleAuth: OAuth client credentials, token em `/btp-keycloak-api/api/token`; namespaces permitidos vlocity_cmt e vlocity_ins | 17/12/2025 Caio |
| Named Credential | ZendeskStatusIntegration | .../btp-salesforce-eapi-prod/api | MuleAuth (mesmo token) | 01/04/2026 Caio |
| Named Credential | GetAddress | https://api01-mulesoft-prd.brasiltecpar.com.br | External Credential GetAddress: OAuth client credentials no mesmo Keycloak | 23/01/2026 Caio |
| Named Credential | CNPJPublicAPI | https://comercial.cnpj.ws | External Credential Custom, chave de API como parametro | 22/05/2026 Iago |
| Remote Site | PrdMule / mule | api01-mulesoft-prd / api01-mulesoft-dev | legado (callout por URL) | dez/2025 |
| Remote Site | BrasilAPI | brasilapi.com.br | sem auth | dez/2025 |
| Remote Site | 128 demais | pacotes: 60+ Marketing Cloud (et4ae5, TenantSpecific), 45 FSL, 4 Vlocity, Google Maps, MetadataAPI, LWC | pacote | |
| Certificados | BTP_SAML_ReqSign_2026 (SAML), X30_Julho_2026 | | | |
| Auth Providers | 11, todos conectores padrao de Data Cloud/Marketing (Google, Facebook, LinkedIn, Microsoft, TikTok, X, Confluence, Gmail) | | | |
| SSO | SamlSsoConfig Okta_Brasil_TecPar | Okta | SAML | 30/07/2026 |

## 3. Saidas (Salesforce chama fora)

### 3.1 IntegrationConfig__mdt (14 registros; resolvido por `IntegrationEndpointConfig` e `BTecparIntegrationConfigProvider`)

| Registro | Metodo | Named Credential | Path | Ambiente | Quem usa |
|---|---|---|---|---|---|
| customerMulesoft | (vazio) | (vazio) | /btp-salesforce-eapi-prod/api/customer/ | (vazio) | IP BTecPar_BaseClientIntegration, `BTecparAssetCallout`, OM Customer Assets |
| createClientMulesoft | | | /btp-salesforce-eapi-prod/api/customer | | IP BTecPar_CreateClient |
| createContractMulesoft | | | /btp-salesforce-eapi-prod/api/create-contract | | IP BTecPar_CreateContract |
| creditAnalysisMulesoft | | | /btp-salesforce-eapi-prod/api/get-credit-analysis/ | | IP BTecPar_CreditAnalysisIntegration |
| technicalViabilityMulesoft | | | /btp-salesforce-eapi-prod/api/get-technical-viability | | IP BTecPar_TechnicalViabilityCheck |
| deliveryBillingEvent | | | /btp-tmf-service/serviceOrderingManagement/v4/listener/serviceOrderStateChangeEvent | | `DeliveryBillingEventQueueable` |
| ccdChargeEvent | POST | MuleCallout | /btp-salesforce-eapi-prod/api/asset-recovery/ccd-charge | prod | `CcdChargeAdapterImpl` |
| customerCoreInternalAlteration | PATCH | MuleCallout | /btp-salesforce-eapi-prod/api/customer/internal-alteration | prod | `CustomerCoreSyncAdapterImpl` |
| ozmapExternalRoute | POST | MuleCallout | /btp-salesforce-eapi-prod/api/external-route/ozmap | prod | `OzmapAdapterImpl` |
| ozmapNetworkRelease | POST | MuleCallout | /btp-salesforce-eapi-prod/api/asset-recovery/ozmap-release | prod | `NetworkDeactivationAdapterImpl` |
| sapAssetMovement | POST | MuleCallout | /btp-salesforce-eapi-prod/api/create-material-movement | **qas** | `SapAssetMovementAdapterImpl` |
| sapAssetWriteOff | POST | MuleCallout | /btp-salesforce-eapi-prod/api/create-technical-operational-movement | **qas** | `SapTechnicalOperationalAdapterImpl` |
| voalleServiceComposition | GET | MuleCallout | /btp-salesforce-eapi-prod/api/customer | **qas** | `VoalleServiceCompositionAdapterImpl` |
| voalleServiceDeactivation | PATCH | MuleCallout | /btp-salesforce-eapi-prod/api/tickets/send-to-voalle | **qas** | `VoalleServiceDeactivationAdapterImpl` |

Os seis primeiros sao a geracao antiga (so Path); os oito ultimos sao da onda REQ-4 a REQ-8 (com metodo, timeout 20 s,
3 tentativas). Quatro estao marcados `Environment__c = qas` dentro da producao.

### 3.2 Apex com callout (41 classes, 20 de producao, o resto mocks e testes)

| Classe | Destino | Gatilho | Flag / observacao |
|---|---|---|---|
| AccountGetSapIdQueueable | Mule `get-base-account/{cnpj}` -> grava `ExternalId__c` (BP SAP) | AccountGetSapIdController, TmfCustomerAccountResolver | ativo |
| GetStockLocationCallout | Mule `person-material-handling/{bp}` -> Location e ProductItem do tecnico | flow ServiceAppointmentChecktheTechnicianStock, ServiceAppointmentStockSyncController | ativo |
| WorkOrderMaterialsCalloutQueueable | Mule GET materiais por Work Order (after insert), timeout 120 s | WorkOrderHelper, ServiceAppointmentMaterialsController | ativo |
| WorkOrderTechnicalOperationalQueueable + WorkOrderMaterialSplitQueueable + WorkOrderClientMaterialQueueable | Zendesk/Mule `create-technical-operational-movement`, `create-material-movement` (Work Order concluida, 1 callout por unidade) | WorkOrderHelper, WorkOrderRetryIntegrationInvocable (flow Reintegrar_Work_Order), TechnicianBagReturnService | ativo |
| TechnicianBagReturnService | devolucao de material (SAP via Mule) | TechnicianBagController | ativo |
| StatusIntegrationCalloutQueueable | `tickets/send-to-voalle`, `tickets/send-to-zendesk` | StatusIntegrationService, NeutralNetworkCalloutQueueable | ativo |
| CustomerServiceCommentCallout | `tickets/send-to-zendesk` (comentarios) | CustomerServiceCommentHandler, WorkOrderCommentController | "manter false ate validacao do contrato" |
| BTecParManualWorkOrderScreenCallout | Zendesk `solicitation/{id}` | tela de ordem de servico manual | ativo |
| DeliveryBillingEventQueueable | TMF `serviceOrderStateChangeEvent` (inicio de faturamento) | DeliveryBillingEventService | ativo |
| BTecparAssetCallout / BTecparOMCustomSystemInterface | Mule `customer/.../assets` e `protocol-closure` (Vlocity OM System Interfaces "Customer Assets" e "Inicio do Faturamento", ambas Online) | Order Management | ativo |
| CnpjWsService | cnpj.ws `GET /cnpj/{cnpj}` | CnpjWsQueueable, CnpjWsMapper | ativo |
| CustomerCoreSyncAdapterImpl | Mule customer / internal-alteration | fabrica CustomerCoreAdapterFactory | `CustomerCoreSyncEnabled__c` = false; payload provisorio |
| OzmapAdapterImpl, NetworkDeactivationAdapterImpl | Mule Ozmap | fabricas | `OzmapSyncEnabled__c` = false |
| CcdChargeAdapterImpl | Mule CCD | fabrica | `CcdSyncEnabled__c` = false |
| SapAssetMovementAdapterImpl, SapTechnicalOperationalAdapterImpl | Mule SAP patrimonio (REQ-6) | fabricas, `AssetRecoveryHttpClient` | `SapSyncEnabled__c` = false |
| VoalleServiceCompositionAdapterImpl, VoalleServiceDeactivationAdapterImpl | Mule Voalle (REQ-7) | VoalleAdapterFactory | `ExternalDeactivationEnabled__c` = false; "rota de composicao nao existe no Exchange (14/09), workaround GET customer/assets" |
| NeutralNetworkHttpClient, NeutralNetworkTmfPassthroughAdapter, NeutralNetworkVtalAdapter | Mule fachada TMF da V.tal (REQ-8) | NeutralNetworkAdapterFactory | parceiro em rascunho |
| NotificationController | notificacoes internas (custom notification), nao callout externo | ContractAutoInactive, OpportunityHelper | |

Feature flags (custom metadata, registro Default): `ExternalAlterationSetting`, `InternalAlterationSetting`,
`DigitalDeactivationSetting`, `AssetRecoverySetting`: **todas as flags de integracao em false** (CustomerCoreSync, OzmapSync,
CcdSync, SapSync, ExternalDeactivation, ExternalAutomation, InventoryConsumption, StockConsumption, AutomationEnabled).
Ou seja, as integracoes REQ-4 a REQ-8 estao implantadas em codigo, mas dormentes.

### 3.3 OmniStudio (padrao, objeto OmniProcess): 8 Rest Actions em Integration Procedures ativas

| IP | Rest Action | Endpoint |
|---|---|---|
| BTecPar_BaseClientIntegration | HTTPCustomer | IntegrationConfig customerMulesoft |
| BTecPar_CreateClient | HTTPCreateClient | IntegrationConfig createClientMulesoft |
| BTecPar_CreateContract | HTTPCreateContract | IntegrationConfig createContractMulesoft |
| BTecPar_CreditAnalysisIntegration | HTTPGetCreditAnalysisIntegration | IntegrationConfig creditAnalysisMulesoft |
| BTecPar_TechnicalViabilityCheck | HTTPSendTechnicalViabilityCheck | IntegrationConfig technicalViabilityMulesoft |
| BTecPar_GetAddressByPostalCode | GetAddressData | CalloutSetup (Mule) |
| BTecPar_GetBankInformation | GetBankData | CalloutSetup (Mule) |
| OmniScript BTecParPF/AddressAndClientData | HTTP_APICEP | https://brasilapi.com.br/api/cep/v1/{cep} |

Consumidores: jornada de venda B2C (`BTecParPF/SalesJourney` e filhos: AddressAndClientData, Cart, PaymentMethod, Summary,
Accept) e `SalesJourney/CheckFeasibility` (viabilidade tecnica + analise de credito + conversao de lead). 224 Remote
Actions e 112 IPs aninhadas, quase todas do pacote CPQ.

### 3.4 Flows com servico externo ou Apex invocavel de integracao

Address_Get_Infos e LeadGetAddress (External Service GetAddress), Get_CNPJ_Details (External Service GetCnpjDetails),
ServiceAppointmentChecktheTechnicianStock (GetStockLocationCallout), Reintegrar_Work_Order (WorkOrderRetryIntegrationInvocable),
ServiceAppointmentCollectCustomerAsset (BTecparProductItemAssetSyncInvocable), WorkOrder_InheritSkillsData e
Work_Order_Update_External_Zendesk_Id_For_Cancelled_Work_Order (Zendesk Id).

### 3.5 Eventos de plataforma

Custom: `InstalationFeeAprovalStatus__e` (publicado por BTecparInstalationAprovalController). Pacotes: 4 FSL, 3 Marketing
Cloud (JB_Event, JB_CDC_Event, JB_Flow_Event), 9 Vlocity (orquestracao e async). Trigger em objeto custom
`NeutralNetworkIntegrationEvent__c` (fila de eventos da rede neutra). Sem Change Data Capture configurado.

## 4. Entradas (fora chama o Salesforce)

| Entrada | Caminho | Quem usa (30 dias) |
|---|---|---|
| Apex REST `/tmf-api/serviceOrdering/v4/serviceOrder/*` (TmfServiceOrderRestResource) | TMF641 da Entrega: Customer Core -> Mule -> Salesforce | app `Integracao_TMF641_MuleSoft` (14 logins) |
| Apex REST `/delivery/v1/work-orders/*` (DeliveryWorkOrderRestResource) | cria Work Order + Conta + Service Appointment (REQ-1 a 6) | via usuario de integracao |
| Apex REST `/neutralnetwork/v1/events/*` (NeutralNetworkInboundRestResource) | tracking TMF697/622 do parceiro de rede neutra | rascunho |
| Apex REST `/v1/fsl/next-slots` (BTecparFSLNextSlotsRestResource) | proximos horarios de agenda FSL | tela manual e invocavel |
| Connected app `IntegracoesBrasilTecpar` | API padrao (SOAP/REST/Bulk) | `Usuario de Integracao` (integration.user@brasiltecpar.com.br, perfil Salesforce API Only System Integrations), 721 logins |
| Connected app `CPQ Integration User Connected App` | Vlocity | `svc_sales_integracao` (API Only) sem login em 30 dias |
| Connected app `BTP Governanca Hub` | ? | Gerson, 8.324 logins |
| Marketing Cloud Connect | API | Alan Cesar Honorio, 26.307 logins |
| Data Analytics PCP / INT6 | BI | Guilherme Elsas, 246 logins |
| SAML Okta | usuarios | 10.485 logins de sucesso; 225 falhas "InResponseTo Invalid", 36 usuarios congelados |
| Site publico Rastreio de Atendimento | convidado | usuario `Rastreio de Atendimento Usuario convidado do site` |
| Usuarios de sistema | Automated Process, Platform Integration User, Sistema (case), Data.com Clean, Insights Integration, `Integracao Ordem Manual` (perfil Admin_User_Test) | |

## 5. Jobs agendados ligados a integracao

WO SA Recovery (a cada 15 min, recuperacao de Work Order/Service Appointment), TerritoryRoutingHourlyCorrection (hora em
hora), ContractExpireContractsDaily (7h), OmnistudioCronJob e Log CPQ Config Data (0h/1h), SLR Purge e
WorkCapacityAvailability (FSL), sitemaps do site publico. Nenhum batch de reenvio de integracao alem do WO SA Recovery.

## 6. Achados

1. **Chave de API do cnpj.ws gravada como parametro da Named Credential** e, portanto, exportavel por qualquer retrieve de
   metadado (esta em `org/tmp`, fora do git). Mover para External Credential com principal e parametro de cabecalho
   protegido, ou para Custom Setting protegida.
2. **Marketing Cloud Connect autenticando com usuario pessoal** (Alan Cesar Honorio, perfil Field Service Admin): 26 mil
   logins/mes. Se ele sair ou trocar senha, para a integracao. O padrao e um usuario de API dedicado.
3. **BTP Governanca Hub**: connected app criado pelo Gerson em 24/08 com 8,3 mil logins/mes. Nao esta documentado no diario.
   Confirmar o que e (ferramenta interna? o "Hub" do controle de mudancas?) e com que escopos OAuth.
4. **Quatro registros de IntegrationConfig com `Environment__c = qas` em producao** (SAP patrimonio e Voalle REQ-6/7). Como
   as flags estao desligadas nao ha efeito hoje, mas ligar a flag sem corrigir o ambiente manda producao para rota de QAS.
5. **Integracoes REQ-4 a REQ-8 dormentes**: codigo em producao, payloads marcados como provisorios, contratos nao
   homologados (Customer Core, Ozmap, CCD, Voalle, V.tal). Manter as flags em false ate homologacao; hoje e so superficie
   de risco sem funcao.
6. **Salesforce CLI com usuario inativo**: 2.197 tentativas em 30 dias ("User is Inactive"). Algum script ou VS Code de
   ex-colaborador ainda tenta logar. Identificar o usuario no LoginHistory e revogar o token.
7. **Falhas SAML**: 225 "InResponseTo Invalid" (tipico de relogio ou sessao expirada no Okta) e 36 logins de usuarios
   congelados. Sem impacto de integracao, mas vale reportar a seguranca.
8. Named Credential legada por Remote Site (`PrdMule`, `mule`, `BrasilAPI`) convive com as Named Credentials novas: duas formas
   de sair para o mesmo Mule. O `mule` aponta para o Mule de DEV e esta ativo em producao.
9. `Integracao_TMF641_MuleSoft` aparece no LoginHistory mas nao existe como ConnectedApplication na org: e um app externo
   (registrado na org do Mule?). Confirmar dono e usuario.
10. Sem Change Data Capture nem Outbound Message: toda saida e sincrona (callout) ou por queueable. Nao ha fila de reenvio
    generica; cada integracao trata retry por conta propria (MaxRetries__c 3).

## 7. Para confirmar com o Diego

- O que e o BTP Governanca Hub e quem responde por ele.
- Trocar o usuario do Marketing Cloud Connect por um usuario de API dedicado (precisa de licenca e reautorizacao no MC).
- Quem cuida da chave do cnpj.ws e se pode ser rotacionada ao mover para lugar seguro.
- Se Data Cloud esta contratado/em uso (pacotes e auth providers presentes, nenhum uso em codigo).
- Dono do usuario `Integracao Ordem Manual` (perfil Admin_User_Test, username com sufixo integracao2).
