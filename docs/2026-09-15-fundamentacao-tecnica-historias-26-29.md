# Fundamentação técnica das histórias B2B 26 a 29 — fatos extraídos da documentação oficial

Fonte: 22 páginas do Salesforce Help coladas pelo Diego em 15/09/2026 (lista em `2026-09-15-fontes-tecnicas-historias-26-29.md`). Cada bloco traz só o que a página afirma e é usado nas works. Nada aqui vem de memória.

## Sales Cloud / Platform

### Contract Fields (`sf.contract_fields`)
- Campos padrão: Contract Start Date; Contract Term (months); Contract End Date ("o admin pode configurar o cálculo automático a partir de start date e term; se auto-calculado, não aparece na edição"); Activated By / Activated Date; Customer Signed By / Date / Title; Company Signed By / Date; Owner Expiration Notice ("dias antes do end date para notificar contract owner e account owner"); Special Terms.
- Status: picklist com valores customizáveis dentro de **três categorias de sistema: Draft, In Approval Process, Activated**. Usadas para relatórios e views.
- Contract Number: auto-number a partir de 100.

### Scheduled Paths em record-triggered flow (`platform.flow_concepts_trigger_scheduled_path`)
- Time Source: evento de gatilho **ou campo Date/DateTime do registro**, com offset antes ou depois.
- Roda em system context; o usuário associado às ações é quem alterou o registro; exige Default Workflow User configurado.
- Batch: padrão e máximo 200, mínimo 1; registros agendados para o mesmo minuto são agrupados.
- **Cancelamento automático**: se o registro é atualizado e deixa de atender às condições de entrada, "any already scheduled paths are canceled". Se volta a atender, agenda de novo.
- **Reagendamento**: mudar o campo usado como Time Source reagenda o path para a nova data, desde que futura, mesmo que o path já tenha rodado (uso documentado para ações recorrentes).
- Só disponível com "A record is created" (com ou sem condição) ou "created/updated/deleted" com **Only when the record is updated to meet the conditions**.
- `$Record__Prior` não suportado no path agendado.
- Limite: 250.000 entrevistas por 24 h ou licenças × 200, o maior; caminhos imediatos não contam; excedente roda quando o limite reseta.
- Falha: e-mail de erro e **retentativa em 15, 30, 60, 120 e 240 min (5 tentativas)**; em lote com falha parcial, rollback e 2 retentativas.
- Desativar o flow cancela os pendentes; nova versão ativa processa os pendentes.
- Pendentes visíveis em Setup > Time-Based Automations. Eventos de debug FLOW_SCHEDULED_PATH_QUEUED e FLOW_VALUE_ASSIGNMENT.
- Tabela comparativa: scheduled path = "uma vez por gatilho, tempo relativo ao gatilho ou a um campo de data"; schedule-triggered flow = "data/hora específica, uma vez, diário ou semanal".

### Schedule-Triggered Flows e Considerations (`platform.flow_concepts_trigger_schedule`, `flow_considerations_trigger_schedule`)
- Inicia em hora e frequência definidas (uma vez, diário, semanal) para um lote de registros do objeto e filtro; `$Record` por registro; monitorado em Setup > Scheduled Jobs.
- **Start Time é no fuso padrão da org**.
- Roda como **Default Workflow User**; ativar exige View All Data.
- Lote padrão 200 (1 a 200); limite 250.000 entrevistas por flow e por 24 h (ou licenças × 200).
- Callouts sem Wait só se processa lote e API 63.0+; senão só após um Wait (truque do Wait de 0 h).
- Se um DML em lote falha para alguns registros, tudo é revertido e os bons são retentados; segunda falha derruba a transação.
- Sandbox refresh: flows agendados ativos podem rodar imediatamente na sandbox nova.

