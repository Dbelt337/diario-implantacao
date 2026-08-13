#!/usr/bin/env python3
# Gera Mapeo_de_Datos_SALES.xlsx (OOXML direto, sem openpyxl).
import zipfile, html

def esc(s): return html.escape(str(s), quote=False)

def col_letter(i):
    s = ''
    while i >= 0:
        s = chr(65 + i % 26) + s
        i = i // 26 - 1
    return s

def sheet_xml(widths, title, header, rows):
    cols = ''.join(f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i, w in enumerate(widths))
    out = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
           '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
           f'<cols>{cols}</cols><sheetData>']
    rnum = 1
    def emit(vals, style):
        nonlocal rnum
        cells = ''.join(
            f'<c r="{col_letter(i)}{rnum}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{esc(v)}</t></is></c>'
            for i, v in enumerate(vals))
        out.append(f'<row r="{rnum}">{cells}</row>')
        rnum += 1
    emit([title] + [''] * (len(header) - 1), 3)
    emit([''] * len(header), 0)
    emit(header, 1)
    for r in rows: emit(r, 2)
    out.append('</sheetData></worksheet>')
    return ''.join(out)

# ---------------------------------------------------------------- GUIA SALES
g_header = ['ID', 'Interfaz', 'Dirección', 'Patrón', 'Disparador', 'Objetos / endpoint Salesforce',
            'Servicio SAP / externo', 'Clave de idempotencia (External Id)', 'Frecuencia · volumen',
            '¿Persiste en Salesforce?', 'Encaje en el flujo construido', 'Historias consolidadas']

