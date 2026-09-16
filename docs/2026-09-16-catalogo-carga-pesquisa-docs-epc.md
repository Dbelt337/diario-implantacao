# 16/09/2026 - Catalogo EPC: e possivel carregar sem wizard custom? (pesquisa na documentacao)

Pergunta do Diego: antes de propor o modelo hibrido, confirmar na documentacao do CPQ/EPC se a carga inicial
e a manutencao do catalogo podem ser feitas pela interface padrao (sem wizard custom sobre o template),
quanto tempo levaria em media, e montar uma proposta nova. Motivo: o wizard e desenvolvimento custom, pode
ter erros; a interface ja cobre as dependencias de criacao e relacionamento dos registros.

## Limitacao do ambiente
help.salesforce.com, trailhead.salesforce.com, developer.salesforce.com, salesforce.com, github.com e apexhours.com
estao bloqueados pelo proxy de saida desta sessao. As evidencias abaixo vieram dos resumos de busca (snippets);
os links foram passados ao Diego para colar o conteudo integral no chat e fechar a validacao.

## O que a documentacao confirma (snippets)
1. Product Designer e o app Lightning oficial para configurar e manter o EPC; e o foco das novas
   funcionalidades e substitui o Product Console (Angular). Sequencia de criacao de oferta: produto -> aba
   Estrutura (filhos e tipo de relacionamento) -> atributos -> aba Preços (New Price; promocoes e custos) ->
   regras de atributo/contexto. Fonte: Trailhead "Explore Offer Creation in Product Designer",
   "Creating Effective Product Bundles in EPC", Apex Hours EPC.
2. Migracao entre orgs: DataPacks (Product2, Promotion, CalculationMatrix), Industry DX (IDX) Workbench (GUI)
   e Vlocity Build / IDX CLI (linha de comando, CI). O DataPack de Product2 inclui Pricebook e Price List
   Entries do produto. Chaves globais geradas pelo job "Generate Global Keys" (Vlocity CMT Administration).
   Citacao: "In Salesforce Industries, Products cannot be passed from one org to another with csv files."
   Fonte: vlocity_build README, howtosfdc.cloud, sfdc247.
3. EPC REST APIs oficiais: "Admin Configure for Product, Picklist and Promotion Web APIs v2" (Swagger) -
   criar objetos de produto, filhos (child items), versoes, promocoes. Fonte: developer.salesforce.com CME guide.
4. Jobs pos-carga: Product Hierarchy Maintenance -> Clear Managed Platform Cache -> Refresh Platform Cache
   (Full), nesta ordem, sempre que a estrutura/cardinalidade mudar; executaveis remotamente por API.
   Fonte: Trailhead "Optimize Industries Cloud Cache Management"; developer docs "Running Maintenance and
   Digital Commerce Cache Jobs Remotely"; Help "Running EPC Jobs for a New Installation".
5. Agentforce for Communications (GA FY27 Q1 / 2026): cinco agentes pre-construidos - billing resolution,
   SLO insights, quoting, site grouping, guided selling. Nenhum topico/acao pre-construida para criar ou
   manter catalogo. Acoes custom podem ser criadas a partir de Apex, Flow ou prompt template.
   Fonte: salesforce.com/news (anuncio), Trailhead Agentforce for Industries.
6. Cuidado: "Data Import Through CSV Files in Product Catalog" com templates DPE (Data Processing Engine)
   e do Revenue Cloud / Product Catalog Management, nao do EPC do Communications Cloud. "CSV Data Management
   for Industries" (Spring '24) e um importador generico de objetos (insert/update/upsert), nao entende a
   semantica do EPC (atributos JSON, hierarquia, cache).
7. Precedente comunitario de "template + carregador": vlocity-epc-on-steroids (Google Sheets -> EPC),
   projeto pessoal no GitHub, sem suporte. Mostra que e viavel e tambem que e codigo custom a manter.

## Conclusao
- E possivel fazer a carga inicial e a manutencao sem desenvolvimento custom: Product Designer em sandbox,
  teste no carrinho, migracao por DataPack/IDX, jobs pos-carga na ordem.
- O wizard sobre o template reimplementa validacoes que a interface ja faz, fica fora do suporte e precisa
  de manutencao a cada release. Proposta: suspender; o template vira planilha de levantamento e roteiro.
- Agentforce: possivel como assistente (explicar manual, checklist, conferir levantamento e pos-carga),
  nao como autor do catalogo; escrever no catalogo exigiria acoes custom sobre as EPC REST APIs + licenca.

## Estimativa de tempo (pratica; a documentacao nao publica tempos; calibrar na Onda 1)
- Produto simples: 20 a 40 min. Pacote/combo 3 a 6 componentes: 2 a 4 h. Promocao: 1 a 2 h.
- Teste no carrinho por familia: meio dia. Migracao por DataPack + jobs por onda: meio dia.
- Onda 1 (11 ofertas de conectividade + 16 componentes): 5 a 8 dias uteis com 1 analista; 2 semanas com homologacao.
- Catalogo completo: soma das unidades do inventario + 1 dia por familia. Hipotese 60 ofertas em 5 familias:
  4 a 6 semanas com 1 analista, 2 a 3 semanas com 2.

