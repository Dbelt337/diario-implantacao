/* ============================================================================
   US-006a — Carga do registro Default da CMT Aprobador_Datos_Sensibles__mdt
   Anonymous Apex (one-off, carga de DADOS de config — nao e Apex de solucao).
   >>> TROCAR o username abaixo pelo aprovador real antes de rodar. <<<
   ============================================================================ */
final String APROBADOR_USERNAME = 'CAMBIAR_POR_APROBADOR@grupoq.com.devsales';  // <-- EDITAR

Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
cm.fullName = 'Aprobador_Datos_Sensibles.Default';   // API do tipo . DeveloperName do registro
cm.label = 'Default';

Metadata.CustomMetadataValue vDef = new Metadata.CustomMetadataValue();
vDef.field = 'Es_Default__c';
vDef.value = true;
cm.values.add(vDef);

Metadata.CustomMetadataValue vUser = new Metadata.CustomMetadataValue();
vUser.field = 'Aprobador_Username__c';
vUser.value = APROBADOR_USERNAME;
cm.values.add(vUser);

Metadata.DeployContainer container = new Metadata.DeployContainer();
container.addMetadata(cm);
Metadata.Operations.enqueueDeployment(container, null);
System.debug(LoggingLevel.ERROR, 'CMT | enfileirado deploy do registro Default com aprobador=' + APROBADOR_USERNAME);
