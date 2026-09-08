# W-000077 — US B2C-20 — Controle de Pagamento, Isenção de Taxa e Autoagendamento Bot

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

Referência: US-17 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-17: Controle de Pagamento, Isenção de Taxa e Autoagendamento Bot
1. NARRATIVA DE NEGÓCIO
Como Sistema / Operação de Backoffice
Quero orquestrar a confirmação de pagamento da taxa, acionar o bot do WhatsApp para agendamento e despachar a OS ao Field Service
Para que eu elimine o trabalho manual do vendedor no agendamento, evite visitas técnicas ociosas de clientes inadimplentes e marque a venda como ganha apenas após a infraestrutura ativada.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: O projeto B2C exige a automação total entre a venda, a compensação financeira e o delivery técnico, eliminando intervenções manuais para agendamento.
Regras:
* [Regra de negócio 1] O agendamento da instalação no Field Service só deve ser liberado/realizado APÓS a confirmação da baixa bancária do pagamento da taxa.
* [Regra de negócio 2] O cliente possui o SLA/Prazo estipulado de 5 dias úteis para realizar o pagamento. Se o pagamento não ocorrer nesse prazo, a oportunidade vira "Perdida" automaticamente. Exceções de prazo são tratadas via tarefas manuais do próprio vendedor, sem alterar o fluxo sistêmico padrão.
* [Regra de negócio 3] Confirmado o pagamento, um Bot integrado ao Zendesk/Salesforce acionará o cliente via WhatsApp para escolha do slot de agendamento, gravando os dados direto no sistema.
* [Regra de negócio 4] A Oportunidade só é classificada como "Ganha" (Closed Won) após a Ordem de Serviço ser efetivamente concluída/ativada pela equipe de campo.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Order, Opportunity, ServiceAppointment, WorkOrder.
Automação / Lógica: Flow Schedule-Triggered (para varrer ordens pendentes de pagamento > 5 dias e fechar oportunidade). Integration Procedure para escutar Webhook do sistema de cobrança/banco.
Integração / APIs: eTOM: Order Handling / Service Provisioning; TMF641 (Service Ordering) e Integração de Inbound API para o Chatbot submeter a data escolhida.
Segurança e Acessos: Usuário de Integração (Integration User) com permissão para criar Service Appointments e atualizar Status da Oportunidade.
4. CRITÉRIOS DE ACEITE (FORMATO GHERKIN)
Cenário 1: Cancelamento por Falta de Pagamento (Prazo 5 Dias)
Dado que uma Ordem de Venda B2C Só pode ser gerada após pagamento.
Quando o prazo de 5 dias é atingido sem retorno do callback de pagamento do ERP
Então o Salesforce roda o job noturno, altera o status da Ordem para "Cancelada" e a Oportunidade para "Fechada Perdida" com o motivo "Falta de Pagamento".
Cenário 2: Agendamento Automatizado Bot -> SFS
Dado que o pagamento foi confirmado via API
Quando o cliente responde ao Bot de WhatsApp escolhendo a data e o período
Então o Bot consome a API do Salesforce, grava os horários no ServiceAppointment e gera a Ordem de Ativação para o Field Service.
Cenário 3: Fechamento Efetivo da Venda
Dado que o Field Service está com a WorkOrder em execução
Quando o técnico em campo dá o "Concluído" no aplicativo móvel
Então o status da WorkOrder é fechado e o sistema atualiza a Oportunidade de vendas para "Closed Won".
5. DEPENDÊNCIAS E RISCOS
Dependências: Sistema de faturamento (Amigo/Customer Core) deve garantir o envio do webhook de compensação bancária em tempo real (Near Real Time).
Riscos/Premissas: [Edge Cases Matrix] O cliente pode pagar a taxa no 5º dia, e a compensação bancária cair no 6º dia, causando o cancelamento indevido pelo Job. É mandatório que o Job de 5 dias considere um delta de D+1 para compensações de boleto, totalizando 6 dias de carência sistêmica.
6. DEFINITION OF DONE (DoD) & MASSA DE TESTES
[ ] Desenvolvimento concluído conforme critérios de aceite.
[ ] Testes unitários com cobertura mínima de 85% e sem violação de Governor Limits.
[ ] Validação dos fluxos/regras em ambiente de Sandbox/QA.
Massa de Teste Sugerida: Ordens simuladas aguardando pagamento; Mocks de confirmação de pagamento bancário; Mocks de Payload do Bot enviando Slot de tempo.
Estimativa Automática de Esforço: 13 Story Points (Alta complexidade. Envolve integração com ERP para Billing, Bot de mensageria e transição de ciclo de vida com o Field Service Lightning).

## Critérios de Aceite (related list)

**1. Cenário 3: Fechamento Efetivo da Venda** (New)
Dado que o Field Service está com a WorkOrder em execução
Quando o técnico em campo dá o "Concluído" no aplicativo móvel
Então o status da WorkOrder é fechado e o sistema atualiza a Oportunidade de vendas para "Closed Won".

**2. Cenário 2: Agendamento Automatizado Bot -> SFS** (New)
Dado que o pagamento foi confirmado via API
Quando o cliente responde ao Bot de WhatsApp escolhendo a data e o período
Então o Bot consome a API do Salesforce, grava os horários no ServiceAppointment e gera a Ordem de Ativação para o Field Service.

**3. Cenário 1: Cancelamento por Falta de Pagamento (Prazo 5 Dias)** (New)
Dado que uma Ordem de Venda B2C Só pode ser gerada após pagamento.
Quando o prazo de 5 dias é atingido sem retorno do callback de pagamento do ERP
Então o Salesforce roda o job noturno, altera o status da Ordem para "Cancelada" e a Oportunidade para "Fechada Perdida" com o motivo "Falta de Pagamento".

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: gap confirmado (matriz #23 - renegociacao/baixa sem cadeia 1:1; matriz #19 - bot).
CONSTRUIR: estados e eventos do ciclo financeiro (SLA 5 dias + carencia D+1, pausa, baixa, expiracao, desbloqueio) e o gate de agendamento pos-pagamento - construcao nova.
REUSAR: infraestrutura de notificacao existente (NotificationController) para os avisos internos.
EVIDENCIA: force-app/main/default/classes/NotificationController.cls.
DIRETRIZ SYSMAP: webhook de compensacao bancaria em near real time e pre-requisito do fluxo; sem ele, todo o desenho de 5 dias falha (risco ja registrado na work).
