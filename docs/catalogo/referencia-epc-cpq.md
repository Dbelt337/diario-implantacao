# Referência rápida EPC / Industries CPQ (Vlocity CMT) para o Catalog Control Plane

Para responder às perguntas do presidente enquanto ele configura o Control Plane. Base: Vlocity CMT 900.650.3 em
produção (Communications Cloud; EPC clássico, não o Product Catalog Management do Revenue Cloud, que está sem uso).
Nomes de objeto e campo são os do pacote `vlocity_cmt`; a sessão conectada confirma cada um com `sf sobject describe`
(tools/catalogo/consultas/README.md). Onde este texto e a org divergirem, vale a org.

Para cada tema: o que é, onde cai no template v1.1, o que a ferramenta dele precisa guardar, armadilhas.

## 1. Produto (Product2 + campos do EPC)

- **Uma tabela para tudo**: oferta, produto comercial, serviço (CFS/RFS) e recurso são todos Product2. O que os separa é
  `vlocity_cmt__SpecificationType__c` (Offer, Product, Service, Resource) e `vlocity_cmt__SpecificationSubType__c`
  (Bundle ou Simple). Template: aba Produtos, colunas Camada, Tipo de especificação e Subtipo.
- **Object Type** (`vlocity_cmt__ObjectClass__c`, campo `vlocity_cmt__ObjectTypeId__c`): a "classe de produto" da
  ferramenta. Hierarquia (tipo base BTP -> Conectividade, Voz, TV, Wi-Fi e Dispositivos, SVA). Atributos podem ser
  herdados do Object Type. Template: coluna Família. A ferramenta chama de Classe de produto.
- **Product Specification x Product**: a spec é um Product2 com tipo Product usada como molde (atributos comuns); os
  produtos comerciais apontam para ela e herdam os atributos. O copiloto pergunta "reutilizamos PS_MANAGED_CORPORATE_
  INTERNET?": é isso. Reusar spec = mesma lista de atributos.
- **Chaves**: `ProductCode` (código canônico; único; imutável depois de publicado) e `vlocity_cmt__GlobalKey__c`
  (identidade entre ambientes; o DataPack casa por ela; gerada pela ferramenta, nunca pela org).
- **Flags**: `IsOrderable` (vendável isolado), `IsConfigurable`, `IsNotAssetizable` (invertido: gera ativo), `IsActive`,
  datas de vigência (`EffectiveDate`/`EndDate` ou versão de produto).
- **Versão**: o EPC versiona produto (Product Version) e agrupa mudanças em **Projetos do EPC** (Track Product Catalog
  Changes with Projects). O Control Plane pode ser a fonte da versão; a org guarda o histórico.
- Armadilha: nome e código são coisas diferentes. O nome muda; o código não.

## 2. Estrutura do bundle (produtos filhos)

- Objeto `vlocity_cmt__ProductChildItem__c`: uma linha por par pai -> filho. Campos: `MinQuantity`, `Quantity`
  (padrão), `MaxQuantity`, `IsRootProductChildItem` (aparece como linha própria no carrinho/fatura), `IsVirtualItem`
  (grupo lógico "escolha um", sem produto físico), `ChildLineNumber` (posição hierárquica 1, 1.1, 1.2), `SeqNumber`.
- Grupo de escolha = **Virtual Item**: um filho virtual que agrupa opções; cardinalidade no grupo (0/1/1 = escolha
  exatamente um). Template: coluna Grupo de escolha.
- Obrigatório = mínimo 1. Opcional = mínimo 0. Não existe flag separada.
- **Override**: o pai pode sobrescrever atributos e preço do filho só naquele bundle (Override Definitions). Útil para
  "porta a 55,00 dentro desta oferta".
- Dois níveis na árvore comercial pelo template; o EPC aceita mais, mas o carrinho fica pesado e o OM confunde.
- Depois de carregar: job **Product Hierarchy Maintenance** (recalcula caminhos e cardinalidades). Sem ele o filho não
  aparece no carrinho.

## 3. Atributos e picklists

- Três objetos: `AttributeCategory__c` (agrupa na tela), `Attribute__c` (código, nome, `ValueType__c`: Text, Number,
  Checkbox, Date, Picklist, Multi-picklist, Lookup) e `AttributeAssignment__c` (atributo em um produto, Object Type ou
  spec: obrigatório, valor padrão, configurável na venda, oculto, somente leitura, sequência, texto de ajuda).
- Picklist é objeto próprio (`Picklist__c` + `PicklistValue__c` com código, rótulo, sequência, ativo). Um atributo
  aponta para uma picklist; várias podem compartilhar (Básico/Avançado para Anti-DDoS e NOC podem ser duas picklists ou
  uma só, `PL_TIER_BASICO_AVANCADO`).
