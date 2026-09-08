# W-000074 — US B2C-17 — Consulta Simultânea de Viabilidade Técnica e Crédito B2C

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

Referência: US-06 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-06: Consulta Simultânea de Viabilidade Técnica e Crédito B2C
1. NARRATIVA DE NEGÓCIO
Como Vendedor B2C (Canal Próprio, Autorizado ou Inside Sales)
Quero realizar a consulta de viabilidade técnica de rede e análise de crédito do cliente em uma única ação (One-Click) durante o preenchimento do cadastro
Para que eu otimize o tempo de atendimento na venda guiada, evite retrabalho e qualifique o prospect imediatamente, reduzindo a fricção na jornada de compra.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: A jornada de vendas B2C no Salesforce foi simplificada para reduzir etapas. As validações fundamentais (técnica e financeira) foram consolidadas. O foco é garantir uma venda rápida, sem bloqueios sistêmicos irrevogáveis que prejudiquem a conversão.
Regras:
* [Regra de negócio 1] A consulta de viabilidade de rede e análise de crédito devem ser disparadas simultaneamente.
* [Regra de negócio 2] O padrão de viabilidade técnica de rede é de 200 metros a partir da CTO. Exceções devem ser tratadas via delivery da regional.
* [Regra de negócio 3] Se o endereço do cliente constar como inadimplente no histórico, o sistema não deve aplicar um bloqueio rígido/automático (hard block), mas sim sinalizar a pendência visualmente e rotear para aprovação do coordenador.
* [Regra de negócio 4] O botão de "Perder Venda" (Lost) deve estar disponível em todas as etapas desta qualificação, sendo ocultado apenas após a assinatura do contrato.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Lead, Opportunity, Account, vlocity_cmt__ServicePoint__c.
Automação / Lógica: OmniScripts (Guided Selling), Integration Procedures (para paralelismo das chamadas), DataRaptors (Extract/Post), FlexCards (para sinalização visual de inadimplência no endereço).
Integração / APIs: eTOM: Selling / TMF645 (Service Qualification API) para viabilidade de rede; Integração REST com motor de crédito Serasa/InHouse.
Segurança e Acessos: Permission Set B2C_Sales_Agent; FLS de leitura nos retornos de score de crédito; OWD Private para Account/Opportunity.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Consulta simultânea aprovada (Caminho Feliz)
Dado que o vendedor preencheu o CEP, Número, Complemento e CPF do cliente no OmniScript de Nova Venda
Quando ele clica em "Consultar Viabilidade e Crédito"
Então o sistema realiza as chamadas assíncronas, retorna viabilidade positiva (<200m) e crédito aprovado, avançando para o carrinho de produtos (CPQ).
Cenário 2: Endereço com histórico de inadimplência (Exceção)
Dado que o endereço consultado possui uma flag de inadimplência prévia na base
Quando a consulta simultânea retorna a validação do local
Então o sistema exibe um alerta visual não-impeditivo no FlexCard para prosseguir para o carrinho.
5. DEPENDÊNCIAS E RISCOS
Dependências: APIs de Viabilidade (Customer Core/Sistemas de Engenharia) e Bureau de Crédito devem suportar concorrência e tempos de resposta < 3s.
Riscos/Premissas: [Governor Limits Check] O uso de Integration Procedures em modo Non-Blocking (Chainable) é mandatório para evitar Callout Exceptions caso as APIs externas demorem a responder simultaneamente.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: CPF válido sem restrições; CEP com viabilidade a 150m da CTO; CEP com histórico de inadimplência mapeado no Customer Core.
Estimativa Automática de Esforço: 8 Story Points (Complexidade média-alta devido ao paralelismo de chamadas no Integration Procedure e tratamento de erros visuais no OmniScript).

## Critérios de Aceite (related list)

**1. Cenário 2: Endereço com histórico de inadimplência (Exceção)** (New)
Dado que o endereço consultado possui uma flag de inadimplência prévia na base
Quando a consulta simultânea retorna a validação do local
Então o sistema exibe um alerta visual não-impeditivo no FlexCard para prosseguir para o carrinho.

**2. Cenário 1: Consulta simultânea aprovada (Caminho Feliz)** (New)
Dado que o vendedor preencheu o CEP, Número, Complemento e CPF do cliente no OmniScript de Nova Venda
Quando ele clica em "Consultar Viabilidade e Crédito"
Então o sistema realiza as chamadas assíncronas, retorna viabilidade positiva (<200m) e crédito aprovado, avançando para o carrinho de produtos (CPQ).

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #4/#5) - as DUAS consultas desta work existem em producao.
REUSAR: BTecPar_TechnicalViabilityCheck (viabilidade) e BTecPar_CreditAnalysisIntegration (credito), hoje orquestradas por SalesJourney_CheckFeasibility.
EVIDENCIA: vlocity-backup/IntegrationProcedure/SalesJourney_CheckFeasibility (orquestrador atual).
CONSTRUIR: o PARALELISMO one-click (IPs non-blocking/chainable), o FlexCard de sinalizacao e o tratamento de timeout - a construcao e de orquestracao/UX, nao de integracao.
DIRETRIZ SYSMAP: refatorar SalesJourney_CheckFeasibility para chamadas paralelas em vez de criar IPs novas do zero.
