# Repuestos & PA — roteiro exato de teste + mapa de integrações (remoção dos mocks)

**Data:** 12/08/2026 · Estado da org: pacotes HU-043 + US-021 + robustez deployados; `CreateSapMaterialAction` removida (escopo estrito).

---

## PARTE 1 — Roteiro exato de teste do fluxo de repuestos

### Passo 0 — Pré-requisitos (uma vez)

1. **Permission set:** Setup → Permission Sets → `PS_Create_SAP_Material` → Manage Assignments → seu usuário.
2. **Cotização de teste:** oportunidade com Record Type `GQOpportunitiesRepuestosPA` → nova Quote → associar um Pricebook (o padrão serve).
3. **Expor o componente:** abrir a Quote → engrenagem → **Edit Page** → arrastar `lineasRepuestos` (seção Custom) para a página → nas propriedades do componente preencher:
   - `companyCode` = `C101` · `canal` = `Q1` · `plant` = `Q1CS` (ou o centro que usarem)
   - `pricebookId` = Id do pricebook da quote — pegar no Developer Console: `SELECT Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Id = '<ID_DA_QUOTE>'`
   - `currencyIsoCode` = a moeda que a query devolveu
   - Save → Activate.
   > No fluxo final os hosts (`ventaPA`/`contraventaRepuestos`) passam esses valores sozinhos — a record page é só o harness de teste. Se `pricebookId` ficar vazio, **toda** linha aparece como *sin catálogo* (o serviço não adivinha a lista de preços).

### Passo 1 — Seed do catálogo (Developer Console → Execute Anonymous)

```apex
// SEED de teste: 5 repuestos no catálogo local + entradas de preço.
// Trocar 0Q0... pelo Id da quote de teste. Rodar UMA vez.
Quote q = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Id = '0Q0XXXXXXXXXXXX'];
Id std = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

List<Product2> prods = new List<Product2>();
for (Integer i = 1; i <= 5; i++) {
    prods.add(new Product2(Name = 'Repuesto demo ' + i, ProductCode = 'REP-00' + i,
        SapMaterialCode__c = 'REP-00' + i, IsActive = true));
}
insert prods;

List<PricebookEntry> pbes = new List<PricebookEntry>();
for (Product2 p : prods) {
    pbes.add(new PricebookEntry(Pricebook2Id = std, Product2Id = p.Id,
        UnitPrice = 100, IsActive = true, CurrencyIsoCode = q.CurrencyIsoCode));
}
insert pbes;

if (q.Pricebook2Id != null && q.Pricebook2Id != std) {
    List<PricebookEntry> lista = new List<PricebookEntry>();
    for (Product2 p : prods) {
        lista.add(new PricebookEntry(Pricebook2Id = q.Pricebook2Id, Product2Id = p.Id,
            UnitPrice = 100, IsActive = true, UseStandardPrice = false,
            CurrencyIsoCode = q.CurrencyIsoCode));
    }
    insert lista;
}
System.debug('Seed OK: 5 repuestos REP-001..REP-005 no catálogo.');
```

> A busca-enquanto-digita usa SOSL: registros recém-inseridos levam alguns
> segundos/minutos para entrar no índice de busca. Se as sugestões não
> aparecerem de imediato, espere um minuto e tente de novo.

### Passo 2 — Roteiro na tela (na ordem; resultados exatos do mock)

O mock de disponibilidade é **determinístico por posição do lote**: linha n recebe piso 10−(n−1), reserva 2(n−1), saldo = piso − reserva.

