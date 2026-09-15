// 11b - Cria a work US B2B-14 (historia nova 27 de 10/09). Uma work por script (limite HTTP 431).
// Reexecutar e seguro (checa por Subject antes de criar). Rodar o script 10 antes.
agf__ADM_Work__c ref = [SELECT RecordTypeId, agf__Scrum_Team__c, agf__Product_Tag__c, agf__Assignee__c, agf__Epic__c
                        FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];

String subj = 'US B2B-14 — Aviso prévio de cancelamento B2B: prazo de 30/60/90 dias, janela de reversão, painel e corte automático';
String det =
      'US de negocio B2B (documento de 10/09, "Historias novas", historia 27; continuacao da W-000099; comentarios de '
    + 'negocio de 14/09 nas historias 4 e 13: entradas pela Celula de Retencao, Central de Cancelamento e GR restrito a '
    + 'carteira; Arquitetura nao atua na retencao). Fundamentacao no Salesforce Help: Scheduled Paths, Schedule-Triggered '
    + 'Flow Considerations, Asset-Based Ordering, Create an Asset-Based Order, Convert an Asset to a Quote or an Order, '
    + 'Overview of Canceled and Amended In-Flight Orders (PONR), Order Decomposition Configuration. ATENCAO: case '
    + 'Salesforce 473919801 (jun-jul/2026) mostra que producao nao tinha licenca de Industries OM; confirmar compra antes '
    + 'de planejar esta US para producao.\n\n'
    + 'NARRATIVA\n'
    + 'Como Central de Cancelamentos / Analista de Retencao BKO B2B, quero registrar o prazo de aviso previo do '
    + 'cancelamento corporativo, acompanhar a janela num painel e ter a desativacao tecnica e o Billing Stop disparados '
    + 'automaticamente so ao fim do prazo, para que o servico continue operante e faturado durante o aviso, a retencao '
    + 'tenha uma janela de reversao e o corte nao dependa de planilha.\n\n'
    + 'CONTEXTO\n'
    + 'A W-000099 cobre solicitacao, esteiras e multa e, na efetivacao, dispara o Billing Stop. No B2B ha aviso previo '
    + 'contratual de 30, 60 ou 90 dias entre a efetivacao e o corte, hoje em planilha. Esta US insere a janela entre a '
    + 'efetivacao e o corte, com reversao possivel e execucao automatica no D-Day.\n\n'
    + 'REGRAS DE NEGOCIO\n'
    + 'RN-01 Ao efetivar o cancelamento (fim das esteiras da W-000099) o usuario informa o Aviso Previo: 30, 60 ou 90 dias '
    + '(Custom Metadata). Data Fim do Aviso Previo = data de efetivacao + prazo, gravada na Opportunity de cancelamento e no Contract.\n'
    + 'RN-02 Status na janela: Contract Status "Em Aviso Previo" (valor custom na categoria Activated, contrato segue ativo '
    + 'em relatorios); Opportunity em "Aguardando Fim do Aviso Previo".\n'
    + 'RN-03 Durante a janela nada e submetido ao OM nem ao Customer Core. Motivo: ordem submetida so pode ser cancelada '
    + 'in-flight antes do Point of No Return e gera ordem suplementar com rollback. A ordem de desativacao nasce no D-Day.\n'
    + 'RN-04 Agendamento do corte: record-triggered flow no Contract com scheduled path, Time Source = Data Fim do Aviso '
    + 'Previo, offset 1 dia depois, condicao Status = "Em Aviso Previo", batch 200. No disparo, Integration Procedure '
    + 'converte os assets do contrato em ordem (Convert Asset to Order, Assets Action Type Change, acao Delete no root '
    + 'bundle; quantidades desabilitadas e one-time charges nao carregadas, comportamento padrao da conversao), submete '
    + 'ao OM (TEC-OM-01) e a decomposicao gera a ordem tecnica ao Customer Core pelo endpoint proprietario (TMF622 como '
    + 'mapa). Billing Stop segue a W-000099: so apos callback do Customer Core.\n'
    + 'RN-05 Reversao: acao "Reverter Cancelamento" para Retencao/BKO, Central de Cancelamentos e GR dono da conta. '
    + 'Exige motivo de retencao (lista da W-000096) e oferta aceita quando houver (CAT-RET-01, gera pedido de alteracao '
    + 'via W-000100); Contract volta a Activated e a Opportunity fecha como "Retido". Com a mudanca de status o registro '
    + 'deixa de atender a condicao do path e o agendamento e cancelado automaticamente, sem passo manual.\n'
    + 'RN-06 Renegociacao do prazo (ex.: 90 para 60 dias): alterar a Data Fim reagenda o corte para a nova data, desde '
    + 'que futura; data passada bloqueada por Validation Rule.\n'
    + 'RN-07 Painel: Lightning Dashboard e list views de contratos "Em Aviso Previo" com dias restantes (formula), GR, '
    + 'celula e MRR em risco. GR ve so a propria carteira (sharing por Account Owner e equipe); Retencao e Central veem tudo.\n'
    + 'RN-08 Apos o corte: Assets com provisioning status Deleted e status "Cancelado", Contract "Encerrado", Opportunity '
    + 'de cancelamento Ganha (churn efetivado), conforme W-000099.\n'
    + 'RN-09 Falha na execucao: a plataforma retenta o scheduled path em 15, 30, 60, 120 e 240 minutos; persistindo, o '
    + 'flow cria Task para o BKO e o registro fica em "Corte com Falha" no painel. Fallout de orquestracao e tratado no OM.\n'
    + 'RN-10 Reversao apos o D-Day (ordem ja submetida): so o BKO pode cancelar in-flight, e apenas antes do PONR; depois '
    + 'disso a reativacao e venda nova (W-000097 em diante).\n'
    + 'RN-11 Limites: 250.000 scheduled paths por 24 h; callouts em massa saem do OM/MuleSoft e nao do flow; Default '
    + 'Workflow User configurado.\n\n'
    + 'ESPECIFICACAO TECNICA\n'
    + 'Campos no Contract: Prazo de Aviso Previo (picklist), Data Fim do Aviso Previo (Date), Dias Restantes (formula), '
    + 'Motivo de Retencao; valores de Status "Em Aviso Previo" e "Encerrado"; record-triggered flow "Contrato - Corte por '
    + 'Aviso Previo" com scheduled path chamando Integration Procedure que usa a implementacao ABO (Convert Asset to Order, '
    + 'Delete) e o checkout do TEC-OM-01; Quick Action "Reverter Cancelamento" (screen flow) com Permission Set; Validation '
    + 'Rule para data passada; Custom Metadata dos prazos; Dashboard e list views com sharing por carteira; acompanhamento '
    + 'em Setup > Time-Based Automations e logs FLOW_SCHEDULED_PATH_QUEUED.\n\n'
    + 'DEPENDENCIAS: W-000099, W-000118 (TEC-OM-01), W-000088, W-000087, W-000128 (CAT-RET-01), W-000096, W-000123, '
    + 'W-000103 (Assets), W-000090 (perfis), licenca de Industries OM em producao. RISCOS: Customer Core sem execucao '
    + 'programada (assumido: Salesforce dispara no dia); contratos sem Asset nao geram ordem ABO; lista de entradas e '
    + 'alcadas com a Tayza (comentario de 14/09). ESTIMATIVA: 8 Story Points.\n\n'
    + 'CRITERIOS DE ACEITE: 8 registros na lista Acceptance Criteria (script 12). Massa de teste: cotacao de cancelamento '
    + 'aprovada com aviso de 30 dias; data manipulada em QA para o 31o dia; contrato com 60 dias e reversao; GR de outra '
    + 'carteira para o criterio 6.';

List<agf__ADM_Work__c> ja = [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj];
if (!ja.isEmpty()) { System.debug('JA EXISTE: ' + ja[0].Name + ' | ' + subj); }
else {
    insert new agf__ADM_Work__c(agf__Subject__c = subj, agf__Details__c = det, agf__Status__c = 'New',
        RecordTypeId = ref.RecordTypeId, agf__Scrum_Team__c = ref.agf__Scrum_Team__c,
        agf__Product_Tag__c = ref.agf__Product_Tag__c, agf__Assignee__c = ref.agf__Assignee__c, agf__Epic__c = ref.agf__Epic__c);
    System.debug('CRIADA: ' + [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj][0].Name + ' | ' + subj);
}
