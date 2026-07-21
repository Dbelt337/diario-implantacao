# HU-027 — Guía técnica detallada: Integración Microsoft 365 ↔ Salesforce

Para el **administrador de Microsoft 365 de Grupo Q** + Santiago (Salesforce).
Enfoque **nativo** (features estándar de Salesforce, sin desarrollo custom, sin
OmniStudio) y **Microsoft Graph** (no EWS). Alcance HU-027: **add-in de Outlook**
(ver registros SF + registro manual) + **sync de eventos** vía **Einstein Activity
Capture (EAC)**. NO es espejado total de buzones.

> Nota de fundamentación: HU-027 no involucra objetos de Automotive Cloud ni
> OmniStudio — son features de productividad de Sales Cloud. Las fuentes oficiales
> son Salesforce Help (EAC / Outlook Integration) y Microsoft Learn (EWS / Entra).
> [Rótulos de UI marcados con (confirmar) se cerrarán con los docs oficiales.]

## Contexto del bloqueo (por qué falla hoy)
1. **Add-in en blanco:** el add-in usa **Nested App Authentication (NAA)**. Si el
   tenant M365 no dio **consentimiento OAuth** a la app de Salesforce, el token
   silencioso falla → panel de Sign In en blanco.
2. **EAC no sincroniza:** "Check User Health Status" muestra Active pero
   *"Can't determine version of Microsoft Exchange"* → la conexión está intentando
   **EWS**, y el tenant lo tiene **restringido/bloqueado**. Microsoft desactiva EWS
   por defecto el **1/oct/2026**. Solución correcta: **conectar por Microsoft
   Graph**, no desbloquear EWS.
3. **PoC en tenant OSF (osf.digital):** las políticas de OSF bloquean ambas
   integraciones. La validación real debe hacerse con un **buzón piloto del tenant
   de Grupo Q**.

---

## ACCIÓN 1 — Consentimiento del add-in de Outlook (NAA)

**Quién:** admin M365 de Grupo Q (rol Global Admin / Cloud Application Admin /
Application Administrator).

**Opción A — Admin Consent URL (recomendada):**
1. Santiago la obtiene en Salesforce: **Setup → (buscar) "Outlook Integration and
   Sync" → sección "Give Users the Integration in Outlook" → "Admin Consent URL
   (For Your Office 365 Admin)"** → copiar el enlace.
2. El admin M365, **con sesión iniciada como admin**, abre esa URL en el navegador.
3. Microsoft muestra la pantalla de consentimiento con los permisos que pide la app
   de Salesforce → **Accept** (marcar "Consent on behalf of your organization" si
   aparece) → consentimiento **a nivel de toda la organización**.

**Opción B — Entra ID directamente:**
- **entra.microsoft.com → Identity → Applications → Enterprise applications** →
  buscar la app **"Salesforce"** (la del add-in) → **Security → Permissions →
  "Grant admin consent for [Grupo Q]"**.
- (Alternativa user-consent: **Enterprise applications → Consent and permissions →
  User consent settings** → permitir que los usuarios consientan apps.)

**Verificación:** el piloto abre el add-in en Outlook → el panel de Salesforce
autentica **sin quedar en blanco** y muestra las pestañas **Compose / Related /
Tasks**.

---

## ACCIÓN 2 — Conexión de EAC por Microsoft Graph (User-Level OAuth 2.0)

> Confirmado en doc oficial: la conexión **User-Level OAuth 2.0** a Microsoft 365
> **usa Microsoft Graph** (su pre-requisito es que el Azure admin conceda acceso
> org-wide a la Graph API). Es decir, elegir "Microsoft 365 + User-Level OAuth 2.0"
> **es** ir por Graph — no hay que tocar EWS.

