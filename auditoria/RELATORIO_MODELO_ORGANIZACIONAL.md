# Auditoria do Modelo Organizacional — GrupoQ DevSales

> Documento de arquitetura. Baseline Modelo B. Auditoria em modo somente leitura.

- **Org auditada:** grupoq--devsales.sandbox.my.salesforce.com
- **Usuário de execução:** diego.beltrao@grupoq.com.devsales
- **Data/hora de execução:** 2026-07-08, ~11:33–11:34 (America/Mexico_City, GMT-06:00)
- **Método:** Apex anônimo (Execute Anonymous), somente leitura, em 4 blocos. Evidência bruta em `evidencias/resultado_auditoria.txt`.
- **Limite de uso (bloco 2):** 8/100 SOQL, 8/50000 linhas — execução governor-friendly.

---

## 1. Sumário executivo

A base de metadados do Modelo B está presente na DevSales — todos os objetos-alvo (Account, BusinessProfile, InternalOrganizationUnit, BranchUnit, ServiceTerritory, BusinessBrand) existem e o lookup BusinessProfile→Account é o padrão `AccountId`. Porém a **camada de dados está apenas parcialmente carregada e a estrutura hierárquica praticamente não foi construída**: dos 1247 Accounts, 1220 não têm pai; a cadeia Holding→País→Sociedade→Dealer materializada resume-se a 2 países, 3 sociedades e 21 dealers. Só existem 5 BusinessProfiles (4 `Sales Dealer` + 1 sem tipo), e 17 dos 21 Accounts de nível dealer não têm BP — o que, em produção, quebraria o dealerCode lookup da cascata de Leads. A qualidade da chave SAP no pouco que existe é boa (nenhum `ExternalReferenceNumber` nulo ou duplicado). Dois campos que o Modelo B pressupõe **não existem**: `User.SucursalBP__c` e `Account.BrandName__c`. A configuração de sociedades diverge entre si e da lista canônica (P101 não-canônico presente em GVS e CMT; P103 ausente do GVS). ServiceTerritory está vazio. Conclusão: o modelo é viável, mas está em estágio inicial de carga e com divergências de governança que precisam ser resolvidas antes de habilitar roteamento e sharing por marca.

**Tabela de achados por severidade**

| Severidade | Qtd | Achados |
|---|---|---|
| P0 — quebra roteamento/integração | 2 | A-01, A-02 |
| P1 — inconsistência estrutural | 5 | A-03, A-04, A-05, A-06, A-07 |
| P2 — completude/pendências | 5 | A-08, A-09, A-10, A-11, A-12 |
| P3 — higiene/governança | 1 | A-13 |

---

## 2. Inventário

### 2.1 Presença de objetos (Fase 1)
Todos PRESENTES: Account, BusinessProfile, InternalOrganizationUnit, BranchUnit, ServiceTerritory, BusinessBrand, User.

### 2.2 Discriminador de nível de Account (descoberta)
Os Record Types de Account são apenas `BusinessAccount` e `PersonAccount` (ambos ativos) — **não são discriminadores de nível**. Não há Record Type nem campo custom de nível. O nível é dado **apenas pela profundidade de `ParentId`**. `Account.Sociedad__c` existe mas é do tipo **TEXTAREA** (texto livre), não picklist/GVS.

### 2.3 Relação BusinessProfile → Account (descoberta)
Lookup padrão **`BusinessProfile.AccountId`**. Confirmado por describe.

### 2.4 Contagens reais x alvo (Fase 2/3)

| Entidade | Alvo (produção) | Real (DevSales) | Evidência |
|---|---|---|---|
| Holding (nível 1 / ParentId nulo) | 1 | 1220 | n1 = 1220 |
| País (nível 2) | 6 | 2 | n2 = 2 |
| Sociedade (nível 3) | 17 | 3 | n3 = 3 (C101, C105, N105) |
| Dealer/Sucursal (nível 4) | 128 | 21 | n4 = 21 |
| Profundidade > 4 níveis | 0 | 1 | n5+ = 1 |
| Accounts (total) | — | 1247 | RT: 1244 Business + 3 Person |
| BusinessProfile total | ~128 | 5 | 4 Sales Dealer + 1 null |
| InternalOrganizationUnit | 17 | 19 | IOU = 19 (15 sem Account) |
| BranchUnit | descobrir | 1 | |
| ServiceTerritory | descobrir | 0 | vazio |
| BusinessBrand | 22 | 23 | 1 a mais |