| # | Ação | Resultado exato esperado |
|---|------|--------------------------|
| 1 | Digitar `REP` no campo Código (3 caracteres) e pausar | Dropdown com os 5 repuestos demo (código + nome). Com `RE` (2 chars), nada |
| 2 | Clicar em `REP-001` → Agregar línea | Linha entra no grid como "Sin consultar" |
| 3 | **Carga masiva** → colar as 4 linhas abaixo → Cargar líneas:<br>`REP-002, 1`<br>`REP-003, 1`<br>`REP-004, 1`<br>`REP-005, 1` | Grid com 5 linhas, todas "Sin consultar" |
| 4 | **Consultar disponibilidad** | REP-001: saldo **10** (piso 10/reserva 0) → `Disponible` · REP-002: **7** → `Disponible` · REP-003: **4** → `Disponible` · REP-004: **1** → `Disponible` · REP-005: **−2** → `No Disponible`, leyenda "sin saldo — piso comprometido por reservas" |
| 5 | Mudar a cantidad de REP-004 para `5` | Estado da linha volta para "Sin consultar" (modificação exige revalidação — GQ-PV-02-019) |
| 6 | Consultar de novo | REP-004 (saldo 1 < cantidad 5) → **`Parcial`** |
| 7 | Marcar **Venta Perdida** em REP-005 | Badge vermelho "Venta Perdida" na linha |
| 8 | **Guardar en cotización** | Toast: `4 creadas · 0 actualizadas · 0 eliminadas · 1 venta(s) perdida(s) trazada(s)` |
| 9 | Digitar `ZZZ-TEST-001` no campo Código e pausar | Aviso "«ZZZ-TEST-001» no está en el catálogo" + botão **Solicitar creación de material** |
| 10 | Solicitar creación → Confirmar **sem** serie | Toast "Serie requerida" — não chama SAP |
| 11 | Preencher serie `D22` → Confirmar | Toast de sucesso do mock; a linha **entra no grid sozinha** e a disponibilidade é reconsultada (atenção: a consulta é por posição — os saldos do lote mudam ao crescer a lista, é o mock) |
| 12 | Carga masiva com `ZZZ-TEST-002, 3` → Consultar → Guardar | Toast marca `ZZZ-TEST-002` como *sin catálogo*; a linha fica rosada com botão **Crear material** — criar por ali (porta da carga masiva) |
| 13 | Remover o permission set do usuário e tentar criar de novo | Erro claro citando `CreateSapMaterial`, sem stack trace |
| 14 | **Concorrência** (smoke): duas abas na mesma quote, "Guardar" quase junto nas duas | Nenhuma linha some/duplica (lock `FOR UPDATE` serializa); conferir com a query V2 |

### Passo 3 — Verificação (Query Editor)

```sql
-- V1: linhas gravadas na cotização com estado e detalhe
SELECT Product2.ProductCode, Quantity, AvailabilityStatus__c, AvailabilityDetail__c
FROM QuoteLineItem WHERE QuoteId = '0Q0XXXXXXXXXXXX'
-- esperado: REP-001..REP-004 (REP-005 NÃO — venta perdida não vira línea)

-- V2: um único produto por material criado, com o external id preenchido
SELECT Id, ProductCode, SapMaterialCode__c, IsActive
FROM Product2 WHERE ProductCode LIKE 'ZZZ-TEST%'

-- V3: traza da venta perdida na descrição da quote
SELECT Description FROM Quote WHERE Id = '0Q0XXXXXXXXXXXX'
```

### O que NÃO dá para testar com o mock (honesto)

- **`Otro Centro` / `Otra Sociedad`:** o estado deriva do texto de existência do SAP (ZHYB_DBM_TEXTO_EXISTENCIA), e o mock nunca devolve esses textos. Testável só com o Mule real.
- **Rejeição SAP → Case:** o mock só rejeita campo faltante e a UI bloqueia isso antes. Coberto pelo teste unitário `rechazoSapAbreCasoConMensajeCrudo`; ponta a ponta só com o Mule real.

---

## PARTE 2 — Onde implementamos as integrações e removemos os mocks

### O interruptor

**Tudo converge num ponto só:** `SapMuleClient.cls`, linha ~38:

```apex
@TestVisible public static Boolean mockMode = true;   // → false no go-live da integração
```

Cada método da fachada já tem os **dois ramos escritos**: `if (mockMode) {...}` e o ramo real com endpoint mapeado via Named Credential (`callout:MuleGateway`). Virar a chave não muda nenhum consumidor — controller, serviços e LWC ficam intactos. Esse foi o motivo da fachada.

### Mapa: RFC/WS SAP → método → endpoint real → quem consome

