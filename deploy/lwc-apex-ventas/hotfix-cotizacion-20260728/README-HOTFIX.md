# Hotfix crear cotizacion (28/07/2026) — v2, MERGEADO con las changes de Davi

Base: retrieve fresco del 28/07 (~15:20, retrieve_09SWK00000RFCkb2AH) que ya
incluye las changes de Davi: mapping disponibilidad->Status en la Service y
el envio del selectedVehicle real desde ventaGuiadaModal (por eso el paquete
ya NO toca el LWC — solo la clase, aditivo, sin destructive).

Paquete: Hotfix_CrearCotizacion_mdapi_v2.zip (Workbench > Migration >
Deploy, Single Package + Rollback On Error).

## Merge contenido en classes/QuoteOrderService.cls

De Davi (intacto): nota de flujo single-quote, VehicleDTO desde
selectedVehicles, mapping de status por disponibilidad, comentarios y TODOs.

Ajustes nuestros encima:
1. El guard "La oportunidad necesita un Pricebook" se reemplaza por
   resolveDefaultPricebookId(): primer pricebook custom activo (estandar
   como fallback) asignado a la Opportunity cuando Pricebook2Id viene null.
   El vendedor nunca elige catalogo; el mapa sociedad->pricebook reemplaza
   el default cuando GrupoQ defina los catalogos.
2. buildVehicleLineFromSelection(): si la Opportunity no tiene linea de
   vehiculo, se crea desde el vehiculo seleccionado en el flujo (match por
   nombre de modelo contra el pricebook; primer vehiculo del pricebook como
   ultimo recurso; filtro por CurrencyIsoCode de la Opp — org multimoneda).
   Evita el "List index out of bounds" en quotes[0].
3. safeQuoteStatus(): el mapping de Davi se aplica SOLO si el valor existe
   en el picklist activo de Quote.Status. Hoy la org tiene los statuses
   default (Draft, Presented, Accepted...), asi que "En tránsito"/"Pedido
   futuro"/"Pendiente" romperian el insert con
   INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST. En cuanto Davi agregue esos
   valores en Setup > Quote Statuses (+ Record Types), el mapping entra en
   vigor SIN redeploy. Guard de null en vehiclesDTO.get(0) incluido.
   Nota registrada para Davi: la logica del ternario esta invertida (stock
   disponible -> "En tránsito") y los usados sin stockCentral/stockDealer
   caen en null != 0 = true; el lo va a retrabajar ("changes na logica do
   status") — el guard mantiene el flujo estable mientras tanto.

## Post-deploy
1. Avisar a Davi que la Service cambio en la org: RETRIEVE antes de seguir
   editando (sus proximas changes de status van encima de este merge).
2. Probar con el usuario de Santiago: venta guiada > Crear cotizacion.
