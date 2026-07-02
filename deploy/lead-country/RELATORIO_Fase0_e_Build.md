# HU Lead.Country__c — Relatório de Fase 0 + Build (rastreabilidade §5)
**Org:** grupoq--devsales.sandbox.my.salesforce.com · **Data:** 2026-07-02 · **Branch:** claude/nifty-dijkstra-AcXrv

Problema: conversão de Lead falha com `REQUIRED_FIELD_MISSING` — "missing a field mapping for the Account.Country__c field". Solução: criar `Lead.Country__c`, mapear na conversão, e carimbá-lo automaticamente a partir da Sociedad.

---

## 1. Desvios da instrução × realidade da org (LER PRIMEIRO)

A Fase 0 (via Apex read-only) revelou 4 pontos onde a instrução **assumia** algo diferente do que a org tem. Os builds seguem a **realidade**, não os placeholders.

| # | Instrução assumia | Realidade confirmada na org | Ação |
|---|---|---|---|
| 1 | Campo de sociedade = `Lead.Sociedad__c` | **Não existe** `Sociedad__c` em Lead. É **`CompanyCode__c`** (label "Sociedad", picklist). | Flow/queries usam `CompanyCode__c`. |
| 2 | Evoluir o flow `Lead_BS_DeriveSociedad` (ativo) | Esse flow está **INATIVO** e referencia `$Record.Sociedad__c` (campo inexistente → não ativa). Nenhum flow de derivação ativo. | Por decisão do time: **não tocar** nele. Criado flow **novo** dedicado `Lead_BS_DeriveCountry`. |
| 3 | Picklist "PA Panama"; CMT 17 registros (C106-PROV, P103…) | Picklist tem **`PA Panamá`** (com acento). `Sociedad_Config__mdt` tem **12** registros (C101, C105, G101, H101, H105, N101, N105, P101, P105, S101, S105, S206) — sem os `-PROV`, com **P101** (não P103). | Clone byte-a-byte com acento; mapeamento sobre os 12 reais. |
| 4 | `Country_Name__c` = "Costa Rica" (talvez baste) | CMT tem `Country__c`="CR" **e** `Country_Name__c`="Costa Rica" — **nenhum** bate com o picklist "CR Costa Rica"; concatenar quebra em Panamá ("Panama"≠"Panamá"). | Adicionado campo **`Country_Picklist_Value__c`** (Text 40) ao CMT com o valor exato. |

---

## 2. Fase 0 — valores confirmados

**2.1 `Account.Country__c`** — picklist **RESTRICTED, local** (não GVS). Valores de API exatos (clone byte-a-byte):
```
CR Costa Rica
SV El Salvador
GT Guatemala
HN Honduras
NI Nicaragua
PA Panamá      <- COM ACENTO
```

**2.2 Flow de derivação:** `Lead_BS_DeriveSociedad` está **inativo/obsoleto** (referencia `Sociedad__c` inexistente). Não há flow before-save ativo que derive Sociedad para "evoluir". Before-save ativos: `Lead_BS_SetSLADeadline`, `Lead_BS_TransicionEstado`, `Lead_SetStatusOnConversion`. → **Criado flow novo** `Lead_BS_DeriveCountry` (não toca em nenhum existente).

**2.3 `Sociedad_Config__mdt`:** 12 registros. Campo de país usado: **`Country_Picklist_Value__c`** (novo, Text 40). De-para populado:

| DeveloperName (Sociedad) | Country_Picklist_Value__c |
|---|---|
| C101, C105 | `CR Costa Rica` |
| S101, S105, S206 | `SV El Salvador` |
| G101 | `GT Guatemala` |
| H101, H105 | `HN Honduras` |
| N101, N105 | `NI Nicaragua` |
| P101, P105 | `PA Panamá` |

**2.4 Map Lead Fields:** não recuperável por Apex → feito na **UI** (deploy de `LeadConvertSettings` por pacote sobrescreveria os mapeamentos existentes, que não temos).

**2.5 Backfill (contagem):** leads não convertidos com `CompanyCode__c` != null ≈ **2008**. Códigos reais na base: **C101 (2306), C105 (1), N101 (2)** — 100% resolvem no CMT (nenhum P103/órfão).

