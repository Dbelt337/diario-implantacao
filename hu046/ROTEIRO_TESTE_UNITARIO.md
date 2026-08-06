# HU-046 — Roteiro de teste unitário (texto, passo a passo)

Sandbox DevSales · executar antes de liberar para validação do cliente e QA.
Planilha com os 36 casos formais: `GrupoQ_HU046_Plan_de_Pruebas.xlsx` (use-a para registrar PASA/FALLA + evidência).

## Etapa 0 — Pré-condições (15 min, uma vez)

1. Suba os 2 zips pendentes: `HU046_flow_opphandler.zip` (v3) e `HU046_flow_execdemo.zip`.
2. Ative os flows NESTA ordem (Setup > Flows > abrir > Activate):
   `Validate Demo Quota` e `Log Demo Activity` (subflows) → `Flow Trigger: Opportunity Before Handler` → `Scheduled: Release Expired Demo Assignments` → as 2 telas.
3. Crie os dados de teste (prefixo DEMO-TEST para achar e limpar depois):
   - 4 Vehicles: `DEMO-TEST-001` Status = En ubicación de concesionario · `002` = En demostración · `003` = En exhibicion (SEM acento) · `004` = En servicio.
   - 1 registro CMDT `DemoCapacityConfig.TEST_TEST_Test` com MaxDemo=1, MaxExhibition=0 (Setup > Custom Metadata Types > Manage Records).
   - 1 Account de teste.
4. Prepare 4 acessos: U1 gerente (PS Demo Vehicle Management), U2 encargado (PS Demo Vehicle Execution), U3 vendedor (sem PS demo), U4 com `Bypass_Gates_Automacao`. Em sandbox, dá para simular com "Login As".
5. Publique as 2 App Pages (Manage com component visibility `{!$Permission.RequestDemoVehicle}`).

## Etapa 1 — A guarda (o coração; 15 min, casos OBH)

Teste PRIMEIRO a guarda, porque protege tudo o mais:
1. Como U1/U3: nova Opportunity RT **GQOpportunitiesAutos**, Vehiculo__c = DEMO-TEST-**002** → deve dar o erro "Esta unidad está designada como Demo/Exhibición..." e NÃO salvar.
2. Repita com **003** (En exhibicion) → bloqueia igual (valida o API name sem acento).
3. Repita com **004** (En servicio) → salva normal.
4. Edite a Opp salva e troque Vehiculo__c para 002 → bloqueia na troca.
5. Numa Opp que JÁ tem unidade demo vinculada (crie via U4), edite só o valor/data → salva (a guarda não re-dispara em edição alheia).
6. Nova Opp RT **GQOpportunitiesRepuestosPA** com Vehiculo__c = 002 → SALVA (peças para unidade demo é legítimo — isenção por record type).
7. Como U4 (bypass): Opp Autos com 002 → salva. É o mesmo bypass dos gates da HU-025.

## Etapa 2 — Ciclo feliz completo de ponta a ponta (20 min, MDV + EDR)

O caminho que o cliente vai validar — solicitar → executar → liberar → vender:
1. **U1 (gerente)** na página "Vehículos Demo": Solicitar designación, VIN DEMO-TEST-001, tipo Demo, marca/sucursal do cupo TEST.
   Verifique: Task "[Demo] Solicitud..." criada para o encargado + notificação + Task de traza. O Vehicle NÃO muda de status ainda.
2. **U2 (encargado)** na página Execute Demo Request: a solicitação aparece na lista (e SÓ as dele). Executa a designação.
   Verifique: Vehicle.Status = En demostración; Task da solicitação Completed; traza criada.
3. **U1**: Solicitar liberación da mesma unidade → Task para U2.
4. **U2**: executa a liberação, destino "En ubicación de concesionario".
   Verifique (o caso mais rico do teste): Status atualizado; **Opportunity criada** RT GQOpportunitiesAutos com Vehiculo__c = a unidade, Stage Prospecting, CloseDate +30; Task fechada; traza. E a guarda NÃO bloqueou (o status muda antes da Opp — se bloquear, a ordem dos elementos foi alterada).
5. Repita a liberação com outra unidade e destino "Demo venta": Status = Demo venta e **ConditionType permanece Nuevo**.

## Etapa 3 — Os limites (15 min)

1. **Cupo cheio**: com o CMDT TEST (MaxDemo=1) e 1 unidade já em demo, peça a 2ª designação → mensagem de cupo indisponível, nenhuma Task criada.
2. **Sem cupo configurado**: marca/sucursal inexistente no CMDT → mensagem amigável, não erro técnico.
3. **VIN errado**: "NO-EXISTE" nas duas telas → tela de "no encontrado".
4. **Asignar/Cancelar**: atribua um asesor (SerializedProduct.OwnerId muda + traza) e cancele (owner reverte, nada mais muda).

## Etapa 4 — Scheduled e permissões (15 min)

1. **ReleaseExpiredDemoAssignments**: crie/edite uma Task "[Demo] Asignación" aberta com data de ontem → rode o flow via Debug no Builder → Task deve fechar. Uma Task de HOJE deve permanecer aberta. Se der, teste a virada de fim de semana (sexta → expira segunda, fórmula WEEKDAY).
2. **Visibilidade**: U3 não vê a página de gerência (component visibility) e não executa nada. U1 vê Manage mas não precisa de Execute. U2 executa tudo sem erro de permissão.

## Etapa 5 — Regressão (10 min, NÃO PULAR)

Mexemos no terreno da HU-025 e de Repuestos — provar que nada quebrou:
1. Opp Autos → estágio "Reserva Confirmada" SEM Vehiculo__c → erro da VR `Opp_Retail_Vehiculo_Cotizacion` (comportamento antigo intacto).
2. Opp Autos → "Cotización Confirmada" sem produto → erro da VR.
3. Fluxo de Repuestos/PA com a búsqueda de vehículo → Vehiculo__c poblado normalmente, sem interferência.

## Avisos que evitam sustos

- O **Debug de screen flow executa DML real** (cria Task, muda Vehicle) — só usar unidades DEMO-TEST.
- Para ensaiar o handler sem sujar dados: Debug do flow com "rollback mode".
- Os API names dos status são literais: `En demostración` COM acento, `En exhibicion` SEM. Se alguém "corrigir" o acento no picklist, os flows quebram silenciosamente (fórmulas fx_Estado*).
- Em produção: flows sobem INATIVOS por default (ativar à mão no release). Deploy "ativo" exigiria 75% de flow test coverage — decisão do plano de release.
- Ao terminar: apagar os dados DEMO-TEST e o registro CMDT TEST_TEST_Test (destructive ou à mão).

## Critério de saída

36 casos PASA na planilha (ou falha documentada com defeito) → libera para validação do cliente e QA.

---
Estado da HU (06/08): desenvolvimento 100% construído; planilhas de dados (mapeo cupos×cuentas + códigos SAP) JÁ ENVIADAS ao cliente — quando responder, preenchemos BranchCode__c, fechamos o de-para e a HU termina (restam só cliques de Setup do runbook e este teste).
