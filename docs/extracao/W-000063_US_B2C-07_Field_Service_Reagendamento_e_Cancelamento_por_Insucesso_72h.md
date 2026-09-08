# W-000063 — US B2C-07 — Field Service: Reagendamento e Cancelamento por Insucesso (72h / 3 Tentativas)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:20 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:38 por Diego Beltrão de Moraes

"Como Despachante de Field Service e Agente de Backoffice
Quero que o sistema controle as tentativas de contato para agendamento de instalação, transferindo a ordem para o Backoffice após 3 tentativas sem sucesso e cancelando a proposta após 72 horas
Para que as agendas das equipes técnicas de campo não fiquem bloqueadas com ordens ociosas e as propostas inativas sejam limpas do pipeline.

SOLUÇÃO TÉCNICA: REUSO do FSL licenciado e em produção (Dispatcher 324, Scheduling 878, Mobile 1.107
usuários) + cancelamento em cascata EXISTENTE (CancelRecordAndRelateds, Cancell_WO_SA) + reagendamento
EXISTENTE (Order.NovoAgendamento, SA_Auto_Schedule, FlowOrderScheduleInstallation).
CONSTRUIR: WorkOrder.ContactAttempts__c (Number) + ação de registro de tentativa com flow contador;
na 3ª tentativa → owner = fila ""Backoffice Comercial B2C"" (criar) + TransferredToBackofficeAt__c
(DateTime); scheduled flow diário (batch controlado): >= 72h na fila → CancelRecordAndRelateds com
motivo ""Cancelado - Insucesso de Contato em 72h"" (valor novo na árvore da W-B2C-05).

Dependências: validação dos gatilhos de tentativa com a gestão de Delivery.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-07."

## Critérios de Aceite (related list)

**1. 2** (New)
Cancelamento Automático da Proposta após 72 Horas sem Contato — Dado que uma proposta está na Fila do Backoffice Comercial aguardando contato do cliente; Quando o tempo de permanência atinge 72 horas sem confirmação de agendamento; Então o sistema deve cancelar automaticamente a Ordem e a Oportunidade com o motivo "Cancelado - Insucesso de Contato em 72h".

**2. 1** (New)
Transferência do Delivery para o Backoffice após 3 Tentativas — Dado que uma Ordem de Serviço de instalação está com a equipe de Delivery; Quando o operador registra a 3ª tentativa de contato sem sucesso com o cliente; Então o Salesforce deve transferir a Ordem de Serviço para a Fila "Backoffice Comercial B2C" e iniciar a contagem do SLA de 72 horas.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #12, confirmado em codigo).
REUSAR: agendamento em producao - FlowOrderScheduleInstallation (grava agendamento) + BTecparFSLAvailabilityController.bookOrderAndAppointment (slots/OS) + Service_AppointmentServiceAppointmentCreation.flow.
EVIDENCIA: force-app/main/default/flows/FlowOrderScheduleInstallation.flow-meta.xml | force-app/main/default/classes/BTecparFSLAvailabilityController.cls.
CONSTRUIR: contador de tentativas (ContactAttempts__c), fila Backoffice, scheduled flow de 72h.
DIRETRIZ SYSMAP: separar explicitamente este agendamento manual/FSL do AUTOAGENDAMENTO bot, que e gap (matriz #19) e vive em outra work.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-07 — Regra de Reagendamento e Cancelamento de Instalação por Insucesso de Contato (72h / 3 Tentativas) to US B2C-07 — Field Service: Reagendamento e Cancelamento por Insucesso (72h / 3 Tentativas)