guia = [
 # ---- Maestros: catálogo y precios (SAP -> SF, réplica)
 ['INT-SAL-01', 'Carga inicial masiva de maestros (pre-go-live)', 'SAP → SF', 'Bulk API 2.0 (snapshot)',
  'Ejecución manual pre-go-live (ventana de corte)',
  'Account, Contact/PersonAccount, Product2, Pricebook2/PricebookEntry, VehicleDefinition, Vehicle, Asset, Location',
  'Extracciones SAP (MARA/MVKE, KNA1, VLC, T001W) normalizadas por Mule',
  'Misma clave de cada interfaz delta (ver filas siguientes)',
  '1 vez · ~180.000 clientes, ~5.450 vehículos, ~5.000 productos, ~50.000 PBE',
  'Sí — es la base del catálogo e inventario',
  'Precondición de TODO el flujo: sin catálogo cargado la venta guiada no encuentra material ni precio',
  'US-SAL-01-02A'],
 ['INT-SAL-02', 'Catálogo de vehículos (modelo/versión)', 'SAP → SF', 'Upsert delta event-driven',
  'Alta/cambio de modelo o versión en SAP/OEM',
  'PATCH /sobjects/Product2/SapMaterialCode__c/{MATNR} · luego VehicleDefinition (ProductId)',
  'Réplica estándar de materiales SAP: IDoc MATMAS (MATMAS_CFS_MATMAS05) + maestro de modelos DBM',
  'Product2.SapMaterialCode__c (único + External Id)',
  'Diario / por evento · centenas',
  'Sí — Product2 + VehicleDefinition',
  'Alimenta la búsqueda de vehículo del modal y el Inventory Search. REGLA: VehicleDefinition SIEMPRE con ProductId (nulos rompen los subqueries del flujo)',
  'US-SAL-02-01A'],
 ['INT-SAL-03', 'Catálogo de repuestos y accesorios', 'SAP → SF', 'Upsert delta event-driven',
  'Alta/cambio de material en SAP',
  'PATCH /sobjects/Product2/SapMaterialCode__c/{MATNR}',
  'Réplica estándar de materiales SAP: IDoc MATMAS (MATMAS_CFS_MATMAS05) — MARA + MVKE por sociedad/canal',
  'Product2.SapMaterialCode__c',
  'Diario / por evento · miles',
  'Sí — Product2 (SOLO catálogo; el SALDO no se replica: ver INT-SAL-07)',
  'Es lo que la búsqueda del grid HU-043 encuentra al teclear (SOSL local) y lo que evita el miss que dispara la US-021',
  'US-SAL-02-01C (parte catálogo)'],
 ['INT-SAL-04', 'Listas de precios por sociedad/canal', 'SAP → SF', 'Composite API (standard → custom)',
  'Lista mensual / cambio de precio aprobado en el maestro',
  'POST /composite (allOrNone=true): PricebookEntry standard + PricebookEntry de la lista',
  'Condiciones de precio SAP por org. de ventas / canal',
  'PBE no tiene External Id nativo → se propone SapPriceKey__c (material+lista+moneda, único) para que el precio sea upsert de UNA llamada',
  'Mensual + deltas · ~50.000 PBE',
  'Sí — Pricebook2 / PricebookEntry',
  'REGLA DE PLATAFORMA: sin entrada en el pricebook STANDARD en la misma moneda, la entrada de la lista custom FALLA (STANDARD_PRICE_NOT_DEFINED). El flujo consume PBE en toda QuoteLineItem',
  'US-SAL-02-01B'],
 ['INT-SAL-05', 'Tipos de cambio', 'SAP → SF', 'Job diario',
  'Cierre diario de tasas',
  'DatedConversionRate (org multi-moneda)',
  'Tabla de tipos de cambio SAP',
  'Fecha + par de monedas',
  'Diaria · 6 monedas (USD, CRC, GTQ, HNL, NIO, PAB)',
  'Sí',
  'Sostiene la moneda de publicación por modelo y el redondeo que debe coincidir con SAP al facturar',
  'US-SAL-02-01D'],
 # ---- Inventario de vehículos (réplica unitaria)
 ['INT-SAL-06', 'Inventario vehicular unitario (por VIN) y su estado',
  'SAP → SF', 'Event-driven (Sync + Process)',
  'Ingreso, traslado, cambio de estado, daño, entrega o facturación de una unidad en SAP',
  'Asset (SerialNumber=VIN, LocationId=centro) → Vehicle (VehicleIdentificationNumber, VehicleDefinitionId, AssetId, Status)',
  'Vehicle Inventory (STAR BOD) / stock VLC del DBM',
  'VIN (Vehicle.VehicleIdentificationNumber único; Asset.SerialNumber)',
  'Casi tiempo real · miles de unidades',
  'Sí — UNIDAD por unidad (es lo que permite buscar, reservar y vender una unidad concreta)',
  'ORDEN OBLIGATORIO: Asset antes de Vehicle (Vehicle.AssetId apunta al Asset, y el centro vive en Asset.LocationId — verificado en la org). Alimenta la selección del modal y la reserva',
  'US-SAL-03-01A + US-SAL-03-01D (mismo canal, distinta operación — consolidadas)'],
 # ---- Disponibilidad de repuestos (consulta, NO réplica)
 ['INT-SAL-07', 'Disponibilidad de materiales al cotizar (saldo por centro)',
  'SF → SAP (request/response)', 'Consulta síncrona masiva (1 llamada por lote)',
  'El asesor pulsa "Consultar disponibilidad" o "Revalidar" en el grid de Repuestos & PA',
  'Apex GuidedSellingController.checkRepuestosAvailability → SapMuleClient → POST /api/v1/materials/query',
  'ZHYB_C4C_CONSULTA_MATERIALES (variante MASIVA — hay request-masivo/response-masivo) + ZHYB_DBM_TEXTO_EXISTENCIA_RFC. Vehículos: ZQEV_C4C_CONSULTA_MATERIALES / ZQEV_SD_CONSULTA_GENERAL_MAT',
  'No aplica (consulta sin efecto de escritura)',
  'Por cotización · lote de N líneas en UNA llamada',
  'NO se replica el saldo. Se guarda SNAPSHOT en la línea: QuoteLineItem.AvailabilityStatus__c / AvailabilityDetail__c',
  'HU-043 RN4 (validada): SAP es el maestro del inventario de repuestos; Salesforce consulta y refleja, nunca calcula stock. Réplica de saldos de miles de SKU × centro sería inconsistente por diseño',
  'US-SAL-02-01C (parte stock real-time)'],
 ['INT-SAL-08', 'Creación de material inexistente', 'SF → SAP', 'Síncrona con respuesta de negocio',
  'Búsqueda sin resultado o línea sin catálogo en el flujo guiado (el asesor solicita el alta)',
  'Apex MaterialCreationService → POST /api/v1/materials · upsert local del Product2 al confirmar',
  'ZQEV_DBM_CREACION_MATERIALES (WS ZWS_CREACION_MATERIALES)',
  'Product2.SapMaterialCode__c (convergen réplica y alta en el MISMO registro)',
  'Por solicitud · baja',
  'Sí — crea/reactiva Product2 + PricebookEntry',
  'US-021 dentro del flujo guiado. MENSAJE de SAP es texto libre CHAR255: Mule debe normalizar a ok+mensaje. Rechazo levanta Case al área',
  'US-021 (no estaba en la guía de integraciones)'],
 # ---- Clientes
 ['INT-SAL-09', 'Cliente nuevo y actualización desde SAP', 'SAP → SF', 'Event-driven + Composite Tree',
  'Alta o cambio de cliente en SAP (convivencia / clientes que nacen en el ERP)',
  'Account / PersonAccount + Contact (Composite Tree cuando hay jerarquía atómica)',
  'Customer Information (STAR BOD)',
  'Account.SAPClientId__c (External Id) — dedup por Sociedad + NúmeroDocumento',
  'Casi tiempo real · ~180.000 base inicial',
  'Sí',
  'Complementa HU-017: el golden record del cliente comercial es Salesforce; esta interfaz cubre convivencia y carga. CustomerTypeCode=Individual exige conversión a PersonAccount (limitación STAR)',
  'US-SAL-01-01A + US-SAL-01-01B + US-SAL-01-01C (mismo canal — consolidadas)'],
 ['INT-SAL-10', 'Cliente creado/modificado en Salesforce → SAP', 'SF → SAP', 'Event-driven (near real time)',
  'Alta o cambio de campo relevante en el maestro (lista de campos relevantes en Custom Metadata)',
  'Account/Contact/AccountAccountRelation (extensión por sociedad) → payload Mule',
  'Alta/modificación de deudor por sociedad (+ atributos fiscales derivados)',
  'Account.SAPClientId__c; por sociedad: deudor SAP en la AccountAccountRelation',
  'Por evento · media',
  'El número de deudor por sociedad VUELVE y se guarda en la relación (AAR)',
  'HU-017: Salesforce es el maestro. La extensión a otra sociedad crea un registro AAR con los datos locales; el deudor SAP retorna como atributo de esa relación',
  'HU-017 (RN-01/RN-05/RN-26) — sin fila propia en la guía original'],
 ['INT-SAL-11', 'Consulta contable, crediticia y de saldos', 'SF → SAP', 'Consulta síncrona (sin réplica)',
  'Apertura de la ficha del cliente / validación comercial',
  'Componente de lectura (no persiste)',
  'Consultas financieras del ERP',
  'No aplica',
  'Por consulta',
  'NO — RN-26 prohíbe replicar dato contable',
  'Evita que Salesforce tenga saldo desactualizado; la autoridad financiera sigue en el ERP',
  'HU-119 RN-26'],
 # ---- Pedido
 ['INT-SAL-12', 'Envío del pedido a SAP', 'SF → SAP', 'Asíncrona disparada por evento',
  'Cotización aceptada → Order creada y activada (flow Quote_Aceptada_Genera_Pedido / botón Generar pedido)',
  'Order + OrderItem → SapOrderService/SapMuleClient → POST /api/v1/orders (simulate previo opcional)',
  'VEHÍCULOS (cadena de 3 pasos): ZQEV_ASIG_CLIENTE y ZQEV_MONEDA_CLIENTE (prerrequisitos) → ZQEV_SSA_CREA_ORD_VEH crea la Z301 (OFERTA/RESERVA) → ZQEV_SSA_COPIA_ORD_VEH copia la Z301 a Z300 (PEDIDO DE VENTA). Modificar: ZQEV_SSA_MOD_ORD_VEH (Z301 y Z300). REPUESTOS/PA: ZHYB_MONEDA_CLIENTE + ZHYB_SD_PARAM_CLIENTE → ZHYB_DBM_COTIZA_REP_RFC; PA usa cod_salesorder_simulate (síncrono) + IDoc SALESORDER_CREATEFROMDAT2',
  'Hash(QuoteId) / número de pedido SAP en Order.SapOrderNumber__c — más lock FOR UPDATE en Salesforce para que doble clic no genere dos Z301',
  'Por venta',
  'Sí — Order.SapOrderNumber__c y estado del ciclo',
  'Corazón del flujo construido (cotización → aceptación → pedido → SAP). Idempotencia DOBLE (lock FOR UPDATE en SF + clave en Mule). PEDIDO PARA MULE: exponer UNA Experience API que orqueste internamente prerrequisitos + CREA + COPIA; Salesforce no debe encadenar 3-4 llamadas',
  'US-SAL-08-01A + US-SAL-08-01B + US-SAL-08-01C (mismo servicio, distinta cardinalidad — consolidadas)'],
 ['INT-SAL-13', 'Retorno del pedido y facturación', 'SAP → SF', 'Platform Event + update inbound',
  'SAP confirma el pedido, entrega o factura',
  'Publicar SapOrderResponse__e (flow SAP_Order_Response_Handler) · factura por update en Order (flow Order_Facturado_Handler)',
  'COD_REPLICATE_SALES_ORDER01 (réplica de la orden creada) · SalesOrderConfirmationMessage / COD_SALESORDER_CONFIRMATION (confirma y cierra) · YMKT_SALES_ORDER (Quotations/Orders/Returns replication)',
  'Order.SapOrderNumber__c / SapInvoiceNumber__c',
  'Por evento',
  'Sí — estado, número de pedido, número y fecha de factura',
  'YA DEPLOYADO en Salesforce: los dos flows existen y escuchan. Mule solo necesita publicar el evento y hacer el update',
  'Retorno de US-SAL-08-01A (estaba implícito)'],
 ['INT-SAL-14', 'Pedido modificado en SAP → Salesforce', 'SAP → SF', 'Event-driven (push)',
  'Cualquier actualización de posiciones del pedido en SAP (excepto PA)',
  'Update de Order/OrderItem vía API (mismo canal del retorno)',
  'ZQEV_DBMPOSICIONES',
  'Número de pedido SAP + número de posición',
  'Por evento',
  'Sí',
  'HU-119 RN-06: push, no polling. El botón manual de "refrescar pedido" se mantiene como tercer nivel de reproceso. PA queda excepción (ya bidireccional)',
  'HU-119 RN-06 — sin fila propia en la guía original'],
 ['INT-SAL-15', 'Vigencia y liberación de la reserva', 'SF ↔ SAP', 'Parámetro en el pedido + aviso de liberación',
  'Creación de la reserva (parámetro de vigencia) y vencimiento de la cotización (liberación anticipada)',
  'Scheduled Flow en Salesforce detecta vencidas → llamada de liberación · Vehicle/Asset reflejan estado',
  'ZQEV_SSA_MOD_ORD_VEH — CONFIRMADO en la sesión 22/07 que modifica Z301 (reserva) y Z300 (pedido): es la ruta de la liberación anticipada. ZQEV_DBM_RECHAZAR_RESERVA para el rechazo',
  'Número de pedido/reserva SAP',
  'Diaria + por evento',
  'Refleja estado; el stock se libera en SAP',
  'HU-050/051 + HU-119 RN-21: el job diario corre en SALESFORCE (pedido de JJ) y SAP mantiene la autoridad final del stock. El plazo por marca/sociedad viene de SAP y se replica como configuración (fuente única)',
  'US-SAL-03-01B + US-SAL-03-01C (la lógica de timer es 100% Salesforce; solo la liberación es interfaz — consolidadas)'],
 ['INT-SAL-16', 'Devolución y anulación', 'SF → SAP', 'Asíncrona con aprobación previa',
  'Solicitud de devolución/anulación aprobada en Salesforce',
  'Reduction Order (Order con IsReductionOrder + OriginalOrderId, por línea) → payload Mule',
  'Peças: Z111 (confirmado). PA: el canal YMKT_SALES_ORDER ya replica Quotations/Orders/RETURNS — pista a validar con el equipo SAP. Vehículos: A CONFIRMAR',
  'Id de la reduction order + documento SAP devuelto',
  'Por solicitud',
  'Sí — estado y documento SAP en la reduction order',
  'PENDIENTE DE DEFINICIÓN SAP (HU-119 RN-22). Modelo Salesforce ya decidido (reduction orders); el flujo se desarrolla en historia propia. No construir hasta cerrar el documento SAP',
  'HU-119 RN-22 + PROP-INT-05 (SOLPED, relacionado)'],
 # ---- Leads y validaciones
 ['INT-SAL-17', 'API única de captura de Leads', 'Externo → SF (vía Mule)', 'REST upsert idempotente',
  'LeadsBridge (redes sociales), TalkMe (WhatsApp/chat), formularios SFCC y sitios de marca, Cyberfuel SOAP',
  'POST /services/apexrest/grupoq/v1/lead/upsert — payload {lead, lineItems[], preferredSellers[]}',
  'No aplica (orígenes digitales; Mule traduce cada origen al mismo contrato)',
  'externalRequestId (UUID) — idempotencia del canal',
  '~38.200 leads/mes · 312 bridges',
  'Sí — Lead + LeadLineItem + LeadPreferredSeller',
  'UNA sola interfaz para los 4 orígenes: cada origen es una transformación en Mule, no un endpoint nuevo. LeadLineItem lleva vehículos/accesorios de interés y se transforma a OpportunityLineItem en la conversión (API nativa de Automotive)',
  'US-SAL-04-01A + 04-01B + 04-01C + 04-01D + 04-01F (5 filas → 1 interfaz). 04-01E (showroom) NO es integración: es captura nativa'],
 ['INT-SAL-18', 'Lista negra / AML (LexisNexis)', 'SF → externo', 'Consulta síncrona con degradación',
  'Lead avanza a calificación',
  'Named Credential vía Mule → campos de screening en el Lead',
  'LexisNexis',
  'Documento del cliente + fecha de consulta (caché 365 días en Account)',
  'Por lead calificado',
  'Solo el resultado del screening',
  'Si el servicio no responde: modo degradado con badge "pendiente de validación" y bloqueo de conversión — nunca se pierde el lead',
  'US-SAL-05-01A (+ 05-01C caché, + 05-01D fallas: son reglas de la misma interfaz)'],
 ['INT-SAL-19', 'Buró de crédito (EFX Interconnect)', 'SF → externo', 'Consulta síncrona con caché',
  'Lead en calificación / pre-aprobación crediticia',
  'Vía Mule → BuroStatus__c / BuroPotencial__c',
  'EFX Interconnect',
  'Documento + fecha (reuso 365 días)',
  'Por lead / oportunidad',
  'Solo el resultado',
  'PENDIENTE: confirmar con CrediQ si es la misma consulta de Opportunity o una pre-consulta simplificada (evita pagar dos veces por el mismo buró)',
  'US-SAL-05-01B (+ 05-01C/D)'],
 # ---- Documentos
 ['INT-SAL-20', 'Documentos a OpenText (push y recuperación)', 'SF ↔ OpenText', 'Push + consulta read-only',
  'Documento adjunto en Lead/Opportunity · consulta de histórico',
  'ContentDocument/ContentVersion → Mule → OpenText · lectura bajo demanda con caché 24h',
  'OpenText (repositorio corporativo)',
  'Id del documento en OpenText guardado en Salesforce',
  'Por documento',
  'Salesforce mantiene preview y link; el archivo vive en OpenText',
  'HU-078. NOTA: la GENERACIÓN de cotizaciones/contratos (Document Templates de Automotive Cloud EE) NO es integración — es nativa, no entra en esta guía',
  'US-SAL-13-01A + US-SAL-13-01B (consolidadas). 13-01C excluida (nativa)'],
 ['INT-SAL-21', 'Reconciliación mensual SAP ↔ Salesforce', 'SAP ↔ SF', 'Job de comparación (red de seguridad)',
  'Calendario mensual',
  'Conteos y checksums: Account, Contact, Vehicle, Asset por Location, Product2 activo, PricebookEntry vigente',
  'Queries equivalentes en SAP',
  'No aplica (solo lectura y reporte de drift)',
  'Mensual',
  'No — genera reporte y casos de corrección',
  'Cubre lo que la integración continua puede perder: timeout, retry con efecto colateral, cambio manual en Salesforce o ventana de indisponibilidad',
  'US-SAL-01-02B (una sola interfaz para todas las entidades)'],
]

