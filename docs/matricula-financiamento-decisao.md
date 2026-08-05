# Matrícula do veículo — onde vive, quem calcula, onde persiste (05-06/08/2026)

Origem: pergunta do Roberto Nisti (frente financeira) em 04/08 — "vamos precisar do
valor de Matrícula do veículo para entrar nos cálculos de financiamento. Vocês
estão prevendo colocar este valor na oportunidade?"

## Decisão de arquitetura (time de vendas)

A matrícula NÃO vai para a Opportunity e NÃO é digitada por ninguém. Cadeia:

1. **Parametrização (fonte do valor)** — decisão T10 da HU-105, em aberto:
   - El Salvador (primera matrícula = percentual do precio): linha na
     **GQ_TaxMatrix** (Decision Matrix BRE), por país/sociedad, versionada,
     mantida pela área de Impuestos sem deploy.
   - Custa fixa por unidade (caso CR "matrícula + entrega"): coluna no
     **PricebookEntry** — candidato a reuso: `Gastos__c` (já existe no
     pricebook C101). Describe do PricebookEntry pendente confirma.
   - Provável misto: matriz resolve percentuais, PBE resolve valores por
     unidade; o Expression Set lê os dois.
2. **Cálculo**: Expression Set **GQ_VehiclePricing** (motor HU-038/105), no
   momento da cotización, com effective date da data da cotización.
3. **Persistência (congelamento)**: desglose da Quote/**QuoteLineItem** —
   campos de breakdown da RN-19 (T09 da HU-105, ~3-4 campos novos no QLI,
   quantidade exata pendente do describe). Valor congelado: mudança
   posterior da tabela não altera cotizaciones existentes. Mock atual:
   linha "Gastos (matrícula + entrega)" no desglose + Description.
4. **Consumo**: frente financeira recebe a matrícula como parâmetro do
   `FinancingRequest` (FinancingService — campo `matricula` a adicionar
   quando o Roberto confirmar); PDF da cotización mostra o desglose.

## Resposta combinada para o Roberto

> Roberto, não precisa ir para a Oportunidade. O valor de matrícula está no
> escopo de impostos e gastos (HU-105): ele não é digitado por ninguém — é
> calculado automaticamente no momento da cotización pelo motor de preços
> (percentual ou valor por unidade, parametrizado por país/sociedad) e fica
> congelado no desglose da Quote/QuoteLineItem.
>
> Como o fluxo de vocês é chamado dentro da venda guiada, depois desse
> cálculo, a gente te entrega o valor como parâmetro de entrada da etapa de
> financiamento — junto com monto a financiar, prima e plazo. Já deixamos o
> contrato dessa chamada pronto do nosso lado (FinancingService); o que falta
> é fecharmos juntos o contrato de entrada/saída: o que sua Integration
> Procedure precisa receber e o que devolve (opções de banco, tasa, plazo,
> cuota). Se para vocês for útil, incluo a matrícula como campo explícito no
> request.
>
> Se além disso vocês precisarem do valor persistido em algum lugar
> específico (Opportunity ou objeto do financeiro), aí é requisito novo —
> alinha com a Melisa para entrar formalmente.

## Pendências que fecham o desenho

- Describes QuoteLineItem + PricebookEntry (queries enviadas 05/08) →
  fecham T09 (campos de breakdown) e T10 (Gastos__c vs coluna nova).
- Confirmação do Roberto: Integration Procedure (OmniStudio runtime standard)
  como entrega da frente financeira + chave Type_SubType + contrato de
  entrada/saída espelhando FinancingRequest/FinancingOption.
- Ao confirmar: adicionar campo `matricula` ao FinancingRequest (uma linha
  no DTO, sem quebra).
