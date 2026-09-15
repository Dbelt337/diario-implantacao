// 24 - Diagnostico (somente leitura) do processo de aprovacao da Opportunity 006V200000yiZh3IAE (producao), chamado da Tayza
// em 15/09: "a aprovacao comercial ficou em nome do GR". Lista a oportunidade, dono, gerente do dono, os processos de
// aprovacao da oportunidade com etapas, aprovador designado (ActorId) e aprovador original, e o cabecalho do processo.
// Filtre o log por APR24|.
Id oppId = '006V200000yiZh3IAE';

Opportunity o = [SELECT Id, Name, StageName, Amount, OwnerId, Owner.Name, Owner.ManagerId, Owner.Manager.Name, Owner.UserRole.Name,
                        Owner.Profile.Name, RecordType.Name, LastModifiedBy.Name, LastModifiedDate
                 FROM Opportunity WHERE Id = :oppId];
System.debug('APR24| OPP | ' + o.Name + ' | fase=' + o.StageName + ' | valor=' + o.Amount + ' | rt=' + o.RecordType.Name
    + ' | dono=' + o.Owner.Name + ' (perfil ' + o.Owner.Profile.Name + ', papel ' + o.Owner.UserRole.Name + ')'
    + ' | gerente do dono=' + o.Owner.Manager.Name + ' (' + o.Owner.ManagerId + ')'
    + ' | ultima alteracao ' + o.LastModifiedBy.Name + ' em ' + o.LastModifiedDate.format('dd/MM HH:mm'));

// campos de usuario da oportunidade que podem ser usados como aprovador no processo (lookup para User)
Map<String, Schema.SObjectField> fm = Schema.SObjectType.Opportunity.fields.getMap();
List<String> userFields = new List<String>();
for (String f : fm.keySet()) {
    Schema.DescribeFieldResult d = fm.get(f).getDescribe();
    if (d.getType() == Schema.DisplayType.REFERENCE && !d.getReferenceTo().isEmpty() && d.getReferenceTo()[0] == User.SObjectType) userFields.add(d.getName());
}
SObject oFull = Database.query('SELECT ' + String.join(userFields, ', ') + ' FROM Opportunity WHERE Id = :oppId');
for (String f : userFields) {
    Id v = (Id) oFull.get(f);
    if (v != null) System.debug('APR24| CAMPO USUARIO | ' + f + ' = ' + v + ' | ' + [SELECT Name FROM User WHERE Id = :v].Name + (v == o.OwnerId ? ' (E O PROPRIO DONO/GR)' : ''));
}

for (ProcessInstance pi : [SELECT Id, Status, ProcessDefinition.Name, ProcessDefinition.DeveloperName, SubmittedBy.Name, CreatedDate, CompletedDate,
                                  (SELECT Id, StepStatus, Actor.Name, ActorId, OriginalActor.Name, OriginalActorId, Comments, CreatedDate FROM Steps ORDER BY CreatedDate),
                                  (SELECT Id, Actor.Name, ActorId, OriginalActor.Name, OriginalActorId, CreatedDate FROM Workitems),
                                  (SELECT ProcessNodeName, NodeStatus, LastActor.Name, CompletedDate FROM Nodes)
                           FROM ProcessInstance WHERE TargetObjectId = :oppId ORDER BY CreatedDate DESC]) {
    System.debug('APR24| PROCESSO | ' + pi.ProcessDefinition.Name + ' (' + pi.ProcessDefinition.DeveloperName + ') | status=' + pi.Status
        + ' | submetido por ' + pi.SubmittedBy.Name + ' em ' + pi.CreatedDate.format('dd/MM HH:mm') + ' | concluido=' + pi.CompletedDate);
    for (ProcessInstanceStep s : pi.Steps) {
        System.debug('APR24|   ETAPA | ' + s.StepStatus + ' | ator=' + s.Actor.Name + ' | ator original=' + s.OriginalActor.Name
            + ' | ' + s.CreatedDate.format('dd/MM HH:mm') + ' | ' + s.Comments);
    }
    for (ProcessInstanceNode n : pi.Nodes) {
        System.debug('APR24|   NO DO PROCESSO | ' + n.ProcessNodeName + ' | ' + n.NodeStatus + ' | ultimo ator=' + n.LastActor.Name + ' | concluido=' + n.CompletedDate);
    }
    for (ProcessInstanceWorkitem w : pi.Workitems) {
        System.debug('APR24|   PENDENTE | aguardando ' + w.Actor.Name + ' (' + w.ActorId + ')' + ' | ator original=' + w.OriginalActor.Name
            + (w.ActorId == o.OwnerId ? ' | ATENCAO: aprovador e o proprio dono da oportunidade' : '') + ' | workitem=' + w.Id);
    }
}
// definicao ativa do processo de aprovacao de Opportunity: etapas e nos
for (ProcessDefinition pd : [SELECT Id, Name, DeveloperName, State, Type, TableEnumOrId FROM ProcessDefinition WHERE TableEnumOrId = 'Opportunity' AND State = 'Active']) {
    System.debug('APR24| DEFINICAO ATIVA | ' + pd.Name + ' (' + pd.DeveloperName + ') | ' + pd.Type);
    for (ProcessNode n : [SELECT Name, DeveloperName FROM ProcessNode WHERE ProcessDefinitionId = :pd.Id]) System.debug('APR24|   NO | ' + n.Name + ' (' + n.DeveloperName + ')');
}
System.debug('APR24| fim');
