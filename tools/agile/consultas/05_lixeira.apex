// Somente leitura: SELECT com ALL ROWS e System.debug. Nenhum DML.
for (agf__ADM_Work__c w : [SELECT Name, IsDeleted, agf__Subject__c, LastModifiedBy.Name, LastModifiedDate FROM agf__ADM_Work__c WHERE IsDeleted = true ORDER BY Name ALL ROWS])
    System.debug('LIX| ' + w.Name + ' | deleted=' + w.IsDeleted + ' | ' + w.agf__Subject__c.left(50) + ' | ' + w.LastModifiedBy.Name + ' ' + w.LastModifiedDate);
System.debug('LIX| total works na lixeira: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE IsDeleted = true ALL ROWS]);
System.debug('LIX| total works ativas: ' + [SELECT COUNT() FROM agf__ADM_Work__c]);
for (agf__ADM_Sprint__c s : [SELECT Name, IsDeleted FROM agf__ADM_Sprint__c WHERE IsDeleted = true ALL ROWS]) System.debug('LIX| sprint na lixeira: ' + s.Name);