> A DevSales é reconhecidamente um subconjunto de carga; contagens abaixo do alvo não são erro automático (Sec 4.1). O achado estrutural não é o número em si, mas a **ausência quase total de vínculo `ParentId`** (1220/1247 sem pai) e de BPs.

---

## 3. Achados

### A-01 — 17 de 21 Accounts de nível dealer sem BusinessProfile `Sales Dealer` (P0)
- **Descrição:** Existem 21 Accounts no nível 4 (dealer) mas apenas 4 BusinessProfiles `Sales Dealer`; o anti-join local aponta 17 dealers sem BP. Como o dealerCode lookup da cascata `Lead_BS_DeriveSociedad` resolve a sociedade a partir de `BusinessProfile.ExternalReferenceNumber`, dealers sem BP não têm chave de roteamento.
- **Evidência:** `AUDIT> DEALERS n4 SEM BP SalesDealer[P0]: 17 de 21`; `AUDIT> BPtype Sales Dealer=4` (`evidencias/resultado_auditoria.txt`, bloco 3).
- **Impacto em Vendas:** Leads desses dealers não derivam sociedade → falha ou fallback de roteamento. Latente enquanto a carga é parcial; bloqueante ao promover para produção.

### A-02 — BusinessProfile com `BusinessPartnerType` nulo (P0)
- **Descrição:** 1 dos 5 BusinessProfiles tem `BusinessPartnerType = null`. Se corresponder a um dealer, fica invisível ao filtro `= 'Sales Dealer'` do roteamento e do inventário de BP.
- **Evidência:** `AUDIT> BPtype null=1` (bloco 3).
- **Impacto em Vendas:** BP não classificado não participa do dealerCode lookup; possível dealer sem cobertura de roteamento apesar de ter BP.

### A-03 — Hierarquia de Account não materializada via `ParentId` (P1)
- **Descrição:** 1220 de 1247 Accounts têm `ParentId` nulo. A cadeia Holding→País→Sociedade→Dealer existe apenas para 2 países, 3 sociedades e 21 dealers. Há ainda 1 Account com profundidade superior a 4 níveis. Sem duplicidade de nome sob o mesmo pai (0 linhas).
- **Evidência:** `n1=1220`, `n2=2`, `n3=3`, `n4=21`, `n5+=1`, DUP=0 (bloco 2).
- **Impacto em Vendas:** Visibilidade por hierarquia (role/sharing baseados em Account) e agregações por país/sociedade ficam incompletas; deriva de sociedade por travessia de pai não funciona fora da amostra.

### A-04 — InternalOrganizationUnit sem Account e acima do alvo (P1)
- **Descrição:** 19 IOUs (alvo 17), das quais 15 têm `AccountId` nulo. Apenas 4 IOUs estão vinculadas a Account. Granularidade real não confirmável sem o vínculo.
- **Evidência:** `AUDIT> IOU total[17]: 19`; `AUDIT> IOU AccountId nulo: 15` (bloco 3).
- **Impacto em Vendas:** IOU sem Account não representa sociedade/sucursal de forma consumível; quebra qualquer lógica (ex.: Repuestos Sec 12.2.2) que dependa de IOU→Account.

### A-05 — Desalinhamento GVS x CMT x lista canônica (P1)
- **Descrição:** Matriz de reconciliação: `P101` (não-canônico) presente **tanto no GVS (User.Sociedad__c) quanto no CMT `Sociedad_Config__mdt`**; `P103` (canônico) está no CMT mas **ausente do GVS**. Panamá canônico é {P103, P105}. GVS(User) ativos ≈ 13 (12 canônicos + P101); CMT ≈ 14 (13 canônicos + P101). Os 4 códigos `-PROV` ausentes de ambos (ver A-10).
- **Evidência:** linhas `RECON ...` e `RECON EXTRA cmt/gvsUser P101`; `RECON P103 gvsUser=- cmt=X` (bloco 4).
- **Impacto em Vendas:** Valor de sociedade inconsistente entre picklist de usuário e defaults do CMT; roteamento/derivação por sociedade pode usar código inexistente (P101) ou não encontrar P103.

### A-06 — `User.SucursalBP__c` não existe (P1)
- **Descrição:** A decisão do Modelo B (a sucursal de atuação do vendedor é um Lookup para BusinessProfile em `User.SucursalBP__c`) não está implementada — o campo está ausente. Existem `User.Sociedad__c`, `User.TipoAutoQueVende__c`, `User.Canal__c`.
- **Evidência:** `AUDIT> User.sucursalbp__c: AUSENTE` (bloco 1).
- **Impacto em Vendas:** Não há como amarrar o vendedor à sua sucursal (BP); regras de atribuição/visibilidade que dependem de SucursalBP não funcionam.

