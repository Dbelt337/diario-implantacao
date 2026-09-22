# 22/09/2026 - Revisao tecnica das 93 historias do programa: native-first e documentacao oficial

Pedido do Diego: avaliar se as historias (US) estao tecnicamente bem escritas para a SysMap construir os fluxos no Salesforce,
validar contra a documentacao oficial de Sales Cloud, Communications Cloud, EPC e Industries CPQ, e melhorar o texto que ja
existe DENTRO do Agile, com conceito native-first e melhores praticas.

## O que foi feito

1. Exportacao das 93 works do programa (todos os epicos menos "Projetos Internos"), 339 mil caracteres de descricao.
2. Revisao historia a historia em quatro grupos, cada uma com: qualidade da escrita, capacidade nativa que atende,
   desvios de native-first, nota (Verde/Amarelo/Vermelho) e ajuste. Cada afirmacao de "e nativo" foi checada na
   documentacao oficial (help.salesforce.com, developer.salesforce.com, trailhead) e a URL ficou na historia. Os quatro
   relatorios de revisao estao em `docs/revisao-historias-2026-09-22/`.
3. Reescrita do campo Detalhes das 93 works, preservando todas as decisoes, regras, campos e fontes, na estrutura:
   NARRATIVA, CONTEXTO E CENARIO DE NEGOCIO, REGRAS DE NEGOCIO (RN-nn), CRITERIOS DE ACEITE (CA-nn, Dado/Quando/Entao),
   SOLUCAO NATIVA, DEPENDENCIAS E LICENCAS, FORA DE ESCOPO, REFERENCIAS, HISTORICO DE DECISOES. As notas datadas que se
   acumulavam no corpo foram consolidadas: o corpo reflete a decisao vigente e o historico guarda as anteriores.
4. Gravacao em producao pela Bulk API (job 750V200000mbRjxIAE, 93 processadas, 0 falhas, 15h00). Assunto, status,
   sprint, epico, pontos e comentarios nao foram tocados. Backup integral do texto anterior em
   `org/tmp/agile_backup/` (fora do git) com CSV de rollback pronto (`rollback_details_2026-09-22.csv`).

## Resultado da avaliacao (antes da reescrita)

| Nota | Quantidade | O que significa |
|---|---|---|
| Verde | 29 | pronta e native-first; recebeu so criterios de aceite e referencias onde faltavam |
| Amarelo | 56 | escrita ou desenho a ajustar; reescrita consolidou e apontou o nativo |
| Vermelho | 8 | historia guarda-chuva ou com desenho superado no corpo; reescrita separou escopo e alinhou ao nativo |

Vermelhas: W-000065 (B2C-09 resumo e aceite, 3 modalidades misturadas), W-000075 (B2C-18 venda touchless com Apex REST
proprio), W-000076 e W-000077 (B2C-19/20 ciclo da taxa de ativacao espalhado), W-000070 (EPC-10 catalogos, conflito de
estrutura e dump de decisoes), W-000098 (B2B-03 cotacao + alcadas + DocGen), W-000099 (B2B-04 cancelamento + esteiras +
multa) e W-000101 (B2B-06 auditoria BKO).

Antes da reescrita: 23 historias sem criterio de aceite, 6 com persona explicita, 19 citando Apex e 25 citando objeto
custom. Depois: 93 com narrativa, criterios Dado/Quando/Entao, solucao nativa nomeada e referencias oficiais.

## Decisoes que as historias nao podem tomar sozinhas (ficaram marcadas como "Decisao pendente" no texto)

1. **Estrutura do catalogo**: por mercado (W-000056) ou por familia (W-000070, W-000111). Os dois modelos sao nativos
   (Catalog + Category + Context Rules); precisa de um registro de decisao unico antes da carga.
2. **Gatilho de "Ganho" na oportunidade B2C**: tres definicoes (OS concluida em B2C-20, callback do OM em B2C-23, nasce
   ganha em B2C-18). Uma so.
3. **Ciclo da taxa de ativacao**: maquina de estados unica entre B2C-11, 12, 19 e 20, com o contrato da baixa bancaria.
4. **Modelo de compartilhamento (OWD)** da Opportunity: decidido de forma contraditoria em B2C-15, 16 e 17.
5. **Fronteira Zendesk x Salesforce** (visao 360, contrato, retencao): bloqueia W-000095, 105 e 129.
6. **Motor de aprovacao unico**: Flow Approval Orchestration (ja em uso na org) x Approval Process classico x Approve
   Discounts do carrinho CPQ. O corpo de varias B2B ainda citava Advanced Approvals (SteelBrick), que nao esta no stack.
7. **Licencas nao confirmadas como pre-condicao**: Omni-Channel para vendedores, Marketing Cloud + WhatsApp, motor de
   assinatura, Order Management, ESM, BRE, MuleSoft Direct.

## Desvios native-first corrigidos no texto

- Apex REST proprio para venda touchless e para site -> Digital Commerce APIs / TMF622 inbound e Web-to-Lead.
- Scheduled/Batch Apex -> schedule-triggered flow; LWC de revisao e "antes x depois" -> FlexCard/OmniScript e carrinho ABO.
- Geracao de documento via MuleSoft -> Server-Side Document Generation (assincrono, com teto de geracoes/hora a conferir).
- Campos e objetos custom duplicando o padrao (StageEnteredAt__c x OpportunityHistory, UserRegionalMapping__c x User,
  Endereco__c x Premises, status proprio de Order e de Contract, versao propria de template) -> padrao da plataforma.
- Mecanismos de preco ambiguos -> matriz de calculo por atributo, PriceListEntry por lista e Context Rules onde cabem.

## Tabela resumo por historia

Work | Assunto | Nota | Capacidade nativa principal | Ajuste

