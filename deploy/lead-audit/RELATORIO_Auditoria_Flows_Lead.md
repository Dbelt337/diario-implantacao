# Auditoria de Automação do Lead — GrupoQ DevSales
**Data:** 2026-07-03 · **Escopo:** 9 flows record-triggered ATIVOS de Lead · **Insumo:** retrieve `09SWK…` (13 solicitados; 9 ativos retornaram)

---

## (a) Inventário classificado

**9 ATIVOS auditados** (5 before-save + 4 after-save). **4 templates inativos** (`AddLeadtoCadence`, `RemoveOptOutLead`, `RemoveUQLead`, `ReferralNotification`) **não retornaram no retrieve** — consistentes com templates standard de Sales Engagement/Slack nunca ativados → **fora da auditoria de consumo, não deletar** (§2.2 ✅).

### 3 flows "fora do radar" — documentados (§2.3)
| Flow | Fase | Propósito (do XML) | Escreve no Lead |
|---|---|---|---|
| **Lead_Dup_Governance** | after-save/Create | Governança de duplicados: registra transferência e publica evento `LeadContactAttempt__e`; cria Task de log | `DuplicateLead__c`, `TransferDate__c`, `TransferredFromOnlineConsultant__c` |
| **GQ_Lead_Repuestos_...** | after-save/Create | Reasignación/cotización de leads de **Repuestos**: reatribui owner (fila) e marca candidato; cria Tasks de log | `OwnerId`, `UnifiedFromLeadId__c` |
| **Lead_BS_TransicionEstado** | before-save/Update | **Máquina de estados**: valida transições permitidas (Custom Errors) e grava efeitos colaterais | `ContactAttempts__c`, `DiscardReason__c` |

---

## (b) Checklist 3.1–3.8 por flow

| Flow | Fase | Entry condition | doesReqChanged | Get | DML sync | Loop c/ data | Anti-padrão | Bypass |
|---|---|---|---|---|---|---|---|---|
| Lead_BS_DeriveSociedad | **before** | CompanyCode∅ OR Country∅ | — | 2 | 0 (assign) | não | ok | n/a |
| Lead_BS_SetSLADeadline | **before** | **NENHUMA** 🚩 | — | 1 | 0 (assign) | não | ok | n/a |
| Lead_BS_TransicionEstado | **before** | IsConverted=false | — | 0 | 0 (assign) | não | ok | não tem |
| Lead_BS_ObligatoriedadMotos | **before** | Motos + ¬Conv + ¬Bypass | — | 2 | 0 | não | ok | **✅** |
| Lead_SetStatusOnConversion | **before** | IsConv=true + Status≠Convertido | true | 0 | **Update $Record (Status)** ⚠️ | não | before-save usando *Update Records* (devia ser Assignment) | n/a |
| Lead_Dup_Governance | **after**/Create | **NENHUMA** 🚩 | — | 2 | Upd$Record +1, Create Task +1, Event +1 | não | **after-save escreve $Record** 🚩 (3.1) | não |
| GQ_Lead_Repuestos | **after**/Create | **NENHUMA** 🚩 | — | 6 | Upd$Record ×2, Create Task ×3 | não | **after-save escreve $Record** 🚩 (3.1) | não |
| Lead_TriggerOmniRouting | **after**/C&U | Brand + ¬Conv + CompanyCode∈{C101,C105,N101,N105} + Industry∈{Repuestos,PA} | true | 1 (+subflow async) | Create Task (fault) | não | subflow **async** (não conta sync) | não |
| Lead_SLA_Escalation | **after**/C&U | Status=Nuevo | true | 8 | Upd$Record ×2, Create Task ×2 | não | **after-save escreve $Record** 🚩 + **scheduled (async)** | (grava; não é gate) |

**Nenhum flow tem loop** → o anti-padrão clássico do "Too many SOQL 101" (data element dentro de loop, §3.3) **NÃO existe em nenhum flow**. ✅

---

## (c) Matriz de consumo + veredicto (§4)

