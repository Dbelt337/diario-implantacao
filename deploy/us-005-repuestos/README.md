# US-005 — Detecção, Identidade e Unificação de Leads de Repuestos/PA (versão revisada)

**Native-First, zero Apex.** Formato **Metadata API tradicional** (campos embutidos nos `*.object`). **Não fiz deploy** — você implanta em 4 fases via Workbench.

## Formato gerado (confirmação)
Metadata API tradicional. `LicensePlate__c` está embutido em `phase1/objects/LeadLineItem.object` e os 3 campos do Lead em `phase1/objects/Lead.object` (não `*.field-meta.xml`). Cada fase tem zip próprio.

## Decisões de arquitetura aplicadas (nativo)
- **VIN** = nativo `LeadLineItem.AssetIdentificationNumber` (não criei campo).
- **Chave de cotización** = nativo `LeadLineItem.ProductId`.
- **Linha Repuestos/PA** = nativo `LeadLineItem.ItemType` ∈ (Part, Accessory).
- **Vínculo ao veículo real** = igualdade de VIN: `AssetIdentificationNumber` = `Vehicle.VehicleIdentificationNumber` **ou** `Asset.SerialNumber` (sem lookup custom).
- **Placa** = único custom: `LeadLineItem.LicensePlate__c` Text(20).
- Matching Rule de Lead só lê campos do Lead → Email/Phone/MobilePhone. VIN/peça/placa são resolvidos no Flow (Camada 2).

## Ordem de deploy

| Fase | Zip | Conteúdo | Pré-requisito |
|---|---|---|---|
| **1** | `phase1.zip` | `LicensePlate__c` (LeadLineItem) + 3 campos Lead + Matching Rule **INATIVA** + PS de FLS | — |
| **2** | `phase2.zip` | **Ativa** a Matching Rule | Fase 1 |
| **3** | `phase3.zip` | Duplicate Rule (Alert + Allow) | Matching Rule ativa (Fase 2) |
| **4** | `phase4.zip` | CMT `GQ_Dedup_Repuestos_Config__mdt` + registro Default + os 2 Flows | Fases 1-3 + **D-005-A/B/C confirmados** |

> Fases 1-3 são neutras às decisões pendentes — podem ir já. Só a Fase 4 (Flows) depende dos valores assumidos.
> Fase 1: **Check Only primeiro**. A Matching Rule vai inativa de propósito (ativar dispara reindexação async, não pode no mesmo deploy que cria campos).

## package.xml por fase
- **Fase 1:** `CustomField` (LeadLineItem.LicensePlate__c, Lead.WasUnified__c, Lead.UnifiedFromLeadId__c, Lead.DuplicateReason__c) · `PermissionSet` (GQ_Lead_Repuestos_FLS) · `MatchingRule` (Lead.GQ_Lead_Repuestos_Match)
- **Fase 2:** `MatchingRule` (Lead.GQ_Lead_Repuestos_Match)
- **Fase 3:** `DuplicateRule` (Lead.GQ_Lead_Repuestos_Dup)
- **Fase 4:** `CustomObject` (GQ_Dedup_Repuestos_Config__mdt) · `CustomField` (3 do CMT) · `CustomMetadata` (GQ_Dedup_Repuestos_Config.Default) · `Flow` (GQ_Lead_Repuestos_Reasignacion_y_Cotizacion, GQ_Lead_Repuestos_PreMerge)

## Flow `GQ_Lead_Repuestos_Reasignacion_y_Cotizacion` (Lead create, async after-commit)
1. Lê o `LeadLineItem` do lead novo. Sem item → sai.
2. Repuestos? `ItemType` ∈ (Part, Accessory). Se não → sai.
3. **Vínculo a veículo:** se `AssetIdentificationNumber` preenchido → busca `Vehicle` (por VIN) e, se não achar, `Asset` (por SerialNumber). Se achar → **Task** ao asesor com a referência.
4. **Reasignación:** Lead anterior do mesmo contato (Email OU MobilePhone). Se o asesor anterior tem presença Omni ativa → atribui o lead novo a ele; senão não mexe.
5. **Unificación (candidato):** mesma peça (`ProductId`) dentro da janela (CMT, 5 dias) → popula `UnifiedFromLeadId__c`. Não unifica, não bloqueia, não deleta.
6. Fault → Task, sem perder o lead.

## Flow `GQ_Lead_Repuestos_PreMerge` (Screen, no Lead master)
Prepara `WasUnified__c`/`UnifiedFromLeadId__c` no master e `DuplicateReason__c` no duplicado. **Merge é manual/nativo** depois. Roda em SystemModeWithSharing.

## 🚩 Pontos a confirmar (não inventei)
1. **Vínculo a veículo — como registrar (AMBÍGUO na spec):** implementei via **Task** ao asesor (sem custom lookup, conforme a opção "logar o match"). Se preferir um **campo de texto de referência no Lead**, me diz que troco a Task por um campo (precisaria adicioná-lo no escopo).
2. **`Vehicle.VehicleIdentificationNumber`, `Asset.SerialNumber`, `LeadLineItem.ItemType/ProductId/AssetIdentificationNumber`** — usei os API names que a spec fixou como nativos. Se algum divergir na org, ajusto (1 linha cada).
3. **FLS via Permission Set** (a spec citou profiles AC_Vend_Rep/AC_Sup_Rep) — PS evita depender do API name interno do profile. Se quiser nos profiles, me confirme os nomes.
4. **D-005-A/B/C** (CMT, assumidos): janela 5 dias · ProductId (SKU) · independentes por peça. Confirmar com a Melisa antes da Fase 4.
5. **Timing do LeadLineItem:** Flow em **async after-commit** pra os line items já existirem. Se entram em transação separada bem posterior, o certo é disparar por **LeadLineItem create** — me avisa como entram que eu adapto.

## Validação pós-deploy (DevSales)
1. Lead Repuestos email X → outro com mesmo email, **peça diferente**, mesmo dia → alerta aparece, **permite salvar**, 2º vai pro mesmo asesor (se online).
2. 3º com mesmo email, **mesma peça**, < 5 dias → **candidato a unificação**, `UnifiedFromLeadId__c` populado.
3. Mesma peça, **6 dias** depois → Lead independente, mesmo asesor.
4. LeadLineItem com `AssetIdentificationNumber` = VIN de um Vehicle/Asset existente → **Task** de vínculo criada.
5. Confirme (Salesforce Inspector) que a Duplicate Rule está em **Alert, nunca Block**.