| W-000057 | B2C-01 Captura, triagem e roteamento de Lead | Amarelo | Dynamic Forms + VRs; Duplicate/Matching Rules; Lead Assignment Rules + filas; Omni-Channel skills-based (suporta Lead) | Quebrar em 3 (captura/validação, dedupe, roteamento), escrever critérios de aceite e confirmar licença Omni-Channel para vendedores |
| W-000058 | B2C-02 Viabilidade + trilha móvel | Amarelo | Premises/ServicePoint do pacote; IP non-blocking; RT MobilePhoneOpportunity; TMF645 como contrato-alvo | Consolidar as 3 emendas em um texto único (TMF645 síncrono via Mule, reserva de porta fora do escopo SF) e adicionar aceite |
| W-000059 | B2C-03 Crédito e Mesa | Amarelo | Decision Matrix/Expression Set (BRE); Flow Approval Processes + fila; FLS | Fechar o corte de score, separar persona Analista (Mesa) da persona Vendedor e definir aceite por faixa |
| W-000060 | B2C-04 Flag de débito no endereço | Amarelo | Premises/ServicePoint como chave do endereço; FlexCard; Reports padrão | Reescrever a seção REUSO conforme decisão 01/09 (Premises, não Endereco__c) e definir contrato da API e FLS |
| W-000061 | B2C-05 Dashboard e árvore de perdas | Amarelo | Reports/Dashboards; Opportunity History (Stage Duration nativo); Global Value Set + picklist dependente | Trocar StageEnteredAt__c + flow pelo OpportunityHistory nativo; separar saneamento (pré-requisito) da entrega dos dashboards |
| W-000062 | B2C-06 Tipo de negociação e segmento por ticket | Amarelo | Picklist existente NegotiationType__c; total do carrinho Industries CPQ (pricing plan / campos de total) | Definir onde o Segment vive e o gatilho (após reprice/salvar carrinho, flow sobre total), sem step custom no pricing plan |
| W-000063 | B2C-07 FSL: 3 tentativas / 72h | Verde | Field Service (WorkOrder owner = fila, ServiceAppointment); Scheduled-Triggered Flow; fila | Definir o que conta como "tentativa" (Task/ação) e o par de aceites (3ª tentativa → fila; 72h → cancelamento em cascata) |
| W-000064 | B2C-08 Perfil e unidade operacional | Amarelo | Campos custom no User (SCIM/Okta); choices filtradas na jornada; Permission Sets | Mover Regional/Empresa/Canal para o User (provisionados pelo SSO) e manter só o de-para Regional×Unidade em objeto/CMDT |
| W-000065 | B2C-09 Resumo da venda e modalidade de aceite | Vermelho | OmniScript existente; DocGen; File Upload nativo; ContentVersion; evento do canal TEC-INT-01 | Reescrever consolidando as decisões (08/09 e 10/09), separar "Resumo" de "Aceite/Assinatura" e retirar biometria até haver contrato |
| W-000066 | B2C-10 Régua de lembretes e expiração 5 dias | Amarelo | Journey Builder API Event (entrada por evento); Scheduled Flow para Closed Lost | Confirmar licença MC + WhatsApp antes do refinamento; aceite com gatilho SignatureSent e exit criteria |
| W-000067 | B2C-11 Débito interno: ticket Zendesk + 5 dias | Amarelo | Flow + Named Credential; Platform Event inbound; Scheduled Flow | Decidir o SLA (5 dias vs compensação 48h) e o status/estágio que "pausa" a Oportunidade; adicionar idempotência e aceite |
| W-000068 | B2C-12 Taxa de ativação e alçadas | Amarelo | Flows de aprovação existentes (ou Flow Approval Processes); VR/Flow como gate do ServiceAppointment | Tirar o chatbot desta US (fica na B2C-20), corrigir valor (149,90 vs 149,99) e escrever aceite do gate |
| W-000069 | B2C-13 Seleção guiada, combos, filtro por IBGE | Amarelo | EPC: context rules / Availability & Eligibility, Promotions, Price Lists e PLE por zona; Cart-based APIs | Fechar o mecanismo (interfaces vs context rules) pela versão do pacote e escrever aceite por rule set e por família |
| W-000071 | B2C-14 Ingestão de leads (carga, QR, forms) | Amarelo | Permissão Import Leads via Permission Set; Web-to-Lead; MC Connect; BarcodeScanner API (LWC mobile) | Dividir em 3; site via Web-to-Lead (não REST custom); Zendesk via Mule; QR com lightning-barcode-scanner e Duplicate Rules na entrada |
| W-000072 | B2C-15 Busca federada Salesforce + Customer Core | Amarelo | FlexCard + IP + DataRaptor; cadeia BTecPar_BaseClientIntegration | Não chamar de "refatoração da busca global"; SOSL exige Remote Action (Apex) — aceitar ou usar DataRaptor por chave; resolver OWD (Read aqui vs Private na B2C-17) |
| W-000073 | B2C-16 Categorização do Lead | Amarelo | Lead Convert nativo com conta existente + Lead Field Mapping; VR de motivo; Global Value Set | Remover "OWD Public Read/Write" (desnecessário e conflita com B2C-17); descrever fallback de timeout como aceite |
| W-000074 | B2C-17 Viabilidade + crédito one-click | Amarelo | IP non-blocking (paralelismo); FlexCard; ServicePoint | Alinhar regra 3 com B2C-04 (sem alçada), tirar "Complemento" da chave e escrever o aceite de timeout ("Em análise") |
| W-000075 | B2C-18 Touchless Order API | Vermelho | Digital Commerce APIs (basket → cart → order) ou TMF622 inbound; Mule como BFF | Redesenhar: sem Apex REST; Mule chama Digital Commerce/TMF622; ordem NÃO nasce "Ganha" (conflita com B2C-20/23); idempotência por chave externa |
| W-000076 | B2C-19 Emissão, notificação, comprovante e Mesa | Vermelho | Flow Approval Processes; File Upload OmniScript; Journey Builder; OM callout para billing | Reescrever: mistura 5 etapas e sobrepõe B2C-12 e B2C-20; definir dono da cobrança (BSS via Mule) e máquina de estados única da taxa |
| W-000077 | B2C-20 Pagamento, bot e Closed Won | Vermelho | Scheduled Flow; Platform Event de baixa; AppointmentBookingService (FSL); OM callback | Reescrever: regra 4 (Ganho no fechamento da OS) contradiz B2C-23 (Ganho após ativação); 5 vs 6 dias; separar bot em US própria |
| W-000078 | B2C-21 List View "Acompanhamento Baixa Bancária" | Verde | List View + Public Groups | Nomear o campo/valor exato do status e criar uma lista por regional (list view não filtra "minha regional" dinamicamente) |
| W-000079 | B2C-22 Relatório instalações não realizadas + notificação | Amarelo | Reports/Dashboards; Send Custom Notification (Flow); Status Category "Cannot Complete" | Retirar a frase "encerrar a oportunidade após integração" (é da B2C-23); definir critério de "agendamento estourado" e origem do Coordenador (User.ManagerId) |
| W-000080 | B2C-23 Ativação final e Ganho | Amarelo | Orchestration Plan do OM (callout + callback), Lock Record / VR | Reescrever o corpo conforme emenda 04/09 (callback do plano, não trigger/callout avulso) e aceite de fallout |
| W-000081 | B2C-24 Dados de faturamento e parametrização | Amarelo | Step de OmniScript existente; campos padrão de Order/Contract (BillingAddress, ContractTerm, StartDate) | Reescrever com prazo read-only herdado do carrinho (03/09) e mapear cada campo a objeto/campo de destino (Order/Contract/Billing Account) |
| W-000082 | B2C-25 Minuta dinâmica do contrato | Amarelo | DocGen server-side (assíncrono, grava ContentVersion); Platform Event Publish After Commit | Consolidar as 3 emendas em texto final (sequência 08/09) e aceite dos estados "em geração / pronta / falha" |
| W-000083 | B2C-26 Guarda de dados e LGPD | Verde | Consent Data Model (Individual, ContactPointTypeConsent, DataUsePurpose); Contact Point Filtering | Trazer os critérios de aceite para o texto e definir retenção/anonimização (prazo) para perdidos sem consentimento |
| W-000084 | Botao Criar Cotacao (Create Cart) | Verde | Cart-Based APIs createCart + Guided Selling OmniScript | Definir o que e "nova versao" da cotacao (clone nativo) e listar os erros esperados como criterios de aceite |
| W-000085 | Modelagem EPC das ofertas B2C | Amarelo | EPC: Product2/atributos, Price List Entries + Context Rules, Promotions, attribute-based pricing | Quebrar em 3 historias (ofertas, promotions, zona x prazo), fechar o valor da taxa e escrever criterios por camada de preco |
| W-000086 | Esqueleto OmniScript Nova Venda B2C | Amarelo | OmniScript pai/filhos reutilizaveis + Integration Procedures + Cart APIs | Corrigir o item pub/sub (OmniScript nao assina Platform Event; usar LWC empApi ou polling) e usar Save for Later para retomada |
| W-000087 | Fundacao de integracoes | Amarelo | Named Credentials + External Credentials (OAuth 2.0 JWT/client credentials), Integration Procedures | Separar a decisao Zendesk/licencas em work propria e transformar o "mapa de APIs" em criterios verificaveis por endpoint |
| W-000088 | OM: decomposicao e plano de orquestracao | Verde | Industries OM: decomposition, orchestration plan, Callout/Auto tasks, fallout | Consolidar as 6 notas em um texto unico e detalhar os criterios do plano condicional de cortesia |
| W-000089 | Infra de Document Generation | Amarelo | OmniStudio Server-Side Document Generation (assincrono nativo) | Tirar o MuleSoft do caminho da GERACAO (nativo ja e assincrono); Mule so para a assinatura; conferir o limite de 1.000 geracoes/hora |
| W-000090 | Seguranca e acessos B2C | Verde | Permission Sets/Groups, FLS, Queues, OWD, Role Hierarchy | Usar Permission Set Groups por papel e tirar o incidente da credencial versionada para um item de seguranca proprio |
| W-000091 | Roteamento Omni-Channel | Amarelo | Omni-Channel (Lead e objeto suportado), Omni-Channel Flows, Skills-Based Routing Rules/Skill Mapping Set | Escrever criterios de aceite (nao tem nenhum) e definir a regra de/para regiao x fila |
| W-000092 | Fundacao Marketing Cloud | Amarelo | Marketing Cloud Connect + Synchronized Data Sources + Journey Builder + WhatsApp (Meta) | Escrever criterios de aceite e detalhar como o consentimento (ContactPointTypeConsent) chega ao MC (sincronizacao + filtro) |
| W-000093 | Orquestracao de ativacao no Customer Core | Amarelo | Industries OM (CP2TP, Callout Task, fallout) + TMF641 outbound e TMF637 inbound nativos | Limpar o texto de referencia (eSIM/ICCID/Black Friday) para o portfolio real (fibra/SVA) e remover Apex Continuation do desenho |
| W-000094 | Work Order de instalacao (OM + Field Service) | Amarelo | Field Service (WorkOrder/ServiceAppointment) acionado por Auto/Callout Task do OM | Retirar as alternativas TOA/ClickSoftware/TMF652, nomear a US de agendamento no checkout e a criacao de Location/Address |
| W-000095 | Visao 360 no console | Amarelo | FlexCards + Integration Procedures + Service Console (Interaction Console) | Definir ou retirar a Regra 3 (NBA) e a mascara com auditoria; resolver a fronteira Zendesk antes de construir |
| W-000105 | Canal de eventos de contrato SF -> Mule | Verde | Platform Events (Publish After Commit) + MuleSoft Pub/Sub Connector | Manter; apenas rever se a geracao da minuta precisa mesmo passar pelo Mule (ver W-000089) |
| W-000106 | Templates juridicos unificados | Amarelo | Document Generation templates com versao/ativacao nativas; CLM templates e clausulas | Usar o versionamento nativo do template em vez de "objeto proprio" e trazer os 4 criterios para o texto |
| W-000109 | Multa pro rata de fidelidade | Amarelo | Penalty Rules for Contracts (Industries CPQ), pricing variable, Calculation Procedure | Reescrever a especificacao tecnica no padrao da nota de 10/09 (penalidade nativa), tirando Apex/Flow do texto |
| W-000110 | Integracao com fornecedores de SVA | Verde | Atributos tecnicos no EPC, Custom Metadata, Orchestration Items de callout, fallout | Manter; incluir o limite de licencas como regra de atributo/validacao no carrinho e criterios por fornecedor |
| W-000115 | Tipos de operacao sem faturamento | Amarelo | Adjustments 100% com Time Plan/Policy, account-based discount, Context Rules, Flow Approval Processes | Unificar o mecanismo (Record Type na Opp x atributo Tipo de Negociacao no carrinho) e trocar Approval Process por Flow Approval |
| W-000116 | Mudanca de plano B2C (MACD) | Verde | Asset-Based Ordering / MACD do Industries CPQ + OM | Manter; ligar RN-05 (refidelizacao) ao aditivo da W-000126 e explicitar a ramificacao do plano de orquestracao |
| W-000117 | Modelo de contas (Consumer/Business/Billing/Service) | Amarelo | Record types do pacote Communications (Business, Consumer, Billing, Service), Premises/ServicePoint | Reescrever como versao final unica (tres camadas de correcao hoje) e fechar a decisao de Person Accounts |
| W-000118 | Checkout e submissao ao OM | Amarelo | Cart API Checkout + Submit Order do CPQ/OM, statuses nativos do Order | Mapear os 8 estados propostos para os status nativos do Order/OM em vez de criar maquina propria |
| W-000126 | Aditivo contratual por MACD (CLM) | Verde | Industries CLM: amend, ContractVersion, estados por Contract Type, contract-based discounts/frame agreement | Manter; mapear RN-06 para os estados configuraveis do CLM e validar volume B2C de aditivos |
| W-000129 | Cancelamento B2C com retencao | Amarelo | ABO disconnect/cancel, promotions com Context Rules, Flow Approval Processes, Case | Fechar onde roda a retencao (Zendesk x Salesforce) antes de refinar; trocar Approval Process por Flow Approval |
| W-000130 | Sincronizacao SAP -> SF do equipamento | Amarelo | Asset hierarchy (Parent Asset), upsert por External Id via REST/Bulk API 2.0 | Rever a conciliacao diaria com TMF638 (contradiz "nunca em massa" da W-000093) e definir Bulk API para a carga de 1 milhao |
| W-000131 | API inbound TMF641 no Field Service | Amarelo | REST API padrao (WorkOrder/ServiceAppointment) chamada pelo Mule + Platform Event de status | Confirmar escopo de Onda; registrar que TMF641 inbound nao e nativo (inbound nativo: TMF622/629/637/648/651) |
| W-000132 | Esteira CI/CD | Verde | sf CLI (source format), OmniStudio/Vlocity Build Tool, sandboxes por papel | Manter; registrar que DevOps Center nao instala em sandbox e incluir secret scanning no pipeline |
| W-000051 | EPC-01 Attribute Categories | Verde | Attribute Category (Product Console/Designer), Display Sequence, Applicable Types | Corrigir a frase "tipo definido na categoria" (data type e do atributo) e mover o bloco de consolidacao 15/09 para a work filha |
| W-000052 | EPC-04 Object Types, heranca, layouts | Amarelo | Object Type hierarchy, heranca dinamica de campos/atributos, copia de layout | Deixar UMA hierarquia normativa (arvore v3 em 2 niveis) e fechar o conflito Codigo SAP campo x atributo com a W-000041 |
| W-000053 | EPC-05 Product Specifications | Amarelo | Product/Offer/Service/Resource Specification (ProductSpecId no Product2) | Realinhar a lista de specs ao modelo v3 (3 familias, filhos da CAT-CHD-01) e criar AC de "produto referencia exatamente uma spec" |
| W-000054 | EPC-09 Compilacao e integridade | Verde | EPCProductAttribJSONBatchJob, EPCFixCompiledAttributeOverrideBatchJob, EPC Jobs (Generate Compile Data), Product Hierarchy Maintenance | Incluir Generate Compile Data por price list e o handoff para o cache do Digital Commerce (CAT-API-01) |
| W-000055 | EPC-03 Dicionario de atributos | Amarelo | Attribute + Data Type + Picklist, Attribute Assignment por Object Type, overrides | Declarar que os metadados de governanca ficam no dicionario (nao em campos custom) e mover o AC3 (Mapping Rule) para a US de decomposicao |
| W-000056 | QUAL-01 Qualificacao Tetra-pe | Amarelo | Context Rules (dimensoes, mapping, rule sets) em produtos, promocoes e PLEs; Digital Commerce context eligibility | Resolver o conflito de estrutura de catalogo com a W-000070 por ADR e usar ZONA (nao cidade IBGE) como dimensao de contexto |
| W-000070 | EPC-10 Catalogos comerciais | Vermelho | Catalog + Category + publicacao N:N, filtragem por Context Rules | Reescrever: um unico modelo de catalogo (ADR), lista de familias atual, nomes genericos, tirar o dump de decisoes P-01..P-18 |
| W-000102 | CAT-TPL-01 Planilha mestre | Amarelo | Carga via Bulk API/Data Loader (upsert por External Id), DataPacks, EPC REST APIs | Adicionar o de-para aba -> objeto EPC e definir o mecanismo de carga; AC verificaveis (nao "erro proximo de zero") |
| W-000103 | CAT-MIG-01 Migracao de ativos | Amarelo | Asset com campos vlocity_cmt (AssetReferenceId, RootItemId, ParentItemId, JSONAttribute), Bulk API upsert, ABO | Separar contas/contratos de ativos e especificar os campos Vlocity obrigatorios para o ativo abrir em Change to Order |
| W-000104 | CAT-TAG-01 Service Tag | Amarelo | Campo Unique + External ID (unicidade no banco), Auto Task no plano de orquestracao, UUID/Crypto Apex | Avaliar Auto Number nativo antes do Apex; gerar na Auto Task (nao trigger) e definir o mapeamento OrderItem -> Asset |
| W-000108 | CAT-PRC-01 Regra de desconto em combos | Amarelo | Promotions (ajuste fixo por item), Time Plans, Context Rules em PLE por zona, Discounts, pricing plan | Trazer os exemplos numericos para os AC e definir o mecanismo do floor (nao existe "floor" nativo) |
| W-000111 | CAT-FAM-01 Familias Movel, Streaming, Camera | Amarelo | Object Types, atributos, specs, bundle (camera), Promotions, categorias | Tirar a referencia a "catalogos por mercado", tirar estoque/NF do escopo e escrever AC por familia |
| W-000112 | CAT-CHD-01 Componentes como produtos filhos | Verde | ProductChildItem com cardinalidade min 0, atributos no filho, PLE por filho, Compatibility Rules, decomposicao | Verificar se "meio de acesso diferente do primario" cabe em Product Relationship ou exige Advanced Rule com filtro de atributo |
| W-000113 | CAT-API-01 Cache Digital Commerce | Verde | Jobs DC (Product Hierarchy Maintenance, Clear/Refresh Cache, ContextEligibilityGenerator, Populate API Cache), execucao remota | Fixar qual Digital Commerce (managed package cacheable APIs x Standard DC) pois o conjunto de jobs muda |
| W-000114 | CAT-ZON-01 Zonas IBGE -> zona | Amarelo | Context dimension + context mapping em sObject, qualificacao de PLE por zona, upsert por External Id | Definir onde a zona resolvida fica persistida (Account/Premises/Order) para o context mapping ler; chave composta se houver vigencia |
| W-000121 | CAT-CPX-01 Taxa Unica (CAPEX) | Amarelo | Pricing Variables one-time x recurring, Attribute-Based Pricing com matriz, Context Rule de visibilidade | Escolher UM mecanismo: matriz com Modalidade como coluna de entrada (MRC/NRC), em vez de "PLE por modalidade" nao comprovada |
| W-000127 | CAT-EQP-01 CPE e matriz de compatibilidade | Amarelo | Product2 por modelo, Resource Spec via decomposicao, Decision Matrix (BRE), carrinho ABO | Dividir em 3 (modelo comercial, CPE tecnico/decomposicao, matriz de upgrade) e dizer por onde a Decision Matrix e chamada no carrinho |
| W-000128 | CAT-RET-01 Promotions de retencao | Amarelo | Promotion + Time Plan/Policy, Context Rules em promocao, Account-based Discount com aprovacao | Um motor por decisao (Context Rules para elegibilidade, aprovacao para N3) e explicitar que a volta ao preco de tabela e do billing (SAP) |
| W-000096 | B2B-01 Inatividade de Lead, Econodata, grupo economico | Amarelo | Schedule-Triggered Flow sobre LastActivityDate; Duplicate/Matching Rules; Lead field mapping; Account Hierarchy | Dividir em 3 US (inatividade, enriquecimento, duplicidade/grupo); trocar Batch Apex por flow agendado; duplicidade por Duplicate Rule no CNPJ |
| W-000097 | B2B-02 Geocodificacao, viabilidade, pre-projeto | Amarelo | Premises/ServicePoint; TMF645 outbound via MuleSoft; IP HTTP Action assincrona; Flow para fila | Corrigir estagio (Opportunity, nao Quote); definir "Pin Drop" sem LWC proprio ou justificar; lote de sites por IP assincrona/Queueable com throttle |
| W-000098 | B2B-03 Cotacao multi-site, alcadas, DocGen | Vermelho | Multi-Site Quote and Order Capture; Approve Discounts (CPQ); Flow Approval Processes com record lock; Quote.ExpirationDate; DocGen server-side | Reescrever consolidando corpo + 4 notas; remover Advanced Approvals; DocGen nativo server-side (sem passar pelo Mule); separar alerta de Compras em US propria |
| W-000101 | B2B-06 Auditoria BKO, credito, handoff | Vermelho | Industries OM (decomposicao, orquestracao, callbacks); OmniScript/FlexCard de revisao; Flow Approval; assetizacao pelo OM | Reescrever: corpo contradiz notas (perfil aberto x somente leitura; Customer Core decompoe x OM decompoe); trocar LWC por FlexCard/OmniScript; Imputar Venda = submit ao OM |
| W-000107 | CPQ-BRE-01 Motor de precificacao de projetos especiais | Amarelo | Business Rules Engine (Decision Matrix, Expression Set) chamado por IP/Flow | Definir como o resultado do BRE entra no carrinho (pricing variable/adjustment, nao override); confirmar licenca BRE; recuperar os AC no texto |
| W-000119 | B2B-07 Importacao de sites por planilha | Amarelo | Multi-Site Quote and Order Capture (grupos/membros); ESM Bulk Upload Location | Separar Multi-Site (no CMT) de ESM (produto/licenca distinta); decidir licenca antes; se OmniScript+DataRaptor, definir fila e limite de 200 |
| W-000120 | B2B-08 Parceiros Finder/Integrator/Premiere | Verde | Record type de Account; Lead field mapping; Opportunity Splits com tipo custom; Validation Rule | Fechar regra de comissao com a Diretoria antes da sprint; confirmar Team Selling habilitado (pre-req de Splits) |
| W-000122 | B2B-09 Signatario legal, procuracao, NPS | Verde | Opportunity Contact Roles customizaveis; Validation Rule/Flow; Files; Scheduled Flow; CLM DocuSign expire settings | Unificar a regua de 30 dias com W-000145 RN-12 (uma fonte); campo de validade da procuracao em ContentVersion |
| W-000123 | B2B-10 Visao 360 do grupo economico | Verde | FlexCards + DataRaptor; Account Hierarchy; ABO a partir do Asset | Definir limite de linhas por FlexCard e carregamento por empresa; MRR consolidado via DataRaptor aggregate |
| W-000140 | Habilitar integracao B2B em sandbox | Verde | Named/External Credentials com principals por permission set; IP reapontadas | Registrar que refresh de sandbox nao copia segredos das External Credentials; checklist por endpoint |
| W-000141 | Escrever historias TEC-B2B (onboarding) | Amarelo | n/a (enabler); padrao TEC-B2C | Reclassificar como Task/Spike com Definition of Ready das TEC; nao e user story |
| W-000144 | B2B-15 Condicoes de faturamento | Verde | Campos header Quote/Order/Contract; Field Mapper ABO; Approval Process com lock; Custom Metadata | Manter; alinhar chaves SAP antes do dev |
| W-000145 | B2B-16 Cadencia de assinatura ao cliente | Verde | Salesforce Data Event + Journey Builder; Schedule-Triggered Flow (contingencia); Vlocity CLM Custom Settings | Mover a contingencia RN-10 para US separada ou anexo; confirmar canal DocuSign do CLM |
| W-000124 | B2B-11 Fim de degustacao | Amarelo | Asset + Scheduled Flow; ABO change order; Time Plan/Time Policy | Com Time Plan a promocao expira sozinha: RN-03/RN-05 nao precisam de change order para "converter", so para refidelizar |
| W-000100 | B2B-05 Upgrade/Swap + notas de permuta e refidelizacao | Amarelo | ABO asset-to-quote (AssetReferenceId); Field Mapper; Discounts order/contract-based; Flow Approval; CLM Amend | Dividir em Upgrade, Swap/Permuta e Refidelizacao com upgrade; trocar LWC "antes x depois" pelo carrinho ABO nativo |
| W-000125 | B2B-12 Downgrade | Verde | ABO change (Change/Delete); Penalty rules (context rules); Flow Approval por faixa; CLM Amend | Manter; validar formula de multa com Juridico |
| W-000142 | B2B-13 Refidelizacao simples | Verde | CLM Amend Frame Agreement; Contract State Model + Vlocity Actions; Scheduled Path; contract-based discount; Repricing Batch | Confirmar em sandbox que o Amend aceita alterar so termo/datas sem clonar linhas |
| W-000099 | B2B-04 Cancelamento, retencao, multa | Vermelho | ABO disconnect; Penalty rules; Promotions/Discounts de retencao; Flow Approval; OM com callback | Reescrever o corpo com as decisoes de 10/09 (sem Apex de multa, sem Price Book); separar esteiras de retencao em US propria |
| W-000143 | B2B-14 Aviso previo e corte automatico | Verde | Record-triggered flow com Scheduled Path; Convert Asset to Order (Delete); PONR/in-flight cancel | Manter; go-live condicionado a licenca de OM (W-000134) |
| W-000136 | Mapear fluxo e APIs do B2B | Verde | Catalogo TM Forum do Communications Cloud (inbound e MuleSoft Direct) | Usar a lista de APIs TMF do Salesforce como coluna "padrao" da tabela; ADR por decisao |
| W-000137 | Decomposicao e camada tecnica do catalogo | Verde | Order Decomposition Configuration; Orchestration Plan Definition | Definir criterio de aceite: 1 oferta decomposta e orquestrada em sandbox |
| W-000133 | CI/CD GitLab + sf CLI | Verde | sf project deploy validate/start; JWT bearer flow; OmniStudio Build Tool para DataPacks | Usar deploy validate + quick deploy em producao; plano para DataPacks (Build Tool) desde a sprint 2 |
| W-000134 | Licenciamento OM e sandboxes | Verde | Usage-Based Entitlements; Match Production Licenses / Push Licenses | Manter; registrar case e data |
| W-000135 | MuleSoft: orcamento e inventario | Verde | MuleSoft Direct Integrations e TM Forum inbound APIs | Verificar o que ja existe no MuleSoft Direct antes de construir; marcar TMF x proprietario por demanda |

