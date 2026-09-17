# Modelagem robusta de catálogo e preço no EPC/CPQ (17/09/2026)

Pergunta do Diego: 400 produtos, 20 a 30 variações cada, 5 mercados, 5 prazos, 4 zonas. Qual a melhor modelagem para não
ter problema de desempenho? Pesquisa em documentação Salesforce, Trailhead, Apex Hours, Vlocity Build e comunidade
(links no fim; as páginas não abrem daqui, o texto vem dos resumos de busca; o Diego confirma abrindo os links).

## O que a documentação e a comunidade dizem (com número)

| Regra | Fonte |
|---|---|
| Attribute-based pricing: um produto só, atributos, e uma matriz que precifica cada combinação. "Reduz o número de produtos no catálogo". Desde Summer '23 suporta matrizes com **mais de 50.000 linhas** (via Business Rules Engine). Preço na matriz como decimal (329.00), nunca inteiro, para as Standard Cart APIs. | Help "Attribute-Based Pricing", "Pricing Matrices for ABP", Dev "Set up Attribute-Based Pricing" |
| Existe **range attribute-based pricing**: faixas em vez de linhas discretas ("matrizes podem representar faixas, o que as mantém pequenas"). | Trailhead "Set Up Range Attribute-Based Pricing" |
| Até **50 atributos por produto** são suportados, mas "um produto com 1 atributo performa melhor que com 5, que performa melhor que com 10". Minimizar. | Stratus Carta, Industries CPQ Performance Best Practices |
| Hierarquia de produto: **no máximo 4 níveis incluindo o bundle raiz**; muitos filhos com cardinalidade padrão >= 1 e hierarquia acima de 3 ou 4 níveis degradam o carrinho. | Apex Hours EPC Best Practices; Stratus Carta |
| **Regras dinâmicas (context rules e advanced rules) têm impacto de desempenho** e aumentam manutenção; preferir configuração estática (cardinalidade, atribuição de atributos, virtual items) sempre que atender. | Apex Hours "Reduce Advanced Product Rule Usage"; Trailhead Context Rules |
| Deploy de matriz grande pelo Vlocity Build: 77.000 linhas deram "Too many DML rows: 10001"; matriz grande sobe por CSV na tela ou em lotes. | vlocity_build issue #169 |
| Standard Cart APIs (Winter '24+) usam **Scale Cache** e métodos de preço reescritos com menos SOQL e DML; Enhanced LWC cart recomendado para bundles complexos. Ajustes: Price Batch Size alto, "Compute Totals In Separate Step". | Dev "Standard Cart APIs"; Stratus Carta |
| A org cacheia a hierarquia de produto (JSON), regras e propriedades de linha; carga nova exige limpar e reaquecer o cache. | Apex Hours EPC |
| Automações em Opportunity, Quote, Order e itens de linha fora do padrão são a causa mais comum de lentidão do CPQ. | Stratus Carta |

## A modelagem recomendada (o que o Control Plane deve gerar)

### 1. Produto: uma oferta comercial por família, variação por atributo, filho só quando é vendável separado

- **Um Product2 por oferta comercial**, não por variação. Banda, tier de NOC, tamanho de armazenamento, perfil de upload
  são **atributos**; a matriz precifica a combinação. É o que a Salesforce chama de "reduz o número de produtos".
- **Filho (Product Child Item) só para o que aparece como linha própria** no carrinho, na fatura ou no ativo: roteador,
  extensor, token físico, licença por usuário, SVA. Filhos com cardinalidade mínima 0 (opcionais) custam menos que
  obrigatórios, porque não entram no carrinho até serem escolhidos.
- **No máximo 3 níveis** (oferta > produto comercial > componente técnico). O quarto nível fica de reserva.
- **Até 10 atributos por produto** como meta interna (a Salesforce suporta 50, mas cada um custa). Atributo técnico que
  o carrinho não precisa mostrar vai como oculto ou fica no OM, não no produto.
- **Picklist com mais de 40 valores vira outra coisa**: lista de modelos (Tipo Appliance 214, SD-WAN 157, Notebook 132)
  vira produtos filhos em grupo de escolha ou catálogo de equipamentos com busca; lista numérica contínua (armazenamento
  121 tamanhos, memória 91) vira **atributo numérico com faixa** e range pricing, não 121 valores.
- Dos 183 componentes do Core, 125 são picklist; a regra acima reduz para cerca de 100 picklists pequenas e move 7 para
  filhos ou faixa.

### 2. Preço: matriz pequena por família, fatores fora da matriz

Quatro objetos, nesta ordem de preferência:

1. **Matriz base** (Calculation Matrix `MTX_PRECO_<FAMILIA>`): entradas ProductCode (ou família), atributo de preço
   (banda), zona de preço; saída BasePrice e FloorPrice. **Uma matriz por família** (Conectividade, Voz, TV, Cloud,
   SVA), não por produto. Só entram na matriz os atributos que mudam preço.
2. **Fatores** (matriz `MTX_FATOR`): prazo e mercado como multiplicador, com linha "*" e sobrescrita por família ou
   produto quando precisar. 25 linhas resolvem 5 prazos x 5 mercados.
3. **Zona de preço**: 4 zonas como coluna da matriz base; cidade -> zona por tabela de-para (Context Mapping), nunca
   regra por cidade. Se só duas cidades fogem do padrão, sobrescrita nessas duas.
4. **Faixas** onde o atributo é numérico contínuo (armazenamento, memória, vCPU, usuários): range pricing por faixa,
   não uma linha por valor.

Pricing Plan com **três passos**: base (matriz 1), fator (matriz 2), piso para aprovação. Nada de lógica de aprovação
ou desconto dentro do plano: o piso é só uma saída que o fluxo de Aprovação Comercial lê.

### 3. Disponibilidade e elegibilidade: dimensões, não regras

- 4 dimensões de contexto: mercado, canal, zona de preço, zona de disponibilidade. Valores vêm da conta e do endereço.
- Elegibilidade por **regra por zona** (4 regras), não por cidade (5.570). Segmento B2B/B2C como dimensão, não como
  produto duplicado.
- Advanced rules só para incompatibilidade real entre filhos (ex.: NOC Premium exige porta 1G). O resto é cardinalidade
  e atribuição estática.

### 4. Ambiente e execução

- Enhanced LWC cart e Standard Cart APIs ligadas (Scale Cache). Testar o carrinho por API no Pós-carga.
- Price Batch Size ajustado por medição; Compute Totals In Separate Step ligado.
- Depois de cada carga: jobs de hierarquia, atributos, pricebook e **limpeza e reaquecimento do cache**.
- Automações em Opportunity, Quote e Order revisadas (a org já tem 18 flows retrieveados; os de Opportunity precisam de
  leitura antes da carga de catálogo).

## Dimensionamento do caso do Diego (400 produtos)

| Modelo | Conta | Linhas de matriz | Avaliação |
|---|---|---|---|
| Tudo expandido | 400 x 25 x 5 x 5 x 4 | 1.000.000 | Não. 2 GB por versão, deploy em lotes de 10.000, reajuste em massa |
| Prazo e mercado como fator | 400 x 25 x 4 | 40.000 | Funciona; ainda conta variação que não muda preço |
| Só atributos que precificam (2 a 3 por produto, ~8 valores) | 400 x 8 x 4 | 12.800 | Confortável |
| Matriz por família (5) com faixas | 5 famílias x ~60 combinações x 4 zonas | ~1.200 + 25 fatores | O alvo |

Régua: até 50 mil linhas por matriz confortável; 50 a 200 mil exige CSV em lotes e versão controlada; acima disso é
fator ou faixa que virou linha.

## O que o Control Plane precisa aplicar para gerar isso

1. Marcar em cada atributo se **precifica** (entra na matriz) ou não.
2. Marcar atributo numérico como **faixa** quando tiver mais de 20 valores contínuos.
3. Gerar **uma matriz por família**, com BasePrice e FloorPrice, e a matriz de fatores separada.
4. Exportar cidade -> zona de preço e cidade -> zona de disponibilidade como tabelas, não como regras.
5. Travar: produto com mais de 10 atributos, picklist com mais de 40 valores, hierarquia com mais de 3 níveis, matriz
   com mais de 50 mil linhas. Cada trava vira pendência na Decisão de Modelagem.

## Fontes

- Help: Attribute-Based Pricing https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing.htm
- Help: Pricing Matrices for Attribute-Based Pricing https://help.salesforce.com/s/articleView?id=ind.comms_pricing_matrices_for_attribute_based_pricing.htm
- Dev: Set up Attribute-Based Pricing (Cart APIs) https://developer.salesforce.com/docs/industries/cme/guide/comms-set-up-attribute-based-pricing-cart.html
- Trailhead: Set Up Range Attribute-Based Pricing https://trailhead.salesforce.com/content/learn/modules/industries-attribute-based-pricing/set-up-range-attribute-based-pricing
- Dev: Standard Cart APIs (Scale Cache) https://developer.salesforce.com/docs/industries/cme/guide/std-cart-get-started.html
- Stratus Carta: Industries CPQ Performance Best Practices https://www.stratuscarta.com/post/industries-cpq-performance-best-practices
- Apex Hours: EPC Best Practices https://www.apexhours.com/enterprise-product-catalog-epc-best-practices/
- Apex Hours: Reduce Advanced Product Rule Usage https://www.apexhours.com/how-to-reduce-advanced-product-rule-usage-in-industries-cpq/
- Help: EPC Best Practices for Product Object Types https://help.salesforce.com/s/articleView?id=ind.comms_epc_best_practices_for_product_object_types.htm
- Trailhead: Context Rules https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/meet-context-rules
- vlocity_build issue #169 (matriz de 77 mil linhas) https://github.com/vlocityinc/vlocity_build/issues/169
- Revolent: 5 best practices for Communications Cloud https://www.revolentgroup.com/blog/salesforce-communications-cloud-implementation/
