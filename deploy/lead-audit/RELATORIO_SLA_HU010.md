# Análise Read-Only — Ecossistema SLA (Lead) + Plano HU-010
> Org grupoq--devsales · 2026-07-07 · **READ-ONLY (R1): nada deployado/editado/ativado.**
> Fonte: retrieve `audit` (2026-07-03) + `metadata_31` (hoje, 2 flows) + dados CMT `Lead_SLA_Config__mdt` colados pelo Beltrão.
> **Limitação (R5):** sem acesso à org, as queries Tooling/SOQL/describe da Fase A não são executáveis aqui — marcadas como PENDENTE. Números de versão (V10) e autoria não vêm no `.flow`.

---

## (1) INVENTÁRIO A1
Flows relevantes encontrados no retrieve (a query `FlowDefinitionView` precisa ser rodada na org para ActiveVersionId/LatestVersionId/autoria — **PENDENTE**):

| Flow | Tipo | apiVersion | triggerOrder | status (retrieve) |
|---|---|---|---|---|
| `Lead_BS_SetSLADeadline` | Before-Save, CreateAndUpdate | 62 | **20** (md31) | Active |
| `Lead_SLA_Escalation` | After-Save, CreateAndUpdate, scheduled | 62 | **40** (md31) | Active |
| `Lead_BS_TransicionEstado` | Before-Save, Update | 66 | (sem triggerOrder no retrieve) | Active |
| `Lead_TriggerOmniRouting` | After-Save, CreateAndUpdate, AsyncAfterCommit | 66 | (n/d) | Active |
| `LeadRouting_OmniFlow` | subflow de roteamento Omni (chamado pelo Trigger) | — | — | (não lido em profundidade) |

Delta `metadata_31` (hoje) vs `audit` (07-03): idênticos na lógica; só adicionam `<areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>` e os `<triggerOrder>` (20 e 40). **O trigger `CreateAndUpdate` está presente** no `Lead_SLA_Escalation` (`<recordTriggerType>CreateAndUpdate</recordTriggerType>`, start).

---

## (2) LEITURA PROFUNDA — Q1–Q15 (com evidência)

### `Lead_BS_SetSLADeadline`
- **Q1 Entrada:** `<start>` **sem `<filters>`** → dispara em TODO Lead (Create+Update). Segmentação interna pela decision `Es_Nuevo` (formula `esNuevo` = `ISNEW()`). **Não filtra por status/canal/línea na entrada.**
- **Q2 Campos estampados:** `SLADeadline__c` (assignment `Set_Deadline`) e `LastGestionDate__c` (assignment `Stamp_Gestion`, = `$Flow.CurrentDateTime`).
- **Q3 Cálculo:** formula `deadlineFx` = `{!$Flow.CurrentDateTime} + ({!Get_SLA.SLAMinutes__c} / 1440)`. `Get_SLA` faz lookup em `Lead_SLA_Config__mdt` com `DeveloperName EqualTo "Default_Bandeja"` (literal). Pelos dados: `Default_Bandeja.SLAMinutes__c = 60`. **Logo o deadline é sempre now + 60 min — NÃO por canal**, apesar de a CMT ter registros por canal (ver risco 1).
- **Q4 Sync/banda:** `RecordBeforeSave` (síncrono). `triggerOrder = 20` (md31).
- **Q5 Bypass:** **AUSENTE.** Nenhum `$Permission` no flow (risco 4).
- **Nota p/ HU-010:** `Stamp_Gestion` grava `LastGestionDate__c` quando `statusCambio` (`ISCHANGED($Record.Status)`) — ou seja, em QUALQUER mudança de status, não numa gestión válida.

### `Lead_SLA_Escalation` (versão do retrieve)
- **Q6 Gatilho:** `<start>` `RecordAfterSave`, `CreateAndUpdate`, `doesRequireRecordChangedToMeetCriteria=true`, filtro de entrada `Status EqualTo "Nuevo"`. **UM único scheduled path** `Path_SLA`: `offsetNumber=0`, `offsetUnit=Minutes`, `recordField=SLADeadline__c`, `timeSource=RecordField` → dispara **exatamente no deadline**. Não há paths de recordatório nem de 10 min.
- **Q7 O que o path faz hoje:**
  - `Verifica_Atendido` (Status ainda = "Nuevo"?) → `Capturar_Owner` → `Get_FilaAnterior` → `Get_Config` (CMT Default_Bandeja) → `Get_Queue` (fila `Get_Config.EscalationQueueDevName__c` = `Leads_CR_Offline`) → `Queue_Found`:
    - **Reasignação (existe):** `Update_Reasignar` seta `OwnerId = Get_Queue.Id`, `Rating="Hot"`, `ReassignReason__c="SLA_Primera_Atencion"`, `SLAReassignCount__c`, `TransferDate__c`, `WebMessage__c`.
    - Sem fila → `Log_Sem_Fila` (Task) → `Update_Soft` (marca Hot/contador, **sem trocar owner**).
  - `Avalia_Max`: se `pasouMax` (`nuevoContador > BLANKVALUE(Get_Config.MaxReassignments__c, 2)`; CMT=3) → `Get_OwnerUser`→`Get_Role`→`Get_Profile` (Name="Gerente de Ventas / Gerente de Marca")→`Get_Manager`→`Notificar_Gerente`.
  - **Notificação a supervisor (existe, mas condicional):** `Notificar_Gerente` = `customNotificationAction` (tipo `Lead_SLA_Alert`), **só quando estourou o máximo de reasignações**, não como degrau intermediário.
  - **Recordatório ao dono (NÃO existe):** nenhum lembrete antes/na hora do deadline.
