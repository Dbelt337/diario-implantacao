# W-000068 — US B2C-12 — Gestão da Taxa de Ativação (R$ 149,99) e Alçadas de Desconto

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:29 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:39 por Diego Beltrão de Moraes

"Como Consultor de Vendas B2C
Quero solicitar aprovação da Mesa de Crédito quando um cliente negativado recusar o valor integral da Taxa de Ativação (R$ 149,90), e garantir que o agendamento da instalação pelo Chatbot ocorra apenas após a confirmação da baixa bancária dessa taxa.
Para que a empresa mantenha a alçada de descontos centralizada na Mesa de Crédito e garanta que o time de campo (Field Service) seja despachado apenas para clientes financeiramente regularizados.

SOLUÇÃO TÉCNICA — REUSO MAIOR DO INVENTÁRIO: a família da taxa JÁ EXISTE no Order
(InstallationFeeAmount__c, InstallationFeeStatus__c, InstallationFeeDueDate__c,
DiscountedInstallationFee__c, DiscountedInstallFeeApproved__c, FeeBillingType__c) e o processo de
desconto/isenção COM APROVAÇÃO JÁ EXISTE (FLW_Approval_InstallationFee,
OrderInstallationFeeExemptionOrDiscount, Order_Approver_Installation_Screen,
Order.RequestExceptionDiscountAction). A work é ADAPTAR: rota de aprovação apontada para a fila
CreditTable (Mesa) com alçada 0-100%; GATE do agendamento = Order.InstallationFeeStatus__c (campo
existente, não criar) bloqueando criação de ServiceAppointment; baixa via Platform Event.
Chatbot: IP expondo AppointmentBookingService.GetSlots (FSL) para consulta/gravação de slots —
o bot em si é EXTERNO (Messaging e Chatbot Salesforce estão DESABILITADOS na lista de licenças).

Dependências: plataforma do bot WhatsApp (Zendesk/broker Meta); callback de baixa do BSS.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-12."

## Critérios de Aceite (related list)

**1. 1** (New)
Envio de solicitação de desconto para a Mesa de Crédito — Dado que o cliente possui restrição no Serasa e é elegível mediante taxa de R$ 149,90; Quando o vendedor selecionar a opção "Solicitar Desconto na Taxa" e informar a justificativa; Então o sistema deve disparar o Processo de Aprovação enviando a Oportunidade para a fila da Mesa de Crédito e bloqueando edições na cotação.

**2. 2** (New)
Agendamento automático no Field Service via WhatsApp pós-baixa — Dado que o cliente efetuou o pagamento da taxa de ativação aprovada; Quando a API do BSS confirmar o pagamento no Salesforce; Então o sistema deve acionar o Chatbot no WhatsApp para que o cliente escolha a data/período de instalação e, ao receber a resposta, gravar o ServiceAppointment no FSL.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado/parcial (matriz #9, confianca alta) + gap financeiro de severidade alta.
REUSAR: aprovacao e alcadas da taxa em producao - FLW_Approval_InstallationFee (submissao/retorno) + OrderInstallationFeeExemptionOrDiscount (isencao/desconto) + BTecParPF_CalculateInstallationFee (calculo). Exatamente o reuso que esta work ja apontava.
EVIDENCIA: force-app/main/default/flows/FLW_Approval_InstallationFee.flow-meta.xml | force-app/main/default/flows/OrderInstallationFeeExemptionOrDiscount.flow-meta.xml | vlocity-backup/IntegrationProcedure/BTecParPF_CalculateInstallationFee.
CONSTRUIR: geracao e baixa do boleto/SAP NAO estao isoladas no AS-IS e TMF678 (Customer Bill) nao foi localizada fim a fim - o elo financeiro (gerar cobranca > baixa > desbloqueio) e construcao nova com contrato de integracao a definir com o time financeiro.
DIRETRIZ SYSMAP: apontar a rota de aprovacao existente para a fila da Mesa; nao iniciar o gate de agendamento sem o contrato do callback de baixa definido.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-12 — Solicitacão de Desconto na Taxa de Ativação e Agendamento pós-Baixa via Chatbot to US B2C-12 — Gestão da Taxa de Ativação (R$ 149,99) e Alçadas de Desconto
