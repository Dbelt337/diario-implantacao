// 32 - Apos a fase 2 do script 31: o trigger de Opportunity inseriu 1 Task durante o update das 5 oportunidades (DML Insert
// Task Rows:1 no log). Lista as tasks criadas hoje pelo usuario executor ligadas as 5 oportunidades e, com EXCLUIR = true,
// apaga as que forem efeito colateral do update em lote (nao as criadas por pessoas). Filtre por TSK32|.
Boolean EXCLUIR = false;
Set<Id> oppIds = new Set<Id>{ '006V200000lw281IAA', '006V200000gRYBuIAO', '006V200000d9ULNIA2', '006V200000u8m41IAA', '006V200000iJjw9IAC' };
List<Task> ts = [SELECT Id, Subject, Status, Owner.Name, What.Name, WhatId, Description, CreatedDate, ActivityDate FROM Task
                 WHERE CreatedDate = TODAY AND CreatedById = :UserInfo.getUserId() ORDER BY CreatedDate DESC];
List<Task> alvo = new List<Task>();
for (Task t : ts) {
    Boolean dasOpps = oppIds.contains(t.WhatId);
    System.debug('TSK32| task criada hoje por mim | ' + t.CreatedDate.format('HH:mm') + ' | ' + t.Subject + ' | ' + t.Status + ' | dono=' + t.Owner.Name
        + ' | registro=' + t.What.Name + (dasOpps ? ' (uma das 5 opps)' : '') + ' | vence=' + t.ActivityDate + ' | ' + (t.Description == null ? '' : t.Description.left(120)));
    if (dasOpps) alvo.add(t);
}
System.debug('TSK32| total criadas hoje por mim: ' + ts.size() + ' | ligadas as 5 opps: ' + alvo.size());
if (EXCLUIR && !alvo.isEmpty()) { delete alvo; System.debug('TSK32| ' + alvo.size() + ' task(s) excluida(s) (Lixeira)'); }
else if (!alvo.isEmpty()) System.debug('TSK32| nada excluido; para apagar as ligadas as 5 opps, rode com EXCLUIR = true');
