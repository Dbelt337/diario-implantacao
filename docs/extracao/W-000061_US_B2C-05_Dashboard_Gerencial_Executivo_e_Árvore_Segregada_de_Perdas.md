# W-000061 — US B2C-05 — Dashboard Gerencial Executivo e Árvore Segregada de Perdas

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:16 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:38 por Diego Beltrão de Moraes

"Como Gerente Comercial, Coordenador B2C e Vendedor
Quero visualizar um Painel de Controle (Dashboard) de oportunidades paradas no fluxo e registrar os motivos de perda com segregação entre Leads e Oportunidades
Para que a equipe gerencial execute intervenções ativas de resgate e o marketing analise com precisão as causas de perda em cada estágio do funil.

SOLUÇÃO TÉCNICA — SANEAMENTO ANTES DE CONSTRUÇÃO: a Opportunity tem LossReason__c E Loss_Reason__c
DUPLICADOS (escolher um, migrar dados, aposentar o outro); o Lead usa LossType__c (picklist) +
LossReason__c (texto) — nomenclatura INVERTIDA em relação à Opportunity, documentar nas automações.
REUSO: VR LossReasonRequired ativa; ações Lead.LossLead, Opportunity.LossOpportunity e
CancelRecordAndRelateds; flows CancelLeads/ModifyLostLead/CancelOpportunity_B2B; OWD da Opportunity é
Private — visibilidade hierárquica dos dashboards é nativa (Role Hierarchy). Lead é Public Read:
visibilidade restrita para Lead sai por filtro de relatório, não por OWD.
CONSTRUIR: Opportunity.StageEnteredAt__c + flow de carimbo na troca de fase (base do tempo-na-etapa);
dashboards por papel; trava do botão de perda pós-assinatura = mecânica da W0382 sobre IsContractSigned__c.

Dependências: árvores de motivos validadas pelo comercial BTP.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-05."

## Critérios de Aceite (related list)

**1. 2** (New)
Segregação de Motivos entre Lead e Oportunidade — Dado que o operador está encerrando um Lead não convertido; Quando ele abre o campo "Motivo de Perda"; Então o sistema deve exibir apenas os valores configurados para a picklist de Leads, impedindo a seleção de motivos exclusivos de Oportunidades.

**2. 1** (New)
Disponibilidade do Botão de Perda até a Assinatura do Contrato — Dado que uma Oportunidade está no estágio de "Análise de Crédito" ou "Aguardando Agendamento"; Quando o cliente desiste da compra antes de assinar o contrato; Então o vendedor deve conseguir acionar o botão de perda e selecionar um motivo da lista exclusiva de Oportunidades.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #15) + parcial (matriz #24).
REUSAR: cancelamento de venda em producao - FlexCard B2C > BTecParPF_CancelSale > SVHasOpportunityId > DMCancelSale (update Lead/Opportunity); gestao de perda via Lead/Opportunity + BTecPar_UpdateOrder.
EVIDENCIA: vlocity-backup/IntegrationProcedure/BTecParPF_CancelSale.
CONSTRUIR: padronizacao de motivos/submotivos/historico; carimbo de tempo-na-etapa; dashboards. O saneamento (LossReason__c x Loss_Reason__c duplicados; nomenclatura invertida no Lead) segue obrigatorio antes de qualquer automacao nova.
DIRETRIZ SYSMAP: reusar status e DML existentes; nao criar segundo mecanismo de perda.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-05 — Painel de Controle de Vendas Travadas e Gestão de Perdas Segregada to US B2C-05 — Dashboard Gerencial Executivo e Árvore Segregada de Perdas
