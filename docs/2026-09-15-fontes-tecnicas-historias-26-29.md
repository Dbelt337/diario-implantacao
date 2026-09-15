# Fundamentação técnica das histórias B2B 26 a 29 — fontes a coletar

Situação em 15/09/2026: os domínios help.salesforce.com, developer.salesforce.com, trailhead.salesforce.com e architect.salesforce.com estão bloqueados pelo proxy de saída deste ambiente. A busca web funciona e confirmou os artigos abaixo. O conteúdo de cada página precisa ser colado pelo Diego para a work e os critérios de aceite serem escritos com base na documentação, não em memória.

Prioridade: **A** = sem isso não dá para escrever a work; **B** = refina regra ou critério; **C** = contexto.

## O que a busca já trouxe (trechos confirmados, sem a página inteira)

- Scheduled-triggered flow: lote padrão de 200 registros (1 a 200); limite de 250.000 entrevistas por 24 h ou licenças × 200, o maior; uma entrevista por registro retornado.
- Scheduled paths em record-triggered flow: mesmo limite de 250.000 por 24 h; caminhos imediatos não contam.
- E-mail: 5.000 destinatários externos por dia (dia em GMT), vale para Send Email de Flow, email alerts e Apex em orgs criadas a partir do Spring '19; internos não contam. Send Email em scheduled flow exige Organization-Wide Email Address.
- Marketing Cloud Journey Builder: Salesforce Data Event injeta contato por criação/atualização de registro de objeto do Sales/Service Cloud; objeto e público não podem ser trocados depois de configurado o entry source.
- OmniStudio Document Generation: templates .docx/.pptx, saída .docx ou .pdf; geração por OmniScript, Integration Procedure ou Apex.
- Industries CPQ: Attribute-Based Pricing tem colunas de saída Time Plan e Time Policy; adjustments com Source = 'ABP'.
- Industries OM: in-flight amendment e cancelamento de ordem só antes do Point of No Return; Cancel Order da API cria supplemental order e submete ao OM.
- Contract padrão: StartDate, EndDate, ContractTerm (meses entre início e fim); Record Locking em approval process define quem edita durante a aprovação.

## Por história

### 26. Refidelização Pura e Simples (renovação sem alteração de escopo)

| Pri | Página | O que preciso dela |
|---|---|---|
| A | https://help.salesforce.com/s/articleView?id=ind.v_contracts_contract_lifecycle_management_overview_364784.htm&type=5 | Industries CLM: ciclo do contrato, versões, status, como nasce de Quote/Order |
| A | https://help.salesforce.com/s/articleView?id=ind.v_contracts_to_amend_frame_agreements.htm&type=5 | Amend de contrato/frame agreement: o que o Amend gera (nova versão, aditivo) |
| A | https://help.salesforce.com/s/articleView?id=ind.v_contracts_contract_administration_example_373487.htm&type=5 | Exemplo de administração: renovar, encerrar, versionar |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_set_up_attribute_based_pricing_with_time_plan_and_time_policy.htm&type=5 | Time Plan/Time Policy: como a promoção de fidelidade ganha nova duração na renovação |
| A | https://help.salesforce.com/s/articleView?id=sf.contract_fields.htm&type=5 | Campos do Contract padrão (ContractTerm, StartDate, EndDate, Status, ActivatedDate) |
| B | https://help.salesforce.com/s/articleView?id=ind.energy_create_an_asset_based_quote_in_industries_cpq.htm&type=5 | Asset-to-Quote reduzido: espelhar ativos somente leitura no OmniScript |
| B | https://help.salesforce.com/s/articleView?id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5 | Document Generation para o aditivo de tempo |
| B | https://help.salesforce.com/s/articleView?id=ind.doc_gen_foundation_document_generation_differences_from_clm_and_limitations_391722.htm&type=5 | Diferenças e limites entre DocGen e CLM (decide onde fica o aditivo) |
| B | https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concept_record_locking.htm&type=5 | Record Locking na aprovação BKO |
| C | https://help.salesforce.com/s/articleView?id=ind.v_contracts_t_contract_lifecycle_management_templates_383328.htm&type=5 | Templates do CLM |

### 27. Aviso prévio de cancelamento (30/60/90), reversão e corte automático

| Pri | Página | O que preciso dela |
|---|---|---|
| A | https://help.salesforce.com/s/articleView?id=platform.flow_concepts_trigger_scheduled_path.htm&type=5 | Scheduled paths: agendar o corte em D-Day a partir de campo de data, cancelamento do caminho quando o registro deixa de atender ao critério (reversão) |
| A | https://help.salesforce.com/s/articleView?id=platform.flow_considerations_trigger_schedule.htm&type=5 | Schedule-triggered flow: limites e lote (alternativa ao scheduled path) |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&type=5 | ABO: ordem de disconnect a partir do Asset |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5 | Ação Delete/Disconnect no asset, campos de ordem gerados |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_t_overview_of_canceled_and_amended_in_flight_orders_in_order_management_233647.htm&type=5 | Cancelar a ordem de desativação durante a janela (reversão) e PONR |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_cancel_an_in_flight_order.htm&type=5 | Passo a passo de cancelamento in-flight |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_of_supplemental_orders_234166.htm&type=5 | Ordem suplementar (cancelamento do cancelamento) |
| B | https://help.salesforce.com/s/articleView?id=sf.flow_considerations_limit.htm&type=5 | Limites gerais de Flow (callouts, entrevistas pausadas) |
| C | https://help.salesforce.com/s/articleView?id=sf.orchestrator_considerations_limit.htm&type=5 | Flow Orchestration: limites, caso a espera seja no Orchestrator |