# ---- Vinculación con los ítems de estimación MuleSoft (vista S4 compartida 13/08)
PED = 'Pedidos SF → SAP (Outbound)'
INV = 'Inventario US-SAL-03-01B, US-SAL-03-01C, US-SAL-03-01D (Parte 1 y Parte 2)'
LEA = 'Captura Leads (Sales Lead BOD + custom) Parte 1 y Parte 2'
DOC = 'Documentación (OpenText + Document Templates)'
NA  = 'NO aparece en la vista S4 compartida — confirmar si está estimado en otro sprint'

ITEM_MULE = {
 'INT-SAL-01': NA,
 'INT-SAL-02': NA,
 'INT-SAL-03': NA,
 'INT-SAL-04': NA,
 'INT-SAL-05': NA,
 'INT-SAL-06': INV + ' — cubre US-SAL-03-01D (estado de la unidad). OJO: 03-01A (alta de unidad) no está nombrada en el ítem',
 'INT-SAL-07': NA + ' (es la consulta que usa el grid de Repuestos: sin ella la HU-043 no funciona)',
 'INT-SAL-08': NA + ' (US-021 — creación de material desde el flujo guiado)',
 'INT-SAL-09': 'Clientes — pedido como ADICIONAL por el equipo; no está en la vista S4',
 'INT-SAL-10': 'Clientes — pedido como ADICIONAL por el equipo; no está en la vista S4',
 'INT-SAL-11': 'Clientes — pedido como ADICIONAL por el equipo; no está en la vista S4',
 'INT-SAL-12': PED,
 'INT-SAL-13': PED + ' — ¿INCLUIDO? El ítem dice "Outbound" y esto es el RETORNO (inbound): confirmar que no quedó fuera',
 'INT-SAL-14': PED + ' — ¿INCLUIDO? Modificación en SAP es inbound: confirmar',
 'INT-SAL-15': INV + ' — cubre US-SAL-03-01B/C. En Salesforce el timer ya es nuestro; de Mule solo se necesita la liberación',
 'INT-SAL-16': NA + ' (devolución: NO estimar hasta que SAP defina el documento)',
 'INT-SAL-17': LEA,
 'INT-SAL-18': NA + ' (LexisNexis — validación de leads, US-SAL-05-01A)',
 'INT-SAL-19': NA + ' (buró EFX — verificar solapamiento con E-CQ de Digital Lending para no pagar dos consultas)',
 'INT-SAL-20': DOC + ' — la parte OpenText. Document Templates es NATIVO: no consume esfuerzo Mule',
 'INT-SAL-21': NA + ' (reconciliación mensual)',
}
g_header = g_header + ['Ítem de estimación MuleSoft (vista S4)']
guia = [r + [ITEM_MULE.get(r[0], NA)] for r in guia]

