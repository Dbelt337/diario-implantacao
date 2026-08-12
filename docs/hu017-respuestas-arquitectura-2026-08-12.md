# HU-017 Gobernanza Cliente Maestro — respuestas de arquitectura para Melisa (v2, verificada contra los docs oficiales)

**Data:** 12/08/2026 · v2: campos reales confirmados en el Object Reference (AccountContactRelation, AccountAccountRelation, InternalOrganizationUnit, ContactPointAddress) y en "Considerations for Merging Duplicate Accounts".
Mensagem pronta para colar no Teams (em espanhol) — abaixo.

---

Melisa — van las definiciones de los 7 puntos, verificadas contra la documentación oficial (Object Reference y Help). Donde la decisión es de negocio/regulatoria lo marco explícito.

**1) Exoneración fiscal (RN-08 / RN-32)**

(a) **Híbrido, sin consulta a SAP por cotización.** La **CONDICIÓN** de exoneración (indicador, documento de respaldo — EXONET, acreditación diplomática, resolución — y vigencia) es **dato maestro del cliente en Salesforce**: nace con la cuenta, la gobierna esta HU y viaja SF→SAP en alta/modificación con los demás atributos fiscales derivados (RN-32). El **porcentaje definitivo** por indicador reside en SAP. Salesforce solo mantiene la **tasa de referencia** para exhibir el Precio Exonerado, y esa referencia vive en la tabla de tasas configurable (Decision Matrix de HU-038: País + Característica + Condición del cliente), editable sin despliegue.
La consulta viva a SAP (propuesta de Harvey) solo se justificaría si el indicador se administrara en SAP fuera del flujo maestro — lo que contradiría RN-01/RN-26: el cambio debe entrar por el maestro.
(b) Si aun así se decide consultar: **siempre vía MuleSoft** (gateway único). Implicaciones: latencia por cotización (llamada síncrona), presión sobre el límite de transacciones Apex largas concurrentes, y capacidad de API en Mule/SAP. Sin implicación de licencia Salesforce.
(c) Redacción sugerida para RN-32: *"Salesforce almacena la condición de exoneración (indicador, documento de respaldo y vigencia) como dato maestro del cliente y muestra el precio/tasa exonerada como referencia desde la tabla de tasas configurable; el porcentaje definitivo reside en SAP, que calcula el impuesto al facturar sobre el precio recibido del CRM. Salesforce no calcula impuestos definitivos ni duplica lógica fiscal."*

**2) Falla de replicación (RN-27 / Escenario 8)**

- **Near real-time, dirigida por eventos** (alta/modificación disparan la sincronización vía Mule). Batch solo como reconciliación nocturna de los "no sincronizado".
- **Notificación:** al rol de **administración de datos maestros** (RN-22) — Custom Notification + **Case automático en la cola de Datos Maestros** con el error crudo. El asesor solo ve el estado en la cuenta.
- **Corrección: en el sistema dueño del dato.** Error de dato → Salesforce (RN-01). Causa del lado SAP (sociedad no abierta, parametrización) → el Case se enruta al equipo SAP.
- **Reproceso en tres niveles:** (i) reintento automático con backoff para errores transitorios; (ii) guardar la corrección re-dispara la sincronización automáticamente; (iii) botón "Reintentar sincronización" para el administrador.

**3) Fuente de la verdad (RN-01 / RN-26)**

**Salesforce es el golden record del cliente comercial y envía a SAP** — dirección definitiva. Por tipo de dato:
- **Nace y se mantiene en SF:** identificación y documento, tipo de cliente, contactos e interlocutores, direcciones, consentimiento, condición de exoneración, atributos fiscales derivados.
- **Nace en SAP y SF solo consume (sin replicar):** número de deudor SAP por sociedad (vuelve como atributo de la extensión — ver punto 5) y dato contable/crediticio/saldos (RN-26: consulta en tiempo real contra el ERP).
- El "buscar clientes en SAP" de la HU original = **carga inicial/convivencia** (migración y dedup contra la base legada), no flujo permanente.

**4) Interlocutores / partner functions (RN-04)**

Confirmado contra el Object Reference:
- Personas con rol → **Contact + AccountContactRelation** (API 37+): un contacto en varias cuentas, campo `Roles` (multipicklist — los valores son personalizables: agregamos los roles de interlocutor de Grupo Q), `StartDate`/`EndDate` (histórico de la relación), `IsActive`, `IsDirect`, **soporta custom fields y Person Accounts** (clave para B2C).
- Funciones entre CUENTAS (solicitante/facturado/pagador/destinatario — SP/BP/PY/SH de SAP) → **AccountAccountRelation** con el tipo de relación en **PartyRoleRelation** (campo `PartyRoleRelationId` — ahí definimos "Facturado de", "Pagador de", etc.).
- Direcciones de entrega → **ContactPointAddress** (master-detail a Account): `AddressType` Billing/Shipping, vigencia (`ActiveFromDate/To`), y **geolocalización nativa** (`Latitude`, `Longitude`, `GeocodeAccuracy`) — el modelo para PA ya existe; lo que merece **historia propia** es el PROCESO de geocodificación y su uso en cobertura/rutas de PA. Sí, ampliarlo en historia específica.
- De-para rol SF ↔ función SAP: tabla de mapeo (Custom Metadata o mapeo en Mule). La replicación los llena **desde el inicio** (carga inicial + sincronización continua), como pidió Juan Carlos.

**5) Extensión multi-sociedad (RN-05)**

Modelado confirmado con los campos reales del **AccountAccountRelation** (API 58+; requiere Automotive + Group Membership habilitados):
- Cada sociedad se representa como **cuenta interna** (las 12: C101…P105), opcionalmente ligada a un **InternalOrganizationUnit** (el objeto que Automotive extiende justo para "estructuras de cuentas de una compañía", con lookup a Account).
- La extensión = un registro AAR: `AccountId` = cliente, `RelatedAccountId` = sociedad, `PartyRoleRelationId` = "Cliente de sociedad", `StartDate` = fecha de extensión, `IsActive`; **custom fields en la relación** para los datos locales (área de ventas, canal, deudor SAP de esa sociedad, indicador de sociedad de origen).
- Bonus de gobernanza que el doc confirma: AAR tiene **field history, sharing rules y sharing** propios — la visibilidad restringida por sociedad (RN-25 / Escenario 7) se apoya en eso.
- **Recomendación:** extensión **bajo demanda AUTOMÁTICA en el primer uso** (Escenario 2 tal cual está escrito): al seleccionar el cliente en una transacción de otra sociedad, el sistema pide solo los datos locales faltantes y extiende en el momento. Concilia a los dos stakeholders: nadie espera trámite y no se crea huella regulatoria en sociedades donde el cliente nunca operó. La creación automática en TODAS las sociedades del país es técnicamente viable (fan-out del alta vía Mule, un AAR por sociedad, guardando la de origen) — si el negocio la quiere, la decisión es regulatoria y debe quedar documentado quién la asume. En ambos casos el modelo AAR es el mismo; solo cambia CUÁNDO se crean las relaciones.

**6) Padrón Electoral de Costa Rica (RN-12)**

Viable, **fuera del núcleo de HU-017**, como historia propia de verificación de identidad. Dato verificado: el **TSE no publica una API REST oficial** — lo oficial es la consulta web por cédula y la **descarga del padrón completo** (ZIP actualizado en tse.go.cr/descarga_padron.html); las APIs REST existentes son de terceros. **Recomendación: carga periódica del ZIP oficial del TSE en un servicio interno de MuleSoft** (fuente oficial, sin dependencia de SLA/costo de un tercero), validación en la captura con **degradación graciosa**: si el servicio no responde, la captura continúa con la marca "documento no verificado" y re-verificación asíncrona — nunca bloquear una venta por indisponibilidad externa.

**7) Fusión de duplicados (RN-18)**

**Manual, nunca automática** (la RN ya lo fija): detección automática (duplicate/matching rules — HU-004/HU-006), fusión ejecutada por el rol de datos maestros. Mecánica nativa confirmada en "Considerations for Merging Duplicate Accounts":
- Hasta 3 cuentas por operación; se elige la principal y los valores campo a campo; relacionados (contactos, oportunidades, casos, actividades, archivos) se re-asignan a la principal; las no principales van a la **Papelera** (restaurarlas NO deshace la fusión); el registro fusionado conserva Created By/Date del registro MÁS ANTIGUO.
- **Restricciones oficiales a escribir en la HU:** no se puede fusionar Person Account con cuenta empresarial; cuentas con usuarios de portal/Experience Cloud no se fusionan; Chatter feed solo se conserva el de la principal.
- **⚠ Gotcha oficial crítico para nosotros:** *"Contact point objects don't support merging — relationships between contact point objects and person accounts are LOST after a merge."* Como los interlocutores usan ContactPointAddress (punto 4), el **checklist post-fusión debe re-crear/re-asociar las direcciones** del registro perdedor. Esto va escrito en la RN-18.
- **Post-fusión SAP:** el merge nativo no avisa a SAP — paso por integración: bloquear el deudor perdedor (baja lógica, coherente con RN-10) conservando el vínculo histórico.
- Casos automatizables: con Crédito y Cobro / CrediQ, como dijiste.

Cualquier punto que el negocio quiera desafiar lo vemos en sesión — con esto puedes ajustar las historias.

---

## Fuentes oficiales usadas (verificadas 12/08)
- AccountContactRelation — Object Reference (campos Roles/StartDate/EndDate/IsDirect; person accounts; custom fields)
- AccountAccountRelation — Automotive Cloud Dev Guide (AccountId/RelatedAccountId/PartyRoleRelationId/HierarchyType/Start-EndDate; history, sharing rules; requiere Automotive + Group Membership)
- Automotive Cloud Fields on InternalOrganizationUnit (estructuras de cuentas de la compañía; lookup Account)
- ContactPointAddress — Object Reference (master-detail Account; Billing/Shipping; vigencia; Latitude/Longitude/GeocodeAccuracy)
- Considerations for Merging Duplicate Accounts — Help (3 registros; papelera; contact points se PIERDEN; person/portal restrictions)
- TSE Costa Rica: consulta oficial por cédula + descarga oficial del padrón (sin API REST oficial)
