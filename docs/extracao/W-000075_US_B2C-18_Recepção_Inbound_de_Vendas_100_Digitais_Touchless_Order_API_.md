# W-000075 — US B2C-18 — Recepção Inbound de Vendas 100% Digitais (Touchless Order API)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 08/09/2026 17:57 por Diego Beltrão de Moraes

Referência: US-15 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-15: Recepção Inbound de Vendas 100% Digitais (Touchless Order API)
1. NARRATIVA DE NEGÓCIO
Como Sistema Integrador (Bot de IA / E-commerce)
Quero enviar um payload JSON padronizado com os dados completos de uma venda fechada digitalmente para o Salesforce
Para que o CRM consolide vendas touchless (sem intervenção de vendedores ou Backoffice) criando Conta, Oportunidade, Cotação e Ordem automaticamente.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Mapeado em 19/08. Com a implementação do bot inteligente de autoatendimento, o cliente B2C pode passar por todo o funil (Viabilidade, Crédito, Escolha de Plano) diretamente pelo WhatsApp/E-commerce.
Regras:
* O Salesforce atuará como receptor passivo (System of Record) dessas vendas digitais, não sendo responsável por guiar a jornada de tela que ocorre no bot.
* O endpoint deve aceitar uma requisição contendo: Dados do Cliente (Party), Endereço Técnico, Produtos Escolhidos, Forma de Pagamento e Status do Aceite Digital.
* Vendas que entram por essa API são marcadas como Record Type "Digital Sale" e o OwnerId deve ser atribuído a uma Fila Genérica (ex: "Fila Vendas E-commerce").
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Account, Contact, Opportunity, Quote, QuoteLineItem, Order.
Automação / Lógica: Apex REST Service (Custom Endpoint) ou MuleSoft orquestrando o roteamento nativo da TMF API. Criação atômica de registros (Account -> Opp -> Quote -> Order).
Integração / APIs: eTOM: Order Handling. Exposição do endpoint POST /services/apexrest/v1/ecommerce/order (ou adoção da TMF622 Product Ordering API caso o pacote Communications Cloud TM Forum Module esteja instalado).
Segurança e Acessos: Autenticação OAuth 2.0 JWT Bearer flow. Usuário de Integração (API Only User) com licença restrita.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Payload recebido com sucesso (Touchless Order)
Dado que o cliente finalizou o carrinho e o aceite no Bot do WhatsApp
Quando o Bot executa o POST na Inbound API do Salesforce
Então a classe Apex processa o JSON, cria todos os registros relacionais de Venda em status "Ganha" e retorna HTTP 201 Created com o ID da Ordem.
Cenário 2: Tratamento de Falhas e Rollback
Dado que o Bot envia um payload com um Produto que não existe no Pricebook ativo do Salesforce
Quando o processamento interno falha
Então a API executa um Database.rollback(), não cria registros parciais (contas órfãs) e retorna HTTP 400 Bad Request detalhando o erro do SKU não encontrado.
5. DEPENDÊNCIAS E RISCOS
Dependências: O dicionário de produtos (SKUs) no Bot de IA deve ser exatamente igual ao do Enterprise Product Catalog (EPC) do Salesforce.
Riscos/Premissas: [Governor Limits Check] Requisições em massa (picos de campanhas de Black Friday no E-commerce) podem estourar os limites de requisições concorrentes. É altamente recomendável que o payload seja recebido e alocado em um Custom Object de Staging ou Processamento Assíncrono (Queueable Apex).
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: Mock JSON contendo payload completo. Disparo via Postman para validar criação da hierarquia relacional e tempos de resposta < 1 segundo.

## Critérios de Aceite (related list)

**1. Cenário 2: Tratamento de Falhas e Rollback** (New)
Dado que o Bot envia um payload com um Produto que não existe no Pricebook ativo do Salesforce
Quando o processamento interno falha
Então a API executa um Database.rollback(), não cria registros parciais (contas órfãs) e retorna HTTP 400 Bad Request detalhando o erro do SKU não encontrado.

**2. Cenário 1: Payload recebido com sucesso (Touchless Order)** (New)
Dado que o cliente finalizou o carrinho e o aceite no Bot do WhatsApp
Quando o Bot executa o POST na Inbound API do Salesforce
Então a classe Apex processa o JSON, cria todos os registros relacionais de Venda em status "Ganha" e retorna HTTP 201 Created com o ID da Ordem.

## Notas de Refinamento e Decisões Registradas

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESPECIFICO: o endpoint touchless do e-commerce e uma Experience API no MuleSoft (BFF) que chama o Salesforce; nao expor Apex REST diretamente a internet. Idempotencia por chave externa do pedido.
