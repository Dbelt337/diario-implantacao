// 13 - EXTRACAO COMPLETA das works (campos, Acceptance Criteria, comentarios, tasks).
// Somente SELECT + System.debug: nao grava nada. Rode com "Open Log"; o log e lido pelo
// tools/parse_ext_log.py, que gera JSON + markdown por work. Blocos de 400 chars por texto longo.
// Ajuste o intervalo em DE/ATE. Execute Anonymous tem limite de tamanho: nao acrescente comentarios.
String DE = 'W-000051', ATE = 'W-000117';
Integer BLK = 400;

void blocos(String w, String tipo, String chave, String txt) {
    if (txt == null) txt = '';
    Integer n = 0;
    if (txt.length() == 0) { System.debug('EXT| ' + w + ' | ' + tipo + ' | ' + chave + ' | 000 | '); return; }
    for (Integer i = 0; i < txt.length(); i += BLK) {
        n++;
        System.debug('EXT| ' + w + ' | ' + tipo + ' | ' + chave + ' | ' + String.valueOf(n).leftPad(3, '0') + ' | '
            + txt.substring(i, Math.min(i + BLK, txt.length())));
    }
}
void campo(String w, String chave, Object v) {
    System.debug('EXT| ' + w + ' | F | ' + chave + ' | ' + (v == null ? '' : String.valueOf(v)));
}

List<agf__ADM_Work__c> ws = [
    SELECT Id, Name, RecordType.Name, agf__Subject__c, agf__Details__c, agf__Description__c, agf__Status__c,
           agf__Priority__c, agf__Story_Points__c, agf__Priority_Rank__c, agf__Type__c,
           agf__Epic__r.Name, agf__Scrum_Team__r.Name, agf__Product_Tag__r.Name, agf__Sprint__r.Name,
           agf__Theme__r.Name, agf__Assignee__r.Name, agf__Product_Owner__r.Name, agf__QA_Engineer__r.Name,
           agf__Due_Date__c, agf__Related_URL__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name,
           (SELECT Id, Name, agf__Status__c, agf__Description__c, CreatedDate FROM agf__Acceptance_Criteria__r ORDER BY CreatedDate),
           (SELECT Id, CreatedDate, CreatedBy.Name, agf__Body__c FROM agf__Comment__r ORDER BY CreatedDate),
           (SELECT Id, Name, agf__Subject__c, agf__Status__c, agf__Assigned_To__r.Name, agf__Hours_Remaining__c FROM agf__Tasks__r ORDER BY CreatedDate)
    FROM agf__ADM_Work__c
    WHERE Name >= :DE AND Name <= :ATE
    ORDER BY Name];

System.debug('EXT| INICIO | works=' + ws.size() + ' | de=' + DE + ' | ate=' + ATE + ' | ' + Datetime.now().format('dd/MM/yyyy HH:mm'));
for (agf__ADM_Work__c w : ws) {
    String n = w.Name;
    campo(n, 'Id', w.Id);
    campo(n, 'RecordType', w.RecordType.Name);
    campo(n, 'Subject', w.agf__Subject__c);
    campo(n, 'Status', w.agf__Status__c);
    campo(n, 'Priority', w.agf__Priority__c);
    campo(n, 'StoryPoints', w.agf__Story_Points__c);
    campo(n, 'PriorityRank', w.agf__Priority_Rank__c);
    campo(n, 'Type', w.agf__Type__c);
    campo(n, 'Epic', w.agf__Epic__r == null ? null : w.agf__Epic__r.Name);
    campo(n, 'ScrumTeam', w.agf__Scrum_Team__r == null ? null : w.agf__Scrum_Team__r.Name);
    campo(n, 'ProductTag', w.agf__Product_Tag__r == null ? null : w.agf__Product_Tag__r.Name);
    campo(n, 'Sprint', w.agf__Sprint__r == null ? null : w.agf__Sprint__r.Name);
    campo(n, 'Theme', w.agf__Theme__r == null ? null : w.agf__Theme__r.Name);
    campo(n, 'Assignee', w.agf__Assignee__r == null ? null : w.agf__Assignee__r.Name);
    campo(n, 'ProductOwner', w.agf__Product_Owner__r == null ? null : w.agf__Product_Owner__r.Name);
    campo(n, 'QAEngineer', w.agf__QA_Engineer__r == null ? null : w.agf__QA_Engineer__r.Name);
    campo(n, 'DueDate', w.agf__Due_Date__c);
    campo(n, 'RelatedURL', w.agf__Related_URL__c);
    campo(n, 'CreatedDate', w.CreatedDate.format('dd/MM/yyyy HH:mm'));
    campo(n, 'CreatedBy', w.CreatedBy.Name);
    campo(n, 'LastModifiedDate', w.LastModifiedDate.format('dd/MM/yyyy HH:mm'));
    campo(n, 'LastModifiedBy', w.LastModifiedBy.Name);
    campo(n, 'DetailsChars', w.agf__Details__c == null ? 0 : w.agf__Details__c.length());
    campo(n, 'ACCount', w.agf__Acceptance_Criteria__r.size());
    campo(n, 'CommentCount', w.agf__Comment__r.size());
    campo(n, 'TaskCount', w.agf__Tasks__r.size());
    blocos(n, 'D', 'Details', w.agf__Details__c);
    blocos(n, 'D', 'Description', w.agf__Description__c);
    Integer i = 0;
    for (agf__ADM_Acceptance_Criterion__c ac : w.agf__Acceptance_Criteria__r) {
        i++;
        String k = 'AC' + String.valueOf(i).leftPad(2, '0');
        campo(n, k + '.Id', ac.Id);
        campo(n, k + '.Name', ac.Name);
        campo(n, k + '.Status', ac.agf__Status__c);
        campo(n, k + '.CreatedDate', ac.CreatedDate.format('dd/MM/yyyy HH:mm'));
        blocos(n, 'A', k + '.Description', ac.agf__Description__c);
    }
    i = 0;
    for (agf__ADM_Comment__c c : w.agf__Comment__r) {
        i++;
        String k = 'CM' + String.valueOf(i).leftPad(2, '0');
        campo(n, k + '.Autor', c.CreatedBy.Name + ' ' + c.CreatedDate.format('dd/MM/yyyy HH:mm'));
        blocos(n, 'C', k + '.Body', c.agf__Body__c);
    }
    i = 0;
    for (agf__ADM_Task__c t : w.agf__Tasks__r) {
        i++;
        String k = 'TK' + String.valueOf(i).leftPad(2, '0');
        campo(n, k, t.Name + ' | ' + t.agf__Subject__c + ' | ' + t.agf__Status__c + ' | '
            + (t.agf__Assigned_To__r == null ? '' : t.agf__Assigned_To__r.Name) + ' | ' + t.agf__Hours_Remaining__c);
    }
    System.debug('EXT| ' + n + ' | FIM');
}
System.debug('EXT| FIM | works=' + ws.size());