# ------------------------------------------------------- VISTA INVERSA
e_header = ['Ítem de estimación MuleSoft', 'Equipo', 'Interfaces de esta guía que cubre', 'Cobertura / observación']
estim = [
 [PED, '[OSF] SOW002 - Automotive Sales', 'INT-SAL-12 (envío del pedido)',
  'El nombre dice OUTBOUND. El flujo necesita además el RETORNO (INT-SAL-13: número de pedido, confirmación, factura) y la MODIFICACIÓN en SAP (INT-SAL-14). CONFIRMAR si están dentro del ítem o si falta estimarlos. Nota: el pedido de vehículos es una cadena (prerrequisitos → CREA Z301 → COPIA Z300), no una llamada'],
 [INV, '[OSF] SOW002 - Automotive Sales', 'INT-SAL-06 (estado de la unidad) + INT-SAL-15 (liberación de la reserva)',
  'El ítem nombra 03-01B/C/D. Falta nombrar 03-01A (recepción del inventario unitario por VIN), que es lo que puebla Vehicle/Asset. El timer de reserva (15/45 min) es lógica Salesforce: no consume Mule'],
 [LEA, '[OSF] SOW002 - Automotive Sales', 'INT-SAL-17 (API única de captura de leads)',
  'Cubre los 4 orígenes (LeadsBridge, TalkMe, SFCC/marcas, Cyberfuel SOAP) con UN endpoint de upsert; cada origen es una transformación. La captura en showroom es nativa (sin Mule)'],
 [DOC, '[OSF] SOW002 - Automotive Sales', 'INT-SAL-20 (documentos a OpenText)',
  'Solo la parte OpenText es integración. Document Templates de Automotive Cloud EE es generación nativa: no debería consumir esfuerzo Mule'],
 ['E-CQ-01 — Validación de Avalúo y Revisión de Vendedor de vehículos Terceros', '[OSF] SOW002 - Digital Lending', 'Ninguna de esta guía',
  'Otro equipo. Se relaciona con la HU-045 (usados/consignación) del lado Sales: coordinar para no duplicar la consulta de avalúo'],
 ['E-CQ-09 — Cotizador / Tasa de Referencia SAP (PRIME, TPROFONI, TBPCR)', '[OSF] SOW002 - Digital Lending', 'Ninguna de esta guía',
  'Otro equipo, pero es integración con SAP por el MISMO gateway: reutilizar credencial, monitoreo y política de reintentos'],
 ['(sin ítem) Catálogo, precios y tipos de cambio', '—', 'INT-SAL-02, 03, 04, 05',
  'RIESGO: sin catálogo ni listas de precios replicadas, la venta guiada no encuentra material ni precio. Es precondición de los ítems ya estimados'],
 ['(sin ítem) Disponibilidad de repuestos y creación de material', '—', 'INT-SAL-07, INT-SAL-08',
  'RIESGO: son las dos llamadas que el grid de Repuestos (HU-043) y la US-021 ya construidos consumen hoy contra el mock'],
 ['(sin ítem) Clientes', '—', 'INT-SAL-09, 10, 11',
  'Pedido por el equipo como adicional — ya está mapeado en esta guía, pueden empezar'],
]

