# W-000069 — US B2C-13 — Seleção Guiada, Combos Promocionais e Filtro Dinâmico por IBGE

Épico: B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 20/08/2026 18:30 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:50 por Diego Beltrão de Moraes

"Como Consultor de Vendas B2C ou Cliente da jornada de autosserviço (E-commerce / App)
Quero visualizar e adicionar ao carrinho de cotação apenas as ofertas e combos promocionais elegíveis e com viabilidade técnica para o endereço selecionado , podendo compor e customizar pacotes (Internet + SVAs/Streaming)
Para que a Brasil TecPar garanta uma venda guiada sem erros de oferta , evite a comercialização de serviços indisponíveis na região e aumente o Ticket Médio/ARPU de forma automatizada e segura.

SOLUÇÃO TÉCNICA — integra com a US QUAL-01 (W-000056) já criada: os 5 catálogos por mercado, as
categorias por família e os Rule Sets globais de qualificação (QUAL_MERCADO, QUAL_CANAL,
QUAL_TIPO_CLIENTE, QUAL_CIDADE) são daquela work; esta cobre a EXECUÇÃO do filtro no funil B2C.
FATO VERIFICADO no registro de interfaces de produção: o filtro de prateleira está DESLIGADO —
ProductAvailability/ProductEligibility rodam nas implementações Default e as alternativas
(FilterAvailability, FilterEligibility, CtxRulesProductsOpen) estão presentes e INATIVAS; context
rules ativas só para preço. A work inclui LIGAR e implementar o filtro — mecanismo conforme a versão
do pacote CMT [DEFINIR]: interfaces Availability & Eligibility (Summer '26) ou context rules clássicas.
Combos: vlocity_cmt__Promotion__c agregando produtos existentes, adjustment FIXO na linha do SVA
(razão fiscal), identificador da promoção herdado nos itens da ordem. Dimensão cidade→zona (IBGE)
alimentada pelo Premises (W-B2C-02), alinhada à GeographicCommercialPolicy (P-17). Preço B2C/B2B por
Price Lists separadas, produto único.

Dependências: P-19 (domínios de qualificação — Joel); P-17 (IBGE); US QUAL-01/EPC-01/EPC-04;
versão do pacote; confirmar com o AE o que os seats on-core (Product Catalog Management, Unified
Catalog) destravam.

Fonte: Histórias Refinadas B2C (19/08) + Desenho Técnico B2C (20/08), seção W-B2C-13."

## Critérios de Aceite (related list)

**1. 2** (New)
Adição de Combo Promocional com Desconto Direcionado ao SVA — Dado que o consultor selecionou o combo promocional "Internet 700MB + HBO Max" ; Quando o combo for inserido no carrinho de cotação ; Então o sistema deve aplicar o valor do desconto fixo exclusivamente sobre a linha do produto HBO Max (SVA) e gravar o identificador Group Promotion ID no cabeçalho/linhas da cotação.

**2. 1** (New)
Exibição de Produtos e Combos Filtrados pelo Endereço de Instalação — Dado que o vendedor inseriu o endereço de instalação qualificado para a Cidade/IBGE "X" e com viabilidade técnica de fibra confirmada ; Quando a tela de seleção do catálogo for aberta ; Então o Salesforce CPQ deve exibir apenas as opções de internet e combos promocionais elegíveis para aquele endereço , omitindo planos e velocidades sem cobertura técnica na região.

**3. 3** (New)
Customização de Atributos no Carrinho e Recálculo Dinâmico — Dado que um combo promocional está adicionado ao carrinho; Quando o usuário alterar o atributo de velocidade da internet (ex: de 600MB para 700MB) ou adicionar um SVA opcional adicional; Então o motor do CPQ deve reprocessar o cálculo do carrinho em tempo real , somando a diferença de valor da nova velocidade ao montante mensal total da cotação.

## Notas de Refinamento e Decisões Registradas

--- NAVEGACAO POR FAMILIA (04/09, ata de 03/09) ---
A execucao do filtro no funil B2C deve apresentar a vitrine por FAMILIA (Internet, Stream, Camera, Movel), conforme decisao das sessoes de pratica de catalogo. Alinhado com o ajuste registrado na US QUAL-01 (W-000056).

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #6/#7).
REUSAR: BTecParPF_Cart (selecao/configuracao sobre PL_B2C) e BTecParPF_UpdateWorkingCart/CPQ_updateCarts (atualizacao do carrinho).
EVIDENCIA: vlocity-backup/OmniScript/BTecParPF_Cart_Portuguese-Brazil | vlocity-backup/IntegrationProcedure/BTecParPF_UpdateWorkingCart.
CONSTRUIR: LIGAR o filtro de prateleira (fato ja registrado nesta work: implementacoes FilterAvailability/FilterEligibility presentes e INATIVAS), combos via Promotion e dimensao cidade/zona.
DIRETRIZ SYSMAP: evoluir o Cart existente; validar produto movel (gap #21) e navegacao por familia conforme nota anterior.

--- ZONA DE PRECO NO FUNIL (decisao 03/09) ---
Alem da zona de DISPONIBILIDADE (habilita/oculta ofertas), o funil deve resolver a zona de PRECO do endereco qualificado e passa-la como contexto do carrinho, para as Price List Entries por zona (W-000085) precificarem corretamente. O prazo de contrato (12/24/36/48/60) e selecionado no passo de oferta e o preco e recalculado ao trocar o prazo - nao e um campo posterior de faturamento.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, B2C - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente, has been added.
- Diego Beltrão de Moraes 31/08/2026 19:13: Subject changed from US B2C-13 — Seleção Guiada de Produtos, Formação de Combos/Promoções e Filtro Dinâmico por Endereço to US B2C-13 — Seleção Guiada, Combos Promocionais e Filtro Dinâmico por IBGE
