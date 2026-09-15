# US B2B-16 — Cadência automática de notificações de assinatura ao cliente (proposta e contrato)

| Campo | Valor |
|---|---|
| Work | (a criar no Agile Accelerator) |
| Épico | B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente |
| Time (Scrum Team) | SysMap |
| Status | New |
| Responsável | a definir |
| Documento gerado em | 15/09/2026 |

US de negócio B2B (documento de 10/09, "Histórias novas", história 29; comentários de negócio de 14/09 nas histórias 3 e 15: régua via Marketing Cloud com templates, e-mail em D+2, D+4, D+7, D+15 e D+30 às 08h, não "após 24h"; nos demais dias o contato é do vendedor; reenvio manual e troca de e-mail permitidos). Complementa a W-000122 RN-05 (régua interna ao GR e gestor) sem duplicá-la. Fundamentação técnica em `docs/2026-09-15-fundamentacao-tecnica-historias-26-29.md`.

## Descrição
Como Gerente de Relacionamento
Quero que o sistema envie ao cliente, com cópia para mim, lembretes automáticos e cadenciados de assinatura de propostas e contratos pendentes, e pare no momento em que o documento for assinado
Para que o ciclo Quote-to-Order encurte sem acompanhamento manual diário.

## Contexto e Cenário de Negócio
A W-000122 avisa o GR e o gestor. Falta o contato com o cliente. O negócio pediu Marketing Cloud (templates e régua), que já é fundação do projeto (W-000092). O gatilho é o envio da proposta (botão "Enviar proposta comercial ao cliente", W-000098) ou do envelope de contrato/aditivo (W-000105, TEC-CLM-01). Como Quote e Contract não têm lookup de contato, a entrada na jornada precisa de um registro que tenha o signatário como Contact.

## Regras de Negócio Associadas
RN-01 Escopo: propostas comerciais (Quote enviada) e contratos e aditivos (envelope enviado), B2B.
RN-02 D0: o envio cria um registro "Envio para Assinatura" (objeto custom) com Tipo (Proposta/Contrato), Data de Envio, Signatário (lookup Contact, do Contact Role Signatário Legal da B2B-09), Quote ou Contract, Oportunidade e Status = Pendente. Um registro por envio; reenvio de novo envelope gera novo registro e reinicia a cadência.
RN-03 Cadência ao cliente: D+2, D+4, D+7, D+15 e D+30, sempre às 08:00 de Brasília, e-mail ao signatário com cópia ao GR, template por tipo de documento (W-000092). Nos demais dias o contato é do vendedor.
RN-04 Entrada na jornada por Salesforce Data Event no objeto "Envio para Assinatura" (criação, Status = Pendente), quem entra = Contact do lookup Signatário; dados da jornada: tipo, número da cotação/contrato, GR e e-mail do GR, link do documento.
RN-05 Quebra da cadência: callback de assinatura (W-000105), aceite da proposta (Quote.Status = Aceita, W-000098), recusa ou expiração de 30 dias (W-000098/W-000122) atualizam Status do registro para Assinado/Recusado/Expirado; o critério de saída da jornada é Status diferente de Pendente. Nenhum envio ocorre após a saída.
RN-06 Registro: cada disparo gera Task Completed na Oportunidade com assunto "Lembrete de assinatura D+N" e data, criada pela atividade Sales Cloud da jornada.
RN-07 Reenvio manual e alteração do e-mail do signatário pelo GR são permitidos e não reiniciam a cadência; só um novo envelope reinicia (RN-02).
RN-08 A régua interna (GR em 1, 3 e 7 dias, gestor em 15, expiração em 30) permanece na W-000122; esta US não envia nada a usuários internos além da cópia.
RN-09 Limites e pré-requisitos: Marketing Cloud Connect na versão 5.496 ou superior; no máximo 80 jornadas por objeto; o objeto e o público do entry source não podem ser trocados depois de criados; Test Mode não funciona com Salesforce Entry Source, então o teste é em sandbox conectada com registros reais.
RN-10 Contingência sem Marketing Cloud: schedule-triggered flow diário às 08:00 no fuso padrão da org sobre "Envio para Assinatura" com Status Pendente e dias desde o envio em {2,4,7,15,30}, com Send Email usando Organization-Wide Email Address (configurado também em Process Automation Settings), Email Template Name, Recipient ID = signatário, Related Record ID = Oportunidade e Log Email on Send = True (registra na timeline). Limite de 5.000 destinatários externos por dia em GMT; cópia ao GR não conta.
RN-11 LGPD: a jornada respeita a flag de opt-out do Contact enviada no evento; base legal e guarda conforme W-000083.

