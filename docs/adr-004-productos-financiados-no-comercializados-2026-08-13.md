# ADR-004 — Produtos financiados que o GrupoQ não comercializa (Financial/CrediQ) no catálogo

**Data:** 13/08/2026 · **Pergunta do Diego Braz:** Financial financia produtos de marcas que o GrupoQ não vende (ex.: VW). Há problema em cadastrá-los na base? Impacta o Cotizador?

## Resposta curta

**Cadastrar: sim. Cadastrar como produto comercial: não.** O risco não é o Cotizador — é o **fluxo de venda**, que hoje enxergaria esses produtos. Com três guardrails, o risco some.

## O impacto é real e verificável (não é hipótese)

`MaterialSearchService.search()` — a busca que alimenta o modal de venda guiada e o grid de Repuestos — faz:

```apex
FIND :sanitized IN ALL FIELDS
RETURNING Product2(Id, ProductCode, Name WHERE IsActive = true LIMIT :MAX_RESULTS)
```

Filtra **só por `IsActive = true`**. Um Product2 de VW ativo apareceria na busca do assessor, que tentaria cotizar algo que a empresa não vende. Também entraria em relatórios de catálogo e, se ganhar `VehicleDefinition`, no Inventory Search.

## Decisão: catálogo NÃO comercial, segregado

1. **Preferência: o veículo financiado de terceiro é GARANTIA, não produto.** No modelo Automotive ele cabe como `VehicleDefinition` (specs para avaliação) + `Vehicle` (unidade com VIN) ligado ao `FinancialAccount` — sem ser um `Product2` vendável. É a modelagem correta para colateral.
2. **Se o Cotizador exigir Product2** (catálogo de valoração, produto financeiro), então cadastrar **segregado**:
   - `RecordType`/`Family` próprio (ex.: *No comercializado / Financiado terceros*);
   - **sem `PricebookEntry` em nenhuma lista comercial** — barreira natural: toda `QuoteLineItem` exige PBE, então não é cotizável mesmo que alguém tente;
   - **filtro explícito na busca do fluxo guiado** — o item de código abaixo.
3. **Chave de integração:** esses produtos **não vêm da réplica SAP (MATMAS)**. Se forem carregados com código próprio, não podem colidir com o `SapMaterialCode__c` (único). Usar prefixo/namespace de origem ou deixar o campo vazio e chavear por outro identificador.

## Ações concretas

| # | Ação | Onde |
|---|---|---|
| 1 | Adicionar filtro por Family/RecordType na SOSL (excluir catálogo não comercial) | `MaterialSearchService` — 1 linha |
| 2 | Garantir que nenhum PBE de lista comercial seja criado para esses produtos | Carga/réplica do time Financial |
| 3 | Definir dono e cadência do catálogo de valoração (não é a réplica SAP) | Financial / CrediQ |
| 4 | Verificar impacto no dominio de preços (HU-038): esses produtos não devem aparecer como "sem preço" na administração | HU-038 |

## Riscos se NÃO segregar

- Assessor cotiza um veículo que a empresa não vende (erro comercial visível ao cliente);
- Ruído em relatórios de catálogo e no Inventory Search;
- Volume: um catálogo de valoração de todas as marcas são milhares de modelos — dilui a busca do fluxo;
- Colisão de chave com o external id da réplica SAP.
