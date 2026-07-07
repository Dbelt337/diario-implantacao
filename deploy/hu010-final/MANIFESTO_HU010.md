# HU-010 — Manifesto de Deploy (ambiente de teste) + Resumo da Solução
> 2026-07-07 · SLA de primeiro contato, escada de escalação, temperatura, priorização e sticky-agent no Lead.
> **Correção 07/07:** Secondary Routing Priority exige campo **picklist** → usamos o `Rating` nativo (não um campo Number). `PrioridadRuteo__c` e o flow B4 foram descartados.

## 1. Resumo da solução (end-to-end)
1. **Lead criado (Status=Nuevo)** → `Lead_BS_SetSLADeadline` (existente) carimba `SLADeadline__c = agora + SLAMinutes` (CMT `Lead_SLA_Config__mdt`).
2. **Temperatura** → `Lead_Score_Temperatura` (before-save, ordem 30) lê Einstein Score (`ScoreIntelligence`) + sinais e grava o **`Rating`** nativo (Hot/Warm/Cold = caliente/tibio/frío).
3. **Roteamento** → `Lead_TriggerOmniRouting` → `LeadRouting_OmniFlow`: se o vendedor preferido tem a skill da marca **e está online** (`UserServicePresence`), entrega direto a ele (**sticky-agent**); senão roteia por skills à fila.
4. **Priorização na fila** → **Secondary Routing Priority nativo** usando o campo **`Rating`** (Hot=0 / Warm=1 / Cold=2). Cobre os dois gatilhos da HU-010: **caliente** (temperatura) e **SLA vencido** (a escada grava `Rating=Hot` no vencimento).
5. **Primeiro contato** → `Lead_AT_PrimerContacto`: na primeira gestión válida grava **`FechaPrimerContacto__c`** e **`CumplioSLA__c`**.
6. **Escada de SLA** → `Lead_SLA_Escalation` (3 scheduled paths sobre `SLADeadline__c`): -15 min recordatório ao dono; 0 (vencimento) notifica supervisor; +10 min reasigna à `Leads_CR_Offline` se `Status=Nuevo` e `FechaPrimerContacto__c` vazio.

## 2. O que subir no deploy (delta HU-010)
**Passo 1 — `Deploy_HU010_Step1_Campos_FLS.zip`** (Check Only + Rollback on Error)
- CustomField: `Lead.CumplioSLA__c`, `Lead.FechaPrimerContacto__c`
- PermissionSet: `HU010_Campos_SLA_Lead` (FLS dos 2 campos)

**Passo 2 — `Deploy_HU010_Step2_Flows.zip`** (Check Only + Rollback on Error) — **depois do Passo 1**
- Flow: `Lead_SLA_Escalation` (evoluído), `Lead_AT_PrimerContacto`, `Lead_Score_Temperatura` — sobem **inativos (Draft)**.

> Priorização **não tem metadata a subir** — é só configuração (item 3).

## 3. Priorización = Secondary Routing Priority (config, fundamentada na doc oficial)
Por que a busca deu 0/0 nas telas: o recurso **fica oculto até ser habilitado**. Passos oficiais:
1. **Habilitar:** Setup → Omni-Channel → **Omni-Channel Settings** → marcar **"Enable Secondary Routing Priority"** → Save. *(É este passo que faltava — sem ele a seção não aparece em lugar nenhum.)*
2. Depois de habilitado, a seção **"Secondary Routing Priority"** aparece **no Service Channel** (`Lead_Channel`).
3. Em **Secondary Routing Priority Field**, selecionar um campo **picklist** → **`Rating`**.
4. Atribuir a ordem a cada valor (**0 = maior prioridade**): `Hot=0`, `Warm=1`, `Cold=2` → Save.

Como funciona (doc): o Secondary Priority **desempata itens com a mesma Primary Priority** — menor número = maior prioridade. Ou seja, dentro da fila, leads `Hot` (caliente / SLA vencido) são empurrados antes.
> **Campo tem que ser picklist** (você ranqueia cada valor). Por isso `PrioridadRuteo__c` (Number) **não serve** e foi descartado; `Rating` é picklist nativo e a escada já o seta como Hot no SLA vencido.

## 4. Config por ambiente (não vai no metadata)
- [ ] **Atribuir o PS** `HU010_Campos_SLA_Lead` aos usuários.
- [ ] **Ativar os 3 flows** (deploy vem Draft).
- [ ] **Habilitar + configurar o Secondary Routing Priority** (item 3), campo = `Rating`.
- [ ] **Confirmar dono do US-031** sobre a mudança de timing da reasignación (0 → +10 min).

## 5. Dependências que JÁ TÊM que existir no destino (não são delta)
Flows: `Lead_BS_SetSLADeadline`, `Lead_TriggerOmniRouting`, `LeadRouting_OmniFlow` (contém o sticky-agent nativo).
Omni: ServiceChannel `Lead_Channel`, QueueRoutingConfig `Lead_Routing_Config`, filas (`Leads_CR_Offline`…), Skills/ServiceResource/Presence.
Config/dados: CMT `Lead_SLA_Config__mdt` (+ registros), `CustomNotificationType` `Lead_SLA_Alert`, Profile `Gerente de Ventas / Gerente de Marca`.
Campos: `SLADeadline__c`, `LastReminderDate__c`, `SLAReassignCount__c`, `ReassignReason__c`, `TransferDate__c`, `Rating`, `ScoreIntelligenceId`, `Status` (ES).

## 6. Descartados (limpeza opcional no DevSales)
Já subiram no DevSales mas **não fazem parte da solução** — não ativar e, se quiser, remover depois (destructiveChanges):
- Campo `Lead.PrioridadRuteo__c` (Number — tipo errado para Secondary Routing Priority).
- Flow `Lead_Calc_Prioridad` (B4 — Draft, não ativar).

## 7. Artefatos (branch claude/nifty-dijkstra-AcXrv)
| Artefato | Caminho |
|---|---|
| Step 1 (campos+FLS) | `deploy/hu010-final/Deploy_HU010_Step1_Campos_FLS.zip` |
| Step 2 (flows) | `deploy/hu010-final/Deploy_HU010_Step2_Flows.zip` |
| Fontes flows | `deploy/hu010-b2/flows/`, `deploy/hu010-rest/flows/` |
| Análise + plano | `deploy/lead-audit/RELATORIO_SLA_HU010.md` |

## 8. Fontes oficiais
- Set Up Secondary Routing Priority — https://help.salesforce.com/s/articleView?id=service.omnichannel_secondary_routing_priority.htm
- Routing Configuration Settings — https://help.salesforce.com/s/articleView?id=service.service_presence_routing_configuration_settings.htm
- Advanced Routing with Omni-Channel Flows — https://help.salesforce.com/s/articleView?id=service.omnichannel_flows.htm
