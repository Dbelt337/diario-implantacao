# Lead_ValidateProductInventory_IP — build

IP read-only: dado `productCode` + `sociedad` (+ `dealerCode` opcional), resolve o
produto e retorna disponibilidade de inventário agregada. Bifurca **VEHICLE**
(status agregado por Sociedade) vs **SPARE_PART** (detalhe por almacén, sempre
SAP-live). Não cria Opportunity/Quote nem reserva estoque. Preenche
`resolvedLineItems[]` do contrato GrupoQ_LeadUpsert v1.2.

## ⚠️ Limitação do ambiente vs "REGRA DE PESQUISA (NÃO NEGOCIÁVEL)"

A regra exige pesquisar **só doc oficial Salesforce** e **DESCRIBE antes de usar
campos Industries**. Neste ambiente de build:
- Doc oficial Salesforce está **bloqueada (HTTP 403)** — não dá para "confirmar na doc".
- **Sem acesso à API da org** — DESCRIBE só o Diego consegue (Workbench).

Portanto: **nenhum nome de campo de objeto Industries é inventado.** Cada campo não
confirmado é marcado **`TODO-DOC`** e depende do DESCRIBE em DevSales.

## Status por passo

| Passo | Status |
|---|---|
| 1. Resolver produto + tipo | `DRProductResolve_1.rpt` pronto (campos nativos Product2). TODO-DOC: valor do RecordType de peça. |
| 2. Escopo de Location (Sociedade/dealer) | bloqueado — precisa DESCRIBE de Location/AssociatedLocation + o Flow `Lead_BS_DeriveSociedad` |
| 3. Inventário (VEHICLE Plano A/B; SPARE_PART SAP-live) | bloqueado — Named Credential MuleSoft + endpoint + sintaxe de cache IP + `FeatureFlag__mdt` |
| 4. Montar response `resolvedLineItems[]` | depende dos passos 2/3 |

## Preciso de você (DESCRIBE + decisões)

1. **DESCRIBE**: `Product2` (RecordType de peça), `ProductItem` (`QuantityOnHand`,
   `Product2Id`, FK de Location), `Location`, `AssociatedLocation` (caminho até
   `Account`), `BusinessProfile` (`ExternalReferenceNumber`, `AccountId`).
2. **MuleSoft**: nome do Named Credential + path da System API de inventário.
3. **D1**: criar `FeatureFlag__mdt` (default Plano A) — confirmar nome do CMDT/campo.
4. **`Lead_BS_DeriveSociedad`**: retrieve do Flow para compor a cascata de Sociedade.
