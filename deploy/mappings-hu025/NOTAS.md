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

## Lacuna conhecida (backlog)

Os campos standard do `LeadLineItem` `PriceType`, `InterestType`,
`Classification`, `Condition` e `ItemType` **não têm equivalente standard**
no `OpportunityLineItem` — o mapping default não os carrega e eles se perdem
na conversão. Se o negócio precisar deles na Opp: criar campos custom no
`OpportunityLineItem` e aí sim criar o pacote `ObjectHierarchyRelationship`
(modelo no histórico do git deste repo, commit 563f646).

## Checklist de teste (DevSales)

- [ ] Converter Lead com line items + preferred seller e conferir cópia dos filhos.
- [ ] Conferir qual Price Book a Opp convertida recebe (desenho: 1 book por
      sociedade; `OpportunityLineItem` depende de `PricebookEntry` do book certo).
- [ ] Conferir interação com `Lead_AS_EstampaRTOpp` (RT + etapa) na mesma transação.
- [ ] Aplicar os 5 pares no Map Lead Fields e testar campos do pai.
