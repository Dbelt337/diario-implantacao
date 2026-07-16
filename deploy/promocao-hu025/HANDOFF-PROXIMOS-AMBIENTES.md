# HU-025 — Hand-off para os próximos ambientes (QA / UAT / Prod)

Conversão de Lead → Opportunity levando **produto** (OpportunityLineItem) e
**vendedor** (OpportunityPreferredSeller), com **preço automático de catálogo**,
usando a transformação **nativa** do Automotive Cloud (Partner Lead Management).
**Sem Apex.**

> Para os devs: o deploy é via **VS Code + Salesforce CLI** (`sf`), formato
> source. NÃO existe "pacote pronto" — o correto é **retrieve do DevSales →
> revisar em git → deploy no destino**, respeitando a ordem abaixo.

---

## 1. O que a solução tem (2 camadas)

**A. Config/feature no ambiente (NÃO é metadata deployável — fazer à mão):**
enablement da feature, licenças, dados (products/price books), record types e
Map Lead Fields.

**B. Metadata deployável (vai no `package.xml`):** os 2 mappings OOB, o flow de
RecordType e o LeadConvertSettings.

A camada A tem que estar pronta **antes** de deployar a camada B.

---

## 2. Pré-requisitos de CONFIG no destino (manual — antes do deploy)

1. **Habilitar Partner Lead Management** (Automotive/Manufacturing lead
   management). Setup → busca por "Automotive" / "Lead" → ligar o toggle.
   > Isso **cria os registros OOB** `ObjectHierarchyRelationship`
   > (`LeadItemToOppItemOOBMappings` e `LeadPrefToOppPrefOOBMappings`) já no
   > destino. O deploy da camada B **atualiza** esses registros — por isso o
   > toggle vem primeiro.

2. **Permission Set Licenses** nos usuários que convertem leads
   (as mesmas do DevSales): *Automotive Foundation User* + a de lead management.
   Sem elas a transformação não roda.

3. **Multimoeda + CRC ativa** (se o destino ainda não tiver). O CurrencyIsoCode
   viaja no mapping; org multimoeda é premissa.

4. **Record Types de Opportunity** referenciados pelo flow:
   `GQOpportunitiesAutos`, `GQOpportunitiesMotos`, `GQOpportunitiesFlotas`.

5. **Campos custom** existindo em **Lead e Opportunity** (pai):
   `CompanyCode__c` (Sociedad), `Brand__c` (Marca), `NationalId__c`,
   `PreferredContactMethod__c`, etc. (deployar os fields antes, se o destino
   não tiver).

6. **DADOS: Products + Price Books por sociedade + PricebookEntries**:
   - `Product2` carregados.
   - Price Books nomeados com o prefixo da sociedade (ex.: `C101 - Vehiculos y
     Motos (CR)`).
   - **PricebookEntry ativa em CRC** para cada produto, no price book onde a Opp
     vai resolver. **Este é o ponto que mais quebra** — se o produto não tiver
     entry CRC ativa no book da Opp, a conversão cria 0 OLI.

7. **Map Lead Fields (pares custom Lead→Opp)**: aplicar via UI (Setup → Object
   Manager → Lead → Map Lead Fields) OU via o metadata `LeadConvertSettings`
   (camada B). Pares mínimos: `CompanyCode__c`, `Brand__c`, `NationalId__c`,
   `PreferredContactMethod__c`.
   > CUIDADO: deploy de `LeadConvertSettings` **substitui o arquivo inteiro**.
   > Fazer retrieve do destino, **mesclar** os pares e só então deployar — ou
   > aplicar os pares direto na UI.

---

## 3. Metadata a levar (camada B)

Componentes (nomes reais confirmados no org), no `package.xml` desta pasta:

| Tipo | Membro | O que é |
|---|---|---|
| ObjectHierarchyRelationship | `LeadItemToOppItemOOBMappings` | Mapping LeadLineItem→OLI. **Conteúdo final: `Quantity` + `UnitPrice` + `CurrencyIsoCode`.** |
| ObjectHierarchyRelationship | `LeadPrefToOppPrefOOBMappings` | Mapping LeadPreferredSeller→OppPreferredSeller (vendedor). |
| Flow | `Lead_AS_EstampaRTOpp` | Carimba RecordType/etapa na Opp convertida. |
| LeadConvertSettings | `LeadConvertSettings` | Pares custom do Map Lead Fields. |

### Por que o mapping é "magro" (crítico entender)
- `OpportunityLineItem.Product2Id` é campo **DERIVADO** → **não pode** ser
  mapeado (dá `INVALID_INPUT`). Quem resolve o produto é a **própria
  transformação**, a partir do `LeadLineItem.ProductId` + o PricebookEntry do
  price book da Opp. **Não adicionar Product2Id.**