**Insight-chave:** os flows mais pesados (`SLA_Escalation` 8 Gets, `TriggerOmniRouting`+subflow de roteamento ~7 Gets) rodam em **scheduled path / async-after-commit** → **transação SEPARADA**, **não somam** na transação síncrona do save.

**Pior caso SÍNCRONO — 1 update de Lead:** só os before-save + after-save imediatos. `DeriveSociedad`(2) + `SetSLADeadline`(1) + `ObligatoriedadMotos`(2) + `TransicionEstado`(0) = **~5 SOQL, 0 DML síncrono** (before-save é assignment, sem DML). → **FOLGADO (<10% de 100 SOQL / 150 DML).**

**Pior caso na CRIAÇÃO:** + after-save `Dup_Governance`(2 Get, 1 Upd, 1 Task, 1 Event) + `GQ_Repuestos`(6 Get, 2 Upd, 3 Task) ≈ **~13 SOQL, ~8 DML** — ainda **FOLGADO**, mas ver recursão abaixo.

**Cenário recursão (§4.3):** `Dup_Governance` e `GQ_Repuestos` fazem **Update no próprio Lead em after-save/Create** → esse update **re-dispara** os flows de contexto Update (uma 2ª passada). Como nenhum dos dois tem entry condition nem `doesRequireRecordChangedToMeetCriteria`, o custo **dobra** na criação. Mesmo dobrado (~26 SOQL/16 DML) segue **FOLGADO**, mas é **desperdício e risco de crescimento**: a US-006a adiciona flows em Account que rodam na **mesma transação** quando a conversão cria Account.

**Bulk 200 (§4.2):** sem loops, tudo bulkifica entre interviews → 1 operação por elemento. Sem estouro projetado. ✅

**Veredicto por cenário:** update **FOLGADO** · criação **FOLGADO (com recursão a limpar)** · bulk **FOLGADO**.

---

## (d) Colisão de campos + máquina de estados (§5)

### Campos do Lead escritos por 2+ flows 🚩
| Campo | Flows | Observação |
|---|---|---|
| **OwnerId** | GQ_Repuestos (create) · SLA_Escalation (scheduled) | dois reatribuem; gatilhos distintos, mas **ordem importa** se coincidirem |
| **TransferDate__c** | Dup_Governance · SLA_Escalation | ambos "registram transferência" |
| **TransferredFromOnlineConsultant__c** | Dup_Governance · SLA_Escalation | idem |

### Máquina de estados do Status (§5.2 — maior risco silencioso)
- **Lead_BS_TransicionEstado** (before, IsConv=false): **valida** transições permitidas (Custom Errors) + grava `ContactAttempts__c`/`DiscardReason__c`. Não escreve Status.
- **Lead_SetStatusOnConversion** (before, IsConv=true): **escreve** `Status='Convertido'`.
- **Lead_BS_ObligatoriedadMotos** (before, Motos + ¬Conv): **gatekeeper** do avanço a "En contacto".

**Parecer:** `TransicionEstado` (IsConv=false) e `SetStatusOnConversion` (IsConv=true) têm entries **mutuamente exclusivas** → **nunca coexistem** na mesma transação; a ordem entre eles é irrelevante. O conflito real de ordem é `TransicionEstado` × `ObligatoriedadMotos` (ambos rodam num avanço de lead Motos não-convertido): hoje, **ordem alfabética** → `ObligatoriedadMotos` roda **antes** de `TransicionEstado` (O < T), ou seja, o gate de moto/sucursal dispara antes da validação de transição. Com o **TriggerOrder proposto** invertemos para o **contrato lógico** (valida transição → depois exige dados). Sem TriggerOrder, isso é **acidente alfabético**.

---

## (e) Divergência `Lead_TriggerOmniRouting` (§2.5) — RESOLVIDA com evidência

- **Registro do projeto:** "desativado, pendente fix Omni×SBR".
- **Evidência da org (XML retrieve):** **`<status>Active</status>`** + entry **modificada** (agora inclui `CompanyCode ∈ {C101,C105,N101,N105}` e `Industry ∈ {Repuestos,PA}` — antes era só C101/C105).
- **Veredicto:** vale a **org — está ATIVO e foi evoluído**. O registro do projeto está **desatualizado**. ⚠️ O fix do conflito **Omni-Channel Flow × Skills-Based Routing** **não é verificável só por este flow** (ele só invoca o subflow `LeadRouting_OmniFlow` via `routeWork`); depende da **Routing Configuration** da fila — auditar à parte (fora do escopo destes 9 flows).

