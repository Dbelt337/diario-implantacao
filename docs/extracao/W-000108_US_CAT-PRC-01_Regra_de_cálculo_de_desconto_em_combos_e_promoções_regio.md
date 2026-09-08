# W-000108 — US CAT-PRC-01 — Regra de cálculo de desconto em combos e promoções regionais

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:18 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:18 por Diego Beltrão de Moraes

US de catálogo/CPQ (agenda presencial 03/09: ação "Definir regra de desconto"; temas "Aplicação de Promoções e Descontos Regionais em Combos" e "Comportamento do Carrinho e Repricagem").

NARRATIVA
Como Gestão de Produtos, quero uma regra única e documentada de como o desconto de combo é calculado, onde ele incide e como se comporta quando o cliente troca um componente ou muda de zona, para que o preço final seja o mesmo na loja, no e-commerce e na fatura.

CONTEXTO E CENÁRIO DE NEGÓCIO
A TEC-B2C-02 (W-000085) define que combos são Promotions com ajuste fixo na linha do SVA e que combinações com variação drástica ganham linha dedicada na matriz. Falta a regra matemática em si: base de cálculo, ordem de aplicação com o preço regional, comportamento na repricagem e limites. Sem isso cada canal calcula de um jeito.

REGRAS DE NEGÓCIO
RN-01 Ordem de aplicação: preço da Price List do segmento → Price List Entry da zona de preço → ajuste da Promotion → desconto contratual (Discount); nunca em outra ordem.
RN-02 Incidência: o benefício do combo incide na linha do SVA/streaming; a linha de internet mantém valor cheio (exigência fiscal já registrada).
RN-03 Valor fixo, não percentual: o ajuste da Promotion é valor fixo por combinação; combinações com variação drástica têm linha própria na matriz, sem cálculo derivado.
RN-04 Repricagem: ao trocar a velocidade dentro do combo, o sistema reprecifica a internet pela matriz e mantém o ajuste do SVA; ao remover o SVA, o combo deixa de existir e a internet volta ao preço de lista.
RN-05 Regional: a Promotion pode ser restrita por zona de preço; fora da zona ela não é oferecida, e não existe "desconto regional" adicional sobre o combo.
RN-06 Piso: nenhum componente pode ficar abaixo do floor definido na matriz após todos os ajustes; se ficar, o carrinho bloqueia.
RN-07 Rastreabilidade: o identificador da promoção é herdado por todas as linhas da ordem, para faturamento e relatórios.

ESPECIFICAÇÃO TÉCNICA
Promotions (vlocity_cmt__Promotion__c) com PromotionItems e adjustments fixos; Pricing Context Rules por zona nas Price List Entries; regra de validação de floor no carrinho (Cart validation) e no checkout.
Documento de regra de preço anexado à work com exemplos numéricos (ex.: internet 600M + streaming: R$ 189 por R$ 150 como linha dedicada).
Testes de paridade entre carrinho do vendedor e Digital Commerce (mesmo cálculo via APIs cacheáveis).

DEPENDÊNCIAS E RISCOS
Dependências: W-000085; US CAT-ZON-01 (zonas de preço); matriz de preços da planilha mestre; definição de floors pela gestão de produtos.
Riscos: promoções com penalidade não são suportadas nas APIs cacheáveis do Digital Commerce; ofertas expiradas não saem do cache automaticamente.

CRITÉRIOS DE ACEITE
Cenário 1: Cálculo padrão. Dado um combo internet 600M + streaming na zona A, quando adicionado ao carrinho, então a internet mostra valor cheio da zona A e o streaming mostra o valor com o ajuste fixo do combo.
Cenário 2: Troca de velocidade. Dado o combo no carrinho, quando o vendedor troca para 700M, então a internet é reprecificada pela matriz e o ajuste do streaming permanece.
Cenário 3: Piso. Dado um desconto contratual adicional, quando o valor de um componente ficar abaixo do floor, então o carrinho bloqueia e informa o piso.
Cenário 4: Paridade de canais. Dado o mesmo combo e endereço, quando precificado no carrinho do vendedor e no e-commerce, então os valores são idênticos.
