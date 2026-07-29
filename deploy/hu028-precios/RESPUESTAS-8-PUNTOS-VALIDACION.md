# HU-028 — Respuestas del arquitecto a los 8 puntos abiertos (revision Grupo Q 27/07)

Fecha: 29/07/2026. Autor: Diego Beltrao (Arquitectura de Ventas).
Destino: documento HU-028_Repuestos_y_PA_Construccion_y_Administracion_del_Precio
(secciones marcadas en amarillo por Melisa). Texto listo para pegar en cada punto.

Principio que gobierna todas las respuestas (native-first, ya acordado y
registrado en el proyecto): SAP es la fuente de la verdad del precio de
Repuestos & PA; Salesforce consulta via MuleSoft y muestra — no calcula, no
convierte, no administra precios (RN-01/03/09/11; Dominio de Precios
Repuestos/PA v1, pestana Responsabilidades). Donde Salesforce si aporta, es
con capacidad ESTANDAR de la plataforma, nunca duplicando logica de SAP.

Referencias oficiales citadas al final. Los numeros siguen el orden del
documento de Melisa.

---

## 1. Carga masiva de precios (RN-11) — MANTENER RN-11: exclusiva en SAP

Respuesta: NO construir carga masiva de precios en Salesforce (ni plantillas
de Data Loader ni interfaz). RN-11 se mantiene tal como esta redactada.

Fundamento tecnico:
- En Salesforce NO existe objeto de precios que actualizar en masa: para
  Repuestos no hay lista (precio dinamico construido por SAP en cada
  consulta, RN-01/04) y para PA el PricebookEntry es referencia de
  EXHIBICION, no fuente de precio (decision registrada del proyecto). Una
  carga masiva en Salesforce actualizaria un dato que el propio sistema no
  usa para poner precio — o peor, crearia una segunda verdad de pricing.
- Best practice de integracion (patron "single source of truth" / system of
  record): el dato maestro se actualiza en su sistema de origen y se publica
  a los consumidores. La actualizacion masiva ya existe en SAP (transacciones
  de condiciones de precio SD); la sincronizacion via MuleSoft republica lo
  actualizado. Duplicar la herramienta de carga en el CRM duplica el riesgo
  (precios divergentes, sin validez fiscal).
- Si Grupo Q necesitara en el futuro DISPARAR la actualizacion desde
  Salesforce, eso seria un servicio de ESCRITURA de dato maestro en el
  contrato MuleSoft (misma categoria que HU-039), con SAP ejecutando —
  alcance nuevo, no dimensionado en R1-S8, a decidir como cambio de alcance.
- Lo detallado en el Technical Annex V5 (plantillas Data Loader) queda
  cubierto de forma nativa en el lugar correcto: la carga masiva del propio
  SAP, que es donde viven las listas activas.

## 2. Fecha de precio y congelamiento (RN-05) — las dos afirmaciones son
## verdaderas en capas distintas; RN-05 se mantiene con una precision

Respuesta: Salesforce FIJA y GUARDA la fecha/vigencia comercial de la
cotizacion; SAP RECONSTRUYE y honra el precio a esa fecha. No hay conflicto
entre lo que dice Grupo Q y la RN vigente — son capas distintas.

Como queda (nativo):
- La cotizacion estandar de Salesforce ya trae el congelamiento comercial:
  Quote.ExpirationDate guarda la vigencia (8/15/30 dias) y el precio cotizado
  queda registrado en QuoteLineItem — la linea NO se refresca sola; el numero
  cotizado queda historico en el documento de forma nativa.
- La "fecha de precio" viaja como PARAMETRO DE ENTRADA del servicio de
  precios: el borrador de contrato del RFC Get_Price_ZGQREF ya incluye
  fechaPrecio en el request y en el response (tarea T01). Al confirmar dentro
  de la vigencia, Salesforce envia la fechaPrecio de la cotizacion y SAP
  reconstruye el MISMO precio desde su historico de condiciones (nucleo de
  RN-05, que se mantiene: el historico y la reconstruccion son de SAP).
- Ajuste de redaccion sugerido para RN-05: "Salesforce fija la fecha de
  precio y la vigencia de la cotizacion/pedido (Quote.ExpirationDate y campo
  de fecha de precio en la linea) y la envia como parametro al servicio de
  precios; SAP mantiene el historico de condiciones y reconstruye el precio a
  esa fecha durante la vigencia; vencida esta, se consulta el precio actual."