# ------------------------------------------------------- MAPEO DE CAMPOS
c_header = ['Interfaz', 'Campo SAP / origen', 'Objeto.Campo Salesforce', 'Tipo', 'Obligatorio', 'Regla de transformación / nota']

campos = [
 ['INT-SAL-02/03', 'MATNR (número de material)', 'Product2.SapMaterialCode__c', 'Text(18) único + External Id', 'Sí', 'CLAVE DE UPSERT. También se copia a ProductCode (que no puede ser único: es estándar)'],
 ['INT-SAL-02/03', 'MAKTX (descripción)', 'Product2.Name', 'Text(255)', 'Sí', 'Truncar a 255'],
 ['INT-SAL-02/03', 'MTART (tipo de material)', 'Product2.Family', 'Picklist', 'Sí', 'De-para: ZREP→Repuesto, vehículo→Vehículo, accesorio→Accesorio (StandardValueSet Product2Family)'],
 ['INT-SAL-02/03', 'Indicador de bloqueo / borrado', 'Product2.IsActive', 'Checkbox', 'Sí', 'Material bloqueado en SAP → IsActive=false (NUNCA borrar: rompe histórico de cotizaciones)'],
 ['INT-SAL-02/03', 'Kit / lista técnica (componentes)', 'ProductRelatedComponent (Parent/Child/Quantity)', 'Junction', 'No', 'El PADRE debe cargarse con Product2.Type=Bundle y cada componente con IsDefaultComponent=TRUE (reglas del catálogo probadas en la org). Tipo de relación existente: Bundle→BundleComponent'],
 ['INT-SAL-02', 'Modelo / versión / año', 'VehicleDefinition (Name, ProductId, atributos)', 'Objeto Automotive', 'Sí', 'ProductId apunta al Product2 del vehículo. SIEMPRE informado (ProductId nulo rompe los subqueries del flujo guiado)'],
 ['INT-SAL-04', 'Precio de condición (por org. ventas/canal)', 'PricebookEntry.UnitPrice', 'Currency', 'Sí', 'Primero la entrada del pricebook STANDARD en la misma moneda; luego la lista custom con UseStandardPrice=false'],
 ['INT-SAL-04', 'Moneda de la condición', 'PricebookEntry.CurrencyIsoCode', 'Picklist', 'Sí', 'Debe ser moneda ACTIVA en la org (USD, CRC, GTQ, HNL, NIO, PAB). Una entrada por producto+lista+MONEDA'],
 ['INT-SAL-04', 'Sociedad + canal', 'Pricebook2 (Name/Id)', 'Lookup', 'Sí', 'Una lista por sociedad/canal. La marca NO multiplica listas (es atributo del producto)'],
 ['INT-SAL-06', 'VIN / chasis', 'Asset.SerialNumber y Vehicle.VehicleIdentificationNumber', 'Text', 'Sí', 'CLAVE de la unidad. API name del VIN confirmado en la org'],
 ['INT-SAL-06', 'Centro / sucursal (WERKS)', 'Asset.LocationId → Location.ExternalReference', 'Lookup', 'Sí', 'Location se carga antes (ExternalReference = código del centro). Vehicle NO tiene lookup nativo a Location: el centro vive en el Asset'],
 ['INT-SAL-06', 'Estado de la unidad', 'Vehicle.Status (+ Asset.Status)', 'Picklist', 'Sí', 'De-para de estados SAP → picklist Salesforce, acordado con el equipo SAP. SAP es source of truth del estado'],
 ['INT-SAL-06', 'Modelo de la unidad', 'Vehicle.VehicleDefinitionId', 'Lookup', 'Sí', 'Resuelto por el modelo ya replicado (INT-SAL-02)'],
 ['INT-SAL-07', 'Lista de materiales consultados', 'request.lineas[].productCode', 'Array', 'Sí', 'UNA llamada por lote (no una por línea). Los kits se expanden antes de consultar'],
 ['INT-SAL-07', 'PISO, RESERVA, TDET_SALDOS', 'respuesta: piso / reserva / saldoDisponible', 'Number', 'Sí', 'saldo = piso − reserva y PUEDE SER NEGATIVO: se devuelve tal cual (no truncar a 0)'],
 ['INT-SAL-07', 'Texto de existencia (ubicación)', 'QuoteLineItem.AvailabilityDetail__c', 'Text(255)', 'No', 'Del ZHYB_DBM_TEXTO_EXISTENCIA. De este texto se deriva el estado Otro Centro / Otra Sociedad'],
 ['INT-SAL-07', 'Estado derivado de la línea', 'QuoteLineItem.AvailabilityStatus__c', 'Picklist', 'Sí', 'Disponible / Parcial / Otro Centro / Otra Sociedad / No Disponible. Lo calcula Salesforce a partir del saldo y del texto'],
 ['INT-SAL-08', 'MATERIAL, SOCIEDAD, CANAL, SERIE', 'request de creación', 'Text', 'Sí', 'Los cuatro son obligatorios (los ZREP exigen serie). VER_DEFAULT="X" dispara lógica adicional con commit en SAP'],
 ['INT-SAL-08', 'MENSAJE (CHAR255 texto libre)', 'respuesta: ok + mensaje', 'Text', 'Sí', 'SAP no devuelve código de éxito: MULE DEBE NORMALIZAR a ok=true/false + mensaje. El mensaje viaja tal cual al Case cuando hay rechazo'],
 ['INT-SAL-12', 'Cabecera del pedido', 'Order (AccountId, EffectiveDate, Pricebook2Id, QuoteId)', 'Objeto', 'Sí', 'La Order nace de la cotización aceptada; Salesforce ya aplica lock FOR UPDATE para no generar dos pedidos'],
 ['INT-SAL-12', 'Posiciones del pedido', 'OrderItem (PricebookEntryId, Quantity, UnitPrice)', 'Objeto', 'Sí', 'Precio cotizado congelado (respeta la vigencia de la cotización)'],
 ['INT-SAL-12', 'Cliente / deudor por sociedad', 'Account + deudor SAP de la AAR de la sociedad', 'Lookup', 'Sí', 'Prerrequisitos SAP: asignación de cliente y moneda del cliente antes del pedido'],
 ['INT-SAL-13', 'Número de pedido SAP', 'Order.SapOrderNumber__c', 'Text', 'Sí', 'Llega por el Platform Event; también sirve de clave de idempotencia del retorno'],
 ['INT-SAL-13', 'Estado del ciclo', 'Order.SapStatus__c', 'Picklist', 'Sí', 'De-para de estados acordado; el flow SAP_Order_Response_Handler ya lo consume'],
 ['INT-SAL-13', 'Número y fecha de factura', 'Order.SapInvoiceNumber__c / SapInvoiceDate__c', 'Text / Date', 'No', 'La factura NO entra por evento: entra por update inbound en la Order (flow Order_Facturado_Handler)'],
 ['INT-SAL-09/10', 'Número de deudor SAP por sociedad', 'AccountAccountRelation (campo custom en la relación)', 'Text', 'Sí', 'NACE en SAP y Salesforce lo consume. Un registro AAR por sociedad habilitada, con los datos locales'],
 ['INT-SAL-09/10', 'Documento de identidad + país', 'Account (documento, país) + Sociedad', 'Text', 'Sí', 'Clave de deduplicación: mismo documento en países distintos NO es el mismo cliente'],
 ['INT-SAL-17', 'Origen del lead (plataforma/campaña)', 'Lead.LeadSource + UTM_* + BridgeId__c', 'Text/Picklist', 'Sí', 'Cada origen (LeadsBridge/TalkMe/SFCC/Cyberfuel) se traduce al MISMO contrato en Mule'],
 ['INT-SAL-17', 'Vehículo/accesorio de interés', 'LeadLineItem', 'Objeto Automotive', 'No', 'En la conversión se transforma a OpportunityLineItem por la API nativa de Automotive (no por Apex)'],
 ['INT-SAL-17', 'Sucursal / dealer', 'LeadPreferredSeller + derivación de Sociedad', 'Lookup', 'Sí', 'La cascada de derivación resuelve 95% de los casos por el dealerCode del payload'],
]

