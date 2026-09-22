# Revisao tecnica - Lote B: B2C - Jornadas de Venda e Gestao do Ciclo de Vida do Cliente (segunda metade, 25 historias)

Data da revisao: 22/09/2026. Fonte: B_b2c_2.md. Criterio: BRIEF.md (native first, Communications Cloud + Sales Cloud + Field Service).
Resultado: 25 historias avaliadas - 8 Verde, 17 Amarelo, 0 Vermelho.

## Tabela resumo

| Work | Assunto (curto) | Nota | Capacidade nativa principal | Ajuste em 1 linha |
|---|---|---|---|---|
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

---

## W-000084 | US TEC-B2C-01 - Botao "Criar Cotacao" na Oportunidade

1. ESCRITA: Boa. Persona, objetivo, regras de visibilidade, tres criterios Gherkin e tratamento de erro. As notas posteriores (motor nativo obrigatorio, reuso do BTecPar_PFCreateOrder, PriceZoneCode) complementam sem contradizer. Falta definir o que e "nova versao" da cotacao no CA 3 (o CPQ nao tem versionamento de Quote; existe clone) e faltam CAs para os erros listados no escopo.
2. NATIVO: Cart-Based APIs createCart/CpqAppHandler (https://developer.salesforce.com/docs/industries/cme/guide/comms-cart-based-apis-for-industries-cpq.html) e Guided Selling OmniScript sobre Cart APIs (https://help.salesforce.com/s/articleView?id=ind.comms_guided_selling_omniscript_using_cpq_apis.htm&language=en_US&type=5, https://help.salesforce.com/s/articleView?id=ind.comms_configure_omniscript_for_guided_selling.htm&language=en_US&type=5). Price List por contexto e resolucao por Context Rules (https://help.salesforce.com/s/articleView?id=ind.comms_price_lists_in_epc.htm&language=en_US&type=5). Quick Action + OmniScript e o padrao.
3. DESVIO: Nenhum relevante; a historia descarta explicitamente o POC btpCpq* (pricing paralelo) - correto. Risco: LWC "proprio" no botao e desnecessario; Quick Action que abre OmniScript basta.
4. NOTA: Verde.
5. AJUSTE: Trocar "nova versao" por "clonar a cotacao existente (acao nativa) e marcar a anterior como superada"; adicionar um CA por erro (conta inativa, sem price list, sem zona de preco, sem endereco qualificado).

## W-000085 | US TEC-B2C-02 - Modelagem EPC das ofertas B2C

1. ESCRITA: Rica em regras, mas e um pacote de tres historias (ofertas/SVAs/taxa; promotions com desconto na linha; preco por zona e prazo). Criterios de aceite em uma linha. Valor da taxa inconsistente (149,90 x 149,99). Dependencias claras.
2. NATIVO: Tudo existe: Product2 + atributos, Price List/Price List Entries com Context Rules para escolher a PLE (https://help.salesforce.com/s/articleView?id=ind.comms_price_lists_in_epc.htm&language=en_US&type=5, https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/create-context-rules-for-price-list-entries), attribute-based pricing por matriz (https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing.htm&language=en_US&type=5), Promotions com adjustment na linha (https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion, https://developer.salesforce.com/docs/industries/cme/guide/comms-post-cart-promotion-items.html), Pricing Rules (https://help.salesforce.com/s/articleView?id=ind.comms_pricing_rules.htm&language=en_US&type=5).
3. DESVIO: Nenhum. Risco tecnico: matriz velocidade x zona (40-50) x prazo (5) x segmento gera milhares de linhas; as restricoes de Context Rules com Digital Commerce (so == e !=, case-sensitive, cache) ja estao anotadas (https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-api-usage-considerations.html). Validar limite de combinacoes antes de gerar.
4. NOTA: Amarelo.
5. AJUSTE: Dividir em tres works com CA proprios (ex.: "dado endereco na zona B e prazo 24, entao a PLE X e aplicada"), confirmar o valor da taxa e registrar a decisao "combo com linha dedicada na matriz" como regra de cadastro.

## W-000086 | US TEC-B2C-03 - Esqueleto do OmniScript "Nova Venda B2C"

1. ESCRITA: Boa como enabler tecnico: ordem dos steps, padrao pai/filhos, limites de performance com fonte oficial. CA generico ("navegacao E2E com mocks"). O item de responsividade (3) afirma que o "elemento pub/sub do OmniScript" assina QuoteContractReady__e - o pub/sub do OmniStudio e mensageria entre componentes na pagina, nao assinatura de Platform Event.
2. NATIVO: OmniScript reutilizavel embutido, Integration Procedures (non-blocking/chainable), limite de elementos e boas praticas (https://help.salesforce.com/s/articleView?id=xcloud.os_omniscript_best_practices.htm&language=en_US&type=5); Guided Selling sobre Cart APIs (https://help.salesforce.com/s/articleView?id=ind.comms_guided_selling_omniscript_using_cpq_apis.htm&language=en_US&type=5; https://developer.salesforce.com/docs/industries/cme/guide/std_comms-add-items-to-cart.html; https://developer.salesforce.com/docs/industries/cme/guide/std_comms-checkout-items-in-cart.html). Retomada de venda: Save for Later/autosave do OmniScript.
3. DESVIO: Assinatura de Platform Event na tela exige LWC custom com empApi (lightning/empApi) ou polling por IP; pequeno e aceitavel, mas deve ser dito. "Embedding de OmniScript em LWC custom" e roadmap, nao escopo.
4. NOTA: Amarelo.
5. AJUSTE: Reescrever o item (3): "LWC custom com empApi dentro do step, assina ao entrar e desassina ao sair; fallback por polling via IP"; citar Save for Later para persistencia; CA por step (contrato de entrada/saida documentado e testado).

## W-000087 | US TEC-B2C-04 - Fundacao de integracoes

1. ESCRITA: Comecou bem (Named Credentials, IPs base, mapa TMF, usuario API-only) e virou repositorio de decisoes: endpoint proprietario x TMF, mapa real do Mule, pendencias com o time Mule, fronteira Zendesk e licencas ociosas. Mistura fundacao tecnica com decisao de negocio. CA genericos.
2. NATIVO: Named Credentials + External Credentials com OAuth 2.0 JWT Bearer/Client Credentials (https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.nc_named_creds_and_ext_creds.htm&type=5, https://help.salesforce.com/s/articleView?id=xcloud.nc_auth_protocols.htm&language=en_US&type=5, https://help.salesforce.com/s/articleView?id=sf.nc_create_edit_jwt_ext_cred.htm&language=en_US&type=5); Integration Procedures com HTTP Action (https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_invocation.htm&language=en_US&type=5). TMF nativos do Communications Cloud: outbound TMF645/TMF641 e inbound TMF622/629/637/648/651 (https://developer.salesforce.com/docs/industries/communications/overview).
3. DESVIO: Nenhum na fundacao. A decisao "TMF como adapter no Mule, Salesforce chama endpoint proprietario" e razoavel para a Onda 1, mas deixa de usar os conectores TMF645/TMF641 outbound nativos; registrar como decisao consciente com criterio de revisao.
4. NOTA: Amarelo.
5. AJUSTE: Mover a nota de 10/09 (Zendesk/licencas) para uma work de decisao propria; transformar o mapa em tabela endpoint x credencial x IP base x CA ("chamada de exemplo por credencial retorna 200 na sandbox X").

## W-000088 | US TEC-B2C-05 - Order Management: decomposicao e plano de orquestracao

1. ESCRITA: Boa base tecnica, decisao de arquitetura registrada (decomposicao unica no Salesforce OM), reuso comprovado do OrderController e Orchestration Items de producao. Seis notas anexadas; o CA original ("pedido E2E com mock") nao cobre o plano condicional de cortesia nem os campos fiscais por linha.
2. NATIVO: Decomposicao CP2TP (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5), Orchestration Plan Definitions e itens (https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5), Callout tasks (https://help.salesforce.com/s/articleView?id=ind.comms_t_creating_a_callout_orchestration_item_definition_235909.htm&language=en_US&type=5), fallout e operacao (https://help.salesforce.com/s/articleView?id=ind.comms_t_setupoperationsand_integration_238840.htm&language=en_US&type=5), checkout pelo Cart API (https://developer.salesforce.com/docs/industries/cme/guide/std_comms-checkout-items-in-cart.html). Campos extras por linha via fieldset CartAllowedFieldSet e nativo.
3. DESVIO: Nenhum. Risco de manutencao: ampliar o OrderController Apex existente em vez de configurar novos Orchestration Item Definitions; a diretriz "evolucao, nao greenfield" deve significar reuso do plano, nao mais Apex.
4. NOTA: Verde.
5. AJUSTE: Consolidar o texto e adicionar CAs: cortesia gera plano condicional com handoff valor zero; falha de ativacao vira Fatally Failed + fila; codigo SAP e descricao fiscal chegam na linha da ordem.

## W-000089 | US TEC-B2C-06 - Infraestrutura de Document Generation

1. ESCRITA: Clara no escopo (template, DataRaptor, PDF bloqueado, ContentVersion separada para o assinado). A decisao 04/09 introduz um desenho em que o Platform Event e consumido pelo MuleSoft para disparar a geracao - nao explica por que a geracao precisa sair do Salesforce.
2. NATIVO: OmniStudio Server-Side Document Generation ja e assincrono, roda no Hyperforce e anexa o documento ao registro (https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_server_side_document_generation_391775.htm&type=5; comparativo client x server: https://help.salesforce.com/s/articleView?id=ind.doc_gen_client_side_server_side_docgen_compared_392343.htm&language=en_US&type=5; visao geral: https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5). Disparo por Flow/IP na Quote, sem bloquear a tela, e o padrao.
3. DESVIO: Colocar o Mule no loop da geracao cria um salto externo para uma capacidade nativa assincrona e um ponto de falha a mais; o Mule so e necessario para a plataforma de assinatura. Limite documentado: ate 1.000 requisicoes server-side por hora por org - a afirmacao "1.034.000 geracoes/mes" precisa ser conferida contra esse teto.
4. NOTA: Amarelo.
5. AJUSTE: "Geracao via Server-Side DocGen disparada por IP/Flow na Quote (assincrona); ao concluir, publica QuoteContractRequested__e com o ContentVersionId para o Mule enviar a assinatura"; registrar o teto de 1.000/hora e o volume esperado por hora de pico.

## W-000090 | US TEC-B2C-07 - Seguranca e acessos da jornada B2C

1. ESCRITA: Objetiva: permission sets nomeados, FLS por regra de negocio, filas, OWD/hierarquia, papeis B2B incluidos. CA verificavel (matriz perfil x permissao com usuario de teste por perfil). O incidente da credencial versionada esta certo em prioridade, mas e outro assunto.
2. NATIVO: Permission Sets e Permission Set Groups, FLS, Queues, OWD e Role Hierarchy sao plataforma padrao; External Credentials para tirar segredos de metadata (https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.nc_named_creds_and_ext_creds.htm&type=5). Permission sets do pacote OM (CommsOMAdmin etc.) citados na W-000093.
3. DESVIO: Nenhum. Risco: dependencia do provisionamento via Senior/Okta (US-22) sem definir quem atribui os permission sets (SCIM/Okta x manual).
4. NOTA: Verde.
5. AJUSTE: Agrupar em Permission Set Groups por papel (Vendedor B2C, BKO, Mesa de Credito, GR, Arquiteto, Retencao) e abrir item de seguranca separado para rotacao da credencial e secret scanning (liga com W-000132).

## W-000091 | US TEC-B2C-08 - Roteamento Omni-Channel

1. ESCRITA: Narrativa e escopo bons e explicitamente native first; nao tem criterio de aceite nenhum e o de/para regiao x fila esta "a definir com o comercial".
2. NATIVO: Omni-Channel roteia Lead e objetos suportados (https://help.salesforce.com/s/articleView?language=en_US&id=service.service_presence_supported_objects.htm&type=5); objetos nao real-time roteados por Omni-Channel Flow (https://help.salesforce.com/s/articleView?id=service.omnichannel_flows.htm&language=en_US&type=5); Skills-Based Routing Rules e Skill Mapping Set (ate 10 campos, 100 valores) (https://help.salesforce.com/s/articleView?id=omnichannel_attribute_based_routing_mapping.htm&language=en_US&type=5, https://help.salesforce.com/s/articleView?language=en_US&id=omnichannel_attribute_based_routing_config.htm&type=5).
3. DESVIO: Nenhum. Risco de licenca: painel do supervisor e presence exigem licenca de Service/Omni para os usuarios de vendas - confirmar (liga com a nota de licencas em W-000087).
4. NOTA: Amarelo.
5. AJUSTE: Adicionar CAs ("dado lead com regiao Sul e canal Loja, quando roteado, entao cai na fila X para agente com skill Y em ate N s"; "agente sem capacidade nao recebe"; "supervisor ve fila regional") e anexar a tabela regiao x fila como pre-requisito.

## W-000092 | US TEC-B2C-09 - Fundacao Marketing Cloud

1. ESCRITA: Escopo bem listado (Connect, jornada base, WhatsApp, remetentes, janela, consentimento) e dependencias reais (licenca, Meta). Sem criterios de aceite. Bloqueio por licenca registrado corretamente.
2. NATIVO: Marketing Cloud Connect + Synchronized Data Sources (https://help.salesforce.com/s/articleView?id=sf.mc_co_synchronized_data_sources.htm&language=en_US&type=5); WhatsApp em Journey Builder com templates aprovados pela Meta (https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_whatsapp_get_started.htm&type=5, https://trailhead.salesforce.com/content/learn/modules/conversations-using-whatsapp-in-journey-builder/prepare-for-whatsapp); modelo de consentimento (https://help.salesforce.com/s/articleView?id=xcloud.consent_data_model_mc_about.htm&language=en_US&type=5, https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contactpointtypeconsent.htm).
3. DESVIO: Nenhum de codigo. Ponto cego: ContactPointTypeConsent nao vira audiencia sozinho - precisa ser sincronizado e usado como filtro de entrada/decision split; "fallback nativo flow + canal do bot" se a licenca atrasar e um segundo desenho que nao esta descrito.
4. NOTA: Amarelo.
5. AJUSTE: Escrever CAs (lead sem opt-in WhatsApp nao entra na jornada; envio fora de 08h-20h fica retido; exit ao mudar status) e descrever o fallback (Flow + Messaging) em uma linha ou retira-lo.

## W-000093 | US B2C-27 - Orquestracao de ativacao no Customer Core

1. ESCRITA: Formato completo (narrativa, eTOM, regras, Gherkin, DoD, massa). Problemas: cenarios e massa falam de Plano Controle, eSIM, ICCID/IMSI e Black Friday - portfolio movel que nao e o da BTP (fibra + SVA; movel via MVNO sem aparelho); tres notas de arquitetura sucessivas; "Apex Continuation para alta concorrencia" nao se aplica a Callout Tasks do OM.
2. NATIVO: Decomposicao e orquestracao do Industries OM (https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5, https://trailhead.salesforce.com/content/learn/modules/industries-order-management-orchestration-foundations/dive-into-industries-order-management-orchestration); TMF641 Service Ordering outbound nativo (https://developer.salesforce.com/docs/industries/communications/references/tmf641) e TMF637 inbound para inventario (https://developer.salesforce.com/docs/industries/communications/guide/TMF637use-cases.html); Asset e Subscription atualizados pelo OM na conclusao.
3. DESVIO: A Onda 1 usa a System Interface Apex existente (BTecparOMCustomSystemInterface) com endpoint proprietario em vez do conector TMF641 outbound - aceitavel por reuso, mas e Apex a manter. Service Tag gerada com retry em DUPLICATE_VALUE e custom pequeno e justificado.
4. NOTA: Amarelo.
5. AJUSTE: Reescrever cenarios e massa para "pedido de fibra 500M + Sky/streaming, Person Account ou Pessoa Fisica"; remover Continuation; unir as notas em uma secao "Decisoes vigentes" e nomear os dois TMF641 como a nota de 09/09 sugere.

## W-000094 | US B2C-28 - Work Order de instalacao (OM + Field Service)

1. ESCRITA: Formato completo, Gherkin, decisao de modelo de endereco registrada (Premises/ServicePoint + Location/Address), escopo de produtos fechado. Ruidos: alternativas TOA/ClickSoftware/TMF652/TMF646 continuam no texto apesar da nota "usar SFS nativo"; Regra 1 exige ServiceAppointment "validado no checkout" sem dizer qual US faz o agendamento; a entrada TMF641 de parceiros ja migrou para W-000131.
2. NATIVO: Field Service nativo (WorkOrder/ServiceAppointment: https://help.salesforce.com/s/articleView?id=service.fs_create_wo.htm&language=en_US&type=5) criado por Auto Task/IP do plano de orquestracao (https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5); Premises do pacote (https://help.salesforce.com/s/articleView?id=ind.v_admin_premises_32879.htm&language=en_US&type=5). Reuso comprovado de FlowOrderScheduleInstallation e BTecparFSLAvailabilityController.
3. DESVIO: Nenhum se ficar no SFS. Risco: migracao de Endereco__c e um projeto de dados proprio (EnderecoHandler, DataRaptors) escondido dentro desta US.
4. NOTA: Amarelo.
5. AJUSTE: Cortar as alternativas externas e os TMF646/652; referenciar a US de agendamento no checkout; abrir work propria para a migracao Endereco__c -> Premises; CA para a criacao automatica de Location/Address 1:1 com o Premises.

## W-000095 | US B2C-29 - Visao 360 no console

1. ESCRITA: Formato completo, cenario de resiliencia (timeout com estado amigavel) bem pensado. Regra 3 (Next Best Action por propensao) e uma historia inteira sem dono nem dado; Regra 2 pede mascara com "revelacao mediante auditoria" sem dizer o mecanismo; a fronteira com o Zendesk (360 em dois sistemas) esta aberta.
2. NATIVO: FlexCards com data sources IP/DataRaptor e cache configuravel (https://help.salesforce.com/s/articleView?id=xcloud.os_omnistudio_flexcards_24388.htm&language=en_US, https://help.salesforce.com/s/articleView?id=xcloud.os_flexcards_data_source_properties.htm&language=en_US&type=5); Interaction/Service Console para Communications usa FlexCards; TMF629/637/678 como mapa de capacidade, endpoints proprietarios na Onda 1 (W-000087).
3. DESVIO: NBA por propensao exige Einstein/Next Best Action ou modelo externo - fora do native first sem licenca definida. Mascara de CPF por perfil e FLS/formula; "revelar com auditoria" e custom (LWC + log) ou Shield Platform Encryption com mascara. Sem callout sincrono na carga: correto.
4. NOTA: Amarelo.
5. AJUSTE: Retirar a Regra 3 para uma US futura com licenca definida; trocar a Regra 2 por "CPF mascarado por formula, campo completo visivel so por permission set, sem revelacao dinamica na Onda 1"; condicionar a construcao a decisao Zendesk.

## W-000105 | US TEC-INT-01 - Canal de eventos de contrato

1. ESCRITA: Muito bem especificada: payload, idempotencia, Publish After Commit, assinatura no Mule, semantica at-least-once, limites e monitoramento, retorno do PDF assinado com hash, cenarios A-D. Depende de decisoes de outras works (W-000089, W-000106).
2. NATIVO: Platform Events com Publish After Commit e limites de entrega/publicacao (https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm, https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_publish.htm); MuleSoft Salesforce Pub/Sub Connector e Replay ID (https://docs.mulesoft.com/salesforce-pubsub-connector/latest/salesforce-pubsub-connector-studio, https://docs.mulesoft.com/salesforce-connector/latest/salesforce-connector-processing-events); ContentVersion/ContentDocumentLink e Files padrao. Orchestration Items SignatureSent/Signed existentes como consumidor.
3. DESVIO: Recalculo de SHA-256 no Salesforce (Crypto.generateDigest em trigger de ContentVersion) e o botao "Validar na plataforma" sao customs pequenos e justificados. Unico ponto: se a geracao ficar nativa (W-000089), o evento de saida muda de "gerar" para "enviar para assinatura".
4. NOTA: Verde.
5. AJUSTE: Alinhar com a W-000089: QuoteContractRequested__e passa a significar "minuta pronta, enviar para assinatura" (ja carrega o ContentVersionId); manter todo o resto.

## W-000106 | US B2C-33 - Templates juridicos unificados

1. ESCRITA: Regras claras (RN-01 a RN-07), variaveis obrigatorias, riscos reais (juridico, contratos estaduais). CAs migrados para a related list - o texto fica sem os 4 criterios para quem le a work.
2. NATIVO: Document Templates do OmniStudio DocGen com versoes e ativacao (https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5); templates e clausulas do Industries CLM (https://help.salesforce.com/s/articleView?id=ind.v_contracts_t_contract_lifecycle_management_templates_383328.htm&language=en_US&type=5); a cotacao gravando template + versao usada e campo simples.
3. DESVIO: "Controle de versao e vigencia em objeto proprio" duplica o versionamento nativo do template; a aprovacao juridica (RN-07) pode ser Flow Approval no proprio template em vez de objeto novo.
4. NOTA: Amarelo.
5. AJUSTE: Trocar "objeto proprio" por "versao e ativacao nativas do Document Template + campos TemplateId/Versao na Quote"; trazer os 4 CAs para o corpo (ex.: "dado template v2 ativo, contrato gerado antes em v1 nao muda").

## W-000109 | US B2C-31 - Multa pro rata de fidelidade

1. ESCRITA: Regras de negocio boas (base, pro rata, teto 12 meses, isencoes, transparencia, imutabilidade). Especificacao tecnica ainda diz "formula em Apex ou Flow" enquanto a nota de 10/09 decide penalidade nativa - texto contraditorio. Regra de arredondamento pendente.
2. NATIVO: Penalty Rules for Contracts do Industries CPQ definem a taxa de cancelamento de contrato/promocao (https://help.salesforce.com/s/articleView?id=ind.comms_penalty_rules_for_contracts.htm&language=en_US&type=5); pricing variables, Calculation Procedures e Time Plans/Policies (https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/create-time-plans-and-time-policies); cancelamento pelo ABO (https://developer.salesforce.com/docs/industries/cme/guide/comms-submit-a-cancel-order-request.html).
3. DESVIO: A versao Apex seria custom onde existe nativo. Risco de dado: fidelidade no Asset depende da migracao (CAT-MIG-01) - sem data de inicio confiavel a penalidade nativa calcula errado tanto quanto o Apex.
4. NOTA: Amarelo.
5. AJUSTE: Reescrever a especificacao: "pricing variable de penalidade + penalty rule por prazo de fidelidade e beneficio, exibida no carrinho de cancelamento; isencoes por Context Rule/motivo"; fechar arredondamento e escrever os CAs no texto.

## W-000110 | US TEC-INT-02 - Fornecedores de SVA e IDs de plano

1. ESCRITA: Boa: separacao comercial x tecnica, mapeamento versionado, ativacao pelo plano (nunca da tela), falha tolerada, limite de licencas. CAs na related list.
2. NATIVO: Atributos tecnicos nao exibidos nas Product Specs do EPC; Custom Metadata para mapeamento; Callout Orchestration Items com fallout (https://help.salesforce.com/s/articleView?id=ind.comms_t_creating_a_callout_orchestration_item_definition_235909.htm&language=en_US&type=5); cardinalidade/validacao de atributo no carrinho para o limite de licencas.
3. DESVIO: Nenhum. Risco: fornecedores sem homologacao e IDs mudando sem aviso - o mapeamento com vigencia mitiga.
4. NOTA: Verde.
5. AJUSTE: Trazer um CA por fornecedor (Disney, PlayHub, MVNO) e um de baixa no cancelamento; explicitar que o limite de licencas e regra de atributo (min/max) no carrinho.

## W-000115 | US B2C-30 - Tipos de operacao sem faturamento

1. ESCRITA: Regras completas e a nota de 10/09 traz a mecanica nativa certa. Contradicao: o escopo original fala em Record Type/picklist na Opportunity/Order (junto com TEC-B2C-01, que preve Record Types Normal/Cortesia/Swap) e a nota fala em atributo "Tipo de Negociacao" no carrinho - dois mecanismos para a mesma coisa. Pede "Approval Process" classico.
2. NATIVO: Adjustment de 100% com Time Plan/Time Policy iniciando na ativacao (https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/create-time-plans-and-time-policies); account-based discount com aprovacao (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5, https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_approve_discounts_in_industries_cpq.htm&type=5); elegibilidade por Context Rule (https://help.salesforce.com/s/articleView?id=ind.comms_types_of_context_rules.htm&language=en_US&type=5); Flow Approval Processes (https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5).
3. DESVIO: Nenhum de codigo; o risco e desenho duplo (Record Type + atributo) e aprovacao no modelo antigo.
4. NOTA: Amarelo.
5. AJUSTE: Decidir: "Tipo de Negociacao e atributo do carrinho gravado na linha e espelhado em campo do Order; Record Type da Opportunity nao carrega essa semantica" (ajustar W-000084); aprovacao via Flow Approval Process bloqueando DocGen ate Aprovado.

## W-000116 | US B2C-32 - Mudanca de plano B2C sem visita tecnica

1. ESCRITA: Boa: origem no ativo, quando ha ou nao tecnico, identidade preservada, preco por zona, elegibilidade por tecnologia. Dependencia critica da base de ativos migrada (hoje 1 Asset em producao).
2. NATIVO: Asset-Based Ordering/MACD do Industries CPQ (https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5, https://help.salesforce.com/s/articleView?id=ind.comms_move__add__change__delete__macd_.htm&language=en_US&type=5, https://trailhead.salesforce.com/content/learn/modules/industries-cpq-asset-management/manage-customer-assets-with-change-orders); plano de orquestracao com itens condicionais para "com/sem Work Order"; UseAssetReferenceIdForParentAndRoot so importa se houver Digital Commerce (https://developer.salesforce.com/docs/industries/cme/guide/std_comms-remove-items-from-cart.html).
3. DESVIO: Nenhum. Risco: RN-01 ("nao se cria venda nova para cliente ativo no mesmo endereco") precisa de bloqueio no Create Cart (W-000084) - nao esta la.
4. NOTA: Verde.
5. AJUSTE: Ligar RN-05 (refidelizacao com aceite) ao aditivo W-000126; adicionar em W-000084 a verificacao "cliente com Asset ativo no Premises -> abrir ABO, nao venda nova".

## W-000117 | US CAT-ACC-01 - Modelo de contas do cliente

1. ESCRITA: Pesquisa excelente (dados reais da org, auditoria das contas "Billing", Person Accounts nao habilitados), mas o texto tem tres camadas que se substituem (RN originais, ajustes de 08/09, correcao apos auditoria). Quem le nao sabe qual RN vale. Decisao de Person Accounts em aberto bloqueia B2C.
2. NATIVO: O pacote Communications entrega Business, Consumer, Billing e Service Account como record types e o modelo Party/Premises/ServicePoint (https://help.salesforce.com/s/articleView?id=ind.v_data_models_t_vlocity_communications_data_model_666929.htm&language=en_US&type=5, https://architect.salesforce.com/diagrams/data-models/communications-cloud/business-customer); campos Default de Billing/Service/ServicePoint na Quote/Order e linhas; Person Accounts irreversiveis (https://help.salesforce.com/s/articleView?id=sf.account_person_enable.htm&language=en_US&type=5, https://help.salesforce.com/s/articleView?id=sales.account_person_behavior.htm&language=en_US&type=5).
3. DESVIO: Lookup custom "Conta cliente" em vez de ParentId e desvio justificado pela incompatibilidade com Person Account; verificar antes se os record types do pacote ja existem na org (nao criar "Service Account" duplicado). Recomendacao de manter "Pessoa Fisica" como Consumer na Onda 1 e pragmatica.
4. NOTA: Amarelo.
5. AJUSTE: Reescrever como versao unica "RN vigentes" (apagando as substituidas), com a decisao Person Accounts como pre-condicao explicita e os 5 CAs + Cenario E no corpo; separar o saneamento da base (1.938 contas, usuarios duplicados) em work de dados.

## W-000118 | US TEC-OM-01 - Checkout e submissao do pedido ao OM

1. ESCRITA: Boa: um Order por Quote, gatilhos por canal, validacoes bloqueantes, idempotencia, fallout, 3 cenarios. Problema: RN-06 inventa oito estados proprios do Order sobre um objeto que ja tem status nativos do CPQ e do OM.
2. NATIVO: Checkout do Cart API cria o Order (https://developer.salesforce.com/docs/industries/cme/guide/std_comms-checkout-items-in-cart.html); Submit Order e integracao CPQ -> OM com status proprios (https://help.salesforce.com/s/articleView?id=ind.comms_order_management_integration_in_industries_cpq.htm&language=en_US&type=5, https://help.salesforce.com/s/articleView?id=ind.comms_submit_order_request_for_order_management_integration_layer.htm&language=en_US&type=5, https://trailhead.salesforce.com/content/learn/modules/industries-cpq-orders/submit-and-monitor-orders); Flow Record-Triggered para o gatilho; Field History nativo.
3. DESVIO: Maquina de estados propria no Order duplica os status do OM e vai exigir sincronizacao custom; "validacao em Decision Matrix ou Apex" - preferir Integration Procedure de pre-submissao.
4. NOTA: Amarelo.
5. AJUSTE: Substituir RN-06 por tabela de/para com os status nativos do Order (Draft/Activated etc.) e do OM (In Progress, Completed, Fatally Failed), criando no maximo um campo "Condicao de submissao" para Aguardando Condicoes/Pronto.

## W-000126 | US TEC-CLM-01 - Aditivo contratual por MACD

1. ESCRITA: Boa: gatilho, versao, template, assinatura, bloqueio do OM ate assinar, estados, frame agreement B2B, 3 cenarios. Diagnostico honesto (CLM na org sem template, clausula ou estados).
2. NATIVO: Industries CLM - Contract Types com estados e aprovacoes, versoes automaticas ao alterar, templates e clausulas (https://trailhead.salesforce.com/content/learn/modules/deep-dive-into-industries-contract-lifecycle-management/meet-contract-types-and-lifecycle-states, https://trailhead.salesforce.com/content/learn/modules/deep-dive-into-industries-contract-lifecycle-management/work-with-contracts, https://help.salesforce.com/s/articleView?id=ind.v_contracts_t_contract_lifecycle_management_templates_383328.htm&language=en_US&type=5); integracao CLM x CPQ com contract-based discounts e frame agreements (https://trailhead.salesforce.com/content/learn/modules/deep-dive-into-industries-contract-lifecycle-management/explore-clm-and-cpq-integration, https://help.salesforce.com/s/articleView?id=ind.comms_t_create_a_contract_based_discount_203552.htm&language=en_US&type=5).
3. DESVIO: Nenhum. Risco: RN-06 define estados proprios - devem ser os estados configurados no Contract Type, nao campo novo; volume B2C de aditivos (cada upgrade com refidelizacao) precisa caber no fluxo de assinatura.
4. NOTA: Verde.
5. AJUSTE: Escrever RN-06 como "estados do Contract Type do CLM: ..." e adicionar CA para contrato legado (primeiro aditivo referencia o PDF importado).

## W-000129 | US B2C-34 - Cancelamento B2C com retencao

1. ESCRITA: Regras claras (motivo obrigatorio, multa, oferta por nivel, desconexao, compulsorio, protocolo, indicadores), 3 cenarios. Risco declarado: onde roda a retencao ainda nao decidido. Pede "Approval Process por nivel".
2. NATIVO: Disconnect/cancel pelo ABO (https://help.salesforce.com/s/articleView?id=ind.comms_move__add__change__delete__macd_.htm&language=en_US&type=5, https://developer.salesforce.com/docs/industries/cme/guide/comms-submit-a-cancel-order-request.html); promocoes elegiveis por Context Rule (https://help.salesforce.com/s/articleView?id=ind.comms_types_of_context_rules.htm&language=en_US&type=5); penalidade nativa (W-000109); Case e Flow Approval Processes (https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concepts.htm&language=en_US&type=5).
3. DESVIO: Nenhum de codigo. Se a retencao ficar no Zendesk, toda a US vira integracao (ofertas e multa expostas por API) - desenho diferente.
4. NOTA: Amarelo.
5. AJUSTE: Tornar a decisao "retencao no Salesforce" pre-condicao formal; trocar Approval Process por Flow Approval por nivel; adicionar CA de protocolo/data registrados mesmo quando retido.

## W-000130 | US TEC-INT-03 - Sincronizacao SAP -> Salesforce do equipamento

1. ESCRITA: Boa: um Asset filho por unidade, eventos, sentido unico, conciliacao, historico, 3 cenarios. Contradicao interna com W-000093 ("TMF638 sob demanda, nunca em massa") x RN-04 "conciliacao diaria" de ~1 milhao. Volume da carga sem metodo.
2. NATIVO: Asset hierarchy com Parent/Root Asset ate 20 niveis (https://help.salesforce.com/s/articleView?id=service.assets_rel_hierarchical.htm&language=en_US&type=5, https://help.salesforce.com/s/articleView?id=service.fs_manage_assets_in_field_service.htm&language=en_US&type=5); upsert por External Id via REST/Bulk API 2.0; Platform Event inbound ou Integration Procedure exposta por REST (https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/omnistudio_apis.htm).
3. DESVIO: Nenhum de objeto. Risco de limites: conciliacao diaria completa consome API e TMF638 por item; melhor conciliar por evento (troca concluida) e amostragem, com job completo mensal.
4. NOTA: Amarelo.
5. AJUSTE: RN-04 -> "conciliacao por evento de instalacao/troca + lote semanal amostral; consulta TMF638 sob demanda"; especificar Bulk API 2.0 para a carga inicial e campos External Id (ID SAP) unicos.

## W-000131 | US TEC-INT-04 - API inbound TMF641 no Field Service

1. ESCRITA: Boa: criacao, idempotencia, mapeamento minimo, estados, autorizacao por parceiro, 3 cenarios. Escopo de Onda indefinido e parceiros nao identificados - risco declarado.
2. NATIVO: A REST API padrao (WorkOrder, WorkOrderLineItem, ServiceAppointment) chamada pelo Mule com usuario de integracao e Named Credential no Mule e nativa e sem codigo; Platform Event para notificar status; Field Service para o despacho (https://help.salesforce.com/s/articleView?id=service.fs_create_wo.htm&language=en_US&type=5). TMF641 inbound nao faz parte das Industry APIs inbound nativas (TMF622/629/637/648/651: https://developer.salesforce.com/docs/industries/communications/guide/get_started_industry_API.html) - o adapter TMF fica no Mule, coerente com a decisao de 04/09.
3. DESVIO: Nenhum se o Mule fizer a traducao TMF -> REST padrao. Se a validacao funcional (sem enums) ficar no Salesforce, sera Flow/validation rule ou Integration Procedure exposta - pequeno.
4. NOTA: Amarelo.
5. AJUSTE: Decidir Onda com Bismarck; registrar "sem TMF641 inbound nativo; Mule traduz para REST padrao e IP de validacao"; CA de autorizacao por parceiro (nao ve ordem de outro).

## W-000132 | US TEC-DEV-01 - Esteira CI/CD

1. ESCRITA: Boa: repositorio, baseline, ramos por sandbox, validacao por MR, deploy so por pipeline, drift, datapacks versionados, 3 cenarios verificaveis. Ja em sprint.
2. NATIVO: sf CLI em source format para sandboxes/producao; OmniStudio/Vlocity Build Tool para datapacks (https://help.salesforce.com/s/articleView?id=xcloud.os_deploy_or_migrate.htm&language=en_US&type=5); DevOps Center como alternativa de UI de release (https://help.salesforce.com/s/articleView?id=platform.devops_center_setup.htm&language=en_US); External Credentials para tirar segredos do metadata.
3. DESVIO: Nenhum; GitLab CI e ferramenta externa esperada. Atencao: DevOps Center nao instala em sandbox; datapacks EPC grandes (matrizes de preco) podem estourar tempo de deploy - prever export seletivo.
4. NOTA: Verde.
5. AJUSTE: Incluir secret scanning como stage obrigatorio (liga com W-000090) e definir estrategia de datapacks EPC (por catalogo/versao) para nao bloquear o pipeline.

---

## Padroes encontrados

1. Works viram diario de decisoes: W-000085, 087, 088, 093, 094, 117 tem 3 a 6 notas datadas que se substituem; ninguem sabe qual RN vale. Consolidar em "versao vigente" e mover historico para o comentario.
2. Criterios de aceite fora do texto ou ausentes: W-000091 e 092 nao tem CA; W-000105, 106, 109, 110, 115, 116, 117 dizem "migrados para a related list". A work precisa ser legivel sozinha.
3. Maquinas de estado e versionamentos proprios onde o produto ja tem: status de Order (W-000118), estados de contrato (W-000126), versao de template (W-000106). Mapear para o nativo.
4. Approval Process classico citado em W-000115 e 129: usar Flow Approval Processes.
5. Fronteira Zendesk x Salesforce (360, contrato, retencao) aparece em W-000087, 095, 105, 129 e nao esta decidida - bloqueia tres historias.
6. Dados legados como pre-condicao invisivel: Person Accounts (W-000117), 1 Asset em producao (W-000116, 109, 130), Endereco__c (W-000094). Abrir works de dados/migracao explicitas.
7. Texto de referencia generico (eSIM, ICCID, Black Friday, TOA/ClickSoftware) sobrevivendo em W-000093/094 - limpar para o portfolio real.
8. Um desvio de desenho relevante: geracao de documento via Mule (W-000089) quando o Server-Side DocGen ja e assincrono; e um custom pequeno mal declarado (assinatura de Platform Event no OmniScript, W-000086).
9. Positivo: o grupo e majoritariamente native first (Cart APIs, EPC, OM, ABO, CLM, Field Service, Platform Events) e reusa o que esta em producao com evidencia.

## Referencias

- https://developer.salesforce.com/docs/industries/cme/guide/comms-cart-based-apis-for-industries-cpq.html
- https://developer.salesforce.com/docs/industries/cme/guide/std_comms-add-items-to-cart.html
- https://developer.salesforce.com/docs/industries/cme/guide/std_comms-checkout-items-in-cart.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-post-cart-promotion-items.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-submit-a-cancel-order-request.html
- https://developer.salesforce.com/docs/industries/cme/guide/std_comms-remove-items-from-cart.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-api-usage-considerations.html
- https://help.salesforce.com/s/articleView?id=ind.comms_guided_selling_omniscript_using_cpq_apis.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_configure_omniscript_for_guided_selling.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=xcloud.os_omniscript_best_practices.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sf.os_integration_procedure_invocation.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/omnistudio_apis.htm
- https://help.salesforce.com/s/articleView?id=xcloud.os_omnistudio_flexcards_24388.htm&language=en_US
- https://help.salesforce.com/s/articleView?id=xcloud.os_flexcards_data_source_properties.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=xcloud.os_deploy_or_migrate.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_price_lists_in_epc.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_pricing_rules.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_types_of_context_rules.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/create-context-rules-for-price-list-entries
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion
- https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/create-time-plans-and-time-policies
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_approve_discounts_in_industries_cpq.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_create_a_contract_based_discount_203552.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_penalty_rules_for_contracts.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_move__add__change__delete__macd_.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-asset-management/manage-customer-assets-with-change-orders
- https://help.salesforce.com/s/articleView?id=ind.order_mgmt_industries_order_management.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_creating_a_callout_orchestration_item_definition_235909.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_setupoperationsand_integration_238840.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_order_management_integration_in_industries_cpq.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_submit_order_request_for_order_management_integration_layer.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-orders/submit-and-monitor-orders
- https://trailhead.salesforce.com/content/learn/modules/industries-order-management-orchestration-foundations/dive-into-industries-order-management-orchestration
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_server_side_document_generation_391775.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.doc_gen_client_side_server_side_docgen_compared_392343.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_contracts_t_contract_lifecycle_management_templates_383328.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/deep-dive-into-industries-contract-lifecycle-management/meet-contract-types-and-lifecycle-states
- https://trailhead.salesforce.com/content/learn/modules/deep-dive-into-industries-contract-lifecycle-management/work-with-contracts
- https://trailhead.salesforce.com/content/learn/modules/deep-dive-into-industries-contract-lifecycle-management/explore-clm-and-cpq-integration
- https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_event_limits.htm
- https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_publish.htm
- https://docs.mulesoft.com/salesforce-pubsub-connector/latest/salesforce-pubsub-connector-studio
- https://docs.mulesoft.com/salesforce-connector/latest/salesforce-connector-processing-events
- https://help.salesforce.com/s/articleView?language=en_US&id=xcloud.nc_named_creds_and_ext_creds.htm&type=5
- https://help.salesforce.com/s/articleView?id=xcloud.nc_auth_protocols.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sf.nc_create_edit_jwt_ext_cred.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=service.service_presence_supported_objects.htm&type=5
- https://help.salesforce.com/s/articleView?id=service.omnichannel_flows.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=omnichannel_attribute_based_routing_mapping.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=omnichannel_attribute_based_routing_config.htm&type=5
- https://help.salesforce.com/s/articleView?id=sf.mc_co_synchronized_data_sources.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=sf.mc_jb_whatsapp_get_started.htm&type=5
- https://trailhead.salesforce.com/content/learn/modules/conversations-using-whatsapp-in-journey-builder/prepare-for-whatsapp
- https://help.salesforce.com/s/articleView?id=xcloud.consent_data_model_mc_about.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contactpointtypeconsent.htm
- https://help.salesforce.com/s/articleView?id=sf.account_person_enable.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sales.account_person_behavior.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_data_models_t_vlocity_communications_data_model_666929.htm&language=en_US&type=5
- https://architect.salesforce.com/diagrams/data-models/communications-cloud/business-customer
- https://help.salesforce.com/s/articleView?id=ind.v_admin_premises_32879.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=service.fs_create_wo.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=service.fs_manage_assets_in_field_service.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=service.assets_rel_hierarchical.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/industries/communications/overview
- https://developer.salesforce.com/docs/industries/communications/guide/get_started_industry_API.html
- https://developer.salesforce.com/docs/industries/communications/guide/TMF637use-cases.html
- https://developer.salesforce.com/docs/industries/communications/references/tmf641
- https://help.salesforce.com/s/articleView?language=en_US&id=platform.automate_automated_approvals.htm&type=5
- https://help.salesforce.com/s/articleView?id=platform.automate_automated_approvals_concepts.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=platform.devops_center_setup.htm&language=en_US