- Compilação: o EPC grava os atributos do produto em JSON (`vlocity_cmt__AttributeMetadata__c` e
  `vlocity_cmt__JSONAttribute__c`) pelo job **Attribute Metadata / Product Attribute Maintenance**. Carregou atributo,
  roda o job, senão o configurador não mostra.
- Runtime: atributo "configurável na venda" vira campo no carrinho; "oculto" vai junto no pedido sem aparecer (bom para
  parâmetros técnicos do OM).
- Armadilha: atributo com o mesmo código em categorias diferentes não é o mesmo atributo. Código único por org.

## 4. Catálogos e vitrine

- `Catalog__c` (código, ativo, raiz, catálogo pai, lista de preço padrão) e `CatalogProductRelationship__c` (produto no
  catálogo, sequência, vigência). Catálogo é vitrine: o que o canal vê. O mesmo produto pode estar em vários.
- Digital Commerce (APIs de catálogo para portal/app) lê catálogos por cache: job de **cache** depois da carga.
- Template: aba Catálogos. Ferramenta: Catálogo e Portfólio (portfólio = catálogo raiz).

## 5. Preço

- **Price List** (`PriceList__c`): lista comercial (PL_B2B). Pode ter lista pai; a filha herda e sobrescreve o que
  precisar. É assim que o template modela **zona** (o EPC não tem objeto Zona): PL_B2B_ZONA_B filha de PL_B2B com a
  porta a 55,00. Cada Price List liga a um `Pricebook2` padrão (sincronizado por job).
- **Pricing Variable** (`PricingVariable__c`): o "tipo de valor": cobrança única ou recorrente, frequência (mensal),
  aplica a preço unitário, custo, desconto. Ex.: `REC_MNTH_STD_PRC` (recorrente mensal), `OT_STD_PRC` (adesão).
- **Pricing Element** (`PricingElement__c`): um valor de uma variável em uma lista (R$ 199,90 mensal em PL_B2B).
- **Price List Entry** (`PriceListEntry__c`): liga produto + elemento + lista, com vigência e flag de preço base.
  Template: aba Preços (uma linha = uma entry).
- **Preço por atributo** (Attribute-Based Pricing): matriz (`CalculationMatrix__c` + versões + linhas) consultada por um
  **Pricing Plan** no carrinho: banda 1G = X, 10G = Y. Template: aba Preço por Atributo. É o caminho para banda,
  Anti-DDoS e NOC; não é "regra de precificação nova".
- **Pricing Plan**: sequência de passos que o carrinho executa para chegar ao preço (base, matriz, ajustes, promoção).
  Só se cria um novo quando a lógica muda, não por produto.
