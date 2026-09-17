# 17/09/2026 - Catalog Control Plane x Template de carga EPC v1.1: mapeamento e especificação de export

O presidente pediu ajuda para configurar o Control Plane (ccp.evo.digital). O que ele precisa de nós é que a **Exportação**
da ferramenta gere o template de carga que já existe: `docs/catalogo/Template_Catalogo_EPC_BTP_v1_1.xlsx` (versão 1 de
11/09; 18 abas, 14 de dados). O Claude via CLI lê esse template, consulta a org, carrega na sandbox na ordem de carga e
roda o Pós-carga. Ver docs/2026-09-17-catalog-control-plane.md.

## O que o Portfolio Explorer mostra (print de 17/09)

Árvore com código canônico, tipo e status por nó. Exemplo: oferta `INT_HOME_STANDARD` (Internet Home Standard,
Publicado) -> produto `CH_ACCESS_PORT_HOME` (Aprovado) -> atributos `ACCESS_TECHNOLOGY` e `PORT_PROFILE` (Aprovado);
produtos `CH_ROUTER_RENTAL`, `CH_SVA_PACKAGE`, `CH_DIGITAL_SERVICES_PACKAGE` em Rascunho. Segunda oferta
`SMART_INTERNET_CORPORATE` com portas primária e secundária. Filtros: 17 tipos e 3 status (Publicado, Aprovado, Rascunho).

Ponto de atenção já visível: a oferta está **Publicada** com filhos em **Rascunho**. A ferramenta precisa travar isso
(oferta só publica quando toda a árvore está aprovada), senão o export sai incompleto.

## Mapeamento: tipo do Control Plane -> aba do template

| Tipo no Control Plane | Aba do template | Colunas que ele precisa preencher | Objeto EPC (Mapa de Campos) |
|---|---|---|---|
| Oferta | Produtos (Camada = Oferta, Subtipo = Bundle) + Estrutura Comercial (uma linha por filho) | Código, Nome, Família, Vitrine, Segmentos, GlobalKey, Vigência; pai/filho, grupo de escolha, qtd mín/padrão/máx | Product2, ProductChildItem |
| Produto | Produtos (Camada = Produto comercial) | + Vendável isolado, Configurável, Gera ativo, Depende de local, Código material SAP, Descrição fiscal, Documento fiscal | Product2 |
| Especificação | Produtos.Tipo de especificação / Subtipo | Offer, Product, Service; Bundle ou Simple | SpecificationType, SpecificationSubType |
| Classe de produto | Produtos.Família (Object Type nível 2) | Conectividade, Voz, TV, Wi-Fi e Dispositivos, SVA | ObjectTypeId |
| Atributo | Atributos + Atribuição de Atributos (a partir da posição na árvore) | Código, Nome, Categoria, Tipo de valor, Picklist; por produto: obrigatório, padrão, configurável, oculto, sequência | AttributeCategory, Attribute, AttributeAssignment |
| Picklist | Atributos.Picklist (código) | | Picklist |
| Valor de picklist | Valores de Picklist | Picklist, Valor, Rótulo, Sequência, Ativo | PicklistValue |
| Catálogo, Portfólio | Catálogos | Código, pai, raiz, lista de preço padrão, produtos e sequência | Catalog, CatalogRelationship, CatalogProductRelationship |
| Lista de preço | Listas de Preço | Código, pai, moeda, zona | PriceList |
| Zona | Listas de Preço.Zona de preço (lista filha) + Elegibilidade.Dimensão | | PriceList filha (CAT-ZON-01) |
| Mercado, Canal | Elegibilidade (Dimensão = mercado ou canal) e Produtos.Segmentos elegíveis | Aplica-se a, Tipo de regra, Dimensão, Operador, Valor, Efeito | Context Rules |
| Regra | Elegibilidade | idem | Context Rules |
| CFS, RFS, Recurso | Decomposição Técnica | Produto comercial, CFS, RFS, Recurso, regra de mapeamento | ProductRelationship, regras do OM |
| Menu Pricing Studio / Prévia de preço | Preços e Preço por Atributo | Produto, lista, variável, tipo de cobrança, recorrência, valor, moeda, **Situação do valor** | PricingElement, PriceListEntry, matriz por atributo |
| Menu Promoções | Promoções e Ajustes | Tipo, código, aplica-se a, método, valor, plano/política de tempo, vigência, dono | Promotion, PromotionItem |
| Menu Materiais SAP | Produtos (colunas P, Q, R) | Código material SAP, Descrição fiscal, Documento fiscal (NFS-e, Fatura, NFCom) | campos a criar em Product2 |
| Menu Últimas alterações / ciclo de vida | Controle de Mudanças | Nº, data, solicitante, tipo, abas afetadas, aprovadores, pacote | governança |
| Menu Implantação / Reconciliação e UAT | Pós-carga | checklist de jobs e teste de carrinho | CMT Administration, API de carrinho |

