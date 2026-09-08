# W-000093 — US B2C-27 — Orquestração de Ativação e Provisionamento do Pedido B2C no Customer Core

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 10:26 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[ORDER MANAGEMENT]" de 01/09/2026 do documento Histórias Refinadas B2C.

[ORDER MANAGEMENT] - Orquestração de Ativação e Provisionamento de Pedido B2C no Customer Core
1. NARRATIVA DE NEGÓCIO
Como Sistema de Orquestração (Salesforce Comms Cloud OM) / Atendente de Loja ou Call Center
Quero Decompor e enviar os dados do pedido B2C aprovado para o Customer Core (BSS/OSS/Billing) para provisionamento técnico e início de faturamento
Para que O cliente B2C tenha seus serviços (Linha Móvel/eSIM/Banda Larga) ativados automaticamente sem intervenção manual, reduzindo o AHT e garantindo a correta contabilização do faturamento.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2C)
Contexto: Após a conclusão do checkout B2C (com pagamento ou análise de crédito aprovados), o pedido deve avançar no ciclo de vida de Order Fulfillment. O Salesforce OM realiza a decomposição de Produtos Comerciais para Produtos Técnicos (CP2TP) e dispara os comandos de ativação de rede (OSS) e cadastro de bilhetagem/faturamento (Billing).
Mapeamento eTOM: 1.2.1.4 Service Order Handling, 1.2.1.5 Service Configuration & Activation, 1.2.1.7 Customer Billing Management.
Regras de Negócio:
Regra 1 (Gatilho de Transição): Apenas pedidos no status Submitted com pagamento/crédito validado entram no fluxo de decomposição e ativação.
Regra 2 (Sincronização de Status): O status do produto/instância (vlocity_cmt__Subscription__c e Asset) só deve mudar para Active após confirmação síncrona/assíncrona de sucesso do OSS via callback.
Regra 3 (Tratamento de Fallout B2C): Qualquer exceção técnica de rede/billing não deve cancelar o pedido imediatamente; deve gerar uma tarefa de Fallout Management para reprocessamento.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2C)
Objetos Impactados: Order, OrderItem, vlocity_cmt__OrchestrationPlan__c, vlocity_cmt__OrchestrationItem__c, vlocity_cmt__Subscription__c, Asset, PersonAccount.
Automação / Front-end: Rules engine de Decomposição do Salesforce Industry OM (CP2TP), Orchestration Items (Callout Task e Auto Task), Integration Procedures (IPs) e Apex Continuation (para alta concorrência).
Integração / APIs TM Forum:
TMF641 (Service Ordering API): Envio da ordem de serviço para ativadores de rede/OSS.
TMF622 (Customer Order Management): Notificação de mudança de estado do pedido para sistemas periféricos.
TMF637 (Product Inventory API): Atualização do inventário e criação de Assets/Subscriptions no Salesforce.
Segurança e Acessos: Permission Set CommsOMAdmin / CommsSystemIntegration, Named Credentials com mTLS/OAuth2 para chamadas ao Barramento/MuleSoft, FLS restrito para dados de identificação técnica de rede (ICCID, IMSI).
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Ativação E2E do Pedido B2C com Sucesso (Caminho Feliz)
Dado que um pedido B2C de plano Controle com eSIM foi finalizado pelo e-Commerce e possui o status "Submitted"
Quando o Salesforce OM executa o plano de orquestração e consome o endpoint TMF641 de ativação no Customer Core
Então o sistema legado retorna confirmação de provisionamento (200 OK / Status "Completed"), o Salesforce altera o status da Order para "Completed", atualiza o status do Asset e da vlocity_cmt__Subscription__c para "Active" e agenda o ciclo de faturamento no BSS.
Cenário 2: Tratamento de Falha no Provisionamento de Rede (Fallout/Exceção)
Dado que o fluxo de ativação enviou a requisição de provisionamento para o Customer Core/OSS
Quando o OSS responder com erro de rede (ex: 500 Internal Error ou Timeout de comunicação)
Então o item da orquestração (vlocity_cmt__OrchestrationItem__c) deve mudar para o status "Fatally Failed", gerando uma fila de Fallout Task no Salesforce OM para análise do suporte N2, mantendo a Order em "In Fulfillment" sem ativar o Asset.
5. ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 13 Story Points (Fibonacci) — Devido à complexidade de modelagem de catálogo técnico (EPC), regras de decomposição OM e integração de callbacks assíncronos.
Dependências: Middleware/Barramento de Integração (MuleSoft/Apigee), BSS Core Engine (Billing) e Plataforma OSS de Provisionamento Móvel/Banda Larga.
Governor Limits & Edge Cases: Utilizar arquitetura assíncrona desacoplada via Callout Tasks do OM para evitar estouro do limite de tempo de resposta da transação Apex (120s Timeout limit). Tratar picos de volumetria B2C (ex: Black Friday) utilizando loteamento (bulkification) nas notificações de callback.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Decomposição de produto comercial para produto técnico validada no Catalog/OM.
[ ] Regras de Orquestração e Callout Tasks implementadas e testadas.
[ ] Cobertura de testes unitários dos seletores/APIs mínima de 85%.
[ ] Validação do fluxo completo de ativação e atualização de inventário (Asset) em ambiente Sandbox/QA via Mocks.
Massa de Teste Sugerida: Person Account com CPF ativo e válido, sem pendências financeiras, associada a uma Order no status "Submitted" contendo uma oferta B2C (Plano Controle B2C + eSIM com ICCID associado).

