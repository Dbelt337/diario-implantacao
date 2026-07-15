# HU-025 — Conversão de Lead com Line Items e Preferred Sellers (Automotive Cloud)

## Contexto (15/07/2026)

A conversão padrão de Lead não carrega os objetos filhos `LeadLineItem` e
`LeadPreferredSeller` para a Opportunity. A solução adotada foi **nativa, sem
Apex e sem alterar o flow**:

1. **Partner Lead Management Default Mappings** habilitado no Setup
   (Sandbox DevSales, 15/07/2026). Com isso a própria conversão invoca a
   Transformations API (`/connect/*/transformations`) internamente e copia:
   - `LeadLineItem` → `OpportunityLineItem`
   - `LeadPreferredSeller` → `OpportunityPreferredSeller`
   (campos standard mapeiam automaticamente)
2. **Campos custom** exigem mapping manual via metadado
   `ObjectHierarchyRelationship` (`usageType = TransformationMapping`) —
   é o pacote desta pasta.

O flow `Lead_AS_EstampaRTOpp` (versionado em `deploy/flows/`) permanece
inalterado: ele só estampa RecordType e etapa inicial na Opp convertida,
conforme a linha do negócio lida de `Lead.Industry`.

## Pendências antes do deploy deste pacote

- [ ] Substituir os placeholders `CAMPO_ORIGEM_1__c` / `CAMPO_DESTINO_1__c`
      pelos API names reais (o deploy FALHA de propósito com os placeholders).
- [ ] Criar os campos custom de destino no `OpportunityLineItem` /
      `OpportunityPreferredSeller` antes do deploy dos mappings.
- [ ] Se a org for multicurrency, descomentar o mapping de `CurrencyIsoCode`.
- [ ] Se não houver campos custom no `LeadPreferredSeller`, remover o member
      correspondente do `package.xml` e apagar o arquivo.
- [ ] Testar conversão no DevSales verificando: filhos copiados + **qual Price
      Book a Opp convertida recebe** (desenho é 1 Price Book por sociedade;
      `OpportunityLineItem` depende de `PricebookEntry` do book certo).
- [ ] Atenção: campos custom no **Lead** (objeto pai) NÃO usam este metadado —
      esses mapeiam em Setup → Object Manager → Lead → Map Lead Fields.

## Deploy

Zipar o conteúdo desta pasta (package.xml + objectHierarchyRelationships/) e
fazer deploy via Metadata API (Workbench/Postman), mesmo procedimento usado
para o flow em `deploy/`.