## Padroes encontrados por grupo

### Grupo A: B2C jornadas (W-000057 a 083)

1. Falta de critérios de aceite verificáveis nas 13 histórias do formato "curto" (W-000057 a W-000069): têm solução técnica rica, mas nenhum Gherkin; as do formato "consolidado" (W-000071 em diante) têm Gherkin, mas às vezes contradizem a solução.
2. Histórias que misturam 2 a 5 histórias (B2C-01, 05, 09, 12, 14, 19, 20): as três Vermelhas B2C-09/19/20 são exatamente as que acumulam etapas de processo e emendas.
3. Emendas empilhadas sem consolidação (B2C-02, 04, 09, 24, 25): o corpo original permanece com o desenho superado e a decisão fica só na nota; quem constrói lê o corpo.
4. Regra de "Ganho" e "trava de perda" definida em três lugares com três gatilhos (B2C-05, B2C-09, B2C-20 regra 4, B2C-23): precisa de uma única fonte (B2C-23 = Ganho após callback de ativação; B2C-09 = trava de perda após PDF assinado).
5. Ciclo financeiro da taxa de ativação espalhado em B2C-11/12/19/20 sem máquina de estados única nem contrato de baixa bancária; todas dependem de um webhook que ainda não existe.
6. Sharing (OWD) decidido dentro de US isoladas e de forma contraditória (B2C-15 "Read", B2C-16 "Public Read/Write", B2C-17 "Private"): deve sair das US e ir para o modelo de segurança do programa.
7. Endpoints custom onde há capacidade do pacote: Apex REST para venda touchless (B2C-18) e REST inbound para site (B2C-14) — Digital Commerce/TMF622, Web-to-Lead e Mule cobrem.
8. Campos/objetos custom duplicando o padrão: StageEnteredAt__c (OpportunityHistory), UserRegionalMapping__c (User), campos de faturamento (Order/Contract padrão), Endereco__c (Premises).
9. Licenças assumidas sem confirmação (Omni-Channel para vendas, Marketing Cloud + WhatsApp, biometria/assinatura): bloqueiam planejamento e devem virar pré-requisito explícito.
10. Nomes TMF usados como se fossem contrato de payload; a diretriz 04/09 (TMF como mapa de capacidade, endpoints proprietários via Mule na Onda 1) está correta e deve ser aplicada em todas as US, não só nas que receberam a nota.

