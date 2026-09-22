# Revisão técnica — Épico B2C (primeira metade, 26 histórias: W-000057 a W-000083)

Base: arquivo A_b2c_1.md (histórias + notas de reaproveitamento AS-IS e decisões até 10/09/2026). Critério native-first: Communications Cloud (EPC, Industries CPQ, OM, OmniStudio, DocGen, CLM), Sales Cloud, Field Service, Flow. Notas: Verde = pronta e native-first; Amarelo = ajustar escrita ou desenho; Vermelho = reescrever ou redesenhar.

Contagem: Verde 3 | Amarelo 19 | Vermelho 4.

## Tabela resumo

| Work | Assunto (curto) | Nota | Capacidade nativa principal | Ajuste em 1 linha |
|---|---|---|---|---|
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

## Avaliação por história

### W-000057 | B2C-01 — Captura, Triagem e Roteamento Omni-Channel
1. ESCRITA: persona e objetivo claros; solução técnica bem inventariada (reuso de campos, VRs inativas, flows de CEP). Mas mistura três histórias (captura/validação, deduplicação, roteamento por skill/região), não tem critérios de aceite verificáveis e deixa dependências abertas (fonte única de canal, Person Account).
2. NATIVO: página padrão de Lead com Dynamic Forms e validation rules (https://help.salesforce.com/s/articleView?language=en_US&id=platform.dynamic_forms_overview.htm&type=5); Duplicate/Matching Rules custom por DocumentNumber__c, inclusive cross-object Lead×Account/Contact (https://help.salesforce.com/s/articleView?language=en_US&id=sales.duplicate_rules_overview.htm&type=5 e https://help.salesforce.com/s/articleView?language=en_US&id=sales.duplicate_rules_create.htm&type=5); Lead Assignment Rules para filas por unidade (https://help.salesforce.com/s/articleView?id=service.creating_assignment_rules.htm&language=en_US&type=5); Omni-Channel skills-based routing e Omni-Channel Flows suportam Lead (https://help.salesforce.com/s/articleView?id=service.omnichannel_attribute_based_routing.htm&language=en_US&type=5 e https://help.salesforce.com/s/articleView?id=service.omnichannel_flows.htm&language=en_US&type=5).
3. DESVIO: nenhum custom indevido. CEPOperationUnit__c como objeto custom mantido pelo Backoffice é aceitável (Custom Metadata Type também é editável na UI e viaja com deploy: https://help.salesforce.com/s/articleView?id=platform.custommetadatatypes_about.htm&language=en_US&type=5; escolher pelo volume de CEPs). Risco de licença: Omni-Channel para usuários de venda exige licença compatível (Service/Digital Engagement) — confirmar antes de assumir skills (https://help.salesforce.com/s/articleView?language=en_US&id=service.omnichannel_enable.htm&type=5). Se não houver licença, Assignment Rules + filas resolvem região; skill fica para fase 2.
4. NOTA: Amarelo.
5. AJUSTE: dividir em 3 US com aceite Gherkin cada; fechar Person Account e fonte única de canal como pré-requisito; registrar decisão de licença Omni.

### W-000058 | B2C-02 — Trilha alternativa: oferta móvel em inviabilidade
1. ESCRITA: persona/objetivo ok, mas o texto tem quatro camadas (original TMF679, AS-IS, oferta móvel 03/09, correção TMF645 09/09) que se contradizem sobre reserva de porta/CTO/token; não há aceite para "inviável → oferta móvel obrigatória → perda só se MobileOfferRejected".
2. NATIVO: Premises e ServicePoint são objetos do pacote CMT para endereço técnico (https://help.salesforce.com/s/articleView?id=ind.v_admin_premises_32879.htm&language=en_US&type=5; modelo em https://help.salesforce.com/s/articleView?id=ind.v_data_models_t_vlocity_communications_data_model_666929.htm&language=en_US&type=5); TMF645 Service Qualification existe como API certificada do Communications Cloud (https://developer.salesforce.com/docs/industries/communications/references/tmf645/v56.0) — aqui a chamada é via Mule, e o padrão TMF fica como contrato-alvo, o que é coerente; Integration Procedure em modo non-blocking para não travar tela (https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_action_properties.htm&language=en_US&type=5).
3. DESVIO: campos custom no Lead (ViabilityStatus__c, MobileOfferRejected__c) são legítimos; CTO__c/PortReservationToken__c devem ficar no ServicePoint (não no Lead) e só existir se o SQM devolver esses dados. VR de bloqueio de perda é nativo. Risco: reserva de porta sem dono.
4. NOTA: Amarelo.
5. AJUSTE: reescrever um texto único com a versão 09/09 (TMF645 síncrono via EAPI, sem reconsulta, campos que o SQM devolve), mover CTO/token para ServicePoint e escrever aceite dos três desfechos (viável, inviável+móvel aceito, inviável+móvel recusado → perda).

### W-000059 | B2C-03 — Análise de crédito e Mesa
1. ESCRITA: duas personas com objetivos diferentes (vendedor consulta; Mesa decide); regras de negócio existem mas o corte de score está "[DEFINIR]"; sem aceite Gherkin; tratamento de exceção (bureau indisponível) não aparece.
2. NATIVO: Decision Matrix + Expression Set do Business Rules Engine para a régua canal→score→taxa→limite, editável sem deploy (https://help.salesforce.com/s/articleView?id=sf.decision_matrices.htm&language=en_US&type=5 e https://help.salesforce.com/s/articleView?id=ind.get_started_with_business_rules_engine.htm&language=en_US&type=5); rota para a Mesa com Flow Approval Processes e fila (https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5); consulta via IP existente.
3. DESVIO: CreditAnalysis__c (snapshot auditável por consulta) é custom justificado — o pacote não tem objeto de análise de crédito; manter FLS restrita. Risco baixo. Governança TMF696 fora do baseline é decisão de arquitetura, não bloqueia.
4. NOTA: Amarelo.
5. AJUSTE: fechar o corte (350/380), separar a US da Mesa (aprovação) da US da consulta, e escrever aceite por faixa de score e para bureau indisponível (resultado "Em análise", sem trava).

### W-000060 | B2C-04 — Flag de débito no endereço
1. ESCRITA: objetivo claro e regra explícita (sem trava, sem alçada); chave definida (CEP+número+IBGE). Faltam aceite Gherkin, o formato do retorno da API e regra de privacidade (quem vê o resumo). A seção REUSO está invalidada pela decisão 01/09 e o texto ainda a carrega.
2. NATIVO: Premises/ServicePoint como registro do endereço consultado (https://help.salesforce.com/s/articleView?id=ind.v_admin_premises_32879.htm&language=en_US&type=5); FlexCard para o alerta; Reports padrão para "vendas em endereços inadimplentes"; IP non-blocking na mesma viagem da viabilidade (https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_best_practices.htm&language=en_US&type=5).
3. DESVIO: nenhum. Dois campos custom no Premises/ServicePoint são o mínimo. Risco: dado sensível (inadimplência de terceiros no mesmo endereço) — FLS e LGPD antes do desenvolvimento.
4. NOTA: Amarelo.
5. AJUSTE: substituir a seção REUSO pelo modelo Premises/ServicePoint, definir contrato da API com TI e escrever aceite (flag exibida, venda segue, relatório lista).

### W-000061 | B2C-05 — Dashboard gerencial e árvore de perdas
1. ESCRITA: mistura saneamento de campos (pré-requisito técnico), árvore de motivos, dashboards e trava de perda pós-assinatura. Sem aceite. Persona tripla.
2. NATIVO: Reports e Dashboards com visibilidade por Role Hierarchy; "tempo na etapa" já é nativo no tipo de relatório Opportunity History (campo Stage Duration, objeto OpportunityHistory) — https://help.salesforce.com/s/articleView?id=sf.reports_opp_history.htm&language=en_US&type=5 e https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunityhistory.htm; motivos/submotivos com Global Value Set + picklist dependente (https://help.salesforce.com/s/articleView?id=platform.fields_creating_global_picklists.htm&language=en_US&type=5 e https://help.salesforce.com/s/articleView?language=en_US&id=fields_about_dependent_fields.htm&type=5).
3. DESVIO: StageEnteredAt__c + flow de carimbo duplica o OpportunityHistory; só se justifica para o Lead (que não tem histórico de estágio nativo) ou para "dias parado" em list view. Risco baixo.
4. NOTA: Amarelo.
5. AJUSTE: separar em (a) saneamento LossReason (pré-requisito), (b) árvore de motivos no Global Value Set da W-000096, (c) dashboards por papel usando Opportunity History; retirar a trava de perda (já está na B2C-09).

### W-000062 | B2C-06 — Tipo de negociação e segmentação por ticket
1. ESCRITA: objetivo e regra (total ≥ R$ 800 → B2S; recálculo a cada alteração) claros; mas não diz onde o Segment é gravado (Opportunity? Quote? Order?), qual o efeito de "direcionar o fluxo" nem o aceite; pendências de negócio (picklist vs RT) não fechadas.
2. NATIVO: picklist existente NegotiationType__c; total do carrinho e recálculo são do Industries CPQ (https://help.salesforce.com/s/articleView?id=ind.comms_final_price_calculation_in_the_industries_cpq_cart.htm&language=en_US&type=5); pricing plans permitem lógica de preço por atributo (https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing_using_pricing_plans.htm&language=en_US&type=5).
3. DESVIO: colocar o cálculo de segmento dentro do pricing plan (step custom) é customização em ponto sensível do pacote. O segmento é uma classificação, não um preço: um Flow record-triggered no Quote/Order após o salvamento do carrinho (campo de total do pacote) resolve sem tocar no pricing.
4. NOTA: Amarelo.
5. AJUSTE: definir campo de destino (Quote.MarketSegment__c existente, replicado na Order para o payload), gatilho = após reprice/salvar carrinho via Flow, e aceite com dois valores (799,99 e 800,00).

### W-000063 | B2C-07 — Field Service: 3 tentativas / 72h
1. ESCRITA: persona, regra quantitativa (3 tentativas, 72h), resultado (fila, cancelamento) e reuso identificados; falta só definir o que registra uma "tentativa" e o aceite formal.
2. NATIVO: Field Service já em produção; WorkOrder com owner = fila e cancelamento de ServiceAppointment; Scheduled-Triggered Flow diário para o corte de 72h (https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_schedule.htm&type=5); filas (https://help.salesforce.com/s/articleView?language=en_US&id=setting_up_queues.htm&type=0); status categories do Field Service para manter o status custom classificado (https://help.salesforce.com/s/articleView?id=fs_status_categories.htm&language=en_US&type=5).
3. DESVIO: ContactAttempts__c e ação de registro são configuração declarativa. CancelRecordAndRelateds é custom já existente (reuso). Risco baixo.
4. NOTA: Verde.
5. AJUSTE: definir "tentativa" (Quick Action que cria Task de tipo Contato e incrementa o contador) e dois cenários Gherkin.

### W-000064 | B2C-08 — Carga automática de perfil e unidade operacional
1. ESCRITA: objetivo e regra de compliance claros; solução prescreve objeto UserRegionalMapping__c sem antes esgotar o User; dependência de provisionamento (SCIM) em aberto; sem aceite.
2. NATIVO: campos custom no objeto User (Empresa do Grupo, Regional, Canal) provisionados por SSO/SCIM do Okta; choices filtradas por $User em OmniScript/Flow; Permission Sets para visão ampliada do Backoffice. Picklists dependentes não filtram por usuário — a história está correta nisso (https://help.salesforce.com/s/articleView?language=en_US&id=fields_about_dependent_fields.htm&type=5).
3. DESVIO: um objeto por usuário duplica dado que deveria estar no User e cria SLA de sincronização manual. Manter apenas o de-para Regional→Unidades (CEPOperationUnit__c ou Custom Metadata: https://help.salesforce.com/s/articleView?id=platform.custommetadatatypes_about.htm&language=en_US&type=5). Risco: desalinhamento com Octa/Senior se ficar manual.
4. NOTA: Amarelo.
5. AJUSTE: mover contexto para o User (SCIM), usar o de-para Regional×Unidade já da B2C-01 para filtrar o picklist e escrever aceite (vendedor da regional X só vê unidades de X; Backoffice vê todas).

### W-000065 | B2C-09 — Resumo da venda e modalidade de aceite
1. ESCRITA: o texto original mais quatro emendas (04/09, 08/09, 10/09) com decisões parcialmente conflitantes (ContractSigned__e vs canal TEC-INT-01; parceiro de biometria vs motor interno; cenário A/B/C em aberto). Mistura tela de resumo, escolha de modalidade, integração de assinatura, armazenamento de PDF e trava de perda. Não é construível como está.
2. NATIVO: etapas de OmniScript existentes; DocGen para a minuta (https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5); File Upload nativo do OmniScript grava ContentVersion (https://help.salesforce.com/s/articleView?id=sf.os_upload_files_and_images_in_omniscripts.htm&language=en_US&type=5); Orchestration Items de assinatura já existentes; Platform Events para o callback (https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_publish.htm).
3. DESVIO: assinatura eletrônica e biometria não são nativas — integração externa é inevitável; o risco é criar um segundo canal de evento paralelo ao TEC-INT-01 (a própria nota já proíbe). Trava de perda por PDF gravado: Flow + VR nativos.
4. NOTA: Vermelho.
5. AJUSTE: reescrever como duas US — "Resumo da venda" (tela) e "Aceite do contrato" (modalidades Digital e Anexo, evento do canal TEC-INT-01, PDF como ContentVersion com hash) — e tirar biometria para US futura condicionada a contrato.

### W-000066 | B2C-10 — Régua de lembretes e expiração por SLA
1. ESCRITA: regra clara (3 disparos, 5 dias, janela 08h-20h, cancelamento automático) e gatilho corrigido para SignatureSent; falta aceite e a licença do Marketing Cloud está "[CONFIRMAR]" — a US não pode ser planejada sem isso.
2. NATIVO: Journey Builder com entrada por API Event (https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_api_entry_source_use_case_1.htm&type=5; https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/how-to-fire-an-event.htm) — correto em preferir API Event ao Salesforce Data Event, cujo sync depende do MC Connect (https://help.salesforce.com/s/articleView?id=sf.mc_co_implement_synchronized_data_sources_best_practices.htm&language=en_US&type=5); templates WhatsApp precisam de aprovação da Meta (https://help.salesforce.com/s/articleView?id=mktg.mc_jb_whatsapp_template_message_approval_considerations.htm&language=en_US&type=5); cancelamento no 5º dia com Scheduled-Triggered Flow (https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_schedule.htm&type=5).
3. DESVIO: nenhum. Risco de licença (MC Engagement + WhatsApp em contrato separado). O fallback (e-mail por Flow + WhatsApp pelo bot) precisa ser uma decisão, não uma nota.
4. NOTA: Amarelo.
5. AJUSTE: bloquear a US até confirmar licença; escrever aceite com o evento de entrada (SignatureSent), exit criteria (assinatura) e o cenário do 5º dia.

### W-000067 | B2C-11 — Débito interno: ticket Zendesk e SLA
1. ESCRITA: objetivo claro; falta decidir o SLA (boleto compensa em 48h dentro de 5 dias), em qual objeto/estágio a Oportunidade "pausa", e o aceite; idempotência do ticket e do evento de baixa não descritas.
2. NATIVO: Flow com Named Credential existente para abrir o ticket; Platform Event inbound DebtSettled__e consumido por Flow (https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_considerations_decoupled_processes.htm); Scheduled-Triggered Flow para o corte de 5 dias; Quick Action de retomada existente.
3. DESVIO: nenhum. Risco de processo: o mesmo evento de baixa alimenta B2C-12/19/20 — deve haver um único canal de "baixa financeira", não um por US.
4. NOTA: Amarelo.
5. AJUSTE: fechar SLA com o negócio, nomear o estágio/status de pausa (o mesmo da list view B2C-21), definir chave de idempotência (ticket por CreditAnalysis__c) e escrever 3 aceites (abre ticket, baixa retoma, 5 dias perde).

### W-000068 | B2C-12 — Taxa de ativação e alçadas de desconto
1. ESCRITA: reuso muito bem mapeado; mas mistura alçada de desconto (Mesa), gate de agendamento por pagamento e consulta de slots pelo chatbot; valor da taxa inconsistente (R$ 149,99 no título, 149,90 no texto); sem aceite.
2. NATIVO: flows de aprovação já existentes (reuso) — se forem refeitos, o padrão atual é Flow Approval Processes com fila (https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5; submit por Flow: https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_approval.htm&language=en_US&type=5); gate de agendamento = Validation Rule/Flow no ServiceAppointment sobre Order.InstallationFeeStatus__c; slots FSL pelo AppointmentBookingService (https://developer.salesforce.com/docs/atlas.en-us.field_service_dev.meta/field_service_dev/apex_class_FSL_AppointmentBookingService.htm).
3. DESVIO: bot externo é inevitável (Messaging desabilitado); expor GetSlots via IP é aceitável mas deve sair pelo Mule (padrão W-000087), não direto. Risco: gate sem callback de baixa definido — a própria diretriz manda não iniciar.
4. NOTA: Amarelo.
5. AJUSTE: reduzir a US a "alçada 0-100% na fila da Mesa + gate de agendamento por status da taxa", mover slots/bot para a B2C-20, corrigir o valor e escrever aceites (aprova, rejeita, gate bloqueia).

### W-000069 | B2C-13 — Seleção guiada, combos e filtro por IBGE
1. ESCRITA: o mais completo do grupo em desenho de catálogo, com fato verificado (filtro desligado) e dependências nomeadas; mas mecanismo "[DEFINIR]" conforme versão do pacote e sem aceite por regra (mercado, canal, tipo de cliente, cidade, família, zona de preço).
2. NATIVO: context rules e qualificação de produtos e de Price List Entries (https://help.salesforce.com/s/articleView?id=ind.comms_rules_overview.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_products.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_price_list_entries_and_child_price_lists.htm&language=en_US&type=5); implementações Availability/Eligibility e cache do Digital Commerce (https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-api-usage-considerations.html; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-defining-context-eligibility-rules.html); Promotions do EPC com ajustes e sequência (https://help.salesforce.com/s/articleView?id=ind.comms_promotions_in_the_product_catalog.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?id=ind.comms_sequential_promotions_and_discounts.htm&language=en_US&type=5); Cart-based APIs (https://help.salesforce.com/s/articleView?id=ind.comms_cart_based_apis_for_ind_cpq.htm&language=en_US&type=5).
3. DESVIO: nenhum — é native-first. Atenção: se o e-commerce usar Digital Commerce com cache, as implementações de interface são ignoradas e só context rules valem (documentado no link acima) — isso decide o mecanismo, não a versão do pacote.
4. NOTA: Amarelo.
5. AJUSTE: fixar "context rules como mecanismo único (CPQ e Digital Commerce)", listar aceite por dimensão e por família, e mover "prazo de contrato como atributo de preço" para a W-000085 com referência cruzada.

### W-000071 | B2C-14 — Ingestão omnichannel de leads
1. ESCRITA: formato completo (regras, Gherkin, DoD, massa), mas são três histórias (carga massiva restrita; QR Code no app; integrações inbound). O Gherkin cobre só duas. Deduplicação na entrada não aparece.
2. NATIVO: permissão "Import Leads" retirada do perfil e concedida por Permission Set (https://help.salesforce.com/s/articleView?id=sf.faq_import_general_permissions.htm&language=en_US&type=5); formulários do site com Web-to-Lead (https://help.salesforce.com/s/articleView?language=en_US&id=sales.setting_up_web-to-lead.htm&type=5); MC Connect para leads de nutrição (https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_salesforce_data_event.htm&type=5); leitura de QR com BarcodeScanner API / componente lightning-barcode-scanner no app Salesforce (https://developer.salesforce.com/docs/platform/lwc/guide/reference-lightning-barcodescanner.html; https://developer.salesforce.com/docs/component-library/bundle/lightning-barcode-scanner); Duplicate Rules na criação.
3. DESVIO: "Inbound REST API para Zendesk e Site" — o site deve usar Web-to-Lead e o Zendesk entrar pelo Mule (padrão W-000087), não Apex REST. O LWC de QR é pequeno e usa API nativa do app; aceitável.
4. NOTA: Amarelo.
5. AJUSTE: dividir em 3 US; trocar REST custom por Web-to-Lead + Mule; adicionar cenário de duplicidade e Assignment Rule por LeadSource.

### W-000072 | B2C-15 — Busca federada e consulta no Customer Core
1. ESCRITA: boa (regras, Gherkin, massa de teste); persona listada de forma confusa; "refatoração da busca global" é enganoso — a busca global do Lightning não é substituível, o que se constrói é um componente de busca na Home/jornada.
2. NATIVO: FlexCard + Integration Procedure + DataRaptor compondo a cadeia BTecPar_BaseClientIntegration existente; DataRaptor Extract por CPF/e-mail/telefone é nativo; Duplicate Rules evitam o duplo cadastro no import.
3. DESVIO: SOSL não é ação nativa de IP (exige Remote Action Apex); usar DataRaptor Extract por chave exata (CPF/CNPJ é chave unívoca) evita Apex. "OWD Read para Accounts" contradiz "OWD Private" da B2C-17 — sharing não é decisão de uma US. Risco de tempo de resposta (2 s) depende do Customer Core.
4. NOTA: Amarelo.
5. AJUSTE: renomear para "Componente de busca do prospect (SF + Customer Core)", trocar SOSL por DataRaptor por chave, retirar a frase de OWD e remeter ao modelo de sharing do programa.

### W-000073 | B2C-16 — Categorização do Lead (converter ou perder)
1. ESCRITA: boa (Gherkin, fallback de timeout, massa de teste, valor set compartilhado). Um ponto errado: "OWD Public Read/Write para conversão cruzada" — conversão em conta existente exige acesso de leitura à conta, não OWD público.
2. NATIVO: Lead Convert nativo permite escolher conta existente e mapeia campos custom via Lead Field Mapping (https://help.salesforce.com/s/articleView?language=en_US&id=sales.customize_mapleads.htm&type=5); Validation Rule para "Motivo da Perda" obrigatório; Global Value Set + dependência motivo/submotivo (https://help.salesforce.com/s/articleView?id=platform.fields_creating_global_picklists.htm&language=en_US&type=5); consulta ao Customer Core pela IP existente.
3. DESVIO: LeadConvertServiceB2C (Apex) já existe — reuso, não novo. Risco: se o merge obrigatório for implementado só no Apex, o botão Converter padrão continua permitindo conta nova; cobrir com VR/flow ou ocultar o botão padrão.
4. NOTA: Amarelo.
5. AJUSTE: remover a frase de OWD, adicionar cenário "API indisponível → conversão manual permitida com flag de pendência" e cenário "cliente da base → conta nova bloqueada".

### W-000074 | B2C-17 — Viabilidade e crédito em um clique
1. ESCRITA: boa estrutura; contradições internas: regra 3 manda "rotear para aprovação do coordenador" enquanto B2C-04 diz "sem trava e sem alçada"; o Gherkin diz "chamadas assíncronas" mas o aceite espera o resultado na mesma tela; a chave de endereço inclui "Complemento" (B2C-04 exclui).
2. NATIVO: Integration Procedure non-blocking/chainable para paralelismo e timeout por step (https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_action_properties.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?id=sf.os_settings_for_long_running_integration_procedures_56206.htm&language=en_US&type=5); FlexCard para o alerta; ServicePoint do pacote.
3. DESVIO: nenhum; é refatoração de orquestração sobre IPs existentes. Risco: SLA < 3 s depende do provedor por tenant — o aceite precisa do estado "Em análise".
4. NOTA: Amarelo.
5. AJUSTE: alinhar regra 3 à B2C-04 (flag, sem alçada), tirar "Complemento" da chave, e adicionar cenário 3 (timeout → "Em análise", vendedor segue com reconsulta).

### W-000075 | B2C-18 — Recepção inbound de vendas 100% digitais
1. ESCRITA: bem estruturada, porém prescreve implementação (Apex REST, Database.rollback, Queueable, objeto de staging) e o Cenário 1 cria a venda em status "Ganha" — contradiz B2C-20/23 (Ganho só após ativação) e B2C-19/20 (taxa e agendamento ainda acontecem).
2. NATIVO: Digital Commerce APIs criam basket → cart → order sem tela (https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce.html; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-create-cart-from-basket.html); TMF622 Product Ordering inbound certificado no Communications Cloud (https://developer.salesforce.com/docs/industries/communications/guide/TMF622.html; v5: https://developer.salesforce.com/docs/industries/communications/guide/TMF622v5.html) — ambos validam SKU contra o EPC e precificam com o mesmo motor do vendedor.
3. DESVIO: Apex REST custom para criar Account→Opp→Quote→Order reimplementa o que o cart do pacote já faz (validação de catálogo, preço, atributos) e cria ordens que o OM não sabe decompor. Risco alto de manutenção e de divergência de preço. A diretriz 04/09 (Experience API no Mule, nada de Apex exposto) já aponta o caminho.
4. NOTA: Vermelho.
5. AJUSTE: redesenhar como "Mule (BFF do e-commerce) → Digital Commerce API ou TMF622 via IP", ordem nasce no status inicial do funil (não Ganha), idempotência por chave externa do pedido, aceite de SKU inválido devolvido pelo próprio pacote.

### W-000076 | B2C-19 — Emissão, notificação, comprovante e Mesa
1. ESCRITA: mistura cinco etapas (gerar cobrança, notificar, isenção, anexar comprovante, liberar) com três personas; sobrepõe B2C-12 (isenção/alçada), B2C-20 (gate por pagamento) e B2C-10 (notificações via MC). Gherkin ok para dois cenários, mas o modelo de estados da taxa não está em lugar nenhum.
2. NATIVO: Flow Approval Processes para "Análise de Comprovante" (https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5) com bloqueio nativo do registro durante a aprovação (https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concept_record_locking.htm&language=en_US&type=5); File Upload do OmniScript (https://help.salesforce.com/s/articleView?id=sf.os_upload_files_and_images_in_omniscripts.htm&language=en_US&type=5); Journey Builder para o aviso ao cliente; a geração da cobrança no BSS deveria ser um callout do plano de orquestração do OM (https://help.salesforce.com/s/articleView?id=ind.comms_t_creating_a_callout_orchestration_item_definition_235909.htm&language=en_US&type=5).
3. DESVIO: TMF678 não é API nativa inbound do Salesforce — é padrão-alvo do BSS; sem contrato de cobrança/baixa definido, tudo aqui é mock. Risco: três US gravando o mesmo campo InstallationFeeStatus__c com regras diferentes.
4. NOTA: Vermelho.
5. AJUSTE: reescrever como uma única "máquina de estados da taxa de ativação" (Isenta / Aguardando pagamento / Comprovante em análise / Paga / Expirada) com dono por transição, unificando B2C-12, B2C-19 e B2C-20, e mover notificações para a régua da B2C-10.

### W-000077 | B2C-20 — Controle de pagamento, bot e Closed Won
1. ESCRITA: três histórias (expiração por falta de pagamento; autoagendamento pelo bot; fechamento como Ganho). Regra 4 (Ganho quando a OS conclui) contradiz B2C-23 (Ganho após ativação no Customer Core). Cenário 1 diz que a Ordem "só pode ser gerada após pagamento" e no mesmo cenário cancela a Ordem. Regra 2 diz 5 dias úteis; risco pede 6 dias corridos.
2. NATIVO: Scheduled-Triggered Flow para expiração (https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_schedule.htm&type=5); Platform Event de baixa consumido por Flow; slots e reserva com AppointmentBookingService do Field Service (https://developer.salesforce.com/docs/atlas.en-us.field_service_dev.meta/field_service_dev/apex_class_FSL_AppointmentBookingService.htm); Ganho pelo callback do plano de orquestração do OM (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_orchestration_231022.htm&type=5).
3. DESVIO: bot externo (Zendesk/Meta) é inevitável; a inbound API do bot deve passar pelo Mule. Risco: sem webhook de baixa near-real-time o desenho cai (já registrado).
4. NOTA: Vermelho.
5. AJUSTE: reescrever em 3 US — (a) expiração por não pagamento (dentro da máquina de estados da B2C-19), (b) autoagendamento pelo bot via Mule → IP → FSL, (c) remover regra 4 e apontar para B2C-23; fechar "5 úteis vs 6 corridos" com o negócio.

### W-000078 | B2C-21 — List View "Acompanhamento Baixa Bancária"
1. ESCRITA: curta e suficiente; persona, filtro, compartilhamento e um aceite. Falta nomear o campo/valor (é StageName da Opportunity ou InstallationFeeStatus__c da Order?) e como "só da sua regional" é obtido.
2. NATIVO: List View compartilhada com Public Groups (https://help.salesforce.com/s/articleView?language=en_US&id=000387584&type=1); filtros por campo; Role Hierarchy limita naturalmente o que cada coordenador vê se OWD é Private.
3. DESVIO: nenhum. Observação: uma list view não filtra "minha regional" dinamicamente — ou se cria uma lista por regional compartilhada com o grupo daquela regional, ou se confia no OWD Private + hierarquia.
4. NOTA: Verde.
5. AJUSTE: escrever o filtro exato (objeto, campo, valor) e a opção escolhida (lista por regional ou visibilidade por hierarquia).

### W-000079 | B2C-22 — Relatório de instalações não realizadas e notificação
1. ESCRITA: objetivo claro; repete a cláusula "encerrar a oportunidade apenas após integração final" que é da B2C-23; "agendamento estourado" não está definido; um aceite só (notificação).
2. NATIVO: Reports/Dashboards em pasta com acesso por papel; Flow record-triggered em WorkOrder com Send Custom Notification para Owner e gerente (https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_sendcustomnotification.htm&language=en_US&type=5); Status Category "Cannot Complete" do Field Service como critério estável mesmo com status custom (https://help.salesforce.com/s/articleView?id=fs_status_categories.htm&language=en_US&type=5).
3. DESVIO: nenhum. Detalhe: "ManagerId (Role Hierarchy)" — o gerente vem de User.ManagerId, não da hierarquia de papéis; escolher um.
4. NOTA: Amarelo.
5. AJUSTE: retirar a cláusula de fechamento, definir "estourado" (ServiceAppointment.DueDate < hoje e status não concluído) e adicionar aceite do relatório.

### W-000080 | B2C-23 — Ativação final e fechamento como Ganho
1. ESCRITA: objetivo e regra corretos; o corpo original ("Integration Procedure / Trigger no fechamento da WorkOrder", "MACD Provide") foi superado pelas emendas 01/09 e 04/09 (callback do plano de orquestração), mas o texto não foi consolidado; um aceite só e sem cenário de fallout.
2. NATIVO: Industries Order Management — decomposição, plano de orquestração, callout e callback (https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_orchestration_231022.htm&type=5), com retry policy no item (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_associate_a_retry_policy_with_an_orchestration_item_definition_237041.htm&type=5); bloqueio pós-Ganho com Lock Record em Flow ou Validation Rule (https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_lockrecord.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?id=000385070&language=en_US&type=1).
3. DESVIO: um trigger/callout avulso na WorkOrder seria desvio — a emenda já corrige. Risco: dupla fonte de "Ganho" (B2C-20 regra 4) se não for retirada de lá.
4. NOTA: Amarelo.
5. AJUSTE: reescrever a especificação técnica com o fluxo OM (item de callout → callback de sucesso → Order Activated → Opportunity Closed Won → lock) e adicionar cenários de falha/retry e fallout.

### W-000081 | B2C-24 — Dados de faturamento e parametrização contratual
1. ESCRITA: regras de campo bem listadas; mas o item "Tempo de contrato" foi movido para o carrinho (03/09) e o texto ainda o descreve como campo da etapa; não diz em que objeto cada campo é gravado (Quote? Order? Contract? Billing Account?) nem como chega ao ERP.
2. NATIVO: step existente do OmniScript PF (BTecParPF_PaymentMethod); campos padrão de Order (BillingAddress) e Contract (ContractTerm, StartDate, EndDate calculado); prazo como atributo de preço no carrinho com pricing por atributo/time plan (https://help.salesforce.com/s/articleView?id=ind.comms_set_up_attribute_based_pricing_with_time_plan_and_time_policy.htm&language=en_US&type=5); CLM do pacote para o contrato (https://help.salesforce.com/s/articleView?language=en_US&id=ind.v_contracts_vlocity_contract_lifecycle_management_351212.htm&type=5).
3. DESVIO: risco de criar campos custom (Order.TempoContrato__c etc.) onde há campo padrão; e de duplicar o endereço de fatura em objeto custom (Endereco__c está descontinuado).
4. NOTA: Amarelo.
5. AJUSTE: reescrever com o prazo read-only herdado da linha, tabela campo → objeto/campo de destino (padrão sempre que existir) e aceite por campo (vencimento 5/10/15, cedente automático, endereço divergente).

### W-000082 | B2C-25 — Geração dinâmica da minuta
1. ESCRITA: objetivo claro; três emendas (04/09, AS-IS, 08/09) chegaram a um desenho final coerente, mas o corpo original ainda diz "exibe preview na tela" (síncrono) e a nota 04/09 diz "Mule executa a geração" (corrigido em 08/09). Sem aceite dos estados assíncronos.
2. NATIVO: OmniStudio Document Generation server-side, assíncrono, grava o documento na org vinculado ao registro (https://help.salesforce.com/s/articleView?id=ind.doc_gen_client_side_server_side_docgen_compared_392343.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5); templates de contrato do CLM (https://help.salesforce.com/s/articleView?id=ind.v_contracts_t_contract_document_templates_383432.htm&language=en_US&type=5); Platform Event com Publish After Commit (https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_publish.htm).
3. DESVIO: nenhum. Risco: idempotência do POST /create-contract (pendência registrada) e versão do DocGen (server-side exige setting e pacote compatível).
4. NOTA: Amarelo.
5. AJUSTE: substituir o corpo pela sequência 08/09 (gate na cotação → evento → DocGen → ContentVersion "Minuta" → Mule → plataforma) e escrever aceite para "em geração", "pronta", "falha/reprocessar".

### W-000083 | B2C-26 — Guarda de dados e LGPD
1. ESCRITA: objetivo e regra claros; o complemento de arquitetura já define o modelo; os critérios de aceite estão "na related list", não no texto — para quem lê a US isso é lacuna.
2. NATIVO: Consent Data Model — Individual, ContactPointTypeConsent, DataUsePurpose (https://help.salesforce.com/s/articleView?id=xcloud.consent_data_model_mc_about.htm&language=en_US&type=5; https://developer.salesforce.com/docs/platform/data-models/guide/privacy-consent.html; https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contactpointtypeconsent.htm); é a base que o Marketing Cloud consulta para consentimento por ponto de contato (https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.consent_management_marketing.htm&type=5); motivos de perda no Global Value Set da W-000096.
3. DESVIO: nenhum; a US proíbe explicitamente o checkbox custom isolado. Risco: retenção — "não deletar" precisa de prazo e base legal, senão vira passivo LGPD.
4. NOTA: Verde.
5. AJUSTE: trazer os aceites para o texto (perda exige motivo + consentimento Sim/Não; Sim cria ContactPointTypeConsent por canal; Não bloqueia jornada) e adicionar regra de retenção/anonimização.

## Padrões encontrados

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

## Referências

- Omni-Channel skills-based routing (suporta Lead): https://help.salesforce.com/s/articleView?id=service.omnichannel_attribute_based_routing.htm&language=en_US&type=5
- Omni-Channel Flows: https://help.salesforce.com/s/articleView?id=service.omnichannel_flows.htm&language=en_US&type=5
- Habilitar Omni-Channel e licenças: https://help.salesforce.com/s/articleView?language=en_US&id=service.omnichannel_enable.htm&type=5
- Omni-Channel no Sales Cloud (release note): https://help.salesforce.com/s/articleView?language=en_US&id=release-notes.rn_omnichannel_in_sales.htm&release=222&type=5
- Lead Assignment Rules: https://help.salesforce.com/s/articleView?id=service.creating_assignment_rules.htm&language=en_US&type=5
- Filas: https://help.salesforce.com/s/articleView?language=en_US&id=setting_up_queues.htm&type=0
- Duplicate Rules (visão geral): https://help.salesforce.com/s/articleView?language=en_US&id=sales.duplicate_rules_overview.htm&type=5
- Customizar Duplicate Rules: https://help.salesforce.com/s/articleView?language=en_US&id=sales.duplicate_rules_create.htm&type=5
- Dynamic Forms: https://help.salesforce.com/s/articleView?language=en_US&id=platform.dynamic_forms_overview.htm&type=5
- Custom Metadata Types: https://help.salesforce.com/s/articleView?id=platform.custommetadatatypes_about.htm&language=en_US&type=5
- Person Accounts (considerações): https://help.salesforce.com/s/articleView?id=sales.account_person_behavior.htm&language=en_US&type=5
- Premises (CMT): https://help.salesforce.com/s/articleView?id=ind.v_admin_premises_32879.htm&language=en_US&type=5
- Modelo de dados Communications: https://help.salesforce.com/s/articleView?id=ind.v_data_models_t_vlocity_communications_data_model_666929.htm&language=en_US&type=5
- TMF645 Service Qualification: https://developer.salesforce.com/docs/industries/communications/references/tmf645/v56.0
- TMF622 Product Ordering inbound (v4): https://developer.salesforce.com/docs/industries/communications/guide/TMF622.html
- TMF622 v5: https://developer.salesforce.com/docs/industries/communications/guide/TMF622v5.html
- Integration Procedure Action Properties (Non-Blocking/Chainable): https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_action_properties.htm&language=en_US&type=5
- Integration Procedure Best Practices: https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_best_practices.htm&language=en_US&type=5
- Settings para IPs longas: https://help.salesforce.com/s/articleView?id=sf.os_settings_for_long_running_integration_procedures_56206.htm&language=en_US&type=5
- Decision Matrices: https://help.salesforce.com/s/articleView?id=sf.decision_matrices.htm&language=en_US&type=5
- Business Rules Engine (início): https://help.salesforce.com/s/articleView?id=ind.get_started_with_business_rules_engine.htm&language=en_US&type=5
- Flow Approval Processes: https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5
- Submit for Approval (Flow): https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_approval.htm&language=en_US&type=5
- Record locking em Flow Approvals: https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concept_record_locking.htm&language=en_US&type=5
- Opportunity History Report (Stage Duration): https://help.salesforce.com/s/articleView?id=sf.reports_opp_history.htm&language=en_US&type=5
- OpportunityHistory (objeto): https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_opportunityhistory.htm
- Global Value Sets: https://help.salesforce.com/s/articleView?id=platform.fields_creating_global_picklists.htm&language=en_US&type=5
- Dependent Picklists: https://help.salesforce.com/s/articleView?language=en_US&id=fields_about_dependent_fields.htm&type=5
- Attribute-Based Pricing com Pricing Plans: https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing_using_pricing_plans.htm&language=en_US&type=5
- Cálculo do preço final no carrinho Industries CPQ: https://help.salesforce.com/s/articleView?id=ind.comms_final_price_calculation_in_the_industries_cpq_cart.htm&language=en_US&type=5
- Time Plan e Time Policy: https://help.salesforce.com/s/articleView?id=ind.comms_set_up_attribute_based_pricing_with_time_plan_and_time_policy.htm&language=en_US&type=5
- Schedule-Triggered Flows: https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_schedule.htm&type=5
- Field Service Status Categories: https://help.salesforce.com/s/articleView?id=fs_status_categories.htm&language=en_US&type=5
- AppointmentBookingService (FSL): https://developer.salesforce.com/docs/atlas.en-us.field_service_dev.meta/field_service_dev/apex_class_FSL_AppointmentBookingService.htm
- OmniStudio Document Generation (visão geral): https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5
- DocGen client-side vs server-side: https://help.salesforce.com/s/articleView?id=ind.doc_gen_client_side_server_side_docgen_compared_392343.htm&language=en_US&type=5
- Upload de arquivos em OmniScript: https://help.salesforce.com/s/articleView?id=sf.os_upload_files_and_images_in_omniscripts.htm&language=en_US&type=5
- Publicar Platform Events: https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_publish.htm
- Platform Events — publicação desacoplada: https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_considerations_decoupled_processes.htm
- Journey Builder API Event: https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_api_entry_source_use_case_1.htm&type=5
- Fire an Entry Event (MC API): https://developer.salesforce.com/docs/atlas.en-us.noversion.mc-apis.meta/mc-apis/how-to-fire-an-event.htm
- Salesforce Data Event (Journey Builder): https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_salesforce_data_event.htm&type=5
- Synchronized Data Sources best practices (MC Connect): https://help.salesforce.com/s/articleView?id=sf.mc_co_implement_synchronized_data_sources_best_practices.htm&language=en_US&type=5
- WhatsApp Template Message Approval: https://help.salesforce.com/s/articleView?id=mktg.mc_jb_whatsapp_template_message_approval_considerations.htm&language=en_US&type=5
- Promotions no catálogo (EPC): https://help.salesforce.com/s/articleView?id=ind.comms_promotions_in_the_product_catalog.htm&language=en_US&type=5
- Sequential Promotions and Discounts: https://help.salesforce.com/s/articleView?id=ind.comms_sequential_promotions_and_discounts.htm&language=en_US&type=5
- Rules for Industries CPQ: https://help.salesforce.com/s/articleView?id=ind.comms_rules_overview.htm&language=en_US&type=5
- Qualification Rules for Products: https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_products.htm&language=en_US&type=5
- Qualification Rules for Price List Entries: https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_price_list_entries_and_child_price_lists.htm&language=en_US&type=5
- Digital Commerce — considerações de uso (cache, availability/eligibility): https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-api-usage-considerations.html
- Context Eligibility Rules (DC): https://developer.salesforce.com/docs/industries/cme/guide/comms-t-defining-context-eligibility-rules.html
- Digital Commerce APIs: https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce.html
- Create Cart from Basket: https://developer.salesforce.com/docs/industries/cme/guide/comms-t-create-cart-from-basket.html
- Cart-Based APIs e Digital Commerce APIs: https://help.salesforce.com/s/articleView?id=ind.comms_cart_based_apis_for_ind_cpq.htm&language=en_US&type=5
- Permissões de importação (Import Leads): https://help.salesforce.com/s/articleView?id=sf.faq_import_general_permissions.htm&language=en_US&type=5
- Web-to-Lead: https://help.salesforce.com/s/articleView?language=en_US&id=sales.setting_up_web-to-lead.htm&type=5
- BarcodeScanner API (LWC mobile): https://developer.salesforce.com/docs/platform/lwc/guide/reference-lightning-barcodescanner.html
- lightning-barcode-scanner: https://developer.salesforce.com/docs/component-library/bundle/lightning-barcode-scanner
- Lead Field Mapping: https://help.salesforce.com/s/articleView?language=en_US&id=sales.customize_mapleads.htm&type=5
- Send Custom Notification (Flow): https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_sendcustomnotification.htm&language=en_US&type=5
- Compartilhar List View com Public Groups: https://help.salesforce.com/s/articleView?language=en_US&id=000387584&type=1
- Lock Record (Flow): https://help.salesforce.com/s/articleView?id=platform.flow_ref_elements_actions_lockrecord.htm&language=en_US&type=5
- VR para impedir edição de Closed Won/Lost: https://help.salesforce.com/s/articleView?id=000385070&language=en_US&type=1
- Industries Order Management: https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5
- Order Orchestration: https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_orchestration_231022.htm&type=5
- Callout Orchestration Item Definition: https://help.salesforce.com/s/articleView?id=ind.comms_t_creating_a_callout_orchestration_item_definition_235909.htm&language=en_US&type=5
- Retry Policy em Orchestration Item: https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_associate_a_retry_policy_with_an_orchestration_item_definition_237041.htm&type=5
- Order Decomposition Configuration: https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5
- Asset-Based Ordering: https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&language=en_US&type=5
- MACD: https://help.salesforce.com/s/articleView?id=ind.comms_move__add__change__delete__macd_.htm&language=en_US&type=5
- Vlocity Contract Lifecycle Management: https://help.salesforce.com/s/articleView?language=en_US&id=ind.v_contracts_vlocity_contract_lifecycle_management_351212.htm&type=5
- Contract Document Templates: https://help.salesforce.com/s/articleView?id=ind.v_contracts_t_contract_document_templates_383432.htm&language=en_US&type=5
- Consent Data Model (help): https://help.salesforce.com/s/articleView?id=xcloud.consent_data_model_mc_about.htm&language=en_US&type=5
- Privacy Consent data model (developer): https://developer.salesforce.com/docs/platform/data-models/guide/privacy-consent.html
- ContactPointTypeConsent (objeto): https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contactpointtypeconsent.htm
- Consent Management para Marketing Cloud Engagement: https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.consent_management_marketing.htm&type=5
