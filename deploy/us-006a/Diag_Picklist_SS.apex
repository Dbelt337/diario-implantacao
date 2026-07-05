/* ============================================================================
   US-006a — DIAG picklist SensitiveChangeStatus__c (READ ONLY). Filtro: SS
   Erro: INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST bad value: Pendiente
   ============================================================================ */
final String P = 'SS | ';
final Id accId = '001WK00002Osu3CYAR';

/* 1 — valores ATIVOS do campo (o que a org aceita hoje) */
System.debug(LoggingLevel.ERROR, P+'=== 1 valores ATIVOS de SensitiveChangeStatus__c ===');
Schema.DescribeFieldResult dfr = Account.SensitiveChangeStatus__c.getDescribe();
for (Schema.PicklistEntry pe : dfr.getPicklistValues())
    System.debug(LoggingLevel.ERROR, P+'VAL ['+pe.getValue()+'] label=['+pe.getLabel()+'] active='+pe.isActive());
System.debug(LoggingLevel.ERROR, P+'restrita? '+dfr.isRestrictedPicklist()+' | dependente? '+dfr.isDependentPicklist());

/* 2 — Record Type da conta de teste */
System.debug(LoggingLevel.ERROR, P+'=== 2 Record Type da conta ===');
for (Account a : [SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, RecordType.Name FROM Account WHERE Id=:accId])
    System.debug(LoggingLevel.ERROR, P+'Conta='+a.Name+' RTId='+a.RecordTypeId
        +' RT='+a.RecordType.DeveloperName+' ('+a.RecordType.Name+')');

/* 3 — Record Types ativos de Account (para saber quantos precisam da atribuicao) */
System.debug(LoggingLevel.ERROR, P+'=== 3 Record Types ativos de Account ===');
Integer rt=0;
for (RecordType r : [SELECT DeveloperName, Name FROM RecordType WHERE SobjectType='Account' AND IsActive=true]) {
    System.debug(LoggingLevel.ERROR, P+'RT ['+r.DeveloperName+'] '+r.Name); rt++;
}
if (rt==0) System.debug(LoggingLevel.ERROR, P+'NENHUM Record Type ativo em Account (so Master) -> causa nao e RT; ver valor/ativo no bloco 1');

System.debug(LoggingLevel.ERROR, P+'=== FIM SS ===');