### Grupo B: B2C jornadas e fundacoes tecnicas (W-000084 a 132)

1. Works viram diario de decisoes: W-000085, 087, 088, 093, 094, 117 tem 3 a 6 notas datadas que se substituem; ninguem sabe qual RN vale. Consolidar em "versao vigente" e mover historico para o comentario.
2. Criterios de aceite fora do texto ou ausentes: W-000091 e 092 nao tem CA; W-000105, 106, 109, 110, 115, 116, 117 dizem "migrados para a related list". A work precisa ser legivel sozinha.
3. Maquinas de estado e versionamentos proprios onde o produto ja tem: status de Order (W-000118), estados de contrato (W-000126), versao de template (W-000106). Mapear para o nativo.
4. Approval Process classico citado em W-000115 e 129: usar Flow Approval Processes.
5. Fronteira Zendesk x Salesforce (360, contrato, retencao) aparece em W-000087, 095, 105, 129 e nao esta decidida - bloqueia tres historias.
6. Dados legados como pre-condicao invisivel: Person Accounts (W-000117), 1 Asset em producao (W-000116, 109, 130), Endereco__c (W-000094). Abrir works de dados/migracao explicitas.
7. Texto de referencia generico (eSIM, ICCID, Black Friday, TOA/ClickSoftware) sobrevivendo em W-000093/094 - limpar para o portfolio real.
8. Um desvio de desenho relevante: geracao de documento via Mule (W-000089) quando o Server-Side DocGen ja e assincrono; e um custom pequeno mal declarado (assinatura de Platform Event no OmniScript, W-000086).
9. Positivo: o grupo e majoritariamente native first (Cart APIs, EPC, OM, ABO, CLM, Field Service, Platform Events) e reusa o que esta em producao com evidencia.

