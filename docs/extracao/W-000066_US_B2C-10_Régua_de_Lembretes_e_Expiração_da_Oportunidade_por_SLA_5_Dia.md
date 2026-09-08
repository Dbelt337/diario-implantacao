# W-000066 — US B2C-10 — Régua de Lembretes e Expiração da Oportunidade por SLA (5 Dias)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:25 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:51 por Diego Beltrão de Moraes

"Como Gestor Comercial B2C
Quero que o Salesforce e o Marketing Cloud executem uma régua de comunicação com até 3 disparos automatizados durante um período máximo de 5 dias no pipeline para propostas aguardando assinatura, cancelando automaticamente a Oportunidade caso não haja aceite.
Para que a operação automatize a cobrança do cliente, reduza o tempo de ciclo da venda e evite propostas pendentes acumuladas no pipeline dos vendedores.

SOLUÇÃO TÉCNICA: jornada no Marketing Cloud com ENTRADA POR API EVENT — o sync padrão do MC Connect
roda em ciclos de ~15 min e NÃO garante o 1º disparo em 15 minutos; janela 08h-20h na configuração da
jornada; exit criteria no aceite (Platform Event ContractSigned__e da W-B2C-09). Templates WhatsApp
exigem aprovação da Meta (até 24h por template — planejar antes da UAT). O cancelamento no 5º dia é
NATIVO e independe do MC: scheduled flow diário → Closed Lost, motivo ""Falta de Assinatura"" (árvore
saneada da W-B2C-05) + tarefa ao vendedor.

Dependências: [CONFIRMAR] licença Marketing Cloud Engagement + canal WhatsApp — NÃO consta na lista
de licenças do org (contrato separado). Fallback sem MC: e-mail via flow + WhatsApp pelo canal do bot.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-10."

## Critérios de Aceite (related list)

**1. 2** (New)
Cancelamento automático no 5º dia — Dado que uma proposta está aguardando assinatura há 5 dias completos; Quando o Job de expiração for executado; Então o Salesforce deve marcar a Oportunidade como Perdida (Closed Lost) com o motivo Falta de Assinatura e notificar o vendedor proprietário.

**2. 1** (New)
Primeiro disparo de lembrete pós 15 minutos — Dado que um contrato foi enviado ao cliente e a Oportunidade está em Aguardando Assinatura; Quando decorrerem 15 minutos sem a confirmação de assinatura; Então o sistema deve disparar o 1º lembrete automático via WhatsApp/E-mail contendo o link de aceite.

## Notas de Refinamento e Decisões Registradas

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: gap confirmado (matriz #20, severidade alta - regua nao localizada no ZIP; templates, consentimento e cadencia nao comprovados).
CONSTRUIR: tudo desta work e novo. A pendencia de licenca Marketing Cloud esta corroborada pelo AS-IS.
DIRETRIZ SYSMAP: capacidade orientada a eventos (entrada por API Event, exit por ContractSigned__e), com o cancelamento do 5o dia NATIVO por scheduled flow, independente do MC - conforme ja especificado.

--- GATILHO DA REGUA POR EVENTO (04/09) ---
Os 15 minutos do 1o lembrete contam a partir do evento SignatureSent (canal de contrato, W-000105), nao da mudanca de estagio da oportunidade. O cancelamento automatico no 5o dia permanece scheduled flow nativo.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-10 — Régua Automática de Lembretes de Assinatura e Expiração da Oportunidade (SLA 5 Dias) to US B2C-10 — Régua de Lembretes e Expiração da Oportunidade por SLA (5 Dias)
