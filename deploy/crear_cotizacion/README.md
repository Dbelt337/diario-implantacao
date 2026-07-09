# Paquete "Crear Cotización" (HU-014 v1)

Action en **Cuenta** que crea una **Cotización (Quote) nativa** ligada a la cuenta, en Borrador.
Sin CPQ / sin OmniStudio. Grava `Quote.AccountId` directo (quotes sin Opportunity ya habilitado).

## Contenido
- `flows/GrupoQ_Crear_Cotacion.flow` — Screen Flow (Active, v62.0).
- `quickActions/Account.Crear_Cotizacion.quickAction` — Action tipo Flow apuntando al flow.
- `package.xml` / `GrupoQ_Crear_Cotacion.zip` — para deploy mdapi.

## Deploy (mdapi, igual a Buscar_Lead)
```
sf project deploy start --metadata-dir deploy/crear_cotizacion --wait 10
# o con la CLI clásica:
sfdx force:mdapi:deploy -d deploy/crear_cotizacion -w 10
```
(o subí el zip `GrupoQ_Crear_Cotacion.zip` por Workbench → Deploy.)

## Único paso manual (no se toca el layout por metadata)
Object Manager → **Account** → *Page Layouts* (o Lightning Record Page) → arrastrá la action
**"Crear Cotización"** a *Mobile & Lightning Actions*. Listo: botón en la cuenta → crea la Quote.

## Nota
- Requiere Quotes Settings → **Create Quotes Without a Related Opportunity = ON** (ya está en el org).
- Precio/pricebook por sociedad y líneas de producto = fuera de esta v1 (van en H3 de HU-014).