Sem correspondente na ferramenta (hoje): **Decisão de Modelagem** (componente do Core -> o que vira no EPC), **Planos e
Políticas de Tempo** e **Preço por Atributo**. Ou a ferramenta ganha essas telas, ou essas abas seguem manuais.

## Regras que o export precisa respeitar (é isso que "configurar a ferramenta" significa para nós)

1. **Cabeçalhos idênticos** aos do template v1.1, aba por aba. O cabeçalho é o contrato do validador.
2. **Ação** derivada do status e do diff com o último export: Publicado e novo -> Criar; Publicado e alterado -> Atualizar;
   Publicado e removido -> Descontinuar; Aprovado ou Rascunho -> Ignorar (sai na planilha, não carrega).
3. **Código** = código canônico da ferramenta (`CH_ACCESS_PORT_HOME`), único por tipo, imutável depois de publicado. Vira
   Product2.ProductCode e chave de todas as abas.
4. **GlobalKey** determinística, gerada pela ferramenta e nunca pela org: padrão do template `BTP-<tipo>-<número do Core>`.
   Se a ferramenta não tiver o número do Core, propor `BTP-<tipo>-<código canônico>`. É a identidade entre ambientes.
5. **Ordem de carga** preservada: Atributos -> Valores de Picklist -> Produtos -> Atribuição -> Estrutura Comercial ->
   Decomposição Técnica -> Catálogos -> Listas de Preço -> Preços -> Preço por Atributo -> Planos de Tempo -> Promoções ->
   Elegibilidade -> Pós-carga. O export pode sair em qualquer ordem; o Claude carrega nessa.
6. **Situação do valor** em todo preço: Ilustrativo ou Validado Core. Ilustrativo não sobe para QA.
7. **Integridade antes de exportar**: todo filho referenciado existe e está Publicado; todo atributo tem categoria; picklist
   referenciada tem valores; lista de preço referenciada existe. A ferramenta trava o export com pendência.
8. **Versão e data** do export na aba Controle de Mudanças (uma linha por export) e no nome do arquivo.
9. Além do xlsx, um **JSON com o mesmo conteúdo** (uma chave por aba) facilita o validador. O xlsx continua sendo o que
   Produtos e Comercial leem.

## O que o Claude faz com o export (já é o método de leads e gerente de conta)

Consulta primeiro (Product2 por ProductCode e GlobalKey, Attribute, Picklist, PriceList, Promotion por código), classifica
cada linha em cria / atualiza / sem mudança / erro, mostra a lista, espera o "vai", carrega na sandbox na ordem acima,
roda os jobs de Pós-carga e o teste de carrinho por API, exporta o DataPack e registra no git. Produção só por DataPack.

## Próximos passos

1. Presidente: acesso à ferramenta para o Diego e export de exemplo da oferta `INT_HOME_STANDARD` (mesmo incompleta).
2. Diego + dev da ferramenta: uma hora para fechar as 9 regras acima e os 3 tipos sem correspondente.
3. Claude: validador `tools/catalogo/validar_template_epc.py` a partir do primeiro export real (não antes).
4. Davi/Gerson: registrar que W-000102 (CAT-TPL-01) passa a ser "export do Control Plane no formato v1.1" e que a
   modelagem canônica vive na ferramenta.
