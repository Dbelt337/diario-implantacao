// Item D — Remediação de segurança do IntegrationLog__c (QA)
// D.1: remover FLS de RequestPayload__c/ResponsePayload__c dos PS de negócio.
// D.2: remover Edit e Delete do objeto dos 4 PS citados no dossiê (log imutável).
// Protocolo: DRY_RUN=true primeiro; execução real somente com aprovação do Diego.
Boolean DRY_RUN = true;

// D.2 — PS que hoje têm Edit+Delete no objeto (dossiê Thiago)
Set<String> psRemoverEditDelete = new Set<String>{
    'Integraçao BTecpar', 'Integration', 'B2C BackOffice', 'BackOffice B2C'
};
// Obs: o acesso de escrita do fluxo passa a vir do PS Integracao_Field_Service (CRU sem Delete).

// D.1 — quem PODE manter FLS nos payloads (integração + admins; demais perdem)
Set<String> manterPayload = new Set<String>{
    'Integracao Field Service', 'Integraçao BTecpar', 'Integration'
};

List<ObjectPermissions> ops = [
    SELECT Id, Parent.Label, PermissionsEdit, PermissionsDelete
    FROM ObjectPermissions
    WHERE SobjectType = 'IntegrationLog__c'
      AND Parent.IsOwnedByProfile = false
      AND Parent.Label IN :psRemoverEditDelete
      AND (PermissionsEdit = true OR PermissionsDelete = true)];
for (ObjectPermissions op : ops) {
    System.debug('D.2 alvo: ' + op.Parent.Label + ' (Edit=' + op.PermissionsEdit + ', Delete=' + op.PermissionsDelete + ') -> Edit=false, Delete=false');
    op.PermissionsEdit = false; op.PermissionsDelete = false;
}

List<FieldPermissions> fps = [
    SELECT Id, Field, Parent.Label
    FROM FieldPermissions
    WHERE SobjectType = 'IntegrationLog__c'
      AND Field IN ('IntegrationLog__c.RequestPayload__c', 'IntegrationLog__c.ResponsePayload__c')
      AND Parent.IsOwnedByProfile = false
      AND Parent.Label NOT IN :manterPayload];
for (FieldPermissions fp : fps) {
    System.debug('D.1 alvo: remover FLS de ' + fp.Field + ' do PS ' + fp.Parent.Label);
}

System.debug('Resumo: ' + ops.size() + ' ObjectPermissions a atualizar; ' + fps.size() + ' FieldPermissions a remover.');

if (DRY_RUN) {
    System.debug('DRY_RUN=true — nenhuma alteracao aplicada. Revisar alvos acima com o Diego.');
} else {
    if (!ops.isEmpty()) update ops;
    if (!fps.isEmpty()) delete fps;
    System.debug('Remediacao aplicada. Pendentes manuais: D.3 (e-mail do usuario -> DL, combinar com Thiago) e D.4 (registro no dossie).');
}
