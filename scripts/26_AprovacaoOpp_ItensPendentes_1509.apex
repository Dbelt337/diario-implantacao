// 26 - Fase 3 do diagnostico da Opportunity 006V200000yiZh3IAE (producao). O script 25 mostrou que a aprovacao comercial B2B
// e um Flow Approval Process ("[Oportunidade] Controle de filas aprovacao", tipo ApprovalWorkflow, RecordAfterSave), nao um
// Approval Process classico: por isso nao ha ProcessInstance. O aprovador vem do campo Opportunity.ManagerAccount__c
// ("Gerente da Conta"), que esta com o proprio dono (Hermes); na Conta, AccountManager__c = Samuel Helbig.
// Este script lista os registros do flow approval (ApprovalSubmission / ApprovalWorkItem) e de orquestracao
// (FlowOrchestrationInstance / FlowOrchestrationWorkItem) da oportunidade, com TODOS os campos preenchidos, para saber o
// nome do campo de designado e se e atualizavel; e conta quantas outras oportunidades abertas tem o mesmo desvio.
// Somente leitura. Filtre o log por APR26|.
Id oppId = '006V200000yiZh3IAE';
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

void dump(String prefixo, String objeto, String filtro) {
    if (!gd.containsKey(objeto.toLowerCase())) { System.debug('APR26| ' + prefixo + ' | objeto ' + objeto + ' nao existe nesta org'); return; }
    Schema.DescribeSObjectResult d = gd.get(objeto.toLowerCase()).getDescribe();
    List<String> campos = new List<String>();
    for (String f : d.fields.getMap().keySet()) campos.add(f);
    try {
        List<SObject> rs = Database.query('SELECT ' + String.join(campos, ', ') + ' FROM ' + objeto + ' WHERE ' + filtro);
        System.debug('APR26| ' + prefixo + ' | ' + objeto + ' | ' + rs.size() + ' registro(s)');
        for (SObject r : rs) {
            Map<String, Object> m = r.getPopulatedFieldsAsMap();
            List<String> pares = new List<String>();
            for (String k : m.keySet()) if (m.get(k) != null && k != 'attributes') pares.add(k + '=' + String.valueOf(m.get(k)));
            System.debug('APR26|   ' + String.join(pares, ' | ').left(1500));
        }
        // quais campos sao atualizaveis (para a reatribuicao)
        List<String> upd = new List<String>();
        for (String f : campos) { Schema.DescribeFieldResult fd = d.fields.getMap().get(f).getDescribe(); if (fd.isUpdateable()) upd.add(fd.getName()); }
        System.debug('APR26| ' + prefixo + ' | campos atualizaveis de ' + objeto + ': ' + String.join(upd, ', '));
    } catch (Exception e) { System.debug('APR26| ' + prefixo + ' | consulta de ' + objeto + ' falhou: ' + e.getMessage().left(200)); }
}

// flow approval process (Winter 25+): submissao, detalhes e itens de trabalho
dump('SUBMISSAO', 'ApprovalSubmission', 'RelatedRecordId = \'' + oppId + '\'');
List<Id> subIds = new List<Id>();
try { for (SObject s : Database.query('SELECT Id FROM ApprovalSubmission WHERE RelatedRecordId = :oppId')) subIds.add(s.Id); }
catch (Exception e) { System.debug('APR26| ApprovalSubmission falhou: ' + e.getMessage().left(150)); }
if (!subIds.isEmpty()) {
    String lista = '(\'' + String.join(subIds, '\',\'') + '\')';
    dump('DETALHE', 'ApprovalSubmissionDetail', 'ApprovalSubmissionId IN ' + lista);
    dump('ITEM', 'ApprovalWorkItem', 'ApprovalSubmissionId IN ' + lista);
} else System.debug('APR26| nenhuma ApprovalSubmission para a oportunidade');
// interviews do flow ligadas a oportunidade (FlowRecordRelation) e orquestracao a partir delas
List<Id> intIds = new List<Id>();
try {
    for (SObject r : Database.query('SELECT FlowInterviewId FROM FlowRecordRelation WHERE RelatedRecordId = :oppId')) intIds.add((Id) r.get('FlowInterviewId'));
} catch (Exception e) { System.debug('APR26| FlowRecordRelation falhou: ' + e.getMessage().left(150)); }
System.debug('APR26| interviews ligadas a oportunidade: ' + intIds.size());
if (!intIds.isEmpty()) {
    String lista = '(\'' + String.join(intIds, '\',\'') + '\')';
    dump('INTERVIEW', 'FlowInterview', 'Id IN ' + lista);
    dump('ORQUESTRACAO', 'FlowOrchestrationInstance', 'InterviewId IN ' + lista);
    List<Id> orqIds = new List<Id>();
    try {
        for (SObject r : Database.query('SELECT Id FROM FlowOrchestrationInstance WHERE InterviewId IN :intIds')) orqIds.add(r.Id);
    } catch (Exception e) { System.debug('APR26| FlowOrchestrationInstance por InterviewId falhou: ' + e.getMessage().left(150)); }
    if (!orqIds.isEmpty()) {
        String lo = '(\'' + String.join(orqIds, '\',\'') + '\')';
        dump('ETAPA ORQ', 'FlowOrchestrationStageInstance', 'FlowOrchestrationInstanceId IN ' + lo);
        dump('ITEM ORQ', 'FlowOrchestrationWorkItem', 'FlowOrchestrationInstanceId IN ' + lo);
    }
}
// itens de orquestracao pendentes atribuidos ao dono ou ao gerente, independentemente do vinculo com a oportunidade
dump('ITENS ORQ DO DONO/GERENTE', 'FlowOrchestrationWorkItem', 'Status = \'Assigned\' AND AssigneeId IN (\'005V200000KJxorIAD\', \'005V200000JWLWDIA5\')');

// abrangencia: outras oportunidades B2B abertas em "Aprovacao comercial" com Gerente da Conta = dono
Integer n = 0;
for (Opportunity x : [SELECT Id, Name, OwnerId, Owner.Name, ManagerAccount__c, ManagerAccount__r.Name, Account.AccountManager__r.Name, StageName, LastModifiedDate
                      FROM Opportunity WHERE IsClosed = false AND StageName = 'Aprovação comercial' ORDER BY LastModifiedDate]) {
    Boolean desvio = x.ManagerAccount__c == x.OwnerId;
    if (desvio) n++;
    System.debug('APR26| EM APROVACAO COMERCIAL | ' + x.Name.left(60) + ' | dono=' + x.Owner.Name + ' | gerente da conta (opp)=' + x.ManagerAccount__r.Name
        + ' | gerente da conta (conta)=' + x.Account.AccountManager__r.Name + (desvio ? ' | DESVIO: gerente = dono' : '') + ' | ' + x.LastModifiedDate.format('dd/MM'));
}
System.debug('APR26| RESULTADO: ' + n + ' oportunidade(s) em Aprovacao comercial com Gerente da Conta = dono.');
