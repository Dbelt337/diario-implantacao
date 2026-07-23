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

## Publicacion del boton "Venta guiada"
- La pagina "GQ Opportunity - Retail" usa ACCIONES DINAMICAS en el Highlights
  Panel (App Builder > Highlights Panel > Actions) — el boton se agrega/quita
  ahi, no en el page layout clasico.
- Al reemplazar una quick action (borrado + recreacion), la referencia vieja
  en el Highlights Panel queda rota ("Highlights Panel is invalid"): quitar la
  entrada muerta con la X, Add Action con la nueva y Save.
- El launcher actual es headless: el click abre directamente el LightningModal
  grande (ventaGuiadaModal) con el step-by-step; el sub-modal de confirmacion
  (cotizacionConfirmModal) demuestra el patron de modales apilados.

## Mock v5 — pasos de Descuentos y Pago (23/07)
El modal paso a 5 pasos: Vehiculo -> Precio y stock -> Descuentos -> Pago ->
Cotizacion. Todo sigue siendo MOCK de presentacion; lo real esta anotado en
cada pantalla.
- Descuentos: input de descuento con calculo en vivo del total. Hasta CRC
  700.000 (parametro simulado del precio minimo) se aplica directo; por encima
  se bloquea el Siguiente y se abre el sub-modal aprobacionDescuentoModal
  (aprobacion simulada del Gerente de Sucursal). Real: precio minimo por
  modelo en Decision Matrix (BRE) + Approval Process nativo; programas de
  descuento via Rebate Management / Price Protection (licenciados). Cambiar el
  monto invalida la aprobacion anterior.
- Pago: Contado o Financiado (CrediQ). Financiado calcula en vivo la cuota
  estimada (sistema frances: prima sugerida 30%, plazo 36-72 meses, tasa de
  referencia 9,5% anual — parametros SIMULADOS) y el boton "Llamar al flujo
  del financiero (CrediQ)" simula el disparo. Real: esta pantalla solo LLAMA
  el flujo de la frente financiera; tasas, seguros y aprobacion crediticia se
  resuelven alla. La cuota es referencia comercial, no oferta de credito.
- La Cotizacion final refleja descuento, forma de pago y cuota; el sub-modal
  de confirmacion recibe el total por @api (ya no esta fijo en el HTML).
- Paquete: Esqueleto_LWC_Apex_Ventas_mdapi_v5.zip (agrega
  aprobacionDescuentoModal y actualiza ventaGuiadaModal y
  cotizacionConfirmModal; deploy aditivo sobre el v4, sin destructive).

## Encaje de otros flujos (HU-042 y hermanas)
El padre enruta por Record Type de la Opportunity (ventaVehiculo /
ventaUsados / contraventaRepuestos / ventaPA). El patron para sumar un flujo
nuevo es: definir su secuencia de pasos (arreglo STEPS propio), reusar los
pasos comunes (busqueda, precio/stock, descuento, pago, resumen) y solo
construir los pasos especificos del negocio (ej. contraventa: item por linea
con precio dinamico SAP; usados: avaluo/trade-in como entrada). Los services
Apex son los mismos para todos los flujos — cambia la composicion de la UI,
no la capa de integracion.