- **Q8 O que para o relógio:** só a decision `Verifica_Atendido` → `$Record.Status EqualTo "Nuevo"`. Se saiu de "Nuevo", o path encerra ("Ja atendido"). **NÃO checa atividade (Task/Event) nem `LastGestionDate__c`.** "Gestión" hoje = status deixou de ser "Nuevo" (risco 5).
- **Q9 Fault:** todos os `recordLookups`/`recordUpdates` têm `faultConnector → Log_Falha` (Task). **Exceção:** `Notificar_Gerente` (actionCall) **não tem faultConnector** → falha da notificação é engolida (risco 3).
- **Q10 Hardcoded:** `Default_Bandeja`; Status `"Nuevo"`; Profile Name `"Gerente de Ventas / Gerente de Marca"`; CustomNotificationType `"Lead_SLA_Alert"`; `Rating="Hot"`; `ReassignReason__c="SLA_Primera_Atencion"`; fallback `MaxReassignments` = `2`; prefixos `"00G"`/`"005"`. **Nenhum Id literal (00G/005 como Id).**
- **Q11 Omni:** **Não libera AgentWork nem chama routeWork.** A reasignação é troca de `OwnerId` para uma fila (`Get_Queue.Id`). O roteamento Omni real está no flow separado `Lead_TriggerOmniRouting` (ver abaixo).
- **Q12 Bypass:** **AUSENTE** (risco 4).
- **Q13 Versão ativa = V10?** **NÃO CONFIRMÁVEL pelo `.flow`** (não traz número de versão). Evidência indireta: o fix `CreateAndUpdate` **está** presente e há `triggerOrder=40` no retrieve de hoje. **Rodar `FlowVersionView`/`FlowDefinitionView` na org para confirmar V10 e o delta ativa×latest (R5).**
- **Q14 Autoria:** não vem no `.flow`. **PENDENTE (Tooling).**

### `Lead_BS_TransicionEstado` (Q15)
- Before-Save, `Update`, entrada `IsConverted EqualTo false`. Máquina de estados (`Evaluar_Transicion`) com transições permitidas: **Nuevo→Asignado**; Asignado→En contacto; En contacto→No calificado (exige `DiscardReason__c` via `Requiere_Motivo`) | Convertido; No calificado→En contacto; No contactado→En contacto (`Resetear_Intentos`: `ContactAttempts__c=0`, limpa `DiscardReason__c`). Transição fora disso → `Error_Transicion_Invalida` (customError).
- **Interação com SLA:** **NÃO** toca `SLADeadline__c` nem `LastGestionDate__c`. Só valida transições e mexe em `ContactAttempts__c`/`DiscardReason__c`. A partir de **Nuevo** a única saída é **Asignado**. A `description` cita que o cierre automático (`Lead_Sched_CierreIntentos`) usa **`$Permission.BypassLeadLifecycle`** — ou seja, **o domínio Lead tem bypass próprio (`BypassLeadLifecycle`)**, distinto de `Bypass_Gates_Automacao` (relevante p/ R7).

### `Lead_TriggerOmniRouting` (para B5)
- After-Save, CreateAndUpdate, path único `AsyncAfterCommit`. Entrada: `Brand__c` not null AND `IsConverted=false` AND (CompanyCode C101/C105/N101/N105 OR Industry Repuestos/PA).
- `TargetQueueDeveloperName` (formula): Industry=Repuestos→`Leads_Repuestos`; PA→`Leads_Productos_Automotrices`; CompanyCode N101→`Leads_N101_Motos`; N105→`Leads_N105_Motos`; else `Queue_Vendedores_CR`.
- `Get_Queue_Target` → `Check_Config` (fila tem `QueueRoutingConfigId`?) → **`Invocar_OmniRouting` = subflow `LeadRouting_OmniFlow`** (inputs recordId, routingConfigId, TargetQueueId). Sem config → `Log_Falha_Config` (Task). Fault do lookup → `Log_Falha_Roteamento` (Task). **Sem bypass gate.**

