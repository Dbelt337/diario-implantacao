# HU-010 — Manifesto Final de Deploy + Plano de Teste
> 2026-07-07 · SLA de primeiro contato, escada de escalação, temperatura, priorização e sticky-agent no Lead.
> 100% declarativo (zero Apex). Org: Enhanced Omni-Channel + skills-based routing.

## 1. O que subir (3 pacotes, nesta ordem)

### Passo 1 — `Deploy_HU010_Step1_Campos_FLS.zip` (Check Only + Rollback on Error)
- CustomField `Lead.FechaPrimerContacto__c` (DateTime) — único campo armazenado novo.
- CustomField `Lead.CumplioSLA__c` (**Fórmula** checkbox) = `AND(NOT(ISBLANK(FechaPrimerContacto__c)), NOT(ISBLANK(SLADeadline__c)), FechaPrimerContacto__c <= SLADeadline__c)`.
- PermissionSet `HU010_Campos_SLA_Lead` (FLS dos 2 campos; CumplioSLA read-only).

### Passo 2 — `Deploy_HU010_Step2_Flows.zip` (depois do Passo 1)
- `Lead_SLA_Escalation` — escada evoluída (recordatório -15 / supervisor no vencimento / reasignación +10 se sem gestión).
- `Lead_AT_PrimerContacto` — grava `FechaPrimerContacto__c` na 1ª Task completada vinculada ao Lead.
- `Lead_Score_Temperatura` — grava `Rating` a partir do Einstein Score/sinais.
- Sobem **Draft** → ativar na tela.

### Passo 3 — `deploy/hu010-priority-omni/` (priorización na Route Work action)
- **Correção de arquitetura.** A abordagem anterior (`Lead_PSR_SecondaryPriority`, record-triggered *after-save* no PSR) **não funciona**: o PSR trava em `IsReadyForRouting=true` e recusa `update`, e no roteamento por fila o objeto *"doesn't invoke triggers"* (Object Reference). O `RoutingPriority` só é honrado **na criação do PSR** e **apenas em skills-based**.
- **A Route Work action NÃO tem input de prioridade numérica** (confirmado no builder + Check Only: só `Work Item Request Date`, `Acceptance Due Date`, `Screen Pop`). Portanto usamos **`Acceptance Due Date` → `TargetAcceptDateTime`**, que a doc do objeto define como o lever de priorização por Flow: *"influences backlog ordering by prioritizing work items with earlier target acceptance deadlines"* (v65+).
- **Solução:** `LeadRouting_OmniFlow` (V9 Active) usa a fórmula DateTime `fAcceptBy = CurrentDateTime + (Hot 15m / Warm 60m / Cold 240m / default 480m)` no campo **Acceptance Due Date → Accept By Variable** da ação skills-based `Rotear_Lead_Queue`. Prazo mais cedo = roteado antes. Zero Apex.
- **Input real (via retrieve): `acceptBy`** → `<elementReference>fAcceptBy</elementReference>` na ação `Rotear_Lead_Queue`. (Os chutes `routingPriority` e `targetAcceptDateTime` foram rejeitados; o correto é `acceptBy`.) O flow no repo é a **V11 ativada da org**, já com o wiring — reproduzível pra prod direto.
- **Retirar `Lead_PSR_SecondaryPriority`**: passo manual no Setup → **Desativar** (delete opcional; delete de flow ativo dá "insufficient access rights"). Fora deste zip para o deploy sair verde.

## 2. Config pós-deploy (por ambiente)
- [ ] **Atribuir** o PS `HU010_Campos_SLA_Lead` aos usuários (senão os campos ficam invisíveis).
- [ ] **Ativar os 3 flows**: `Lead_SLA_Escalation`, `Lead_AT_PrimerContacto`, `Lead_Score_Temperatura`. (A priorización agora vive dentro do `LeadRouting_OmniFlow`, já ativo — basta subir a nova versão e ativá-la.)
- [ ] **Desativar** `Lead_PSR_SecondaryPriority` (substituído; será deletado pelo destructiveChanges).
- [ ] **Record Type**: garantir que o valor de `Rating` funciona (é standard).
- [ ] **NÃO precisa** configurar "Secondary Routing Priority" no Service Channel — a prioridade vai por `routingPriority` na Route Work action (skills-based).
- [ ] **US-031**: confirmar com o dono que a reasignación passou de 0 para +10 min (mudança intencional no `Lead_SLA_Escalation`).

## 3. Dependências pré-existentes (têm que existir no destino)
`Lead_BS_SetSLADeadline`, `Lead_TriggerOmniRouting`, `LeadRouting_OmniFlow` (contém o sticky-agent nativo), ServiceChannel `Lead_Channel`, QueueRoutingConfig `Lead_Routing_Config`, filas (`Leads_CR_Offline`…), Skills/ServiceResource/Presence, CMT `Lead_SLA_Config__mdt` (+ registros), `CustomNotificationType` `Lead_SLA_Alert`, Profile `Gerente de Ventas / Gerente de Marca`, campos `SLADeadline__c`, `LastReminderDate__c`, `SLAReassignCount__c`, `ReassignReason__c`, `TransferDate__c`, `Rating`, `ScoreIntelligenceId`, `Status` (ES).

---

## 4. PLANO DE TESTE

