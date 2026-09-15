// 23 - Antes da fase 2 do script 22: despeja as tasks (agf__ADM_Task__c) das works W-000041 a W-000050, que a fase 1 mostrou
// terem 141 tasks no total (10 a 26 por work), com responsavel, status e horas. Somente SELECT + System.debug. As tasks sao
// filhas da work e vao junto na exclusao; este dump preserva o registro no diario. Filtre o log por TSK23|.
Set<String> alvo = new Set<String>();
for (Integer i = 41; i <= 50; i++) alvo.add('W-0000' + i);
Map<Id, agf__ADM_Work__c> works = new Map<Id, agf__ADM_Work__c>([SELECT Id, Name, agf__Subject__c FROM agf__ADM_Work__c WHERE Name IN :alvo]);
Set<Id> alvoIds = works.keySet();
// campos consultados dinamicamente porque o conjunto varia por versao do pacote; se algum nao existir, cai para o minimo
List<SObject> tasks;
try {
    tasks = Database.query('SELECT Id, Name, agf__Work__c, agf__Subject__c, agf__Status__c, agf__Assigned_To__r.Name, agf__Hours_Remaining__c, '
        + 'agf__Actual_Hours__c, CreatedBy.Name, CreatedDate FROM agf__ADM_Task__c WHERE agf__Work__c IN :alvoIds ORDER BY agf__Work__c, CreatedDate');
} catch (Exception e) {
    System.debug('TSK23| consulta completa falhou (' + e.getMessage().left(150) + '); usando campos minimos');
    tasks = Database.query('SELECT Id, Name, agf__Work__c, agf__Subject__c, agf__Status__c FROM agf__ADM_Task__c WHERE agf__Work__c IN :alvoIds ORDER BY agf__Work__c, CreatedDate');
}
Integer total = 0;
for (SObject t : tasks) {
    total++;
    Id wid = (Id) t.get('agf__Work__c');
    System.debug('TSK23| ' + works.get(wid).Name + ' | ' + JSON.serialize(t.getPopulatedFieldsAsMap()).left(600));
}
System.debug('TSK23| RESULTADO: ' + total + ' tasks em ' + works.size() + ' works (W-000041 a W-000050).');
