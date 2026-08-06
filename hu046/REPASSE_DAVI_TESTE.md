# HU-046 — Repasse para o Davi · teste e continuação

**Data:** 06/08/2026 (noite) · **Autor:** Diego (com registro completo no STATUS.md do diário)
**Estado geral:** ciclo principal TESTADO E FUNCIONANDO ponta a ponta na DevSales. Restam os testes negativos/complementares (seção 4) e a limpeza (seção 5).

---

## 1. O que está na org AGORA (versões finais ativas)

| Componente | Estado | Observação |
|---|---|---|
| Flow `ManageDemoVehicle` (tela gerência) | **Ativa a última versão** (vários redeploys hoje — usar sempre a de maior número) | Ver mudanças de desenho na seção 2 |
| Flow `ExecuteDemoRequest` (tela encargado) | Ativa (busca dupla VIN/nome) | |
| Subflows `ValidateDemoQuota` + `LogDemoActivity` | Ativos | |
| `OpportunityBeforeHandler` | Ativo (v3: só RT GQOpportunitiesAutos; bypass BypassAllocationValidation OU Bypass_Gates_Automacao) | |
| Scheduled `ReleaseExpiredDemoAssignments` | Ativo (diário 06:00 UTC, fórmula WEEKDAY) | |
| 2 App Pages + tabs (Vehículos Demo / Ejecutar Solicitudes Demo) | Criadas e ativas; visibility `{!$Permission.RequestDemoVehicle}` na 1ª | |
| PS `PS_Demo_Vehicle_Management` + `PS_Demo_Vehicle_Execution` | Atribuídos a Diego e Davi | |
| CMDT `DemoCapacityConfig__mdt` | 158 registros reais + **1 registro de TESTE `TEST_TEST_Test`** (TESTMARCA / TestSucursal / CR / MaxDemo 2 / MaxExh 0) | O TEST sai na limpeza |

**Fonte da verdade dos zips:** repo `diario-implantacao`, `deploy/HU046_flow_manage.zip`, `deploy/HU046_flow_execdemo.zip`, `deploy/HU046_faltantes/` (pacote completo sincronizado).

## 2. Mudanças de DESENHO feitas hoje (importante pra você e pra Meli)

1. **SerializedProduct SAIU do ManageDemoVehicle.** A tela exigia um SerializedProduct com SerialNumber = input (resquício das premissas antigas) e por isso "Unidad no encontrada" sempre. Modelagem correta (validada no object reference oficial): unidade = **Vehicle + Asset**; identidade = `Vehicle.VehicleIdentificationNumber` (unique + idLookup). SerializedProduct é objeto de inventário serializado (Field Service/Manufacturing), exige PSL "Industries Visit", Status restricted sem aderência — fora do desenho e fora do mapa de cargas SAP.
2. **Busca dupla nas 2 telas:** `VehicleIdentificationNumber = input` OU `Name = input` (igualdade exata; busca parcial/CBSF é evolução v2).
3. **Asignación excepcional é 100% via Task** (decisão do Diego: "o veículo é do GrupoQ"): asignar cria Task **"[Demo] Asignación" com DONO = asesor** no Vehicle — ela É a asignación. **Nenhum OwnerId de Asset/Vehicle muda** (Asset.AccountId = sociedade; Vehicle.CurrentOwnerId = dealer; intocados). Cancelar fecha a Task aberta da unidade. O scheduled fecha as vencidas (8h hábiles ≈ vence no dia útil seguinte — simplificação D9a, validar com o negócio).
4. **Campo obrigatório "Encargado de piso" na tela inicial** — vira dono da Task de solicitação (designación/liberación) e destinatário da notificação (era variável vazia → "owner cannot be blank"). v2: derivar do grupo GRP_Sucursal_*.
5. **Notificações com `targetId` = Vehicle** (obrigatório na action; clicar no sininho abre o registro).
6. Aprendizados de plataforma: **Vehicle NÃO tem OwnerId** (dono vive no Asset); deploy de flow nunca ativa (ativar na mão); rollbackOnError reverte sucessos parciais.

## 3. O que JÁ FOI TESTADO E PASSOU (06/08, Diego + Davi)

| # | Cenário | Evidência |
|---|---|---|
| T1 | Solicitar designación (VIN10001, Demo, TESTMARCA/TestSucursal, encargado Davi) com validação de cupo | Notificação "Cupo disponible: 1 de 2 en uso" no sininho do Davi + Task "[Demo] Solicitud de designación" (dono Davi) |
| T2 | Davi executou a designación na tab Ejecutar | Hilux **Status = En demostración** |
| T3 | Busca por VIN e por nome | VIN10001 encontra; validar nome na regressão |
| T4 | Asignar a asesor | Task "[Demo] Asignación" criada com dono = asesor; nenhum owner de registro mudou. SEM notificação nesse ramo (por desenho) |
| T5 | Liberación: solicitação + notificação + execução | Sininho "Solicitud de liberación..." + execução com estado destino D4 (validar T5b abaixo) |