**Pre-requisito (admin M365 de Grupo Q):** conceder **acceso y permisos org-wide
de la Microsoft Graph API** a la app de Salesforce (ver doc "App ID for Microsoft
Graph Authentication" para el/los App ID exactos a consentir en Entra ID). El
admin debe tener rol **Global Admin / Cloud Application Admin / Application Admin**.

**Lado Salesforce (Santiago) — permiso necesario: Customize Application o Modify All Data:**
1. **Setup → Quick Find → "Einstein Activity Capture" → Settings.**
2. Si es primera configuración, el flujo guía los pasos. **Si ya está configurado
   y hay que cambiar el método de autenticación (p. ej. está en EWS) → hay que
   RESETEAR Einstein Activity Capture** (no es un simple toggle). [Existe además una
   ruta de "Upgrade to Microsoft Graph" para conexiones elegibles — confirmar en el
   doc #2 cuál aplica a esta org antes de resetear.]
3. Seleccionar **Microsoft 365** como app de correo/calendario.
4. Seleccionar **User-Level OAuth 2.0** como método de autenticación.
5. Completar los pasos restantes: crear una **configuración** y **agregar usuarios**.
6. Salesforce le pide a cada usuario **conectar su cuenta Microsoft 365**. Hasta que
   lo hagan, **no pueden enviar correos en Lightning Experience**. El usuario piloto
   conecta/reconecta su cuenta.

**Lado M365 (admin):** al conectar, se otorga el **consentimiento org-wide de los
permisos de Microsoft Graph** a la app de Salesforce (una sola vez). Requiere el rol
indicado arriba.

**Verificación:** **Check User Health Status** muestra conexión **Active** y la
**versión de Exchange se determina** (sin la advertencia de EWS).

---

## ACCIÓN 3 — Desbloqueos de red / Conditional Access / IPs

**Quién:** admin M365 / equipo de seguridad de Grupo Q.
1. **Conditional Access (Entra ID → Protection → Conditional Access):** verificar
   que ninguna política **bloquee** la app de Salesforce / EAC (p. ej. políticas
   por app, o MFA que un servicio no pueda cumplir). Si aplica, **excluir** la app
   de Salesforce EAC de esa política.
2. **Políticas de Exchange Online:** confirmar que el buzón del piloto no tenga
   restringido el acceso de aplicaciones.
3. **Allowlist de IPs:** si el tenant/firewall filtra por IP, agregar los **rangos
   de IP publicados por Salesforce para EAC** (Santiago los obtiene en el asistente
   de EAC → **"See required IP addresses"**).

---

## ACCIÓN 4 — Distribución del add-in (opcional, para todos los usuarios)

**M365 admin center (admin.microsoft.com) → Settings → Integrated apps →
"Get apps"** → buscar **"Salesforce"** → **Deploy** → asignar a usuarios/grupos.
(Alternativa: cada usuario lo instala desde **Microsoft AppSource**.)

---

## NO hacer
- ❌ **No habilitar EWS.** Se desactiva por defecto el 1/oct/2026 (retiro total
  abril/2027). Ir directo por **Microsoft Graph**. (Puente EWS solo si es
  imprescindible para una prueba puntual, coordinado con Santiago.)

## Resultado esperado al cerrar
1. Add-in de Outlook autentica y muestra registros de Salesforce. ✅
2. Un evento creado en Outlook aparece en Salesforce (Calendar + Activity Timeline)
   en pocos minutos. ✅
3. Health Status **Active** vía **Microsoft Graph**, versión de Exchange
   determinada. ✅

## Docs oficiales base (a confirmar rótulos exactos)
- Salesforce Help — Connect EAC to Microsoft Office 365 (User-Level / Microsoft Graph).
- Salesforce Help — Give Users the Outlook Integration / Admin Consent URL.
- Salesforce Help — Einstein Activity Capture required IP addresses.
- Microsoft Learn — Grant tenant-wide admin consent to an application.
- Microsoft Learn — Deprecation of EWS in Exchange Online.
- Microsoft Learn — Deploy add-ins in the Integrated Apps portal.