- `UnitPrice` é **obrigatório** no mapping: a transformação exige um preço para
  construir o OLI (sem ele → 0 OLI, comprovado). O Sales Price do OLI carrega o
  `UnitPrice` do LeadLineItem. O **List Price** (catálogo) já resolve sozinho do
  PricebookEntry, independente disso.
- Mapping final = **`Quantity` + `UnitPrice` + `CurrencyIsoCode`**.

---

## 4. Passo a passo no VS Code (Salesforce CLI)

Pré: extensão Salesforce Extension Pack + `sf` CLI. Autorizar os dois orgs:
```bash
sf org login web -a DevSales          # origem (já configurada)
sf org login web -a QA                # destino (repetir por ambiente)
```

**1) Retrieve do DevSales (traz o estado que funciona para o projeto git):**
```bash
sf project retrieve start -x deploy/promocao-hu025/package.xml -o DevSales
```
Revisar o diff no git. Conferir especialmente que
`LeadItemToOppItemOOBMappings` tem só `Quantity` + `CurrencyIsoCode`.

**2) (Recomendado) Validar o deploy sem gravar (check-only + testes):**
```bash
sf project deploy validate -x deploy/promocao-hu025/package.xml -o QA
```

**3) Deploy no destino:**
```bash
sf project deploy start -x deploy/promocao-hu025/package.xml -o QA
```

**4) Ativar o Flow** (se subir como Inactive): Setup → Flows →
`Lead_AS_EstampaRTOpp` → Activate. (Ou garantir `status=Active` no metadata.)

> Alternativa MDAPI: os `.settings`/`.flow` também estão versionados neste repo
> (`deploy/mappings-hu025/` e `deploy/flows/`) e podem ir por
> `sf project deploy start --metadata-dir <pasta>` se o time preferir.

---

## 5. Teste de fumaça no destino (obrigatório)

1. Criar um Lead da sociedade (com `CompanyCode__c` preenchido, ex.: C101).
2. Adicionar 1 **LeadLineItem** (Product + Quantity + Unit Price) — e, para
   testar o vendedor, 1 **LeadPreferredSeller**.
3. Aguardar o OmniRouting soltar o lead (senão `RECORD_IN_USE_BY_WORKFLOW`).
4. **Converter.**
5. Conferir na Opp:
   - Related list **Products (1)** com o produto, **Sales Price = preço de
     catálogo** (não "1"), Quantity correto.
   - Related list **Preferred Seller (1)** com o vendedor.
6. Query de conferência:
   ```sql
   SELECT Id, Opportunity.Pricebook2.Name, Product2.Name,
          ListPrice, UnitPrice, Quantity, CurrencyIsoCode
   FROM OpportunityLineItem WHERE OpportunityId = '<OppId>'
   ```

**Se vier 0 OLI:** 99% é PricebookEntry — o produto não tem entry **ativa em
CRC** no price book em que a Opp caiu. Ver seção 6.

---

## 6. Price book por sociedade (DECISÃO PENDENTE — ler antes de Prod)

A Opp convertida **nasce no Standard Price Book** (comportamento nativo; não há
config nativa que atribua price book por sociedade — confirmado na doc
Salesforce; o padrão oficial é automação). Hoje, se o preço do produto for
**igual** entre Standard e o book da sociedade, a conversão traz o preço certo.

**Risco:** quando um produto tiver preço **diferente** por sociedade, a Opp no
Standard traz o preço **errado, em silêncio**.

**Salvaguarda (padrão Salesforce, sem flow novo):** estender o before-save
`Opp_BS_EstampaRT` para também carimbar `Pricebook2Id` a partir do
`CompanyCode__c` (buscar o `Pricebook2` cujo nome começa com o código da
sociedade). Decidir com o negócio:
- Preços uniformes entre sociedades → dispensa.
- Preços podem divergir → aplicar a salvaguarda antes de Prod.

---

## 7. Rollback

- Os mappings originais (OOB, quase vazios) estão em
  `deploy/mappings-hu025/backup/`. Redeploy reverte.
- O `LeadConvertSettings` do destino: fazer retrieve **antes** de qualquer
  deploy para ter o backup local.
- Flow: desativar a versão nova e reativar a anterior em Setup → Flows.

---

## 8. Checklist rápido de promoção

- [ ] Toggle Partner Lead Management ligado (cria os OOB).
- [ ] Permission Set Licenses atribuídas.
- [ ] Multimoeda + CRC.
- [ ] Record Types de Opportunity.
- [ ] Campos custom (Lead + Opp) presentes.
- [ ] Products + Price Books + **PricebookEntry CRC ativa**.
- [ ] Deploy do `package.xml` (mappings + flow + convert settings).
- [ ] Flow `Lead_AS_EstampaRTOpp` ativo.
- [ ] Map Lead Fields conferido (não sobrescrito).
- [ ] Teste de fumaça: produto + vendedor + preço automático.
- [ ] Decisão price book por sociedade (seção 6).
