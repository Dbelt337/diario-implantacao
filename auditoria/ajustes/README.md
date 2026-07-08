# Artefatos de ajuste — NÃO EXECUTADOS

Esta pasta recebe os artefatos de correção propostos, **um por achado que exija ajuste de
dados ou configuração**, gerados após a coleta de evidência. Nada aqui é executado pela
auditoria — são insumos para uma decisão humana posterior.

Regras:
- Todo artefato inicia com um cabeçalho `# NAO EXECUTADO` e a referência ao achado (A-xx).
- CSVs de upsert devem trazer a chave idLookup usada (ex.: `ExternalReferenceNumber` para
  BusinessProfile) e apenas as colunas necessárias.
- Esqueletos de Flow/metadado ficam como `.md`/`.xml` comentados, com pré-condições.

Modelos esperados conforme os achados típicos do roteiro:

| Provável achado | Artefato sugerido | Mecanismo |
|---|---|---|
| `ExternalReferenceNumber` nulo em dealer (P0) | `A-xx_upsert_bp_extref.csv` | data load (upsert por Id) |
| `ExternalReferenceNumber` duplicado (P0) | `A-xx_dedup_extref.md` | análise + correção manual |
| Dealer sem BP `Sales Dealer` (P0) | `A-xx_insert_bp_salesdealer.csv` | data load (insert) |
| Hierarquia órfã / nível errado (P1) | `A-xx_fix_parentid.csv` | data load (update ParentId) |
| IOU sem Account / faltante (P1) | `A-xx_upsert_iou.csv` | data load |
| GVS x CMT x Accounts desalinhados (P1) | `A-xx_reconciliacao.md` | metadado (GVS/CMT) + data |
| `BrandName__c` parcial (P2) | `A-xx_backfill_brandname.md` | reprocessar Flow / batch |

> Gerar cada artefato somente com base em evidência real coletada em `../evidencias/`.
