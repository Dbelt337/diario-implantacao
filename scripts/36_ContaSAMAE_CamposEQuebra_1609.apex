// 36 - Print da Tayza (16/09): a PAGINA DA CONTA 001V200000lodzIIAQ (SAMAE) nao carrega ("Ocorreu um problema ... Server Error"),
// enquanto outras contas abrem. A conta existe e ela tem acesso (script 34). Portanto e um componente da record page que
// estoura com os DADOS desta conta (formula, lookup para registro inexistente, campo em formato inesperado). Este script,
// somente leitura, despeja TODOS os campos preenchidos da conta, verifica cada lookup (registro alvo existe? esta na Lixeira?)
// e faz o mesmo para uma conta "irma" (mesmo record type e dona) que abre normalmente, para comparar. Filtre por CMP36|.
void dumpConta(String rotulo, Id accId) {
    Map<String, Schema.SObjectField> fm = Schema.SObjectType.Account.fields.getMap();
    List<String> campos = new List<String>();
    for (String f : fm.keySet()) campos.add(fm.get(f).getDescribe().getName());
    SObject a = Database.query('SELECT ' + String.join(campos, ', ') + ' FROM Account WHERE Id = :accId');
    Map<String, Object> m = a.getPopulatedFieldsAsMap();
    List<String> pares = new List<String>();
    for (String k : m.keySet()) {
        if (k == 'attributes' || m.get(k) == null) continue;
        Schema.DescribeFieldResult d = fm.get(k.toLowerCase()).getDescribe();
        String v = String.valueOf(m.get(k));
        pares.add(k + (d.isCalculated() ? '(formula)' : '') + '=' + v.left(60));
    }
    System.debug('CMP36| ' + rotulo + ' | ' + m.size() + ' campos preenchidos');
    // em blocos, para o log nao cortar
    for (Integer i = 0; i < pares.size(); i += 12) {
        List<String> bloco = new List<String>();
        for (Integer j = i; j < Math.min(i + 12, pares.size()); j++) bloco.add(pares[j]);
        System.debug('CMP36|   ' + rotulo + ' | ' + String.join(bloco, ' | '));
    }
    // lookups: o registro apontado existe?
    for (String k : m.keySet()) {
        if (k == 'attributes' || m.get(k) == null) continue;
        Schema.DescribeFieldResult d = fm.get(k.toLowerCase()).getDescribe();
        if (d.getType() != Schema.DisplayType.REFERENCE || d.getReferenceTo().isEmpty()) continue;
        Id alvo = (Id) m.get(k);
        String obj = String.valueOf(alvo.getSObjectType());
        try {
            List<SObject> r = Database.query('SELECT Id, IsDeleted FROM ' + obj + ' WHERE Id = :alvo ALL ROWS');
            String st = r.isEmpty() ? 'NAO EXISTE' : ((Boolean) r[0].get('IsDeleted') ? 'NA LIXEIRA' : 'ok');
            if (st != 'ok') System.debug('CMP36|   ' + rotulo + ' | LOOKUP QUEBRADO | ' + k + ' -> ' + obj + ' ' + alvo + ' | ' + st);
        } catch (Exception e) { System.debug('CMP36|   ' + rotulo + ' | lookup ' + k + ' -> ' + obj + ' nao verificavel: ' + e.getMessage().left(80)); }
    }
}
void run() {
    Id samae = '001V200000lodzIIAQ';
    Account s = [SELECT Id, RecordTypeId, OwnerId FROM Account WHERE Id = :samae];
    dumpConta('SAMAE', samae);
    // conta irma: mesmo record type e dona, alterada mais recentemente (abre normalmente, para comparar)
    List<Account> irmas = [SELECT Id, Name FROM Account WHERE RecordTypeId = :s.RecordTypeId AND OwnerId = :s.OwnerId AND Id != :samae ORDER BY LastModifiedDate DESC LIMIT 1];
    if (!irmas.isEmpty()) { System.debug('CMP36| conta irma para comparacao: ' + irmas[0].Name + ' (' + irmas[0].Id + ')'); dumpConta('IRMA', irmas[0].Id); }
    // filhos da conta que componentes da pagina costumam carregar
    System.debug('CMP36| filhos SAMAE | contatos=' + [SELECT COUNT() FROM Contact WHERE AccountId = :samae] + ' | casos=' + [SELECT COUNT() FROM Case WHERE AccountId = :samae]
        + ' | ativos=' + [SELECT COUNT() FROM Asset WHERE AccountId = :samae] + ' | contas filhas=' + [SELECT COUNT() FROM Account WHERE ParentId = :samae]
        + ' | tarefas=' + [SELECT COUNT() FROM Task WHERE WhatId = :samae] + ' | arquivos=' + [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :samae]);
    System.debug('CMP36| fim');
}
run();