- **Time Plan / Time Policy** (`TimePlan__c`, `TimePolicy__c`): duração e gatilho de um ajuste temporário ("100% de
  desconto por 3 meses a partir da ativação"). Template: aba Planos e Políticas de Tempo.
- Depois da carga: job de **refresh do Pricebook / recompilação de preço**, e limpar cache.
- Armadilha: preço sem Price List Entry ativa dentro da vigência = produto sem preço no carrinho, sem erro.

## 6. Promoções e ajustes

- `Promotion__c` (código, vigência, período de compromisso) + `PromotionItem__c` (a que oferta/produto aplica; tipo de
  ajuste: override de preço, desconto percentual ou absoluto, item grátis; time plan e policy). A promoção pode
  adicionar produtos ao carrinho (bundle promocional) ou só ajustar preço.
- Elegibilidade e limite de reuso viram **regras de contexto**, não campos da promoção. Contrapartida (fidelidade) vai
  para o contrato.
- Template: aba Promoções e Ajustes. Ferramenta: menu Promoções.

## 7. Elegibilidade, disponibilidade e contexto

- **Context Dimensions** (`ContextDimension__c`): eixos que o carrinho conhece (segmento, canal, região, tipo de conta).
  **Context Mapping** diz de onde vem o valor (campo da conta, do endereço). **Rule Set / Context Rules**: condições
  sobre as dimensões que qualificam (mostra) ou desqualificam (esconde) produtos, promoções e preços.
- Disponibilidade por região: ou lista de preço por zona (§5) ou regra de contexto por dimensão Região. Zona de preço
  e zona de disponibilidade são coisas diferentes; o template separa (Listas de Preço x Elegibilidade).
- **Advanced Rules** (`Rule__c`): regras dentro do carrinho (se escolher X, exige Y; incompatibilidades; auto-adicionar).
  Não são elegibilidade; são configuração.
- Template: aba Elegibilidade, "configuração assistida" (a planilha é a especificação; a configuração é feita no
  Product Designer ou por DataPack de regra).
- Ferramenta: Mercado, Canal, Zona, Regra, Disponibilidade, Dimensões de contexto.

## 8. Decomposição técnica e Order Management

- Camada técnica: Product2 tipo Service (CFS voltado ao cliente, RFS voltado ao recurso) e Resource. A ligação comercial
  -> técnico é a **Decomposition Relationship** (`DecompositionRelationship__c`: produto origem, produto destino,
  condição, mapeamento de atributos origem -> destino).
- O OM lê a decomposição e executa o **Orchestration Plan** (`OrchestrationPlanDefinition__c` + itens: chamadas a
  sistemas, tarefas manuais, dependências). Fora do escopo do template (Princípio "o que está aqui torna vendável; o que
  está lá entrega").
- Fato da org (15/09): a cortesia de OM venceu em 16/06/2026 e a decomposição parou; a licença nova ainda não apareceu em
  produção. Decomposição fica "configuração assistida" até isso resolver.
- Ferramenta: CFS, RFS, Recurso, Decomposição técnica.

## 9. Carrinho e CPQ

- Carrinho = Opportunity, Quote ou Order com line items do pacote. APIs `getCartsItems`, `postCartsItems`,
  `putCartsItems`, `getCartsProducts` (o que é elegível), `checkout`. O teste de Pós-carga usa essas APIs.
- Configuração no carrinho: atributos configuráveis, filhos com cardinalidade, Advanced Rules, Pricing Plan.
- Enhanced LWC cart: a página do CPQ montada com Flexcards e OmniScripts (ver doc de 15/09, seção "Enhanced LWC").
- Asset-based ordering (MACD): mover, adicionar, mudar, desconectar partem do Asset criado pelo pedido; exige
  `IsNotAssetizable = false` no produto e OM funcionando. Ferramenta: Assets e MACD.
- Quote -> Order -> Contract (CLM dentro do mesmo pacote): o produto precisa estar no Pricebook do CPQ (job) para entrar
  na proposta.

## 10. Carga, migração e jobs (o que o Claude via CLI faz)

- **Produto Designer** é a UI oficial; **DataPacks** (JSON) são o formato de migração; **IDX Workbench** (GUI) e
  **Vlocity Build / IDX CLI** (`vlocity packExport` / `packDeploy`) são as ferramentas. O DataPack de Product2 leva
  filhos, atributos, price list entries e catálogo junto; Promotion e CalculationMatrix têm DataPack próprio.
- **EPC REST APIs** (Admin Configure v2): CRUD de produto, filhos, picklist e promoção por API. Alternativa ao DataPack
  para a carga inicial na org de desenvolvimento.
- Ordem de carga do template: Atributos -> Picklists -> Produtos -> Atribuições -> Estrutura -> Decomposição ->
  Catálogos -> Listas -> Preços -> Preço por atributo -> Planos de tempo -> Promoções -> Elegibilidade.
- **Jobs pós-carga** (CMT Administration): Product Hierarchy Maintenance, Product Attribute Metadata, Pricebook refresh /
  Price List sync, Clear Cache (Platform Cache e Digital Commerce), Refresh Pricing (se pricing plan mudou). Depois:
  carrinho por API. Registro sem carrinho abrindo não conta como carga (Princípio 3).
- Princípio 2: carga uma vez na org de desenvolvimento; QA, homologação e produção recebem DataPack versionado. Nunca
  recarregar planilha em produção.
- Limite prático: 1 assento de licença do pacote em produção (Caio) e 5 admins com PSL de catálogo. Quem carrega
  precisa estar nessa lista.

## 11. Respostas curtas para perguntas prováveis

| Pergunta | Resposta |
|---|---|
| "Preciso criar um tipo novo de produto?" | Não. Tipo é Object Type; produto novo é Product2 com o Object Type certo. |
| "Onde ponho o segmento B2B/B2C?" | Não é tipo. É elegibilidade (regra de contexto) + lista de preço. |
| "Como faço o cliente escolher um entre três?" | Virtual item (grupo) com min 1 max 1 e os três como filhos do grupo. |
| "Banda muda o preço, é regra?" | Não. Atributo com picklist + matriz de preço por atributo. |
| "Preço diferente por região?" | Lista de preço filha por zona; disponibilidade por regra de contexto. |
| "Desconto de 3 meses?" | Promoção com item de ajuste + time plan 3 meses + time policy no gatilho de ativação. |
| "Quando a oferta pode ser publicada?" | Quando todos os filhos, atributos, picklists e preços referenciados estão publicados. |
| "Como o Salesforce sabe que é o mesmo produto em outro ambiente?" | GlobalKey. A ferramenta gera, a org nunca. |
| "Posso mudar o código depois?" | Não. Código é chave de todas as abas e do ProductCode. Mude o nome. |
| "Quem carrega em produção?" | Ninguém. DataPack versionado sobe por pipeline; produção não recebe planilha. |
| "E a parte técnica (CFS/RFS)?" | Decomposition Relationship + orquestração do OM; depende da licença de OM (pendente). |
| "Quantos níveis de filhos?" | Dois na árvore comercial. Mais que isso, revisar a modelagem. |