### Send Email Action (`platform.flow_ref_elements_actions_sendemail`)
- Exige verificação de domínio e de e-mail do usuário.
- Sender Type: CurrentUser (padrão), DefaultWorkflowUser ou **OrgWideEmailAddress** (com Sender Email Address).
- **Em scheduled-triggered flow: configurar Organization-Wide Email Address em Setup > Email e também em Setup > Process Automation Settings > Automated Process User Email Address.**
- Recipient ID = Lead ou Contact; Related Record ID = registro não destinatário (ex.: Oportunidade); **Log Email on Send = True registra o e-mail na timeline/histórico de atividades** do Recipient e do Related Record.
- Email Template ID/Name exige Recipient ID; template com merge fields de outro objeto usa Related Record ID; preferir Email Template Name para deploy entre orgs.
- Máximo 150 destinatários somados (To, CC, BCC, Recipient ID); e-mail até 35 MB.
- **Usar template, anexos ou Log Email on Send muda a API e o limite passa a ser o General Email Limit (5.000 externos/dia, GMT); sem isso vale o Daily Workflow Email Limit.** Internos não contam.
- E-mail só sai quando a transação da entrevista completa; não sai em debug Rollback.

### Daily Allocations for Email Alerts (`platform.workflow_limits_email`)
- Email alerts: 1.000 por licença standard por dia, teto 2.000.000 por org (24 h GMT); vale para workflow, approval, flows, REST.
- Single email: **5.000 destinatários externos por dia, GMT**; orgs criadas do Spring '19 em diante aplicam também a email alerts, simple email actions, Send Email de flow e REST. Composer: 250 externos por hora por usuário.
- Ao estourar: e-mails na fila são descartados, não reenviados; aviso a 90% e a cada 100 tentativas acima.

## Marketing Cloud Engagement

### The Salesforce Data Event (`mktg.mc_jb_salesforce_data_event`)
- Entrada na jornada por criação/atualização de registro de objeto do Sales/Service Cloud; ao ativar, **cria um Flow na org Sales Cloud**.
- Definir: objeto primário, quem entra (users, leads, contacts, person accounts), quando (create/update/ambos), filtros no primário e em objetos referenciados, dados da jornada (≤ 250 campos; ≤ 80 jornadas por objeto).
- Cada registro leva ID do who, e-mail e flag de opt-out.
- **Depois de configurado não se troca o objeto nem quem entra; para trocar, deletar e recriar.** Só editável quando nenhuma jornada em execução usa o entry source.
- Cria uma Data Extension com os campos do evento; uma linha por entrada (o mesmo registro pode entrar mais de uma vez).
- **Test Mode não suporta Salesforce Entry Sources.**
- Sujeito a governor limits do Apex: future (usar MC Connect ≥ 5.496), transações com > 2.000 registros falham, CPU, 50 enqueueJob por transação.
- Permissões: Email | Integrations | Salesforce CRM; Journey Builder | Sales and Service Cloud.

### Configure the Salesforce Data Event (`mktg.mc_jb_configure_salesforce_data_event`)
- "Se o objeto for Leads, Contacts ou Users, o Who ID está disponível. **Para qualquer outro objeto, o objeto precisa ter um campo lookup para o Who ID**" (Contact).
- Campos polimórficos não servem para filtro secundário.

## Communications Cloud — Industries CPQ / EPC

### Industries CPQ (índice, `ind.comms_industries_configure__price__quote__cpq_`)
- Três interfaces: Angular (Hybrid), LWC CPQ (Flexcards, Winter '22), **Enhanced LWC CPQ (Spring '24, recomendada, componentes nativos)**; Salesforce não investe mais no Angular.
- Capacidades listadas: ABO, MACD, multi-site (grupos), attribute-based pricing, availability/eligibility, versionamento, OM integration, Cart-Based APIs, Sales Config Templates, Deep Clone.

### EPC (índice, `ind.comms_enterprise_product_catalog__epc_`)
- Catálogo comercial + técnico num modelo único (PSR: product-service-resource), consumido por CPQ, CLM e OM; Product Console/Product Designer e Pricing Designer; import/export por DataPacks; "SLDS 2 não é compatível com EPC".

