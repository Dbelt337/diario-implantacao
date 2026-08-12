# HU-017 Gobernanza Cliente Maestro — respuestas de arquitectura para Melisa

**Data:** 12/08/2026 · Responde a la consolidación de dudas de Melisa (7 puntos, HU-017 v. consolidada).
Mensagem pronta para colar no Teams (em espanhol) — abaixo.

---

Melisa — van las definiciones de los 7 puntos. Donde la decisión es de negocio/regulatoria lo marco explícito.

**1) Exoneración fiscal (RN-08 / RN-32)**

(a) **Híbrido, y es lo que la RN-32 ya insinúa:** la **CONDICIÓN** de exoneración (indicador, documento de respaldo — EXONET, acreditación diplomática, resolución — y su vigencia) es **dato maestro del cliente en Salesforce**: nace con la cuenta, la gobierna esta HU y viaja SF→SAP en alta/modificación junto con los demás atributos fiscales derivados. El **porcentaje definitivo** por indicador reside en SAP. Salesforce solo mantiene la **tasa de referencia** para exhibir el Precio Exonerado en la cotización, y esa referencia vive en la tabla de tasas configurable (la Decision Matrix de HU-038: País + Característica del vehículo + Condición del cliente), editable por el administrador sin despliegue.
No recomiendo la consulta a SAP por cotización (propuesta de Harvey): si el indicador puede cambiar en SAP fuera del flujo maestro, eso viola RN-01/RN-26 — el cambio debe entrar por el maestro. La consulta viva solo se justificaría si Grupo Q confirma que el indicador se administra en SAP por otra área; en ese caso:
(b) sí, **siempre vía MuleSoft** (gateway único). Implicaciones: latencia en la cotización (llamada síncrona por cotización), consumo del límite de transacciones Apex largas concurrentes (la misma razón por la que la disponibilidad migra a Continuation), y capacidad de API en Mule/SAP. No hay implicación de licencia Salesforce.
(c) Redacción sugerida para cerrar RN-32: *"Salesforce almacena la condición de exoneración (indicador, documento de respaldo y vigencia) como dato maestro del cliente y muestra el precio/tasa exonerada como referencia a partir de la tabla de tasas configurable; el porcentaje definitivo reside en SAP, que calcula el impuesto al facturar sobre el precio recibido del CRM. Salesforce no calcula impuestos definitivos ni duplica lógica fiscal."*

**2) Falla de replicación (RN-27 / Escenario 8)**

- **Replicación: near real-time, dirigida por eventos** (alta/modificación disparan la sincronización vía Mule). No batch; el batch queda solo como reconciliación nocturna que barre los "no sincronizado".
- **Notificación:** al rol de **administración de datos maestros** (RN-22), no al asesor — Custom Notification + **Case automático en la cola de Datos Maestros** con el error crudo (mismo patrón que ya usamos para el rechazo de creación de material en US-021). El asesor solo ve el estado "no sincronizado" en la cuenta (lectura).
- **Corrección: en el sistema DUEÑO del dato.** Si el error es de dato → se corrige en Salesforce (RN-01). Si la causa es del lado SAP (sociedad no abierta, parametrización) → el Case se enruta al equipo SAP; el dato no se toca en SAP.
- **Reproceso en tres niveles:** (i) reintento automático con backoff para errores transitorios (timeout/indisponibilidad); (ii) al guardar la corrección en la cuenta, la propia modificación re-dispara la sincronización — automático, sin acción extra; (iii) botón "Reintentar sincronización" para el administrador como acción manual.

**3) Fuente de la verdad (RN-01 / RN-26)**

Dirección definitiva: **Salesforce es el golden record del cliente comercial y envía a SAP** (RN-01, confirmada). Por tipo de dato:
- **Nace y se mantiene en SF →** identificación y documento, tipo de cliente, contactos e interlocutores, direcciones, consentimiento, condición de exoneración, atributos fiscales derivados (RN-32).
- **Nace en SAP y SF solo CONSUME (sin replicar) →** el número de deudor SAP por sociedad (vuelve como atributo de la extensión y se guarda en la AccountAccountRelation de esa sociedad) y el dato contable/crediticio/saldos — la propia RN-26 ya lo dice: consulta en tiempo real contra el ERP, sin copia local.
- El "buscar clientes en SAP" de la HU-017 original corresponde a la **carga inicial/convivencia** (migración y dedup contra la base legada), no al flujo permanente.

