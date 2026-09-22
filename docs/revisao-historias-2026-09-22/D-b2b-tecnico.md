# Revisao tecnica - Grupo D: B2B (epicos 1 a 7) e works tecnicas (Arquitetura, Integracao/MuleSoft/CI-CD)

Arquivo avaliado: D_b2b_tecnico.md (24 historias). Criterio: BRIEF.md (escrita, capacidade nativa, desvio, nota, ajuste). Nenhuma org foi tocada.

## Tabela resumo

| Work | Assunto (curto) | Nota | Capacidade nativa principal | Ajuste em 1 linha |
|---|---|---|---|---|
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

Totais: Verde 14, Amarelo 7, Vermelho 3.

---

## W-000096 | B2B-01 - Inatividade de Leads, Econodata e grupo economico
1. ESCRITA: Persona e objetivo claros, Gherkin presente, massa de teste boa. Porem mistura 4 historias (regua de inatividade, enriquecimento Econodata, duplicidade/grupo economico, motivos de perda) e prescreve implementacao (Scheduled Apex/Batch, Database.QueryLocator) sem justificar volume. A nota de 10/09 sobre Lead Source e Marca esta correta, mas e outra historia.
2. NATIVO: regua de inatividade = schedule-triggered flow diario filtrando Lead por LastActivityDate (https://help.salesforce.com/s/articleView?id=platform.flow_considerations_trigger_schedule.htm&language=en_US&type=5). Duplicidade por CNPJ = Duplicate Rule + Matching Rule com campo custom (https://help.salesforce.com/s/articleView?id=sales.duplicate_rules_create.htm&language=en_US). Heranca Lead > Conta/Oportunidade = Map Lead Fields (https://help.salesforce.com/s/articleView?language=en_US&id=sales.customize_mapleads.htm&type=5). Matriz/filial = Account Hierarchy (https://help.salesforce.com/s/articleView?language=en_US&id=sales.account_hierarchy_setup_lex.htm&type=5). Motivo/submotivo = Global Value Set + dependencia de campo (padrao).
3. DESVIO: Batch Apex onde um flow agendado resolve (4.411 leads/ano nao justifica Apex). FlexCard de grupo economico e nativo. "Redirecionar a jornada para criar Oportunidade" no cenario 2 exige OmniScript, aceitavel. Sincronizacao Econodata via Mule (batch) esta correta.
4. NOTA: Amarelo.
5. AJUSTE: dividir em US-01a (regua), US-01b (enriquecimento/sync) e US-01c (duplicidade e grupo economico); substituir "Scheduled Apex/Batch" por "schedule-triggered flow, Apex so se volume > limite do flow"; usar Duplicate Rule no CNPJ como mecanismo do cenario 2.

## W-000097 | B2B-02 - Geocodificacao, viabilidade expressa e pre-projeto
1. ESCRITA: Boa: regras numeradas, limite de 20 sites, Gherkin. Erros: cenario 1 "avanca a Cotacao para o estagio Proposta Comercial" (estagio e da Opportunity; Quote tem Status); prescreve "LWC de Geocodificacao" sem dizer o resultado esperado (lat/long validada). As notas de 01/09 e 09/09 corrigem o modelo de site e o fluxo TMF645 e deveriam entrar no corpo.
2. NATIVO: modelo de site = vlocity_cmt__Premises__c + ServicePoint do data model CME (https://help.salesforce.com/s/articleView?id=ind.v_data_models_t_vlocity_communications_data_model_666929.htm&language=en_US&type=5). Viabilidade = TMF645 Service Qualification outbound (https://developer.salesforce.com/docs/industries/communications/references/tmf645) e endereco/site TMF673/TMF674 (https://developer.salesforce.com/docs/industries/communications/references/tmf674). Chamada = Integration Procedure HTTP Action, com passos assincronos (https://help.salesforce.com/s/articleView?id=sf.os_http_action_for_integration_procedures_53002.htm&language=en_US&type=5). Roteamento para fila de Arquitetura = Flow criando Task/queue ou Flow Approval Process com step em fila (https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5).
3. DESVIO: LWC proprio de geocodificacao (mapa/pin) e custom real: a plataforma nao geocodifica Premises nativamente sem Salesforce Maps. Risco medio de manutencao; alternativa e geocodificar no Mule (TMF673) e so exibir. Queueable para lote de sites e aceitavel se o SQM nao aceitar varios itens.
4. NOTA: Amarelo.
5. AJUSTE: corrigir o cenario 1 para "Opportunity Stage = Proposta Comercial e Quote Status = Pronta"; reescrever "LWC de geocodificacao" como resultado ("lat/long obrigatorias, obtidas pelo servico de endereco via Mule; marcacao manual so como excecao") e incorporar as notas de 01/09 e 09/09 ao corpo.

## W-000098 | B2B-03 - Cotacao multi-site, alcadas de desconto/trading e proposta DocGen
1. ESCRITA: Corpo + 4 notas (04/09, 04/09, 10/09, 10/09) que se corrigem entre si; hoje o texto pede Advanced Approvals (SteelBrick) e a nota diz para nao usar. Mistura 5 historias: cotacao multi-site, aprovacao de desconto, aceite formal/abandono, DocGen, alerta de Compras a 90% e validade de 30 dias. Cenario 1 junta desconto e temperatura no mesmo Quando.
2. NATIVO: cotacao multi-site = Multi-Site Quote and Order Capture (QuoteGroup/QuoteMember) (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_multi_site_quote_and_order_capture.htm&type=5). Aprovacao de desconto no carrinho = Approve Discounts in Industries CPQ (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_approve_discounts_in_industries_cpq.htm&type=5) ou Flow Approval Process com record lock (https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concept_record_locking.htm&language=en_US&type=5). Trading/degustacao = promotion com Time Plan/Time Policy (https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion). Proposta = OmniStudio Document Generation server-side (https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5). Validade = Quote.ExpirationDate + flow agendado.
3. DESVIO: (a) Advanced Approvals nao existe no stack; (b) DocGen disparado por Platform Event e compilado "pelo MuleSoft" e desvio: a geracao server-side ja e assincrona e nativa; o Mule so deveria receber o PDF pronto se precisar; (c) alerta de Compras por "temperatura 90%" e Flow simples, mas nao pertence a esta US. Risco: manter dois motores de aprovacao (cart discount approval e Approval Process) sem definir qual e o master.
4. NOTA: Vermelho.
5. AJUSTE: reescrever em 3 US (cotacao multi-site + validade; aprovacao de desconto/cortesia com um unico motor: Flow Approval Process; proposta DocGen server-side com aceite formal e abandono), incorporando as notas ao corpo e removendo Advanced Approvals e a compilacao no Mule.

## W-000101 | B2B-06 - Auditoria BKO, credito e handoff
1. ESCRITA: O corpo diz que o Customer Core decompoe e que o BKO tem "permissoes abertas"; as notas de 01/09 e 10/09 dizem que o OM decompoe e que o BKO e somente leitura. Um dev que le so o corpo constroi errado. Tela de conferencia prescrita como LWC. Gherkin bom; idempotencia bem lembrada.
2. NATIVO: decomposicao e orquestracao no Industries OM, com callbacks e assetizacao (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5; https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5). Handoff = TMF622 outbound via MuleSoft Direct (https://developer.salesforce.com/docs/industries/communications/guide/TMF622_outbound.html). Tela de revisao = FlexCard + OmniScript com FLS em QuoteLineItem/OrderItem. Trava de credito = Flow Approval Process (https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals_build.htm&type=5). Ordem submetida por Order Management Integration in Industries CPQ (https://help.salesforce.com/s/articleView?id=ind.comms_order_management_integration_in_industries_cpq.htm&language=en_US&type=5).
3. DESVIO: LWC de auditoria e botao custom onde FlexCard/OmniScript + submit padrao do OM resolvem; "converte itens em Assets" no cenario 1 e trabalho do OM, nao do botao. Passthrough (Callout Task unica) e aceitavel como transicao, mas precisa de licenca OM (W-000134).
4. NOTA: Vermelho.
5. AJUSTE: reescrever o corpo com o desenho vigente (OM decompoe; BKO somente leitura; Imputar Venda = submit ao OM com chave de idempotencia; campos fiscais por linha) e trocar "Review Screen LWC" por "FlexCard de conferencia + OmniScript de rejeicao com comentario".

## W-000107 | CPQ-BRE-01 - Motor de precificacao de projetos especiais
1. ESCRITA: Narrativa e RN-01 a RN-06 claras e verificaveis; entradas e saidas listadas. Faltam os criterios de aceite no texto (migrados para a related list) e o ponto de integracao com o carrinho e vago ("invocado por IP a partir do carrinho").
2. NATIVO: Business Rules Engine com Decision Matrices, Decision Tables e Expression Sets versionados, invocaveis por Flow e OmniStudio (https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/business_rules_engine.htm; https://help.salesforce.com/s/articleView?id=sf.decision_matrices.htm&language=en_US&type=5). Alcada = Flow Approval Process. Preco no carrinho = pricing variable/adjustment via pricing plan e calculation procedures do Industries CPQ (https://trailhead.salesforce.com/content/learn/modules/industries-advanced-pricing/get-started-with-industries-advanced-pricing).
3. DESVIO: o risco real e o resultado do BRE virar "override de preco" na linha, o que contraria RN-06 e as decisoes de permuta (sem override). Precisa entrar como pricing variable (ex.: preco de projeto) preenchida pelo pricing plan. Objeto de log e custom aceitavel (BRE nao persiste calculos). Licenca do BRE nao confirmada.
4. NOTA: Amarelo.
5. AJUSTE: adicionar RN-07 "o resultado grava a pricing variable X da linha via pricing plan step; nenhum override manual" e trazer os 4 AC de volta ao texto; confirmar licenca BRE com o AE antes da sprint.

## W-000119 | B2B-07 - Importacao de sites por planilha
1. ESCRITA: Boa: template de colunas, limite de 200, erro parcial, 3 cenarios mensuraveis. O texto trata "Multi-Site Quote and Order Capture" (CMT) e "Enterprise Sales Management" (ESM) como o mesmo recurso; sao produtos diferentes.
2. NATIVO: grupos e membros = Multi-Site Quote and Order Capture (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_a_multi_site_quote_or_order_in_industries_cpq.htm&type=5). Upload em massa de localidades = ESM Bulk Upload Location or Subscriber Details (https://help.salesforce.com/s/articleView?id=ind.comms_t_bulk_upload_location_or_subscriber_details_55846.htm&language=en_US&type=5), que exige licenca ESM. Viabilidade em lote = TMF645 via Mule (W-000097).
3. DESVIO: sem ESM, a importacao vira OmniScript + DataRaptor Load + fila assincrona, custom moderado e sustentavel. Risco: licenca ESM cara para um unico recurso; risco de duplicar Premises se reenviar planilha.
4. NOTA: Amarelo.
5. AJUSTE: separar no texto "Multi-Site (ja na org)" de "ESM (licenca a decidir)" e fechar a decisao antes da sprint; se OmniScript, incluir chave de idempotencia por linha (identificador do site + CNPJ).

## W-000120 | B2B-08 - Parceiros do lead a oportunidade
1. ESCRITA: Boa: RN-01 a RN-07, cenarios claros, limites explicitos (um parceiro por oportunidade; pagamento fora do SF).
2. NATIVO: Account com record type Parceiro; lookup no Lead mapeado na conversao (https://help.salesforce.com/s/articleView?language=en_US&id=sales.customize_mapleads.htm&type=5); comissao = Opportunity Splits com tipo custom (https://help.salesforce.com/s/articleView?id=sales.teamselling_opp_splits_create_custom_splits.htm&language=en_US&type=5); status via Validation Rule.
3. DESVIO: nenhum. Objeto filho de percentual por familia e custom justificado. Atencao: Splits exigem Team Selling e o split e sobre Amount, nao MRR; o relatorio precisa usar campo de MRR ganho.
4. NOTA: Verde.
5. AJUSTE: registrar que o split usa Amount e que o MRR vem de campo proprio; obter a regra de comissao antes do dev.

## W-000122 | B2B-09 - Signatario legal, procuracao e regua de assinatura
1. ESCRITA: Boa: RN-01 a RN-06, cenarios verificaveis, dependencias nomeadas.
2. NATIVO: Opportunity Contact Roles customizaveis com valores proprios (https://help.salesforce.com/s/articleView?id=sales.sales_core_opp_contact_setup.htm&language=en_US&type=5); Validation Rule/Flow de pre-geracao; arquivos em Files; regua = schedule-triggered flow; expiracao do envelope = DocuSignExpireAfter nos Vlocity CLM Custom Settings (https://help.salesforce.com/s/articleView?id=ind.v_contracts_vlocity_clm_custom_settings_368284.htm&language=en_US&type=5) e DocuSign do CLM (https://help.salesforce.com/s/articleView?id=ind.v_contracts_setting_up_docusign_integration_370804.htm&language=en_US&type=5).
3. DESVIO: nenhum relevante; campo de validade em ContentVersion e custom leve.
4. NOTA: Verde.
5. AJUSTE: apontar que a expiracao de 30 dias e configurada no CLM e apenas refletida pelo callback, para nao haver dois relogios (W-000145 RN-12).

## W-000123 | B2B-10 - Visao 360 do grupo economico
1. ESCRITA: Boa: fonte do grupo, colunas da visao, acoes por perfil, cenarios com numeros.
2. NATIVO: FlexCards com DataRaptor Extract e Integration Procedure para faturas; Account Hierarchy; acoes de MACD a partir do Asset (Asset-Based Ordering, https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&language=en_US&type=5); perfis por Permission Set.
3. DESVIO: nenhum; FlexCard 360 e o padrao. Risco de performance em grupos com centenas de ativos (a US ja preve paginacao).
4. NOTA: Verde.
5. AJUSTE: definir no AC o limite de ativos por carregamento e que "grupo por raiz de CNPJ" e campo formula na Account, indexado.

## W-000140 | Habilitar integracao B2B para testes
1. ESCRITA: Work tecnica com escopo enumerado, dependencias e evidencia exigida; adequada como enabler.
2. NATIVO: Named Credentials + External Credentials com principals em permission set (https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.nc_named_creds_and_ext_creds.htm&type=5); Integration Procedures por ambiente; sandbox com licencas atualizadas (https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.overview_licenses_and_sandbox.htm&type=5).
3. DESVIO: nenhum.
4. NOTA: Verde.
5. AJUSTE: acrescentar que o refresh de sandbox nao carrega os segredos das External Credentials (precisam ser reinseridos) e listar o endpoint x work num quadro.

## W-000141 | Escrever historias TEC-B2B (onboarding)
1. ESCRITA: E um plano de trabalho, nao uma historia; nao tem criterio de aceite verificavel alem de "works criadas".
2. NATIVO: n/a. A lista proposta de TEC-B2B (BRE, CLM, Scheduled Paths, integracoes, seguranca, 360) esta coerente com as fundacoes nativas citadas nas demais US.
3. DESVIO: nenhum.
4. NOTA: Amarelo.
5. AJUSTE: reclassificar como Task/Spike e definir Definition of Ready das TEC (fundamentacao no Help com URL, AC Dado/Quando/Entao, dependencia de licenca).

## W-000144 | B2B-15 - Condicoes de faturamento na cotacao
1. ESCRITA: Excelente: decisao de desenho explicita (frequencia e parametro contratual, nao pricing variable), RN-01 a RN-09, massa de teste.
2. NATIVO: campos custom em Quote/Order/Contract mapeados pelo Field Mapper do ABO (https://help.salesforce.com/s/articleView?id=ind.comms_mapping_fields_for_asset_based_ordering.htm&language=en_US&type=5); Approval Process com record lock (https://help.salesforce.com/s/articleView?id=sf.approvals_create_recordeditability.htm&language=en_US&type=5); Custom Metadata para de-para.
3. DESVIO: nenhum.
4. NOTA: Verde.
5. AJUSTE: manter; fechar chaves SAP com Rodrigo antes da sprint.

## W-000145 | B2B-16 - Cadencia de assinatura ao cliente
1. ESCRITA: Muito completa (12 RNs, limites, contingencia); talvez longa demais para uma sprint, mas verificavel.
2. NATIVO: Salesforce Data Event como entry source do Journey Builder (https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_salesforce_data_event.htm&type=5); contingencia por schedule-triggered flow com Send Email; lembretes DocuSign controlados pelos Vlocity CLM Custom Settings (https://help.salesforce.com/s/articleView?id=ind.v_contracts_vlocity_clm_custom_settings_368284.htm&language=en_US&type=5).
3. DESVIO: objeto custom Envio_para_Assinatura__c e justificado (Quote/Contract sem lookup de Contact). Nenhum outro.
4. NOTA: Verde.
5. AJUSTE: mover RN-10 (contingencia sem MC) para anexo ou US separada e confirmar que o canal de assinatura da W-000105 e o DocuSign do CLM.

## W-000124 | B2B-11 - Fim de degustacao (Try & Buy)
1. ESCRITA: Boa: RN-01 a RN-07 e 3 cenarios. Porem RN-03 e RN-05 assumem que "converter" exige um change order para remover o ajuste de 100%.
2. NATIVO: ajuste de 100% com Time Plan/Time Policy expira sozinho na data fim (https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion); regua = schedule-triggered flow; encerrar = ABO Delete (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5); refidelizacao = W-000142.
3. DESVIO: change order para "remover o ajuste" e redundante com o Time Plan e pode gerar ordem tecnica sem necessidade. Custom real: nenhum.
4. NOTA: Amarelo.
5. AJUSTE: reescrever RN-03: "conversao = deixar o Time Plan expirar e, se houver fidelidade, aditivo via W-000142; nenhum change order quando nao ha mudanca de servico".

## W-000100 | B2B-05 - Upgrade/Swap com notas de permuta e refidelizacao
1. ESCRITA: Corpo bom em Gherkin, mas com 3 notas longas (04/09, 10/09 a e b) que adicionam permuta, refidelizacao, travas e fiscal; hoje sao pelo menos 4 historias. Prescreve "LWC antes x depois".
2. NATIVO: ABO asset-to-quote com AssetReferenceId preservado (https://help.salesforce.com/s/articleView?id=ind.comms_move__add__change__delete__macd_.htm&language=en_US&type=5); Field Mapper; permuta como Discount order-based e contract-based (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5); alcada = Flow Approval; aditivo = CLM Amend Frame Agreement (https://help.salesforce.com/s/articleView?id=ind.v_contracts_to_amend_frame_agreements.htm&type=5&language=en_US).
3. DESVIO: LWC de comparacao onde o carrinho ABO ja mostra linhas com action code e preco; "espelhamento imutavel" e comportamento padrao do ABO. Duplo check da Arquitetura e Flow/Task, nao custom.
4. NOTA: Amarelo.
5. AJUSTE: dividir em Upgrade (Change), Swap/Permuta (Change + Discount com aprovacao) e Refidelizacao com upgrade (delegar prazo a W-000142); trocar "LWC antes x depois" por "carrinho ABO com action codes".

## W-000125 | B2B-12 - Downgrade contratual
1. ESCRITA: Boa: RN-01 a RN-09, alcadas por faixa, cenario com numeros.
2. NATIVO: ABO com action codes Change/Delete; multa = penalty rules dos context rules (https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/meet-context-rules) sobre pricing variable de penalidade (W-000109); aprovacao por faixa = Flow Approval Process; aditivo = CLM Amend.
3. DESVIO: nenhum; "nenhum calculo financeiro no Salesforce" esta coerente.
4. NOTA: Verde.
5. AJUSTE: manter; validar formula com Juridico e registrar que a multa e exibida, nao faturada, pelo Salesforce.

## W-000142 | B2B-13 - Refidelizacao simples
1. ESCRITA: Excelente: fundamentada no Help, RN-01 a RN-12, perfis por estado, limites do Repricing Batch.
2. NATIVO: Amend Frame Agreements (https://help.salesforce.com/s/articleView?id=ind.v_contracts_to_amend_frame_agreements.htm&type=5&language=en_US); Contract State Model e Vlocity Actions (https://help.salesforce.com/s/articleView?id=ind.v_contracts_contract_state_model_and_the_contract_workflow_376531.htm&language=en_US&type=5; https://help.salesforce.com/s/articleView?id=ind.v_contracts_defining_vlocity_actions_for_contracts_376811.htm&language=en_US&type=5); scheduled path (https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_scheduled_path.htm&type=5); repricing (https://trailhead.salesforce.com/content/learn/modules/industries-advanced-pricing/reprice-order-line-items-and-assets).
3. DESVIO: nenhum. Risco: Customer Core aceitar update de vigencia.
4. NOTA: Verde.
5. AJUSTE: provar em sandbox que o Amend gera aditivo so com datas/termo (sem clonar linhas) antes de fechar a estimativa.

## W-000099 | B2B-04 - Cancelamento, retencao e multa
1. ESCRITA: O corpo prescreve "Motor de Formula Apex" e "Price Book de Retencao"; as notas de 10/09 revogam os dois. Mistura evidencia formal, duas esteiras de retencao, multa, isencao e Billing Stop. Um dev que le o corpo implementa Apex.
2. NATIVO: desconexao = ABO Delete e ordem ao OM com callback (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5); multa = penalty rules/pricing variable (https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/meet-context-rules); retencao = Promotions e Discounts com Time Plan (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5); isencao = Flow Approval Process com lock; evidencia = Files.
3. DESVIO: Apex de multa e Price Book sao desvios ja rejeitados; "imutabilidade do arquivo" e custom leve (validation em ContentDocumentLink ou permissao). Billing Stop com fallout e do OM.
4. NOTA: Vermelho.
5. AJUSTE: reescrever o corpo com as decisoes de 10/09 e dividir: US-04a solicitacao + evidencia + multa exibida; US-04b esteiras de retencao (CAT-RET-01); US-04c efetivacao e Billing Stop (liga com W-000143).

## W-000143 | B2B-14 - Aviso previo e corte automatico
1. ESCRITA: Excelente: fundamentada, RN-01 a RN-11 com limites da plataforma, reversao e falha tratadas.
2. NATIVO: record-triggered flow com scheduled path por campo de data (https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_scheduled_path.htm&type=5); Convert Asset to Order com Delete; cancelamento in-flight e PONR (https://help.salesforce.com/s/articleView?id=ind.comms_t_overview_of_canceled_and_amended_in_flight_orders_in_order_management_233647.htm&language=en_US&type=5); painel = Dashboard e list views.
3. DESVIO: nenhum. Dependencia dura: licenca OM (W-000134).
4. NOTA: Verde.
5. AJUSTE: manter; no AC, incluir prova de que a reversao cancela o scheduled path (Time-Based Automations vazio).

## W-000136 | Arquitetura - Mapear fluxo e APIs do B2B
1. ESCRITA: Work de sessao com entregas concretas (diagramas, tabela de APIs, ADR, ata). Adequada.
2. NATIVO: catalogo TM Forum do Communications Cloud, inbound (TMF622, 629, 637, 648, 651) e MuleSoft Direct outbound (TMF645, 673, 674, 620) (https://developer.salesforce.com/docs/industries/communications/overview; https://developer.salesforce.com/docs/industries/communications/guide/Industry_integrations.html).
3. DESVIO: nenhum.
4. NOTA: Verde.
5. AJUSTE: usar a lista oficial de APIs TMF como coluna "padrao Salesforce" da tabela, marcando onde a Onda 1 fica no proprietario.

## W-000137 | Arquitetura - Decomposicao e camada tecnica do catalogo
1. ESCRITA: Boa: premissas, escopo por oferta, 4 cenarios de orquestracao. Falta criterio de aceite mensuravel.
2. NATIVO: Order Decomposition Configuration e Orchestration Plan Definition do Industries OM (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5; https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5).
3. DESVIO: nenhum; SAP na decomposicao (P-16) esta alinhado ao padrao.
4. NOTA: Verde.
5. AJUSTE: acrescentar AC "1 oferta de Conectividade decomposta e orquestrada em sandbox com Callout Task ao Mule mockado".

## W-000133 | Integracoes - CI/CD GitLab e sf CLI
1. ESCRITA: Boa: escopo, fora de escopo, branches, gates e riscos.
2. NATIVO: sf project deploy validate e quick deploy (https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_project_deploy_validate.html); JWT bearer flow para CI (https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_jwt_flow.htm); DevOps Center e a alternativa de UI (https://help.salesforce.com/s/articleView?id=platform.devops_center_overview.htm&language=en_US&type=5); OmniStudio no Package Runtime via OmniStudio Build Tool/DataPacks (https://developer.salesforce.com/blogs/2026/02/omnistudio-deployments-made-easier-whats-coming-on-the-salesforce-roadmap).
3. DESVIO: nenhum; GitLab CI com sf CLI e padrao aceito. Risco: metadata Industries (EPC, DataPacks) fora do pipeline por mais de uma sprint.
4. NOTA: Verde.
5. AJUSTE: em producao usar deploy validate + quick deploy do job validado; incluir plano de DataPacks pelo Build Tool a partir da sprint 2.

## W-000134 | Integracoes - Licenciamento OM e sandboxes
1. ESCRITA: Boa: evidencias, consequencia, entregas numeradas.
2. NATIVO: Usage-Based Entitlements e definicao de ordem para licenciamento do OM (https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5); Match Production Licenses / Push Updated Licenses to Sandbox (https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.overview_licenses_and_sandbox.htm&type=5).
3. DESVIO: nenhum.
4. NOTA: Verde.
5. AJUSTE: manter; registrar case e data prevista; pedir explicitamente a linha de ordens B2B na entitlement.

## W-000135 | Integracoes - MuleSoft: orcamento e inventario
1. ESCRITA: Boa: dois objetivos separados, inventario inicial com 9 demandas e work de origem.
2. NATIVO: MuleSoft Direct Integrations para Communications Cloud e Industry APIs inbound (https://developer.salesforce.com/docs/industries/communications/guide/Industry_integrations.html; https://developer.salesforce.com/docs/industries/communications/guide/Industry_API.html).
3. DESVIO: nenhum. Risco: cada squad construir API proprietaria onde ja existe TMF pronto no MuleSoft Direct (exige licenca add-on).
4. NOTA: Verde.
5. AJUSTE: adicionar coluna "existe no MuleSoft Direct?" ao inventario e confirmar a licenca do add-on antes de orcar construcao.

---

## Padroes encontrados
1. Corpo desatualizado com notas que o contradizem (W-000098, W-000099, W-000101, W-000100): as decisoes de 01/09, 04/09 e 10/09 vivem em apendices; o dev que le o corpo implementa o desenho antigo (Advanced Approvals, Apex de multa, Price Book, LWC). Consolidar o corpo antes da sprint.
2. Historias-guarda-chuva: as US originais do documento "Historias refinadas" juntam 3 a 5 historias (regua + enriquecimento + duplicidade; cotacao + alcada + DocGen + validade; cancelamento + retencao + multa + billing). As US novas (W-000119 a W-000145) ja nascem no tamanho certo; usar o mesmo padrao.
3. Prescricao de implementacao custom onde ha nativo: Scheduled/Batch Apex (flow agendado), LWC de tela (FlexCard/OmniScript), LWC "antes x depois" (carrinho ABO), motor Apex de multa (penalty rules), Advanced Approvals (Flow Approval Processes), DocGen via MuleSoft (server-side nativo).
4. Dois motores de aprovacao sem dono: Approve Discounts do carrinho CPQ x Approval Process/Flow Approval. Definir um unico padrao de projeto (proposta: Flow Approval Process com record lock) e citar nas US B2B-03, 05, 06, 12, 15 e 04.
5. Licenca como pre-condicao invisivel: OM (W-000134), ESM (W-000119), BRE (W-000107), MuleSoft Direct (W-000135). Marcar "Bloqueado por licenca" no Agile ate confirmacao.
6. Confusao de vocabulario Sales Cloud x CPQ: "estagio da Cotacao" (Quote tem Status; Stage e da Opportunity); "Assets convertidos pelo botao" (assetizacao e do OM).
7. Ponto forte: as US tecnicas (W-000133 a W-000137, W-000140) e as B2B novas (W-000142 a W-000145) citam o Help e os limites da plataforma; sao o modelo a seguir.

## Referencias
- https://help.salesforce.com/s/articleView?id=platform.flow_considerations_trigger_schedule.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=platform.flow_concepts_trigger_scheduled_path.htm&type=5
- https://help.salesforce.com/s/articleView?id=sales.duplicate_rules_create.htm&language=en_US
- https://help.salesforce.com/s/articleView?language=en_US&id=sales.customize_mapleads.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=sales.account_hierarchy_setup_lex.htm&type=5
- https://help.salesforce.com/s/articleView?id=sales.sales_core_opp_contact_setup.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sales.teamselling_opp_splits_create_custom_splits.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals_build.htm&type=5
- https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concept_record_locking.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sf.approvals_create_recordeditability.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_data_models_t_vlocity_communications_data_model_666929.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_multi_site_quote_and_order_capture.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_a_multi_site_quote_or_order_in_industries_cpq.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_bulk_upload_location_or_subscriber_details_55846.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_approve_discounts_in_industries_cpq.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/meet-context-rules
- https://trailhead.salesforce.com/content/learn/modules/industries-advanced-pricing/get-started-with-industries-advanced-pricing
- https://trailhead.salesforce.com/content/learn/modules/industries-advanced-pricing/reprice-order-line-items-and-assets
- https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_move__add__change__delete__macd_.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_mapping_fields_for_asset_based_ordering.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_order_management_integration_in_industries_cpq.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_overview_of_canceled_and_amended_in_flight_orders_in_order_management_233647.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_contracts_to_amend_frame_agreements.htm&type=5&language=en_US
- https://help.salesforce.com/s/articleView?id=ind.v_contracts_contract_state_model_and_the_contract_workflow_376531.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_contracts_defining_vlocity_actions_for_contracts_376811.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_contracts_vlocity_clm_custom_settings_368284.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_contracts_setting_up_docusign_integration_370804.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/business_rules_engine.htm
- https://help.salesforce.com/s/articleView?id=sf.decision_matrices.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sf.os_http_action_for_integration_procedures_53002.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.nc_named_creds_and_ext_creds.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.overview_licenses_and_sandbox.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_salesforce_data_event.htm&type=5
- https://developer.salesforce.com/docs/industries/communications/overview
- https://developer.salesforce.com/docs/industries/communications/guide/Industry_API.html
- https://developer.salesforce.com/docs/industries/communications/guide/Industry_integrations.html
- https://developer.salesforce.com/docs/industries/communications/guide/TMF622_outbound.html
- https://developer.salesforce.com/docs/industries/communications/references/tmf645
- https://developer.salesforce.com/docs/industries/communications/references/tmf674
- https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_project_deploy_validate.html
- https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth_jwt_flow.htm
- https://help.salesforce.com/s/articleView?id=platform.devops_center_overview.htm&language=en_US&type=5
- https://developer.salesforce.com/blogs/2026/02/omnistudio-deployments-made-easier-whats-coming-on-the-salesforce-roadmap
