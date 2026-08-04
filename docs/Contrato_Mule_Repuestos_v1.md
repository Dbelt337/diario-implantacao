# Contrato Experience API — Repuestos (proposta Salesforce para validação MuleSoft)

Versão 1 — 05/08/2026 — Diego Beltrão (Sales) para Flavio Medeiros (MuleSoft)

Dois serviços na Experience API, consumidos pelo Salesforce via Named Credential
(OAuth 2.0 client credentials). Base URL e credenciais por ambiente, fora do código.

## Serviço 1 — Busca de catálogo (browse, cacheável)

Uso: tela de venda guiada, busca por texto digitado (mínimo 3 caracteres).
Cache de catálogo no Mule (TTL sugerido: 15 min). Filtro e paginação no servidor.

```
GET /api/v1/materials/search
    ?term={texto}            (obrigatório, min 3 chars)
    &companyCode={sociedad}  (obrigatório, ex.: C101)
    &plant={centro}          (opcional; filtra estoque por bodega)
    &page={n}                (default 1)
    &pageSize={n}            (default 50, máx 200)
```

Resposta 200:
```json
{
  "page": 1,
  "pageSize": 50,
  "total": 137,
  "items": [
    {
      "productCode": "FIL-001",
      "name": "Filtro de aceite TIGGO 4 PRO",
      "brand": "CHERY",
      "group": "Filtros",
      "stock": [
        { "plant": "C101", "quantity": 12 },
        { "plant": "C105", "quantity": 3 }
      ]
    }
  ]
}
```

Sem preço neste serviço (preço é transacional, Serviço 2).

## Serviço 2 — Preço e estoque transacional (nunca cacheável)

Uso: momento de cotizar. Encapsula o RFC de preços (Get_Price_ZGQREF / RN-18).
O DTO abaixo já está implementado no Apex (SapInventoryService) — request/response
exatamente nesta forma.

```
POST /api/v1/prices-and-inventory
Content-Type: application/json
```

Request:
```json
{
  "productCode": "FIL-001",
  "companyCode": "C101",
  "plant": "C101",
  "customerCode": "0001234567",
  "quantity": 2
}
```

Resposta 200:
```json
{
  "productCode": "FIL-001",
  "unitPrice": 150.00,
  "currencyIsoCode": "USD",
  "availableQuantity": 12,
  "plant": "C101",
  "errorMessage": null
}
```

## Erros (ambos os serviços)

- 4xx/5xx com corpo `{ "error": "texto" }`; o Salesforce exibe mensagem amigável
  e não repete automaticamente.
- Timeout do lado Salesforce: 60 s (Continuation).

## Segurança

- OAuth 2.0 client credentials (token endpoint no Mule/gateway).
- Um client id/secret por org Salesforce (DevSales, UAT, Prod).

## Pendências para o Flavio

1. Validar caminhos/nomes dos recursos e o shape dos payloads.
2. Confirmar viabilidade do cache de catálogo no Mule e TTL.
3. URL base e token endpoint do sandbox + client id/secret (DevSales).
4. Alinhar se o Serviço 2 cobre também PA por canal (campo customerCode/canal).
