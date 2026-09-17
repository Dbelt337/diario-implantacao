# 17/09/2026 - Pesquisa: como o Control Plane pode alimentar o EPC (três caminhos, do mais direto ao mais seguro)

Pedido do Diego durante a reunião com o presidente: "algo bem legal" para o sistema dele gerar o que o Salesforce precisa.
Busca na web feita pela sessão remota (as páginas não abrem aqui; só os resumos de busca. Diego confirma os detalhes
abrindo os links). Fatos da org: Vlocity CMT 900.650.3 = Communications Cloud; 1.950 PSL Comms Cloud Plus; 5 admins
com PSL de Product Catalog; 1 assento de licença do pacote.

## 1. TMF620 inbound: o Salesforce já fala a língua da ferramenta dele

Communications Cloud expõe a **API TMF620 Product Catalog Management (inbound)**: GET, POST, PATCH e DELETE de
Product Specification e Product Offering direto no EPC. O `productNumber` do payload vira `ProductCode`; o
`lifecycleStatus` do TMF vira `IsActive` + `Status` do EPC (spec sempre nasce Draft/ativa). Há página específica de
"Retrieve Child Items Using TMF620 API" (a estrutura do bundle vem junto). Desde Spring '26 dá para chamar por
**Direct Access** (Connect/Apex REST) sem MuleSoft. Pré-requisitos: PSL Shared Product Catalog e Industries CPQ na org,
licença do pacote no usuário da API.

Por que é "bem legal": o Control Plane já modela em TM Forum (Oferta, Especificação, CFS, RFS, Recurso). Em vez de
exportar planilha, o sistema dele **POSTa TMF620 na org de desenvolvimento**, e a spec/oferta/filhos/características
nascem no EPC sem template no meio. O template v1.1 continua para o que o TMF620 não cobre (ver §4).

O que confirmar antes de prometer: (a) a org tem o endpoint habilitado (Diego abre TMF620.html e pega a URL de Direct
Access; sessão local testa um GET); (b) quais campos do Product2 o mapeamento cobre (página Product Offering Mappings
e Product Specification Mappings); (c) preço, promoção, catálogo e picklist entram ou não no inbound.

## 2. Skills oficiais da Salesforce para Claude Code (catálogo como código)

