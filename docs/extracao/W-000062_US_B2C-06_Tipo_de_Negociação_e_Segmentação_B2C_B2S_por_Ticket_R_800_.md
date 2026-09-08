# W-000062 — US B2C-06 — Tipo de Negociação e Segmentação B2C/B2S por Ticket (< R$ 800)

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:19 por Diego Beltrão de Moraes | Alterado: 31/08/2026 19:13 por Diego Beltrão de Moraes

"Como Vendedor B2C e Administrador do Catálogo (CPQ)
Quero selecionar o Tipo de Negociação no início da criação da Oportunidade e ter a segmentação automática entre B2C e B2S aplicada no carrinho por Ticket Médio
Para que o sistema direcione o fluxo correto (Normal, Cortesia ou Swap) e carimbe automaticamente a categoria comercial sem intervenção manual do operador.

SOLUÇÃO TÉCNICA (native-first): REUSAR NegotiationType__c (""Tipo negociação"", picklist EXISTENTE na
Opportunity) para Normal/Cortesia/Swap em vez dos Record Types novos da especificação original — RT
novo replica páginas/perfis/automações; tradeoff a registrar com o negócio. VERIFICAR os campos
EXISTENTES Quote.MarketSegment__c e Quote.MarketType__c antes de criar Opportunity.Segment__c — a
segmentação pode já ter casa. Cálculo no reprice do carrinho Vlocity (price rule/pricing plan do
pacote, não SF CPQ): total < R$ 800 → B2C; >= R$ 800 → B2S; recálculo a cada alteração do carrinho;
Segment no payload de ordem (MuleSoft → Customer Core/ERP).

Dependências: aprovação do negócio para picklist vs Record Type; levantamento dos valores atuais
de MarketSegment__c/MarketType__c.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-06."

## Critérios de Aceite (related list)

**1. 2** (New)
Segmentação Automática para B2S por Ticket Médio >= R$ 800,00 — Dado que uma Oportunidade do tipo "Venda Normal" está no carrinho de compras; Quando os produtos são adicionados e o valor total atinge R$ 850,00; Então o Salesforce deve atualizar o campo de segmento automaticamente para "B2S".

**2. 1** (New)
Seleção do Tipo de Negociação ao Criar Oportunidade — Dado que o vendedor está iniciando a criação de uma nova Oportunidade; Quando o formulário é carregado; Então o sistema deve exigir a escolha do tipo de negociação entre "Venda Normal", "Venda Cortesia" ou "Venda Swap".

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-06 — Tipo de Negociação no Início da Oportunidade e Segmentação B2C/B2S por Ticket Médio to US B2C-06 — Tipo de Negociação e Segmentação B2C/B2S por Ticket (< R$ 800)
