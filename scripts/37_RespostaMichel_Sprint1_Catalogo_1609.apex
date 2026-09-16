// 37 - Base para responder ao Michel (16/09): o que esta na "Sprint 1 - SysMap (15-26/09)", o que esta no epico de Catalogo
// e a situacao das 6 works que ele cita como excluidas (W-000041 a 044, W-000138 e 139): Lixeira e prazo de restauracao.
// Somente SELECT + System.debug. Filtre o log por MIC37|.
String SPRINT = 'Sprint 1 - SysMap (15-26/09)';
Set<String> seis = new Set<String>{'W-000041', 'W-000042', 'W-000043', 'W-000044', 'W-000138', 'W-000139'};

System.debug('MIC37| === WORKS NA SPRINT "' + SPRINT + '" ===');
for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c, agf__Status__c, agf__Epic__r.Name, agf__Scrum_Team__r.Name, agf__Assignee__r.Name
                           FROM agf__ADM_Work__c WHERE agf__Sprint__r.Name = :SPRINT ORDER BY Name]) {
    System.debug('MIC37| SPRINT ' + w.Name + ' | ' + w.agf__Status__c + ' | epico=' + w.agf__Epic__r.Name + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | resp=' + w.agf__Assignee__r.Name + ' | ' + (w.agf__Subject__c == null ? '' : w.agf__Subject__c.left(80)));
}
System.debug('MIC37| === WORKS DO EPICO DE CATALOGO (todas as sprints) ===');
for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c, agf__Status__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name
                           FROM agf__ADM_Work__c WHERE agf__Epic__r.Name LIKE '%Cat_logo%' ORDER BY Name]) {
    System.debug('MIC37| CATALOGO ' + w.Name + ' | ' + w.agf__Status__c + ' | sprint=' + w.agf__Sprint__r.Name + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | ' + (w.agf__Subject__c == null ? '' : w.agf__Subject__c.left(80)));
}
System.debug('MIC37| === AS 6 CITADAS PELO MICHEL ===');
Set<String> vistas = new Set<String>();
for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c, IsDeleted, LastModifiedDate, LastModifiedBy.Name
                           FROM agf__ADM_Work__c WHERE Name IN :seis ORDER BY Name ALL ROWS]) {
    vistas.add(w.Name);
    System.debug('MIC37| SEIS ' + w.Name + ' | ' + (w.IsDeleted ? 'NA LIXEIRA (restauravel ate ' + w.LastModifiedDate.addDays(15).date().format() + ')' : 'ATIVA')
        + ' | excluida em ' + w.LastModifiedDate.format('dd/MM HH:mm') + ' por ' + w.LastModifiedBy.Name + ' | ' + (w.agf__Subject__c == null ? '' : w.agf__Subject__c.left(80)));
}
for (String n : seis) if (!vistas.contains(n)) System.debug('MIC37| SEIS ' + n + ' | NAO ENCONTRADA nem na Lixeira (purgada)');
System.debug('MIC37| FIM. Total de works ativas na org: ' + [SELECT COUNT() FROM agf__ADM_Work__c]);
