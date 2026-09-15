// 16 - Lista as works da org que NAO tem doc no export de 11/09 (82 docs) nem foram documentadas em 15/09 (W-000142 a 145)
// e despeja o conteudo delas para gerar os docs faltantes. Somente SELECT + System.debug.
// DUMP_ANTIGAS = false: cabecalho de todas as faltantes, Details so das W-000041 em diante (as anteriores a 041 nao eram
// do export SysMap). Mude para true se quiser Details de todas. Filtre o log por DOC16| e DUMP16| e mande tudo.
Boolean DUMP_ANTIGAS = false;
Set<String> comDoc = new Set<String>{
 'W-000041','W-000051','W-000052','W-000053','W-000054','W-000055','W-000056','W-000057','W-000058','W-000059','W-000060','W-000061',
 'W-000062','W-000063','W-000064','W-000065','W-000066','W-000067','W-000068','W-000069','W-000071','W-000072','W-000073','W-000074',
 'W-000075','W-000076','W-000077','W-000078','W-000079','W-000080','W-000081','W-000082','W-000083','W-000084','W-000085','W-000086',
 'W-000087','W-000088','W-000089','W-000090','W-000091','W-000092','W-000093','W-000094','W-000095','W-000096','W-000097','W-000098',
 'W-000099','W-000100','W-000101','W-000102','W-000103','W-000104','W-000105','W-000106','W-000107','W-000108','W-000109','W-000110',
 'W-000111','W-000112','W-000113','W-000114','W-000115','W-000116','W-000117','W-000118','W-000119','W-000120','W-000121','W-000122',
 'W-000123','W-000124','W-000125','W-000126','W-000127','W-000128','W-000129','W-000130','W-000131','W-000132',
 'W-000142','W-000143','W-000144','W-000145' };

Integer total = 0, faltam = 0;
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Status__c, RecordType.Name, agf__Epic__r.Name,
                                  agf__Scrum_Team__r.Name, agf__Sprint__r.Name, agf__Assignee__r.Name, agf__Product_Tag__r.Name,
                                  agf__Story_Points__c, CreatedBy.Name, CreatedDate, LastModifiedDate
                           FROM agf__ADM_Work__c ORDER BY Name]) {
    total++;
    if (comDoc.contains(w.Name)) continue;
    faltam++;
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    System.debug('DOC16| SEM DOC | ' + w.Name + ' | ' + w.agf__Status__c + ' | rt=' + w.RecordType.Name + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | epic=' + w.agf__Epic__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name
        + ' | tag=' + w.agf__Product_Tag__r.Name + ' | pontos=' + w.agf__Story_Points__c + ' | criada ' + w.CreatedDate.format('dd/MM/yy') + ' por ' + w.CreatedBy.Name
        + ' | details=' + det.length() + ' | ' + w.agf__Subject__c);
    if (!DUMP_ANTIGAS && w.Name < 'W-000041') continue;
    for (Integer i = 0; i < det.length(); i += 250) {
        System.debug('DUMP16| ' + w.Name + ' | ' + det.substring(i, Math.min(i + 250, det.length())));
    }
    for (agf__ADM_Acceptance_Criterion__c c : [SELECT Name, agf__Status__c, agf__Description__c FROM agf__ADM_Acceptance_Criterion__c WHERE agf__Work__c = :w.Id ORDER BY Name]) {
        System.debug('DOC16| ' + w.Name + ' | criterio | ' + c.Name + ' | ' + c.agf__Status__c + ' | ' + c.agf__Description__c);
    }
}
System.debug('DOC16| RESULTADO: ' + total + ' works na org, ' + faltam + ' sem doc (' + comDoc.size() + ' ja documentadas).');