---

## (3) ACHADOS A3 (campos, picklists, setup)

**Campos que EXISTEM (evidenciados nos flows):** `SLADeadline__c`, `LastGestionDate__c`, `SLAReassignCount__c`, `ReassignReason__c`, `TransferDate__c`, `TransferredFromOnlineConsultant__c`, `WebMessage__c`, `ContactAttempts__c`, `DiscardReason__c`, `Brand__c`, `CompanyCode__c`, `Sociedad__c`, `Industry`, `Rating`, `Status`.

**Campos da HU-010 — SEM evidência de existência** (não referenciados em nenhum flow): `FechaPrimerContacto__c`, `CumplioSLA__c`, `Temperatura__c`, `PrioridadRuteo__c`. **Rodar a query `FieldDefinition` para confirmar (R5).**

**CMT `Lead_SLA_Config__mdt`** (dados colados): campos `Channel__c`, `BusinessLine__c`, `Sociedad__c`, `EscalationQueueDevName__c`, `MaxReassignments__c`, `SLAMinutes__c`, `MaxContactAttempts__c`, `ReminderIntervalHours__c`. 5 registros por canal (Agencia 120/2, Bandeja 60/3, Correo 120/2, Redes 120/2, Web 60/2). **`ReminderIntervalHours__c` (1h/24h) existe mas nenhum flow usa** (risco 2).

**PENDENTE (R5) — não executável sem org:** picklist completa `Lead.Status` (EN×ES; o lead real em "Working - Contacted"), picklist `Lead.Industry` (valor real "Gobierno"), describe `ScoreIntelligence` (Score/categoria/BaseId), ServiceChannel `Lead_Channel` (Secondary Routing Priority), QuickAction "Reassign" no layout, modelo Einstein (global×próprio). **Rode as queries do briefing e cole; eu completo a análise.**

---

## (4) PLANO DE EXTENSÃO B1–B5 (mapa, sem executar)

### B1 — Estampado de primeiro contato (`FechaPrimerContacto__c` + `CumplioSLA__c`)
- **Onde nasce:** **FLOW NOVO** no domínio de atividade (não tocar SetSLADeadline nem TransicionEstado).
- **Gatilho proposto:** record-triggered em **Task/Event completada vinculada ao Lead** (gestión válida real, conforme cliente) — na 1ª, se `FechaPrimerContacto__c` IsNull, estampa `FechaPrimerContacto__c = now` e `CumplioSLA__c = (now <= Lead.SLADeadline__c)`. Alternativa mais simples: gatilho na transição a "En contacto". **A definição exata de "gestión válida" é decisão do Beltrão** (Q8 mostra que hoje o "stop" é só Status≠Nuevo, fraco).
- **Elementos novos:** flow `Lead_AT_PrimerContacto`; Get do Lead; decision (primeiro contato nulo?); update dos 2 campos.
- **NÃO será tocado:** `Lead_BS_SetSLADeadline`, `Lead_BS_TransicionEstado`, `LastGestionDate__c`.
- **SELO: ADITIVO PURO — elementos existentes intocados.** SP≈3. Risco: depende da definição de gestión.

### B2 — Escada estendida (recordatório + supervisor + reasignação 10 min)
- **Onde nasce:** **scheduled paths NOVOS anexados** ao `Lead_SLA_Escalation` (o `Path_SLA` existente fica byte-idêntico).
- **Elementos novos:** `Path_Recordatorio` (offset por `ReminderIntervalHours__c` — aproveita o campo hoje morto) → recordatório ao owner (Custom Notification/Task); `Path_10min` (offset +10 min do deadline) → decision "sem gestión válida" (`FechaPrimerContacto__c` IsNull) → reasignação. Cada path com gate `NOT($Permission.BypassLeadLifecycle)` (R7).
- **Mecanismo de reasignação (Q11):** hoje é troca de `OwnerId` p/ fila; para "liberar AgentWork + re-roteamento" propõe-se **chamar o subflow `LeadRouting_OmniFlow`** a partir do path novo (detalhar com o XML do subflow).
- **NÃO será tocado:** `Path_SLA`, `Verifica_Atendido`, `Update_Reasignar`, `Notificar_Gerente` e todos os elementos atuais.
- **SELO: ADITIVO PURO — elementos existentes intocados.** SP≈5. Risco: colisão de offsets/duplicidade de reasignação; validar interação com o `Path_SLA` (offset 0).

