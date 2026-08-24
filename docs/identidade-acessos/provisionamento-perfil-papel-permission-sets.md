# Provisionamento sincronizado de Perfil, Papel e Permission Sets — one-pager para decisão

**Data:** 24/08/2026
**Contexto:** thread Samuel Vitor / Victor Luiz / Priscila De Lima — Okta hoje não preenche perfil, papel e permission sets na criação de usuários no Salesforce; o ajuste manual gera erros de processo. Pergunta do Victor: "é possível fazer isso via API?"
**Resposta curta:** sim — e não precisa construir API do zero. O Salesforce já expõe isso nativamente (SCIM 2.0) e tem automação declarativa interna (User Access Policies). O conector Salesforce do Okta já sabe consumir esses recursos.

---

## As 4 opções (todas confirmadas em documentação oficial)

### Opção 1 — SCIM API nativa do Salesforce (`/services/scim/v2`)

A "API para ajustar perfil, papel e permission sets" **já existe publicada pelo Salesforce**, em **todas as edições** (doc oficial: *Manage Salesforce User Identities with SCIM* + *SCIM and REST API Reference Sheet*).

- **Perfil e Permission Sets** são modelados como **Entitlements** (`type: "Profile"` / `type: "Permission Set"`). Atribuir permission set = `PATCH /services/scim/v2/Users/<id>` com operação `add` no array `entitlements`. Trocar perfil = `replace` no entitlement de tipo Profile.
- **Papel** = `PATCH` com `replace` no array `roles` (consultar `/Roles` antes para obter o ID).
- **Grupos públicos** = endpoint `/Groups` (GET/PATCH).
- Autenticação: OAuth 2.0 (integration user + External Client App com JWT Bearer).
- Atenção: o endpoint `/Entitlements` retorna no máximo 200 registros em consulta aberta — consultar entitlements específicos quando a org tiver mais.

**Exemplo oficial (adicionar permission set):**

```json
PATCH /services/scim/v2/Users/<UserId>
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
  "Operations": [
    { "op": "add",
      "value": { "entitlements": [ { "value": "<permission_set_id>" } ] } }
  ]
}
```

### Opção 2 — User Access Policies (nativo, declarativo, zero código)

