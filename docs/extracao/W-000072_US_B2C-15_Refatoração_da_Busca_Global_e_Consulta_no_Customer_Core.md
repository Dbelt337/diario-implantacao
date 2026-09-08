# W-000072 — US B2C-15 — Refatoração da Busca Global e Consulta no Customer Core

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

Referência: US-02 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-02: Refatoração da Busca Global e Consulta no Customer Core
1. NARRATIVA DE NEGÓCIO
Como Vendedor B2C ou Agente de Backoffice, BackOffice Inside Sales;Agente de BackOffice (lança a venda para os Agentes Autorizados e Agentes Comerciais, quando necessário);Agente de Relacionamento;Central de Atendimento e Relacionamento - CAR;Agente Autorizado / Agente Comercial;
Quero pesquisar a existência do prospect simultaneamente no banco de dados do Salesforce e do sistema legado (Customer Core) a partir de uma única barra de busca
Para que eu evite a criação de leads e contas duplicadas, equalizando as bases de dados e garantindo uma visão 360º do cliente antes de iniciar qualquer fluxo de venda.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Identificado na reunião de 19/08, a busca nativa do Salesforce não alcança dados que ainda residem exclusivamente no Customer Core. É necessário refatorar a busca para que o vendedor não cadastre como "Lead Novo" um cliente que já possui histórico legado.
Regras:
* O sistema deve realizar uma busca federada utilizando CPF/CNPJ, E-mail ou Telefone como chaves primárias.
* O retorno deve consolidar de forma clara e visual se o registro encontrado reside no Salesforce (Lead/Conta) ou no Customer Core (Cliente Legado).
* Se o cliente for localizado apenas no Customer Core, o sistema deve permitir um "Import/Sync" para instanciar a Pessoa (Account/Contact) no Salesforce com os dados legados antes de abrir a Oportunidade.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Lead, Account, Contact.
Automação / Lógica: FlexCard embutido na Home Page (Search Component) chamando uma Integration Procedure (IP). A IP executará um SOSL interno (Salesforce) paralelamente a uma chamada HTTP externa (ERP).
Integração / APIs: eTOM: Customer Management / TMF632 (Party Management API) para requisição GET /party no Customer Core.
Segurança e Acessos: Permission Set para permitir que o OmniStudio invoque o Named Credential do Customer Core. OWD Read para Accounts.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Prospect não existe em nenhuma base (Lead Inédito)
Dado que o vendedor digita um CPF na busca global refatorada
Quando o sistema aciona a Integration Procedure e não encontra dados no SF nem no Customer Core
Então a interface exibe a mensagem "Nenhum registro encontrado" e habilita o botão "Criar Novo Lead".
Cenário 2: Cliente localizado no Customer Core
Dado que o vendedor busca por um CPF
Quando a API retorna que o cliente possui cadastro ativo no sistema legado
Então o FlexCard exibe os dados mascarados do cliente com a tag "Base Customer Core" e disponibiliza a ação "Iniciar Venda para Cliente da Base" (fazendo o sync dos dados via DataRaptor).
5. DEPENDÊNCIAS E RISCOS
Dependências: API de busca no Customer Core deve estar indexada para suportar chamadas síncronas de alta volumetria.
Riscos/Premissas: [Governor Limits Check] O uso de SOSL no Apex e a chamada REST simultânea não devem exceder 2 segundos de timeout para garantir a usabilidade do operador.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: CPF inédito; CPF existente apenas no Salesforce; CPF existente apenas no Customer Core.

## Critérios de Aceite (related list)

**1. Cenário 2: Cliente localizado no Customer Core** (New)
Dado que o vendedor busca por um CPF
Quando a API retorna que o cliente possui cadastro ativo no sistema legado
Então o FlexCard exibe os dados mascarados do cliente com a tag "Base Customer Core" e disponibiliza a ação "Iniciar Venda para Cliente da Base" (fazendo o sync dos dados via DataRaptor).

**2. Cenário 1: Prospect não existe em nenhuma base (Lead Inédito)** (New)
Dado que o vendedor digita um CPF na busca global refatorada
Quando o sistema aciona a Integration Procedure e não encontra dados no SF nem no Customer Core
Então a interface exibe a mensagem "Nenhum registro encontrado" e habilita o botão "Criar Novo Lead".

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #1 - usada por TODAS as jornadas).
REUSAR: consulta de cliente em producao - BTecParPF_AddressAndClientData > IP_CustomerIntegration > BTecPar_BaseClientIntegration > HTTPCustomer; GET /customer/{documento} via MuleCallout (IntegrationConfig__mdt.customerMulesoft).
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecPar_BaseClientIntegration.
CONSTRUIR: apenas a experiencia federada (SOSL interno em paralelo + FlexCard de resultado + acao de import/sync) SOBRE a cadeia existente.
DIRETRIZ SYSMAP: nao criar novo endpoint de consulta; compor a IP federada chamando BTecPar_BaseClientIntegration como bloco.
