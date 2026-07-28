# Esqueleto LWC + Apex del flujo de ventas (GUIA v5)

Scaffold en formato SFDX de la arquitectura hibrida aprobada en el direcional:
LWC y Apex SOLO en interfaz e integracion; el modelo, la cotizacion, el pedido
y la assetizacion son nativos; las reglas viven en el BRE.

## GOBERNANZA — leer antes de desplegar
- DECISION 27/07/2026 (Diego Braz): seguir con LWC+Apex SIN esperar el aval
  de la validacion con Salesforce (Felipe Pajon). Este scaffold es el camino
  oficial del build; si el aval posterior trae observaciones, se incorporan
  como ajustes, no como cambio de rumbo.
- Regla BFF (27/07): una pantalla = una llamada Apex. GuidedSellingController
  agrega todo lo que la pantalla renderiza en UN payload (ViewModel);
  MuleSoft agrega del lado SAP (precio + stock + disponibilidad futura en un
  solo endpoint). Render local primero, prefetch de la consulta SAP durante
  el paso Accesorios, cacheable=true en lecturas.
- Al desplegar: registrar cada componente en la DLG como "Ventas / HU-042"
  (o la HU que corresponda) el mismo dia.
- Prerequisito de integracion: Named Credential "MuleSoftPricesInventory"
  configurada por ambiente (autenticacion de sistema; si Mule exigiera OAuth
  por usuario, revisar la estrategia ANTES de construir — limite de la GUIA).
- Configuracion manual por ambiente que NO viaja en el paquete (checklist
  post-deploy): (1) posicion de la accion "Venta guiada" en el page layout /
  Dynamic Actions de la Opportunity — se pierde si otra frente edita el
  layout (ocurrio 28/07: edicion del layout por pruebas de HU-036 la quito);
  re-agregar en Salesforce Mobile and Lightning Experience Actions. (2) En
  sandboxes de desarrollo, desmarcar Session Settings > "Enable secure and
  persistent browser caching" para que los testers vean los LWC nuevos sin
  logout/login.

## Renombre a la convencion GRPQM (v18, 28/07)
- Los 8 bundles LWC nacieron en espanol en la fase mock; con el esqueleto
  como camino oficial se renombraron a ingles (regla: metadato nunca en
  espanol): guidedSellingLauncher, guidedSellingModal, quoteConfirmModal,
  discountApprovalModal, vehicleSale, usedVehicleSale, partsCounterSale,
  agriculturalProductsSale. QuickAction nueva Opportunity.GuidedSelling
  (label sigue "Venta guiada"); VentasTestDataFactory -> SalesTestDataFactory;
  label del flow con verbo (Send Inventory Exhausted Notification); RT
  descriptions con el proceso de negocio primero. Los componentes viejos se
  eliminan via destructiveChangesPost en el mismo deploy.
- SECUENCIA DE DEPLOY del v18: (1) quitar la accion "Venta guiada" vieja de
  la record page/layout ANTES del deploy (la eliminacion falla si esta
  referenciada); (2) desplegar el zip (crea nuevos + borra viejos);
  (3) re-agregar la accion nueva (Opportunity.GuidedSelling) a la pagina;
  (4) logout/login.
- Deuda registrada: identificadores internos del JS del mock aun en espanol
  (se normalizan al industrializar); evaluar rename del platform event
  SapOrderResponse__e a patron <Action><Entity>Event con Diego Braz.

## HU-042 (v13) — metadatos de la historia de seleccion de vehiculo
- Quote Record Types NewVehicle ("Vehículo Nuevo") y UsedVehicle ("Vehículo
  Usado") — base de las plantillas diferenciadas (T02). TRIO post-deploy por
  ambiente: asignacion a perfiles + page layout assignment + defaults.
- CustomPermission ViewInventoryQuantities + PermissionSet
  InventoryQuantitiesAccess (T04): asignar el PS a los asesores de PISO.
  Sin el permiso, la venta guiada oculta las columnas/cantidades de stock
  (RN-03: online no ve cantidades; disponibilidad cualitativa si).
- CustomNotificationType InventoryAlert + Flow InventoryExhaustedNotification
  (T06): subflujo autolanzado (inputs RecipientId, ProductCode, ProductName,
  TargetRecordId) que avisa al encargado para EVALUAR desactivar el codigo.
  Llega en Draft — ACTIVAR tras el deploy; lo invoca la integracion de
  disponibilidad o un batch cuando el nivel pais llegue a cero.
- scripts/DESCRIBE-hu042.apex (T01): correr ANTES de crear campos en la
  linea (T08) — confirma lookups nativos a Vehicle y campos de color.
- Config por ambiente SIN cobertura de deploy: Field History de Quote
  (historial de cotizaciones, T15) y matrices BRE de precio de referencia
  (T09) se configuran en la org.
- Seleccion del mock alineada a la HU: filtros marca/año + busqueda, color
  exterior E interior, cantidades tras el permiso, cotizacion sin stock
  (codigo activo = Product2.IsActive como interruptor de cotizable, T05).

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

