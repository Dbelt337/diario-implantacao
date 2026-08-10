# LeadLineItem — object reference + conversão (colado pelo Diego 10/08)

Automotive Cloud, API 56+. Suporta CRUD/upsert; change events, feed, **history**.

## Campos (API names reais)
| Campo | Tipo | Nota |
|---|---|---|
| `LeadId` | lookup Lead (req) | pai |
| `Name` | string (req) | nome do item |
| `ProductId` | lookup **Product2** | relationship `Product` — a peça/veículo/serviço do catálogo |
| `Quantity` | double | unidades de interesse |
| `UnitPrice` | currency | preço unitário |
| `ItemType` | picklist restrita | **Accessory / Part / Service / Vehicle** |
| `InterestType` | picklist restrita | **Buy / Lease / Sell / TestDrive / TradeIn** |
| `Classification` | picklist restrita | New / Used / Refurbished |
| `Condition` | picklist restrita | Excellent/Good/Fair/Poor/Unknown |
| `PriceType` | picklist restrita | MSRP / QuotePrice / OfferPrice / AskingPrice / InvoiceCost / AppraisedCost |
| `ApprovalStatus` | picklist restrita | Approved/In Review/On Hold/Rejected |
| `AssetIdentificationNumber` | string | **VIN/serial da unidade específica** — usado quando o lead VENDE ou faz TRADE-IN do veículo dele (doc explícita) |

## Conversão LLI→OLI (nativa) — REQUISITOS (da release note + help)
1. Automotive Cloud **+ Partner Lead Management habilitado** (edição Enterprise+).
2. Usuário com **permission set "Partner Lead Management"**.
3. **Mapeamentos criados via `ObjectHierarchyRelationship` (Metadata API)** — help "Create and Deploy Mappings for Automotive Lead Management" (campos custom mapeiam também). "Converte automaticamente **se as configurações requeridas estão definidas**".
4. Produto **ativo e associado ao STANDARD price book ativo** (nota do help de criação).
5. UI: related list **Products** no layout do Lead.
6. Alternativa programática: Connect API `/connect/manufacturing/transformations` (POST, usageType TransformationMapping, LeadLineItem→OpportunityLineItem; `CurrencyIsoCode` obrigatório no default em org multimoeda!).

## Encaixe GrupoQ (decidido 10/08)
- Portal cria Lead + LeadLineItems (peça com match no catálogo: ProductId + ItemType=Part/Accessory + InterestType=Buy; qtd/preço quando houver).
- `RequestedParts__c` = captura BRUTA do texto do form + fallback sem match (→ hand-off solicitar material HU-039; nunca auto-provisionar material SAP).
- Conversão nativa → OLIs → `createQuotesSingleVehicle` consome (OLI→QLI, já implementado).
- **Trade-in/venda do carro do cliente: VIN vai em `AssetIdentificationNumber` do LLI (InterestType=TradeIn/Sell)** — refina a discussão VIN/Placa: p/ trade-in o lugar doc-correto é o line item; os campos Lead-level VIN/Placa do Tiago ficam p/ o contexto repuestos (veículo do cliente que RECEBE peças, que não é "item de interesse").
- Multimoeda: transformação exige CurrencyIsoCode default — atenção no mapping.
## Pendências
- Check org: Partner Lead Management habilitado? PS atribuída?
- Diego colar help **"Create and Deploy Mappings for Automotive Lead Management"** (p/ autorar o ObjectHierarchyRelationship sem inventar schema).
