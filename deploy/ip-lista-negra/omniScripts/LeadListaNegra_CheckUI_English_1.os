<?xml version="1.0" encoding="UTF-8"?>
<!--
  OmniScript LeadListaNegra/CheckUI (UI da consulta de lista negra).
  Type=LeadListaNegra  SubType=CheckUI (SubType distinto da IP "Check" porque IP e
  OmniScript dividem o objeto OmniProcess: o uniqueName precisa ser unico).

  Estrutura raiz casada com um OmniScript real exportado (metadata_7):
    sem customJavaScript, sem omniProcessKey, com isManagedUsingStdDesigner,
    propertySetConfig raiz = default rico da Salesforce.
  Os omniProcessElements seguem o schema que ja deployou com sucesso na IP.

  Fluxo de tela:
    Step "Dados do Cliente"
       SetLeadId (Set Values)  leadId = %ContextId%   (Id do Lead na record page)
       documento (Text, obrigatorio)
       nome      (Text)
    ChamaListaNegra (Integration Procedure Action) -> IP LeadListaNegra_Check
       envia { leadId, documento, nome }; resposta no node "consulta"
    Step "Resultado"
       MsgResultado (Text Block) mostra %consulta:statusListaNegra% / %consulta:mensagem%

  isWebCompEnabled=true => ao ATIVAR no Designer gera o LWC, que aparece no dropdown
  "Lightning Web Component" da New Action do Lead.

  Pos-deploy: abrir UMA vez no Designer, RE-SELECIONAR a IP "LeadListaNegra_Check"
  no elemento ChamaListaNegra (colar JSON nao faz o bind) e ACTIVATE.
  Recomendado: Workbench Deploy em CHECK-ONLY antes do deploy real.
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
        <description>Step de captura: documento e nome do cliente.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>StepDados</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"label":"Dados do Cliente","instructions":"Informe o documento e o nome do cliente para consultar a lista negra.","showSaveBtn":false,"showNextLabel":"Consultar","showPreviousLabel":"","isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>1.0</sequenceNumber>
        <type>Step</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Captura o Id do Lead da record page em leadId.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>1.0</level>
        <name>SetLeadId</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <parentElementName>StepDados</parentElementName>
        <propertySetConfig>{"elementValueMap":{"leadId":"%ContextId%"},"isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>1.0</sequenceNumber>
        <type>Set Values</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Documento do cliente (obrigatorio).</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>1.0</level>
        <name>documento</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <parentElementName>StepDados</parentElementName>
        <propertySetConfig>{"label":"Documento","required":true,"readOnly":false,"hide":false,"placeholder":"Ex.: 1-2345-6789","help":"","helpText":"","isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>2.0</sequenceNumber>
        <type>Text</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Nome do cliente.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>1.0</level>
        <name>nome</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <parentElementName>StepDados</parentElementName>
        <propertySetConfig>{"label":"Nome","required":false,"readOnly":false,"hide":false,"placeholder":"Ex.: Juan Perez","isActive":true,"id":"","executionConditionalFormula":""}</propertySetConfig>
        <sequenceNumber>3.0</sequenceNumber>
        <type>Text</type>
    </omniProcessElements>
    <omniProcessElements>
        <description>Chama a IP LeadListaNegra_Check (mock) e grava resposta no node consulta.</description>
        <isActive>true</isActive>
        <isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
        <level>0.0</level>
        <name>ChamaListaNegra</name>
        <omniProcessVersionNumber>0.0</omniProcessVersionNumber>
        <propertySetConfig>{"integrationProcedureKey":"LeadListaNegra_Check","sendOnlyAdditionalInput":true,"additionalInput":{"leadId":"%leadId%","documento":"%documento%","nome":"%nome%"},"returnOnlyAdditionalOutput":false,"responseJSONPath":"","responseJSONNode":"consulta","useFutureMethod":false,"useQueueable":false,"useContinuation":false,"failOnStepError":true,"chainOnStep":false,"isActive":true,"id":"","executionConditionalFormula":"","remoteTimeout":30000}</propertySetConfig>
        <sequenceNumber>2.0</sequenceNumber>
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
        <sequenceNumber>3.0</sequenceNumber>
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
        <sequenceNumber>1.0</sequenceNumber>
        <type>Text Block</type>
    </omniProcessElements>
    <omniProcessType>OmniScript</omniProcessType>
    <propertySetConfig>{"persistentComponent":[{"render":false,"label":"","remoteClass":"","remoteMethod":"","remoteTimeout":30000,"remoteOptions":{"preTransformBundle":"","postTransformBundle":""},"preTransformBundle":"","postTransformBundle":"","sendJSONPath":"","sendJSONNode":"","responseJSONPath":"","responseJSONNode":"","id":"vlcCart","itemsKey":"cartItems","modalConfigurationSetting":{"modalHTMLTemplateId":"vlcProductConfig.html","modalController":"ModalProductCtrl","modalSize":"lg"}},{"render":false,"dispOutsideOmni":false,"label":"","remoteClass":"","remoteMethod":"","remoteTimeout":30000,"remoteOptions":{"preTransformBundle":"","postTransformBundle":""},"preTransformBundle":"","postTransformBundle":"","id":"vlcKnowledge","itemsKey":"knowledgeItems","modalConfigurationSetting":{"modalHTMLTemplateId":"","modalController":"","modalSize":"lg"}}],"allowSaveForLater":false,"saveNameTemplate":null,"saveExpireInDays":null,"saveForLaterRedirectPageName":"sflRedirect","saveForLaterRedirectTemplateUrl":"vlcSaveForLaterAcknowledge.html","saveContentEncoded":false,"saveObjectId":"%ContextId%","saveURLPatterns":{},"autoSaveOnStepNext":false,"elementTypeToHTMLTemplateMapping":{},"seedDataJSON":{},"trackingCustomData":{},"enableKnowledge":false,"bLK":false,"lkObjName":null,"knowledgeArticleTypeQueryFieldsMap":{},"timeTracking":false,"hideStepChart":false,"mergeSavedData":false,"visualforcePagesAvailableInPreview":{},"cancelType":"SObject","allowCancel":true,"cancelSource":"%ContextId%","cancelRedirectPageName":"OmniScriptCancelled","cancelRedirectTemplateUrl":"vlcCancelled.html","consoleTabLabel":"Consultar Lista Negra","wpm":false,"ssm":false,"message":{},"pubsub":false,"autoFocus":false,"currencyCode":"","showInputWidth":false,"rtpSeed":false,"consoleTabTitle":null,"consoleTabIcon":"custom:custom18","errorMessage":{"custom":[]},"stylesheet":{"newport":"","lightning":"","newportRtl":"","lightningRtl":""},"stepChartPlacement":"right","disableUnloadWarn":true,"scrollBehavior":"auto"}</propertySetConfig>
    <subType>CheckUI</subType>
    <type>LeadListaNegra</type>
    <uniqueName>LeadListaNegra_CheckUI_English_1</uniqueName>
    <versionNumber>1.0</versionNumber>
</OmniScript>
