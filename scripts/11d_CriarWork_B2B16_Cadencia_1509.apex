// 11d - Cria a work US B2B-16 (historia nova 29 de 10/09). Uma work por script (limite HTTP 431).
// Reexecutar e seguro (checa por Subject antes de criar). Rodar o script 10 antes.
agf__ADM_Work__c ref = [SELECT RecordTypeId, agf__Scrum_Team__c, agf__Product_Tag__c, agf__Assignee__c, agf__Epic__c
                        FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];

String subj = 'US B2B-16 — Cadência automática de notificações de assinatura ao cliente (proposta e contrato)';
String det =
      'US de negocio B2B (documento de 10/09, "Historias novas", historia 29; comentarios de negocio de 14/09 nas historias '
    + '3 e 15: regua via Marketing Cloud com templates, e-mail em D+2, D+4, D+7, D+15 e D+30 as 08h, nao "apos 24h"; nos '
    + 'demais dias o contato e do vendedor; reenvio manual e troca de e-mail permitidos). Complementa a W-000122 RN-05 '
    + '(regua interna ao GR e gestor) sem duplica-la. Fundamentacao no Salesforce Help: The Salesforce Data Event, '
    + 'Configure the Salesforce Data Event, Journey Settings, Sales and Service Cloud Activities, Schedule-Triggered Flows, '
    + 'Send Email Action, Daily Allocations for Email Alerts.\n\n'
    + 'NARRATIVA\n'
    + 'Como Gerente de Relacionamento, quero que o sistema envie ao cliente, com copia para mim, lembretes automaticos e '
    + 'cadenciados de assinatura de propostas e contratos pendentes, e pare no momento em que o documento for assinado, '
    + 'para que o ciclo Quote-to-Order encurte sem acompanhamento manual diario.\n\n'
    + 'CONTEXTO\n'
    + 'A W-000122 avisa GR e gestor; falta o contato com o cliente. O negocio pediu Marketing Cloud (templates e regua), '
    + 'fundacao do projeto (W-000092). Gatilho: envio da proposta (botao "Enviar proposta comercial ao cliente", W-000098) '
    + 'ou do envelope de contrato/aditivo (W-000105, TEC-CLM-01). Como Quote e Contract nao tem lookup de contato, e o '
    + 'Salesforce Data Event exige objeto com lookup para o Who (Contact), a entrada na jornada usa um registro proprio '
    + 'com o signatario.\n\n'
    + 'REGRAS DE NEGOCIO\n'
    + 'RN-01 Escopo: propostas (Quote enviada) e contratos/aditivos (envelope enviado), B2B.\n'
    + 'RN-02 D0: o envio cria um registro "Envio para Assinatura" (objeto custom) com Tipo (Proposta/Contrato), Data de '
    + 'Envio, Signatario (lookup Contact do Contact Role Signatario Legal, B2B-09), Quote ou Contract, Opportunity e Status = '
    + 'Pendente. Um registro por envio; novo envelope gera novo registro e reinicia a cadencia.\n'
    + 'RN-03 Cadencia ao cliente: D+2, D+4, D+7, D+15 e D+30 as 08:00 de Brasilia, e-mail ao signatario com copia ao GR, '
    + 'template por tipo de documento (W-000092). Nos demais dias o contato e do vendedor.\n'
    + 'RN-04 Entrada na jornada por Salesforce Data Event no objeto Envio para Assinatura (criacao, Status = Pendente), quem '
    + 'entra = Contact do lookup Signatario; dados da jornada: ID do envio, tipo, numero da cotacao/contrato, ID da '
    + 'Opportunity, GR e e-mail do GR, link do documento. Journey Settings: Contact Entry = "Re-entry only after exiting"; '
    + 'Default Email Address = "email attribute from Contacts" (a correcao de e-mail pelo GR vale no proximo disparo).\n'
    + 'RN-05 Quebra: callback de assinatura (W-000105), aceite da proposta (Quote.Status = Aceita, W-000098), recusa ou '
    + 'expiracao de 30 dias (W-000098/W-000122) atualizam Status para Assinado/Recusado/Expirado. Como a Data Extension do '
    + 'Data Event e preenchida so na entrada, a jornada verifica o Status atual (objeto sincronizado pelo Marketing Cloud '
    + 'Connect) num Decision Split imediatamente antes de cada e-mail e sai quando Status diferente de Pendente.\n'
    + 'RN-06 Registro: cada disparo gera Task Completed na Opportunity (WhatId do Journey Data) com assunto "Lembrete de '
    + 'assinatura D+N" pela Task/Object activity da jornada (assincrona, ate 24 h); o Envio para Assinatura recebe "Ultimo '
    + 'lembrete enviado" por Object activity (Simple Update) para auditoria imediata.\n'
    + 'RN-07 Reenvio manual e alteracao do e-mail do signatario pelo GR sao permitidos e nao reiniciam a cadencia; so novo '
    + 'envelope reinicia (RN-02).\n'
    + 'RN-08 A regua interna (GR 1/3/7 dias, gestor 15, expiracao 30) permanece na W-000122; esta US so envia ao cliente e '
    + 'copia ao GR.\n'
    + 'RN-09 Limites e pre-requisitos: Marketing Cloud Connect 5.496 ou superior; no maximo 80 jornadas por objeto; objeto e '
    + 'publico do entry source nao podem ser trocados depois de criados; Test Mode nao funciona com Salesforce Entry Source '
    + 'nem com "No re-entry" (teste em sandbox conectada com registros reais); o objeto Envio para Assinatura entra na '
    + 'sincronizacao do MC Connect; atividades Sales Cloud so retentam UNABLE_TO_LOCK_ROW.\n'
    + 'RN-10 Contingencia sem Marketing Cloud: schedule-triggered flow diario as 08:00 no fuso padrao da org sobre Envio para '
    + 'Assinatura com Status Pendente e dias desde o envio em {2,4,7,15,30}, Send Email com Organization-Wide Email Address '
    + '(configurado tambem em Process Automation Settings > Automated Process User Email Address), Email Template Name, '
    + 'Recipient ID = signatario, Related Record ID = Opportunity e Log Email on Send = True. Limite de 5.000 destinatarios '
    + 'externos por dia (GMT); copia ao GR nao conta.\n'
    + 'RN-11 LGPD: a jornada respeita a flag de opt-out do Contact enviada no evento; base legal e guarda conforme W-000083.\n'
    + 'RN-12 Lembretes nativos do DocuSign no CLM: os Vlocity CLM Custom Settings do Contract Type trazem '
    + 'DocuSignReminderEnabled (padrao Yes), DocuSignReminderDelay (2) e DocuSignReminderFrequency (1), cadencia uniforme '
    + 'que conflita com a regua D+2/4/7/15/30. Para os contract types B2B: DocuSignReminderEnabled = No (a regua desta US '
    + 'e a unica fonte de lembrete ao cliente), DocuSignExpireAfter = 30 e DocuSignExpireWarn alinhado, e '
    + 'ContractSignatureExpiredStatus/ContractSignatureVoidedStatus apontando para o status que a W-000122 usa ao expirar. '
    + 'Pre-requisito: confirmar que a assinatura da W-000105 passa pelo DocuSign do CLM; se for outro canal, a RN vale '
    + 'para o equivalente.\n\n'
    + 'ESPECIFICACAO TECNICA\n'
    + 'Objeto custom Envio_para_Assinatura__c (Tipo, Data de Envio, Signatario lookup Contact, Quote, Contract, Opportunity, '
    + 'Status, Ultimo Lembrete, Data de Encerramento); criacao por Integration Procedure no envio da proposta (W-000098) e do '
    + 'envelope (W-000105); record-triggered flow que atualiza Status pelo callback e pelo Quote.Status; jornada no Journey '
    + 'Builder com entry source Salesforce Data Event, esperas ate 08:00 de cada dia da regua, Decision Split por Status, '
    + 'atividades de e-mail, Task activity e Object activity; templates por tipo (W-000092); contingencia RN-10.\n\n'
    + 'DEPENDENCIAS: W-000092, W-000105, W-000098, W-000122, W-000126 (TEC-CLM-01), W-000066 (regua B2C), W-000083 (LGPD), '
    + 'Vlocity CLM Custom Settings por Contract Type (RN-12). '
    + 'RISCOS: callback atrasado ou sincronizacao do MC Connect fora de hora gera lembrete indevido (mitigado pelo Decision '
    + 'Split no envio); fuso da org precisa ser America/Sao_Paulo; Task na Opportunity pode atrasar ate 24 h. '
    + 'ESTIMATIVA: 5 Story Points.\n\n'
    + 'CRITERIOS DE ACEITE: 8 registros na lista Acceptance Criteria (script 12). Massa de teste: envios com Data de Envio '
    + 'manipulada para D+2, D+4 e D+30; assinatura via callback na vespera do D+15; org em fuso -03:00; log de e-mails as 08:00.';

List<agf__ADM_Work__c> ja = [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj];
if (!ja.isEmpty()) { System.debug('JA EXISTE: ' + ja[0].Name + ' | ' + subj); }
else {
    insert new agf__ADM_Work__c(agf__Subject__c = subj, agf__Details__c = det, agf__Status__c = 'New',
        RecordTypeId = ref.RecordTypeId, agf__Scrum_Team__c = ref.agf__Scrum_Team__c,
        agf__Product_Tag__c = ref.agf__Product_Tag__c, agf__Assignee__c = ref.agf__Assignee__c, agf__Epic__c = ref.agf__Epic__c);
    System.debug('CRIADA: ' + [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj][0].Name + ' | ' + subj);
}
