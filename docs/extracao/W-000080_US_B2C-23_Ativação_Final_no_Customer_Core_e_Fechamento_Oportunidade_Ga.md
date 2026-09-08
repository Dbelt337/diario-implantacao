# W-000080 — US B2C-23 — Ativação Final no Customer Core e Fechamento Oportunidade "Ganho"

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:50 por Diego Beltrão de Moraes

Referência: US-21 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-21: Ativação Final no Customer Core e Fechamento Oportunidade "Ganho"
1. NARRATIVA DE NEGÓCIO
Como Gestor de Vendas e Sistema BSS
Quero encerrar a oportunidade apenas após a integração final de ativação no Customer Core.
Para que os vendedores/coordenadores atuem proativamente para garantir o provisionamento e o ganho ("Closed Won") da receita, e comissões sejam pagas corretamente.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Orquestração final de fechamento sistêmico.
Regras:
* Etapa 12 (Integração Customer Core): Após a Ordem de Serviço concluída (SFS), o Salesforce deve enviar o payload final via API para provisionar/ativar os serviços no Customer Core.
* Etapa 11 (Encerrar Oportunidade): Somente após o retorno de sucesso da Etapa 12 (Status Ativo no Customer Core), o Salesforce atualizará automaticamente a Oportunidade para "Ganho" (Closed Won).
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Opportunity, Order, WorkOrder.
Automação / Lógica:
* Integration Procedure / Trigger: Envio do Payload de MACD (Provide) no fechamento da WorkOrder.
Integração / APIs: TMF641 (Service Ordering) ou TMF622 (Product Ordering) - Envio de ativação final para o Customer Core/OSS.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Fechamento Automatizado e Integração (Closed Won)
Dado que a instalação física foi concluída com sucesso
Quando a API envia os dados para o Customer Core e recebe o status HTTP 200 (Completed)
Então o Salesforce atualiza a Ordem para "Activated" e a Oportunidade correspondente para o status "Ganho", bloqueando edições retroativas.

## Critérios de Aceite (related list)

**1. Cenário 1: Fechamento Automatizado e Integração (Closed Won)** (New)
Dado que a instalação física foi concluída com sucesso
Quando a API envia os dados para o Customer Core e recebe o status HTTP 200 (Completed)
Então o Salesforce atualiza a Ordem para "Activated" e a Oportunidade correspondente para o status "Ganho", bloqueando edições retroativas.

## Notas de Refinamento e Decisões Registradas

--- ALINHAMENTO 01/09/2026 ---
A orquestração completa de decomposição, ativação e fallout está detalhada na nova US de Order Management (work B2C-27). Esta work mantém o escopo de fechamento: callback de ativação com sucesso conclui a orquestração e atualiza a Oportunidade para Ganho, bloqueando edição retroativa.
--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---
Os nomes TMF citados nesta work valem como MAPA DE CAPACIDADE, nao como contrato de payload da Onda 1. Decisao 04/09 (registrada em W-000087): a Onda 1 reusa os endpoints PROPRIETARIOS ja em producao via Named Credential MuleCallout / IntegrationConfig__mdt; o padrao TMF entra como ADAPTER no MuleSoft quando formalizado, sem alterar as Integration Procedures do Salesforce. Contratos de payload por API ficam registrados na W-000087. Nenhum callout sincrono bloqueando tela (padrao W-000086). ESPECIFICO: a ativacao final e o CALLBACK do plano de orquestracao do OM (W-000088/W-000093), nao um callout avulso da oportunidade; Closed Won somente apos o callback de sucesso.