# ------------------------------------------------------- DEDUPLICACIÓN
d_header = ['Fila(s) de la guía original', 'Se consolida en', 'Por qué no es una interfaz aparte']
dedup = [
 ['US-SAL-03-01A + US-SAL-03-01D', 'INT-SAL-06', 'Mismo canal (Vehicle Inventory) y mismo mapeo: alta de unidad y cambio de estado son operaciones distintas del MISMO servicio'],
 ['US-SAL-08-01A + 08-01B + 08-01C', 'INT-SAL-12', 'Mismo servicio de pedido: retail = 1 pedido, flotas = N pedidos por VIN y consolidación. Cambia la cardinalidad, no el contrato'],
 ['US-SAL-04-01A + 01B + 01C + 01D + 01F', 'INT-SAL-17', 'Un único endpoint de upsert de Lead: cada origen es una TRANSFORMACIÓN en Mule. Cinco endpoints separados serían cinco contratos para el mismo objeto'],
 ['US-SAL-01-01A + 01B + 01C', 'INT-SAL-09', 'Alta, delta y conversión a PersonAccount son reglas del mismo flujo de recepción de cliente'],
 ['US-SAL-05-01C + 05-01D', 'INT-SAL-18 / INT-SAL-19', 'Caché de 365 días y tratamiento de fallas son REGLAS de las consultas externas, no interfaces nuevas'],
 ['US-SAL-01-01D + 08-01D', 'Convenciones (hoja Reglas)', 'Reintentos y reprocesamiento son política transversal: se definen UNA vez para todas las interfaces'],
 ['US-SAL-02-01C', 'INT-SAL-03 (catálogo) + INT-SAL-07 (saldo)', 'La fila original mezcla dos patrones distintos: el CATÁLOGO se replica, el SALDO se consulta. Separarlos evita que Mule construya una réplica de stock que no debe existir'],
 ['US-SAL-03-01B + 03-01C', 'INT-SAL-15 (solo la liberación)', 'El timer de reserva (15/45 min) es lógica 100% Salesforce: no es interfaz. Solo la liberación en SAP lo es'],
 ['US-SAL-13-01C', 'EXCLUIDA', 'Document Templates de Automotive Cloud EE es generación NATIVA de documentos: no pasa por Mule'],
 ['US-SAL-04-01E', 'EXCLUIDA', 'Captura en showroom es Lead Page nativa: no hay integración'],
 ['US-SAL-15-01A', 'EXCLUIDA de esta guía', 'Sincronización con Marketing Cloud usa Marketing Cloud Connect, no MuleSoft'],
 ['US-SAL-17-01B + 18-01C', 'EXCLUIDAS', 'Einstein Lead Scoring y campos custom de segmentación son configuración/desarrollo Salesforce, no interfaces'],
 ['US-SAL-02-01E (Servicontratos Z07)', 'FUERA DE ALCANCE Sales', 'Postventa Autopits (cross-team); si se consume, es por INT-SAL-03 sin esfuerzo adicional'],
]

# ------------------------------------------------------- REGLAS
r_header = ['Tema', 'Regla / convención', 'Fundamento']
reglas = [
 ['Gateway único', 'TODA interfaz pasa por MuleSoft. En Salesforce hay una sola Named Credential (MuleGateway) y una External Credential', 'Un único punto de credenciales y de monitoreo; una llamada directa SAP↔SF crearía un segundo canal fuera del monitoreo centralizado'],
 ['Claves de idempotencia', 'Catálogo: Product2.SapMaterialCode__c · Cliente: Account.SAPClientId__c + deudor por sociedad en la AAR · Unidad: VIN · Pedido: número SAP en la Order', 'Con clave externa única, un reintento converge en el MISMO registro y nunca duplica. Es la precondición que hace segura toda la política de reintentos'],
 ['ProductCode no sirve de clave', 'El upsert por API SOLO acepta campos External Id. ProductCode es estándar y no puede marcarse único ni External Id', 'Comprobado en la INT: por eso existe SapMaterialCode__c. El patrón consultar-luego-insertar generó productos duplicados'],
 ['Referencia al padre por External Id', 'Al crear PricebookEntry se referencia el producto así: "Product2": { "SapMaterialCode__c": "<MATNR>" } — sin consultar el Id antes', 'Evita 2 llamadas por línea y elimina la ventana de carrera'],
 ['Precio: standard primero', 'Antes de la entrada en la lista custom debe existir la entrada en el pricebook STANDARD en la misma moneda. Recomendado: Composite API con allOrNone=true', 'Regla de plataforma (error STANDARD_PRICE_NOT_DEFINED). Solo existe UN pricebook standard por org y su marca no es editable'],
 ['Precio: re-ejecución', 'PricebookEntry no tiene upsert nativo (una entrada por producto+lista+moneda): la segunda ejecución da DUPLICATE_VALUE. Decisión pendiente: tratar el 400 con PATCH, o crear SapPriceKey__c (único + External Id) y hacer upsert de una llamada', 'Necesario para que la réplica de precios sea re-ejecutable sin limpieza manual'],
 ['Reintentos', 'Síncronas con usuario esperando: 0 reintentos, falla rápida · Asíncronas de negocio: 3 intentos con backoff 2→4→8 min (+1 inmediato solo para timeout de red) · Réplicas masivas: 3 por lote 5→15→45 min · Eventos inbound: replay nativo (72h) + reconciliación', 'Propuesta OSF para HU-119 RN-08/RN-09'],
 ['Errores persistentes', 'Tras agotar reintentos: registro marcado como no sincronizado + Case automático a la cola de Datos Maestros con el error crudo, y botón de reproceso manual', 'HU-119 RN-27: el asesor solo ve el estado; corrige quien es dueño del dato'],
 ['Monitoreo y traza', 'Traza técnica (payload, latencia, retry) en Anypoint; traza funcional por registro en Salesforce. Retención propuesta: estado permanente + log 90 días en SF; Anypoint según plan', 'HU-119 RN-15/RN-16. Ampliar el monitoreo centralizado a las interfaces SAP es un GAP de alcance a señalizar'],
 ['Permisos del usuario de integración', 'Campos custom nuevos nacen INVISIBLES: hay que dar FLS al perfil del usuario de integración (o incluirlo en el permission set PS_Mule_Integration) tras cada deploy', 'Causa del error "field does not exist or is not accessible" en la INT'],
 ['Multi-moneda', 'CurrencyIsoCode debe ser moneda activa en la org. Guatemala maneja doble moneda (GTQ y USD): son DOS PricebookEntry del mismo producto', 'Modelo nativo: una entrada por producto+lista+moneda'],
 ['Redondeo', 'La regla de redondeo por sociedad y moneda debe ser la MISMA que aplica SAP al facturar (SAP calcula con 4 decimales y monta posiciones con 2)', 'Si cada sistema redondea distinto, la factura no cuadra con la cotización por centavos'],
]

