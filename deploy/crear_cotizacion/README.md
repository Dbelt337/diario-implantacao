# Paquete "Crear Cotización" (HU-014 v1)

Action que crea una **Cotización (Quote) nativa** en Borrador. Sin CPQ / sin OmniStudio.
Sirve en **Cuenta** (Persona Natural **y** Business) y en **Oportunidad**.

El flow detecta el contexto por el prefijo del Id del registro:
- `001` (Cuenta, sea persona o empresa) → `Quote.AccountId` directo.
- `006` (Oportunidad) → `Quote.OpportunityId` (el `AccountId` lo deriva Salesforce).

## Contenido
- `flows/GrupoQ_Crear_Cotacion.flow` — Screen Flow (Active, v62.0), con decisión Cuenta/Oportunidad.
- `quickActions/Account.Crear_Cotizacion.quickAction` — Action tipo Flow para Cuenta.
- `quickActions/Opportunity.Crear_Cotizacion.quickAction` — Action tipo Flow para Oportunidad.
- `package.xml` / `GrupoQ_Crear_Cotacion.zip` — para deploy mdapi.

## Deploy (mdapi, igual a Buscar_Lead)
```
sf project deploy start --metadata-dir deploy/crear_cotizacion --wait 10
# o clásico:
sfdx force:mdapi:deploy -d deploy/crear_cotizacion -w 10
```
(o subí `GrupoQ_Crear_Cotacion.zip` por Workbench → Deploy.)

## Paso manual (no se toca layout por metadata)
- Object Manager → **Account** → Page Layouts / Lightning Record Page → arrastrá **"Crear Cotización"**.
- Object Manager → **Opportunity** → Page Layouts / Lightning Record Page → arrastrá **"Crear Cotización"**.

Abrí una cuenta (persona o empresa) u oportunidad → botón **Crear Cotización** → la Quote nace ligada al registro.

## Notas
- Person Account: `Quote.AccountId` acepta cuentas persona igual que business — mismo camino, sin rama especial.
- Requiere Quotes Settings → **Create Quotes Without a Related Opportunity = ON** (ya está en el org).
  Si estuviera OFF, el camino Cuenta cae en la pantalla de error con el detalle; el camino Oportunidad funciona igual.
- Precio/pricebook por sociedad y líneas de producto = fuera de esta v1 (van en H3 de HU-014).
