// 30 - Residuo da fase 2 do script 29 (16/09): 3 contas e 5 oportunidades nao aceitaram a troca do gerente por regras de
// validacao ("seu usuario nao esta definido a um cluster" nas contas; "usuario nao possui autorizacao para manipular o
// registro nesta fase" / "Aguardando contrato: apenas secao Informacoes..." nas oportunidades). Somente leitura: identifica os
// registros, os campos de cluster do usuario que executa e o que a fase 2 gravou. Filtre por RES30|.
User rodrigo = [SELECT Id FROM User WHERE Name = 'Rodrigo Nascimento Piccolo' AND IsActive = true LIMIT 1];
User wesley  = [SELECT Id FROM User WHERE Name = 'Wesley Ramalho Goncalves' AND IsActive = true LIMIT 1];
// 1. as 3 contas que falharam (ainda com Wesley)
for (Account a : [SELECT Id, Name, Owner.Name, RecordType.Name, AccountManager__r.Name, Type, Industry FROM Account WHERE Id IN ('001V200000nbiHCIAY', '001V200000nsRTeIAM', '001V200000nM90PIAS')]) {
    System.debug('RES30| CONTA PENDENTE | ' + a.Name + ' | dono=' + a.Owner.Name + ' | rt=' + a.RecordType.Name + ' | tipo=' + a.Type + ' | gerente=' + a.AccountManager__r.Name);
}
// 2. campos de "cluster" no usuario e valores do usuario que executa e do Rodrigo
Map<String, Schema.SObjectField> uf = Schema.SObjectType.User.fields.getMap();
List<String> campos = new List<String>();
for (String f : uf.keySet()) if (f.containsIgnoreCase('cluster')) campos.add(uf.get(f).getDescribe().getName());
System.debug('RES30| campos de cluster no User: ' + campos);
if (!campos.isEmpty()) {
    Id me = UserInfo.getUserId();
    for (SObject u : Database.query('SELECT Id, Name, Profile.Name, ' + String.join(campos, ', ') + ' FROM User WHERE Id IN (\'' + me + '\', \'' + rodrigo.Id + '\')')) {
        System.debug('RES30| usuario ' + JSON.serialize(u.getPopulatedFieldsAsMap()).left(400));
    }
}
// 3. campos de "cluster" na conta (a regra pode comparar cluster da conta x cluster do usuario)
Map<String, Schema.SObjectField> af = Schema.SObjectType.Account.fields.getMap();
List<String> camposA = new List<String>();
for (String f : af.keySet()) if (f.containsIgnoreCase('cluster')) camposA.add(af.get(f).getDescribe().getName());
System.debug('RES30| campos de cluster na Account: ' + camposA);
// 4. as 5 oportunidades que falharam
Set<Id> equipe = new Set<Id>();
for (User u : [SELECT Id FROM User WHERE IsActive = true AND UserRole.Name LIKE 'B2B % Alt e GGNet Operadoras / Utilities%' AND Id != :rodrigo.Id]) equipe.add(u.Id);
for (Opportunity o : [SELECT Id, Name, Owner.Name, StageName, ManagerAccount__r.Name, RecordType.Name, Send4Approval__c FROM Opportunity
                      WHERE IsClosed = false AND OwnerId IN :equipe AND (ManagerAccount__c != :rodrigo.Id OR ManagerAccount__c = null)]) {
    System.debug('RES30| OPP PENDENTE | ' + o.Name.left(50) + ' | dono=' + o.Owner.Name + ' | fase=' + o.StageName + ' | rt=' + o.RecordType.Name + ' | gerente=' + o.ManagerAccount__r.Name + ' | ' + o.Id);
}
// 5. task criada pelo trigger durante a fase 2 (DML Insert Task Rows:1 no log)
for (Task t : [SELECT Subject, Status, Owner.Name, What.Name, CreatedDate FROM Task WHERE CreatedDate = TODAY AND CreatedById = :UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 5]) {
    System.debug('RES30| TASK criada hoje por mim | ' + t.CreatedDate.format('HH:mm') + ' | ' + t.Subject + ' | ' + t.Status + ' | dono=' + t.Owner.Name + ' | registro=' + t.What.Name);
}
System.debug('RES30| fim');