Funcionalidade padrão do Setup (GA Summer '24), **Enterprise/Unlimited**. Políticas que disparam **quando o usuário é criado e/ou atualizado** e concedem/revogam automaticamente: **permission sets, permission set groups, permission set licenses, licenças de pacote, grupos públicos e filas**.

- Critérios: até **3 filtros de acesso** (Perfil, Papel, PS/PSG, licença de pacote, grupo/fila) + até **10 campos adicionais** do User (padrão ou custom). Operadores `equals`/`in`; **sem filter logic** — tudo é AND.
- Até **200 políticas ativas**; havendo sobreposição, aplica-se a de menor `Order`.
- **Não define perfil nem papel** (reage a eles). Perfil/papel precisam chegar prontos do provisionamento (Opções 1/3).
- Considerações importantes (doc *User Access Policy Considerations*):
  - Uma política **não encadeia** outra (ação de UAP não dispara UAP).
  - Política ativa só pega usuário existente **quando o registro é atualizado** e passa a casar com o critério — para o estoque atual, usar o modo manual **Apply Policy** (aplica a todos que casam, tipo "migração").
  - Critério por grupo público/fila só enxerga membros diretos (não via role/território/grupo aninhado).
  - Mudanças em massa de grupos públicos podem disparar recálculo de sharing — considerar *Defer Sharing Calculations* em aplicações grandes.
  - Auditoria embutida: aba *Recent User Access Changes* por política (mostra só mudanças ainda vigentes).

### Opção 3 — Conector Salesforce do Okta (provisionamento "To App")

O app Salesforce do Okta suporta, na atribuição do app, definir **Profile, Role, Federation ID e Permission Sets** por usuário/grupo. A versão atual usa **OAuth + REST** (padrão para orgs novas).

**Pré-requisitos que costumam ser a causa do "Okta não entrega" (doc *Enable Salesforce provisioning*):**
1. Integration user com **perfil custom** contendo `API Enabled` + `Manage Users` — e as permissões devem estar **diretamente no perfil, não via permission set** (exigência explícita do Okta).
2. API integration habilitada na aba Provisioning com Consumer Key/Secret do External Client App e credenciais testadas.
3. Mapeamento dos atributos "To App" configurado (é aí que perfil/papel/PS são enviados).

Ou seja: antes de qualquer construção, vale um **health-check da configuração atual do app** — há boa chance de o gap ser configuração, não capacidade.

### Opção 4 — JIT provisioning via SAML (complementar)

Criação/atualização do usuário no primeiro login SSO, com atributos na assertion. Handler padrão gerenciado pelo Salesforce, ou custom via Apex (`Auth.SamlJitHandler`) para lógica própria (ex.: permission sets). Disponível em todas as edições.
- Limitação relevante: só roda **no login** (não serve para ajustes em massa nem revogação).
- Desde Spring '24, usuário criado por JIT nasce com e-mail **não verificado** e não envia e-mails do Salesforce até verificação manual.

---

## Comparativo

| | Cobre Perfil/Papel | Cobre PS/PSG | Esforço | Quem mantém | Auditoria |
|---|---|---|---|---|---|
| **1. SCIM nativa** | Sim | Sim (PS; PSG não exposto) | Médio (cliente SCIM/middleware) | Integrações | SetupAuditTrail |
| **2. User Access Policies** | Não | Sim (PS, PSG, licenças, grupos, filas) | Baixo (declarativo) | Admin Salesforce | Nativa por política |
| **3. Conector Okta** | Sim | Sim (PS na atribuição do app) | Baixo (configuração) | Time IAM/Okta | Logs Okta + SetupAuditTrail |
| **4. JIT SAML** | Sim (assertion) | Só com handler Apex custom | Médio/Alto | Dev Salesforce | Limitada |

## Arquitetura recomendada

1. **Perfil + Papel + Federation ID** → responsabilidade do **provisionamento Okta** (Opção 3, que usa a API da Opção 1 por baixo). Pré-condição: health-check do app (integration user, OAuth, atributos "To App").
2. **Permission Set Groups por persona** → responsabilidade de **User Access Policies** dentro do Salesforce (Opção 2). O Okta não precisa conhecer a matriz de permissões; o Salesforce se autocompleta de forma determinística e auditável. Modelar **1 PSG por persona** para eliminar o erro "faltou um set".
3. **Estoque atual** (usuários já criados errados) → rodada única de **Apply Policy** manual das UAPs + correção de perfil/papel via SCIM/Data Loader.
4. API/middleware custom **só se** a origem da verdade do de-para (função → acessos) morar fora do Salesforce/Okta (ex.: RH).

## Pré-requisito de qualquer caminho

**Matriz de personas validada**: função → perfil + papel + PSGs. Sem ela, qualquer automação só padroniza a bagunça. Com ela, a implantação das UAPs é de horas, não semanas.

## Pauta sugerida para a agenda (Samuel, Victor, Priscila, Matheus, Anderson)

1. Health-check do app Salesforce no Okta (permissões do integration user, OAuth REST, mapeamento "To App") — responsável IAM.
2. Validação da matriz de personas com o negócio — responsável Salesforce/BKO.
3. Decisão: conector Okta para perfil/papel + UAP para PSGs (recomendado) vs. middleware SCIM próprio.
4. Definição do fluxo de mudança de função (update do usuário → UAP "on update" reatribui acessos) e de desligamento (revoke).
5. Piloto com 1–2 personas em sandbox antes de ativar em produção (UAP deployável via Metadata API — `UserAccessPolicy`).

## Fontes

- Manage Salesforce User Identities with SCIM — help.salesforce.com (`identity_scim_overview`)
- SCIM and REST API Reference Sheet — help.salesforce.com (`identity_scim_rest_api`)
- Examples: Update Users with SCIM — help.salesforce.com (`identity_scim_update_users`)
- User Access Policy Considerations — help.salesforce.com (`perm_user_access_policy_considerations`)
- Enable Salesforce provisioning — help.okta.com (`sfdc-enable-provisioning`)
- Just-in-Time Provisioning for SAML — help.salesforce.com (`sso_jit_about`)
- Salesforce User Access Policies: The Complete Guide — Salesforce Ben (jan/2025)
