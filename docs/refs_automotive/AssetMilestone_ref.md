# AssetMilestone — object reference (colado pelo Diego 07/08, mapeado p/ API names)

Automotive Cloud Developer Guide, API 56+. Suporta create/update/upsert/query, change events, feed, **history**.

| Campo API | Tipo | Obrigatório | Nota |
|---|---|---|---|
| `Name` | string | sim | nome do marco |
| `AssetId` | lookup **Asset** | sim (Create, sem nillable) | relationship `Asset` |
| `VehicleId` | lookup **Vehicle** | não | relationship `Vehicle` — liga o marco à timeline do veículo |
| `MilestoneDate` | date | sim | data do evento |
| `MilestoneType` | picklist RESTRITA | sim | **`Order Received`, `Sold`, `Delivered`**, `Manufactured`, `Critical Recall`, `10 Years Service` (extensível no Setup Events & Milestones) |
| `Stage` | picklist restrita | sim | `Active` / `Expired` / `Provisional` (+ `StageComment`) |
| `UsageType` | picklist restrita | sim | `Automotive` |
| `Description`, `ExpirationDate` | string/date | não | |
| `LocationId` | lookup Location | não | + endereço completo (Street/City/State/Country/PostalCode, Lat/Long/GeocodeAccuracy) — onde a entrega ocorreu |
| `SourceSystemIdentifier` / `SourceSystemName` | string | não | chave p/ integração (ex.: nº fatura SAP!) |

**Action Plans in Automotive Cloud** (dev guide): ActionPlan/Item/Template/TemplateItem/TemplateItemValue/TemplateVersion — "use action plans for vehicles, **asset milestones**, and asset account/contact participants" → o checklist de entrega pode pendurar no próprio milestone ou no Vehicle.

**Events and Milestones component** (help): componente de página p/ Vehicle/Account/Contact/FinancialAccount; tipos configuráveis + ícones; dá p/ ocultar tipos por layout; ações rápidas a partir do marco (log call, create order).

## Mapeamento GrupoQ (decidido 07/08)
- Pedido enviado/confirmado SAP → (futuro, opcional) `Order Received`
- **Facturado → `Sold`** (flow Order_Facturado_Handler v2 — fase 4): Asset/Vehicle via Order→Opportunity.`Vehiculo__c`→Vehicle.AssetId; `SourceSystemName='SAP'`, `SourceSystemIdentifier` = nº fatura
- **Entrega física concluída → `Delivered`** (pacote assetização+entrega, com Action Plan template do ritual — pendente definição do checklist c/ negócio)
- Assetização (fechar asset do dono anterior + criar do comprador) continua no Facturado — quando implantada, os marcos passam a pendurar no asset do COMPRADOR.