### Pricing Definition (índice, `ind.comms_pricing_definition`)
- Benefícios: componentes reutilizáveis independentes de produto; tipos (penalidades, charges, adjustments); **frequência da cobrança é propriedade do preço**; transição de preços no tempo.
- Subpáginas relevantes: Manual Price Changes in the Cart, Price Adjustments and Overrides, Reprice Existing Prices ("reprecificar line items de opportunities, orders, quotes **e assets**"), Pricing Strategies for Bundles, Pricing Hooks.

### Create a Pricing Variable (`ind.comms_create_a_pricing_variable_in_pricing_designer`)
- Pricing Variable: Code (ex.: REC_MNTH_STD_PRC, OT_FEE), **Charge Type = Recurring | One-time | Adjustment | Usage; Sub-Type = Standard price | Penalty fee**; Currency Type (moeda ou pontos); Type = Price | Cost; **Frequency: só quando Charge Type = Recurring, define a frequência da recorrência**; Adjustment Method Absolute/Percentage.
- Value Type Calculated ou Pricing Element; Aggregation Unit/Quantity; Scope Line Item / Rollup / Parent / Parent Rollup / **Group, Group Rollup, Master, Master Rollup (multi-site)**; Applies To Variable (ex.: adjustment sobre o recorrente anual).
- Conclusão para a história 28: **a frequência de cobrança no Industries CPQ é atributo da pricing variable, ou seja, do catálogo de preços, não uma escolha por cotação.**

### Price Assignment and the Cart (`ind.comms_price_assignment_and_the_industries_cpq_cart`)
- Price List Entry = pricing variable + pricing element; um PLE marcado como base price aparece na lista; ao adicionar ao carrinho o pricing service escolhe o **"tightest match"** (PLE vigente, PLE com context rule, ou PLE de child price list por context rule).
- Produto sem base price aparece com preço zero na lista.
- Vários preços: price lists diferentes ou PLEs com faixas de efetividade sem sobreposição. PLE válido: Active, Effective From não futuro, Effective Until não passado.

### Set Up ABP with Time Plan and Time Policy (`ind.comms_set_up_attribute_based_pricing_with_time_plan_and_time_policy`)
- Na Pricing Plan Step do ABP, flag `CreateAdjustment: true` com `TimePlanAttributeBasedProcedure` / `TimePlanAttributeBasedMatrix`; a matriz tem colunas de saída **MRC, NRC, Time Plan e Time Policy**; gera line items de Pricing Adjustment com **Source = ABP**.

### Availability and Eligibility Rules (`ind.comms_availability_and_eligibility_rules`)
- Regras rodam contra o header (Opportunity, Quote, Order); availability primeiro, depois eligibility; multi-service point com regras por site.
- Standard: Products Not Available (estado/CEP, datas) e Products Not Eligible (Account Record Type, SLA). Advanced: entity filters (tipo Qualification) + Vlocity Rules com ações include/exclude.
- Implementações por interface (ProductAvailabilityInterface / ProductEligibilityInterface).

### Asset-Based Ordering (`ind.comms_asset_based_ordering`)
- Asset com extensões Industries (descontos, bundle pricing, **cancellation fees**, preferências). Provisioning status: **New, Active, Deleted**.
- Mudanças: adicionar serviço/produto, atualizar, **disconnect** ("cancelar um serviço").
- Fluxo: Asset → Quote → Order → Asset, ou Asset → Order → Asset; submissão da ordem chama a implementação ABO que cria/atualiza assets. Field Mapper mapeia campos entre Opportunity, Order, Quote e Asset; Object Mapper leva objetos filhos. **Asset Reference ID + provisioning status rastreiam o asset no ciclo ABO.**
- Subpáginas: MACD, Asset Viewer (LWC), Convert an Asset to a Quote or an Order, Fields for Asset-Based Orders, Submitting an Order and Creating Assets.

