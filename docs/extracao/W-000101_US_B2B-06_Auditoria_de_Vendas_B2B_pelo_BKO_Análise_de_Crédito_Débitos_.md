# W-000101 — US B2B-06 — Auditoria de Vendas B2B pelo BKO, Análise de Crédito/Débitos e Handoff com Customer Core/ERP

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 15:08 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[BACKOFFICE & EOM]" do documento "Histórias refinadas B2B".

NARRATIVA DE NEGÓCIO
Como Analista de Backoffice (BKO) / Sistema Order Management (EOM)
Quero auditar os documentos contratuais, realizar a verificação de crédito/débitos internos e executar o handoff de imputação da venda para o Customer Core/ERP
Para que os dados cadastrais, fiscais e contratuais sejam validados com risco zero de erro antes da decomposição do pedido e ativação na rede.
CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2B)
Contexto: Etapa final de conferência comercial/técnica/documental pelo time de Backoffice (período de auditoria mantido por 6 meses), verificação de adimplência e envio do payload de integração ao orquestrador BSS/OSS.
Mapeamento eTOM: 1.2.1.4 Order Handling, 1.2.1.3 Customer Credit Profile Management.
Regras de Negócio:
[Regra 1: Auditoria BKO por 6 Meses e Perfil Aberto para Correção] O Backoffice atuará como validador final de todas as vendas B2B durante o período inicial de 6 meses. O perfil do BKO terá permissões abertas no Salesforce para realizar correções de cadastro/atributos antes de acionar o botão "Imputar Venda".
[Regra 2: Verificação de Crédito e Débitos Internos] O sistema executará a verificação de débitos internos (Customer Core) e risco financeiro externo (Serasa). Havendo qualquer pendência financeira ou restrição de crédito na conta/Grupo Econômico, o pedido será travado e exigirá aprovação mandatória do Gestor Imediato para prosseguir.
[Regra 3: Handoff de Pedido e Decomposição via Customer Core] Após o clique em "Imputar Venda", o Salesforce envia a ordem (TMF622) ao Customer Core, que realiza a decomposição e provisionamento no ERP/SAP, retornando o ID do Pedido/Contrato para tornar a Oportunidade imutável (Closed Won).
ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2B)
Objetos Impactados: Opportunity, Quote, Order, OrderItem, Contract, Business Account.
Automação / Front-end: Tela de Conferência BKO (Review Screen LWC), Botão de Ação "Imputar Venda", Flow Orchestrator para tratamento de exceções de crédito.
Integração / APIs TM Forum: TMF622 (Product Order), TMF637 (Product Inventory), API REST Serasa / Consultation Service do Customer Core.
Segurança e Acessos: Apenas perfis de BKO e Administradores possuem o botão "Imputar Venda"; imutabilidade total do registro (Read-Only) após confirmação do handoff.
CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Auditoria aprovada pelo BKO e imputação de venda com sucesso
Dado que uma cotação corporativa possui proposta assinada anexada e viabilidade homologada
Quando o Analista de BKO revisa os dados na Tela de Conferência e clica em "Imputar Venda"
Então o sistema consome a API TMF622 enviando a ordem ao Customer Core, recebe o ID de confirmação do ERP, converte os itens em Ativos (Assets) e atualiza a Oportunidade para "Closed Won".
Cenário 2: Trava por débito interno e exigência de aprovação gerencial Dado que o BKO aciona a validação de crédito e o Customer Core retorna registro de débito em aberto no CNPJ Quando o BKO tenta prosseguir com a imputação Então o sistema bloqueia a ação, altera o status do pedido para "Pendente - Aprovação de Crédito" e gera uma tarefa de aprovação compulsória para o Gestor Imediato do vendedor.
ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 13 Story Points (Desenvolvimento da tela de auditoria BKO, integrações duplas TMF622/Crédito e conversão de Assets).
Dependências: Prontidão dos endpoints de ordenação e débito no Customer Core / Barramento MuleSoft.
Governor Limits & Edge Cases: Garantia de idempotência nas chamadas de API do botão "Imputar Venda" para evitar duplicação de ordens no ERP em caso de múltiplos cliques.
DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Cobertura de testes unitários mínima de 85% (sem violação de limites de Apex CPU/SOQL).
[ ] Validação E2E no ambiente de Sandbox/QA.
Massa de Teste Sugerida: Pedido B2B completo com minuta contratual DocuSign aprovada; Business Account com histórico de débito interno no Customer Core; Pedido com erro de payload cadastral para validação de tratamento de exceções do BKO.

Nota de arquitetura BTP: handoff via TMF622 com garantia de idempotência (chave externa do pedido) para evitar duplicação no ERP; Closed Won somente após ID de confirmação do Customer Core, mesmo padrão da B2C-27.

## Critérios de Aceite (related list)

**1. Cenário 2: Trava por débito interno e exigência de aprovação gerencial** (New)
Dado que o BKO aciona a validação de crédito e o Customer Core retorna registro de débito em aberto no CNPJ
Quando o BKO tenta prosseguir com a imputação
Então o sistema bloqueia a ação, altera o status do pedido para "Pendente - Aprovação de Crédito" e gera uma tarefa de aprovação compulsória para o Gestor Imediato do vendedor.

**2. Cenário 1: Auditoria aprovada pelo BKO e imputação de venda com sucesso** (New)
Dado que uma cotação corporativa possui proposta assinada anexada e viabilidade homologada
Quando o Analista de BKO revisa os dados na Tela de Conferência e clica em "Imputar Venda"
Então o sistema consome a API TMF622 enviando a ordem ao Customer Core, recebe o ID de confirmação do ERP, converte os itens em Ativos (Assets) e atualiza a Oportunidade para "Closed Won".

## Notas de Refinamento e Decisões Registradas

--- DECISÃO DE ARQUITETURA 01/09/2026 (substitui a pendência acima) ---
Decomposição ÚNICA no Salesforce Industries OM para B2C e B2B, dirigida pelo Shared Catalog/EPC (produto comercial e técnico no mesmo catálogo). Customer Core e ERP atuam como executores: provisionamento de rede e billing, recebendo ordens técnicas via barramento e devolvendo callbacks. No B2B, o botão Imputar Venda permanece como gate do BKO e passa a SUBMETER a ordem ao OM (com idempotência). Transição: enquanto o catálogo técnico B2B não estiver modelado no EPC, o plano de orquestração B2B roda em modo passthrough (Callout Task única de handoff + callback), evoluindo para decomposição plena. Fundamento: função documentada do OM e do Shared Catalog; prática eTOM de ponto único de decomposição guiado por catálogo.

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESCOPO: Onda 1 = B2C venda nova (Avare), ata 03/09; esta work B2B segue em refinamento e entra na onda B2B, a calendarizar.

--- CAMPOS FISCAIS NO HANDOFF (decisao 04/09) ---
O Imputar Venda deve carregar, por LINHA da ordem, codigo de material SAP + descricao fiscal (parametrizados na criacao da ordem, W-000088). Sao os contratos B2B estaduais/federais que exigem descricoes e tipos de nota distintos para o mesmo servico; sem esses campos o handoff ao ERP falha. A Tela de Conferencia do BKO exibe e valida os dois campos antes de liberar o botao.

## Comentários

- Diego Beltrão de Moraes 01/09/2026 15:44: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
- Diego Beltrão de Moraes 01/09/2026 15:47: Epic__c changed from Catálogo Comercial Unificado - B2B/B2C to B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente
