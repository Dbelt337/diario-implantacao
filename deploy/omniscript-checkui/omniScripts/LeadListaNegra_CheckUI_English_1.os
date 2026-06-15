<?xml version="1.0" encoding="UTF-8"?>
<!--
  OmniScript LeadListaNegra/CheckUI - VERSAO AJUSTADA.
  Fluxo:
    SetLeadId (Set Values)            leadId = %ContextId%
    DRCarregaLead (DataRaptor Extract Action)  roda no LOAD -> DRLeadGetForListaNegra
        envia o Data JSON (contem leadId); DR filtra Lead WHERE Id = leadId
        retorna node lead[]  (array!)
    MapeiaDados (Set Values)          nome=%lead:0:Name%  documento=%lead:0:NationalId__c%
    Step "Dados do Cliente"           Nome, Documento (bindam aos nodes nome/documento)
    ChamaListaNegra (IP Action)       IP LeadListaNegra_Check -> node consulta
    Step "Resultado"                  MsgResultado (%consulta:mensagem%)

  Observacoes:
   - DRCarregaLead e DataRaptor EXTRACT Action (nao Turbo): Extract roda no load.
   - lead vem como ARRAY -> usar indice :0: nos merge fields.
   - integrationProcedureKey e bundle ja vem preenchidos porque a IP e o DataRaptor
     estao ATIVOS na org (a dependencia resolve no deploy). Se mesmo assim o Designer
     mostrar o elemento sem bind, RE-SELECIONE no dropdown (limitacao do metadado).
-->
<OmniScript xmlns="http://soap.sforce.com/2006/04/metadata">
    <elementTypeComponentMapping>{"ElementTypeToHTMLTemplateList":[]}</elementTypeComponentMapping>
    <isActive>false</isActive>
    <isIntegrationProcedure>false</isIntegrationProcedure>
    <isManagedUsingStdDesigner>true</isManagedUsingStdDesigner>
    <isMetadataCacheDisabled>false</isMetadataCacheDisabled>
    <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
    <isTestProcedure>false</isTestProcedure>
    <isWebCompEnabled>true</isWebCompEnabled>
    <language>English</language>
    <name>CheckUI</name>
    <omniProcessElements>
        <description>Captura o Id do Lead da record page em leadId.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>SetLeadId</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"elementValueMap":{"leadId":"%ContextId%"},"isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>1.0</sequenceNumber>
        <type>Set Values</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Roda no load: busca os dados do Lead (DRLeadGetForListaNegra) -> node lead[].</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>DRCarregaLead</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"bundle":"DRLeadGetForListaNegra","sendOnlyAdditionalInput":false,"extraPayload":{},"returnOnlyAdditionalOutput":false,"responseJSONPath":"","responseJSONNode":"","ignoreCache":false,"failOnStepError":false,"isActive":true,"id":"","executionConditionalFormula":"","actionMessage":"","sendJSONPath":"","sendJSONNode":""}</propertySetConfig>
        <sequenceNumber>2.0</sequenceNumber>
        <type>DataRaptor Extract Action</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Mapeia os dados do Lead (array) para os campos do modal.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>MapeiaDados</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"elementValueMap":{"nome":"%lead:0:Name%","documento":"%lead:0:NationalId__c%"},"isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>3.0</sequenceNumber>
        <type>Set Values</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Step de captura: documento e nome do cliente.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>StepDados</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"label":"Dados do Cliente","instructions":"Confira os dados do cliente e consulte a lista negra.","showSaveBtn":false,"showNextLabel":"Consultar Lista Negra","showPreviousLabel":"","isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>4.0</sequenceNumber>
        <type>Step</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Nome do cliente (vem do Lead).</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>1.0</level>
        <name>nome</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <parentElementName>StepDados</parentElementName>
        <propertySetConfig>{"label":"Nome","required":false,"readOnly":false,"hide":false,"isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>5.0</sequenceNumber>
        <type>Text</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Documento do cliente (vem do Lead - NationalId__c).</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>1.0</level>
        <name>documento</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <parentElementName>StepDados</parentElementName>
        <propertySetConfig>{"label":"Documento","required":false,"readOnly":false,"hide":false,"isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>6.0</sequenceNumber>
        <type>Text</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Chama a IP LeadListaNegra_Check e grava a resposta no node consulta.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>ChamaListaNegra</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"integrationProcedureKey":"LeadListaNegra_Check","sendOnlyAdditionalInput":true,"additionalInput":{"leadId":"%leadId%","documento":"%documento%","nome":"%nome%"},"returnOnlyAdditionalOutput":false,"responseJSONPath":"","responseJSONNode":"consulta","useFutureMethod":false,"useQueueable":false,"useContinuation":false,"failOnStepError":true,"chainOnStep":false,"isActive":true,"id":"","executionConditionalFormula":"","remoteTimeout":30000}</propertySetConfig>
        <sequenceNumber>7.0</sequenceNumber>
        <type>Integration Procedure Action</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Step de resultado da consulta.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>StepResultado</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"label":"Resultado","instructions":"","showSaveBtn":false,"showNextLabel":"Concluir","showPreviousLabel":"Voltar","isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>8.0</sequenceNumber>
        <type>Step</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Mensagem com o resultado da consulta.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>1.0</level>
        <name>MsgResultado</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <parentElementName>StepResultado</parentElementName>
        <propertySetConfig>{"text":"&lt;p&gt;Consulta realizada: &lt;b&gt;%consulta:statusListaNegra%&lt;/b&gt;&lt;/p&gt;&lt;p&gt;%consulta:mensagem%&lt;/p&gt;","isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>9.0</sequenceNumber>
        <type>Text Block</type>
    </omniProcessElements>
    <omniProcessType>OmniScript</omniProcessType>
    <propertySetConfig>{"persistentComponent":[{"render":false,"label":"","remoteClass":"","remoteMethod":"","remoteTimeout":30000,"remoteOptions":{"preTransformBundle":"","postTransformBundle":""},"preTransformBundle":"","postTransformBundle":"","sendJSONPath":"","sendJSONNode":"","responseJSONPath":"","responseJSONNode":"","id":"vlcCart","itemsKey":"cartItems","modalConfigurationSetting":{"modalHTMLTemplateId":"vlcProductConfig.html","modalController":"ModalProductCtrl","modalSize":"lg"}},{"render":false,"dispOutsideOmni":false,"label":"","remoteClass":"","remoteMethod":"","remoteTimeout":30000,"remoteOptions":{"preTransformBundle":"","postTransformBundle":""},"preTransformBundle":"","postTransformBundle":"","id":"vlcKnowledge","itemsKey":"knowledgeItems","modalConfigurationSetting":{"modalHTMLTemplateId":"","modalController":"","modalSize":"lg"}}],"allowSaveForLater":false,"saveNameTemplate":null,"saveExpireInDays":null,"saveForLaterRedirectPageName":"sflRedirect","saveForLaterRedirectTemplateUrl":"vlcSaveForLaterAcknowledge.html","saveContentEncoded":false,"saveObjectId":"%ContextId%","saveURLPatterns":{},"autoSaveOnStepNext":false,"elementTypeToHTMLTemplateMapping":{},"seedDataJSON":{},"trackingCustomData":{},"enableKnowledge":false,"bLK":false,"lkObjName":null,"knowledgeArticleTypeQueryFieldsMap":{},"timeTracking":false,"hideStepChart":false,"mergeSavedData":false,"visualforcePagesAvailableInPreview":{},"cancelType":"SObject","allowCancel":true,"cancelSource":"%ContextId%","cancelRedirectPageName":"OmniScriptCancelled","cancelRedirectTemplateUrl":"vlcCancelled.html","consoleTabLabel":"Consultar Lista Negra","wpm":false,"ssm":false,"message":{},"pubsub":false,"autoFocus":false,"currencyCode":"","showInputWidth":false,"rtpSeed":false,"consoleTabTitle":null,"consoleTabIcon":"custom:custom18","errorMessage":{"custom":[]},"stylesheet":{"newport":"","lightning":"","newportRtl":"","lightningRtl":""},"stepChartPlacement":"right","disableUnloadWarn":true,"scrollBehavior":"auto"}</propertySetConfig>
    <subType>CheckUI</subType>
    <type>LeadListaNegra</type>
    <uniqueName>LeadListaNegra_CheckUI_English_1</uniqueName>
    <versionNumber>1.0</versionNumber>
</OmniScript>