### Grupo C: Catalogo (EPC/CPQ)

1. Conflito de estrutura de catalogo nao resolvido (por mercado na W-000056 x por familia na W-000070), replicado na W-000111 RN-06. E a decisao que mais trava o grupo; ambos os modelos sao nativos, falta um ADR e limpar as outras works.
2. Blocos de governanca colados dentro das historias (consolidacao 15/09 identica em W-000051/052/055; decisoes P-01..P-18 dentro da W-000070; pendencias P1-P8 repetidas). Isso deixa as US sem uma versao unica e cria numeracao divergente de pendencias (P-17/P-18/P-19 com significados diferentes).
3. Criterios de aceite "migrados para related list" e ausentes do texto em 10 das 18 works; quem constroi nao ve o AC junto da regra. As works com Gherkin no corpo (W-000121, 127, 128) sao as mais construiveis.
4. Mistura de dominios na mesma US: estoque, Work Order, NF, billing e integracao SAP aparecem em historias de catalogo (W-000111, 127, 128, 103). Catalogo deve parar na publicacao/precificacao; fulfilment fica em OM/FSL/integracao.
5. Ambiguidade de mecanismo de precificacao: "PLE por modalidade" x matriz (W-000121), floor sem mecanismo (W-000108), Context Rules e Decision Matrix para a mesma decisao (W-000128). Escolher um caminho nativo por regra e escrever.
6. Dimensao de contexto no nivel errado: Cidade IBGE como dimensao (W-000056) em vez de zona resolvida (W-000114); em cache do Digital Commerce isso multiplica combinacoes.
7. Positivo: nenhuma historia pede carrinho proprio, LWC proprio ou objeto custom onde ha nativo; os customs identificados (objeto IBGE->zona, Service Tag, campo de ultimo uso) sao pequenos e justificados. O grupo e native-first no desenho; o problema e escrita e governanca.

