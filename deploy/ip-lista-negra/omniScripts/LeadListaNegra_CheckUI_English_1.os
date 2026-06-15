<?xml version="1.0" encoding="UTF-8"?>
<!--
  OmniScript LeadListaNegra/CheckUI (UI da consulta de lista negra).
  Type=LeadListaNegra  SubType=CheckUI  (SubType distinto da IP "Check" para
  o uniqueName nao colidir no objeto OmniProcess).

  Fluxo de tela:
    Step "Dados do Cliente"
       SetLeadId (Set Values)  leadId = %ContextId%   (Id do Lead na record page)
       documento (Text, obrigatorio)
       nome      (Text)
    ChamaListaNegra (Integration Procedure Action) -> IP LeadListaNegra_Check
       envia { leadId, documento, nome }, grava resposta no node "consulta"
    Step "Resultado"
       MsgResultado (Text Block) mostra %consulta:statusListaNegra% / %consulta:mensagem%

  isWebCompEnabled=true => ao ATIVAR no Designer gera o LWC, que entao aparece no
  dropdown "Lightning Web Component" da New Action do Lead.

  ============================ AVISO (igual ao da IP) ============================
  A estrutura exata do metadado OmniProcess para OmniScript (campos de
  OmniProcessElement, parentElementName, serializacao do propertySetConfig de
  elementos de UI) NAO pode ser confirmada contra a doc oficial Salesforce neste
  ambiente de build (developer/help.salesforce.com -> 403). Este arquivo segue o
  melhor conhecimento do schema Standard Runtime. ANTES do deploy real:
    1) Workbench Deploy em CHECK-ONLY (Single Package + Rollback On Error);
    2) deployar de verdade;
    3) abrir UMA vez no OmniStudio Designer: RE-SELECIONE a IP "LeadListaNegra_Check"
       no elemento ChamaListaNegra (colar JSON nao faz o bind) e confirme os campos
       do Step; depois ACTIVATE para gerar o LWC.
  ===============================================================================
-->
<OmniScript xmlns="http://soap.sforce.com/2006/04/metadata">
    <customJavaScript>{"ContextId":"00QXXXXXXXXXXXXXXX"}</customJavaScript>
    <elementTypeComponentMapping>{"ElementTypeToHTMLTemplateList":[]}</elementTypeComponentMapping>
    <isActive>false</isActive>
    <isIntegrationProcedure>false</isIntegrationProcedure>
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
        <propertySetConfig>{"integrationProcedureKey":"LeadListaNegra_Check","sendOnlyAdditionalInput":true,"additionalInput":{"leadId":"%leadId%","documento":"%documento%","nome":"%nome%"},"returnOnlyAdditionalOutput":false,"responseJSONPath":"","responseJSONNode":"consulta","useFutureMethod":false,"useQueueable":false,"useContinuation":false,"failOnStepError":true,"chainOnStep":false,"invokeMode":"","isActive":true,"id":"","executionConditionalFormula":"","remoteTimeout":30000}</propertySetConfig>
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
    <omniProcessKey>LeadListaNegra_CheckUI</omniProcessKey>
    <omniProcessType>OmniScript</omniProcessType>
    <propertySetConfig>{"description":"Consulta lista negra do cliente e grava o resultado no Lead.","allowSaveForLater":false,"persistComponentState":false,"trackingCustomData":{},"width":"","cssName":"","alpacaTheme":"","seedDataJSON":{},"errorMessage":{},"isWebCompEnabled":true}</propertySetConfig>
    <subType>CheckUI</subType>
    <type>LeadListaNegra</type>
    <uniqueName>LeadListaNegra_CheckUI_English_1</uniqueName>
    <versionNumber>1.0</versionNumber>
</OmniScript>
