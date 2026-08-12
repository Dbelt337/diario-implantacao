# ADR-002 — Onde vivem os acessórios: OpportunityLineItem vs QuoteLineItem

**Data:** 12/08/2026 · **Contexto:** pergunta do Davi ("os acessórios não estão sendo criados no OpportunityLineItem — isso deveria refletir na opportunity?")
**Status:** decidido, com 3 limitações documentadas a tratar no desenho.

## Veredito

O desenho está **coerente**, mas com uma **correção importante** sobre a minha primeira leitura: não é que o `OpportunityLineItem` "não deva ter acessórios" — o Automotive Cloud **espera** OLIs com veículo + acessórios. O que está certo é **quem os escreve e quando**: não é o fluxo de cotização.

## Fundamentação (docs oficiais)

1. **Automotive Cloud modela acessórios como line item desde o Lead:** `LeadLineItem` — *"Represents items such as vehicles, accessories, and parts that a lead is interested in"* (API 56+).
2. **E fornece transformação OFICIAL `LeadLineItem → OpportunityLineItem`** (Automotive Cloud Developer Guide → Transformations). Ou seja: na conversão do lead, a oportunidade **nasce com OLIs** de veículo e acessórios de interesse. Isso é modelo Automotive, não invenção.
3. **O Automotive NÃO estende Opportunity, Quote nem QuoteLineItem** — a seção oficial "Automotive Cloud Fields on Standard Objects" cobre Lead, Product2, Asset, ApplicationForm*, BusinessProfile, InternalOrganizationUnit. Do estágio de oportunidade para frente, vale **Sales Cloud puro**.
4. **Sales Cloud:** cada oportunidade pode ter **várias quotes**; **uma** pode ser sincronizada (`Opportunity.SyncedQuoteId`). Com o sync ativo, mudança nas QLIs reflete nos produtos da opp e vice-versa.

## Decisão: três momentos, três donos

| Momento | Quem escreve | O quê |
|---|---|---|
| Conversão do Lead | Transformação Automotive (`LeadLineItem → OpportunityLineItem`) | OLIs de **interesse** (veículo + acessórios) = valor do pipeline |
| Venta guiada | Nosso código (`QuoteOrderService`) | **QLIs por cotização** — cada quote é um cenário (modelo/config/acessórios/desconto diferentes) |
| Aceitação da quote | **Nativo** (`SyncedQuoteId`) | A opp passa a **refletir a quote ganhadora** — veículo e acessórios |

**O fluxo guiado nunca escreve OLI à mão.** Duas razões: (i) contabilidade dupla (quote diz uma coisa, opp outra) e (ii) não existe resposta para "qual das N quotes a opp mostraria?". O elo que falta hoje é **setar `SyncedQuoteId` no flow de aceitação** (`Quote_Aceptada_Genera_Pedido`).

## Três limitações oficiais do sync que ENTRAM no desenho

1. **Só campos padrão sincronizam** — campos custom (ex.: `AvailabilityStatus__c`) não propagam para a opp. Se o negócio precisar deles lá, é automação nossa explícita, não sync.
2. **Oportunidade não suporta bundles nem atributos de produto** — os KITs da HU-043 (GQ-PV-02-029) não chegam como estrutura: entram como produtos individuais ou só o pai. Decisão de negócio: o que a opp deve mostrar de um kit.
3. **Pré-condições que fazem o sync falhar em silêncio:** quote com Pricebook definido e **opp com `Pricebook2Id` vazio**, ou QLI apontando para **PricebookEntry inativa**. Nosso `createQuote` deve garantir que a opp tenha o mesmo pricebook da quote.

## Ações (ordem obrigatória)

1. **Resolver a automação da org que remove OLIs de acessórios** (investigação aberta desde 11/08, achada pela suíte de testes) — ligar o sync antes disso faz a automação brigar com o espelhamento nativo.
2. Garantir `Opportunity.Pricebook2Id` = pricebook da quote na criação.
3. Setar `SyncedQuoteId` no flow de aceitação e validar que veículo + acessórios aparecem na opp.
4. Levar a limitação 2 (kits na opp) ao negócio como decisão consciente.

## Fontes

- LeadLineItem — Automotive Cloud Developer Guide: `developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_leadlineitem.htm`
- Transformations (LeadLineItem → OpportunityLineItem) — Automotive Cloud Developer Guide: `.../auto_resources_transformations.htm`
- Automotive Cloud Standard Objects / Fields on Standard Objects (Automotive não estende Opportunity/Quote)
- Considerations for Syncing Quotes and Opportunities — Salesforce Help (campos padrão; bundles/atributos não suportados)
- Troubleshoot Opportunity/Quote sync — Salesforce Help (pricebook da opp vazio; PBE inativa)
