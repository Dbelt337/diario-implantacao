# Sustentação B2B: hierarquia comercial do time do Rodrigo Piccolo (chamado via Samuel Vitor, 15-16/09/2026)

Pedido original (Tatiane Pompermaier, planejamento): "Gabriel sob gestão do Rodrigo Nascimento Piccolo", porque interfere nos relatórios de funil/forecast. Levantamento do Diego (15/09): na hierarquia de papéis o Gabriel já está abaixo do Rodrigo, como todo o time de Operadoras e Utilities; a divergência está no campo **Gerente da conta** (`Account.AccountManager__c`), usado nos relatórios: 6 contas com Wesley (3 Gabriel, 3 Tatiane), 27 em branco (Luan, Lucidia, Tamires, Tatiane), 13 oportunidades abertas com aprovador (`Opportunity.ManagerAccount__c`) diferente do Rodrigo, 6 delas do Gabriel travadas na aprovação de Arquitetura.

Decisão (Tatiane, 16/09, confirmada com o planejamento): contas passam para o Rodrigo como gerente, tanto as com Wesley quanto as em branco; **não mudar o dono da conta nem o dono da oportunidade** (são o gerente de relacionamento).

Execução: `scripts/29_GerenteConta_TimeRodrigo_1609.apex` (duas fases). Time = usuários ativos nos papéis abaixo do papel do Rodrigo (até 3 níveis). Contas: gerente Wesley ou em branco → Rodrigo. Oportunidades abertas do time com aprovador ≠ Rodrigo → Rodrigo (as travadas em aprovação falham na regra de validação e ficam para depois da aprovação ou para reatribuição pelo script 27). Owner nunca é tocado.

Contexto relacionado: o mesmo campo Gerente da Conta foi a causa do chamado da Tayza (SENAC, 15/09): o `ManagerAccount__c` da oportunidade é copiado na criação e define o aprovador da etapa comercial na orquestração `OpportunityApprovalSteps_B2B`.