### T1 — Primeiro contato (B1: `Lead_AT_PrimerContacto`)
1. Crie um Lead com `Status = Nuevo`.
2. Crie uma **Task vinculada ao Lead** (WhoId = o Lead) e marque **Status = Completed**.
3. Verifique no Lead:
```sql
SELECT Id, FechaPrimerContacto__c, CumplioSLA__c, SLADeadline__c FROM Lead WHERE Id='<lead>'
```
- `FechaPrimerContacto__c` = carimbado com a data/hora.
- `CumplioSLA__c` = true se dentro do `SLADeadline__c`, false se fora (fórmula, automática).

### T2 — Escada de SLA (B2: `Lead_SLA_Escalation`)
Pré: baixe `SLAMinutes__c` do CMT `Default_Bandeja` para **2** (restaure 60 depois).
1. Crie um Lead `Status = Nuevo` (o `SetSLADeadline` carimba deadline = agora + 2 min).
2. Observe:
   - **No vencimento (~+2 min):** o **supervisor** (gerente do dono) recebe notificação no sino.
   - **+10 min:** se `Status=Nuevo` e `FechaPrimerContacto__c` vazio → **reasigna** para `Leads_CR_Offline`, `Rating=Hot`, `SLAReassignCount__c=1`.
3. **Gate de gestión:** repita, mas preencha `FechaPrimerContacto__c` antes do +10 (ou complete uma Task) → **NÃO deve reasignar**.
4. **Atendido:** mude `Status` para `Asignado`/`En contacto` antes → nenhum path age.
Query:
```sql
SELECT Id, Status, SLADeadline__c, FechaPrimerContacto__c, OwnerId, Rating, SLAReassignCount__c, LastReminderDate__c FROM Lead WHERE Id='<lead>'
```
Falhas: consulte Tasks "Falha em Lead_SLA_Escalation (HU-010)" ou Setup → Paused And Failed Flow Interviews.

### T3 — Temperatura (B3: `Lead_Score_Temperatura`)
1. Com Einstein Lead Scoring ativo, crie/edite um Lead que gere score alto (ou ajuste os sinais).
2. Verifique `Rating` (Hot/Warm/Cold) gravado:
```sql
SELECT Id, Rating, ScoreIntelligenceId FROM Lead WHERE Id='<lead>'
```

### T4 — Priorización (`LeadRouting_OmniFlow` / Route Work skills-based)
Pré: precisa de **backlog** (itens esperando na fila, sem agente pegando na hora) **e** roteamento **skills-based** (`RoutingPriority` só é considerado em skills-based; queue-based usa a Priority da Routing Configuration).
1. Deixe agentes offline (ou sem capacidade) para segurar os itens na fila.
2. Roteie 2 leads com `Rating` já preenchido: um `Hot`, um `Cold`.
3. Confira **enquanto ainda está na fila** (o PSR é transiente e some quando aceito):
```sql
SELECT Id, WorkItemId, RoutingType, TargetAcceptDateTime FROM PendingServiceRouting ORDER BY CreatedDate DESC
```
- `RoutingType = SkillsBased`; Lead Hot com `TargetAcceptDateTime` **mais cedo** que o Cold (≈ agora+15m vs agora+240m).
4. Traga um agente online → o **caliente (prazo mais cedo) deve ser roteado antes** do cold.
> A priorização vem do **prazo de aceitação** (mais cedo = mais prioritário), gravado na criação do PSR pela Route Work action. Se os prazos vierem iguais/vazios: (a) confirme `RoutingType=SkillsBased`, (b) confirme que a nova versão do `LeadRouting_OmniFlow` está ativa e que o `Rating` está preenchido, (c) veja `Update_Lead_Error` no Lead ou Setup → Paused And Failed Flow Interviews.

> ⚠️ **Pré-condição de roteamento:** o `Lead_TriggerOmniRouting` só entra no Omni com `Brand__c` (Marca) **E** `CompanyCode__c` preenchidos. Sem Marca → não roteia → nenhum PSR (não é bug de priorización).

**✅ VALIDADO (2026-07-08, sandbox DevSales):** 2 leads skills-based —
Hot (Costa): `CreatedDate 00:52:18 → TargetAcceptDateTime 01:07:18` (**+15 min**);
Cold (Moraes): `00:51:58 → 04:51:57` (**+240 min**). Hot com prazo mais cedo → priorizado. `RoutingType=SkillsBased` nos dois.

---

## 5. Estado final da HU-010
| Requisito | Solução | Tipo |
|---|---|---|
| SLA primeiro contato + data/hora | `SLADeadline__c` (existente) + escada | declarativo |
| Escada (recordatório/supervisor/reasignación 10min) | `Lead_SLA_Escalation` evoluído | declarativo |
| "Gestión" válida | Task completada → `FechaPrimerContacto__c` | declarativo |
| Cumpriu SLA | `CumplioSLA__c` (fórmula) | declarativo |
| Temperatura frío/tibio/caliente | `Rating` nativo (via B3 + Einstein) | declarativo |
| Priorización calientes / SLA vencido | `TargetAcceptDateTime` (Acceptance Due Date) na Route Work action do `LeadRouting_OmniFlow` (skills-based), derivado do `Rating` | declarativo |
| Sticky-agent por presença | `LeadRouting_OmniFlow` (nativo, já existia) | nativo |

**Campos novos criados: 1 (`FechaPrimerContacto__c`) + 1 fórmula (`CumplioSLA__c`). Zero Apex.**