# ------------------------------------------------------- FUENTES
f_header = ['Tema', 'Fuente']
fuentes = [
 ['Inventario de vehículos: Vehicle / VehicleDefinition / Asset / Location', 'Automotive Cloud Developer Guide — Standard Objects y VehicleDefinition (cadena Product2 → VehicleDefinition → Asset → Vehicle)'],
 ['Búsqueda de inventario multi-tienda', 'Salesforce Help — Set Up Vehicle Inventory Search / VehicleSearchableField'],
 ['Stock por ubicación (si algún día se replica saldo de repuestos)', 'ProductItem — "the stock of a particular product at a particular location" (modelo de inventario de Field Service: requiere esa habilitación; NO es el patrón elegido para repuestos)'],
 ['Catálogo y precios: una entrada por producto+lista+moneda; standard primero', 'PricebookEntry — Object Reference (Usage) y Salesforce Help de carga de listas de precios'],
 ['Upsert por External Id y referencia al padre por External Id', 'REST API Developer Guide — Upsert / relaciones por campo External Id'],
 ['LeadLineItem (vehículos, accesorios y partes) y conversión a OpportunityLineItem', 'Automotive Cloud Developer Guide — LeadLineItem y Transformations'],
 ['Devolución: reduction orders (IsReductionOrder + OriginalOrderId)', 'Salesforce Help — Reduction Orders / Order Settings; Object Reference del Order'],
 ['Reversión de venta en el ERP referenciando el documento original', 'SAP Help Portal — DBM Order Processing ("To reverse the sales transaction, you can create a returns order")'],
 ['Mapa RFC/BOD ↔ endpoint por dominio', 'Fachada SapMuleClient (cabecera de la clase) — mapa vivo mantenido junto con el código'],
 ['Catálogo de servicios de cotización y pedido (Z300/Z301, prerrequisitos, IDocs)', 'Documento del equipo SAP/Mule "Integraciones para cotizar y crear un pedido" — sesión 22/07/2026 (fuente primaria de los nombres de función)'],
 ['Premisa STAR 5 (BODs de cliente, catálogo e inventario)', 'Documento del equipo (inspección de 870 XSDs) — premisa del programa, a confirmar en el contrato Mule'],
]


# ------------------------------------------------------- SERVICIOS SAP (sesión 22/07)
sv_header = ['Dominio', 'Servicio / función SAP', 'Para qué sirve (según la sesión 22/07)', 'Interfaz de esta guía', 'Observación']
servicios = [
 ['Vehículos', 'ZQEV_ASIG_CLIENTE', 'Prerrequisito obligatorio antes de ejecutar cualquier función de pedido', 'INT-SAL-12', 'Debe ir DENTRO de la orquestación Mule, no como llamada separada desde Salesforce'],
 ['Vehículos', 'ZQEV_MONEDA_CLIENTE', 'Prerrequisito obligatorio (moneda del cliente)', 'INT-SAL-12', 'Ídem'],
 ['Vehículos', 'ZQEV_SSA_CREA_ORD_VEH', 'Crea la Z301 = OFERTA o RESERVA', 'INT-SAL-12 / INT-SAL-15', 'Aquí se bloquea el stock: es la reserva'],
 ['Vehículos', 'ZQEV_SSA_COPIA_ORD_VEH', 'Toma la Z301 y la copia a Z300 = PEDIDO DE VENTA', 'INT-SAL-12', 'El pedido NO es una sola llamada: es crear y luego copiar'],
 ['Vehículos', 'ZQEV_SSA_MOD_ORD_VEH', 'Modifica Z301 (reserva) y Z300 (pedido)', 'INT-SAL-14 / INT-SAL-15', 'Ruta de la liberación anticipada y de la modificación'],
 ['Vehículos', 'ZQEV_C4C_CONSULTA_MATERIALES / ZQEV_SD_CONSULTA_GENERAL_MAT', 'Consulta de materiales del lado vehículos', 'INT-SAL-07', ''],
 ['Repuestos', 'ZHYB_C4C_CONSULTA_MATERIALES', 'Consulta de materiales para agregar a la orden: uno a uno o CARGA MASIVA', 'INT-SAL-07', 'USAR LA VARIANTE MASIVA: una llamada por lote (ya es lo que hace el grid)'],
 ['Repuestos', 'TDET_SALDOS = PISO − RESERVA', 'Cálculo del saldo disponible', 'INT-SAL-07', 'PUEDE SER NEGATIVO y se devuelve tal cual (no truncar)'],
 ['Repuestos', 'ZHYB_DBM_TEXTO_EXISTENCIA_RFC', 'Texto de existencia (ubicación de la pieza)', 'INT-SAL-07', 'De este texto derivamos Otro Centro / Otra Sociedad'],
 ['Repuestos', 'ZHYB_MONEDA_CLIENTE + ZHYB_SD_PARAM_CLIENTE', 'Parámetros y moneda del cliente antes de generar el pedido', 'INT-SAL-12', 'Equivalente de los prerrequisitos de vehículos, para repuestos/PA'],
 ['Repuestos', 'ZHYB_DBM_COTIZA_REP_RFC', 'Crea cotización / pedido de repuestos en el DBM', 'INT-SAL-12', ''],
 ['Repuestos', 'ZHYB_DBM_MOD_DET_ORDEN', 'Modifica detalle de la orden/cotización', 'INT-SAL-14', ''],
 ['Repuestos', 'ZHYB_DBMPOSICIONES', 'Consulta de posiciones del pedido', 'INT-SAL-14', 'OJO: la guía de historias la nombra ZQEV_DBMPOSICIONES y la sesión 22/07 ZHYB_DBMPOSICIONES — confirmar el nombre exacto con el equipo SAP'],
 ['Repuestos', 'ZHYB_DBM_DESCUENTO_DE_VENDEDOR', 'Tope de descuento del vendedor', 'INT-SAL-12', 'DECISIÓN ABIERTA en el propio documento: scheduler diario en lugar de consultar en cada pedido. Recomendación: scheduler + caché (evita una llamada por cotización)'],
 ['PA', 'cod_salesorder_simulate', 'Simulación de precio del pedido — SÍNCRONO', 'INT-SAL-12', 'El precio lo calcula el SD: Salesforce exhibe y congela'],
 ['PA', 'SALESORDER_CREATEFROMDAT2 (IDoc)', 'Confirma / crea el pedido en SD', 'INT-SAL-12', 'El resto del flujo de PA es asíncrono por IDocs'],
 ['PA', 'COD_REPLICATE_SALES_ORDER01', 'Respuesta con la orden creada', 'INT-SAL-13', 'Es el retorno que alimenta SapOrderResponse__e'],
 ['PA', 'COD_SALESORDER_CONFIRMATION / SalesOrderConfirmationMessage', 'Confirma y cierra la orden', 'INT-SAL-13', ''],
 ['PA', 'YMKT_SALES_ORDER', 'Replicación de Quotations / Orders / RETURNS', 'INT-SAL-13 / INT-SAL-16', 'Contiene RETURNS: posible ruta de devoluciones para PA — validar'],
 ['Catálogo', 'MATMAS (MATMAS_CFS_MATMAS05)', 'Réplica estándar de materiales de SAP', 'INT-SAL-02 / INT-SAL-03', 'Es el contrato de la réplica de catálogo'],
 ['Clientes', 'ZHYB_SD_PARAM_CLIENTE / Update Business Partner', 'Parámetros del cliente y actualización de BP', 'INT-SAL-10', ''],
 ['B2C (fuera de Sales)', 'Archivos XML en SFTP + scheduler Mule', 'Estrategia B2C: B2C genera XML en SFTP y Mule los lee', 'No aplica a Sales', 'ATENCIÓN: el documento circula con credenciales SFTP en texto plano — deben rotarse y salir del documento'],
]