## Entregue
- docs/deck-catalogo/Catalogo_Carga_e_Manutencao_v2_Rota_Padrao.pptx (13 slides), gerado por
  scripts/gerar_deck_catalogo_v2.py a partir do pacote do deck original (docs/deck-catalogo/Template_vs_Catalogo_Manual_original.pptx).
- Renderizacao visual nao pode ser conferida neste ambiente (sem LibreOffice funcional); revisar no PowerPoint.

## Links para o Diego colar o conteudo (bloqueados aqui)
- https://help.salesforce.com/s/articleView?id=ind.comms_enterprise_product_catalog__epc_.htm
- https://help.salesforce.com/s/articleView?id=ind.comms_t_running_vlocity_epc_jobs_for_a_new_installation_100824.htm
- https://help.salesforce.com/s/articleView?id=release-notes.rn_csv_data_import.htm&release=248
- https://trailhead.salesforce.com/content/learn/modules/product-designer-basics/explore-offer-creation-in-product-designer
- https://trailhead.salesforce.com/content/learn/modules/shared-catalog-management/manage-the-industries-cloud-cache
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-enterprise-product-catalogepcrest-apis.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-running-maintenance-and-digital-commerce-cache-jobs-remotely.html
- https://www.salesforce.com/news/stories/agentforce-for-communications-announcement/
- https://github.com/vlocityinc/vlocity_build/blob/master/README.md

## Validacao com o conteudo integral colado pelo Diego (16/09, tarde)
- Help "Enterprise Product Catalog (EPC)": "Allows you to import products from other systems. For example, if you
  want to move from a development to a production environment, you can use Vlocity DataPacks"; "EPC uses the
  IDX Workbench build tool"; Product Designer e "the administration application for the product catalog";
  Pricing Designer cuida de precos, promocoes e regras de preco. Confirma a rota padrao.
- Help "Running EPC Jobs for a New Installation": jobs de instalacao (Install Default Objects and Layouts,
  Create Default Pricing Variables and Bindings, Install Default Pricing Plan Data), na aba Vlocity CMT
  Administration, em sequencia. Nao sao os jobs pos-carga (esses estao em "Administration Jobs Reference for CME").
- Developer Docs "EPC REST APIs": CRUD de Product2, Product Version, Product Child, Picklist, Picklist Version,
  PicklistItem, Promotion, PromotionItem. Nao ha API de price list entry nem de atribuicao de atributos:
  um wizard teria de gravar preco e atributo direto na base, sem a validacao da interface. Argumento extra
  contra o conversor custom.
- Anuncio Salesforce 26/02/2026 "Agentforce for Communications": Billing Resolution, SLO Insights, Quoting,
  Site Grouping, Guided Selling. Todos consomem o catalogo; nenhum cria ou mantem catalogo. O Quoting Agent
  monta cotacoes seguindo regras de negocio, o que depende de um catalogo bem cadastrado.
- Deck ajustado nos slides 3, 4 e 6 com esses pontos.
- Help "Administration Tasks Reference for CME" (indice): "In most cases, do not run administration jobs on live
  production environments. Running the jobs may disrupt order processing and the customer experience." Os jobs
  pos-carga estao na pagina "Running Maintenance Jobs for the CME Managed Package" (a colar). O indice tambem
  lista "Agentforce for Cart Operations in CME Managed Package" e "Flows and Invocable Actions in CME": as acoes
  padrao de Agentforce no pacote sao para o carrinho (venda), nao para autoria de catalogo. Deck ajustado
  (slides 3, 10 e 11: jobs em janela de manutencao, nunca em producao ao vivo).
- Help "Create Products in the Product Designer": "administration application for the product catalog", para
  usuarios de negocio e de TI. "Plan Your Product Catalog": antes da oferta, criar tipos de objeto, atributos e
  especificacoes; depois pacotes e preco. "Track Product Catalog Changes with Projects": projetos do EPC
  registram todas as mudancas (historico para gestao de mudanca). "Product Versioning" e "Product Lifecycles"
  (current, future, past, retired) nativos. Restricao: sem virgulas em valores de picklist. Recomendacao: view
  All Products como padrao. Deck ajustado (slides 3, 10 e 11): sequencia oficial, projetos do EPC como evidencia,
  descontinuacao = aposentar pelo ciclo de vida.
- Help "Running Maintenance Jobs for the CME Managed Package" (Vlocity CMT Administration > Admin Console >
  Maintenance Jobs): Product Hierarchy Maintenance constroi a hierarquia no Data Store; Refresh Platform Cache
  (Full) copia a hierarquia para o cache e reconstroi o cache de atributos; Refresh Platform Cache (Incremental)
  atualiza sem apagar, e exige Product Hierarchy Maintenance antes; Clear Managed Platform Cache limpa a particao
  CPQPartition; Product Category Data Maintenance regenera o Category Data JSON de todos os Product2.
  Regra para o manual: carga = Hierarchy + Clear + Refresh Full; manutencao = Hierarchy + Refresh Incremental
  (+ Category Data se mudar catalogo/categoria). Sempre em janela.