Repositório **forcedotcom/sf-skills** (oficial, 60+ skills; blog de junho/2026 "Build Production-Ready Apps in Claude
Code with Salesforce Skills"). Duas interessam:
- **omnistudio-epc-catalog-generate**: "expert CME EPC modeler" que gera DataPack JSON de Product2, atributos por
  categoria, Product Child Item, com templates canônicos em `assets/`, exemplo `business-internet-plus-bundle` e um
  **rubric de 120 pontos** para auditar bundles existentes (riscos, lacunas, correções). Mantém GlobalKey, source keys
  e namespace consistentes para deploy.
- **sf-vlocity-build-deploy** (origem jaganpro/sf-skills, migrado para forcedotcom/afv-library): guia o Vlocity Build
  (validateLocalData -> packGetDiffs -> packDeploy -> packRetry), manifestos, integridade de matching key e GlobalKey.

Instalação: `npx skills forcedotcom/sf-skills` dentro do projeto SFDX (`org/`). Uso: a sessão local do Claude passa a
gerar e auditar DataPacks a partir do export do Control Plane com o padrão da própria Salesforce; o presidente pode
copiar os templates de `assets/` para o gerador dele (é o formato final que o deploy espera).

## 3. Precedente: vlocity-epc-on-steroids (planilha inteligente -> EPC)

Projeto aberto de Sasha Morozov: Google Sheets com template de desenho de catálogo (produtos, atributos, picklists,
filhos, preços) e botão que converte e empurra para a org. Mesma ideia do Control Plane, só que em planilha. Serve para
comparar a estrutura de abas com o template v1.1 e para ver como ele resolve chaves e ordem de carga. Verificar
manutenção (último release) antes de usar em produção.

## 4. Arquitetura proposta (para levar ao presidente)

```
Control Plane (design-time, aprovação, versão)
   |-- (a) TMF620 JSON  --POST-->  EPC da org de desenvolvimento: spec, oferta, filhos, características
   |-- (b) DataPack JSON (templates do sf-skills) para o que o TMF620 não cobre: listas de preço, preços,
   |        preço por atributo, promoções, catálogos, regras de contexto
   `-- (c) xlsx no template v1.1: leitura humana (Produtos, Comercial), Decisão de Modelagem e Controle de Mudanças
Claude Code local (com sf-skills): audita (rubric), roda Vlocity Build packDeploy na sandbox, jobs pós-carga,
   teste de carrinho por API, exporta DataPack versionado para o git
Pipeline: DataPack do git -> QA -> produção (nunca planilha, nunca TMF620 direto em produção)
```

Ganhos: sem recodificar TM Forum em planilha; formato de deploy oficial; auditoria automática; histórico no git.
Custos: confirmar os pré-requisitos do TMF620 (licença/PSL do usuário da API) e a cobertura do inbound; instalar as
skills no projeto local.

## 5. Próximos passos

1. Diego: abrir e colar aqui o conteúdo de TMF620.html (inbound), product_offering.html e product_specification.html.
2. Sessão local: `npx skills forcedotcom/sf-skills` em `org/`; listar as skills instaladas; ler o SKILL.md de
   omnistudio-epc-catalog-generate e copiar os templates de `assets/` para `docs/catalogo/datapack-templates/`.
3. Sessão local: inventário EPC (tools/catalogo/consultas) e teste de GET no endpoint TMF620 de Direct Access.
4. Presidente/dev: protótipo de export TMF620 da oferta INT_HOME_STANDARD; Claude valida contra o rubric e carrega.

## Fontes

- TMF620 inbound: https://developer.salesforce.com/docs/industries/communications/guide/TMF620.html
- Child items via TMF620: https://developer.salesforce.com/docs/industries/communications/guide/retrieve_child_items_using_TMF620_API.html
- Mapeamentos: https://developer.salesforce.com/docs/industries/communications/guide/product_offering.html e
  https://developer.salesforce.com/docs/industries/communications/guide/product_specification.html
- Casos de uso: https://developer.salesforce.com/docs/industries/communications/guide/TMF620use-cases.html
- Referência TMF620 (Salesforce): https://developer.salesforce.com/docs/industries/communications/references/tmf620
- TMF620 outbound (publicar oferta para outros sistemas): https://developer.salesforce.com/docs/industries/communications/guide/TMF620_outbound.html
- sf-skills oficial: https://github.com/forcedotcom/sf-skills ; skill EPC: https://www.skills.sh/forcedotcom/sf-skills/omnistudio-epc-catalog-generate
- Blog Salesforce Developers (jun/2026): https://developer.salesforce.com/blogs/2026/06/build-production-ready-apps-in-claude-code-with-salesforce-skills
- Skill Vlocity Build: https://www.remoteopenclaw.com/skills/jaganpro/sf-skills/sf-vlocity-build-deploy
- Vlocity Build: https://github.com/vlocityinc/vlocity_build
- EPC REST APIs (Admin Configure v2, Swagger): https://developer.salesforce.com/docs/industries/cme/guide/comms-t-epc-api-swagger-reference.html
- vlocity-epc-on-steroids: https://github.com/sashavmorozov/vlocity-epc-on-steroids

## 6. Validação com o conteúdo integral colado pelo Diego (17/09, tarde)

### TMF620 inbound: confirmado, com limites que importam

Confirmado na doc oficial:
- Recursos: **Catalog, Category, Product Offering, Product Offering Price, Product Specification**; GET, POST, PATCH, DELETE.
- Direct Access (Apex REST, sem MuleSoft): `/services/apexrest/vlocity_cmt/tmforum/productopenapi/v1/{catalog | category |
  productOffering | productOfferingPrice | productSpecification}`. A partir do Winter '27 só existe esse caminho.
- Pré-requisitos: aceitar os termos das Industry APIs (Setup > Enable Access to Industry APIs); PSL Shared Product Catalog +
  Industries CPQ **ou** licença do pacote no usuário da API; instalar o **multipack TMF620** e o DataPack Attribute
  Category; API 58+: importar os static resources TMFOpenAPI; connected app com OAuth 2.0.
- Mapeamentos do Product Offering: name -> Product2.Name; productNumber -> ProductCode; isBundle -> SpecificationSubType;
  isSellable -> IsOrderable; lifecycleStatus -> Status + IsActive; bundledProductOffering -> ProductChildItem;
  prodSpecCharValueUse -> AttributeAssignment; productOfferingPrice -> PriceListEntry (+ PricingElement amount, charge
  type, recurring frequency); productOfferingRelationship -> ProductRelationship; productOfferingTerm -> Promotion +
  TimePlan; productSpecification -> ProductSpecId; validFor -> SellingStartDate / EndOfLifeDate; version -> VersionLabel.

**Limitações declaradas ("Constraints and Limitations") que conflitam com o template v1.1:**
| Limite do TMF620 | Efeito no nosso modelo |
|---|---|
| "The minimum, maximum and quantity field of ProductChildItem ... is set to 1" (embora o subrecurso mapeie lower/upper/default) | Cardinalidade 0/0/1 (opcional) e grupos "escolha um" não saem pela API sem teste; a aba Estrutura Comercial não cabe inteira |
| Price List única, fixada em custom metadata (TMForumPriceList) | Sem lista por zona (CAT-ZON-01) via API |
| Attribute Category única em custom metadata (TMForumDefaultAttributeCategory) | Todos os atributos numa categoria só; sem picklist/valores de picklist mapeados |
| "It is not possible to add additional entity mappings to extend POST resource of the Product Offering API" | Campos custom (Código material SAP, Descrição fiscal, Documento fiscal, Marca) não entram |
| Category exige catálogo já existente; relacionamentos exigem entidades existentes; PATCH sobrescreve pricelist/promotion | Ordem de carga e pré-existência viram responsabilidade do chamador |
| Bundle casa filho só por GlobalKey + Name | O nome tem de ser idêntico ao da org, senão não liga |
| GET/POST de filhos exige custom metadata (4 registros) + editar 2 DataRaptors | Configuração extra antes de usar |

Conclusão: **TMF620 inbound serve para o esqueleto** (spec, oferta, filhos simples, atributos com valor, preço base em
uma lista) e para integração contínua no futuro. **Não cobre** cardinalidade/grupos, zonas, picklists, campos fiscais,
matriz por atributo, regras de contexto. Para a carga completa do template, o caminho é DataPack.

Bônus que vale registrar: existe **TMF620 outbound** (EPC -> MuleSoft -> sistemas externos) quando uma oferta é criada ou
alterada no EPC. É o caminho natural para o Control Plane **receber de volta** o que está publicado na org (reconciliação,
menu "Reconciliação e UAT").

### Vlocity Build (vlocityinc/vlocity_build, v1.17.24, MIT): confirmado como motor de carga

- `npm install --global vlocity`; autenticação pela CLI: `-sfdx.username btp-preprod`. Node 18+.
- **DataPack de Product2 leva junto**: PricebookEntry, AttributeAssignment, ProductChildItem, OverrideDefinition,
  ProductRelationship, ProductEligibility, ProductAvailability, PricingElement, PriceListEntry, DecompositionRelationship,
  OrchestrationScenario. Tipos separados: VlocityPicklist (Picklist + PicklistValue), AttributeCategory (+ Attribute),
  ObjectClass, Catalog (+ CatalogProductRelationship), PriceList (+ PricingElement, PricingVariable), PricingPlan,
  Promotion (+ PromotionItem), TimePlan, TimePolicy, CalculationMatrix, ContextDimension, ContextScope, Rule,
  OrchestrationPlanDefinition. **Cobre as 14 abas de dados do template.**
- Chave do DataPack: `Product2/<GlobalKey>` (pasta = GlobalKey). Matching keys padrão: Product2 = GlobalKey; PriceList,
  PricingVariable, Attribute, AttributeCategory = Code; CatalogProductRelationship = CatalogId + Product2Id;
  PromotionItem = ProductId + PromotionId; PricebookEntry = Product2Id + Pricebook2Id + CurrencyIsoCode. **Pode-se criar
  Matching Key custom para Product2 = ProductCode**, que é exatamente o "Código" do template.
- Fluxo: `validateLocalData` (GlobalKeys ausentes/duplicadas) -> `packDeploy` -> `packRetry` até o erro parar de cair ->
  `packGetDiffs`. `gitCheck: true` para deploy incremental por commit. `postStepApex: EPCProductJSONUpdate.cls` gera o JSON
  de atributos após deploy de produtos (o job de metadados do Pós-carga, automatizado). Product2 não deploya em paralelo
  (`SupportParallel: false`). Logs: VlocityBuildLog.yaml e VlocityBuildErrors.log.
- Erros já mapeados: "missing a Pricebook Entry in pricebook" (filho fora do Pricebook), "Duplicate Results found for
  Product2 WHERE GlobalKey" (duplicata na org), "No match found for ProductChildItem.ChildProductId" (filho não
  deployado), "No Configuration Found" (rodar packUpdateSettings), "Multiple Imported Records" (mesmo produto duas vezes
  no mesmo catálogo).
- Sandbox nova: `installVlocityInitial` uma vez.

### Skill oficial omnistudio-epc-catalog-generate (forcedotcom/sf-skills): confirmado

`npx skills add https://github.com/forcedotcom/sf-skills --skill omnistudio-epc-catalog-generate` (4,7 mil instalações,
auditorias de segurança aprovadas). Templates em `assets/`: product2-offer, attribute-assignment, product-child-item,
pricebook-entries, price-list-entries, object-field-attributes, orchestration-scenarios, decomposition-relationships,
compiled-attribute-overrides, override-definitions, parent-keys; exemplos por tipo de oferta em `assets/examples/`.
Complemento: skill `sf-vlocity-build-deploy` (jaganpro, migrando para forcedotcom/afv-library) com o gate
validateLocalData -> packGetDiffs -> packDeploy -> packRetry e a matriz de erros.

### Standard Cart APIs v2 (para o teste de carrinho do Pós-carga)

`POST /services/apexrest/vlocity_cmt/v2/carts` (Create Cart), `.../v2/cpq/carts/{id}/items` (add/update/delete),
`.../price` (run pricing), `.../items/checkout`, `.../promotions`. Habilitar as standard cart APIs na org (Winter '24+).

## 7. Arquitetura final (revisada com a doc)

```
Control Plane
  export A (obrigatório): DataPacks JSON no formato Vlocity Build, pastas por VlocityDataPackKey
     Product2/<GlobalKey>, VlocityPicklist/<key>, AttributeCategory/<Code>, PriceList/<Code>,
     Promotion/<GlobalKey>, TimePlan/<GlobalKey>, Catalog/<GlobalKey>, CalculationMatrix/<Name>, ContextDimension/<GlobalKey>
     (templates da skill oficial como esqueleto; o gerador dele preenche)
  export B (governança/leitura): xlsx no template v1.1 (Decisão de Modelagem, Pós-carga, Controle de Mudanças + espelho das abas)
  export C (futuro, opcional): TMF620 JSON para integração contínua e para receber de volta pelo outbound
Claude Code local (sf-skills + Vlocity Build)
  validateLocalData -> rubric da skill -> packDeploy na sandbox -> packRetry -> EPCProductJSONUpdate ->
  jobs de hierarquia/pricebook/cache -> teste de carrinho pela Cart API v2 -> packGetDiffs -> commit do DataPack no git
Pipeline: git -> QA -> produção via packDeploy (gitCheck), nunca planilha, nunca TMF620 direto em produção
```

Decisão a pedir ao presidente: o gerador dele produz DataPack (formato de deploy) ou só o xlsx (e o Claude converte)?
Produzir DataPack direto é o "bem legal": o export dele já é o que a org recebe, sem tradução no meio.

Pré-requisitos a confirmar na org (sessão local): Matching Key custom Product2 = ProductCode (decidir), Pricebook padrão
das listas, `installVlocityInitial` já rodado na sandbox alvo, standard cart APIs habilitadas.