sheets = [
 ('Sales', [11, 34, 13, 22, 34, 40, 32, 34, 24, 30, 46, 34, 52], g_header, guia,
  'GUIA SALES v3 - Integraciones Salesforce <-> SAP via MuleSoft (12/08/2026) - 21 interfaces UNICAS, con nombres de servicio SAP (sesion 22/07) y vinculacion a los items de estimacion MuleSoft (vista S4)'),
 ('Mapeo Campos', [14, 32, 40, 22, 12, 60], c_header, campos,
  'Mapeo de campos por interfaz (nivel campo) - reglas de transformacion'),
 ('Deduplicacion', [40, 26, 80], d_header, dedup,
  'Trazabilidad: como las filas de la guia original se consolidaron (y que quedo fuera por no ser integracion)'),
 ('Reglas', [26, 70, 60], r_header, reglas,
  'Reglas y convenciones transversales (validas para TODAS las interfaces)'),
 ('Estimacion Mule', [46, 30, 44, 80], e_header, estim,
  'Vista inversa: cada item de estimacion MuleSoft (vista S4) y las interfaces que cubre — incluye los huecos de cobertura'),
 ('Servicios SAP', [16, 46, 56, 20, 60], sv_header, servicios,
  'Catalogo de servicios SAP confirmados en la sesion 22/07 (documento Integraciones para cotizar y crear un pedido)'),
 ('Fuentes', [46, 80], f_header, fuentes,
  'Fundamentacion: documentacion oficial Salesforce / Automotive Cloud / SAP'),
]

content_types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
 '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
 '<Default Extension="xml" ContentType="application/xml"/>'
 '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
 '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
 + ''.join(f'<Override PartName="/xl/worksheets/sheet{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(len(sheets)))
 + '</Types>')

root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
 '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
 '</Relationships>')

workbook = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
 + ''.join(f'<sheet name="{esc(s[0])}" sheetId="{i+1}" r:id="rId{i+1}"/>' for i, s in enumerate(sheets))
 + '</sheets></workbook>')

wb_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
 + ''.join(f'<Relationship Id="rId{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i+1}.xml"/>' for i in range(len(sheets)))
 + f'<Relationship Id="rId{len(sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
 '</Relationships>')

styles = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
 '<fonts count="3">'
 '<font><sz val="10"/><name val="Arial"/></font>'
 '<font><b/><color rgb="FFFFFFFF"/><sz val="10"/><name val="Arial"/></font>'
 '<font><b/><sz val="13"/><color rgb="FF0F172A"/><name val="Arial"/></font>'
 '</fonts>'
 '<fills count="3">'
 '<fill><patternFill patternType="none"/></fill>'
 '<fill><patternFill patternType="gray125"/></fill>'
 '<fill><patternFill patternType="solid"><fgColor rgb="FF1D4ED8"/><bgColor indexed="64"/></patternFill></fill>'
 '</fills>'
 '<borders count="2">'
 '<border><left/><right/><top/><bottom/><diagonal/></border>'
 '<border><left style="thin"><color rgb="FFCBD5E1"/></left><right style="thin"><color rgb="FFCBD5E1"/></right>'
 '<top style="thin"><color rgb="FFCBD5E1"/></top><bottom style="thin"><color rgb="FFCBD5E1"/></bottom><diagonal/></border>'
 '</borders>'
 '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
 '<cellXfs count="4">'
 '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
 '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
 '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
 '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
 '</cellXfs>'
 '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
 '</styleSheet>')

out = '/tmp/claude-0/-home-user-diario-implantacao/893746cb-45f5-5d03-a6b1-46d670b73ed0/scratchpad/mapeo/Mapeo_de_Datos_SALES.xlsx'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', root_rels)
    z.writestr('xl/workbook.xml', workbook)
    z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
    z.writestr('xl/styles.xml', styles)
    for i, (name, widths, header, rows, title) in enumerate(sheets):
        z.writestr(f'xl/worksheets/sheet{i+1}.xml', sheet_xml(widths, title, header, rows))
print('xlsx ok:', out)
print('interfaces:', len(guia), '| campos:', len(campos), '| dedup:', len(dedup), '| reglas:', len(reglas))
