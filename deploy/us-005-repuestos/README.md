# US-005 — Detecção, Identidade e Unificação de Leads de Repuestos/PA

**Native-First, zero Apex.** Formato **Metadata API tradicional** (campos embutidos em `Lead.object`, deploy via Workbench). Eu **não fiz deploy** — você implanta nas 4 fases abaixo.

## Formato gerado (confirmação)
Metadata API tradicional. Os 5 custom fields estão **embutidos** em `phase1/objects/Lead.object` (não como `*.field-meta.xml`). Cada fase tem zip próprio (`phaseN.zip`) pronto pra Workbench → Migration → Deploy.

## Ordem de deploy (a ordem importa)

| Fase | Zip | Conteúdo | Pré-requisito |
|---|---|---|---|
| **1** | `phase1.zip` | 5 campos no Lead + Matching Rule **INATIVA** + PS de FLS | — |
| **2** | `phase2.zip` | **Ativa** a Matching Rule (`ruleStatus=Active`) | Fase 1 deployada |
| **3** | `phase3.zip` | Duplicate Rule (Alert + Allow) | Matching Rule **ativa** (Fase 2) |
| **4** | `phase4.zip` | CMT de config + registro Default + os 2 Flows | Fases 1-3 + **D-005-A/B/C confirmados** |

> **Fases 1-3 são neutras** às decisões pendentes — podem ir agora. **Só a Fase 4 (Flows)** depende dos valores assumidos. Se a Melisa responder antes, sobe tudo; senão, sobe 1-3 e segura.

### Por fase
- **Fase 1:** Workbench → Deploy → `phase1.zip`. **Marque "Check Only" primeiro** (valida sem gravar). Depois deploy real. A Matching Rule está inativa de propósito: ativar dispara reindexação assíncrona e não pode no mesmo deploy que cria os campos.
- **Fase 2:** Deploy `phase2.zip` (mesma regra, agora `Active`). Os campos já existem → ativação passa.
- **Fase 3:** Deploy `phase3.zip`. A Duplicate Rule referencia a Matching Rule pelo fullName; se ela não estiver ativa, falha.
- **Fase 4:** Deploy `phase4.zip` (CMT + record + 2 Flows). O Flow de reasignación lê os campos da Fase 1, o CMT e a presença Omni.

## package.xml por fase
- **Fase 1:** `CustomField` (Lead.VIN__c, VehiclePlate__c, WasUnified__c, UnifiedFromLeadId__c, DuplicateReason__c) · `PermissionSet` (GQ_Lead_Repuestos_FLS) · `MatchingRule` (Lead.GQ_Lead_Repuestos_Match)
- **Fase 2:** `MatchingRule` (Lead.GQ_Lead_Repuestos_Match)
- **Fase 3:** `DuplicateRule` (Lead.GQ_Lead_Repuestos_Dup)
- **Fase 4:** `CustomObject` (GQ_Lead_Repuestos_Config__mdt) · `CustomField` (4 do CMT) · `CustomMetadata` (GQ_Lead_Repuestos_Config.Default) · `Flow` (GQ_Lead_Repuestos_Reasignacion, GQ_Lead_Repuestos_PreMerge)

## Como funciona
- **Matching/Duplicate Rule:** detectam dup por Email **OR** MobilePhone **OR** VIN **OR** Placa (todos **Exact**, OR), e **alertam sem bloquear** (Alert + Allow).
- **Flow `GQ_Lead_Repuestos_Reasignacion`** (Lead create, **async after-commit**): se é Repuestos e há lead anterior do mesmo contato → se o asesor anterior tem presença Omni ativa, **reasigna** o lead novo a ele; e, se for **mesma peça** (`Product2Id`) **dentro da janela** (5 dias, CMT), marca **candidato a unificação** (popula `UnifiedFromLeadId__c`). Não unifica, não bloqueia, não deleta. Fault → Task, sem perder lead.
- **Flow `GQ_Lead_Repuestos_PreMerge`** (Screen, no Lead master): prepara `WasUnified__c`/`UnifiedFromLeadId__c` no master e `DuplicateReason__c` no duplicado. **O merge é manual/nativo** depois.

## 🚩 Assunções a confirmar (NÃO inventei — sinalizei)
1. **Campo do produto no LeadLineItem = `Product2Id`** (standard). A spec escreveu `ProductId`. **Confirme o API name exato** — se for outro, troco na decisão `Avalia_Unificacao` e no `Get_LineItem_*`.
2. **O que marca um Lead como "Repuestos"** = `LeadSource == CMT.RepuestosLeadSource__c` (default `'Repuestos'`). **Confirme o campo/valor** (pode ser ChannelCode__c ou outro). É parâmetro no CMT — troca sem redeploy de Flow.
3. **FLS via Permission Set** `GQ_Lead_Repuestos_FLS` (a spec pediu nos profiles AC_Vend_Rep/AC_Sup_Rep). Usei PS pra não depender do API name interno do profile. Se quiser nos profiles, me confirme os nomes exatos.
4. **D-005-A/B/C** (no CMT, assumidos): janela 5 dias · granularidade ProductId (SKU) · regra dominante "independentes por peça". **Confirmar com a Melisa antes da Fase 4.**
5. **Timing do LeadLineItem:** rodei o Flow em **async after-commit** pra dar tempo dos line items existirem. Se na sua org os `LeadLineItem` são inseridos numa **transação separada bem depois** do Lead, a detecção de "mesma peça" pode não ver o item — nesse caso o certo é um Flow disparado por **LeadLineItem create**. Me avisa como os line items entram (mesmo request do Lead, ou batch posterior) que eu ajusto.

## Validação pós-deploy (DevSales)
1. Lead Repuestos email X → outro com mesmo email, **peça diferente**, mesmo dia → **alerta aparece, permite salvar**, e o 2º vai pro mesmo asesor (se disponível).
2. 3º com mesmo email, **mesma peça**, dentro de 5 dias → **candidato a unificação**, `UnifiedFromLeadId__c` populado.
3. Mesma peça, **6 dias** depois → Lead independente, mesmo asesor.
4. Confirme (Salesforce Inspector) que a Duplicate Rule está em **Alert, nunca Block**.

> Lembrete de teste: a reasignación depende de o asesor anterior estar **online no Omni** (UserServicePresence). E a "mesma peça" depende de o LeadLineItem existir quando o Flow async roda.
