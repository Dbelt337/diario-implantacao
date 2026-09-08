# W-000059 — US B2C-03 — Regra de Risco: Análise de Contratos sem 1ª Parcela (Gatilho 3º Contrato)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:38 por Diego Beltrão de Moraes

"Como Consultor de Vendas B2C ou Analista de Crédito
Quero realizar a análise de crédito automatizada (com réguas de escore associadas ao Canal de Entrada) e encaminhar solicitações para a Mesa de Crédito
Para que a empresa estabeleça travas de segurança contra fraudes e inadimplência crônica sem comprometer a fluidez das vendas comerciais.

SOLUÇÃO TÉCNICA: régua canal→score→taxa→limite em Decision Matrix (BRE licenciado e habilitado),
editável pela Mesa sem deploy. REUSO: fila CreditTable EXISTE (hoje atende Order — adicionar Lead aos
objetos suportados); score corrente no campo EXISTENTE Account.vlocity_cmt__CreditScore__c; framework
de log de integração do Lead (IntegrationStatus__c/Attempts__c/Error__c) para Serasa/Customer Core.
CONSTRUIR: objeto CreditAnalysis__c (Lead__c/Opportunity__c, Score__c, Bureau__c, ConsultedAt__c,
InternalDebts__c, ContractsWithoutFirstPayment__c, Result__c) — um registro por consulta, snapshot
auditável; flow pós-consulta decide rota (>= limite → Mesa); FLS restrita — vendedor vê só Result__c.

Dependências: API ""contratos sem 1ª parcela"" no Customer Core; score exatamente no corte
(350/380) [DEFINIR — pendência herdada da Política de Crédito]; mesma fonte de canal da W-B2C-01.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-03."

## Critérios de Aceite (related list)

**1. 2** (New)
Consulta de Score Parametrizada por Canal de Entrada — Dado que uma proposta é cadastrada com o Canal de Entrada "PAP Terceiro"; Quando a consulta de crédito é disparada; Então o sistema deve avaliar o escore de corte configurado para o canal "PAP Terceiro" , independentemente do perfil do usuário que realizou o input.

**2. 1** (New)
Gatilho da Mesa de Crédito na Tentativa do 3º Contrato sem 1ª Parcela — Dado que o cliente CPF "111.222.333-44" possui 2 contratos ativos no sistema sem confirmação do pagamento da 1ª parcela; Quando o vendedor tenta avançar uma nova solicitação de 3º contrato no Lead; Então o Salesforce deve bloquear a aprovação direta e direcionar o Lead para a fila da "Mesa de Crédito".

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #5).
REUSAR: consulta de credito em producao - IPCreditAnalysisIntegration > BTecPar_CreditAnalysisIntegration > HTTPGetCreditAnalysisIntegration; GET /get-credit-analysis/{documento} via MuleCallout (IntegrationConfig__mdt.creditAnalysisMulesoft).
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecPar_CreditAnalysisIntegration.
CONSTRUIR: objeto CreditAnalysis__c (snapshot por consulta), regua canal x score em Decision Matrix, rota para a Mesa, API de contratos sem 1a parcela (Customer Core) e fluxo de baixa.
GOVERNANCA: a analise TMF associa esta capacidade a TMF696, que NAO consta no baseline - decidir inclusao no baseline ou registrar dominio alternativo para credito/risco.
DIRETRIZ SYSMAP: a consulta e reuso; o snapshot auditavel e as reguas sao a construcao nova.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-03 — Análise de Risco to US B2C-03 — Regra de Risco: Análise de Contratos sem 1ª Parcela (Gatilho 3º Contrato)
