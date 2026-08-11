# Classes de teste — Venta Guiada / pedido SAP (11/08/2026)

Pacote de deploy em `deploy/deploy-testes-venta-guiada/` (zip enviado ao Diego).
Escrito conforme a documentação oficial de Apex Testing: `@isTest` em tudo,
dados criados no próprio teste (nunca `SeeAllData`), `@TestSetup` +
`VentasTestDataFactory`, callouts sempre mockados (`HttpCalloutMock` /
`Test.setContinuationResponse`), `Test.startTest/stopTest` para executar
Queueables, asserts com mensagem (`Assert.*`), caminhos positivo, negativo,
bulk e idempotência.

## Conteúdo do pacote (7 classes)

| Classe | Tipo | Cobre |
|--------|------|-------|
| `QuoteOrderServiceTest` (novo) | 10 testes | `createQuotesSingleVehicle` (happy path com payload completo, payload ilegível, fallback por seleção, sem oportunidade, resolveDefaultPricebook + erro sem veículos), `createOrderFromQuote` (criação, idempotência, 3 erros), `sendOrderToSap` |
| `SapOrderServiceTest` (novo) | 5 testes | Queueable em mock (Confirmado SAP + Z301), modo real com `HttpCalloutMock` (sucesso, HTTP 500 → Error SAP, ok=false → Error SAP), pedido inexistente |
| `SapMuleClientTest` (novo) | 13 testes | Todos os métodos RFC em mock (incl. saldo negativo TDET_SALDOS) + transporte real: POST/GET/PATCH com mock, HTTP 404 → exceção |
| `GenerateSapOrderActionTest` (novo) | 2 testes | Contrato bulk do invocable (1 Result por Request, erro por linha não quebra o lote), idempotência |
| `PricingServiceTest` (novo) | 2 testes | Contrato do skeleton (resultado nunca nulo) + DTO |
| `GuidedSellingControllerTest` (atualizado) | 9 testes | Stubs, continuation, `createQuote`/`createOrderFromQuote` felizes + `AuraHandledException` |
| `VentasTestDataFactory` (atualizado) | factory | Conta com `Country__c` (obrigatório), Opp com `PreferredContactMethod__c` (VR Autos/Motos) e pricebook standard, produto+`VehicleDefinition`, PBEs, quote com linha |

Já existentes e mantidos: `FinancingServiceTest`, `MaterialSearchServiceTest`,
`SapInventoryServiceTest` (continuam valendo cobertura).

## Como rodar / deploy

```bash
# deploy só das classes de teste, rodando a suíte do escopo:
sf project deploy start --metadata-dir deploy-testes-venta-guiada \
  --test-level RunSpecifiedTests \
  --tests QuoteOrderServiceTest --tests SapOrderServiceTest \
  --tests SapMuleClientTest --tests GenerateSapOrderActionTest \
  --tests PricingServiceTest --tests GuidedSellingControllerTest \
  --tests FinancingServiceTest --tests MaterialSearchServiceTest \
  --tests SapInventoryServiceTest

# cobertura por classe depois do run:
sf apex run test --tests QuoteOrderServiceTest ... --code-coverage --result-format human
```

## Bugs reais encontrados ao escrever os testes

1. **`GuidedSellingControllerTest` (versão da org) não compila** contra o
   controller atual: chamava `createQuote(null, '{}')` com 2 argumentos e a
   assinatura tem 3. Corrigido na versão deste pacote.
2. **`VentasTestDataFactory.createAccount()` quebrava em qualquer teste**:
   `Account.Country__c` é obrigatório na org e não era preenchido. Corrigido.
3. **`provisionAccessoriesAndBuildLines` (QuoteOrderService) é intestável
   como está**: consulta `Pricebook2 WHERE IsStandard = true` por SOQL, que
   retorna vazio em contexto de teste sem `SeeAllData` (documentado; por isso
   existe `Test.getStandardPricebookId()`). Em teste, acessório fora do
   catálogo → `QueryException`. Sugestão de patch de 1 linha ao Davi:
   `Id stdId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;`
   Os testes atuais evitam esse caminho (acessórios sempre no catálogo);
   com o patch, dá para cobrir a auto-provisão também.

## Sobre os 75%

- Cobertura projetada por classe (a confirmar com o run na org):
  `SapMuleClient` ~95% (todos os métodos + os dois modos), `SapOrderService`
  ~100%, `GenerateSapOrderAction` ~100%, `PricingService` 100%,
  `GuidedSellingController` >85%, `QuoteOrderService` ~80% (fica de fora a
  auto-provisão de acessórios — item 3 acima — e o bloco comentado não conta).
- O gate de produção são **75% org-wide + toda trigger coberta**; rodar com
  `--code-coverage` e conferir por classe, não só a média.
- Risco conhecido: `VehicleDefinition` (Automotive Cloud) criado na factory —
  se a org exigir campos além de `Name`/`ProductId`, o erro aparece no
  primeiro run; ajustar a factory (1 método) resolve para a suíte inteira.
