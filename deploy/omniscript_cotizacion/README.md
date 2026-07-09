# Paquete OmniScript + Integration Procedure "GrupoQ/CrearCotizacion" (HU-014 v1)

Desde una **Cuenta** (Persona Natural o Business) o una **Oportunidad**, crea una **Cotización
(Quote) nativa** en Borrador. OmniStudio **Standard Runtime**, **sin Apex** — el DML lo hace un
DataRaptor Post dentro del Integration Procedure, igual que `GrupoQ_LeadUpsert`.

## Arquitectura (mismo patrón que LeadUpsert)
```
OmniScript  GrupoQ/CrearCotizacion/English
  PasoConfirmar (Step)
  CrearQuote (Integration Procedure Action)  ─────► IP GrupoQ_CrearCotizacion
  PasoResultado (Step, muestra %resultado:quoteId%)

IP  GrupoQ_CrearCotizacion  (Integration Procedure)
  ReturnIfNoContext (Response Action)      corta si falta ContextId
  PrepBase (Set Values)                    objTipo, Name, Status=Draft, ExpirationDate=hoy+30
  PrepAccount (Set Values, si 001)         quote.AccountId = ContextId
  PrepOpportunity (Set Values, si 006)     quote.OpportunityId = ContextId
  CrearQuote (DataRaptor Post Action)  ──► bundle DRQuoteInsert  (inserta Quote)
  RespSuccess (Response Action)            devuelve { success, quoteId, quoteName }
  RespError   (Response Action)            devuelve { success:false, message }

DataRaptor  DRQuoteInsert  (Load, JSON -> SObject Quote)
  quote:Name -> Name · quote:Status -> Status · quote:ExpirationDate -> ExpirationDate
  quote:AccountId -> AccountId · quote:OpportunityId -> OpportunityId
```
El id que no aplica no se escribe: los Set Values condicionales (001/006) solo agregan el campo
correspondiente al node `quote`, así el DataRaptor nunca recibe un id en blanco.
Person Account y Business comparten el prefijo `001` → mismo camino, sin rama especial.

## Contenido
- `omniScripts/GrupoQ_CrearCotizacion_English_1.os` — el OmniScript (llama al IP, no a Apex).
- `omniIntegrationProcedures/GrupoQ_CrearCotizacion_English_1.oip` — el Integration Procedure.
- `omniDataTransforms/DRQuoteInsert_1.rpt` — el DataRaptor Load que inserta la Quote.
- `package.xml` / `GrupoQ_CrearCotizacion_OS.zip` — deploy mdapi (v65). **Paquete completo.**

Idioma **English** (textos en español) a propósito: evita el bug del Designer Standard con Spanish.

## Deploy
```
sf project deploy start --metadata-dir deploy/omniscript_cotizacion --wait 10
# o subí GrupoQ_CrearCotizacion_OS.zip por Workbench > Deploy.
```

## Después del deploy
1. **Activar** el IP y el OmniScript en el OmniStudio Designer (compila el runtime).
2. Publicar la Action **OmniScript** en **Account** y **Opportunity** (New Action tipo OmniScript →
   `GrupoQ/CrearCotizacion/English`). El `ContextId` llega solo.

## Nota
- Path Cuenta requiere Quotes Settings → *Create Quotes Without a Related Opportunity = ON*.
- Precio/pricebook por sociedad y líneas = fuera de esta v1 (H3).
