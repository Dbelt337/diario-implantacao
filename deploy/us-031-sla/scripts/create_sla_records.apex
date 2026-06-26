// US-031 — cria/atualiza os registros do CMT Lead_SLA_Config via Metadata API.
// One-time setup (Execute Anonymous). NAO faz parte da solucao (flows sao declarativos).
//
// NAO precisa mais editar PLACEHOLDER em 5 lugares: o script AUTO-RESOLVE a fila de Lead.
//  - Se voce souber o DeveloperName exato, preencha QUEUE_DEV_NAME abaixo e ele usa esse.
//  - Se deixar em branco, ele busca as filas habilitadas para Lead:
//       * exatamente 1 fila  -> usa ela em todas as linhas automaticamente;
//       * 0 ou >1 filas      -> imprime a lista no debug e PARA (escolha e preencha
//                               QUEUE_DEV_NAME com o DeveloperName desejado).

String QUEUE_DEV_NAME = 'Queue_Vendedores_CR';   // fila de escalada/re-roteamento (Fase 1 e 2)

// --- Resolve a fila de escalada -------------------------------------------------
if (String.isBlank(QUEUE_DEV_NAME)) {
    // Filas que aceitam Lead (QueueSobject) + o DeveloperName/Nome de cada uma.
    Map<Id, Group> queueById = new Map<Id, Group>(
        [SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'Queue']
    );
    List<String> leadQueues = new List<String>();
    Map<String, String> nameByDev = new Map<String, String>();
    for (QueueSobject qs : [SELECT QueueId FROM QueueSobject WHERE SobjectType = 'Lead']) {
        Group g = queueById.get(qs.QueueId);
        if (g != null && !nameByDev.containsKey(g.DeveloperName)) {
            leadQueues.add(g.DeveloperName);
            nameByDev.put(g.DeveloperName, g.Name);
        }
    }

    if (leadQueues.size() == 1) {
        QUEUE_DEV_NAME = leadQueues[0];
        System.debug('>>> Fila de Lead auto-resolvida: ' + QUEUE_DEV_NAME +
                     ' (' + nameByDev.get(QUEUE_DEV_NAME) + ')');
    } else {
        System.debug('>>> Nao deu pra auto-resolver (' + leadQueues.size() + ' filas de Lead).');
        for (String dev : leadQueues) {
            System.debug('    - DeveloperName=' + dev + '  | Nome="' + nameByDev.get(dev) + '"');
        }
        if (leadQueues.isEmpty()) {
            System.debug('    Nenhuma fila aceita Lead. Crie/ajuste a Queue e adicione Lead em "Supported Objects".');
        }
        throw new System.NoAccessException(); // para a execucao; preencha QUEUE_DEV_NAME e rode de novo.
    }
}
System.debug('>>> Usando fila de escalada: ' + QUEUE_DEV_NAME);

// --- Upsert dos registros do CMT ------------------------------------------------
Metadata.DeployContainer container = new Metadata.DeployContainer();

// {DeveloperName, Label, Channel, SLAMinutes}  (a fila vem de QUEUE_DEV_NAME)
List<List<Object>> rows = new List<List<Object>>{
    new List<Object>{'Default_Bandeja','Default Bandeja Leads','Bandeja Leads',   60},
    new List<Object>{'Default_Web',    'Default Formulario Web','Formulario Web',  60},
    new List<Object>{'Default_Correo', 'Default Correo',        'Correo',          120},
    new List<Object>{'Default_Agencia','Default Agencia',       'Agencia',         120},
    new List<Object>{'Default_Redes',  'Default Redes Sociales','Redes Sociales',  120}
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
    vQ.field = 'EscalationQueueDevName__c';   vQ.value = QUEUE_DEV_NAME;   cm.values.add(vQ);

    container.addMetadata(cm);
}
Id jobId = Metadata.Operations.enqueueDeployment(container, null);
System.debug('>>> Deployment de CMT enfileirado: ' + jobId);
