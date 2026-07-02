/* ============================================================================
   Cria o registro Sociedad_Config.G105 clonando G101 (Guatemala) e
   sobrescrevendo a identidade. G105 ESTA na picklist CompanyCode__c mas NAO
   tinha registro no CMT -> leads G105 ficariam sem pais. Este script fecha isso.
   REVISAR o log 'G105CREATE' antes: confirme que os campos herdados de G101
   (moeda / locale / timezone / parent) valem para G105.
   PRE-REQUISITO: campo Country_Picklist_Value__c ja deployado.
   ============================================================================ */
final String TEMPLATE = 'G101';   // registro de Guatemala usado como base
final String NOVO     = 'G105';

Map<String, Object> overrides = new Map<String, Object>{
    'SAP_Company_Code__c'       => 'G105',
    'IOU_DeveloperName__c'      => 'G105',
    'Country_Picklist_Value__c' => 'GT Guatemala'
};

Map<String, Schema.SObjectField> fmap = Schema.SObjectType.Sociedad_Config__mdt.fields.getMap();
List<String> cols = new List<String>();
for (String k : fmap.keySet()) if (k.endsWith('__c')) cols.add(fmap.get(k).getDescribe().getName());

List<SObject> src = Database.query('SELECT ' + String.join(cols, ',') +
    ' FROM Sociedad_Config__mdt WHERE DeveloperName = :TEMPLATE LIMIT 1');
if (src.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'G105CREATE | template ' + TEMPLATE + ' NAO encontrado - abortando');
    return;
}
SObject t = src[0];

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
    System.debug(LoggingLevel.ERROR, 'G105CREATE | ' + col + ' = ' + val
        + (overrides.containsKey(col) ? '  (override)' : '  (herdado de ' + TEMPLATE + ')'));
}

Metadata.DeployContainer c = new Metadata.DeployContainer();
c.addMetadata(cm);
Id jobId = Metadata.Operations.enqueueDeployment(c, null);
System.debug(LoggingLevel.ERROR, 'G105CREATE | deploy enfileirado. JobId=' + jobId + ' -> Setup > Deployment Status');
