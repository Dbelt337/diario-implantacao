<?xml version="1.0" encoding="UTF-8"?>
<OmniScript xmlns="http://soap.sforce.com/2006/04/metadata">
	<elementTypeComponentMapping>{"ElementTypeToHTMLTemplateList":[]}</elementTypeComponentMapping>
	<isActive>true</isActive>
	<isIntegrationProcedure>false</isIntegrationProcedure>
	<isManagedUsingStdDesigner>true</isManagedUsingStdDesigner>
	<isMetadataCacheDisabled>false</isMetadataCacheDisabled>
	<isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
	<isTestProcedure>false</isTestProcedure>
	<isWebCompEnabled>true</isWebCompEnabled>
	<language>English</language>
	<name>CrearCotizacion</name>
	<omniProcessElements>
		<isActive>true</isActive>
		<isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
		<level>0.0</level>
		<name>PasoConfirmar</name>
		<omniProcessVersionNumber>0.0</omniProcessVersionNumber>
		<propertySetConfig>{
  "label": "Crear Cotizacion",
  "instructions": "Se creara una cotizacion (borrador) ligada a este registro. Pulse Crear para continuar.",
  "showSaveBtn": false,
  "showNextLabel": "Crear",
  "showPreviousLabel": "",
  "isActive": true,
  "id": "",
  "executionConditionalFormula": "",
  "previousLabel": "",
  "nextLabel": "Crear"
}</propertySetConfig>
		<sequenceNumber>0.0</sequenceNumber>
		<type>Step</type>
	</omniProcessElements>
	<omniProcessElements>
		<description>Llama al IP GrupoQ/CrearQuote (sin Apex).</description>
		<isActive>true</isActive>
		<isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
		<level>0.0</level>
		<name>CrearQuote</name>
		<omniProcessVersionNumber>0.0</omniProcessVersionNumber>
		<propertySetConfig>{
  "integrationProcedureKey": "GrupoQ_CrearQuote",
  "sendOnlyAdditionalInput": true,
  "additionalInput": {
    "ContextId": "%ContextId%"
  },
  "returnOnlyAdditionalOutput": false,
  "responseJSONPath": "",
  "responseJSONNode": "resultado",
  "useFutureMethod": false,
  "useQueueable": false,
  "useContinuation": false,
  "failOnStepError": true,
  "chainOnStep": false,
  "isActive": true,
  "id": "",
  "executionConditionalFormula": "",
  "remoteTimeout": 30000,
  "remoteOptions": {
    "useFuture": false,
    "chainable": false,
    "preTransformBundle": "",
    "postTransformBundle": ""
  },
  "extraPayload": {
    "ContextId": "%ContextId%"
  },
  "sendOnlyExtraPayload": true
}</propertySetConfig>
		<sequenceNumber>1.0</sequenceNumber>
		<type>Integration Procedure Action</type>
	</omniProcessElements>
	<omniProcessElements>
		<isActive>true</isActive>
		<isOmniScriptEmbeddable>false</isOmniScriptEmbeddable>
		<level>0.0</level>
		<name>PasoResultado</name>
		<omniProcessVersionNumber>0.0</omniProcessVersionNumber>
		<propertySetConfig>{
  "label": "Cotizacion creada",
  "instructions": "Cotizacion creada: %resultado:quoteName% (Id %resultado:quoteId%). Estado Borrador, ligada al registro. Aparece en la lista relacionada de Cotizaciones.",
  "showSaveBtn": false,
  "showNextLabel": "",
  "showPreviousLabel": "",
  "isActive": true,
  "id": "",
  "executionConditionalFormula": "",
  "previousWidth": "0",
  "nextWidth": "0"
}</propertySetConfig>
		<sequenceNumber>2.0</sequenceNumber>
		<type>Step</type>
	</omniProcessElements>
	<omniProcessType>OmniScript</omniProcessType>
	<propertySetConfig>{
  "persistentComponent": [],
  "allowSaveForLater": false,
  "saveNameTemplate": null,
  "saveExpireInDays": null,
  "saveForLaterRedirectPageName": "sflRedirect",
  "saveForLaterRedirectTemplateUrl": "vlcSaveForLaterAcknowledge.html",
  "saveContentEncoded": false,
  "saveObjectId": "%ContextId%",
  "saveURLPatterns": {},
  "autoSaveOnStepNext": false,
  "elementTypeToHTMLTemplateMapping": {},
  "seedDataJSON": {},
  "trackingCustomData": {},
  "enableKnowledge": false,
  "bLK": false,
  "lkObjName": null,
  "knowledgeArticleTypeQueryFieldsMap": {},
  "timeTracking": false,
  "hideStepChart": true,
  "mergeSavedData": false,
  "visualforcePagesAvailableInPreview": {},
  "cancelType": "SObject",
  "allowCancel": true,
  "cancelSource": "%ContextId%",
  "cancelRedirectPageName": "OmniScriptCancelled",
  "cancelRedirectTemplateUrl": "vlcCancelled.html",
  "consoleTabLabel": "Crear Cotizacion",
  "wpm": false,
  "ssm": false,
  "message": {},
  "pubsub": false,
  "autoFocus": false,
  "currencyCode": "",
  "showInputWidth": false,
  "rtpSeed": false,
  "consoleTabTitle": null,
  "consoleTabIcon": "standard:quotes",
  "errorMessage": {
    "custom": []
  },
  "stylesheet": {
    "newport": "",
    "lightning": "",
    "newportRtl": "",
    "lightningRtl": ""
  },
  "stepChartPlacement": "right",
  "disableUnloadWarn": true,
  "scrollBehavior": "auto"
}</propertySetConfig>
	<subType>CrearCotizacion</subType>
	<type>GrupoQ</type>
	<uniqueName>GrupoQ_CrearCotizacion_English_1</uniqueName>
	<versionNumber>1.0</versionNumber>
</OmniScript>
