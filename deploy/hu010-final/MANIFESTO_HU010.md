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

### Passo 3 — `Deploy_HU010_Priorizacion.zip`
- `Lead_PSR_SecondaryPriority` — record-triggered no `PendingServiceRouting`: lê o `Rating` do Lead roteado e grava **`RoutingPriority`** (Hot=0, Warm=1, Cold=2; 0 = maior prioridade). Draft → ativar.

## 2. Config pós-deploy (por ambiente)
- [ ] **Atribuir** o PS `HU010_Campos_SLA_Lead` aos usuários (senão os campos ficam invisíveis).
- [ ] **Ativar os 4 flows**: `Lead_SLA_Escalation`, `Lead_AT_PrimerContacto`, `Lead_Score_Temperatura`, `Lead_PSR_SecondaryPriority`.
- [ ] **Record Type**: garantir que o valor de `Rating` funciona (é standard).
- [ ] **NÃO precisa** configurar "Secondary Routing Priority" no Service Channel — usamos `RoutingPriority` direto via flow (o campo `SecondaryRoutingPriority` não existe nesta org).
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

### T4 — Priorización (`Lead_PSR_SecondaryPriority`)
Pré: precisa de **backlog** (itens esperando na fila, sem agente pegando na hora).
1. Deixe agentes offline (ou sem capacidade) para segurar os itens na fila.
2. Roteie 2 leads: um `Rating=Hot`, um `Rating=Cold`.
3. Confira o valor gravado no PSR:
```sql
SELECT Id, WorkItemId, RoutingPriority FROM PendingServiceRouting ORDER BY CreatedDate DESC
```
- Lead Hot → `RoutingPriority = 0`; Lead Cold → `2`.
4. Traga um agente online → o **caliente deve ser roteado antes** do cold.
> A prioridade só se manifesta com backlog. Sem fila de espera, não há o que reordenar (correto).

---

## 5. Estado final da HU-010
| Requisito | Solução | Tipo |
|---|---|---|
| SLA primeiro contato + data/hora | `SLADeadline__c` (existente) + escada | declarativo |
| Escada (recordatório/supervisor/reasignación 10min) | `Lead_SLA_Escalation` evoluído | declarativo |
| "Gestión" válida | Task completada → `FechaPrimerContacto__c` | declarativo |
| Cumpriu SLA | `CumplioSLA__c` (fórmula) | declarativo |
| Temperatura frío/tibio/caliente | `Rating` nativo (via B3 + Einstein) | declarativo |
| Priorización calientes / SLA vencido | `RoutingPriority` via flow no PSR | declarativo |
| Sticky-agent por presença | `LeadRouting_OmniFlow` (nativo, já existia) | nativo |

**Campos novos criados: 1 (`FechaPrimerContacto__c`) + 1 fórmula (`CumplioSLA__c`). Zero Apex.**
