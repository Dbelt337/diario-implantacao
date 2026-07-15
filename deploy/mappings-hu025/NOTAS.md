# HU-025 — Conversão de Lead com Line Items e Preferred Sellers (Automotive Cloud)

## Decisão final (15/07/2026)

**Solução 100% nativa — sem Apex, sem flow novo e sem pacote de mappings.**

1. **Partner Lead Management Default Mappings** habilitado no Setup
   (Sandbox DevSales, 15/07/2026). A conversão do Lead passa a copiar
   automaticamente, via Transformations API interna:
   - `LeadLineItem` → `OpportunityLineItem`
   - `LeadPreferredSeller` → `OpportunityPreferredSeller`
2. **Describe dos 4 objetos filhos conferido via Anonymous Apex
   (log 07LWK00000PXu9w2AD): nenhum campo custom.** Portanto o metadado
   `ObjectHierarchyRelationship` (TransformationMapping) NÃO é necessário —
   o pacote de placeholders que existia nesta pasta foi removido.
3. O flow `Lead_AS_EstampaRTOpp` (versionado em `deploy/flows/`) permanece
   inalterado: estampa RecordType e etapa inicial na Opp convertida conforme
   `Lead.Industry`.

## Campos custom Lead → Opportunity (fora do escopo deste metadado)

Os campos custom estão nos objetos PAI. Mapeiam via *Map Lead Fields*
(Setup → Object Manager → Lead → Map Lead Fields / metadado
`LeadConvertSettings`). Pares identificados:

| Lead | Opportunity | Obs |
|---|---|---|
| `Brand__c` | `Brand__c` | Marca |
| `CompanyCode__c` | `CompanyCode__c` | Sociedad — define Price Book |
| `NationalId__c` | `NationalId__c` | Text 17 → TextArea 255 |
| `PreferredContactMethod__c` | `PreferredContactMethod__c` | |
| `BlacklistStatus__c` | `ListaNegraStatus__c` | confirmar intenção |

Sem mapeamento: `Country__c` → `Pais__c` (destino é fórmula na Opp).

CUIDADO: deploy de `LeadConvertSettings` substitui o arquivo inteiro —
aplicar os pares na UI e depois fazer retrieve para versionar aqui, ou
mesclar com o retrieve atual antes de qualquer deploy.

## Lacuna conhecida — DESCARTADA (15/07/2026)

Os campos standard do `LeadLineItem` `PriceType`, `InterestType`,
`Classification`, `Condition` e `ItemType` não têm equivalente no
`OpportunityLineItem` e se perdem na conversão. **Decisão: não precisa**
carregá-los para a Opp. Se o negócio mudar de ideia: criar campos custom no
`OpportunityLineItem` e criar o pacote `ObjectHierarchyRelationship`
(modelo no histórico do git deste repo, commit 563f646).

## Estado dos flows de Record Type (15/07/2026)

Dois flows para o mesmo problema (estampar RT da linha na Opp), ambos
versionados em `deploy/flows/`. NENHUM chama a Transformations API — a
cópia de line items é 100% do toggle nativo, camada independente.

- `Lead_AS_EstampaRTOpp` — **Active**. After-save no Lead convertido.
  Estampa RT + etapa inicial, lê `Lead.Industry`. É o que vale hoje.
- `Opp_BS_EstampaRT` v3 — **Obsolete (inativo)**. Before-save no create da
  Opp (banda 10), lê `Account.Industry`, cobre todos os canais de criação.
  Substituto planejado ("Desactivar Lead_AS_EstampaRTOpp tras validar").

Lacunas a resolver ANTES de ativar o Opp_BS e desativar o Lead_AS:
- [ ] Opp_BS não estampa etapa inicial (Open_Stage só existe no Lead_AS).
- [ ] Conversão para Account EXISTENTE: `Account.Industry` pode divergir do
      Lead ou estar vazio → RT errado ou default Autos indevido.
- [ ] Confirmar divergências de regra: Repuestos/PA (D-REP-01: sem RT no
      Opp_BS vs. GQOpportunitiesRepuestosPA no Lead_AS) e default quando
      Industry vazio (Autos no Opp_BS vs. no-op no Lead_AS).
- [ ] Pendências da própria description: braço Venta_Mayorista e fallback
      `TipoAutoQueVende__c` (deploy rejeitou o campo — investigar).

## Checklist de teste (DevSales)

- [ ] Converter Lead com line items + preferred seller e conferir cópia dos filhos.
- [ ] Conferir qual Price Book a Opp convertida recebe (desenho: 1 book por
      sociedade; `OpportunityLineItem` depende de `PricebookEntry` do book certo).
- [ ] Conferir interação com `Lead_AS_EstampaRTOpp` (RT + etapa) na mesma transação.
- [ ] Aplicar os 5 pares no Map Lead Fields e testar campos do pai.