### Grupo D: B2B e tecnicas

1. Corpo desatualizado com notas que o contradizem (W-000098, W-000099, W-000101, W-000100): as decisoes de 01/09, 04/09 e 10/09 vivem em apendices; o dev que le o corpo implementa o desenho antigo (Advanced Approvals, Apex de multa, Price Book, LWC). Consolidar o corpo antes da sprint.
2. Historias-guarda-chuva: as US originais do documento "Historias refinadas" juntam 3 a 5 historias (regua + enriquecimento + duplicidade; cotacao + alcada + DocGen + validade; cancelamento + retencao + multa + billing). As US novas (W-000119 a W-000145) ja nascem no tamanho certo; usar o mesmo padrao.
3. Prescricao de implementacao custom onde ha nativo: Scheduled/Batch Apex (flow agendado), LWC de tela (FlexCard/OmniScript), LWC "antes x depois" (carrinho ABO), motor Apex de multa (penalty rules), Advanced Approvals (Flow Approval Processes), DocGen via MuleSoft (server-side nativo).
4. Dois motores de aprovacao sem dono: Approve Discounts do carrinho CPQ x Approval Process/Flow Approval. Definir um unico padrao de projeto (proposta: Flow Approval Process com record lock) e citar nas US B2B-03, 05, 06, 12, 15 e 04.
5. Licenca como pre-condicao invisivel: OM (W-000134), ESM (W-000119), BRE (W-000107), MuleSoft Direct (W-000135). Marcar "Bloqueado por licenca" no Agile ate confirmacao.
6. Confusao de vocabulario Sales Cloud x CPQ: "estagio da Cotacao" (Quote tem Status; Stage e da Opportunity); "Assets convertidos pelo botao" (assetizacao e do OM).
7. Ponto forte: as US tecnicas (W-000133 a W-000137, W-000140) e as B2B novas (W-000142 a W-000145) citam o Help e os limites da plataforma; sao o modelo a seguir.

