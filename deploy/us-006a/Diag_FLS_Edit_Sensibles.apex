/* US-006a — quem da EDIT nos campos sensiveis (READ ONLY). Filtro: FLS
   Permissao e aditiva: qualquer profile/PS com Edit deixa o vendedor editar. */
final String P = 'FLS | ';
Set<String> campos = new Set<String>{
  'Account.DocumentType__c','Account.DocumentNumber__c','Account.ElectronicBillingEmail__c',
  'Account.SensitiveChangeStatus__c','Account.ProposedName__c','Account.ProposedDocumentType__c',
  'Account.ProposedDocumentNumber__c','Account.ProposedElectronicBillingEmail__c'
};
System.debug(LoggingLevel.ERROR, P+'=== FieldPermissions com EDIT=true nesses campos ===');
for (FieldPermissions fp : [SELECT Field, Parent.Label, Parent.IsOwnedByProfile, Parent.Profile.Name
                            FROM FieldPermissions
                            WHERE SobjectType='Account' AND Field IN :campos AND PermissionsEdit=true
                            ORDER BY Field]) {
    String origem = fp.Parent.IsOwnedByProfile ? ('PROFILE: '+fp.Parent.Profile.Name) : ('PermSet: '+fp.Parent.Label);
    System.debug(LoggingLevel.ERROR, P+fp.Field+'  <= EDIT por '+origem);
}
System.debug(LoggingLevel.ERROR, P+'=== FIM FLS (tirar Edit desses origens) ===');
