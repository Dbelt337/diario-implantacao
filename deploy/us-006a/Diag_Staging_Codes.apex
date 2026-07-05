/* US-006a — confirma valores ATUAIS de ProposedDocumentType__c (READ ONLY). Filtro: DT2 */
final String P = 'DT2 | ';
Integer cod=0, txt=0;
for (Schema.PicklistEntry pe : Account.ProposedDocumentType__c.getDescribe().getPicklistValues()) {
    Boolean ehCodigo = pe.getValue().length() <= 2;   // codigos = 01..99
    System.debug(LoggingLevel.ERROR, P+'VAL ['+pe.getValue()+'] label=['+pe.getLabel()+'] active='+pe.isActive()
        + (ehCodigo ? '  <== CODIGO' : ''));
    if (ehCodigo) cod++; else txt++;
}
System.debug(LoggingLevel.ERROR, P+'TOTAL codigos='+cod+' | textos_antigos='+txt
    + (cod>=16 ? '  -> codigos OK, staging aceita o valor do dropdown real' : '  -> FALTAM codigos: reveja o deploy do objeto'));
System.debug(LoggingLevel.ERROR, P+'=== FIM DT2 ===');