## 4. O QUE FALTA VOCÊ TESTAR (na ordem; marcar no Plan de Pruebas — 36 casos)

**T5b — Conferir o resultado da liberación (2 queries):**
```sql
SELECT Name, VehicleIdentificationNumber, Status FROM Vehicle WHERE VehicleIdentificationNumber = 'VIN10001'
```
```sql
SELECT Name, StageName, RecordType.Name, Vehiculo__r.Name FROM Opportunity WHERE CreatedDate >= 2026-08-06T00:00:00Z
```
Esperado: Hilux = "Demo venta" (ou o estado D4 escolhido) e Opportunity RT Autos com `Vehiculo__c` = Hilux.

**T6 — Cancelación:** Vehículos Demo > Cancelar > `VIN10002` (CX-5) → a Task "[Demo] Asignación" do CX-5 vira Completed; as outras seguem abertas. (Há 3 Tasks de asignación abertas residuais: CX-5, Onix, Prueba Demo — usa elas.)

**T7 — Cupo lleno (negativo):** Solicitar designación > `VIN10002` > Demo > TESTMARCA/TestSucursal → **tela de cupo esgotado** (hoje há 3 unidades "En demostración" ≥ teto 2). Sem Task, sem notificação.

**T8 — Guarda de venta:** Opportunity manual RT GQOpportunitiesAutos vinculando o **Kia VIN10003 ("En demostración")** em Vehículo → salvar deve **bloquear com erro**. Testar com user SEM bypass (se admin tiver Bypass_Gates_Automacao, passa — isso é o teste do bypass, não defeito). Repuestos/PA com unidade demo NÃO pode bloquear (isento por RT).

**T9 — Scheduled (via Debug no Builder):** cria/edita uma Task "[Demo] Asignación" aberta com ActivityDate de ontem → Debug do `ReleaseExpiredDemoAssignments` → a vencida fecha, a de hoje fica. Atenção: Debug executa DML REAL.

**T10 — Permissões:** user sem os PS não vê as tabs (component visibility) e não executa os flows.

**T11 — Regressão:** VR `Opp_Retail_Vehiculo_Cotizacion` (HU-025) segue funcionando; fluxo de Repuestos intacto.

## 5. LIMPEZA depois do teste (obrigatória)

1. Vehicles de volta ao estado original: Hilux/CX-5/Kia/Duster → "En servicio"; Onix → "En exhibicion"; Prueba Demo → "En demostración" (era o estado pré-teste).
2. Deletar o registro CMDT `TEST_TEST_Test`.
3. Deletar as Opportunities de teste de hoje.
4. Fechar/deletar as Tasks "[Demo] ..." de teste.

## 6. Pendências pós-teste (donos)

| Pendência | Dono |
|---|---|
| Confirmações do cliente: mapeo cupos×cuentas (GWM Liberia, Terrazas, NI Managua, C105) + códigos SAP dos centros CR | GrupoQ (Isabella/Andrea) |
| Preencher BranchCode__c dos 158 cupos + regerar CMDT (fecha a HU) | Diego/IA |
| T12 fin de ciclo por km (bloqueado pela D6: MaxDemoMileage + campo odômetro) | GrupoQ → Diego |
| Wire B v2: derivar marca (BusinessBrand) e sucursal (CurrentOwnerId) nas telas; encargado default por grupo GRP_Sucursal_* | Davi/Diego (pós-carga real) |
| CBSF: filtro da busca de venda excluir Status demo/exh (Esc.10 na origem) | Davi |
| FHT Vehicle (Status/Owner) | Davi |
| Reescrever a HU no modelo Vehicle.Status + Task-based asignación + cadeia CBSF→guarda→VR | Meli |
| Validar com o negócio a simplificação das 8h hábiles (vence no dia útil seguinte) | Diego |
| Rollout GT/HN/NI/PA (contas dealer + grupos + cupos) | Admin |

## 7. Débitos de UX anotados (v2, não bloqueiam)

- Busca por igualdade exata (não parcial) → CBSF search na v2.
- Campo "Encargado de piso" aparece na tela inicial mesmo pra ações que não usam (Asignar/Cancelar).
- Sem notificação ao asesor no ramo Asignar (a HU não exige; adicionar se o negócio pedir — 5 min, mesmo padrão).