### 28. Condições especiais de faturamento e intervalos de cobrança

| Pri | Página | O que preciso dela |
|---|---|---|
| A | https://help.salesforce.com/s/articleView?id=ind.comms_pricing_definition.htm&type=5 | Pricing Definition: como o CPQ representa frequência recorrente e ciclo |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_create_a_pricing_variable_in_pricing_designer.htm&type=5 | Pricing Variable: Charge Type, Recurring Frequency (mensal/trimestral/anual) e se dá para ter mais de uma frequência por produto |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_price_assignment_and_the_industries_cpq_cart.htm&type=5 | Como a frequência chega às linhas do carrinho (Quote/OrderItem) |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5 | Decomposição: mapear Billing Cycle e Payment Terms para o payload ao SAP |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_pricing_rules.htm&type=5 | Pricing Rules: bloquear combinações não padrão |
| B | https://help.salesforce.com/s/articleView?id=sales.quotes_fields.htm&type=5 | Campos padrão de Quote (onde criar Intervalo de Cobrança e Condição de Vencimento) |
| B | https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concepts_approval_step.htm&type=5 | Approval step com critério de entrada (ciclo não padrão roteia ao BKO) |
| C | https://help.salesforce.com/s/articleView?id=sf.os_calculation_procedures_and_matrices.htm&type=5 | Calculation Procedure para pró-rata em ciclos longos |

### 29. Cadência de notificações de assinatura (proposta e contrato)

| Pri | Página | O que preciso dela |
|---|---|---|
| A | https://help.salesforce.com/s/articleView?id=platform.flow_concepts_trigger_schedule.htm&type=5 | Schedule-triggered flow diário às 08h, fuso da org, filtro por data de envio |
| A | https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_sendemail.htm&type=5 | Send Email: remetente (org-wide ou usuário), template, limites |
| A | https://help.salesforce.com/s/articleView?id=platform.workflow_limits_email.htm&type=5 | Alocação diária de e-mails (5.000, GMT) e o que conta |
| A | https://help.salesforce.com/s/articleView?id=sf.mc_jb_salesforce_data_event.htm&type=5 | Marketing Cloud Salesforce Data Event: entrada na jornada por Quote/Contract (Fernanda pediu MKT Cloud) |
| A | https://help.salesforce.com/s/articleView?id=sf.mc_jb_configure_salesforce_data_event.htm&type=5 | Configuração do Data Event e dados disponíveis na jornada |
| B | https://help.salesforce.com/s/articleView?id=ind.sf_contracts_document_generation_with_omniscript.htm&type=5 | Status do documento gerado e callback de assinatura |
| B | https://help.salesforce.com/s/articleView?id=sales.quotes_fields.htm&type=5 | Quote.Status e ExpirationDate para parar a cadência |
| C | https://help.salesforce.com/s/articleView?id=000386730&type=1 | Visão geral dos tipos de limite de e-mail |

### Transversais (valem para as quatro e para as notas de ajuste)

| Pri | Página | O que preciso dela |
|---|---|---|
| A | https://help.salesforce.com/s/articleView?id=ind.comms_industries_configure__price__quote__cpq_.htm&type=5 | Índice do Industries CPQ (LWC vs Angular, MACD, ABO, multi-site) |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_enterprise_product_catalog__epc_.htm&type=5 | Índice do EPC |
| A | https://help.salesforce.com/s/articleView?id=ind.comms_availability_and_eligibility_rules.htm&type=5 | Context Rules de elegibilidade (cortesia, Taxa Única por oferta) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5 | Discounts order-based e contract-based (permuta, retenção) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_t_create_a_contract_based_discount_203552.htm&type=5 | Contract-based discount (frame agreement) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_create_a_multi_site_quote_or_order_in_industries_cpq.htm&type=5 | Multi-site quote (base da cotação B2B) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing.htm&type=5 | ABP (Taxa Única por atributo, CAT-CPX-01) |
| B | https://help.salesforce.com/s/articleView?id=ind.comms_pricing_matrices_for_attribute_based_pricing.htm&type=5 | Matrizes de preço por atributo (CAT-PRC-01) |
| C | https://help.salesforce.com/s/articleView?id=ind.comms_change_of_plans_in_industries_cpq_and_product_catalog.htm&type=5 | Change of plans (MACD) |
