# Paquete OmniScript "GrupoQ/CrearCotizacion" (HU-014 v1)

OmniScript que, desde una **Cuenta** (Persona Natural o Business) o una **Oportunidad**, crea una
**Cotización (Quote) nativa** en Borrador. OmniStudio **Standard Runtime** (sin Vlocity/CPQ).

El OmniScript no hace DML: la grabación la hace su **Remote Action Apex** `GrupoQ_CrearCotizacion`
(el "hijo" headless, sancionado por el diseño en `auditoria/ajustes/OMNISCRIPT_criar_cotacao.md` §4).
La Apex resuelve el contexto por el prefijo del Id: `001` Cuenta → `Quote.AccountId`; `006`
Oportunidad → `Quote.OpportunityId`. Person Account y Business comparten el prefijo `001`, mismo camino.

## Contenido
- `classes/GrupoQ_CrearCotizacion.cls` — Remote Action (`System.Callable`), método `crearCotizacion`.
- `classes/GrupoQ_CrearCotizacionTest.cls` — pruebas (cuenta, oportunidad, contexto inválido, sin contexto).
- `omniScripts/GrupoQ_CrearCotizacion_English_1.os` — el OmniScript: Paso Confirmar → Remote Action → Paso Resultado.
- `package.xml` / `GrupoQ_CrearCotizacion_OS.zip` — deploy mdapi (v65).

Idioma del OmniScript = **English** (los textos van en español). Es a propósito: evita el bug del
Designer en Standard Runtime con Spanish ya identificado en la auditoría.

## Deploy (mdapi)
```
sf project deploy start --metadata-dir deploy/omniscript_cotizacion --wait 10
# o subí GrupoQ_CrearCotizacion_OS.zip por Workbench > Deploy.
```

## Después del deploy (2 pasos)
1. **Activar el OmniScript**: abrí `GrupoQ/CrearCotizacion/English` en el OmniStudio Designer y
   pulsá **Activate** (esto compila el componente LWC de runtime). Ya viene `isActive=true`, pero el
   Designer regenera el artefacto compilado en la activación — es el paso estándar de OmniStudio.
2. **Lanzarlo como Action**: Object Manager → **Account** y **Opportunity** → New Action tipo
   *OmniScript* apuntando a `GrupoQ/CrearCotizacion/English` (o el LWC `omniscriptGrupoQCrearCotizacionEnglish`
   en la Lightning Record Page). Arrastralo al layout. El `ContextId` llega solo.

## Nota
- Requiere Quotes habilitado. El path Cuenta requiere Quotes Settings →
  *Create Quotes Without a Related Opportunity = ON* (ya está en el org); si estuviera OFF, el path
  Oportunidad funciona igual y el de Cuenta devuelve el error en la Remote Action.
- Precio/pricebook por sociedad y líneas de producto = fuera de esta v1 (van en H3 de HU-014, y es
  donde el OmniScript crecerá con la búsqueda de repuestos y el precio SAP).