## Especificação Técnica (Salesforce)
Objeto custom Envio_para_Assinatura__c (Tipo, Data de Envio, Signatário lookup Contact, Quote, Contract, Opportunity, Status, Data de Encerramento); criação por Integration Procedure no envio da proposta (W-000098) e no envio do envelope (W-000105); record-triggered flow que atualiza Status a partir do callback (W-000105) e do Quote.Status; jornada no Journey Builder com entry source Salesforce Data Event, esperas até 08:00 de cada dia da régua, atividades de e-mail e atividade Sales Cloud de criação de Task, saída por Status; templates de e-mail por tipo (W-000092); contingência: schedule-triggered flow + Send Email (RN-10), org-wide address e Automated Process User Email Address configurados.

## Dependências, Riscos e Estimativa
Dependências: W-000092 (Marketing Cloud Connect, jornadas base, templates), W-000105 (canal e callback de assinatura), W-000098 (botão de envio e validade 30 dias), W-000122 (signatário legal e régua interna), W-000126 (TEC-CLM-01 envelope de aditivo), W-000066 (régua B2C, mesma mecânica), W-000083 (LGPD).
Riscos: callback de assinatura atrasado gera lembrete indevido a quem já assinou; fuso da org precisa ser America/Sao_Paulo para a régua bater com 08:00; a página de Journey Settings (critério de saída) e a de Sales and Service Cloud Activities (Task) ainda não foram lidas (pendência técnica P-B).
Estimativa: 5 Story Points.

## Critérios de Aceite (formato Agile Accelerator: Name | Status | Description)

| Name | Status | Description |
|---|---|---|
| Critério 1 — D0 | New | Dado uma proposta enviada pelo botão "Enviar proposta comercial ao cliente", quando o envio conclui, então existe um registro Envio para Assinatura com Status Pendente, o signatário legal como contato e o Contact entrou na jornada. |
| Critério 2 — D+7 às 08:00 | New | Dado um envio com Status Pendente há exatos 7 dias, quando o relógio marca 08:00 de Brasília, então o signatário recebe o e-mail do template de proposta com cópia ao GR e uma Task Completed "Lembrete de assinatura D+7" é criada na Oportunidade. |
| Critério 3 — Quebra por assinatura | New | Dado um envio com lembrete D+15 previsto para amanhã, quando o callback de assinatura chega hoje à tarde, então o Status muda para Assinado, o Contact sai da jornada e nenhum e-mail é enviado amanhã. |
| Critério 4 — Expiração | New | Dado um envio pendente há 30 dias, quando o D+30 dispara, então é o último e-mail e o Status passa a Expirado pela regra da W-000098. |
| Critério 5 — Reenvio manual | New | Dado um envio pendente em D+5, quando o GR reenvia manualmente o mesmo envelope após corrigir o e-mail do signatário, então a cadência continua contando do envio original e o próximo lembrete é D+7. |
| Critério 6 — Novo envelope | New | Dado um envio pendente, quando um novo envelope é gerado, então o registro anterior é encerrado e um novo D0 começa. |
| Critério 7 — Contingência | New | Dado o Marketing Cloud indisponível e a contingência ativa, quando o schedule-triggered flow roda às 08:00, então os envios com 2, 4, 7, 15 ou 30 dias recebem o e-mail pelo endereço organizacional, com o e-mail registrado na Oportunidade e sem envio a quem já assinou. |

Massa de teste sugerida: Oportunidades com envios cuja Data de Envio é manipulada para simular D+2, D+4 e D+30; assinatura via callback no dia anterior ao D+15; org em fuso -03:00; verificação do log de e-mails às 08:00.
