# HU-046 — Pacote de deploy consolidado (v2, com carga real de cupos)

## Conteúdo (deployável)

| Item | Tarefa | Qtd |
|---|---|---|
| `DemoCapacityConfig__mdt` — Country, Brand, BranchName, BranchCode (opcional, pendente mapeo), MaxDemo, MaxExhibition, MaxDemoMileage (pendente open point 4), Comments | T04 | 1 tipo, 8 campos |
| Registros de cupos (excel `202606_Lista_DEMOEXH_Region_UnidosCom_vfinal2`, aba DATOS) | T04/D2 | **158** (CR 30 · GT 33 · HN 26 · NI 10 · PA 26 · SV 33; 15 marcas; totais 1.067 demo + 823 exh) |
| `RequestDemoVehicle` (entrada da tela de gerência) | T05 | 1 |
| `BypassAllocationValidation` (bypass do custom error em Quote — só integração/admin) | T11 | 1 |
| `DemoDesignationAlert` (desktop+mobile) | T09 | 1 |

Caso especial: SV/GWM/Los Duraznos tinha EXH "-" no excel → carregado como 0 com comentário no registro.

## O que NÃO está no pacote (e por quê)

| Item | Tarefa | Motivo / como fazer |
|---|---|---|
| Valores de picklist standard (Vehicle.Status "En exhibicion"/"Demo venta"; SerializedProduct.Status "Allocated"/Asignado) | T03 | StandardValueSet via metadata substitui o conjunto inteiro (risco); fazer via Object Manager (1 min cada) |
| Field History Tracking (Vehicle/SerializedProduct: Status + Owner) | T13 | Config de UI (Object Manager > Field History) — deploy parcial de objeto standard tem risco desnecessário |
| BusinessHours por país | T14 | SÓ se D9 = precisão (recomendação é D9a sem Apex); é dado de Setup, não metadata |
| Flows (T06/T07/T08/T10/T11/T12) e config CBSF (T01/T02) | build | Construção em org (Davi); depois de prontos, recuperar via retrieve e versionar aqui |
| Atualização dos Permission Sets (T15) | T15 | Adicionar custom permissions + FLS nos PS existentes da org |

## Pendências de dados
1. **Mapeo nombre → código de sucursal (C0xx)**: o excel traz nomes ("Uruca"); confirmar com GrupoQ o código SAP de cada uma e preencher `BranchCode__c` (ou o flow filtra por nome, se o Vehicle carregar o nome)
2. **MaxDemoMileage** (open point 4): km máximo por política — campo já existe, valores pendentes

## Deploy
```
sf project deploy start --metadata-dir deploy/HU046_faltantes -o <org> --dry-run   # validar
sf project deploy start --metadata-dir deploy/HU046_faltantes -o <org>
```
