// Item B — Reverter privilégio temporário do usuário de integração (QA)
// Protocolo: rodar com DRY_RUN=true, revisar o debug, obter aprovação, rodar com false.
// User e PermissionSetAssignment são ambos setup objects — sem mixed DML aqui.
Boolean DRY_RUN = true;

String username   = 'svc_sales_integracao@brasiltecpar.com.br.qa';
String perfilAlvo = 'Salesforce API Only System Integrations';
String psNovo     = 'Integracao_Field_Service'; // API name do PS (deploy do item B.2/C)

User u = [SELECT Id, Username, ProfileId, Profile.Name FROM User WHERE Username = :username LIMIT 1];
System.debug('Usuario: ' + u.Username + ' | Perfil atual: ' + u.Profile.Name);

// Inventário dos PS atuais (subsídio para a decisão B.3 sobre os 5 PS de Field Service)
for (PermissionSetAssignment psa : [
        SELECT PermissionSet.Label, PermissionSet.Name, PermissionSet.LicenseId
        FROM PermissionSetAssignment
        WHERE AssigneeId = :u.Id AND PermissionSet.IsOwnedByProfile = false]) {
    System.debug('PS atribuido hoje: ' + psa.PermissionSet.Label + ' (' + psa.PermissionSet.Name + ')');
}

Profile alvo = [SELECT Id FROM Profile WHERE Name = :perfilAlvo LIMIT 1];
List<PermissionSet> novo = [SELECT Id FROM PermissionSet WHERE Name = :psNovo LIMIT 1];
Integer jaAtribuido = novo.isEmpty() ? 0 :
    [SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :u.Id AND PermissionSetId = :novo[0].Id];

System.debug('PLANO: perfil -> ' + perfilAlvo
    + ' | atribuir PS ' + psNovo + ': ' + (novo.isEmpty() ? 'PS NAO EXISTE (deployar item C antes)'
    : (jaAtribuido > 0 ? 'ja atribuido' : 'sera atribuido')));

if (DRY_RUN) {
    System.debug('DRY_RUN=true — nenhuma alteracao aplicada. Revisar plano acima e reexecutar com false.');
} else {
    if (u.ProfileId != alvo.Id) { u.ProfileId = alvo.Id; update u; System.debug('Perfil revertido.'); }
    if (!novo.isEmpty() && jaAtribuido == 0) {
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = novo[0].Id);
        System.debug('PS ' + psNovo + ' atribuido.');
    }
    System.debug('Item B.1/B.2 concluidos. B.3 (remocao dos PS de FS) e B.4 (System Permission API-only no perfil) sao manuais/decisao Diego.');
}
