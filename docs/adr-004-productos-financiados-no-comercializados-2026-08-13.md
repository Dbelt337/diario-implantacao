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

## Requisito real (esclarecido 13/08): planos de financiamento POR MARCA

CrediQ tem planos específicos por marca (ex.: um plano só para Volkswagen), mesmo sem comercializar a marca. Precisam de entidades de marca/modelo para vincular os planos elegíveis.

### Modelo em 3 camadas (tudo nativo)

| Camada | Objeto | Papel |
|---|---|---|
| **Plano de financiamento** | `Product2` com `Family = Financiamiento` | É produto que CrediQ **comercializa de fato** — entra no catálogo deles com naturalidade |
| **Marca / modelo financiável** | `VehicleDefinition` (marca, modelo, ano, versão) — objeto Automotive para isso | Se precisar de Product2 espelho: `Family = No Comercializado`, **nunca** com PricebookEntry comercial |
| **Elegibilidade plano × marca/modelo** | **Decision Matrix / Expression Set (BRE)** | Regras (marca + modelo + ano + valor + LTV → planos elegíveis), editáveis pelo negócio sem deploy |

**Por que regras e não tabela de vínculos:** é assim que a indústria de *captive finance* modela — programas com **critérios de elegibilidade**, não enumeração de combinações. Um catálogo de todas as marcas × todos os planos gera milhares de registros de junção que ninguém mantém. E é a MESMA ferramenta (BRE) que já usamos para impostos e fatores de preço. Se para um conjunto pequeno precisarem de vínculo registro a registro, o nativo é `ProductRelatedComponent` com relação AddOn.

**Opção adicional a verificar:** `ProductClassification` (Revenue Cloud, API 60+) — "template que agrupa atributos dinâmicos para definir produtos similares". Se a org tiver a licença RLM, "Marca" vira atributo de classificação e o vínculo fica ainda mais natural. O GAPCHECK4 já testa isso.

## Sobre usar `IsActive = false` como segregação: NÃO

Resolve a exibição hoje, mas pelo motivo errado e com três custos:
1. **Semântica trocada:** `IsActive=false` significa *descontinuado*. Esconde o produto em **toda** a UI — inclusive onde CrediQ precisa dele (lookups, related lists, relatórios próprios, seleção nos planos).
2. **Briga com a plataforma:** produto inativo não sustenta PricebookEntry ativo. Se um dia o plano ou o modelo precisar de valor/preço, o modelo trava.
3. **Frágil:** nossa busca filtra `IsActive = true` **por acaso** — no dia em que alguém ativar um registro, ou uma consulta nova não filtrar, o vazamento volta. Uma `Family` é explícita e auto-documentada.

**Design à prova de futuro na busca:** filtrar por **lista de famílias comerciais permitidas** (allowlist), não por exclusão. Assim, qualquer família não comercial criada depois já nasce fora do fluxo de venda, sem tocar no código.

## Riscos se NÃO segregar

- Assessor cotiza um veículo que a empresa não vende (erro comercial visível ao cliente);
- Ruído em relatórios de catálogo e no Inventory Search;
- Volume: um catálogo de valoração de todas as marcas são milhares de modelos — dilui a busca do fluxo;
- Colisão de chave com o external id da réplica SAP.
