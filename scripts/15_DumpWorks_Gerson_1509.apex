// 15 - DUMP (somente SELECT + System.debug) das works criadas pelo Gerson em 15/09 (W-000133 a W-000141), para validar
// e complementar as tecnicas (integracao/MuleSoft, CI/CD, arquitetura) e consolidar as duas de EPC nas US 51/52/55.
// Nada e alterado. Filtre o log por DMP15| e DUMP15| e mande tudo (Details sai em blocos de 250 caracteres).
Set<String> nomes = new Set<String>{ 'W-000133','W-000134','W-000135','W-000136','W-000137','W-000138','W-000139','W-000140','W-000141' };

for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Status__c, RecordType.Name, agf__Epic__r.Name,
                                  agf__Scrum_Team__r.Name, agf__Sprint__r.Name, agf__Assignee__r.Name, agf__Product_Tag__r.Name,
                                  agf__Story_Points__c, agf__Priority__c, agf__Due_Date__c, CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate
                           FROM agf__ADM_Work__c WHERE Name IN :nomes ORDER BY Name]) {
    nomes.remove(w.Name);
    System.debug('DMP15| ' + w.Name + ' | ' + w.agf__Subject__c);
    System.debug('DMP15| ' + w.Name + ' | rt=' + w.RecordType.Name + ' | status=' + w.agf__Status__c + ' | epic=' + w.agf__Epic__r.Name
        + ' | time=' + w.agf__Scrum_Team__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name
        + ' | tag=' + w.agf__Product_Tag__r.Name + ' | pontos=' + w.agf__Story_Points__c + ' | prioridade=' + w.agf__Priority__c
        + ' | due=' + w.agf__Due_Date__c + ' | criada por ' + w.CreatedBy.Name + ' em ' + w.CreatedDate.format('dd/MM HH:mm')
        + ' | alterada por ' + w.LastModifiedBy.Name + ' em ' + w.LastModifiedDate.format('dd/MM HH:mm'));
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    System.debug('DMP15| ' + w.Name + ' | details=' + det.length() + ' chars');
    for (Integer i = 0; i < det.length(); i += 250) {
        System.debug('DUMP15| ' + w.Name + ' | ' + det.substring(i, Math.min(i + 250, det.length())));
    }
    Integer nc = 0;
    for (agf__ADM_Acceptance_Criterion__c c : [SELECT Name, agf__Status__c, agf__Description__c FROM agf__ADM_Acceptance_Criterion__c WHERE agf__Work__c = :w.Id ORDER BY Name]) {
        nc++; System.debug('DMP15| ' + w.Name + ' | criterio | ' + c.Name + ' | ' + c.agf__Status__c + ' | ' + c.agf__Description__c);
    }
    System.debug('DMP15| ' + w.Name + ' | criterios=' + nc);
    // filhos com nome de campo variavel por versao do pacote: consulta dinamica em try/catch
    for (String q : new List<String>{
            'SELECT Id, Name, agf__Subject__c, agf__Status__c FROM agf__ADM_Task__c WHERE agf__Work__c = :wid',
            'SELECT Id, CreatedBy.Name, agf__Comment__c FROM agf__ADM_Comment__c WHERE agf__Work__c = :wid',
            'SELECT Id, agf__Theme__r.Name FROM agf__ADM_Theme_Assignment__c WHERE agf__Work__c = :wid' }) {
        try {
            Id wid = w.Id;
            for (SObject o : Database.query(q)) {
                System.debug('DMP15| ' + w.Name + ' | filho ' + o.getSObjectType() + ' | ' + JSON.serialize(o.getPopulatedFieldsAsMap()).left(400));
            }
        } catch (Exception e) { /* objeto/campo inexistente nesta versao: ignorar */ }
    }
}
for (String n : nomes) System.debug('DMP15| ' + n + ' | NAO ENCONTRADA');
System.debug('DMP15| FIM');
