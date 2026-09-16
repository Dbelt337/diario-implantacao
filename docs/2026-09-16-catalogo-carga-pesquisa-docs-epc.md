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
