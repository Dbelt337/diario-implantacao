// 11c - Cria a work US B2B-15 (historia nova 28 de 10/09). Uma work por script (limite HTTP 431).
// Reexecutar e seguro (checa por Subject antes de criar). Rodar o script 10 antes.
agf__ADM_Work__c ref = [SELECT RecordTypeId, agf__Scrum_Team__c, agf__Product_Tag__c, agf__Assignee__c, agf__Epic__c
                        FROM agf__ADM_Work__c WHERE Name = 'W-000122' LIMIT 1];

String subj = 'US B2B-15 — Condições especiais de faturamento e intervalos de cobrança na cotação B2B';
String det =
      'US de negocio B2B (documento de 10/09, "Historias novas", historia 28; comentario de negocio de 14/09 na historia 8: '
    + 'parametros de faturamento sao preenchidos na etapa "dados de faturamento, fidelidade e tempo de contrato", depois do '
    + 'carrinho; W-000081 B2C-24 mantem "Mensal" somente leitura no B2C; W-000125 RN-02: nenhum calculo financeiro no '
    + 'Salesforce). Fundamentacao no Salesforce Help: Pricing Definition, Create a Pricing Variable (Charge Type Recurring + '
    + 'Frequency), Price Assignment and the Cart, Order Decomposition Configuration, Approval Process Record Locking.\n\n'
    + 'NARRATIVA\n'
    + 'Como Gerente de Relacionamento / Backoffice B2B, quero parametrizar na cotacao corporativa o intervalo de cobranca '
    + '(mensal, bimestral, trimestral, semestral, anual) e a condicao de vencimento, com aprovacao quando fugir do padrao, '
    + 'para que contas governamentais e grandes grupos sejam faturados conforme o contrato sem ajuste manual no legado.\n\n'
    + 'CONTEXTO E DECISAO DE DESENHO\n'
    + 'No Industries CPQ a frequencia de cobranca e propriedade da pricing variable (Charge Type Recurring + Frequency) da '
    + 'price list entry, ou seja, definicao de catalogo, nao escolha por cotacao. Criar cinco pricing variables e price '
    + 'list entries por frequencia multiplicaria o catalogo e contraria a precificacao por atributo sem produto duplicado '
    + '(CAT-CPX-01). Decisao: o preco da cotacao continua o recorrente mensal da price list; intervalo de cobranca e '
    + 'condicao de vencimento sao parametros contratuais do header (Quote > Order > Contract) que viajam no handoff e sao '
    + 'aplicados pelo motor de cobranca do SAP/Customer Core.\n\n'
    + 'REGRAS DE NEGOCIO\n'
    + 'RN-01 Campos no header da Quote, preenchidos pelo GR na etapa de dados de faturamento apos o carrinho: Intervalo de '
    + 'Cobranca (Mensal padrao, Bimestral, Trimestral, Semestral, Anual); Condicao de Vencimento (Mes Corrente padrao, Mes '
    + 'Seguinte); Dia de Vencimento (lista em Custom Metadata); Tipo de Faturamento (Padrao, Orgao Publico, Conglomerado).\n'
    + 'RN-02 O preco das linhas nao muda: continua o MRC mensal (pricing variable recorrente mensal). Campo formula '
    + 'informativo "Valor por ciclo" = MRC x meses do intervalo. Nenhuma pricing variable, price list entry ou adjustment '
    + 'e criada por frequencia.\n'
    + 'RN-03 Combinacao fora do padrao (intervalo diferente de Mensal, vencimento diferente de Mes Corrente ou tipo Orgao '
    + 'Publico/Conglomerado) bloqueia a aprovacao expressa: Approval Process com criterio de entrada roteia ao BKO ou '
    + 'Gestor Financeiro, justificativa obrigatoria e record lock durante a aprovacao.\n'
    + 'RN-04 Apos aprovacao os campos ficam somente leitura (FLS para o GR e Validation Rule por status); alterar exige '
    + 'abandonar a cotacao e gerar cotacao filha (W-000098).\n'
    + 'RN-05 Propagacao: campos mapeados de Quote para Order e Contract pelo Field Mapper do ABO e incluidos no payload de '
    + 'handoff do Imputar Venda (W-000101) e da decomposicao (W-000088) como campos de header, com as chaves acordadas com '
    + 'o SAP (Billing Frequency, Payment Terms). Nao sao atributos de produto e nao passam pelas mapping rules de produto.\n'
    + 'RN-06 De-para de valores Salesforce > SAP em Custom Metadata, mantido com Rodrigo/fiscal; valor sem de-para bloqueia '
    + 'o handoff com mensagem.\n'
    + 'RN-07 Pro-rata em ciclos longos e apurado pelo billing (SAP), nao no Salesforce (W-000125 RN-02); o Salesforce so '
    + 'envia a data de inicio de vigencia.\n'
    + 'RN-08 Elegibilidade: intervalos nao mensais so para Business Account; Consumer Account mantem Mensal somente leitura '
    + '(W-000081).\n'
    + 'RN-09 Multi-site: parametros do master quote valem para todos os grupos, salvo override por grupo com a mesma alcada '
    + 'da RN-03.\n\n'
    + 'ESPECIFICACAO TECNICA\n'
    + 'Campos custom em Quote, Order e Contract (mesmos API names); passo do OmniScript de dados de faturamento (W-000081 '
    + 'estendido para B2B); formula "Valor por ciclo"; Approval Process "Condicoes de Faturamento Nao Padrao" com record '
    + 'lock; Validation Rules (RN-04, RN-08); Field Mapper do ABO para Quote > Order > Asset/Contract; DataRaptor Transform '
    + 'do handoff (W-000101/W-000088) com os campos de header; Custom Metadata de de-para SAP e de dias de vencimento.\n\n'
    + 'DEPENDENCIAS: W-000081, W-000098, W-000101, W-000088, W-000121 (CAT-CPX-01), Rodrigo/fiscal e SAP (chaves de Billing '
    + 'Frequency e Payment Terms). RISCOS: SAP/Customer Core precisam absorver as novas chaves; contratos estaduais/federais '
    + 'com descricoes fiscais distintas por ciclo (ja tratadas por linha na W-000101). ESTIMATIVA: 5 Story Points.\n\n'
    + 'CRITERIOS DE ACEITE: 7 registros na lista Acceptance Criteria (script 12). Massa de teste: cotacoes "Mensal/Mes '
    + 'Corrente", "Trimestral/Mes Seguinte" e "Anual"; conta Consumer para o criterio 7; auditoria do payload no SAP em sandbox.';

List<agf__ADM_Work__c> ja = [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj];
if (!ja.isEmpty()) { System.debug('JA EXISTE: ' + ja[0].Name + ' | ' + subj); }
else {
    insert new agf__ADM_Work__c(agf__Subject__c = subj, agf__Details__c = det, agf__Status__c = 'New',
        RecordTypeId = ref.RecordTypeId, agf__Scrum_Team__c = ref.agf__Scrum_Team__c,
        agf__Product_Tag__c = ref.agf__Product_Tag__c, agf__Assignee__c = ref.agf__Assignee__c, agf__Epic__c = ref.agf__Epic__c);
    System.debug('CRIADA: ' + [SELECT Name FROM agf__ADM_Work__c WHERE agf__Subject__c = :subj][0].Name + ' | ' + subj);
}