### Create an Asset-Based Order (`ind.comms_create_an_asset_based_order_in_industries_cpq`)
- Da aba Assets da conta: selecionar assets > Change to Order > New Order (nome, start date, status, price list, **"requested date and time to submit the order"**, Assets Action Type = Change Assets, Update Method Bulk) ou Add to Existing Order.
- Grupos por offer ID; por linha: No Change (padrão), Bulk Add, atualização de propriedade, **Bulk Delete (root bundle ou filhos opcionais)**; valida e precifica; ordem temporária interna no LWC.

## Communications Cloud — Industries CLM (Vlocity Contracts)

### CLM Overview (`ind.v_contracts_contract_lifecycle_management_overview`)
- Contratos ligados a opportunity, order, quote ou objeto custom; contrato carregado da opportunity para a quote e para a order; contratos standalone.
- Recursos: tipos de contrato; biblioteca de cláusulas e templates; condições por seção; geração no order capture; **State Model + Vlocity Actions** (estados, condições, permissões); termos automáticos; **roteamento e escalonamento de aprovações**; comparar e reconciliar versões; **integração com DocuSign para lembretes e eSignature**; **"renovar contratos automaticamente criando oportunidades, enviando notificações e gerenciando atividades"**; rastreio de termos gerais e de preço (descontos); **versionamento e change management nativos**.
- DocGen do CLM: 100% nativo, mas roda no browser (não é serviço server-side, não roda em OmniOut, não gera lote); saída Word/PDF a partir de HTML.
- Subpáginas: Contract State Model and Workflow, Contract Creation (contrato criado na opportunity é copiado para a quote), Large Quotes to Contracts (assíncrono), Contract Document Management ("admin configura que tipos de mudança exigem aprovação/assinatura; mudança de preço exige, typo não"), Generating a Contract Document.

### To Amend Frame Agreements (`ind.v_contracts_to_amend_frame_agreements`)
- Só frame agreement com status Active. **Amend Frame Agreement cria uma nova quote/opportunity/order**; no carrinho ajustam-se descontos (Allocation = Contract, período em meses, end date, filtro de itens); aprovações internas; **Create Frame Amendment** volta ao contrato com o novo contrato ligado, listado em **Amendment Contracts** no master.
- No aditivo: Manage Contract Terms > Discounts; editar **Contract Start Date e Contract Term (months)**; Effective Start/End dos descontos.
- **Amendment não copia General Terms nem aplica os termos padrão do contract type; carrega só preço e dados da quote; termos gerais devem ser adicionados manualmente** (ou vir do template do aditivo).

### Contract Administration Example (`ind.v_contracts_contract_administration_example`)
- Contract Type + Record Type por perfil; clonar contract type; cláusulas e templates restritos ao contract type; Vlocity CLM Custom Settings. Modelo para criar o tipo "Aditivo de Refidelização".

## Communications Cloud — Industries Order Management

### Overview of Canceled and Amended In-Flight Orders (`ind.comms_t_overview_of_canceled_and_amended_in_flight_orders_in_order_management`)
- Amend/Cancel só **antes do Point of No Return**; ao clicar, o OM **congela** a ordem (itens completos não mudam) e o operador submete uma **ordem suplementar que substitui a original**; o plano de orquestração original é associado à suplementar e segue os planos de rollback/amendment.
- Tabela de estados: itens completos amendados → Amended com itens compensatórios; não iniciados → Discarded; em execução cancelados → Canceled seguindo rollback; falhos cancelados → Failed Discarded com **manual task compensatória para checar fallout**.

### Order Decomposition Configuration (`ind.comms_t_order_decomposition_configuration`)
- Decomposição transforma ordem comercial em técnica e gera fulfillment requests; configura-se **relação (source = produto comercial, target = produto técnico), mapping rules (como os campos/atributos do source vão ao target) e condition rules (avaliadas em runtime)**.

## Páginas de prioridade B (coladas em 15/09, segunda rodada)

