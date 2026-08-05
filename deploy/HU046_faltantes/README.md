# HU-046 — Pacote dos itens pendentes (negrito da planilha v2)

| Item | Tarefa | Tipo |
|---|---|---|
| DemoCapacityConfig__mdt (5 campos) | T04 | Custom Metadata Type |
| RequestDemoVehicle | T05 | Custom Permission |
| DemoDesignationAlert | T09 | Custom Notification Type |
| DemoCapacityConfig.Ejemplo_C013_CHEVROLET | T04 | Registro CMDT de EXEMPLO (valores ficticios 2/4/10000 — substituir pela carga do excel de cupos do GrupoQ e apagar) |

**BusinessHours (T14) NÃO está no pacote, de propósito:** só é necessário se a decisão D9 optar pela precisão com BusinessHours (a recomendação da planilha é D9a = fórmula sem Apex). E BusinessHours é dado de Setup ("sin deploy"), criado manualmente em Setup > Company Settings > Business Hours, 1 por país, quando/se D9b for escolhida.

## Deploy
```
sf project deploy start --metadata-dir deploy/HU046_faltantes -o <org-devsales> 
# (ou Workbench > Migration > Deploy com o zip, validate antes)
```

## Pós-deploy (manual, sem metadata)
1. T03: adicionar valores de picklist standard via Object Manager: Vehicle.Status += "En exhibicion", "Demo venta"; SerializedProduct.Status += "Allocated" (label "Asignado")
2. T05: adicionar a custom permission RequestDemoVehicle aos PS de gerência
3. FLS dos 5 campos do CMDT para os perfis de manutenção
4. Substituir o registro de exemplo pela carga real de cupos
