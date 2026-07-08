# Plano de remediação — Modelo Organizacional GrupoQ DevSales

> Ordem de execução recomendada, por severidade e dependência. Cada passo indica
> mecanismo, artefato e se é bloqueante para o roteamento de Vendas.
> **Nada aqui foi executado.** Referências de achado remetem ao RELATORIO_MODELO_ORGANIZACIONAL.md.

## Antes de tudo: extrair a lista de trabalho
Rode `discovery_worklist.apex` (Execute Anonymous, somente leitura) para obter os IDs
concretos que alimentam os CSVs de carga: dealers sem BP, IOUs sem Account, Accounts
de sociedade, BP com tipo nulo e registros de CMT. Sem esses IDs os data loads não
podem ser montados com precisão.

---

## Bloco 1 — Metadado (deploy, não depende de dados)
Pode ir junto para o próximo ambiente; são as duas lacunas de schema do Modelo B.

| Passo | Achado | Artefato | Ação |
|---|---|---|---|
| 1.1 | A-06 | `metadata/User.SucursalBP__c.field-meta.xml` | Criar Lookup(BusinessProfile) em User. Adicionar a permission sets/perfis relevantes. |
| 1.2 | A-09 | `metadata/Account.BrandName__c.field-meta.xml` | Criar Text(255) em Account. Depois construir o Flow populador (ver 3.2). |

Deploy sugerido (após copiar para uma pasta sfdx `force-app/main/default/objects/.../fields/`):
`sf project deploy start -o <alias> -d force-app/main/default/objects`

---

## Bloco 2 — Configuração de sociedades (metadado + dado) — P1
Resolve o desalinhamento GVS x CMT x canônica (A-05). **Depende de 1 decisão** (P101).

| Passo | Achado | Ação | Mecanismo |
|---|---|---|---|
| 2.1 | A-05 | Decidir o destino de `P101` (ver `A-05_reconciliacao_sociedades.md`). | Decisão |
| 2.2 | A-05 | Incluir `P103` no GlobalValueSet `GVS_Sociedad`; remover/renomear `P101`. | Metadado (GVS) |
| 2.3 | A-05 | Ajustar `Sociedad_Config__mdt` (remover/renomear P101; garantir P103). | Metadado (CMT) |
| 2.4 | A-10 | Adicionar os 4 códigos `-PROV` a GVS e CMT quando o SAP final sair. | Metadado (pendência externa) |

Meta: GVS, CMT e a lista canônica idênticos (17 valores, com os `-PROV` quando definidos).

---

## Bloco 3 — Estrutura e dados — P0/P1
Ordem importa: hierarquia antes de BP, BP antes de validar roteamento.

| Passo | Achado | Ação | Artefato | Bloqueia roteamento? |
|---|---|---|---|---|
| 3.1 | A-03 | Popular `ParentId`: País→Holding, Sociedade→País, Dealer→Sociedade. Corrigir o 1 Account de profundidade >4. | `A-03_account_parentid_TEMPLATE.csv` | Sim (deriva de sociedade) |
| 3.2 | A-01 | Criar BusinessProfile `Sales Dealer` para os 17 dealers sem BP, com `ExternalReferenceNumber`=SAP, `BusinessPartnerType`='Sales Dealer', `AccountId` correto. | `A-01_bp_salesdealer_TEMPLATE.csv` | **Sim (P0)** |
| 3.3 | A-02 | Classificar o BP com `BusinessPartnerType` nulo. | (via discovery) | **Sim (P0)** |
| 3.4 | A-04 | Vincular as 15 IOUs a seus Accounts de sociedade; conciliar 19→17 (mesclar/remover excedentes e definir granularidade oficial = sociedade). | `A-04_iou_accountid_TEMPLATE.csv` | Não (afeta Repuestos) |
| 3.5 | A-11 | Backfill de `User.Sociedad__c` e `User.SucursalBP__c` nos usuários de teste. | `A-11_user_sociedad_TEMPLATE.csv` | Parcial |

Data load sugerido (exemplo BP): `sf data upsert bulk -o <alias> -s BusinessProfile -f A-01_bp_salesdealer.csv -i ExternalReferenceNumber`

---

## Bloco 4 — Território e sharing — P1/P2
**Depende de 1 decisão** (ServiceTerritory vs BranchUnit).

| Passo | Achado | Ação | Mecanismo |
|---|---|---|---|
| 4.1 | A-07 | Definir objeto canônico de território (recomendação: ServiceTerritory, é o formal do Modelo B) e popular espelhando os dealers. | Decisão + data load |
| 4.2 | A-09 | Construir o Flow que popula `Account.BrandName__c` a partir da fonte de marca (definir: BusinessBrand relacionada? campo?). | Metadado (Flow) |
| 4.3 | A-09 | Após popular, criar/ativar as Sharing Rules por marca sobre `BrandName__c`. | Configuração |
| 4.4 | A-12 | Conferir a 23ª BusinessBrand contra `Lista de marcas por pais.xlsx`. | Revisão |

---

## Bloco 5 — Higiene — P3
| Passo | Achado | Ação |
|---|---|---|
| 5.1 | A-13 | Avaliar converter `Account.Sociedad__c` (hoje TEXTAREA) para picklist governada pelo GVS, ou fórmula derivada da sociedade-pai. |

---

## Duas decisões que preciso de você para fechar os artefatos finais
1. **P101**: é erro de digitação de **P103** (então renomeamos e removemos P101), ou é uma **sociedade real** de Panamá que deveria entrar na lista canônica?
2. **Território canônico**: seguimos com **ServiceTerritory** (formal do Modelo B) e aposentamos BranchUnit, ou o inverso?

Respondidas essas duas, consolido os artefatos definitivos (GVS/CMT e o de território) sem ambiguidade.

## Ordem enxuta para destravar o roteamento (se o tempo é curto)
1. Deploy dos 2 campos (Bloco 1).
2. `ParentId` da cadeia real (3.1).
3. BP `Sales Dealer` dos dealers + classificar BP nulo (3.2, 3.3).
4. Alinhar GVS/CMT (2.2, 2.3).
5. Validar `Lead_BS_DeriveSociedad` end-to-end com um Lead de teste por sociedade.
