# HU-046 — Pacote de deploy consolidado (v4)

Estado: v3.2 deployou **177 componentes verdes**; falharam só os 2 Permission Sets (description > 255 chars — corrigido na v4).
Novidade v4: a guarda de venda mudou de Quote para **Opportunity** (describes 05/08: Quote e QuoteLineItem NÃO têm lookup de unidade; `Opportunity.Vehiculo__c → Vehicle` já existe na org e é o anchor nativo).

## Para o Davi — o que deployar agora

**Não precisa redeployar tudo.** Use `HU046_delta.zip` (4 componentes) + `HU046_destructive_v2.zip`:

1. `HU046_delta.zip`: PS_Demo_Vehicle_Management + PS_Demo_Vehicle_Execution (descriptions ≤255), `OpportunityBeforeHandler` (novo, substitui QuoteBeforeHandler) e `ExecuteDemoRequest` (agora grava `Vehiculo__c` na Opportunity criada na liberação).
2. `HU046_destructive_v2.zip`: apaga o flow Draft `QuoteBeforeHandler` (obsoleto — sem campo de unidade em Quote, a guarda nunca fecharia).

O pacote completo (`HU046_faltantes.zip`) segue atualizado e é idempotente — serve para re-deploy integral se preferir.

## Conteúdo (deployável)

| Item | Tarefa | Qtd |
|---|---|---|
| `DemoCapacityConfig__mdt` (8 campos) + 158 registros de cupos (CR 30 · GT 33 · HN 26 · NI 10 · PA 26 · SV 33) | T04/D2 | 159 |
| `RequestDemoVehicle`, `BypassAllocationValidation` (custom permissions) | T05/T11 | 2 |
| `DemoDesignationAlert` (notification type desktop+mobile) | T09 | 1 |
| Flows (Draft): `ValidateDemoQuota`, `LogDemoActivity`, `OpportunityBeforeHandler` (guarda de venda via `Vehiculo__c`), `ReleaseExpiredDemoAssignments` (scheduled diário), `ManageDemoVehicle` (tela gerência, 4 ramas), `ExecuteDemoRequest` (tela encargado) | T06–T12 | 6 |
| `PS_Demo_Vehicle_Management` (gerência: gate RequestDemoVehicle + tela Manage), `PS_Demo_Vehicle_Execution` (encargado de piso: tela Execute) | T15 | 2 |

## O que NÃO está no pacote (e por quê)
- Valores de picklist standard (Vehicle.Status) — StandardValueSet via metadata substitui o conjunto inteiro; fazer no Object Manager (já feito).
- Field History Tracking Vehicle/SerializedProduct (T13) — config de UI.
- App Pages/tabs de exposição das telas — App Builder (component visibility `{!$Permission.RequestDemoVehicle}` na tela de gerência).
- Ativação dos flows — ordem: ValidateDemoQuota + LogDemoActivity → OpportunityBeforeHandler → ReleaseExpiredDemoAssignments → telas.
- BusinessHours por país (T14) — só se D9 = precisão.

## Pendências
1. Mapeo nombre → código sucursal (C0xx) para `BranchCode__c`.
2. `MaxDemoMileage` (open point 4) — valores pendentes.
3. TODO-DAVI nas descriptions dos flows (merge com handler de Opportunity existente, se houver; lookups de User; derivação marca/sucursal do Vehicle — depende do describe de VehicleDefinition).

## Deploy
```
sf project deploy start --metadata-dir deploy/HU046_delta -o <org> --dry-run
sf project deploy start --metadata-dir deploy/HU046_delta -o <org>
sf project deploy start --metadata-dir deploy/HU046_destructive_v2 -o <org> --post-destructive-changes deploy/HU046_destructive_v2/destructiveChanges.xml
```