### A-07 — ServiceTerritory vazio e BranchUnit residual (P1)
- **Descrição:** ServiceTerritory = 0; BranchUnit = 1. O Modelo B formal usa Account + BusinessProfile + ServiceTerritory; o Mapeamento usa BranchUnit para visibilidade em handover (Sec 48). Nenhum dos dois está efetivamente populado.
- **Evidência:** `AUDIT> ServiceTerritory total: 0`; `AUDIT> BranchUnit total: 1` (bloco 3).
- **Impacto em Vendas:** Mecanismo de território/handover inexistente na prática; decisão de qual objeto é canônico permanece em aberto (divergência doc x org).

### A-08 — Cobertura de carga abaixo do alvo (P2)
- **Descrição:** Países 2/6, sociedades 3/17, dealers 21/128, BusinessProfile 5/~128. Consistente com carga parcial de sandbox, registrado como completude, não como erro.
- **Evidência:** bloco 2 e bloco 3.
- **Impacto em Vendas:** Testes de roteamento cobrem só uma fração das sociedades/dealers reais.

### A-09 — `Account.BrandName__c` não existe (P2)
- **Descrição:** O campo auxiliar de texto para Sharing Rules por marca (contorno da limitação de criteria-based sharing) não existe; logo, não há Flow populador nem taxa de preenchimento a medir.
- **Evidência:** `AUDIT> Account.BrandName__c AUSENTE` (bloco 1 e 4).
- **Impacto em Vendas:** Sharing por marca via BrandName não é implementável no estado atual.

### A-10 — Códigos `-PROV` ausentes de GVS e CMT (P2)
- **Descrição:** C106-PROV, H106-PROV, S106-PROV, N106-PROV não estão no GVS nem no CMT. Pendência conhecida (aguardam código SAP final da Active Motors, Sec 4.1).
- **Evidência:** linhas `RECON *-PROV gvsUser=- cmt=-` (bloco 4).
- **Impacto em Vendas:** Sociedades provisórias ainda não roteáveis; esperado até definição do SAP.

### A-11 — `User.Sociedad__c` majoritariamente vazio (P2)
- **Descrição:** 46 de 48 usuários ativos sem `Sociedad__c`; apenas 2 com C101.
- **Evidência:** `AUDIT> UserSoc null=46`; `AUDIT> UserSoc C101=2` (bloco 4).
- **Impacto em Vendas:** Regras que dependem da sociedade do usuário atuam sobre base quase vazia; baixa representatividade de teste.

### A-12 — BusinessBrand acima do alvo (P2)
- **Descrição:** 23 BusinessBrand vs alvo 22 (1 a mais). Cruzamento marca×sociedade pendente do arquivo `Lista de marcas por pais.xlsx` (não disponível na execução).
- **Evidência:** `AUDIT> BusinessBrand total[22]: 23` (bloco 3).
- **Impacto em Vendas:** Possível marca duplicada/indevida; baixo impacto até o cruzamento.

### A-13 — `Account.Sociedad__c` é texto livre (P3, governança)
- **Descrição:** Na Account a sociedade é TEXTAREA; no User é picklist (GVS). Governança inconsistente do mesmo conceito.
- **Evidência:** `AUDIT> Acc.f Sociedad__c TEXTAREA` (bloco 1).
- **Impacto em Vendas:** Risco de grafias divergentes de sociedade no Account; dificulta reconciliação automática.

---

## 4. Plano de ajustes (NÃO EXECUTADO)

