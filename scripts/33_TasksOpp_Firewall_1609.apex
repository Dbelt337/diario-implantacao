// 33 - Tasks da oportunidade FIREWALL - NOVOS SO GRUPO V ARAUCARIA, para saber se a task "Aguardando contrato" criada pelo
// trigger em 16/09 18:27 (00TV200001AJXRrMAP) duplica uma ja existente. Somente leitura. Filtre por TSK33|.
for (Task t : [SELECT Id, Subject, Status, Owner.Name, CreatedBy.Name, CreatedDate, ActivityDate FROM Task
               WHERE WhatId = '006V200000iJjw9IAC' ORDER BY CreatedDate]) {
    System.debug('TSK33| ' + t.CreatedDate.format('dd/MM HH:mm') + ' | ' + t.Subject + ' | ' + t.Status + ' | dono=' + t.Owner.Name
        + ' | criada por ' + t.CreatedBy.Name + ' | vence=' + t.ActivityDate + (t.Id == '00TV200001AJXRrMAP' ? ' | <- criada pelo nosso update' : ''));
}
