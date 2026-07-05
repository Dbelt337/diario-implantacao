/* ============================================================================
   US-006a — DIAG Record Type + FLS (READ ONLY). Filtro: RT2
   Dropdown Tipo de Documento vem --None-- mesmo lendo DocumentType__c real.
   ============================================================================ */
final String P = 'RT2 | ';

/* 1 — a conta de teste e seu Record Type */
System.debug(LoggingLevel.ERROR, P+'=== 1 conta Corporacion Regional + RT ===');
for (Account a : [SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, RecordType.Name,
                         DocumentType__c, ProposedDocumentType__c
                  FROM Account WHERE Name LIKE 'Corporaci%Regional%' ORDER BY LastModifiedDate DESC LIMIT 5])
    System.debug(LoggingLevel.ERROR, P+'Conta='+a.Name+' Id='+a.Id+' RT='+a.RecordType.DeveloperName
        +' ('+a.RecordType.Name+') | DocumentType__c='+a.DocumentType__c+' | Proposed='+a.ProposedDocumentType__c);

/* 2 — FLS do usuario atual nos dois campos (choice set exige READ) */
System.debug(LoggingLevel.ERROR, P+'=== 2 FLS do usuario atual ==='+' user='+UserInfo.getName());
Schema.DescribeFieldResult dReal = Account.DocumentType__c.getDescribe();
Schema.DescribeFieldResult dProp = Account.ProposedDocumentType__c.getDescribe();
System.debug(LoggingLevel.ERROR, P+'DocumentType__c        accessible(READ)='+dReal.isAccessible()+' updateable='+dReal.isUpdateable());
System.debug(LoggingLevel.ERROR, P+'ProposedDocumentType__c accessible(READ)='+dProp.isAccessible()+' updateable='+dProp.isUpdateable());

/* 3 — todos os Record Types ativos de Account (p/ saber se ha varios) */
System.debug(LoggingLevel.ERROR, P+'=== 3 Record Types ativos de Account ===');
for (RecordType r : [SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType='Account' AND IsActive=true])
    System.debug(LoggingLevel.ERROR, P+'RT '+r.Id+' ['+r.DeveloperName+'] '+r.Name);

System.debug(LoggingLevel.ERROR, P+'=== FIM RT2 (checar tb: Setup > Account > Record Types > [RT da conta] > tem valores de DocumentType__c atribuidos?) ===');
