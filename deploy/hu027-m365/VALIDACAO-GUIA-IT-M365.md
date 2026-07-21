# HU-027 — Validação do Guia IT (Integração M365 ↔ Salesforce)

Valida o `HU-027_H3_Guia_IT_Integracion_M365` (Santiago) contra a documentação
oficial (Microsoft Learn + Salesforce Help). Data: 2026-07-21.

## Veredito: guia CORRETO e bem estruturado
Separa certo as **duas integrações** e as datas conferem. Só há **1 melhoria
estratégica** (ordem das ações — ver §3).

## 1. As duas integrações (confirmado)
- **Outlook Integration (add-in):** ver registros SF no Outlook + logar manualmente
  e-mails/eventos. **NÃO sincroniza calendário.** ✅
- **Einstein Activity Capture (EAC):** sincronização automática de eventos/e-mails.
  É o EAC que faz o sync — o add-in não. ✅

## 2. Fatos oficiais confirmados
- **EWS (Exchange Online) — aposentadoria:** a partir de **1 out 2026** o EWS fica
  **desabilitado por padrão** (EWSEnabled=False) nos tenants que **não** tiverem
  optado por mantê-lo (Allow List + EWSEnabled=True **até fim de agosto 2026**).
  Desligamento faseado a partir de out/2026, **retirada total em abril 2027**. Só
  afeta Exchange Online (on-prem continua). [Microsoft Learn]
- **EAC → Microsoft Graph:** Salesforce recomenda concluir a migração para
  **Microsoft Graph até agosto 2026**. **Agosto/2026 = Graph passa a ser o ÚNICO
  método de autenticação suportado** para EAC no M365. [Salesforce Help]
- **Spring '26:** EAC configurado para M365 **passa a usar Microsoft Graph
  automaticamente** em novas conexões. Orgs configuradas antes do Spring '26 podem
  precisar do upgrade manual (ferramenta 1-clique). Após o upgrade, usuários
  user-level recebem banner pra reconectar; o sync segue por EWS até cada um
  reconectar, mas **novas conexões já usam Graph**. [Salesforce Help]
- **Requisito do admin M365 pra Graph:** consentimento org-wide da Graph API; o
  admin que configura precisa de DirectoryRole **Global Admin, Cloud Application
  Admin ou Application Admin**. [Salesforce Help]

Ou seja, as datas do guia (EWS 01/out/2026, migrar antes de ago/2026) estão certas.

## 3. MELHORIA ESTRATÉGICA — ir de Graph-first, não habilitar EWS
O guia coloca "habilitar EWS" como ação primária (#2) e a migração pro Graph como
ação futura (#5). **Recomendo inverter:**

> **Não investir em habilitar o EWS agora.** Estamos em jul/2026 — o EWS é
> desabilitado por padrão em **~2 meses** (01/out/2026). Habilitar EWS agora =
> ligar um serviço que morre em semanas **e** forçar uma re-migração logo depois.
> Como o GrupoQ está configurando o EAC **novo** (pós-Spring '26), a conexão deve
> ir **direto pro Microsoft Graph**.

O sintoma "Can't determine Exchange version / EWS restringido" é exatamente uma
conexão tentando **EWS** num tenant onde o EWS está bloqueado. A solução certa não
é desbloquear o EWS — é **conectar o EAC por Graph** (reconectar o usuário piloto
via Graph; se a config for anterior ao Spring '26, rodar o upgrade 1-clique).

## 4. Lista de ações IT — REFINADA (Graph-first)
| # | Ação | Onde | Para quê |
|---|------|------|----------|
| 1 | **Admin consent do add-in** (NAA) — ou permitir user consent | Entra ID / Admin Consent URL (Setup → Outlook Integration and Sync) | Desbloqueia o **Outlook add-in** (tela de Sign Up em branco) |
| 2 | **Conectar/atualizar o EAC via Microsoft Graph** (não EWS) + **admin consent org-wide da Graph API** da app Salesforce/EAC | Entra ID (admin = Global/Cloud App/Application Admin) | Sync de calendário/e-mail **à prova de futuro** (sem EWS) |
| 3 | **Allowlist de IPs do Salesforce** (se houver filtro por IP) | Rede / firewall / tenant | Permite o acesso do EAC (ver "required IP addresses" no assistente EAC) |
| 4 | Distribuição centralizada do add-in (opcional) | M365 admin center → Integrated apps | Deploy do add-in a todos |
| ~~x~~ | ~~Habilitar EWS nos buzones~~ | — | **Evitar** — EWS morre 01/out/2026; ir direto pro Graph |

## 5. Pequenos ajustes ao doc do Santiago
- Reordenar: Graph-first como ação primária do EAC; "habilitar EWS" só como
  **bridge temporário** se precisarem do sync funcionando ainda esta semana pro
  teste (e mesmo assim, com o Graph já no roadmap imediato).
- Deixar explícito o **role exigido do admin M365** pro consent do Graph
  (Global/Cloud App/Application Admin).
- Nota: o consent do **add-in (NAA)** e o consent do **EAC (Graph)** são **apps/
  permissões diferentes** — os dois precisam de admin M365, mas são passos
  separados (o guia já separa, só reforçar).

## Fontes
- Microsoft Learn — Deprecation of EWS in Exchange Online.
- Salesforce Help — Connect EAC to Microsoft 365 (User-Level) / Upgrade to Microsoft Graph.
- Salesforce Help — Troubleshoot EAC Email and Calendar Sync.