| RFC / WS SAP | Método em `SapMuleClient` | Endpoint (Named Credential `MuleGateway`) | Consumidor |
|---|---|---|---|
| CONSULTA_MATERIALES (massivo) + ZHYB_DBM_TEXTO_EXISTENCIA | `consultaMateriales` | `POST /api/v1/materials/query` | `RepuestosLineService` (consultar/revalidar) |
| ZQEV_DBM_CREACION_MATERIALES (WS ZWS_CREACION_MATERIALES) | `creacionMateriales` | `POST /api/v1/materials` | `MaterialCreationService` (US-021) |
| ZHYB_DBM_COTIZA_REP_RFC | `cotizarRepuestos` | `POST /api/v1/parts-quotes` | cotización DBM de repuestos |
| ZHYB_DBM_MOD_DET_ORDEN / ZHYB_DBMPOSICIONES | `modificarPosicionesOrden` | `PATCH /api/v1/parts-orders/{doc}/lines` | modificação de posições do pedido |
| ZHYB_DBM_DESCUENTO_DE_VENDEDOR | `descuentoVendedor` | `GET /api/v1/seller-discounts` | tope de desconto (cadência: decisão aberta) |
| ZQEV_ASIG_CLIENTE / ZQEV_MONEDA_CLIENTE | `asigCliente` / `monedaCliente` | `POST /api/v1/customers/...` | pré-requisitos do pedido |
| Ordem Z301 (simulate + create) | `simulateSalesOrder` / ordem | `POST /api/v1/orders/simulate` · `/api/v1/orders` | `SapOrderService` |
| Busca de catálogo no SAP | `MaterialSearchService` perna 2 | `GET /api/v1/materials/search` | **pendente implementar** (bloco comentado na classe) |
| IDocs de retorno (ordem confirmada, fatura) | — não passam pela fachada | Mule **publica** `SapOrderResponse__e`; fatura entra por update inbound na Order | flows `SAP_Order_Response_Handler` / `Order_Facturado_Handler` (já deployados) |

### Checklist do go-live da integração (ordem de execução)

1. **Contrato Mule (Flavio):** cada endpoint acima deve responder no formato dos DTOs documentados em `SapMuleClient` (o mapa RFC→endpoint está no cabeçalho da classe). Mule normaliza o MENSAJE CHAR255 da criação para `ok + mensaje`.
2. **Credenciais:** Setup → Named Credentials → `MuleGateway` → apontar a URL do gateway real; `MuleSoft_EC` (External Credential) → client id/secret reais. Atribuir `PS_Mule_Integration` a quem dispara callouts.
3. **Virar a chave:** `SapMuleClient.mockMode = false`. Os blocos `if (mockMode)` viram código morto — **remover só depois** do contrato estabilizar, e ao remover, migrar os testes que dependem do mock default (ex.: sucesso do `MaterialCreationServiceTest`) para `Test.setMock` com `SapCalloutMockFactory`, que já existe.
4. **`checkRepuestosAvailability` → Continuation** (obrigatório, mesma release da chave): hoje a consulta é callout síncrono — com Mule real, cada consulta segura uma transação Apex o round-trip inteiro e o limite de transações longas concorrentes vira risco com vários assessores. Padrão pronto na base: `SapInventoryService.getPricesAndInventory`.
5. **Perna SAP da busca:** implementar o bloco comentado em `MaterialSearchService` (perna 2) e, no mesmo commit, tirar o `cacheable=true` de `GuidedSellingController.searchMaterials` ou migrá-lo a Continuation (callout é proibido em cacheable — anotado no código).
6. **Backfill:** `SapMaterialCode__c = ProductCode` em massa nos Product2 legados (Data Loader/batch) para a unicidade do banco valer para todo o catálogo, não só para os criados pela US-021.
7. **Inbound (lado Mule):** publicar `SapOrderResponse__e` e o update de fatura na Order com o usuário de integração — os handlers do lado Salesforce já estão deployados.
8. **FinancingService → CrediQ:** quando o front financeiro fechar o contrato, converter `getFinancingOptions` em Continuation (anotado no código; call site do LWC não muda).
