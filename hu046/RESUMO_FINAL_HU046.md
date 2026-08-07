# HU-046 · Auto Demo/Exhibición — Resumo final (07/08/2026)

Costa Rica · sandbox DevSales · zero Apex, zero objeto custom, zero campo custom novo.

---

## 1. Visão de NEGÓCIO — o que o GrupoQ ganha

**O problema que a HU resolve:** unidades novas destinadas a demo/exhibición ficavam sem controle — sem cupo por marca/sucursal, sem rastro de quem pediu/aprovou, e com risco de serem vendidas como unidades comuns.

**Como fica com a solução:**

1. **Solicitar com cupo** — o gerente pede a designación escolhendo marca e sucursal **de listas** (só aparecem combinações que TÊM cupo configurado — impossível pedir errado). O sistema conta quantas unidades já estão em demo/exhibición e compara com o teto da tabela de cupos (ex.: "Cupo disponible: 1 de 2 en uso"). Sem cupo → solicitação barrada na hora, com transparência do número.
2. **Encargado no circuito** — quem executa a mudança física/de estado é o encargado de piso: recebe alerta no sininho (clica e abre o veículo) e uma tarefa pendente na tela dele. Nada muda de estado sem essa segunda mão.
3. **Demo não se vende "sem querer"** — unidade em demostración/exhibición é visível mas não vendível: qualquer tentativa de amarrá-la a um negócio de venda de veículos é bloqueada com mensagem clara. Três camadas: não aparece na busca de venda (CBSF, config pendente), bloqueio duro ao salvar a Opportunity, e a etapa "Reserva Confirmada" exige unidade válida.
4. **Exceção controlada de 8h úteis** — o gerente pode designar UM asesor específico para vender a unidade demo (cliente apaixonado pelo carro do showroom, p.ex.). Só ele consegue salvar essa venda, pelos próximos "8h hábiles" (= mesmo horário do dia útil seguinte; sexta vence segunda). Vence sozinho — em tempo real, sem depender de rotina noturna. Reasignar troca o asesor (o anterior perde o direito na hora); cancelar encerra. Tudo trazado em tarefas no veículo.
5. **Liberación formal para venta** — gerente solicita, encargado executa escolhendo o estado destino (sigue siendo Nuevo), e a **Opportunity do VIN nasce pronta**, já amarrada à unidade.
6. **Administração sem TI** — os cupos vivem numa tabela de configuração (158 registros, já com os códigos SAP centro+almacén). Mudou o cupo, as telas refletem sozinhas.

## 2. Visão TÉCNICA — componentes e amarrações

| Componente | Papel |
|---|---|
| **CMDT `DemoCapacityConfig__mdt`** (158 registros) | Cupo por País+Marca+Sucursal: MaxDemo, MaxExhibition, BranchCode (código SAP composto centro+almacén, ex. C0111200) |
| **Screen Flow `ManageDemoVehicle`** (tela do gerente, tab Vehículos Demo, visibility `$Permission.RequestDemoVehicle`) | 4 ramos: Solicitar / Asignar / Liberar / Cancelar. Busca a unidade no **Vehicle** por `VehicleIdentificationNumber` OU `Name` (igualdade exata). Marca/Sucursal = **dropdowns em cascata** lidos do CMDT CR (marcas deduplicadas em loop; sucursais filtradas pela marca). Campo obrigatório Encargado de piso (dono da Task + destinatário da notificação, `targetId` = Vehicle) |
| **Cupo (subflow `ValidateDemoQuota`)** | Conta Vehicles com Status alvo ("En demostración"/"En exhibicion") vs teto do CMDT. v1 conta por status global; v2 filtrará marca/sucursal derivadas (carga real) |
| **Asignación excepcional** | 100% via Task: **"[Demo] Asignación" aberta com DONO = asesor É a credencial**. Nenhum OwnerId de Asset/Vehicle muda (o veículo é do GrupoQ: `Asset.AccountId` = sociedade, `Vehicle.CurrentOwnerId` = dealer). Asignar fecha a asignación anterior (swap trazado); Cancelar fecha a Task |
| **Screen Flow `ExecuteDemoRequest`** (tela do encargado, tab própria) | Lista as Tasks "[Demo] Solicitud..." pendentes DO usuário; a unidade é **derivada da Task** (sem redigitar VIN); campos condicionais por ação. Designación: `Vehicle.Status` → En demostración/En exhibicion. Liberación: muda o Status ANTES e cria a **Opportunity RT GQOpportunitiesAutos com `Vehiculo__c`** = unidade (por isso a guarda não a bloqueia) |
| **`OpportunityBeforeHandler` v4.1** (before-save Opportunity) | Dispara se RT Autos + `Vehiculo__c` novo/alterado + sem bypass (`BypassAllocationValidation` OU `Bypass_Gates_Automacao`). Unidade demo/exh → **permite APENAS se o usuário é dono de Task "[Demo] Asignación" aberta E dentro da janela** (fórmula `isAssignmentValid`); senão custom error. Vencimento em TEMPO REAL |
| **Scheduled `ReleaseExpiredDemoAssignments`** (diário 06:00 UTC, dias úteis via fórmula WEEKDAY) | Housekeeping: fecha Tasks de asignación vencidas (a guarda já não as aceita desde o vencimento). Fórmula: `NOW() > CreatedDate + (1 dia; sexta +3; sábado +2)` — sem feriados (limitação declarada) |
| **Trazabilidade (subflow `LogDemoActivity`)** | Task padronizada no Vehicle para cada ação (solicitud, ejecución, asignación, cancelación, liberación) |
| **Permissões** | `PS_Demo_Vehicle_Management` (gerentes) / `PS_Demo_Vehicle_Execution` (encargados) + custom permissions; cadeia de object perms Vehicle→Asset→Account/Contact |