### Reprice Existing Prices (`ind.comms_reprice_existing_prices`)
- Reprecifica line items de opportunities, orders, quotes **e assets**, em processo de background (batch); reavalia efetividade das price list entries e das promoções aplicadas; **re-executa só as context rules das price list entries**, não as de produto/promoção; ajustes manuais inválidos voltam ao preço original.
- **"Repricing updates the effectivity dates of promotion adjustment records based on the price list definitions at the time of repricing."**
- Guias: rodar em batch (não em tempo real), objectList com no máximo 20 line items, resultado ordenado por OrderId/QuoteId/OpportunityId/AccountId.
- Repricing API (VlocityOpenInterface) reprecifica OrderItem, QuoteLineItem, OpportunityLineItem, promoções aplicadas, ajustes de oferta e overrides; **Repricing Batch Processor trabalha com assets e orderItems e pode ser restrito por conta, ordem, período ou condição**.
- Winter '22+: **é possível desabilitar a reprecificação de assets** para manter preços e continuar usando promoções expiradas/desqualificadas; "Maintain Asset Price during MACD" e "Retain Original Price During MACD" impedem repricing automático ao converter asset em order line (compatível com ABP).

### Convert an Asset to a Quote or an Order (`ind.comms_convert_an_asset_to_a_quote_or_an_order`, trecho)
- Toda mudança de asset passa por quote ou order. **One-time charges não são levadas do asset para as linhas da ordem. Quantidades das linhas ficam desabilitadas ao converter asset em quote/order.**

### Contract State Model and the Contract Workflow (`ind.v_contracts_contract_state_model_and_the_contract_workflow`)
- O State Model é a lista de estados válidos e transições do Contract Document; **Vlocity Actions** definem, por estado, quais ações existem e para quem (campos To State, Filter/Filter Criteria, **Applicable User Profile**, Active); a ação só aparece se todas as condições valem.
- Só transições iniciadas pela toolbar de Vlocity Actions podem mudar o Contract Record Type; **não há State Transition Rules nem Vlocity Actions customizadas** no State Model.
- Aprovações: aprovadores por contrato ou por contexto de conta/ordem, nomeados ou por título/papel, com sequência e escalonamento.

### Journey Settings (`mktg.mc_jb_journey_settings`)
- **Contact Entry**: No re-entry (não muda após ativar; Test Mode não suporta), Re-entry at any time (pode entrar várias vezes simultaneamente), **Re-entry only after exiting** (indicado para "renovação anual", não concorrente).
- **Default Email Address**: "Use email attribute from Contacts" quando o e-mail pode mudar durante uma jornada longa; "from Entry Source" quando não muda. Campos EmailAddress só aparecem após o entry source configurado.
- Transaction Key só para Custom Events (API), não para Salesforce Data Event. HTS aumenta throughput de e-mail e não pode ser desligado na jornada depois.
- A página **não trata critério de saída**; a Data Extension do Salesforce Data Event é preenchida na entrada e "existing rows aren't updated" (página do Data Event), logo o status atual precisa ser lido em cada passo por decisão sobre dado sincronizado, não pelo dado de entrada.

### Sales and Service Cloud Activities (`mktg.mc_jb_sales_service_cloud_activities`)
- Atividades de canvas que criam/atualizam registros do Sales/Service Cloud via SOAP API: **Object activity (standard ou custom, Create / Simple Update / Find and Update), Task activity (cria Task com campos pré-preenchidos, atribuída ao owner do contato/lead, usuário de sistema ou usuário definido)**, Account, Contact, Case, Lead, Opportunity, Campaign Member, Convert Lead.
- **Assíncronas: a atualização pode levar até 24 horas; só erros UNABLE_TO_LOCK_ROW são retentados (até 10 vezes).** O ID criado fica disponível como Journey Data.
- Permissões: Email | Integrations | Salesforce CRM e Journey Builder | Sales and Service Cloud. Copiar a atividade exige reconfigurar.
