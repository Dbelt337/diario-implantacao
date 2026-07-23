# Esqueleto LWC + Apex del flujo de ventas (GUIA v5)

Scaffold en formato SFDX de la arquitectura hibrida aprobada en el direcional:
LWC y Apex SOLO en interfaz e integracion; el modelo, la cotizacion, el pedido
y la assetizacion son nativos; las reglas viven en el BRE.

## GOBERNANZA — leer antes de desplegar
- NO se despliega hasta el aval de la validacion LWC vs OmniStudio con
  Salesforce (reunion con Producto en agenda via Felipe Pajon). Este scaffold
  es preparacion versionada en el repositorio.
- Al desplegar: registrar cada componente en la DLG como "Ventas / HU-042"
  (o la HU que corresponda) el mismo dia.
- Prerequisito de integracion: Named Credential "MuleSoftPricesInventory"
  configurada por ambiente (autenticacion de sistema; si Mule exigiera OAuth
  por usuario, revisar la estrategia ANTES de construir — limite de la GUIA).

## Capa Apex (services de la pestana "Capas y componentes")
- SapInventoryService (+Test): Continuation @AuraEnabled(continuation=true
  cacheable=true) contra callout:MuleSoftPricesInventory/api/v1/
  prices-and-inventory. DTOs request/response incluidos.
- PricingService: orquesta PricebookEntry + BRE (tasa de referencia). Stub.
- QuoteOrderService: cotizacion y pedido nativos por Record Type. Stub.
- SapOrderService: Queueable + AllowsCallouts; publica SapOrderResponse__e. Stub.
- MaterialSearchService: busqueda unificada local -> SAP -> upsert ->
  derivacion a solicitud (dominio Gestion de Productos). Stub.
- VentasTestDataFactory (@isTest) y SapCalloutMockFactory (@isTest):
  patron de datos de prueba y mocks del Mule (aporte de Davi en la GUIA).

## Capa LWC
- ventaGuiadaAction (padre, expuesto como accion/record page): recibe recordId
  por setter @api y enruta por Record Type.
- ventaVehiculo / ventaUsados / contraventaRepuestos / ventaPA (hijos, delgados).

## Platform Event
- SapOrderResponse__e (HighVolume, PublishAfterCommit) con OrderId (clave del
  filtro de canal), numero SAP, estado y error. API sin underscores por la
  GRPQM Naming Convention — la GUIA cita "Sap_Order_Response__e"; ajustar la
  GUIA a SapOrderResponse__e (decision de naming, registrar).
- Gobernanza empApi: suscripcion acotada + PlatformEventChannel con filtro;
  el retorno de factura NO usa empApi (actualizacion del pedido + Custom
  Notification).

## Pendientes de diseno antes de completar los stubs
1. Record Types definitivos de Opportunity/Quote (DeveloperNames usados en el
   router son placeholders: VentaVehiculo/VentaUsados/ContraventaRepuestos/VentaPA).
2. Contrato JSON definitivo del Mule (campos del request/response).
3. Invocacion del BRE desde Apex para PricingService (o mover esa lectura a
   la LWC via flow/action segun rendimiento).
