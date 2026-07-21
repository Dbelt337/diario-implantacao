# HU-027 — Sesión de trabajo: desbloqueo integración Microsoft 365 ↔ Salesforce

Objetivo: en una sola sesión, dejar funcionando el **add-in de Outlook** y el
**sync de calendario (Einstein Activity Capture)** en el tenant de **Grupo Q**,
por **Microsoft Graph** (sin EWS). El lado Salesforce ya está configurado.

## Participantes
- **Santiago** (Salesforce / OSF) — verifica el lado SF, entrega URLs/IPs.
- **Admin M365 de Grupo Q** — ejecuta las acciones del tenant. Rol requerido:
  **Global Admin**, **Cloud Application Admin** o **Application Admin**.
- **Usuario piloto** (buzón en el tenant de **Grupo Q**, no OSF) — para probar en vivo.

## Antes de la sesión (pre-requisitos)
- [ ] Buzón piloto en el tenant de **Grupo Q** (el PoC en OSF siempre queda
      bloqueado por política de OSF).
- [ ] Admin M365 de Grupo Q disponible con el rol correcto.
- [ ] Santiago con a mano: **Admin Consent URL** (Setup → Outlook Integration and
      Sync → "Give Users the Integration in Outlook") y la **lista de IPs**
      (asistente EAC → "See required IP addresses").
- [ ] Add-in "Salesforce" instalado en el Outlook del piloto (desde AppSource o
      despliegue central).

## Agenda (orden — ~40 min)
| # | Responsable | Acción | Verificación |
|---|-------------|--------|--------------|
| 1 | Santiago (5') | Confirmar **EAC en Microsoft Graph** (no EWS). Setup → Einstein Activity Capture → método de conexión; si está en EWS, hacer **upgrade a Graph** / el piloto **reconecta** su cuenta MS. | Método de conexión = Microsoft Graph |
| 2 | Admin M365 (10') | **Consentimiento del add-in (NAA):** abrir la Admin Consent URL (o Entra ID → Enterprise applications → Consent and permissions → permitir a la app Salesforce). | Abrir el add-in en Outlook del piloto → autentica **sin ventana en blanco**; muestra Compose/Related/Tasks |
| 3 | Admin M365 (10') | **Consentimiento org-wide de Microsoft Graph** para la app de **Salesforce / Einstein Activity Capture** (durante el flujo de conexión de EAC o en Entra ID). **+ Allowlist de IPs** de Salesforce si el firewall filtra. | Consent otorgado a nivel organización |
| 4 | Piloto + Santiago (10') | **Prueba EAC:** crear un evento en el calendario Outlook del piloto. | En minutos aparece en **Calendario de Salesforce** + **Activity Timeline**. En **Check User Health Status**: conexión **Active** vía Graph y versión de Exchange determinada (sin aviso EWS) |
| 5 | Todos (5') | Cierre: confirmar que **NO** se habilitó EWS. Registrar pendientes. | — |

## NO hacer
- ❌ **No habilitar EWS.** Microsoft lo desactiva por defecto el **1/oct/2026**;
  ir directo por Microsoft Graph. (Puente EWS solo si es imprescindible para una
  prueba puntual, coordinado con Santiago.)

## Después de la sesión
- [ ] **Distribución del add-in** al resto de usuarios: M365 admin center →
      Settings → **Integrated apps** (Centralized Deployment), o AppSource.
- [ ] Confirmar el **deadline Graph** ya cubierto (nada pendiente de migración,
      porque se configuró Graph de entrada).
- [ ] Alinear expectativa con el cliente: HU-027 = add-in en Outlook + sync de
      eventos (EAC). **No** es espejado total de buzones.

## Resultado esperado al cerrar
1. Add-in de Outlook autentica y muestra registros de Salesforce. ✅
2. Un evento creado en Outlook aparece en Salesforce (Calendar + Activity Timeline). ✅
3. Health Status **Active** vía **Microsoft Graph**. ✅