---

## 3. Artefatos entregues (na ordem de deploy)

1. **`Deploy_Lead_Country_Campos.zip`** — `Lead.Country__c` (picklist restricted, label "País", 6 valores exatos c/ acento) + `Sociedad_Config__mdt.Country_Picklist_Value__c` (Text 40). *(objects/ Traditional, API 65)*
2. **`Popular_CMT_Country.apex`** — popula os 12 registros via `Metadata.Operations` (seta só o campo novo; preserva MasterLabel e demais). Async → conferir em Setup > Deployment Status.
3. **`Deploy_Lead_Country_FLS.zip`** — permission set `Lead_Country_Access` (read/edit de `Lead.Country__c`). **Atribuir** aos perfis de Vendas + Integration User.
4. **`Deploy_Lead_BS_DeriveCountry.zip`** — flow before-save novo. Entry: `CompanyCode__c != null AND Country__c IsNull` → Get `Sociedad_Config__mdt` (DeveloperName = CompanyCode__c) → `Country__c = Country_Picklist_Value__c`. "Trust the source": não sobrescreve se já vier preenchido.
5. **Map Lead Fields (UI):** Object Manager > Lead > Fields > Map Lead Fields > Account: `País (Country__c)` → `Account.Country__c`.
6. **`Deploy_Lead_Country_Backfill.zip`** + **`Backfill_Executar.apex`** — Batch `LeadCountryBackfill` (allOrNone=false, Stateful, log `ok/erros/semMapaCMT`). Executar `Database.executeBatch(new LeadCountryBackfill(), 100)`.

> Não incluído (fora de escopo / decisão): não relaxamos o required do Account.Country__c; sem flow pós-conversão; sem tocar em BillingCountry/Address; sem campo espelho em Opportunity/Contact.

---

## 4. Testes de aceite (mapeados)

| # | Teste | Esperado |
|---|---|---|
| 1 | Lead `CompanyCode__c=C101`, sem país | `Country__c` = "CR Costa Rica" no save |
| 2 | Lead já com `Country__c` no payload | preservado (não sobrescreve) |
| 3 | Converter (Create New Account) | sem erro de mapping; `Account.Country__c` = valor do Lead; `BillingCountry` = país do Address (caminhos distintos) |
| 4 | Converter p/ Account EXISTENTE | valor da Account preservado (mapeamento não sobrescreve conta existente) — confirmar/registrar |
| 5 | Um lead por país | valor correto (P101/P105 → "PA Panamá" com acento) |
| 6 | Lead sem Sociedad | `Country__c` vazio; conversão segue bloqueada — guarda esperada |
| 7 | Backfill | contagem antes/depois; `erros=0`; `semMapaCMT=0`; sem pendência nova em Time-Based Automations |

---

## 5. Dívidas de governança (documentar)

- **Picklist local, não GVS** (Account.Country__c já existe e é obrigatório). Novo valor de país deve ser adicionado **nos DOIS campos** (`Lead.Country__c` e `Account.Country__c`) **e** no `Country_Picklist_Value__c` do CMT. (Registrado no help text de ambos os campos.)
- **Panamá:** picklist = `PA Panamá` (acento); `Country_Name__c` do CMT = `Panama` (sem). Por isso existe o `Country_Picklist_Value__c` (valor exato). Concatenar `Country__c`+`Country_Name__c` **não** serve.
- **P103:** `Brand_Sociedad_Map__mdt` usa `P103` para marcas de Panamá, mas `Sociedad_Config__mdt` tem `P101`. Nenhum lead real usa P103 hoje (0 ocorrências), mas se passar a existir, `Country_Picklist_Value__c` de um registro P103 precisa ser criado (o Batch conta esses como `semMapaCMT`).
- **Backfill:** update só toca `Country__c` (não Status) → `Lead_SLA_Escalation` (ajuste ativo) não reagenda; `Lead_TriggerOmniRouting` (doesRequireRecordChangedToMeetCriteria=true) não re-dispara em lead que já atendia critério. Rodar em janela de baixo tráfego mesmo assim.
- **Batch em produção:** deploy em sandbox não exige cobertura; para promover a classe a produção, adicionar test class (a CMT é visível em teste).
