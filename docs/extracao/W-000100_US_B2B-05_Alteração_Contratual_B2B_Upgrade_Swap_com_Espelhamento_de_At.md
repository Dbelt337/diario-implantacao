# W-000100 — US B2B-05 — Alteração Contratual B2B (Upgrade/Swap) com Espelhamento de Ativos e Duplo Check da Arquitetura

Épico: B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 01/09/2026 15:08 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

Referência: US "[MACD - UPGRADE & SWAP]" do documento "Histórias refinadas B2B".

NARRATIVA DE NEGÓCIO
Como Gerente de Relacionamento (GR) / Arquiteto de Soluções
Quero processar alterações contratuais B2B do tipo Upgrade (expansão) ou Swap (permuta) a partir de contratos ativos com espelhamento imutável de Ativos
Para que o incremento de receita ou substituição tecnológica seja validado pela Arquitetura, garanta a governança de margem de contribuição e sincronize os novos ativos no ecossistema de Billing/EOM.
CONTEXTO E REGRAS DE NEGÓCIO (TELECOM B2B)
Contexto: Processamento de ordens MACD em contratos vigentes, garantindo que Ativos atuais sejam espelhados de forma imutável e que modificações de serviço passem por análise técnica e aprovação gerencial.
Mapeamento eTOM: 1.2.1.4 Order Handling, 1.2.1.6 Quotation Management.
Regras de Negócio:
[Regra 1: Espelhamento de Ativos e Imutabilidade] A criação de ordens de Upgrade ou Swap herda automaticamente os Ativos (Assets) vigentes do contrato de forma travada (somente leitura), permitindo apenas a adição de novos produtos ou substituição por itens de maior valor no carrinho.
[Regra 2: Bifurcação de Viabilidade (Expressa vs. Escopo) no Upgrade] Upgrades puramente financeiros (sem alteração técnica de produto/velocidade) seguem via Viabilidade Expressa; Upgrades com adição de novos produtos/capacidade exigem tarefa obrigatória de "Desenho de Solução" pela Arquitetura.
[Regra 3: Duplo Check da Arquitetura no Swap] Negociações do tipo Swap exigem obrigatoriamente justificativa de negócio, aprovação gerencial de margem (Record Lock) e uma etapa de "Validação Técnica Final (Double Check)" pelo Arquiteto antes do envio ao Backoffice.
ESPECIFICAÇÃO TÉCNICA (SALESFORCE B2B)
Objetos Impactados: Contract, Asset, Opportunity (Tipo = Upgrade/Swap), Quote, QuoteLineItem, vlocity_cmt__InventoryItem__c.
Automação / Front-end: LWC / Enterprise CPQ Cart para comparação "Antes vs. Depois", Flow Orchestrator para criação de tarefas de Arquitetura, Approval Process para alçada de margem no Swap.
Integração / APIs TM Forum: TMF637 (Product Inventory), TMF622 (Product Order / MACD Payload).
Segurança e Acessos: Bloqueio do botão MACD em contratos inadimplentes ou com outros processos pendentes de auditoria.
CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Processamento de Upgrade de Valor e Serviço com validação da Arquitetura Dado que o GR dispara a ação "Realizar Upgrade" em um contrato B2B ativo e adiciona um novo link dedicado Quando a cotação é montada Então o sistema identifica alteração de serviço, classifica o fluxo como "Escopo de Solução", bloqueia o avanço comercial e atribui uma tarefa de desenho técnico para o time de Arquitetura.
Cenário 2: Processamento de Swap com aprovação gerencial e Duplo Check Técnico Dado que o GR configura um Swap de tecnologia de um serviço ativo Quando o carrinho é finalizado Então o sistema aciona o Record Lock para aprovação do Gestor Imediato e, após a aprovação comercial e aceite do cliente, retorna obrigatoriamente para a Arquitetura realizar a Validação Técnica Final (Double Check).
ESTIMATIVA, DEPENDÊNCIAS E GOVERNOR LIMITS
Estimativa Sugerida: 13 Story Points (Lógica complexa de MACD em CPQ, espelhamento de ativos e validações de duplo check).
Dependências: Estrutura de Ativos (Assets / Product Inventory) sincronizada com o Customer Core.
Governor Limits & Edge Cases: Otimização de queries SOQL ao clonar e recalcular múltiplos Ativos vigentes para evitar estouro de Heap Size na sessão do CPQ.
DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Cobertura de testes unitários mínima de 85% (sem violação de limites de Apex CPU/SOQL).
[ ] Validação E2E no ambiente de Sandbox/QA. Massa de Teste Sugerida: Contrato B2B com 2 Ativos ativos; Oportunidade de Upgrade com acréscimo de R$ 2.000 MRR; Oportunidade de Swap com justificativa de substituição de infraestrutura.

Nota de arquitetura BTP: jornada MACD Change/Swap asset-based (espelhamento via asset-to-quote). Mesmo pré-requisito de Assets da US anterior.

## Critérios de Aceite (related list)

**1. Cenário 2: Processamento de Swap com aprovação gerencial e Duplo Check Técnico** (New)
Dado que o GR configura um Swap de tecnologia de um serviço ativo
Quando o carrinho é finalizado
Então o sistema aciona o Record Lock para aprovação do Gestor Imediato e, após a aprovação comercial e aceite do cliente, retorna obrigatoriamente para a Arquitetura realizar a Validação Técnica Final (Double Check).

**2. Cenário 1: Processamento de Upgrade de Valor e Serviço com validação da Arquitet** (New)
Dado que o GR dispara a ação "Realizar Upgrade" em um contrato B2B ativo e adiciona um novo link dedicado
Quando a cotação é montada
Então o sistema identifica alteração de serviço, classifica o fluxo como "Escopo de Solução", bloqueia o avanço comercial e atribui uma tarefa de desenho técnico para o time de Arquitetura.

## Notas de Refinamento e Decisões Registradas

--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESCOPO: Onda 1 = B2C venda nova (Avare), ata 03/09; esta work B2B segue em refinamento e entra na onda B2B, a calendarizar.

--- MACD SEM TECNICO E IDENTIDADE DO ATIVO (04/09) ---
Espelhamento via asset-based ordering (AssetReferenceId preservado). Upgrade que altera apenas atributo (ex.: velocidade) e um CHANGE no mesmo ativo, sem Work Order e com a mesma ServiceTag; troca de CPE ou de tecnologia gera equipamento novo (nova ServiceTag EQ) e Work Order. Regras de geracao na US CAT-TAG-01 (W-000104).

## Comentários

- Diego Beltrão de Moraes 01/09/2026 15:44: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
- Diego Beltrão de Moraes 01/09/2026 15:47: Epic__c changed from Catálogo Comercial Unificado - B2B/B2C to B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente
