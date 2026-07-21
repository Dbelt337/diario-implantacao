# HU-027 — Guía técnica detallada: Integración Microsoft 365 ↔ Salesforce

Para el **administrador de Microsoft 365 de Grupo Q** + Santiago (Salesforce).
Enfoque **nativo** (features estándar, sin desarrollo custom ni OmniStudio) y
**Microsoft Graph** (no EWS). Alcance HU-027: **add-in de Outlook** (ver registros
SF + registro manual) + **sync de eventos** vía **Einstein Activity Capture (EAC)**.
NO es espejado total de buzones. Fundamentación: Salesforce Help (EAC / Outlook
Integration) + Microsoft Learn. Rótulos confirmados con docs oficiales.

## Contexto del bloqueo (por qué falla hoy)
1. **Add-in en blanco:** el add-in usa autenticación que requiere **consentimiento
   OAuth del tenant M365** a la app de Salesforce. Sin ese consentimiento, la
   ventana de Sign In queda en blanco.
2. **EAC no sincroniza:** "Check User Health Status" muestra Active pero *"Can't
   determine version of Microsoft Exchange"* → la conexión intenta **EWS** y el
   tenant lo tiene restringido. Microsoft **retira EWS el 1/oct/2026** (retiro total
   abril/2027) y **Microsoft Graph lo reemplaza**. Solución: **ir por Graph**.
   Desde **Spring '26**, EAC con Microsoft 365 se autentica automáticamente por
   Graph; configs anteriores deben **actualizarse a Graph antes de agosto/2026**.
3. **PoC en tenant OSF (osf.digital):** políticas de OSF bloquean ambas
   integraciones. Validar con un **buzón piloto del tenant de Grupo Q**.

---

## ACCIÓN 1 — Consentimiento del add-in de Outlook (desbloquea la ventana en blanco)

**Lado Salesforce (Santiago) — ya hecho, referencia:** add-in "Salesforce"
instalado desde **Microsoft AppSource** y configurado en **Setup → Set Up the
Integration with Outlook**.

**Lado M365 (admin de Grupo Q):** otorgar el **consentimiento de administrador**
a la app de Salesforce en el tenant. El consentimiento **User-Level de EAC+Inbox**
(Acción 2) cubre también la autenticación Inbox del add-in. Si tras ese consent el
panel de registros del add-in aún queda en blanco, otorgar consent a la app del
add-in en **Entra ID → Identity → Applications → Enterprise applications** →
buscar **"Salesforce"** → **Security → Permissions → "Grant admin consent for
Grupo Q"**.

**Uso (usuario):** en Outlook (web / 2016 / Mac 2016 / 2013), seleccionar un correo
o evento → botón **Salesforce** → iniciar sesión en Salesforce → aparecen los
registros relacionados.

**Verificación:** el add-in autentica **sin quedar en blanco** y muestra
**Compose / Related / Tasks**.

---

## ACCIÓN 2 — EAC por Microsoft Graph (User-Level OAuth 2.0) ★ acción central

> **User-Level OAuth 2.0 hacia Microsoft 365 = Microsoft Graph.** No hay que tocar
> EWS. Elegir Microsoft 365 + User-Level OAuth 2.0 ya es ir por Graph.

### 2.1 Pre-requisito — consentimiento org-wide de la Graph API (admin M365)
El admin de Grupo Q (rol **Global Admin / Cloud Application Admin / Application
Admin**) abre el **Admin Consent URL** del nivel **User-Level (EAC e Inbox)** y
otorga el consentimiento a nivel de toda la organización (automatiza los scopes,
evita que cada usuario autorice manualmente):

```
https://login.microsoftonline.com/common/adminconsent?client_id=e535e657-0666-4ad5-940a-c3cf6296a541
```

Scopes/permissions que se conceden (User-Level, delegados):
`Calendars.ReadWrite · Contacts.ReadWrite · Mail.Read · Mail.Send · User.Read ·
openid · profile · email · offline_access`

(App IDs oficiales por nivel — por si se opta por otro método:
Application-Level `cbcb7087-72b9-4977-8dd7-aa803a5da602` ·
RBAC `da3cd6f0-d438-40a4-8524-4cc3569a23b6` ·
User-Level `e535e657-0666-4ad5-940a-c3cf6296a541`.)

### 2.2 Lado Salesforce (Santiago) — permiso: Customize Application o Modify All Data
1. **Setup → Quick Find → "Einstein Activity Capture" → Settings.**
2. **Config nueva** (post-Spring '26): el flujo guía y usa **Graph** automáticamente.
   **Config existente en EWS:** hacer el **Upgrade a Microsoft Graph**. (Para
   *cambiar el método de autenticación* de una config existente puede requerirse
   **reset de EAC**; el *upgrade a Graph* es la ruta específica para pasar de EWS a
   Graph sin reconfigurar todo — usar el upgrade si la org es elegible.)
3. Método: **Microsoft 365** + **User-Level OAuth 2.0**.
4. Al hacer upgrade User-Level, cada usuario recibe un **banner para reconectar** su
   cuenta Microsoft. **La sync sigue por EWS hasta que cada usuario reconecta**;
   tras reconectar, esa conexión pasa a **Graph**. Hasta conectar, el usuario **no
   puede enviar correos en Lightning Experience**.

**Alternativa para escala — Application-Level OAuth:** acceso org-wide aprobado por
el admin, **sin reconexión individual** (Salesforce usa Client Credential flow con
un certificado en su vault gestionado). Trade-off: acceso más amplio a los buzones.
Admin Consent URL: `...adminconsent?client_id=cbcb7087-72b9-4977-8dd7-aa803a5da602`.
Decidir User-Level vs Application-Level con seguridad de Grupo Q.

**Verificación:** **Check User Health Status** → conexión **Active** y **versión de
Exchange determinada** (sin la advertencia de EWS).

---

## ACCIÓN 3 — Red / allowlist (para Microsoft Graph)

Como vamos por **Graph**, permitir en **outbound** los **webhooks de Microsoft
Graph** (para que Microsoft 365 envíe push notifications a Salesforce):

| Instancia SF | Webhook Microsoft Graph (outbound) |
|---|---|
| Fuera de Europa | `apiq-ms-gph-webhook-c01.apiq.sfdc-lywfpd.svc.sfdcfc.net` · `apiq-ms-gph-webhook-c02.apiq.sfdc-lywfpd.svc.sfdcfc.net` |
| En Europa | `apiq-ms-gph-webhook-c01.apiq.sfdc-yzvdd4.svc.sfdcfc.net` |

- **Los IPs inbound de EWS NO aplican** al ir por Graph (eran para exponer el
  Exchange server; con Graph la conexión es Salesforce → nube de Microsoft).
- Permitir además los **IPs/dominios generales de Salesforce** (ver "Salesforce IP
  Addresses and Domains to Allow").
- **Confirmar la región de la instancia Salesforce de Grupo Q** (Europa o no) para
  elegir el webhook correcto.
- Revisar **Conditional Access** (Entra ID): que ninguna política bloquee la app de
  Salesforce/EAC.

---

## ACCIÓN 4 — Distribución del add-in (opcional, todos los usuarios)
**M365 admin center (admin.microsoft.com) → Settings → Integrated apps → Get apps**
→ buscar **"Salesforce"** → **Deploy** → asignar a usuarios/grupos. (Alternativa:
cada usuario lo instala desde Microsoft AppSource.)

---

## NO hacer
- ❌ **No habilitar EWS.** Se desactiva por defecto el 1/oct/2026. Ir por Graph.

## Deadlines
- **Agosto 2026:** completar el upgrade a Microsoft Graph (Salesforce) — antes del
  bloqueo de Microsoft.
- **1 oct 2026:** EWS desactivado por defecto. **Abril 2027:** retiro total.
- Impacto: si hubiera **Lightning Sync** con EWS, migrar a EAC + Graph antes de
  agosto/2026. (EAC/Inbox: actualizar uno a Graph actualiza el otro.)

## Resultado esperado al cerrar
1. Add-in de Outlook autentica y muestra registros de Salesforce. ✅
2. Un evento creado en Outlook aparece en Salesforce (Calendar + Activity Timeline)
   en minutos. ✅
3. Health Status **Active** vía **Microsoft Graph**, versión de Exchange
   determinada. ✅

## Fuentes oficiales (confirmadas)
- Salesforce Help — Connect EAC to Microsoft 365 (User-Level Authentication).
- Salesforce Help — Microsoft Graph API in EAC / App ID for Microsoft Graph
  Authentication / Upgrade to Microsoft Graph.
- Salesforce Help — Network Connection (IPs/webhooks EAC).
- Salesforce Help — Outlook Integration / Give Outlook Access to Salesforce.
- Microsoft Learn — Deprecation of EWS in Exchange Online.