---

## (f) TriggerOrder aplicado (§7.1) — tabela final

| Ordem | Before-save | | Ordem | After-save |
|---|---|---|---|---|
| **10** | Lead_BS_DeriveSociedad | | **10** | Lead_Dup_Governance |
| **20** | Lead_BS_SetSLADeadline | | **20** | GQ_Lead_Repuestos |
| **30** | Lead_SetStatusOnConversion | | **30** | Lead_TriggerOmniRouting |
| **40** | Lead_BS_TransicionEstado | | **40** | Lead_SLA_Escalation |
| **50** | Lead_BS_ObligatoriedadMotos | | | |

**Justificativas:** DeriveSociedad 1º (outros dependem de `CompanyCode`/`Country`). SetStatusOnConversion e TransicionEstado nunca coexistem (entries opostas) → posições 30/40 sem conflito. TransicionEstado (40) **antes** de ObligatoriedadMotos (50) = valida transição → depois exige dados (inverte o acidente alfabético). After-save: dedup → repuestos-reassign → routing → SLA (dependências de owner/dados na ordem natural).
**Pacote:** `Deploy_Lead_TriggerOrder.zip` (9 flows, nova versão, só `<triggerOrder>` adicionado — zero mudança de lógica). **Não altera comportamento** — só troca acidente alfabético por contrato.

---

## (g) Fixes de anti-padrão — PROPOSTOS (não incluídos no pacote TriggerOrder)

1. **`GQ_Repuestos` e `Dup_Governance` — after-save escrevendo `$Record` sem entry condition + recursão.** Fix: adicionar **entry conditions estreitas** (só disparar quando fizer sentido) e mover a **escrita dos campos do Lead para um before-save** (a parte de Task/PlatformEvent fica em after-save — não pode ir pra before). ⚠️ Toca lógica → **janela própria com testes** (§7.2), não misturar com TriggerOrder.
2. **`Lead_BS_SetSLADeadline` — sem entry condition** (roda em todo save, reescreve `SLADeadline__c`/`LastGestionDate__c` sempre). Fix: entry condition estreita (ex.: só quando `Status` muda / em Nuevo). Baixo risco.
3. **`Lead_SetStatusOnConversion` — before-save usando *Update Records* em `$Record`** (deveria ser **Assignment**/Fast Field Update). Baixo risco, ganho de performance.
4. **Bypass transversal:** só `ObligatoriedadMotos` usa `Bypass_Gates_Automacao`. Avaliar aplicá-lo aos que também são gate/reação de integração (`TransicionEstado`).

---

## (h) Fica para janela própria (§10 não-escopo)
- **Renames** para o padrão `Objeto_BS_/AS_Proposito` (`GQ_Lead_...`, `Lead_Dup_Governance`, `Lead_SLA_Escalation` sem sufixo de fase) — rename = novo API name = risco.
- **Consolidação** ("1 flow por objeto") — decisão de arquitetura pós-relatório.
- **Fixes de anti-padrão** do item (g) 1–2 (tocam lógica).
- **Auditoria Omni×SBR** (Routing Configuration da fila).

---

## Próximo passo recomendado
1. **Deploy `Deploy_Lead_TriggerOrder.zip`** (Check Only antes; nova versão dos 9, desativar anteriores). **Seguro** — só ordem.
2. **Regressão (§8):** reexecutar criação / avanço Nuevo→En contacto (Motos c/ LLI) / conversão + os aceites da semana (SLA, T1–T7). Resultado **idêntico** ao pré-deploy = ordem formalizada sem mudança de comportamento.
3. **Medição empírica (§6):** debug log Workflow=FINER nos 3 cenários → comparar `LIMIT_USAGE_FOR_NS` com a matriz (c). *(pendente — precisa rodar na org)*