**Cadeia de enforcement da venda:** CBSF (filtro na origem — config pendente com Davi) → guarda before-save (bloqueio duro, com exceção do asesor designado) → VR `Opp_Retail_Vehiculo_Cotizacion` HU-025 (Reserva Confirmada exige unidade).

**Decisões de arquitetura registradas:** SerializedProduct/ProductItem FORA do modelo de veículos (inventário serializado/fungível de Field Service; exigem PSL extra; unidade = par Vehicle+Asset, identidade = VIN unique); estado comercial em `Vehicle.Status` (AllocationStatus é system-managed); código de sucursal = composto centro+almacén (validado em áudio pelo cliente).

## 3. COMO TESTAR (estado atual da sandbox)

**Pré-requisito:** subir e ATIVAR os 2 zips pendentes — `HU046_flow_opphandler.zip` (guarda v4.1) e `HU046_flow_manage.zip` (cascata + swap). Sem isso, os testes de exceção/dropdown abaixo não existem na org.

**Dados atuais:** TEST_TEST_Test no CMDT (TESTMARCA/TestSucursal, MaxDemo 2); Vehicles: Prueba Demo + Hilux(VIN10001, pós-liberación) + Kia(VIN10003) — conferir Status atuais antes de começar.

| # | Teste | Passos | Esperado |
|---|---|---|---|
| 1 | Dropdowns em cascata | Solicitar designación > `VIN10002` > Next | Marca = dropdown sem repetição (marcas CR + TESTMARCA); escolhida TESTMARCA → sucursal só TestSucursal |
| 2 | **Cupo lleno** | Continua o #1 com Demo | Tela de cupo esgotado (unidades "En demostración" ≥ teto 2). Sem Task, sem alerta |
| 3 | **Exceção do asesor (Esc.4)** | Asignar `VIN10003` (Kia, En demostración) a VOCÊ mesmo. Depois: Opp nova RT Autos com Vehículo = Kia > salvar | Salva (você tem a credencial). ⚠️ admin com Bypass_Gates_Automacao passa sempre — o teste que vale é com user comum |
| 4 | **Bloqueio do não-designado (Esc.10)** | Davi (sem Task, sem bypass) tenta a mesma Opp com o Kia | Custom error "unidad designada como Demo/Exhibición..." |
| 5 | **Cancelación re-arma (Esc.11)** | Cancelar asignación do Kia > repetir o save do #3 | Agora VOCÊ também é bloqueado |
| 6 | **Reasignación = swap (Esc.6)** | Asignar Kia a você; depois Asignar Kia ao Davi; query Tasks | Só UMA "[Demo] Asignación" aberta (dono Davi); a sua fechada |
| 7 | **Vencimento (Esc.5)** | Debug do `ReleaseExpiredDemoAssignments` no Builder (⚠️ DML real) com uma Task de ontem | Task de ontem fecha; a de hoje fica. Vencimento em tempo real: coberto pela fórmula da guarda (mesma regra) |
| 8 | Regressão | VR HU-025 (Opp Autos → Reserva Confirmada sem unidade = erro) + fluxo Repuestos com unidade demo NÃO bloqueia | Comportamentos preservados |
| 9 | Permissões | User sem PS | Não vê as tabs; flows inacessíveis |

**Limpeza final:** restaurar Status dos Vehicles, deletar CMDT TEST_TEST_Test, Opps de teste, Tasks "[Demo]" de teste. Aí marcar os 36 casos do `GrupoQ_HU046_Plan_de_Pruebas.xlsx` e liberar pro QA do cliente.

**Pendências que NÃO bloqueiam o teste:** CBSF filtro de venda (Davi), FHT (Davi), reescrita da HU (Meli — AllocationStatus/QuantityAvailable/regla de cotización são premissas mortas), 2 respostas do cliente (Forland PZ C211×C311, GWM Liberia), T12 km (D6), validação das "8h ≈ dia útil seguinte" com o negócio.
