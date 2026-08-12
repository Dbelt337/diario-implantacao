# Roteiro de teste — robustez do fluxo guiado (12/08/2026) + hand-off Davi

Pacote: `deploy/deploy-robustez-flujo-guiado.zip`. Pré-requisito: sandbox com o
pacote da US-021 já deployado (feito em 11/08).

## A. Deploy e testes unitários

1. Workbench → migration → Deploy → zip, com **Single Package** e **Rollback on Error**.
2. Setup → Apex Test Execution → rodar `MaterialCreationServiceTest`.
   Esperado: **7 testes verdes** (a action de Flow foi removida por decisão de escopo em 12/08 — o teste dela saiu junto), incluindo os 2 novos
   (`reutilizaProductoLegadoYRellenaCodigoSap`, `busquedaDelFlujoEncuentraYRespetaElMinimo`).
3. Rodar a suíte completa da venta guiada (as 7 classes de teste) — nada regride.

## B. Roteiro de UI (mockMode ligado)

Antes: atribuir o permission set **PS_Create_SAP_Material** ao usuário de teste
(Setup → Permission Sets → Manage Assignments).

| # | Passo | Esperado |
|---|-------|----------|
| 1 | Abrir cotização Repuestos & PA com o grid `lineasRepuestos` e digitar 3+ caracteres de um material **existente** no campo Código | Dropdown de sugestões aparece (após ~300 ms de pausa); com 2 caracteres, nada acontece |
| 2 | Clicar numa sugestão | Código preenche o campo; "Agregar línea" põe no grid |
| 3 | Digitar um código **inexistente** (ex.: `ZZZ-TEST-001`) | Aviso "«ZZZ-TEST-001» no está en el catálogo" + botão **Solicitar creación de material** |
| 4 | Clicar em Solicitar creación e confirmar **sem** serie | Toast de aviso "Serie requerida" — não chama SAP |
| 5 | Preencher serie (ex.: `D22`) e confirmar | Toast de sucesso; a linha **entra no grid automaticamente** e a disponibilidade é consultada |
| 6 | Repetir a criação do mesmo código (buscar de novo → não vai dar miss; forçar via carga masiva + botão da linha) | Nunca nasce um segundo Product2 (ver consulta C1) |
| 7 | **Carga masiva** com um código inexistente no meio (ex.: `REP-001, 2` + `ZZZ-TEST-002, 5`) → Consultar → Guardar | Toast lista `ZZZ-TEST-002` como *sin catálogo*; a linha fica marcada e mostra o botão **Crear material** — a porta da US-021 para o caminho da carga masiva |
| 8 | Usuário **sem** o permission set clica em criar | Erro claro citando a permission `CreateSapMaterial` — sem stack trace |
| 9 | **Concorrência** (smoke): duas abas na mesma cotização aceita, clicar "Generar pedido" nas duas quase ao mesmo tempo | Uma só Order nasce (ver C2); a segunda aba recebe o pedido existente |

Observação: o caminho de **rejeição SAP → Case** não é acionável na UI com o
mock atual (o mock só rejeita campo faltante, e a UI bloqueia isso antes).
Ele está coberto pelo teste unitário `rechazoSapAbreCasoConMensajeCrudo`
(HttpCalloutMock com `ok:false`) e será testável de ponta a ponta quando o
contrato Mule real entrar.

## C. Consultas de verificação (Developer Console → Query Editor)

```sql
-- C1: um único produto por material, com o external id preenchido (backfill)
SELECT Id, ProductCode, SapMaterialCode__c, IsActive
FROM Product2 WHERE ProductCode LIKE 'ZZZ-TEST%'

-- C2: um único pedido por cotização (lock FOR UPDATE funcionando)
SELECT COUNT() FROM Order WHERE QuoteId = '0Q0...'

-- C3: caso aberto no teste de rejeição (só via teste unitário por ora)
SELECT Subject, Description FROM Case
WHERE Subject LIKE 'Creación de material SAP rechazada%'
```

---

## Mensagem pronta para o Davi (copiar/colar)

> Davi — subí un paquete de robustez del flujo guiado (rama del diario:
> `deploy/deploy-robustez-flujo-guiado.zip`). Qué cambia y qué sigue contigo:
>
> **Qué entra:**
> 1. La creación de material (US-021) ahora vive DENTRO del flujo: el campo
>    de código del grid de Repuestos busca el catálogo mientras se teclea
>    (`GuidedSellingController.searchMaterials` → `MaterialSearchService`,
>    debounce 300 ms / mínimo 3 caracteres). Si no encuentra, el asesor pide
>    la creación ahí mismo y la línea entra al grid al confirmarse. El botón
>    "Crear material" de la línea sinCatalogo queda para el camino de la
>    carga masiva (GQ-PV-02-001-4), que no pasa por la búsqueda.
> 2. Concurrencia: locks `FOR UPDATE` en `QuoteOrderService.createOrderFromQuote`
>    (doble clic ya no genera dos pedidos Z301) y en
>    `RepuestosLineService.guardarLineas` (dos guardados simultáneos se
>    serializan). Referencia: Locking Statements del Apex Dev Guide.
> 3. Campo nuevo `Product2.SapMaterialCode__c` (Text 18, único, External ID) y
>    `Database.upsert` por ese campo en `MaterialCreationService`: la base de
>    datos garantiza UN Product2 por material; los legados de la réplica se
>    reutilizan con backfill del código.
>
> **Para seguir con la HU:**
> - Deploy del zip + correr `MaterialCreationServiceTest` (7 verdes — la action de Flow se removió por decisión de alcance) y la suite.
> - Asignar `PS_Create_SAP_Material` a los perfiles piloto.
> - Cuando cierre el contrato Mule con Flavio: apagar `SapMuleClient.mockMode`,
>   implementar la pierna SAP de `MaterialSearchService` (y en ese momento
>   `searchMaterials` DEBE dejar de ser cacheable o migrar a Continuation —
>   está anotado en el código), y migrar `checkRepuestosAvailability` a
>   Continuation como `SapInventoryService` (límite de transacciones largas
>   concurrentes con varios asesores consultando).
> - Ruteo del Case de rechazo (cola/record type del área) — hoy nace genérico.
> - El precio 0 placeholder de las PricebookEntries se reemplaza con el
>   catálogo de precios (US-024/US-025).
>
> Roteiro de prueba completo en el diario:
> `docs/roteiro-teste-robustez-2026-08-12.md`.