## Segunda rodada (22/09, noite): licencas, objetos nativos, sincrono x assincrono, OM e releases

Motivo: a W-000145 saiu da primeira rodada assumindo DocuSign, e outras historias assumiam Advanced Approvals, Person
Account, objetos custom onde existe objeto padrao ou do pacote, e nao diziam quais chamadas sao sincronas ou assincronas.
As 107 works do programa (93 da primeira rodada + 14 criadas na conciliacao) foram reescritas de novo, agora cruzando cada
uma com quatro insumos fixos: `docs/2026-09-22-licencas-org-prod.md`, `docs/2026-09-22-perfis-e-papeis-org-prod.md`,
`docs/2026-09-22-pesquisa-order-management-e-releases.md` e a documentacao oficial (help, developer, trailhead).

Regras aplicadas em todas:
- Toda capacidade citada tem PSL ou licenca conferida no inventario; o que nao existe na org entra na linha "Nao utilizado
  por falta de licenca" (DocuSign ou qualquer motor de assinatura, Advanced Approvals, ESM, MuleSoft Direct, Salesforce Maps).
- Assinatura: aceite por evidencia (ContentVersion vinculado a Quote/Contract, AuthorizationFormConsent quando cabe) ate a
  BTP decidir fornecedor; tokens do Document Generation preservados no template para o motor futuro.
