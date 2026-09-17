// 49 - MFA da Priscila De Lima (17/09): o login direto pede uma "chave de seguranca" (U2F/passkey) que ela nao tem a mao.
// Remove os metodos de chave de seguranca e autenticador embutido com UserManagement.deregisterVerificationMethod; no proximo
// login direto o Salesforce pede para cadastrar um metodo novo (Salesforce Authenticator). Nao mexe em senha, perfil nem SSO.
// Cada remocao e tentada separadamente; se o metodo nao existir ou a permissao faltar, o log mostra a excecao. Filtre por MFA49|.
// Requer que quem executa tenha a permissao "Gerenciar autenticacao multifator na interface do usuario".
User u = [SELECT Id, Name, Username FROM User WHERE Name = 'Priscila De Lima' AND IsActive = true LIMIT 1];
System.debug('MFA49| usuario ' + u.Name + ' | ' + u.Id);
Map<String, Auth.VerificationMethod> metodos = new Map<String, Auth.VerificationMethod>{
    'chave de seguranca (U2F)' => Auth.VerificationMethod.U2F,
    'autenticador embutido / passkey' => Auth.VerificationMethod.BUILT_IN_AUTHENTICATOR
};
for (String nome : metodos.keySet()) {
    try { System.UserManagement.deregisterVerificationMethod(u.Id, metodos.get(nome)); System.debug('MFA49| removido: ' + nome); }
    catch (Exception e) { System.debug('MFA49| nao removido (' + nome + '): ' + e.getTypeName() + ' - ' + e.getMessage().left(200)); }
}
System.debug('MFA49| concluido.');
