/* ============================================================================
   Cria o registro Sociedad_Config.P103 clonando um registro de Panama (P105)
   e sobrescrevendo os campos de identidade. READ do template + Metadata deploy.
   READ ONLY ate o enqueueDeployment (async -> Setup > Deployment Status).
   REVISAR o log 'P103CREATE' antes: confirme que os campos herdados de P105
   (moeda / locale / timezone / parent) valem tambem para P103.
   PRE-REQUISITO: campo Country_Picklist_Value__c ja deployado.
   ============================================================================ */
final String TEMPLATE = 'P105';   // registro de Panama usado como base
final String NOVO     = 'P103';

// overrides de identidade (o resto e herdado do template)
Map<String, Object> overrides = new Map<String, Object>{
    'SAP_Company_Code__c'       => 'P103',
    'IOU_DeveloperName__c'      => 'P103',
    'Country_Picklist_Value__c' => 'PA Panamá'
};

// 1) ler TODOS os campos custom do template (dinamico)
Map<String, Schema.SObjectField> fmap = Schema.SObjectType.Sociedad_Config__mdt.fields.getMap();
List<String> cols = new List<String>();
for (String k : fmap.keySet()) if (k.endsWith('__c')) cols.add(fmap.get(k).getDescribe().getName());

List<SObject> src = Database.query('SELECT ' + String.join(cols, ',') +
    ' FROM Sociedad_Config__mdt WHERE DeveloperName = :TEMPLATE LIMIT 1');
if (src.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'P103CREATE | template ' + TEMPLATE + ' NAO encontrado - abortando');
    return;
}
SObject t = src[0];

// 2) montar o novo registro
Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
cm.fullName = 'Sociedad_Config.' + NOVO;   // ajustar prefixo se o CMT tiver namespace
cm.label    = NOVO;
for (String col : cols) {
    Object val = overrides.containsKey(col) ? overrides.get(col) : t.get(col);
    if (val == null) continue;
    Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
    v.field = col;
    v.value = val;
    cm.values.add(v);
    System.debug(LoggingLevel.ERROR, 'P103CREATE | ' + col + ' = ' + val
        + (overrides.containsKey(col) ? '  (override)' : '  (herdado de ' + TEMPLATE + ')'));
}

// 3) deploy
Metadata.DeployContainer c = new Metadata.DeployContainer();
c.addMetadata(cm);
Id jobId = Metadata.Operations.enqueueDeployment(c, null);
System.debug(LoggingLevel.ERROR, 'P103CREATE | deploy enfileirado. JobId=' + jobId + ' -> Setup > Deployment Status');
