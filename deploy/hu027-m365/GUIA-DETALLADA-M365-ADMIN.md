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

## ACCIÓN 2 — Conexión de EAC por Microsoft Graph + consentimiento

**Lado Salesforce (Santiago):**
1. **Setup → (buscar) "Einstein Activity Capture" → Settings** (o el nombre de la
   configuración activa) → revisar el **método de conexión**.
2. Si la conexión está en **EWS** (síntoma del §Contexto), hacer el **upgrade a
   Microsoft Graph** (confirmar botón/enlace exacto en el doc oficial). Desde
   **Spring '26**, las conexiones nuevas de M365 usan Graph por defecto; las
   anteriores requieren upgrade manual.
3. Con autenticación **User-Level**, el usuario piloto verá un **banner para
   reconectar** su cuenta Microsoft → reconecta.

**Lado M365 (admin):**
4. Durante el flujo de conexión (o en Entra ID → Enterprise applications → la app
   **"Salesforce" / "Einstein Activity Capture"**) → **Grant admin consent** de los
   permisos de **Microsoft Graph** (lectura de correo/calendario según la app).
   Requiere rol Global / Cloud App / Application Admin. Consentimiento **org-wide**
   (una sola vez, sin consentimiento por usuario).

**Verificación:** **Check User Health Status** muestra conexión **Active** vía
**Graph** y la **versión de Exchange se determina** (sin la advertencia de EWS).

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