### B3 — Temperatura (`Temperatura__c`)
- **Onde nasce:** **FLOW NOVO** no domínio de scoring. Sinais do cliente dominam (caliente direto); banda sobre `ScoreIntelligence.Score` (Get Records por `BaseId = Lead.Id`) como secundário; cortes default = tercis.
- **Elementos novos:** flow `Lead_Score_Temperatura`; Get `ScoreIntelligence`; decision sinais→caliente; senão banda de score→frío/tibio/caliente; update `Temperatura__c`.
- **NÃO será tocado:** nenhum flow existente. Requer criar `Temperatura__c`.
- **SELO: ADITIVO PURO.** SP≈5. Risco: **depende do describe de `ScoreIntelligence` (A3 pendente)** — nome do campo Score e relação BaseId a confirmar (R5).

### B4 — Priorização (`PrioridadRuteo__c` + Secondary Routing Priority no `Lead_Channel`)
- **Onde nasce:** campo novo `PrioridadRuteo__c` + **flow novo** de cálculo (Temperatura caliente e/ou SLA vencido → prioridade alta).
- **Config do canal:** apontar **Secondary Routing Priority** do ServiceChannel `Lead_Channel` para `PrioridadRuteo__c`. **NÃO é aditivo puro:** essa configuração **altera o comportamento de priorização de toda a fila que roteia pelo `Lead_Channel`**. → **DECISÃO PARA O BELTRÃO — não executar** sem GO específico.
- **NÃO será tocado:** flows de roteamento.
- **SELO parcial:** campo+flow = ADITIVO PURO; config do canal = **DECISÃO (altera comportamento existente)**. SP≈3 + decisão. Risco: reordenar fila em produção.

### B5 — Exceção sticky-agent (presença / `UserServicePresence`)
- **Onde nasce:** o roteamento chama o subflow `Invocar_OmniRouting` (`LeadRouting_OmniFlow`) a partir de `Check_Config` no `Lead_TriggerOmniRouting`. Inserir a checagem **sem editar o conector existente** `Check_Config → Invocar_OmniRouting` (R2) implica colocar o check **como elementos NOVOS dentro do `LeadRouting_OmniFlow`** (antes do `routeWork`), gated para deixar o caminho atual byte-idêntico quando o sticky não se aplica.
- **Elementos novos (proposta):** decision `Owner_Con_Presencia?` (Get `UserServicePresence` do owner anterior) → se online, mantém owner (sticky) → senão segue o `routeWork` atual.
- **Pré-requisito:** **ler o `LeadRouting_OmniFlow`** (disponível em `md18`/`md30`) para localizar o `routeWork` exato — a posição do enxerto é decisão a validar.
- **SELO: ADITIVO PURO (dentro do subflow, sem alterar elementos atuais).** SP≈5 + leitura do subflow. Risco: ponto de enxerto sem editar conector existente.

---

## (5) RISCOS NOMEADOS (R6 — só nomeados, sem correção)
1. **Config por canal MORTA:** SetSLADeadline e Escalation fixam `DeveloperName="Default_Bandeja"`; os registros CMT por canal (Agencia/Correo/Redes/Web) **nunca são usados** — todo lead recebe 60 min / fila `Leads_CR_Offline` / MaxReassign 3, ignorando `Channel__c`.
2. **Campos CMT ociosos:** `ReminderIntervalHours__c` e `MaxContactAttempts__c` existem mas o Escalation não tem recordatório nem usa o intervalo.
3. **Fault silencioso:** `Notificar_Gerente` (customNotificationAction) sem `faultConnector` — falha da notificação some.
4. **Sem bypass gate:** SetSLADeadline, Escalation e TriggerOmniRouting não têm `$Permission` — integrações/automação não podem ser isentadas (R7).
5. **"Gestión" fraca:** o "stop" do relógio é só `Status ≠ "Nuevo"`; não valida interação real (Task/Event) — passível de burla.
6. **Default divergente:** fallback `MaxReassignments = 2` na formula vs `3` no CMT Default_Bandeja.
7. **Reasignação fora do Omni:** Escalation troca `OwnerId` para fila sem `routeWork`; re-entrada no Omni depende da config da fila.
8. **Profile por NOME hardcoded:** `"Gerente de Ventas / Gerente de Marca"` — renomear o profile quebra o lookup do manager.
9. **Nomes de fila/Industry/CompanyCode hardcoded** na formula do TriggerOmniRouting — dependência cross-ambiente.
10. **Higiene de Status EN×ES:** lead real em `"Working - Contacted"` (standard EN) não casa a lógica em espanhol (`"Nuevo"`, transições) — SLA/escalação podem não disparar/parar corretamente.
11. **Industry como "línea":** roteamento usa Industry=Repuestos/PA, mas há lead com Industry=`"Gobierno"` — picklist standard reaproveitada, conflito de premissa.

## (6) Nada foi alterado na org. Execução aguarda GO.