- Help "Agentforce for Cart Operations in CME Managed Package": acoes invocaveis e flows prontos para criar
  cotacao/pedido, navegar produtos, adicionar ao carrinho, configurar campos e atributos, aplicar ajustes e
  promocoes, submeter pedido, trocar plano; "eliminates the need for custom Apex"; exige licenca Agentforce
  Employee Agent. Escopo: venda (carrinho). Nada de autoria de catalogo.
- Help "Track Product Catalog Changes with Projects": projeto = work set; um projeto padrao recebe toda
  criacao/alteracao/exclusao; lista de itens com acao Add/Change/Delete e versao; IDX Workbench migra as
  mudancas de um projeto em status Released para outra org. Regra: um projeto por onda/evento, Released ao
  homologar, migrado pelo IDX. Deck ajustado (slides 3, 6, 9, 10, 11 e 12). Validacao concluida.
- Help "EPC Project Management": status Draft > In-Review > In-Test > Released (ou Canceled); ao mudar o status
  do projeto, produtos, tipos de objeto e picklists versionados vao para o mesmo estado; em Released nao se move
  nem remove item; so o dono do projeto move itens ou muda o padrao; mover so pacotes inteiros a partir do
  produto raiz. Regra para o manual: Draft = analista cadastra; In-Review = governanca revisa; In-Test =
  comercial homologa no carrinho; Released = governanca publica pelo IDX. Deck ajustado (slides 10, 11 e 12).

## Correcao 16/09 (tarde): PowerPoint pedia reparo ao abrir o deck
Causa: tamanhos de fonte fracionados (10,5 e 11,5 pt) gerados como sz="1050.0" (o XSD exige inteiro); o reparo do
Office descartava esses textos (slide 10 ficou so com titulos). Corrigido no gerador (int(round(sz*100)), idem
spcPts; titulo vazio nao gera run). Validacao passou a ser feita com xmllint contra o XSD oficial pml.xsd
(scripts/validar_pptx_xsd.sh): 13 slides + presentation.xml validam; teste negativo com sz="1050.0" falha como
esperado; content types, rels e zip conferidos. Deck regerado e reenviado.

## Correcao de rota (16/09, 11:30-11:45): a v2 errou o alvo

Davi (WhatsApp, 11:32-11:41): "nao e isso nao". O agente da proposta dele nao e Agentforce nem wizard em Apex/Flow:
"a ideia e que o agente execute a leitura do template e execute via cli"; "na vdd e um agente custom mesmo";
"o claude conectado agora com a salesforce ele vai fazer isso"; "claude e o executor, ele nao vai desenvolver nada,
ele vai auxiliar na execucao das coisas que vierem no template". Pediu tambem menos informacao no deck, para nao
confundir na apresentacao.

Onde a v2 errou: leu "agente" como Agentforce (slides 1, 2, 6, 7, 12, 13); recomendou suspender o wizard e cair no
cadastro manual pelo Product Designer (slides 4 e 5), derrubando as duas alternativas sem apresentar a do Davi;
13 slides de pesquisa de documentacao.

O que continua valido e sustenta a proposta do Davi: DataPacks/IDX sao a rota suportada de migracao (o Claude gera os
DataPacks a partir do template e publica com o Vlocity Build, sem gravar registro direto); jobs pos-carga disparaveis
por API; padrao do projeto "validar antes, executar, conferir depois, registrar". Restricao que permanece: as EPC REST
APIs nao cobrem preco nem atributo (resolvida via DataPack, nao e argumento contra). Nota para o Diego: a frase
"teria que criar classes e fluxos" nao vale nesse modelo; via CLI nao ha Apex nem Flow. Pre-requisitos reais: acesso
autenticado a sandbox (usuario de integracao), Vlocity Build e sf CLI instalados, template com os codigos exatos da org.

Entregue: docs/deck-catalogo/Catalogo_Carga_e_Manutencao_v3_Template_Claude_CLI.pptx (6 slides), gerado por
scripts/gerar_deck_catalogo_v3.py sobre o pacote do deck original. Slides: capa; como funciona (5 passos: negocio
preenche o template, Claude le e confere, Claude executa na sandbox via CLI, comercial homologa no carrinho, pessoas
publicam por DataPack/IDX); por que este caminho (wizard x manual x template + Claude); seguranca (4 garantias);
prazo e pre-requisitos (Onda 1 em 1 a 2 semanas; P1/P2 travam); decisoes e proximos passos. Validado contra pml.xsd
com xmllint (OK). LibreOffice continua sem carregar arquivos neste ambiente; revisar a renderizacao no PowerPoint.
Ponto em aberto com o Davi: o Claude gera DataPacks (rota suportada) ou chama as EPC REST APIs direto; o slide 2 assume
DataPacks/Vlocity Build.
