// 46 - Acessos do Delivery (planilha da Priscila, 17/09): decisao do Diego em 17/09: "nao cria usuarios novos e todos com o
// perfil do Romulo". Alvo = configuracao do Romulo Gustavo Ramos da Silva: perfil Read Only, role B2B - Delivery e permission
// set App BTP B2B - Visibilidade. Age sobre os 62 usuarios existentes da planilha (lista B da fase 1, por Id; nenhum e-mail aqui).
// EXCECOES (ficam de fora salvo INCLUIR_EXCECOES = true): Fernanda Ientzn da Rosa (gerente, perfil B2B - Backoffice: virar Read
// Only tira a edicao dela) e Ciro Librino, Telmo Baggio, Oscar Oesterreich (perfil B2B - Especialistas, role B2B Arquiteto
// Backoffice, membros da fila Arquitetura: trocar tira os tres da arquitetura). Confirmar com a Priscila antes de incluir.
// Nao cria User, nao inativa, nao mexe em e-mail/username/licenca. Idempotente. DUAS FASES: EXECUTAR = false so lista. Filtre por ACC46|.
Boolean EXECUTAR = false;
Boolean INCLUIR_EXCECOES = false;
Set<Id> excecoes = new Set<Id>{ '005V200000PLuwsIAD', '005V200000PLxI2IAL', '005V200000Lsr87IAB', '005V200000JlbxFIAR' };
List<Id> alvo = new List<Id>{ '005V200000PLuwsIAD','005V200000PLxMsIAL','005V200000PKw7vIAD','005V200000PKghXIAT','005V200000PKZ9kIAH','005V200000PLobKIAT','005V200000LtKwTIAV','005V200000PLxY9IAL','005V200000PLxjRIAT','005V200000PL6bvIAD','005V200000PLxczIAD','005V200000PLxWXIA1','005V200000PKWDZIA5','005V200000PJtfDIAT','005V200000PLUHhIAP','005V200000PL48iIAD','005V200000PLxDBIA1','005V200000PLLRGIA5','005V200000PLxbNIAT','005V200000PLqgPIAT','005V200000PKozzIAD','005V200000PLJR5IAP','005V200000PLllXIAT','005V200000PLkshIAD','005V200000PLJhCIAX','005V200000PLAdvIAH','005V200000PLY0NIAX','005V200000PLxI2IAL','005V200000PLkayIAD','005V200000PLxUvIAL','005V200000PLudWIAT','005V200000PLxgDIAT','005V200000PKVCZIA5','005V200000PKQ9iIAH','005V200000PLxhpIAD','005V200000PLXyiIAH','005V200000PLxI1IAL','005V200000PLxGPIA1','005V200000PLxLFIA1','005V200000Lsr87IAB','005V200000LsF4RIAV','005V200000LtJsNIAV','005V200000Lt9JYIAZ','005V200000LtL1JIAV','005V200000LtKoPIAV','005V200000Lt9csIAB','005V200000LtJsMIAV','005V200000LtGCwIAN','005V200000Lt4q6IAB','005V200000Lt2JeIAJ','005V200000LtDDTIA3','005V200000LtLHRIA3','005V200000LtkuAIAR','005V200000LtKmnIAF','005V200000LtKlBIAV','005V200000Lt7b4IAB','005V200000LsNA6IAN','005V200000LsU9vIAF','005V200000LtL7lIAF','005V200000LtR3YIAV','005V200000JlbxFIAR','005V200000Lsw1LIAR' };

User romulo = [SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name FROM User WHERE Name = 'Romulo Gustavo Ramos da Silva' LIMIT 1];
PermissionSet ps = [SELECT Id, Label FROM PermissionSet WHERE Name = 'App_BTP_B2B_Visibilidade' LIMIT 1];
if (romulo.Profile.Name != 'Read Only' || romulo.UserRole.Name != 'B2B - Delivery') { System.debug('ACC46| TRAVA: Romulo nao esta mais em Read Only / B2B - Delivery (' + romulo.Profile.Name + ' / ' + romulo.UserRole.Name + ') - nada alterado'); return; }
System.debug('ACC46| alvo: perfil ' + romulo.Profile.Name + ' (' + romulo.ProfileId + ') | role ' + romulo.UserRole.Name + ' (' + romulo.UserRoleId + ') | PS ' + ps.Label);

Set<Id> comPs = new Set<Id>();
for (PermissionSetAssignment a : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId IN :alvo]) comPs.add(a.AssigneeId);
List<User> upd = new List<User>(); List<PermissionSetAssignment> novasPsa = new List<PermissionSetAssignment>();
Integer nPerfil = 0, nRole = 0, nPs = 0, nSem = 0, nExc = 0;
for (User u : [SELECT Id, Name, IsActive, ProfileId, Profile.Name, UserRoleId, UserRole.Name FROM User WHERE Id IN :alvo ORDER BY Name]) {
    if (excecoes.contains(u.Id) && !INCLUIR_EXCECOES) { nExc++; System.debug('ACC46| EXCECAO (nao mexe): ' + u.Name + ' | ' + u.Profile.Name + ' / ' + u.UserRole.Name + (comPs.contains(u.Id) ? ' | com PS' : ' | sem PS')); continue; }
    if (!u.IsActive) { System.debug('ACC46| INATIVO (nao mexe): ' + u.Name); continue; }
    List<String> mud = new List<String>();
    if (u.ProfileId != romulo.ProfileId) { mud.add('perfil ' + u.Profile.Name + ' -> Read Only'); u.ProfileId = romulo.ProfileId; nPerfil++; }
    if (u.UserRoleId != romulo.UserRoleId) { mud.add('role ' + (u.UserRole == null ? '(vazia)' : u.UserRole.Name) + ' -> B2B - Delivery'); u.UserRoleId = romulo.UserRoleId; nRole++; }
    if (!comPs.contains(u.Id)) { mud.add('+ PS ' + ps.Label); novasPsa.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id)); nPs++; }
    if (mud.isEmpty()) { nSem++; System.debug('ACC46| ' + u.Name + ' | ja como o Romulo'); continue; }
    System.debug('ACC46| ' + u.Name + ' | MUDA: ' + String.join(mud, '; '));
    if (u.ProfileId != null && (mud[0].startsWith('perfil') || mud[0].startsWith('role'))) upd.add(u);
}
System.debug('ACC46| resumo: ' + alvo.size() + ' alvo | ' + nExc + ' excecao(oes) fora | perfil a trocar ' + nPerfil + ' | role a trocar ' + nRole + ' | PS a atribuir ' + nPs + ' | ja ok ' + nSem);
if (!EXECUTAR) { System.debug('ACC46| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
if (!upd.isEmpty()) update upd;
if (!novasPsa.isEmpty()) insert novasPsa;
System.debug('ACC46| DEPOIS alvo com perfil Read Only e role B2B - Delivery: ' + [SELECT COUNT() FROM User WHERE Id IN :alvo AND ProfileId = :romulo.ProfileId AND UserRoleId = :romulo.UserRoleId]);
System.debug('ACC46| DEPOIS alvo com o PS: ' + [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId IN :alvo]);
System.debug('ACC46| DEPOIS usuarios ativos Read Only + B2B - Delivery na org: ' + [SELECT COUNT() FROM User WHERE IsActive = true AND ProfileId = :romulo.ProfileId AND UserRoleId = :romulo.UserRoleId]);
System.debug('ACC46| concluido: ' + upd.size() + ' usuario(s) alterado(s), ' + novasPsa.size() + ' PS atribuido(s).');
