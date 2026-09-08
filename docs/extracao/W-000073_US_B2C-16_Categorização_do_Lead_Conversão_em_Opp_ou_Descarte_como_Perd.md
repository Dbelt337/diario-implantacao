# W-000073 — US B2C-16 — Categorização do Lead (Conversão em Opp ou Descarte como Perdido)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 08/09/2026 17:57 por Diego Beltrão de Moraes

Referência: US-04 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-04: Categorização do Lead (Conversão em Opp ou Descarte como Perdido)
1. NARRATIVA DE NEGÓCIO
Como Vendedor B2C ou Sistema
Quero executar a etapa de consulta do prospect/base no Customer Core e realizar a categorização formal (Perdido ou Convertido)
Para que eu separe prospects inéditos de clientes da base instalada (Up-sell/Cross-sell) e mantenha as métricas de conversão do funil de marketing íntegras.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Estruturação das etapas 2 e 3 apontadas pelo negócio. A validação contra o sistema legado é obrigatória para evitar criação de contas duplicadas e guiar o fechamento da fase de prospecção.
Regras:
* Consulta Customer Core (Prospect/Base): O Lead deve ser submetido à consulta do Customer Core para confirmar se já possui cadastro ativo (Base) ou se é cliente novo (Prospect).
* Categorização de Descarte (Perdido): Se o Lead não tiver interesse ou viabilidade, deve ser categorizado como "Perdido" selecionando o Motivo de Perda correspondente, encerrando o ciclo.
* Categorização de Sucesso (Convertido): Se o Lead qualificar, ele deve ser convertido. O sistema criará ou mesclará a Account e criará a Opportunity automaticamente, transicionando o funil.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Lead, Account, Opportunity, Contact.
Automação / Lógica:
* OmniScript (Lead Qualification): Etapa dedicada "Consulta Customer Core" utilizando uma Integration Procedure (REST GET) via CPF/CNPJ.
* Lead Conversion Mapping: Mapeamento de campos customizados do Lead para Account/Opp.
Integração / APIs:
* TMF632 (Party Management API) para verificar a existência do cadastro no Customer Core (BSS legado).
Segurança e Acessos: Field-Level Security em campos de base legada para visualização do Vendedor. OWD Public Read/Write para conversão cruzada entre contas.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Consulta retornando cliente já na Base (Cross-sell)
Dado que o vendedor inicia a qualificação e insere o CPF do Lead
Quando aciona a "Consulta Customer Core" e a API retorna dados de contrato ativo
Então o sistema sinaliza que é "Cliente da Base" e, ao converter, obriga a vinculação (Merge) do Lead à Conta já existente, gerando uma Oportunidade de expansão.
Cenário 2: Descarte do Lead (Categorização de Perda)
Dado que o contato com o prospect resultou em desinteresse
Quando o vendedor altera o Status para "Perdido"
Então o sistema exige o preenchimento obrigatório do campo "Motivo da Perda" e encerra o fluxo do Lead sem criar Oportunidade.
5. DEPENDÊNCIAS E RISCOS
Dependências: API de consulta de CPF no Customer Core deve estar disponível e responder em tempo real.
Riscos/Premissas: [Edge Cases] Timeout na consulta do Customer Core; o sistema deve ter fallback permitindo a conversão manual caso a API esteja indisponível, mitigando travamento de vendas.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: CPF não cadastrado (Prospect limpo); CPF já cadastrado no Customer Core; Lead categorizado como Perdido (validação de regra de validação do Motivo).
Estimativa de Esforço: 8 Story Points (OmniScript + Integração TMF632 + Lógica de Merge).

## Critérios de Aceite (related list)

**1. Cenário 2: Descarte do Lead (Categorização de Perda)** (New)
Dado que o contato com o prospect resultou em desinteresse
Quando o vendedor altera o Status para "Perdido"
Então o sistema exige o preenchimento obrigatório do campo "Motivo da Perda" e encerra o fluxo do Lead sem criar Oportunidade.

**2. Cenário 1: Consulta retornando cliente já na Base (Cross-sell)** (New)
Dado que o vendedor inicia a qualificação e insere o CPF do Lead
Quando aciona a "Consulta Customer Core" e a API retorna dados de contrato ativo
Então o sistema sinaliza que é "Cliente da Base" e, ao converter, obriga a vinculação (Merge) do Lead à Conta já existente, gerando uma Oportunidade de expansão.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #1/#2).
REUSAR: consulta ao Customer Core (BTecPar_BaseClientIntegration) e conversao (LeadConvertServiceB2C.convertLead) ja operam em producao.
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecPar_BaseClientIntegration | force-app/main/default/classes/LeadConvertServiceB2C.cls.
CONSTRUIR: etapa dedicada de categorizacao (Base x Prospect), merge obrigatorio com conta existente e fallback para indisponibilidade da API.
DIRETRIZ SYSMAP: estender o mapeamento de conversao existente; nao duplicar a logica de merge.