- El campo de fecha de precio en la linea (tarea T06) se crea SOLO despues de
  validar esta redaccion (misma disciplina de describe-antes-de-crear usada
  en HU-041/042).

## 3. Combos (RN-13) — el combo se crea y se valora en SAP; RN-13 se mantiene

Respuesta: mantener RN-13. El combo es un SKU (material SAP) cuyo precio se
calcula AUTOMATICAMENTE A PARTIR DE SUS COMPONENTES EN SAP, no en Salesforce.
Salesforce lo trata como un Product2 mas (ProductCode = material SAP del
combo) y muestra el precio que devuelve el mismo servicio Get_Price_ZGQREF.

Fundamento tecnico (native-first y licenciamiento):
- Salesforce SIN CPQ / Revenue Cloud no tiene motor estandar de precio de
  kit/bundle (esa capacidad pertenece a esos productos, que Grupo Q NO tiene
  licenciados — guarda registrada del proyecto). Automotive Cloud tampoco
  aporta un motor de precio de kits en el modelo estandar (Developer Guide
  v66.0: no existe objeto estandar de BOM comercial con calculo de precio).
  Calcular el combo desde componentes en Salesforce seria construir un motor
  de pricing custom — exactamente lo que la historia prohibe (RN-03).
- SAP SD ya resuelve esto de forma estandar (estructuras de material /
  listas tecnicas y esquema de condiciones): el precio del combo se deriva de
  los componentes segun la regla que Repuestos y PA respondieron ("se calcula
  automaticamente a partir de sus componentes") — esa regla se parametriza en
  SAP y el resultado viaja a Salesforce con su desglose ZGQREF.
- ¿"Crearse en Salesforce"? El REGISTRO del combo llega a Salesforce por el
  sync de catalogo (HU-030) como cualquier material; si el combo aun no
  existe en SAP, el camino es la solicitud de material de la HU-039 (SAP crea
  y devuelve el MATNR). Lo que no se hace es definir composicion y precio en
  Salesforce.
- Descuentos sobre el combo: los automaticos (ZRTA/ZRCR) llegan dentro del
  precio de SAP (RN-14); los manuales siguen la HU-065. Sin cambio.

## 4. Administracion y auditoria de listas en Salesforce — administracion:
## SAP; acceso y visibilidad: Salesforce nativo; auditoria de pricing: SAP

Respuesta: mantener la premisa (administracion 100% SAP) y resolver lo que
Grupo Q realmente pide con capacidades nativas de consulta y trazabilidad:

- Administrar (crear/modificar listas y parametros): en SAP, unico lugar
  donde el dato es productivo. En Salesforce no hay nada que administrar —
  el PricebookEntry de PA es referencia de exhibicion (si alguien lo editara,
  el precio real no cambiaria: eso es un riesgo de inconsistencia, no una
  funcionalidad). Los perfiles citados (Coordinador de Operaciones Regional,
  Inteligencia Comercial) necesitan acceso de administracion EN SAP; en
  Salesforce les damos la CONSULTA con permiso dedicado (Custom Permission +
  Permission Set, tarea T09 — mismo patron ya usado en HU-042).
- Auditoria/historial: el historico oficial de cambios de precio ya existe en
  SAP (documentos de modificacion de condiciones) y es el unico con validez.
  Salesforce solo puede auditar lo que Salesforce almacena: para los campos
  de referencia del PricebookEntry se puede evaluar Field History Tracking
  nativo (sujeto a validacion en la org de que el objeto lo soporte — se
  confirma con describe antes de prometer); la configuracion queda cubierta
  por el Setup Audit Trail estandar. Lo que NO se recomienda es replicar el
  historial de pricing de SAP dentro del CRM: seria una segunda auditoria sin
  valor legal y con costo de almacenamiento/sincronizacion permanente.
- Si tras esta aclaracion Grupo Q sigue queriendo administracion de listas EN
  Salesforce, eso contradice RN-11 y las premisas aprobadas y entra como
  cambio de alcance no dimensionado (tarea T14 queda en analisis hasta esa
  decision).

## 5. Consulta rapida del precio (GQ-PV-03-036) — recomendacion: las dos,
## con UN solo componente [decision final de Grupo Q]

Respuesta recomendada: construir UNA sola pieza (LWC de consulta de precio,
tarea T03) y exponerla en los dos contextos, porque el costo marginal es
practicamente cero y cubre los dos usos que Grupo Q describio:

- Dentro del documento (cotizacion/pedido): la consulta ya ocurre al agregar
  la linea (HU-043 consume el precio de esta historia).
- Pantalla independiente (mostrador/atencion rapida): el MISMO componente
  publicado en una App Page / Utility Bar, para consultar precio por canal y
  codigo de cliente SIN abrir un documento — que es exactamente el texto del
  requisito ("consulta rapida del precio por canal de venta y por codigo de
  cliente").
- Tecnicamente es un unico servicio (GuidedSellingController.getPricePageData,
  que ya nacio con canal, clienteId y cantidad en la firma) y un unico LWC
  con dos targets de despliegue — patron estandar de Lightning (mismo
  componente en record page y app page). Cero duplicacion.
- Queda para Grupo Q confirmar solo la PRIORIDAD: si la pantalla
  independiente entra en R1 junto con la consulta en documento o despues.

## 6. Comparacion de precios (RN-12) — en R1: bajo demanda, por SKU, solo
## fuentes internas [confirmar accionador con Grupo Q]

Respuesta recomendada:
- Fuentes: SOLO informacion interna (los precios que SAP devuelve por
  sociedad/marca/etc.). Fuentes EXTERNAS (competencia, mercado) implican una
  integracion nueva que no existe en el Technical Annex V5 — si Grupo Q la
  quiere, es requisito nuevo con contrato y costo propios, no cabe en esta
  historia.
- Granularidad: POR SKU/material bajo demanda del usuario (vendedor o
  analista) desde la pantalla de consulta — accionador explicito, en el
  momento de cotizar o analizar. Una comparacion SISTEMATICA sobre todo el
  maestro es un proceso analitico masivo: eso es reporting del lado
  SAP/BI (donde estan todos los precios), no una transaccion del CRM;
  ejecutarla desde Salesforce significaria disparar miles de consultas al
  servicio de precios (costo e latencia sin valor transaccional).
- Los criterios ya respondidos (marca, tipo de material, jerarquia,
  antiguedad, sociedad + familia, categoria, modelo y año pedidos por Grupo
  Q) entran como parametros de la consulta al servicio; Salesforce presenta
  la comparacion (tarea T07).
- Pregunta que queda a Grupo Q: confirmar el accionador/momento (boton en la
  consulta de precio vs. pantalla del analista) — la arquitectura soporta
  ambos con el mismo servicio.

## 7. Simulacion (RN-10) — lo viable lo define el contrato del servicio; OSF
## especifica aqui lo que el contrato debe exponer

Respuesta (esto es lo que Grupo Q pidio: la especificacion de OSF para el
contrato tecnico del servicio de simulacion):

Request minimo del servicio de simulacion (SAP via MuleSoft, servicio
/price-simulations del mapa de integraciones):
- material o lote/criterio (rotacion, familia), sociedad, moneda;
- variables a simular: nuevo FOB y/o nuevo factor de acercamiento y/o nuevo
  mark-up (al menos una);
- flag de base historica (comparar contra historico de precios).

Response minimo:
- precio actual y precio simulado, margen actual y margen simulado, con el
  mismo desglose ZGQREF que la consulta de precio;
- moneda y fecha/hora de calculo;
- identificador del escenario calculado (para trazabilidad).

Con ese contrato, RN-10 se cierra tal como esta: SAP ejecuta el calculo sin
tocar precios productivos; Salesforce (pantalla del analista, tarea T08,
acceso por Permission Set segun los perfiles ya respondidos) consume y
muestra. Guardar/versionar escenarios (pedido de Grupo Q): se resuelve de
forma NATIVA con Salesforce Files — ContentVersion versiona automaticamente
cada actualizacion del archivo de escenario (JSON del request/response) —
sin crear objeto custom nuevo, respetando la restriccion registrada del
cliente para las HU de Repuestos. Si SAP no puede exponer el servicio de
simulacion en R1, la pantalla se difiere completa (no se construye una
simulacion local en Salesforce).

## 8. Precio, descuentos e impuestos en la exhibicion — precio FINAL con
## impuestos, desglose visible; la frontera con HU-115 no se mueve

Respuesta: el precio que Salesforce muestra en cotizacion/pedido es el precio
FINAL que SAP devuelve — que YA incluye los descuentos automaticos (ZRTA,
ZRCR dentro del precio, RN-14) y las condiciones fiscales (MWST, y J1RI
cuando aplica) del esquema ZGQREF (RN-16). Salesforce presenta el total y el
DESGLOSE tal como llega, sin recomponer: precio parte (ZPRT), descuentos
aplicados, subtotal (KUMU), IVA (MWST), retencion (J1RI).

Por que esto es lo correcto y no rompe la frontera con HU-115:
- Coincide con lo que Grupo Q pide ("el impuesto deberia formar parte del
  precio en la cotizacion y el pedido") y con RN-07 ("al cliente se le
  muestra su precio final, no un descuento").
- La DETERMINACION del impuesto (que condicion aplica, que tasa, por pais y
  categoria de cliente — p.ej. J1RI solo El Salvador segun categoria) sigue
  siendo 100% SAP y su definicion de reglas pertenece a HU-115. HU-028 no
  calcula ni parametriza impuestos: EXHIBE la composicion que SAP entrega en
  la respuesta de precio. Exhibir no es determinar — la frontera queda
  intacta y asi debe precisarse en la redaccion.
- Presentacion recomendada en la UI: total con impuestos como cifra
  principal + desglose expandible (transparencia para el vendedor y el
  cliente, y coincide con el documento de venta de SAP, evitando diferencias
  entre cotizacion y factura).
- Nota tecnica: la nota fiscal/factura sigue siendo de SAP; cualquier
  redondeo por moneda se muestra tal como SAP lo devuelve (decision #9 del
  Dominio de Precios: misma regla de redondeo que SAP por sociedad).

---

## Sintesis para la reunion (o para evitarla)

- Cerrados por arquitectura (no requieren reunion): 1 (carga masiva: SAP),
  2 (fecha de precio: SF fija/envia, SAP reconstruye), 3 (combo: SAP crea y
  valora; SF exhibe), 4 (administracion SAP; consulta y permisos nativos en
  SF), 7 (especificacion del contrato de simulacion entregada; guardar
  escenarios via Files nativo), 8 (precio final con impuestos + desglose;
  frontera HU-115 intacta).
- Quedan con Grupo Q (pueden resolverse por escrito): 5 (prioridad de la
  pantalla independiente en R1) y 6 (accionador/momento de la comparacion;
  confirmacion de que fuentes externas quedan fuera).
- Proceso: estas respuestas actualizan la redaccion de RN-05 y precisan
  RN-13/RN-16; Melisa incorpora en la version unica ANTES del refinamiento
  (compromiso del 22/07) y el registro en la GUIA se hace el mismo dia de la
  validacion.

## Referencias oficiales (para anexar al documento)

1. Salesforce Automotive Cloud Developer Guide v66.0 (Spring '26) — modelo de
   objetos estandar (sin motor de precio de kits/BOM comercial):
   https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/
2. Salesforce Object Reference — Quote / QuoteLineItem (ExpirationDate,
   precio de linea persistido en la cotizacion):
   https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_quote.htm
3. Salesforce Object Reference — ContentVersion (versionado nativo de Files):
   https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_contentversion.htm
4. Salesforce Help — Field History Tracking y Setup Audit Trail (auditoria
   nativa de la plataforma):
   https://help.salesforce.com/s/articleView?id=sf.tracking_field_history.htm
   https://help.salesforce.com/s/articleView?id=sf.admin_monitorsetup.htm
5. Integration patterns (system of record / single source of truth):
   https://developer.salesforce.com/docs/atlas.en-us.integration_patterns_and_practices.meta/integration_patterns_and_practices/
6. Evidencia de licenciamiento org Grupo Q (22/07/2026, registrada en el
   proyecto): sin CPQ / Revenue Cloud / EPC; BRE licenciado; Rebate
   Management y Price Protection licenciados.

Nota: si algun enlace no abre desde el ambiente de trabajo, pedir el
contenido y validar la cita antes de publicar la version final de la HU
(mismo criterio usado en HU-041: la validacion que vale es contra la org).