| Achado | Ação proposta | Mecanismo | Pré-condições | Esforço |
|---|---|---|---|---|
| A-01 | Criar BusinessProfile `Sales Dealer` para os 17 dealers, com `ExternalReferenceNumber` = SAP e `AccountId` correto | Data load (insert) | Mapa dealer→SAP validado | M |
| A-02 | Definir `BusinessPartnerType` do BP nulo (classificar como Sales Dealer ou o tipo correto) | Data load (update) | Identificar o BP e seu papel | P |
| A-03 | Popular `ParentId` da cadeia País→Sociedade→Dealer; investigar e recolocar o Account de profundidade >4 | Data load (update) | Definição de qual país/sociedade cada Account pertence | G |
| A-04 | Vincular as 15 IOUs a seus Accounts de sociedade; conciliar 19→17 (remover/mesclar excedentes) | Data load (update) + revisão | Definição da granularidade oficial (sociedade) | M |
| A-05 | Alinhar GVS, CMT e canônica: remover/renomear P101, incluir P103 no GVS | Metadado (GlobalValueSet + CMT) | Decisão sobre P101 (é erro ou sociedade real?) | M |
| A-06 | Criar `User.SucursalBP__c` Lookup(BusinessProfile) e popular nos vendedores | Metadado (campo) + data load | Aprovação do desenho Modelo B | M |
| A-07 | Decidir objeto canônico (ServiceTerritory vs BranchUnit) e popular | Configuração + data load | Decisão de arquitetura | G |
| A-09 | Criar `Account.BrandName__c` e Flow populador; então medir preenchimento | Metadado (campo + Flow) | Definição das Sharing Rules por marca | M |
| A-10 | Substituir `-PROV` pelos códigos SAP finais quando definidos | Data/metadado | Código SAP da Active Motors | P |
| A-11 | Backfill de `User.Sociedad__c` nos usuários de teste | Data load (update) | Mapa usuário→sociedade | P |
| A-12 | Conferir a 23ª BusinessBrand contra `Lista de marcas por pais.xlsx` | Revisão manual | Arquivo disponível | P |
| A-13 | Avaliar converter `Account.Sociedad__c` para picklist (GVS) ou fórmula | Metadado | Decisão de governança | M |

> Artefatos detalhados por achado devem ser gerados em `ajustes/` a partir dos IDs reais coletados (ver `ajustes/README.md`). Ainda não gerados por dependerem de decisões acima (ex.: qual objeto de território é canônico, se P101 é erro).

---

## 5. Premissas assumidas e divergências doc x org

**Premissas**
- P-01: A coleta foi executada pelo usuário via Execute Anonymous (o ambiente de auditoria não tinha acesso de rede/CLI à org). Evidência = log de debug do próprio usuário.
- P-02: Reconciliação do Account de sociedade feita por `Name` (o código aparece embutido, ex.: "GrupoQ Costa Rica C101"); por isso `acc=-` na matriz apesar de as 3 sociedades existirem.
- P-03: O GVS `GVS_Sociedad` foi aproximado pelos valores ativos de `User.Sociedad__c` (Apex não consulta GlobalValueSet diretamente); um retrieve de metadado confirmaria o GVS em si.
- P-04: Fase 8 (flows/dealerCode step) **pendente**: `FlowDefinitionView` não suporta `queryMore()` via `Database.query`; requer `LIMIT`. Ver snippet de correção no anexo.

**Divergências doc x org (a org é a fonte da verdade)**
- D-01: Doc prevê `User.SucursalBP__c` Lookup(BusinessProfile) — **não existe** (A-06).
- D-02: Doc prevê `Account.BrandName__c` + Flow — **não existe** (A-09).
- D-03: Doc prevê GVS de 17 valores idênticos à canônica — org tem ~13 com `P101` extra e sem `P103` (A-05).
- D-04: Doc (Sec 17.3) prevê 1 IOU por sociedade (17) com Account — org tem 19, 15 sem Account (A-04).
- D-05: Modelo B formal usa ServiceTerritory — org tem 0; BranchUnit tem 1 (A-07).
- D-06: Panamá canônico {P103, P105} — CMT/GVS usam `P101` (A-05).
- D-07: `Account.Sociedad__c` esperado como valor governado — é texto livre (A-13).

---

## 6. Apêndice — comandos e queries executados

Fonte primária: `evidencias/resultado_auditoria.txt` (saída bruta dos 4 blocos). Scripts em `scripts/apex_partes/parte1_schema.apex` … `parte4_config_flows.apex` (somente leitura).

**Fase 8 pendente — snippet corrigido para flows ativos** (o original falhou por `queryMore`):

```apex
for(FlowDefinitionView f:[SELECT ApiName,Label,ProcessType,TriggerType FROM FlowDefinitionView WHERE IsActive=true ORDER BY ProcessType,ApiName LIMIT 200])
 System.debug('AUDIT> FLOW '+f.ApiName+' '+f.ProcessType+' '+f.TriggerType);
```

Para confirmar o dealerCode step da cascata (chave = `BusinessProfile.ExternalReferenceNumber`), recomenda-se retrieve de metadado do Flow `Lead_BS_DeriveSociedad` e inspeção do elemento de lookup — não realizável por Apex.