**4) Interlocutores / partner functions (RN-04)**

- Personas con rol → **Contact + AccountContactRelation** (roles múltiples, un contacto en varias cuentas — es exactamente lo que la RN-04 describe).
- Funciones de interlocutor entre CUENTAS (solicitante / facturado / pagador / destinatario — SP/BP/PY/SH de SAP) → **AccountAccountRelation con rol** (el mismo objeto estándar de la extensión por sociedad); direcciones de entrega → ContactPointAddress.
- De-para rol SF ↔ función SAP: tabla de mapeo (Custom Metadata en SF o mapeo en Mule). La replicación los llena **desde el inicio**, como pidió Juan Carlos: en la carga inicial y en la sincronización continua.
- Geolocalización para PA: **sí, historia específica.** Tiene alcance propio (geocoding de direcciones de entrega, cobertura/rutas de PA). HU-017 se queda con el modelo y el de-para.

**5) Extensión multi-sociedad (RN-05)**

Técnicamente **ambas opciones son viables** — la creación automática en todas las sociedades del país es un fan-out de la misma alta por sociedad vía Mule. Pero la recomendación de arquitectura es la **extensión bajo demanda AUTOMÁTICA en el primer uso**, que es literalmente el Escenario 2 de la HU: cuando el cliente se selecciona en una transacción de otra sociedad, el sistema pide solo los datos locales faltantes y lo extiende en el momento, guardando la sociedad de origen. Esto concilia a los dos stakeholders: nadie espera un trámite (la extensión es automática) y no se crea huella regulatoria en sociedades donde el cliente nunca operó. **No cambia la propuesta de AccountAccountRelation — la refuerza:** una relación por sociedad habilitada, con los datos locales, la sociedad de origen y el deudor SAP de esa sociedad. Si el negocio insiste en crear en todas las sociedades al alta: es el mismo flujo repetido N veces; la decisión es regulatoria, no técnica — que quede documentado quién la asume.

**6) Padrón Electoral de Costa Rica (RN-12)**

Viable, pero **fuera del núcleo de HU-017** (que garantiza tipo y formato del documento por país). Recomiendo una **historia propia de verificación de identidad**: validación en la captura vía MuleSoft (gateway único — el TSE no publica una API REST oficial estable; las vías son un proveedor de consulta de cédulas o la carga periódica del padrón publicado en un servicio interno de Mule), con **degradación graciosa**: si el servicio no responde, la captura continúa con la marca "documento no verificado" y re-verificación asíncrona — nunca bloquear una venta por indisponibilidad de un servicio externo. Alcance y costo dependen del proveedor: llevarlo a Grupo Q con la estimación de Mule.

**7) Fusión de duplicados (RN-18)**

La RN ya lo fija bien: **manual, nunca automática.** El sistema detecta y alerta (duplicate/matching rules — HU-004/HU-006); la fusión la ejecuta un usuario con permiso de datos maestros. El mecanismo nativo (merge de Accounts): hasta 3 registros por operación, se elige el maestro y los valores campo a campo; **todos los relacionados (contactos, oportunidades, cotizaciones, casos, actividades) se re-asignan al maestro**; los registros perdedores se **eliminan** (papelera) y la fusión queda auditada. Dos atenciones de arquitectura que hay que escribir en la HU: (i) el merge nativo **no avisa a SAP** — hace falta el paso post-fusión por integración: bloquear el deudor perdedor en SAP (baja lógica, coherente con RN-10) conservando el vínculo histórico; (ii) el merge es irreversible en la práctica — por eso manual y con checklist. Los casos automatizables, con Crédito y Cobro / CrediQ, como dijiste.

Cualquier punto que el negocio quiera desafiar, lo vemos en la próxima sesión — pero con esto puedes ajustar las historias.
