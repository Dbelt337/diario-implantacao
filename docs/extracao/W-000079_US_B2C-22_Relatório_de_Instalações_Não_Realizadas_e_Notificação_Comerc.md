# W-000079 — US B2C-22 — Relatório de Instalações Não Realizadas e Notificação Comercial

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 31/08/2026 19:14 por Diego Beltrão de Moraes | Alterado: 31/08/2026 19:26 por Diego Beltrão de Moraes

Referência: US-20 do documento "Histórias Refinadas B2C - Backlog Completo e Consolidado".

US-20: Relatório de Instalações Não Realizadas e Notificação Comercial
1. NARRATIVA DE NEGÓCIO
Como Gestor de Vendas e Sistema BSS
Quero visualizar relatórios/dashboards de instalações pendentes, notificar as hierarquias comerciais sobre status críticos e encerrar a oportunidade apenas após a integração final de ativação.
Para que a diretoria acompanhe estrategicamente os gargalos operacionais e os vendedores/coordenadores atuem proativamente para garantir o provisionamento e o ganho ("Closed Won") da receita.
2. CONTEXTO E REGRAS DE NEGÓCIO (TELECOM)
Contexto: Estruturação das etapas 9 a 12 (Fase Pós-Venda e Provisionamento). Trata-se da visibilidade executiva e orquestração final de fechamento sistêmico.
Regras:
* Etapa 9 (Relatório de Instalações não realizadas): Criação de relatórios e painéis listando Oportunidades/Ordens com agendamento estourado, cancelado em campo ou pendente.
* Etapa 10 (Notificações e Dashboard Estratégico): O sistema deve disparar notificações Push no Salesforce (Bell Icon) ao Vendedor e seu Coordenador caso uma instalação falhe. Um Dashboard Executivo deve consolidar essas visões para a gerência.
3. ESPECIFICAÇÃO TÉCNICA (SALESFORCE)
Objetos Impactados: Opportunity, Order, WorkOrder (SFS), ServiceAppointment.
Automação / Lógica:
* Reports & Dashboards: Pasta "Executivo B2C", Dashboard "Acompanhamento Estratégico de Instalações".
* Salesforce Flow (Record-Triggered): Uso do elemento Send Custom Notification endereçado ao OwnerId e ManagerId (Role Hierarchy) em caso de falha de instalação (WorkOrder.Status = Cannot Complete).
- Notificação de Falha: Dado que o técnico de campo marca a OS como "Não Concluído", / Quando o registro é atualizado, / Então o sistema dispara uma notificação (Bell Icon) para o Vendedor e Coordenador.

## Critérios de Aceite (related list)

**1. Notificação de Falha** (New)
Dado que o técnico de campo marca a OS como "Não Concluído"
Quando o registro é atualizado
Então o sistema dispara uma notificação (Bell Icon) para o Vendedor e Coordenador.
