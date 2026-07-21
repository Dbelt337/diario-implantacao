# Estrutura do Catálogo — GrupoQ (5 linhas de negócio)

Linhas: **Autos Novos**, **Autos Usados**, **Motos**, **Frotas**, **Repuestos e PA**.
Native-first, fundamentado nos objetos nativos de catálogo do Automotive Cloud.

> ⚠️ **RESTRIÇÃO CONFIRMADA (Diego, 2026-07-21): GrupoQ usa o CATÁLOGO STANDARD e
> NÃO tem EPC (Enterprise Product Catalog).** Impacto na modelagem:
> - **NÃO usar o framework de atributos EPC** (Product Attribute / Attribute Set /
>   AttributeDefinition / ProductClassification) — não está disponível sem EPC.
> - **Specs de veículo → campos nativos do `VehicleDefinition`** (Automotive Cloud,
>   NÃO é EPC): `EngineCubicCapacity` (cilindrada), etc.
> - **Atributos de peças/não-veículo → campos custom no `Product2`** (sem EPC não há
>   framework nativo de atributos).
> - **Categorização:** confirmar no org se `ProductCategory`/`ProductCatalog` estão
>   disponíveis na edição; se não, usar `Product2.Family` por linha.
> - **Preço → Price Book standard** (disponível; não muda).

## Princípio central: DOIS EIXOS (não misturar)

Estruturar o catálogo em dois eixos independentes evita duplicar catálogo por
tipo de venda:

1. **Eixo PRODUTO — "o que é"** (o catálogo em si):
   `Product Catalog` → `Product Category` → `Product2` (+ `Business Brand`,
   + `Vehicle Definition` p/ veículos, + `Product Attribute` p/ specs).
2. **Eixo COMERCIAL — "como se vende/precifica"**:
   `Price Book` por **sociedade/país × tipo de venda** + Record Type / Sales
   Process por linha.

> Regra de ouro: **o produto é UM só; a precificação e o processo é que variam.**
> Frotas NÃO tem catálogo próprio — reusa o de Autos com Price Book de frota.

## Objetos nativos (Automotive Cloud)

| Objeto | Papel |
|---|---|
| **Product Catalog** | Agrupamento de alto nível (ex.: Autos Novos, Repuestos, PA/Accesorios) |
| **Product Category** | Categorias dentro do catálogo (SUV/Sedan/Pickup; Filtros/Frenos) |
| **Product2** | O produto (veículo-modelo ou peça). Tem `BusinessBrandId`, `Family`, `ProductCode` |
| **Product Attribute / Attribute Set** | Specs/atributos (cilindrada, cor, tração…) — nativo p/ tipo de moto/cilindrada |
| **Vehicle Definition** | Specs de veículo (make/model/versão), **por país** (`GeoCountryId`). `VehicleDefinition.Id = Product2.Id` |
| **Business Brand** | Marca (Chevrolet, Hyundai, Isuzu…), com hierarquia de marca-pai |
| **Price Book / PricebookEntry** | Preço por sociedade/país × tipo de venda (multimoeda) |
| **Location / ProductItem / SerializedProduct** | Estoque (quantidade por local; unidade serializada) |
| **Vehicle / Asset** | Unidade específica (usado = VIN individual; inventário) |

## Como cada linha se modela

### 1. Autos Novos
`Product Catalog "Autos Novos"` → `Product Category` (SUV/Sedan/Pickup…) →
`Product2` + `Vehicle Definition` (por país via `GeoCountryId`) + `Business Brand`.
Preço: **Price Book retail** por sociedade. Estoque: `SerializedProduct`/`Vehicle`.

### 2. Autos Usados
**NÃO é catálogo de definições.** Cada usado é um **`Vehicle` / `Asset` único**
(VIN, `ConditionType = Used`, valor de mercado — `AverageMarketValue`,
`MarketPrice`, `LatestResidualValue`). Preço **individual**, não lista.
(Opcional: um catálogo "leve" só p/ vitrine, mas o núcleo é o Asset individual.)

### 3. Motos
Igual Autos Novos: `Product Catalog "Motos"` → categorias (por cilindrada/tipo) →
`Product2` + `Vehicle Definition` (**`EngineCubicCapacity` = cilindrada**) +
`Business Brand`. Tipo de moto/cilindrada como **Product Attribute** (evita
`TipoMoto__c`/`Cilindrada__c` custom). Preço: **Price Book Motos**.

### 4. Frotas
**Reusa o catálogo de Autos** — mesma `Vehicle Definition`. Só muda o
**Price Book (fleet)** + o Sales Process / Record Type de frota. **Não criar
catálogo separado de frota.** (Cliente de frota = `Business Profile` + `Party
Relationship Group`.)

### 5. Repuestos e PA
`Product Catalog` "Repuestos" e "PA/Accesorios" (ou um "Parts" com categorias) →
`Product Category` (Filtros, Frenos, Aceites…) → `Product2` + `Product Attribute`
+ **tabela de compatibilidade** (`VehicleDefinition` ↔ peça; dado OEM, custom).
Preço: **Repuestos = dinâmico no SAP** (callout); **PA = Price Book** (lista).

## Matriz de Price Books (eixo comercial)

Preço = **sociedade/país × tipo de venda**. Exemplos:

| Sociedade | Autos Retail | Autos Frota | Motos | PA |
|---|---|---|---|---|
| C101 (Costa Rica) | PB C101-Retail | PB C101-Fleet | PB C101-Motos | PB C101-PA |
| (futuro HN/GT/SV) | … | … | … | … |

Repuestos: preço dinâmico SAP (não entra em Price Book estático).
Multimoeda: cada país na sua moeda (CRC, HNL, GTQ, USD).

## Pontos a confirmar (rubrica #4 — não assumir escopo)

1. **Licença/feature** de Product Catalog / Category / Attributes na edição AC —
   confirmar que está habilitado (é parte do Product Management do Automotive Cloud).
2. **Autos Usados** entra nesta versão? (modelagem diferente — Asset individual).
3. Granularidade dos catálogos: 1 catálogo por linha vs menos catálogos + mais
   categorias — decisão de organização.
4. **Cilindrada/tipo de moto**: usar Product Attribute nativo ou
   `VehicleDefinition.EngineCubicCapacity` — confirmar no describe do org.

## Docs oficiais
- Manage Products in Automotive Cloud: https://help.salesforce.com/s/articleView?id=ind.auto_manage_products_container.htm
- Automotive Cloud Fields on Product2: https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_product2.htm
- VehicleDefinition: https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehicledefinition.htm
- Automotive Cloud Data Model: https://help.salesforce.com/s/articleView?id=ind.auto_data_model.htm
- Data Model Gallery (Automotive): https://developer.salesforce.com/docs/platform/data-models/guide/automotive-cloud.html
