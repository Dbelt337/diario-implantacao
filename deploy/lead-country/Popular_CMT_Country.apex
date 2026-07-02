/* ============================================================================
   Popula Sociedad_Config__mdt.Country_Picklist_Value__c nos 12 registros.
   Seta SOMENTE o campo novo (le o MasterLabel atual e nao mexe nos demais).
   Deploy assincrono via Metadata.Operations -> conferir em Setup > Deployment Status.
   PRE-REQUISITO: o campo Country_Picklist_Value__c ja deployado (etapa 1).
   ============================================================================ */
Map<String,String> dev2val = new Map<String,String>{
    'C101' => 'CR Costa Rica', 'C105' => 'CR Costa Rica',
    'S101' => 'SV El Salvador', 'S105' => 'SV El Salvador', 'S206' => 'SV El Salvador',
    'G101' => 'GT Guatemala',
    'H101' => 'HN Honduras', 'H105' => 'HN Honduras',
    'N101' => 'NI Nicaragua', 'N105' => 'NI Nicaragua',
    'P101' => 'PA Panamá', 'P103' => 'PA Panamá', 'P105' => 'PA Panamá'
};

Metadata.DeployContainer container = new Metadata.DeployContainer();
Integer n = 0;
for (Sociedad_Config__mdt r : [SELECT DeveloperName, MasterLabel FROM Sociedad_Config__mdt WHERE DeveloperName IN :dev2val.keySet()]) {
    Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
    cm.fullName = 'Sociedad_Config.' + r.DeveloperName;   // ajustar prefixo se o CMT tiver namespace
    cm.label = r.MasterLabel;                             // preserva o label atual
    Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
    v.field = 'Country_Picklist_Value__c';
    v.value = dev2val.get(r.DeveloperName);
    cm.values.add(v);
    container.addMetadata(cm);
    n++;
}
System.debug(LoggingLevel.ERROR, 'CMTPOP | registros no container = ' + n + ' (esperado 12)');
if (n > 0) {
    Id jobId = Metadata.Operations.enqueueDeployment(container, null);
    System.debug(LoggingLevel.ERROR, 'CMTPOP | deployment enfileirado. JobId=' + jobId + ' -> ver Setup > Deployment Status');
} else {
    System.debug(LoggingLevel.ERROR, 'CMTPOP | nenhum registro encontrado - conferir DeveloperNames');
}
