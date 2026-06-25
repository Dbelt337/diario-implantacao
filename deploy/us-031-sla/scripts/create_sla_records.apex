// US-031 — cria/atualiza os registros do CMT Lead_SLA_Config via Metadata API.
// One-time setup (Execute Anonymous). NAO faz parte da solucao (flows sao declarativos).
// Editar o 5o valor de cada linha com o DeveloperName REAL da fila de escalada.
Metadata.DeployContainer container = new Metadata.DeployContainer();

// {DeveloperName, Label, Channel, SLAMinutes, EscalationQueueDevName}
List<List<Object>> rows = new List<List<Object>>{
    new List<Object>{'Default_Bandeja','Default Bandeja Leads','Bandeja Leads',   60,  'PLACEHOLDER_QUEUE'},
    new List<Object>{'Default_Web',    'Default Formulario Web','Formulario Web',  60,  'PLACEHOLDER_QUEUE'},
    new List<Object>{'Default_Correo', 'Default Correo',        'Correo',          120, 'PLACEHOLDER_QUEUE'},
    new List<Object>{'Default_Agencia','Default Agencia',       'Agencia',         120, 'PLACEHOLDER_QUEUE'},
    new List<Object>{'Default_Redes',  'Default Redes Sociales','Redes Sociales',  120, 'PLACEHOLDER_QUEUE'}
};
Integer maxReassign = 2;

for (List<Object> r : rows) {
    Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
    cm.fullName = 'Lead_SLA_Config.' + (String) r[0];
    cm.label    = (String) r[1];

    Metadata.CustomMetadataValue vCh = new Metadata.CustomMetadataValue();
    vCh.field = 'Channel__c';                 vCh.value = (String) r[2];   cm.values.add(vCh);
    Metadata.CustomMetadataValue vSla = new Metadata.CustomMetadataValue();
    vSla.field = 'SLAMinutes__c';             vSla.value = (Integer) r[3]; cm.values.add(vSla);
    Metadata.CustomMetadataValue vMax = new Metadata.CustomMetadataValue();
    vMax.field = 'MaxReassignments__c';       vMax.value = maxReassign;    cm.values.add(vMax);
    Metadata.CustomMetadataValue vQ = new Metadata.CustomMetadataValue();
    vQ.field = 'EscalationQueueDevName__c';   vQ.value = (String) r[4];    cm.values.add(vQ);

    container.addMetadata(cm);
}
Id jobId = Metadata.Operations.enqueueDeployment(container, null);
System.debug('>>> Deployment de CMT enfileirado: ' + jobId);
