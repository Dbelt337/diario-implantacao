/* ============================================================================
   US-006a CR — Carga da matriz de aprobadores (CMT) via Apex (Metadata.Operations).
   Anonymous Apex, one-off, carga de DADOS de config. Idempotente (upsert por DevName).
   75 regras + Default. Deploy de CMT via metadata-zip da UNKNOWN_EXCEPTION
   nesta org -> Apex e o caminho confiavel (proven).
   ============================================================================ */
List<String> rows = new List<String>{
        'C101|APP|ContaCorriente|MDG_GCCC|C101_APP_ContaCorriente',
        'C101|APP|CrediQ|MDG_CREDIQ|C101_APP_CrediQ',
        'C101|APP|SinCredito|MDG_GCL6|C101_APP_SinCredito',
        'C101|Autopits|ContaCorriente|MDG_GCCC|C101_Autopits_ContaCorriente',
        'C101|Autopits|CrediQ|MDG_CREDIQ|C101_Autopits_CrediQ',
        'C101|Autopits|SinCredito|MDG_G019|C101_Autopits_SinCredito',
        'C101|CRM|ContaCorriente|MDG_GCCC|C101_CRM_ContaCorriente',
        'C101|CRM|CrediQ|MDG_CREDIQ|C101_CRM_CrediQ',
        'C101|CRM|SinCredito|MDG_G006|C101_CRM_SinCredito',
        'C101|Call Center|ContaCorriente|MDG_GCCC|C101_Call_Center_ContaCorriente',
        'C101|Call Center|CrediQ|MDG_CREDIQ|C101_Call_Center_CrediQ',
        'C101|Call Center|SinCredito|MDG_GCL6|C101_Call_Center_SinCredito',
        'C101|FORMULARIO|ContaCorriente|MDG_GCCC|C101_FORMULARIO_ContaCorriente',
        'C101|FORMULARIO|CrediQ|MDG_CREDIQ|C101_FORMULARIO_CrediQ',
        'C101|FORMULARIO|SinCredito|MDG_GCL6|C101_FORMULARIO_SinCredito',
        'C101|Online|ContaCorriente|MDG_GCCC|C101_Online_ContaCorriente',
        'C101|Online|CrediQ|MDG_CREDIQ|C101_Online_CrediQ',
        'C101|Online|SinCredito|MDG_G003|C101_Online_SinCredito',
        'C101|PA|ContaCorriente|MDG_GCCC|C101_PA_ContaCorriente',
        'C101|PA|CrediQ|MDG_CREDIQ|C101_PA_CrediQ',
        'C101|PA|SinCredito|MDG_G022|C101_PA_SinCredito',
        'C101|Pintura|ContaCorriente|MDG_GCCC|C101_Pintura_ContaCorriente',
        'C101|Pintura|CrediQ|MDG_CREDIQ|C101_Pintura_CrediQ',
        'C101|Pintura|SinCredito|MDG_G022|C101_Pintura_SinCredito',
        'C101|Repuestos|ContaCorriente|MDG_GCCC|C101_Repuestos_ContaCorriente',
        'C101|Repuestos|CrediQ|MDG_CREDIQ|C101_Repuestos_CrediQ',
        'C101|Repuestos|SinCredito|MDG_G022|C101_Repuestos_SinCredito',
        'C101|Taller|ContaCorriente|MDG_GCCC|C101_Taller_ContaCorriente',
        'C101|Taller|CrediQ|MDG_CREDIQ|C101_Taller_CrediQ',
        'C101|Taller|SinCredito|MDG_G022|C101_Taller_SinCredito',
        'C101|Trámites|ContaCorriente|MDG_GCCC|C101_Tr_mites_ContaCorriente',
        'C101|Trámites|CrediQ|MDG_CREDIQ|C101_Tr_mites_CrediQ',
        'C101|Trámites|SinCredito|MDG_G003|C101_Tr_mites_SinCredito',
        'C101|Usados|ContaCorriente|MDG_GCCC|C101_Usados_ContaCorriente',
        'C101|Usados|CrediQ|MDG_CREDIQ|C101_Usados_CrediQ',
        'C101|Usados|SinCredito|MDG_G003|C101_Usados_SinCredito',
        'C101|Vehículos|ContaCorriente|MDG_GCCC|C101_Veh_culos_ContaCorriente',
        'C101|Vehículos|CrediQ|MDG_CREDIQ|C101_Veh_culos_CrediQ',
        'C101|Vehículos|SinCredito|MDG_G003|C101_Veh_culos_SinCredito',
        'C101|WEB|ContaCorriente|MDG_GCCC|C101_WEB_ContaCorriente',
        'C101|WEB|CrediQ|MDG_CREDIQ|C101_WEB_CrediQ',
        'C101|WEB|SinCredito|MDG_GCL6|C101_WEB_SinCredito',
        'C105|APP|ContaCorriente|MDG_GCCC|C105_APP_ContaCorriente',
        'C105|APP|CrediQ|MDG_CREDIQ|C105_APP_CrediQ',
        'C105|APP|SinCredito|MDG_GCL6|C105_APP_SinCredito',
        'C105|Autopits|ContaCorriente|MDG_GCCC|C105_Autopits_ContaCorriente',
        'C105|Autopits|CrediQ|MDG_CREDIQ|C105_Autopits_CrediQ',
        'C105|Autopits|SinCredito|MDG_G019|C105_Autopits_SinCredito',
        'C105|CRM|ContaCorriente|MDG_GCCC|C105_CRM_ContaCorriente',
        'C105|CRM|CrediQ|MDG_CREDIQ|C105_CRM_CrediQ',
        'C105|CRM|SinCredito|MDG_G006|C105_CRM_SinCredito',
        'C105|Distribuidor|ContaCorriente|MDG_GCCC|C105_Distribuidor_ContaCorriente',
        'C105|Distribuidor|CrediQ|MDG_CREDIQ|C105_Distribuidor_CrediQ',
        'C105|Distribuidor|SinCredito|MDG_G003|C105_Distribuidor_SinCredito',
        'C105|FORMULARIO|ContaCorriente|MDG_GCCC|C105_FORMULARIO_ContaCorriente',
        'C105|FORMULARIO|CrediQ|MDG_CREDIQ|C105_FORMULARIO_CrediQ',
        'C105|FORMULARIO|SinCredito|MDG_GCL6|C105_FORMULARIO_SinCredito',
        'C105|Online|ContaCorriente|MDG_GCCC|C105_Online_ContaCorriente',
        'C105|Online|CrediQ|MDG_CREDIQ|C105_Online_CrediQ',
        'C105|Online|SinCredito|MDG_G003|C105_Online_SinCredito',
        'C105|Repuestos|ContaCorriente|MDG_GCCC|C105_Repuestos_ContaCorriente',
        'C105|Repuestos|CrediQ|MDG_CREDIQ|C105_Repuestos_CrediQ',
        'C105|Repuestos|SinCredito|MDG_G022|C105_Repuestos_SinCredito',
        'C105|Taller|ContaCorriente|MDG_GCCC|C105_Taller_ContaCorriente',
        'C105|Taller|CrediQ|MDG_CREDIQ|C105_Taller_CrediQ',
        'C105|Taller|SinCredito|MDG_G022|C105_Taller_SinCredito',
        'C105|Trámites|ContaCorriente|MDG_GCCC|C105_Tr_mites_ContaCorriente',
        'C105|Trámites|CrediQ|MDG_CREDIQ|C105_Tr_mites_CrediQ',
        'C105|Trámites|SinCredito|MDG_G003|C105_Tr_mites_SinCredito',
        'C105|Vehículos|ContaCorriente|MDG_GCCC|C105_Veh_culos_ContaCorriente',
        'C105|Vehículos|CrediQ|MDG_CREDIQ|C105_Veh_culos_CrediQ',
        'C105|Vehículos|SinCredito|MDG_G003|C105_Veh_culos_SinCredito',
        'C105|WEB|ContaCorriente|MDG_GCCC|C105_WEB_ContaCorriente',
        'C105|WEB|CrediQ|MDG_CREDIQ|C105_WEB_CrediQ',
        'C105|WEB|SinCredito|MDG_GCL6|C105_WEB_SinCredito'
};
Metadata.DeployContainer c = new Metadata.DeployContainer();
for (String r : rows) {
    List<String> p = r.split('\\|');
    Metadata.CustomMetadata cm = new Metadata.CustomMetadata();
    cm.fullName = 'Aprobador_Datos_Sensibles.' + p[4];
    cm.label = p[4];
    Metadata.CustomMetadataValue v1 = new Metadata.CustomMetadataValue(); v1.field='Sociedad__c'; v1.value=p[0]; cm.values.add(v1);
    Metadata.CustomMetadataValue v2 = new Metadata.CustomMetadataValue(); v2.field='Departamento__c'; v2.value=p[1]; cm.values.add(v2);
    Metadata.CustomMetadataValue v3 = new Metadata.CustomMetadataValue(); v3.field='Escenario_Credito__c'; v3.value=p[2]; cm.values.add(v3);
    Metadata.CustomMetadataValue v4 = new Metadata.CustomMetadataValue(); v4.field='Grupo_Aprobador__c'; v4.value=p[3]; cm.values.add(v4);
    Metadata.CustomMetadataValue v5 = new Metadata.CustomMetadataValue(); v5.field='Es_Default__c'; v5.value=false; cm.values.add(v5);
    c.addMetadata(cm);
}
/* Default (fallback) */
Metadata.CustomMetadata cd = new Metadata.CustomMetadata();
cd.fullName='Aprobador_Datos_Sensibles.Default'; cd.label='Default';
Metadata.CustomMetadataValue d1=new Metadata.CustomMetadataValue(); d1.field='Es_Default__c'; d1.value=true; cd.values.add(d1);
Metadata.CustomMetadataValue d2=new Metadata.CustomMetadataValue(); d2.field='Grupo_Aprobador__c'; d2.value='MDG_Default'; cd.values.add(d2);
c.addMetadata(cd);
Metadata.Operations.enqueueDeployment(c, null);
System.debug(LoggingLevel.ERROR, 'CMT | enfileirado ' + rows.size() + ' regras + Default');
