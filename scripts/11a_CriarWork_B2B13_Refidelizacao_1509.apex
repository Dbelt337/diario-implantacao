// 11a - Cria a work US B2B-13 (historia nova 26 de 10/09). Uma work por script (limite HTTP 431).
// Reexecutar e seguro (checa por Subject antes de criar). Rodar o script 10 antes.
agf__ADM_Work__c ref = [SELECT RecordTypeId, agf__Scrum_Team__c, agf__Product_Tag__c, agf__Assignee__c, agf__Epic__c
                        FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];

String subj = 'US B2B-13 — Refidelização pura e simples B2B: renovação de prazo sem alteração de escopo (aditivo de tempo)';
String det =
      'US de negocio B2B (documento de 10/09, "Historias novas", historia 26; decisoes de 10/09 na W-000100 notas (c) '
    + 'e (f); comentarios de negocio de 14/09 na historia 14: refidelizacao cobre todas as etiquetas do contrato '
    + 'guarda-chuva e prazo "e outros"). Fundamentacao no Salesforce Help: CLM Overview, To Amend Frame Agreements, '
    + 'Contract State Model, Contract Fields, Scheduled Paths, Reprice Existing Prices, ABP com Time Plan/Time Policy.\n\n'
    + 'NARRATIVA\n'
    + 'Como Gerente de Relacionamento, quero renovar o prazo de fidelidade de um contrato B2B ativo, sem alterar '
    + 'produtos, quantidades nem valores, escolhendo 12, 24, 36, 48, 60 meses ou prazo customizado, com aditivo de '
    + 'tempo gerado pelo sistema e aprovacao do BKO, para estender a vigencia juridica e garantir o MRR sem abrir '
    + 'ordem de alteracao tecnica.\n\n'
    + 'CONTEXTO\n'
    + 'A W-000100 trata refidelizacao so junto com upgrade. Nao existe fluxo de renovacao de prazo sem mexer no '
    + 'escopo. O contrato B2B e guarda-chuva: a renovacao vale para todas as etiquetas e ativos. Sem Arquitetura, '
    + 'sem carrinho e sem Order Management: so datas, aditivo, aprovacao e sincronizacao de vigencia com o Customer Core.\n\n'
    + 'REGRAS DE NEGOCIO\n'
    + 'RN-01 Entrada pela Visao 360 do grupo economico (B2B-10) no contrato. Perfis: GR dono da conta e gestor; SDR nao.\n'
    + 'RN-02 Elegibilidade: Contract com Status na categoria Activated e sem outra Opportunity aberta de record type '
    + 'Alteracao Contratual ou Refidelizacao Simples para o mesmo contrato; havendo, bloqueia e aponta a oportunidade.\n'
    + 'RN-03 Prazo: picklist 12/24/36/48/60 meses ou "Outro" (numero de meses) com justificativa obrigatoria (W-000100 c).\n'
    + 'RN-04 Escopo travado: OmniScript exibe os ativos do contrato em somente leitura (nome, atributos, MRC). Sem carrinho, '
    + 'sem adicionar/remover item, sem alterar preco. Mudanca de escopo encerra o fluxo e vai para MACD (W-000100/W-000125).\n'
    + 'RN-05 Vigencia: grava novo Contract Term (months) e Contract Start Date da vigencia renovada; Contract End Date '
    + 'calculada pela configuracao padrao (start + term). Data Fim de Fidelidade (campo custom no Contract e nos Assets) '
    + 'atualizada em todas as etiquetas do contrato.\n'
    + 'RN-06 Aditivo de tempo pelo Amend Frame Agreement do Industries CLM (TEC-CLM-01) com contract type proprio '
    + '"Aditivo de Refidelizacao": nasce ligado ao master (lista Amendment Contracts); no aditivo o sistema grava Contract '
    + 'Start Date e Contract Term e estende a Effective End Date dos descontos contract-based do frame agreement (desconto '
    + 'de fidelidade B2B, W-000100 g). O Amend nao copia termos gerais: o template do aditivo carrega as clausulas. '
    + 'Aceite pelo signatario legal (B2B-09).\n'
    + 'RN-07 Ciclo pelo Contract State Model do CLM: Rascunho > Aguardando Aceite > Aguardando BKO > Ativo (ou Rejeitado), '
    + 'com Vlocity Actions por estado e Applicable User Profile: GR so cria e envia; "Aprovar Aditivo" aparece apenas para '
    + 'o perfil BKO no estado Aguardando BKO. BKO so le, nao edita valores (W-000101).\n'
    + 'RN-08 Sincronizacao: na transicao para Ativo, Integration Procedure envia as novas datas de vigencia ao Customer Core '
    + 'pelo endpoint proprietario via MuleSoft (decisao 04/09, W-000087); TMF651 e mapa de capacidade. So com retorno 200 '
    + 'o contrato passa a "Renovado" e a oportunidade a Ganha.\n'
    + 'RN-09 Nenhuma ordem tecnica, nenhuma tarefa de Arquitetura, nenhuma submissao ao OM.\n'
    + 'RN-10 Alerta pre-vencimento: scheduled path no Contract com Time Source = Data Fim de Fidelidade e offset de 60 dias '
    + 'antes (Custom Metadata) cria Task ao GR; o path e cancelado automaticamente se o contrato deixar de atender '
    + '(renovado, cancelado) e reagendado se a data mudar.\n'
    + 'RN-11 Desconto de fidelidade: no B2B e contract-based discount do frame agreement e a RN-06 estende sua vigencia sem '
    + 'tocar nos assets. Se algum ativo tiver ajuste de promocao com Time Plan/Time Policy (Source = ABP), a nova duracao e '
    + 'aplicada pelo Repricing Batch Processor restrito aos assets da conta, em lotes de ate 20 line items (o repricing '
    + 'atualiza as datas de efetividade dos ajustes de promocao). Fora desse caso, nenhum repricing de assets: manter '
    + '"Retain Original Price during MACD".\n'
    + 'RN-12 Sem multa (nao ha alteracao de escopo nem cancelamento). Reajuste financeiro nao tramita aqui (W-000100 b).\n\n'
    + 'ESPECIFICACAO TECNICA\n'
    + 'Opportunity record type "Refidelizacao Simples" criada da 360; OmniScript "Renovacao Contratual B2B" com FlexCard de '
    + 'ativos somente leitura (Integration Procedure por Contract e Asset Reference ID); campos custom no Contract: Data Fim '
    + 'de Fidelidade, Prazo de Fidelidade (meses), Justificativa de Prazo; Validation Rule para RN-02; Vlocity CLM Amend com '
    + 'contract type "Aditivo de Refidelizacao" e template proprio (TEC-CLM-01, W-000106); Contract State Model e Vlocity '
    + 'Actions por perfil; Integration Procedure de sincronizacao via Named Credential MuleCallout / IntegrationConfig__mdt; '
    + 'record-triggered flow no Contract com scheduled path (RN-10); Custom Metadata para offset e lista de prazos.\n\n'
    + 'DEPENDENCIAS: W-000123 (B2B-10), W-000100, W-000126 (TEC-CLM-01), W-000122 (B2B-09), W-000101 (BKO), W-000087, '
    + 'W-000103 (Assets com fidelidade), P1 do Joel (prazo de contrato na oferta). RISCOS: Customer Core devolver vigencias '
    + 'e aceitar update de datas; contratos sem Asset sincronizado nao renovam pela 360; CLM precisa estar ativo na org '
    + '(verificacao de 15/09). ESTIMATIVA: 8 Story Points.\n\n'
    + 'CRITERIOS DE ACEITE: 9 registros na lista Acceptance Criteria (script 12). Massa de teste: Business Account com '
    + 'contrato de conectividade ativo ha 12 meses e 3 assets; renovacao para 36 meses; usuario BKO; contrato com '
    + 'oportunidade de upgrade aberta para o criterio 1.';

List<agf__ADM_Work__c> ja = [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj];
if (!ja.isEmpty()) { System.debug('JA EXISTE: ' + ja[0].Name + ' | ' + subj); }
else {
    insert new agf__ADM_Work__c(agf__Subject__c = subj, agf__Details__c = det, agf__Status__c = 'New',
        RecordTypeId = ref.RecordTypeId, agf__Scrum_Team__c = ref.agf__Scrum_Team__c,
        agf__Product_Tag__c = ref.agf__Product_Tag__c, agf__Assignee__c = ref.agf__Assignee__c, agf__Epic__c = ref.agf__Epic__c);
    System.debug('CRIADA: ' + [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj][0].Name + ' | ' + subj);
}