- Aprovacoes: Flow Approval Orchestration (ApprovalSubmission/ApprovalWorkItem), record-triggered e Request Approval,
  aprovacao unanime quando a regra pede; nunca sbaa__ (Salesforce CPQ).
- Person Account nao habilitado: Account record type Pessoa Fisica + Contact / B2B - Pessoa juridica.
- Objeto custom so com justificativa; antes disso: objetos padrao, objetos do pacote CMT, Custom Metadata Type, Decision
  Table/Decision Matrix do Business Rules Engine (PSL BREDesigner licenciada e sem uso), Task padrao.
- Cada historia ganhou tres secoes novas: LICENCAS E CAPACIDADES UTILIZADAS, CHAMADAS SINCRONAS E ASSINCRONAS (tabela com
  mecanismo, retentativa/idempotencia e o que o usuario ve) e OBJETOS (padrao / pacote / custom com justificativa), alem de
  REFERENCIAS so com URLs oficiais.
- Perfis e papeis com os nomes reais da org (B2B - Vendedor/SDR, B2B - Gerencia, B2B - Backoffice, B2C - Vendedor,
  B2C - BackOffice, B2C - Gerente, papeis B2B_Head_*, B2B_Gerente_<cluster>, B2C_Agente_*, etc.).
- OM e releases: mecanismos nativos do Order Management (supplemental order, amend/cancel ate o ponto de nao retorno,
  rollback, item callout com retentativa, fallout, OrderSubmitMode em fila) e a decisao Plan A (OM do pacote) / B (Mule) /
  C (DRO no Core) registrada nas historias de pedido; Spring/Summer '26: Apex user mode API 67.0, External Client App,
  trim mode e deep clone do carrinho, Decision Tables versionadas com Decision Explainer, Generate Document localizado,
  flows agendados em lote no lugar de Batch Apex.

Trocas de licenca ou objeto por historia (o que mudou de solucao, nao so de texto):

| Historias | Antes | Depois |
|---|---|---|
| W-000086, 087, 089, 101, 105, 106, 116, 118, 121, 122, 126, 128, 145, 169 | DocuSign / motor de assinatura | Aceite por evidencia (ContentVersion, AuthorizationFormConsent); motor externo so via MuleSoft |
| W-000098, 108, 121, 128, 144, 160, 163, 165, 166, 169, 170 | Advanced Approvals (sbaa__) | Flow Approval Orchestration com Decision Table de alcadas |
| W-000056, 102, 114 | Objeto custom GeographicCommercialPolicy (IBGE x zona) | Decision Table versionada do BRE com upload CSV; codigos de zona como campos em Premises/ServicePoint |
| W-000110, 120 | Objetos custom de mapeamento e percentuais | Custom Metadata Type |
| W-000107 | Objeto custom de log de calculo | Decision Explainer + campos na QuoteLineItem |
| W-000119 | Relatorio custom de importacao | CSV como ContentVersion + Task |
| W-000145 | Objeto custom Envio_para_Assinatura__c | Task padrao com WhoId no signatario (entry source do MC a validar) |
| W-000168, 169 | ProcessInstance | ApprovalSubmission / ApprovalWorkItem |
| W-000171, 172, 173 | vlocity_cmt__Contract__c / ContractTerm__c | Contract padrao + vlocity_cmt__ContractVersion__c |
| W-000169, 170 | Record types Cortesia/Swap na Opportunity | Atributo Tipo de Negociacao no carrinho |
| W-000162, 165 | Manual Override / override via OmniScript | Promocao 100% com Time Plan/Time Policy (162); Discount order-based (165) |
| W-000128 | Campo de reuso no Asset | AccountAppliedPromotion__c / OrderAppliedPromotion__c (Asset so espelho) |
| W-000127 | Matriz de compatibilidade custom | Decision Matrix ou Decision Table do BRE |
| W-000130 | Platform Event / IP inbound | REST upsert padrao por External Id |
| W-000097 | vlocity_cmt__ServiceAccount__c | Account com record type do modelo CME |
| W-000093, 096, 101, 117, 144, 166, 167, 169, 170, 171, 172 | Person Account | Account record type Pessoa Fisica + Contact |
| W-000092 | WhatsApp assumido | Add-on do MC Engagement a confirmar; fallback e-mail por Flow |
| W-000090, 091, 095, 129 | Assentos de Service | Licenca Salesforce full ja atribuida + Service Console for Communications (PSL ociosa) |

Pendencias que ficaram escritas nos textos (decisao do negocio, nao da historia): aprovador financeiro da W-000144 (nao
existe perfil financeiro; proposta B2B_Head_<unidade>); Task como entry source do Marketing Cloud (W-000145); Decision
Explainer x objeto de log (W-000107); Plan C do OM (DRO no Core) a levar ao presidente; WhatsApp no contrato do MC (W-000092).

Validacao antes da carga: 107 textos entre 3.932 e 8.996 caracteres (limite 32.000); sem markdown, sem emoji, sem marca de
ferramenta; URLs so de dominios oficiais; DocuSign/Advanced Approvals/Person Account aparecem apenas como "nao licenciado" ou
"nao habilitado". Backup do texto anterior em `org/tmp/agile_backup/rollback_details_2026-09-22_v2.csv` (fora do git).

Carga: o modo automatico bloqueou o `sf data update bulk` em producao. Arquivo pronto em
`org/tmp/agile_carga/carga_details_2026-09-22_v2.csv` (Id, agf__Details__c). Comando para executar na raiz do repo:

```
sf data update bulk --sobject agf__ADM_Work__c --file org/tmp/agile_carga/carga_details_2026-09-22_v2.csv --target-org btp-prod --wait 10
```

Conferencia depois da carga: `python tools/agile/conferir_carga_details.py` compara o campo na org com o CSV e lista
divergencias. Rollback: `python tools/agile/conferir_carga_details.py --gerar-rollback` recorta o backup para as colunas
Id e agf__Details__c em `org/tmp/agile_carga/rollback_details_2026-09-22_v2.csv`, que se aplica com o mesmo comando de carga.
