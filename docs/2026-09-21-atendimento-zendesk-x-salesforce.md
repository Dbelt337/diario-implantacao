# 21/09/2026 - Atendimento: Zendesk x Salesforce (decisão pendente com Bismarck)

## Fatos
- Atendimento B2C hoje no Zendesk (marca Seja Amigo, WhatsApp, bot "Amigo", fila Fidelização). App próprio "Tecpar ticket
  sidebar" busca contratos por CPF/CNPJ/telefone e mostra ofertas (fonte a confirmar: Core). Ticket sem organização vinculada:
  conector nativo Zendesk-Salesforce não ligado.
- Org tem **2.100 assentos sem uso** de Service Console for Communications, Industries Sales Excellence e Business Processes
  for Communications. Enterprise Sales Management sem permission set license (chamado ao AE, como o OM).
- Conector nativo Zendesk for Salesforce: Account -> Organization, Contact/Lead -> User; ticket -> Case só de ida; fechados e
  anexos não sincronizam; só Case. Digital Engagement (Messaging/WhatsApp no Salesforce) não consta na lista de licenças de 15/09.
- Sidebar Tecpar: quem construiu, de onde lê, se grava pedido e o que faz "Massiva" (perguntas abertas).

## Três fronteiras e a recomendação
| Fronteira | Recomendação |
|---|---|
| 1. Visão 360 em dois sistemas | Uma 360 só, no Salesforce (conta, ativos, pedidos, casos, faturas). Zendesk mostra via conector e sidebar lendo do Salesforce, não do Core. |
| 2. Contrato, faturas, ordens de campo por API via Mule | Leitura no sidebar é correto para o 1º nível; fonte = Salesforce (Asset, Order, WorkOrder FSL) via Mule, não o Core. |
| 3. Onde nasce o cancelamento e onde roda a retenção | Nasce no Zendesk (ticket -> Case pelo conector). Retenção roda no Salesforce (Service Console for Communications + CPQ + promoção W-000128 + piso + Aprovação Comercial). Aceite = pedido; recusa = ordem de desconexão no OM. |

Concordo com a BTP: **célula de retenção no Salesforce**. Primeiro nível, WhatsApp e bot ficam no Zendesk por enquanto
(mover exige Messaging/Digital Engagement, bot em Agentforce e retreino; não é o momento com a Onda 1 do catálogo).

## Sequência proposta
1. Agora: conector nativo ligado; célula de retenção no Salesforce; sidebar do Zendesk passa a ler do Salesforce (DC APIs
   para ofertas; TMF622 ou Cart API para o pedido).
2. Onda 2: 1º nível B2B no Service Console (B2B já vive no Salesforce, volume menor).
3. Decisão à parte, com licença de Messaging na mesa: 1º nível B2C.

## Regras
- Zendesk nunca decide preço nem grava pedido fora do Salesforce: pergunta ("ofertas para este contrato?") e envia ("aceitou esta").
- Renegociação: uma oportunidade por negociação, uma cotação por pacote proposto; oportunidade nova só se fechou perdida e
  voltou, ou se mudou o contrato/ativo. Aprovação Comercial roda na oportunidade (OpportunityApprovalSteps_B2B): cada cotação
  abaixo do piso reabre a aprovação; combinar com Gerson se passa a olhar a cotação principal.
- Um projeto, duas frentes (Atendimento no Zendesk; Plataforma no Salesforce), um dono do contrato de integração. Histórias do
  Zendesk no mesmo Agile, épico B2C, tag Atendimento.

## Perguntas para o Bismarck
1. Motivo do atendimento no Zendesk (histórico, contrato, equipe?). 2. Vencimento e prazo do contrato Zendesk. 3. Quem mantém o
sidebar Tecpar e de onde ele lê e grava. 4. Provisão das PSL de Enterprise Sales Management e de Messaging.
