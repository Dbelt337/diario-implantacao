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
  Prep (Set Values)                        objTipo=LEFT(ContextId,3); arma node "quote"
                                           AccountId si 001 / OpportunityId si 006
  CrearQuote (DataRaptor Post Action)  ──► bundle DRQuoteInsert  (inserta Quote)
  RespSuccess (Response Action)            devuelve { success, quoteId, quoteName }
  RespError   (Response Action)            devuelve { success:false, message }
```
Person Account y Business comparten el prefijo `001` → mismo camino, sin rama especial.

## Contenido
- `omniScripts/GrupoQ_CrearCotizacion_English_1.os` — el OmniScript (llama al IP, no a Apex).
- `omniIntegrationProcedures/GrupoQ_CrearCotizacion_English_1.oip` — el Integration Procedure.
- `package.xml` / `GrupoQ_CrearCotizacion_OS.zip` — deploy mdapi (v65).

Idioma **English** (textos en español) a propósito: evita el bug del Designer Standard con Spanish.

## Dependencia: DataRaptor `DRQuoteInsert`  (Post/Load)
El IP referencia un DataRaptor Load llamado **`DRQuoteInsert`** (campo `bundle` del elemento
`CrearQuote`), tal como `InsertLead` referencia `DRLeadInsertMapper`. Mapea el node de entrada
`quote` → objeto **Quote**:

| Input (node `quote`) | Output (Quote) | Nota |
|---|---|---|
| `Name` | `Name` | |
| `Status` | `Status` | "Draft" |
| `ExpirationDate` | `ExpirationDate` | |
| `AccountId` | `AccountId` | **Ignorar en blanco** (viene vacío en path Oportunidad) |
| `OpportunityId` | `OpportunityId` | **Ignorar en blanco** (viene vacío en path Cuenta) |

Salida del DR: el Id del registro creado, referenciable como `%CrearQuote:Quote_1:Id%`.

> Es el único componente que falta para dejar el paquete 100% desplegable. No lo incluyo inventado
> para no romper el deploy; se genera 1:1 con el schema de un DataRaptor Load real del org.

## Deploy
```
sf project deploy start --metadata-dir deploy/omniscript_cotizacion --wait 10
```
(el DR `DRQuoteInsert` debe existir en el org antes de ejecutar el flujo — deploya con el paquete
o créalo aparte.)

## Después del deploy
1. **Activar** el IP y el OmniScript en el OmniStudio Designer (compila el runtime).
2. Publicar la Action **OmniScript** en **Account** y **Opportunity** (New Action tipo OmniScript →
   `GrupoQ/CrearCotizacion/English`). El `ContextId` llega solo.

## Nota
- Path Cuenta requiere Quotes Settings → *Create Quotes Without a Related Opportunity = ON*.
- Precio/pricebook por sociedad y líneas = fuera de esta v1 (H3).
