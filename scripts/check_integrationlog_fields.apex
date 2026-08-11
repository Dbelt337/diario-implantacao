// Diagnóstico do IntegrationLog__c via Schema Describe.
// Executar: sf apex run -o <alias-da-org> --file scripts/check_integrationlog_fields.apex
// Saída no debug log: tipo do Name (Text vs Auto Number), campos obrigatórios
// no insert e acesso do usuário atual — cruzar com o payload que veio nulo.

SObjectType t = Schema.getGlobalDescribe().get('IntegrationLog__c');
if (t == null) {
    System.debug('ERRO: objeto IntegrationLog__c nao existe nesta org.');
    return;
}

DescribeSObjectResult d = t.getDescribe();
System.debug('=== Objeto: ' + d.getName() + ' | label: ' + d.getLabel());
System.debug('Acesso do usuario atual -> createable=' + d.isCreateable()
    + ' updateable=' + d.isUpdateable() + ' accessible=' + d.isAccessible());

List<String> obrigatorios = new List<String>();
List<String> semEscrita = new List<String>();

for (SObjectField f : d.fields.getMap().values()) {
    DescribeFieldResult fd = f.getDescribe();

    if (fd.isAutoNumber()) {
        System.debug('AUTO NUMBER: ' + fd.getName() + ' (null no payload e ignorado)');
    }
    // Obrigatório no insert: não aceita null e o chamador precisa informar valor
    if (!fd.isNillable() && fd.isCreateable() && !fd.isDefaultedOnCreate()) {
        obrigatorios.add(fd.getName());
    }
    // FLS: usuário atual não consegue gravar este campo (valor descartado no insert)
    if (fd.isCustom() && !fd.isCreateable() && !fd.isCalculated() && !fd.isAutoNumber()) {
        semEscrita.add(fd.getName());
    }
    if (fd.isNameField()) {
        System.debug('CAMPO NAME: tipo=' + fd.getType()
            + ' autoNumber=' + fd.isAutoNumber()
            + ' nillable=' + fd.isNillable()
            + (fd.isAutoNumber()
               ? ' -> OK enviar null'
               : ' -> Text: enviar null causa REQUIRED_FIELD_MISSING'));
    }
}

System.debug('OBRIGATORIOS no insert (falham com null): ' + obrigatorios);
System.debug('SEM ESCRITA para o usuario atual (FLS): ' + semEscrita);

// Campos que o payload do Mule envia — conferir um a um
for (String campo : new List<String>{
        'Name', 'RelatedRecordId__c', 'IntegrationName__c', 'IntegrationType__c',
        'TargetSystem__c', 'RequestPayload__c', 'ResponsePayload__c',
        'Status__c', 'Timestamp__c'}) {
    SObjectField f = d.fields.getMap().get(campo);
    if (f == null) {
        System.debug('PAYLOAD -> ' + campo + ': NAO EXISTE no objeto (INVALID_FIELD no POST)');
        continue;
    }
    DescribeFieldResult fd = f.getDescribe();
    System.debug('PAYLOAD -> ' + campo + ': tipo=' + fd.getType()
        + ' obrigatorio=' + (!fd.isNillable() && !fd.isDefaultedOnCreate())
        + ' gravavel(usuario atual)=' + fd.isCreateable()
        + ' tamanho=' + fd.getLength());
}
