/* ============================================================================
   US-006a — DIAG DocumentType (READ ONLY). Filtro: DT
   Dropdown "Nuevo Tipo de Documento" mostra so --None--.
   Choice set le de ProposedDocumentType__c; comparar com DocumentType__c real.
   ============================================================================ */
final String P = 'DT | ';
final Id accId = '001WK00002Osu3CYAR';
Map<String, Schema.SObjectField> af = Schema.SObjectType.Account.fields.getMap();

for (String fn : new List<String>{'documenttype__c','proposeddocumenttype__c'}) {
    System.debug(LoggingLevel.ERROR, P+'==================================================');
    if (!af.containsKey(fn)) { System.debug(LoggingLevel.ERROR, P+fn+' -> NAO EXISTE'); continue; }
    Schema.DescribeFieldResult d = af.get(fn).getDescribe();
    System.debug(LoggingLevel.ERROR, P+'CAMPO '+d.getName()+' | type='+d.getType()
        +' | restrita='+d.isRestrictedPicklist()+' | dependente='+d.isDependentPicklist());
    Integer n = 0;
    for (Schema.PicklistEntry pe : d.getPicklistValues()) {
        System.debug(LoggingLevel.ERROR, P+'   VAL ['+pe.getValue()+'] label=['+pe.getLabel()+'] active='+pe.isActive());
        n++;
    }
    System.debug(LoggingLevel.ERROR, P+'   TOTAL valores ATIVOS = '+n + (n==0 ? '  <<< VAZIO! (causa do --None--)' : ''));
}

/* Record type da conta (valores de picklist podem estar filtrados por RT) */
System.debug(LoggingLevel.ERROR, P+'==================================================');
for (Account a : [SELECT Name, RecordTypeId, RecordType.DeveloperName, DocumentType__c, ProposedDocumentType__c
                  FROM Account WHERE Id=:accId])
    System.debug(LoggingLevel.ERROR, P+'Conta='+a.Name+' RT='+a.RecordType.DeveloperName
        +' | DocumentType__c='+a.DocumentType__c+' | ProposedDocumentType__c='+a.ProposedDocumentType__c);

System.debug(LoggingLevel.ERROR, P+'=== FIM DT ===');
