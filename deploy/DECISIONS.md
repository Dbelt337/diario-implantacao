# GrupoQ — Decisões de arquitetura (Lead flow)

> Log vivo das decisões, pra evitar conflitos entre instruções sucessivas.
> Última atualização: 2026-05-30.

## Componentes-alvo

| Componente | Papel | Estado |
|---|---|---|
| `Lead_SearchActiveProducts_IP` | Read-only. Busca catálogo Product2 (ativo) por texto+marca + inventário. Retorna lista; `productId` reusado na criação. **Substitui** `Lead_ValidateProductInventory_IP`. | a construir |
| `Lead_Upsert_IP` | Persiste Lead (+LeadLineItem +LeadPreferredSeller) no submit. Idempotente. | núcleo pronto (v2); falta idempotência, Sociedade-por-marca, dedup, campos LLI |
| `IP-Dedup-Lead` (Sec 37.1) | Autoridade única de dedup (cliente+produto+Sociedade). | confirmar se = `Lead_Deduplication` existente (era stub) |
| `Lead_BS_DeriveSociedad` (Flow) | **APOSENTADO** (decisão 30/05). Derivação migra pra IP. | desativar |

## Decisões

- **DEC-01 — Flow aposentado.** Derivação de Sociedade sai do Before-Save Flow e mora na `Lead_Upsert_IP`. O Flow deve ser **desativado** (não deployar o fix anterior).
- **DEC-02 — Sociedade por MARCA + PAÍS**, não por dealer/sucursal. Precedência: (1) `sociedad` explícita no payload → usa + valida coerência com marca; (2) marca+país → `id_marca` → BusinessBrand → `Brand_Sociedad_Map__mdt` → `Lead.Sociedad__c`; (3) sem marca/sociedade → triagem. Dealer/sucursal só roteiam o vendedor depois.
- **DEC-03 — Search substitui Validate.** `Lead_SearchActiveProducts_IP` é a IP de consulta. `Lead_ValidateProductInventory_IP` fica obsoleta.
- **DEC-04 — Reuso de productId.** A criação confia no `productId` vindo da consulta, mas verifica integridade (Product2 existe + `IsActive=true`). Fallback por `productCode` se só vier o código.
- **DEC-05 — `includeProduct`** (default true) decide se cria o LeadLineItem.
- **DEC-06 — REST nativo OmniStudio**, namespace **`grupoq`**: `POST /services/apexrest/grupoq/v1/integrationprocedure/<Type>_<SubType>/`. Sem casca Apex. Confirmar o namespace na org.
- **DEC-07 — Atomicidade:** Lead sempre criado; filhos com falha viram warning, nunca derrubam o Lead.

## Bloqueios / dependências (owner: GrupoQ)

- ❗ Instrução **`Roteamento_Sociedade_por_Marca`** (regra completa de Sociedade-por-marca) — não recebida.
- BusinessBrands criados; de-para `id_marca`/`id_version` → Salesforce; CMT `Brand_Sociedad_Map__mdt` carregado (chave marca+país).
- Licença: PSL **"Partner Lead Management"** + PS **"ManufacturingPartnerLeadMgmtPsl"** no Integration User (senão create de LeadLineItem/LeadPreferredSeller falha por CRUD).
- DESCRIBE (ambiente do build não acessa doc/DESCRIBE): `Lead` (campo de `externalRequestId`), `LeadLineItem`, `LeadPreferredSeller`, `Product2` (`BusinessBrandId`, `MakeName`, `IsActive`), `BusinessBrand`.