Nota de arquitetura: o módulo TM Forum do Communications Cloud fornece TMF622 e TMF637; o TMF641 citado é API externa exposta pelo barramento/OSS e consumida pelo Salesforce como cliente. Fundação técnica: TEC-B2C-05.

## Critérios de Aceite (related list)

**1. Cenário 2: Tratamento de Falha no Provisionamento de Rede (Fallout/Exceção)** (New)
Dado que o fluxo de ativação enviou a requisição de provisionamento para o Customer Core/OSS
Quando o OSS responder com erro de rede (ex: 500 Internal Error ou Timeout de comunicação)
Então o item da orquestração (vlocity_cmt__OrchestrationItem__c) deve mudar para o status "Fatally Failed", gerando uma fila de Fallout Task no Salesforce OM para análise do suporte N2, mantendo a Order em "In Fulfillment" sem ativar o Asset.

**2. Cenário 1: Ativação E2E do Pedido B2C com Sucesso (Caminho Feliz)** (New)
Dado que um pedido B2C de plano Controle com eSIM foi finalizado pelo e-Commerce e possui o status "Submitted"
Quando o Salesforce OM executa o plano de orquestração e consome o endpoint TMF641 de ativação no Customer Core
Então o sistema legado retorna confirmação de provisionamento (200 OK / Status "Completed"), o Salesforce altera o status da Order para "Completed", atualiza o status do Asset e da vlocity_cmt__Subscription__c para "Active" e agenda o ciclo de faturamento no BSS.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO COM B2B (decisão pendente) ---
Conflito de arquitetura entre os documentos: esta US define que o Salesforce OM decompõe o pedido (CP2TP) e dispara a ativação (TMF641 no OSS), enquanto a US B2B-06 define handoff via Imputar Venda com decomposição no Customer Core/ERP. Decidir e registrar: um padrão único de decomposição ou padrões distintos por jornada (B2C orquestrado no Salesforce OM; B2B mestre no Customer Core). Envolver time de integração e fornecedor.

--- DECISÃO DE ARQUITETURA 01/09/2026 (substitui a pendência acima) ---
Decomposição ÚNICA no Salesforce Industries OM para B2C e B2B, dirigida pelo Shared Catalog/EPC (produto comercial e técnico no mesmo catálogo). Customer Core e ERP atuam como executores: provisionamento de rede e billing, recebendo ordens técnicas via barramento e devolvendo callbacks. No B2B, o botão Imputar Venda permanece como gate do BKO e passa a SUBMETER a ordem ao OM (com idempotência). Transição: enquanto o catálogo técnico B2B não estiver modelado no EPC, o plano de orquestração B2B roda em modo passthrough (Callout Task única de handoff + callback), evoluindo para decomposição plena. Fundamento: função documentada do OM e do Shared Catalog; prática eTOM de ponto único de decomposição guiado por catálogo.

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso parcial (matriz #16; analise TMF640/641).
REUSAR: sincronizacao com o Customer Core existente - BTecPar_CreateContract (contrato) e BTecparOMCustomSystemInterface (ordens tecnicas; inclui endpoint protocol-closure com action/serviceTag).
EVIDENCIA: force-app/main/default/classes/BTecparOMCustomSystemInterface.cls | vlocity-backup/System/Mulesoft/Mulesoft_SystemInterfaces.json.
ATENCAO da consultoria: a sincronizacao generica pode representar operacoes DIFERENTES por evento - documentar contrato por evento, sistema mestre e reconciliacao (pendencia da matriz).
DIRETRIZ SYSMAP: a decisao de decomposicao unica no Salesforce OM (ja registrada) parte de capacidade comprovada; evoluir a System Interface existente em vez de criar nova.

--- SERVICE TAG E IDENTIDADE DO ATIVO (04/09) ---
Na aceitacao do pedido (Submitted com pagamento/credito validado) gerar a ServiceTag por item de servico e por equipamento conforme US CAT-TAG-01 (W-000104): 16 caracteres Base32 Crockford, prefixo SV/EQ, unicidade garantida por External ID unico + retry em DUPLICATE_VALUE. Gravada no OrderItem e propagada a Subscription/Asset na criacao do inventario; e a chave de negocio enviada ao Customer Core/OSS e imutavel apos a ativacao. O AssetReferenceId do pacote NUNCA e alterado (rastreio pai-filho e MACD dependem dele).
