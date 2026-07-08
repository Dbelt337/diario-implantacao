# Auditoria do Modelo Organizacional — GrupoQ DevSales

> Documento de arquitetura. Modelo B (baseline aprovada, Diego Braz). Somente leitura.
> **Status: SCAFFOLD — pendente de coleta de evidência.** Preencher a partir de `evidencias/`
> após executar `scripts/run_auditoria.sh` contra a org `grupoq--devsales`.

- **Org auditada:** grupoq--devsales.sandbox.my.salesforce.com
- **Data/hora de execução (UTC):** _[preencher: campo `_apendice_comandos.log`, 1ª linha]_
- **API version / usuário / instância:** _[preencher de `evidencias/00_org_display.json`]_
- **Multi-currency esperado:** HNL, NIO, USD, GTQ, CRC

---

## 1. Sumário executivo

_[Até 10 linhas: estado geral do modelo organizacional, principais riscos ao roteamento de
Leads (chave SAP `BusinessProfile.ExternalReferenceNumber`) e à integração, e veredito de
prontidão. Preencher por último.]_

**Tabela de achados por severidade**

| Severidade | Qtd | Achados |
|---|---|---|
| P0 — quebra roteamento/integração | _[n]_ | _[A-xx, ...]_ |
| P1 — inconsistência estrutural | _[n]_ | _[A-xx, ...]_ |
| P2 — completude/pendências | _[n]_ | _[A-xx, ...]_ |
| P3 — higiene | _[n]_ | _[A-xx, ...]_ |

---

## 2. Inventário

### 2.1 Presença e acesso a objetos (Fase 1)
_[De `evidencias/_objetos_presenca.csv`. Objeto ausente/sem acesso = achado.]_

| Objeto | Presente | Read/Create/Edit (perfis chave) | Observação |
|---|---|---|---|
| Account | | | |
| BusinessProfile | | | |
| InternalOrganizationUnit | | | |
| BranchUnit | | | |
| ServiceTerritory | | | |
| BusinessBrand | | | |

### 2.2 Discriminador de nível de Account (descoberta)
_[Documentar: Record Type, campo custom, ou profundidade de ParentId. Evidência:
`evidencias/01_account_recordtypes.csv`, `_campos_custom_Account.csv`.]_

### 2.3 Relação BusinessProfile → Account (descoberta)
_[Campo de lookup real confirmado via `describe_BusinessProfile.json`. Evidência: nome do campo.]_

### 2.4 Contagens reais x alvo (Fase 2)

| Entidade | Alvo (produção) | Real (DevSales) | Fonte de evidência |
|---|---|---|---|
| Holding (nível 1) | 1 | | 02_account_nivel1_holding.csv |
| País (nível 2) | 6 | | 02_account_nivel2_pais.csv |
| Sociedade (nível 3) | 17 | | 02_account_nivel3_sociedade.csv |
| Dealer/Sucursal (nível 4) | 128 | | 02_account_nivel4_dealer.csv |
| BusinessProfile (Sales Dealer) | ~128 | | 02_businessprofile_por_tipo.csv |
| InternalOrganizationUnit | 17 | | 02_contagem_iou.csv |
| BranchUnit | descobrir | | 02_contagem_branchunit.csv |
| ServiceTerritory | descobrir | | 02_contagem_serviceterritory.csv |
| BusinessBrand | 22 | | 02_contagem_businessbrand.csv |

> DevSales pode conter subconjunto de carga. Reportar cobertura real vs. alvo; subconjunto
> não é erro automático (ver Sec 4.1 da instrução).

### 2.5 Licenciamento (PSL)
_[De `evidencias/01_permission_set_licenses.csv`, destacar PSLs de Automotive/Industries.]_

---

## 3. Achados

> Formato: ID sequencial · severidade · descrição · evidência (query + números + arquivo) · impacto em Vendas.

### A-01 — _[título]_
- **Severidade:** P_[x]_
- **Descrição:** _[...]_
- **Evidência:** query `[...]` → `evidencias/[arquivo].csv` (n = _[...]_)
- **Impacto no fluxo de Vendas:** _[...]_

_[Repetir A-02, A-03, ... Áreas a cobrir obrigatoriamente:
 Fase 3 — órfãos, nível errado, profundidade >4, duplicidade de nome/código, sociedades fora da lista canônica;
 Fase 4 (P0) — dealers sem BP, BP órfão, BP em Account não-dealer, ExternalReferenceNumber nulo/duplicado, formato do código SAP;
 Fase 5 — granularidade e cobertura de IOU, IOU sem Account ou nível incompatível;
 Fase 6 — qual objeto populado, paridade com dealers, coerência de hierarquia, unidades sem vínculo;
 Fase 7 — matriz de reconciliação GVS x CMT x Accounts x canônica, BrandName__c, User.Sociedad__c/SucursalBP__c;
 Fase 8 — chave do dealerCode lookup na cascata, Flow populador de BrandName__c, Sharing Rules dependentes.]_

---

## 4. Plano de ajustes

> Por achado: ação proposta · mecanismo (data load / metadado / configuração) · pré-condições ·
> esforço (P/M/G) · artefato em `ajustes/` (marcado NÃO EXECUTADO).

| Achado | Ação proposta | Mecanismo | Pré-condições | Esforço | Artefato |
|---|---|---|---|---|---|
| A-01 | | | | | |

---

## 5. Premissas assumidas e divergências doc x org

**Premissas assumidas**
- _[P-01] O toolkit de coleta foi preparado para execução externa porque o ambiente remoto de
  auditoria bloqueou (403 de egresso) os hosts do Salesforce e a instalação da CLI, e não havia
  autenticação disponível. Ver `README.md` desta pasta._
- _[P-02] ..._

**Divergências doc x org** (a org é a fonte da verdade — Sec 2.3 da instrução)
- _[D-01] ..._

---

## 6. Apêndice — comandos executados, na ordem

_[Colar/anexar `evidencias/_apendice_comandos.log`, que registra cada `sf`/SOQL na ordem de execução.]_
