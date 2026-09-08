# W-000067 — US B2C-11 — Tratamento de Débito Interno: Ticket Zendesk e SLA de 5 Dias

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:27 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

"Como Consultor de Vendas B2C
Quero que, ao identificar um débito interno de um cliente durante a análise de elegibilidade, o Salesforce abra automaticamente um chamado de renegociação no Zendesk para a equipe de Cobrança e mantenha a Oportunidade em meu pipeline por até 5 dias.
Para que a cobrança atue na regularização financeira do cliente sem que eu precise sair do ambiente do CRM , permitindo a retomada automática da venda após a confirmação da baixa bancária.

SOLUÇÃO TÉCNICA: REUSO da integração Zendesk EXISTENTE (flow WorkOrder_Update_Zendesk_Status —
aproveitar a mesma Named Credential) e da retomada de venda EXISTENTE (Order.RetomarVendaQuickAction).
CONSTRUIR: status ""Aguardando Pagamento de Débito Interno"" no funil; flow de abertura do ticket com os
dados da CreditAnalysis__c (W-B2C-03); Platform Event DebtSettled__e inbound (BSS/SAP) → flow retoma a
venda + notifica o vendedor; scheduled flow: 5 dias sem baixa → Closed Lost ""Débito Interno Não
Quitado"".

Dependências: callback de baixa financeira do BSS/SAP; risco de negócio: boleto compensa em até 48h
dentro de SLA de 5 dias — aceitar ou alargar o prazo [DEFINIR].

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-11."

## Critérios de Aceite (related list)

**1. 2** (New)
Retomada automática da venda pós-baixa bancária — Dado que o cliente realizou o pagamento do acordo promovido pela cobrança; Quando a API do BSS/SAP notificar a baixa bancária no Salesforce; Então o status da Oportunidade deve ser atualizado para Débito Quitado - Liberado para Venda e uma notificação de tarefas atribuída ao vendedor proprietário.

**2. 1** (New)
Abertura automática de ticket de cobrança no Zendesk — Dado que o retorno da análise de crédito indica a existência de um débito interno pendente; Quando a Oportunidade avançar para o status Aguardando Pagamento de Débito Interno; Então o Salesforce deve disparar uma requisição API criando um chamado no Zendesk da equipe de Cobrança com os dados do débito e do cliente.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: gap confirmado (matriz #19/#23, severidade alta).
REUSAR: apenas a infraestrutura de conexao Zendesk - StatusIntegrationService.cls + WorkOrder_Update_Zendesk_Status.flow (mesma Named Credential). Esta integracao cobre SOMENTE status de WorkOrder e NAO comprova a jornada comercial.
EVIDENCIA: force-app/main/default/classes/StatusIntegrationService.cls | force-app/main/default/flows/WorkOrder_Update_Zendesk_Status.flow-meta.xml.
CONSTRUIR: ticket de renegociacao, callback de baixa (DebtSettled__e), estados, SLA e idempotencia - desenho novo completo.
DIRETRIZ SYSMAP: reaproveitar credencial e padrao de callout; nao assumir reaproveitamento funcional.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-11 — Abertura de Ticket de Débito Interno via Zendesk e SLA de Regularização to US B2C-11 — Tratamento de Débito Interno: Ticket Zendesk e SLA de 5 Dias
