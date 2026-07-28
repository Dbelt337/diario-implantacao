# Hotfix crear cotizacion (28/07/2026) — PENDIENTE DE REBASE

ATENCION: Davi aviso que volvio a modificar el codigo en la org DESPUES del
retrieve de las 15h (base de esta carpeta). NO desplegar este paquete hasta
rebasear sobre un retrieve fresco (mismo manifest
package-retrieve-captura-org-actual.xml). Los ajustes son quirurgicos y se
reaplican en minutos sobre la version nueva.

## Ajustes contenidos (sobre el codigo real de Davi, nombres viejos)

1. classes/QuoteOrderService.cls
   - El guard "La oportunidad necesita un Pricebook" se reemplaza por
     resolveDefaultPricebookId(): primer pricebook custom activo (estandar
     como fallback) asignado a la Opportunity cuando Pricebook2Id viene
     null. El vendedor nunca elige catalogo; el mapa sociedad->pricebook
     reemplaza el default cuando GrupoQ defina los catalogos.
   - buildVehicleLineFromSelection(): si la Opportunity no tiene linea de
     vehiculo, se crea desde el vehiculo seleccionado en el flujo (match
     por nombre de modelo contra el pricebook; primer vehiculo del
     pricebook como ultimo recurso; filtro por CurrencyIsoCode de la Opp —
     org multimoneda). Evita el "List index out of bounds" en quotes[0].
   - Todo lo demas (comentarios, TODOs, DTOs, mocks de Davi) INTACTO.

2. lwc/ventaGuiadaModal/ventaGuiadaModal.js
   - handleCreateQuote: en vez de selectedVehicles: '[]' fijo, envia el
     this.selectedVehicle real como DTO con la forma exacta de
     QuoteOrderService.VehicleDTO (strings explicitos; sin campos extra
     del mock que puedan romper el JSON.deserialize).

## Secuencia al llegar el retrieve nuevo
1. Diff retrieve nuevo vs captura-org-20260728 (que aporto Davi).
2. Reaplicar los 2 ajustes sobre la version nueva.
3. Zip mdapi (solo QuoteOrderService + ventaGuiadaModal, ADITIVO, sin
   destructive) y deploy via Workbench.
4. Probar con el usuario de Santiago: venta guiada > Crear cotizacion.
