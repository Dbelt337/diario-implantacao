# HU-027 — Plano para destravar a integração M365 ↔ Salesforce

O "bloqueio" é do **tenant M365**, não do Salesforce. Só o **admin M365 do
Grupo Q** executa as ações de tenant. O time Salesforce (Santiago) prepara o lado
SF em **Graph-first** e entrega o hand-off ao admin. NÃO validar em produção no
tenant OSF (osf.digital) — política da OSF bloqueia; usar buzón piloto do Grupo Q.

## Parte A — Santiago (lado Salesforce, verificar/ajustar)
1. **EAC em Microsoft Graph (não EWS).** Setup → **Einstein Activity Capture** →
   Settings/Configurations → conferir o método de conexão. Se estiver em EWS
   (sintoma "Can't determine Exchange version"), fazer o **upgrade para Microsoft
   Graph** (ou o usuário piloto **reconecta** a conta Microsoft pelo banner). Novas
   conexões pós-Spring '26 já default para Graph.
2. **Pegar a Admin Consent URL do add-in.** Setup → **Outlook Integration and
   Sync** → "Give Users the Integration in Outlook" → copiar
   **"Admin Consent URL (For Your Office 365 Admin)"** → entregar ao admin M365.
3. **IPs do EAC.** No assistente do EAC, abrir **"See required IP addresses"** e
   passar a lista ao admin (pro allowlist, se houver filtro por IP).
4. **Buzón piloto no tenant do Grupo Q** (não OSF) pro teste real.

## Parte B — Hand-off pro admin M365 do Grupo Q (paste-ready, ES)
Ver bloco em espanhol abaixo (§Hand-off).

## Parte C — Verificação (depois que o admin executar)
- **Add-in:** abrir no Outlook → o painel Salesforce autentica sem tela em branco
  e mostra Compose / Related / Tasks.
- **EAC:** criar um evento no calendário do usuário piloto → em minutos aparece no
  **Calendario de Salesforce** e no **Activity Timeline**. Em **Check User Health
  Status**, a versão do Exchange é determinada e a conexão fica **Active** via
  Graph (sem aviso de EWS).

## Escopo da HU (do que o Santiago apontou)
A HU-027 **não** oferece sincronização total — apenas o **add-in do Salesforce no
Outlook** + o sync de eventos via EAC. Alinhar expectativa: não é espelhamento
completo de caixas.

---

## Hand-off (ES) — Acciones para el administrador de Microsoft 365 de Grupo Q

Objetivo: desbloquear la integración Microsoft 365 ↔ Salesforce (HU-027). El lado
Salesforce ya está configurado. Estas acciones son solo del tenant M365 de
Grupo Q. **No habilitar EWS** — Microsoft lo desactiva por defecto el 1/oct/2026;
vamos directo por **Microsoft Graph**.

Requisito: ejecutar con un usuario **admin M365 de Grupo Q** con rol
**Global Administrator**, **Cloud Application Administrator** o
**Application Administrator**. Usar un buzón piloto del tenant de Grupo Q.

1) **Consentimiento del add-in de Outlook (Nested App Authentication).**
   Abrir la **Admin Consent URL** que entrega el equipo Salesforce (o en
   **Entra ID → Enterprise applications → Consent and permissions**, permitir el
   consentimiento a la app de Salesforce). Resultado esperado: al abrir el add-in
   en Outlook, ya no queda la ventana en blanco.

2) **Consentimiento org-wide de Microsoft Graph para Einstein Activity Capture.**
   Otorgar el consentimiento de administrador (org-wide) a la aplicación
   empresarial de **Salesforce / Einstein Activity Capture** con los permisos de
   **Microsoft Graph** (durante el flujo de conexión de EAC o desde Entra ID →
   Enterprise applications). Esto reemplaza a EWS y es a prueba de futuro.

3) **Allowlist de IPs de Salesforce (si el tenant/firewall filtra por IP).**
   Agregar los rangos de IP de Salesforce (la lista "required IP addresses" que
   pasa el equipo Salesforce) para permitir el acceso de EAC.

4) **NO habilitar EWS.** Si por algún motivo se necesita un puente temporal para
   pruebas esta semana, coordinar con el equipo Salesforce; el objetivo final es
   Microsoft Graph.

Verificación tras el consentimiento: el add-in autentica sin quedar en blanco; y
un evento creado en el calendario del usuario piloto aparece en pocos minutos en
el Calendario de Salesforce y en el Activity Timeline.
