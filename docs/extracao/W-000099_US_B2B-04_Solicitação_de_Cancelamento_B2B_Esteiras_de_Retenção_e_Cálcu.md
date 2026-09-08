# W-000099 — US B2B-04 — Solicitação de Cancelamento B2B, Esteiras de Retenção e Cálculo de Multa Rescisória

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 15:08 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[MACD - RETENÇÃO & CHURN]" do documento "Histórias refinadas B2B".

NARRATIVA DE NEGÓCIO
Como Gestor de Relacionamento (GR) / Analista de Retenção / Backoffice B2B
Quero processar solicitações de cancelamento de contratos corporativos através de esteiras sequenciais de retenção e cálculo automatizado de multa por quebra de fidelidade
Para que a empresa esgote as tentativas de manutenção da receita recorrente (MRR), garanta conformidade jurídica e execute o desligamento financeiro (Billing Stop) sem passivos operacionais.
CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2B)
Contexto: Gestão de churn em contratos B2B ativos, exigindo upload de notificação formal, esteira de retenção por desconto (BKO), esteira de retenção por readequação técnica (Arquitetura) e automação de penalidade por carência.
Mapeamento eTOM: 1.2.1.7 Retention & Loyalty, 1.2.1.4 Order Handling.
Regras de Negócio:
[Regra 1: Upload Obrigatório de Evidência Formal] A abertura do fluxo de cancelamento em contrato ativo exige o upload obrigatório da notificação formal do cliente (e-mail/PDF/MSG) ou marcação de "Cancelamento Compulsório" (notificação extrajudicial por inadimplência), bloqueando o avanço sem este comprovante.
[Regra 2: Esteiras Sequenciais de Retenção] O cancelamento transita primeiro pela Esteira de Retenção BKO (tentativa de conceder desconto via Price Book de Retenção); caso recusada pelo cliente, transita pela Esteira de Retenção da Arquitetura (redimensionamento/troca de produtos). Se aceito em qualquer etapa, o contrato é readequado e o churn é cancelado.
[Regra 3: Cálculo Automático de Multa e Governança de Isenção] Se as retenções falharem, o motor do sistema calcula automaticamente a multa rescisória proporcional com base na carência restante. Qualquer pedido de isenção de multa exige aprovação mandatória do Diretor Comercial em fluxo de aprovação com bloqueio de registro (Record Lock).
ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2B)
Objetos Impactados: Contract, Opportunity (Tipo = Cancelamento/Churn), Asset, Task, ContentDocumentLink.
Automação / Front-end: OmniScript / Flow de Cancelamento, Motor de Fórmula Apex para cálculo de multa rescisória ((Mensalidades Restantes * Valor MRR) * % Multa), Approval Process para Isenção de Multa.
Integração / APIs TM Forum: TMF622 (Product Order - Cancel/Disconnect), TMF637 (Product Inventory), API REST MuleSoft/Customer Core para comando de Billing Stop.
Segurança e Acessos: Imutabilidade do arquivo de evidência anexado (tag de segurança restrita); congelamento dos Ativos (Assets) contra novos adicionais durante o processo de cancelamento.
CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Reversão bem-sucedida na Esteira de Retenção BKO Dado que um contrato ativo possui uma solicitação de cancelamento com e-mail formal anexado Quando o Analista de BKO aplica uma proposta de desconto do Price Book de Retenção e o cliente aceita Então o sistema atualiza o valor do contrato/Ativo vigente, altera o estágio para "Retido - Comercial" e encerra a Oportunidade de cancelamento mantendo o serviço ativo.
Cenário 2: Falha nas retenções, cálculo de multa e envio de Billing Stop ao ERP Dado que o cliente recusou as propostas de retenção do BKO e da Arquitetura e o contrato possui 6 meses de carência restante Quando o BKO confirma a efetivação do cancelamento Então o sistema calcula a multa rescisória imutável, altera o status dos Ativos para "Cancelado", e envia a chamada de API TMF622 (Billing Stop) para o Customer Core/ERP aguardando o Callback 200 OK.
ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 13 Story Points (Desenvolvimento de fluxos sequenciais de retenção, motor de cálculo de multa e integração de encerramento de billing).
Dependências: Estabilidade da API de Billing Stop no Customer Core / Barramento MuleSoft.
Governor Limits & Edge Cases: Garantia de sincronismo e tratamento de timeouts na integração com o ERP para evitar que o cliente seja desativado no CRM mas continue sendo faturado no BSS/SAP.
DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Cobertura de testes unitários mínima de 85% (sem violação de limites de Apex CPU/SOQL).
[ ] Validação E2E no ambiente de Sandbox/QA. Massa de Teste Sugerida: Contrato B2B em período de fidelidade (12 meses restantes); Contrato fora da carência; Solicitação de cancelamento com flag "Solicitar Isenção de Multa" ativada.

Nota de arquitetura BTP: jornada MACD Disconnect asset-based; depende dos Assets sincronizados (hoje a org só tem OrderItems com action Add). Evidência de cancelamento como File tipado e imutável.

## Critérios de Aceite (related list)

**1. Cenário 2: Falha nas retenções, cálculo de multa e envio de Billing Stop ao ERP** (New)
Dado que o cliente recusou as propostas de retenção do BKO e da Arquitetura e o contrato possui 6 meses de carência restante
Quando o BKO confirma a efetivação do cancelamento
Então o sistema calcula a multa rescisória imutável, altera o status dos Ativos para "Cancelado", e envia a chamada de API TMF622 (Billing Stop) para o Customer Core/ERP aguardando o Callback 200 OK.

**2. Cenário 1: Reversão bem-sucedida na Esteira de Retenção BKO** (New)
Dado que um contrato ativo possui uma solicitação de cancelamento com e-mail formal anexado
Quando o Analista de BKO aplica uma proposta de desconto do Price Book de Retenção e o cliente aceita
Então o sistema atualiza o valor do contrato/Ativo vigente, altera o estágio para "Retido - Comercial" e encerra a Oportunidade de cancelamento mantendo o serviço ativo.

## Notas de Refinamento e Decisões Registradas

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESPECIFICO: Billing Stop pelo endpoint proprietario do Customer Core; o cancelamento referencia o ativo pela ServiceTag (chave de negocio, US CAT-TAG-01) e preserva o AssetReferenceId. ESCOPO: Onda 1 = B2C venda nova (Avare), ata 03/09; esta work B2B segue em refinamento e entra na onda B2B, a calendarizar.

## Comentários

- Diego Beltrão de Moraes 01/09/2026 15:44: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
- Diego Beltrão de Moraes 01/09/2026 15:47: Epic__c changed from Catálogo Comercial Unificado - B2B/B2C to B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente
