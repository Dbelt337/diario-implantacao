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
