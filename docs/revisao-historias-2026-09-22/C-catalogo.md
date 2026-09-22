# Revisao tecnica - Grupo C: Catalogo Comercial Unificado B2B/B2C (18 historias)

Base: BRIEF.md (native first, Communications Cloud / Industries CPQ / EPC). Data da revisao: 22/09/2026.
Notas: Verde = pronta e native-first; Amarelo = ajustar escrita ou desenho; Vermelho = reescrever ou redesenhar.
Contagem: 4 Verde, 13 Amarelo, 1 Vermelho.

## Tabela resumo

| Work | Assunto (curto) | Nota | Capacidade nativa principal | Ajuste em 1 linha |
|---|---|---|---|---|
| W-000051 | EPC-01 Attribute Categories | Verde | Attribute Category (Product Console/Designer), Display Sequence, Applicable Types | Corrigir a frase "tipo definido na categoria" (data type e do atributo) e mover o bloco de consolidacao 15/09 para a work filha |
| W-000052 | EPC-04 Object Types, heranca, layouts | Amarelo | Object Type hierarchy, heranca dinamica de campos/atributos, copia de layout | Deixar UMA hierarquia normativa (arvore v3 em 2 niveis) e fechar o conflito Codigo SAP campo x atributo com a W-000041 |
| W-000053 | EPC-05 Product Specifications | Amarelo | Product/Offer/Service/Resource Specification (ProductSpecId no Product2) | Realinhar a lista de specs ao modelo v3 (3 familias, filhos da CAT-CHD-01) e criar AC de "produto referencia exatamente uma spec" |
| W-000054 | EPC-09 Compilacao e integridade | Verde | EPCProductAttribJSONBatchJob, EPCFixCompiledAttributeOverrideBatchJob, EPC Jobs (Generate Compile Data), Product Hierarchy Maintenance | Incluir Generate Compile Data por price list e o handoff para o cache do Digital Commerce (CAT-API-01) |
| W-000055 | EPC-03 Dicionario de atributos | Amarelo | Attribute + Data Type + Picklist, Attribute Assignment por Object Type, overrides | Declarar que os metadados de governanca ficam no dicionario (nao em campos custom) e mover o AC3 (Mapping Rule) para a US de decomposicao |
| W-000056 | QUAL-01 Qualificacao Tetra-pe | Amarelo | Context Rules (dimensoes, mapping, rule sets) em produtos, promocoes e PLEs; Digital Commerce context eligibility | Resolver o conflito de estrutura de catalogo com a W-000070 por ADR e usar ZONA (nao cidade IBGE) como dimensao de contexto |
| W-000070 | EPC-10 Catalogos comerciais | Vermelho | Catalog + Category + publicacao N:N, filtragem por Context Rules | Reescrever: um unico modelo de catalogo (ADR), lista de familias atual, nomes genericos, tirar o dump de decisoes P-01..P-18 |
| W-000102 | CAT-TPL-01 Planilha mestre | Amarelo | Carga via Bulk API/Data Loader (upsert por External Id), DataPacks, EPC REST APIs | Adicionar o de-para aba -> objeto EPC e definir o mecanismo de carga; AC verificaveis (nao "erro proximo de zero") |
| W-000103 | CAT-MIG-01 Migracao de ativos | Amarelo | Asset com campos vlocity_cmt (AssetReferenceId, RootItemId, ParentItemId, JSONAttribute), Bulk API upsert, ABO | Separar contas/contratos de ativos e especificar os campos Vlocity obrigatorios para o ativo abrir em Change to Order |
| W-000104 | CAT-TAG-01 Service Tag | Amarelo | Campo Unique + External ID (unicidade no banco), Auto Task no plano de orquestracao, UUID/Crypto Apex | Avaliar Auto Number nativo antes do Apex; gerar na Auto Task (nao trigger) e definir o mapeamento OrderItem -> Asset |
| W-000108 | CAT-PRC-01 Regra de desconto em combos | Amarelo | Promotions (ajuste fixo por item), Time Plans, Context Rules em PLE por zona, Discounts, pricing plan | Trazer os exemplos numericos para os AC e definir o mecanismo do floor (nao existe "floor" nativo) |
| W-000111 | CAT-FAM-01 Familias Movel, Streaming, Camera | Amarelo | Object Types, atributos, specs, bundle (camera), Promotions, categorias | Tirar a referencia a "catalogos por mercado", tirar estoque/NF do escopo e escrever AC por familia |
| W-000112 | CAT-CHD-01 Componentes como produtos filhos | Verde | ProductChildItem com cardinalidade min 0, atributos no filho, PLE por filho, Compatibility Rules, decomposicao | Verificar se "meio de acesso diferente do primario" cabe em Product Relationship ou exige Advanced Rule com filtro de atributo |
| W-000113 | CAT-API-01 Cache Digital Commerce | Verde | Jobs DC (Product Hierarchy Maintenance, Clear/Refresh Cache, ContextEligibilityGenerator, Populate API Cache), execucao remota | Fixar qual Digital Commerce (managed package cacheable APIs x Standard DC) pois o conjunto de jobs muda |
| W-000114 | CAT-ZON-01 Zonas IBGE -> zona | Amarelo | Context dimension + context mapping em sObject, qualificacao de PLE por zona, upsert por External Id | Definir onde a zona resolvida fica persistida (Account/Premises/Order) para o context mapping ler; chave composta se houver vigencia |
| W-000121 | CAT-CPX-01 Taxa Unica (CAPEX) | Amarelo | Pricing Variables one-time x recurring, Attribute-Based Pricing com matriz, Context Rule de visibilidade | Escolher UM mecanismo: matriz com Modalidade como coluna de entrada (MRC/NRC), em vez de "PLE por modalidade" nao comprovada |
| W-000127 | CAT-EQP-01 CPE e matriz de compatibilidade | Amarelo | Product2 por modelo, Resource Spec via decomposicao, Decision Matrix (BRE), carrinho ABO | Dividir em 3 (modelo comercial, CPE tecnico/decomposicao, matriz de upgrade) e dizer por onde a Decision Matrix e chamada no carrinho |
| W-000128 | CAT-RET-01 Promotions de retencao | Amarelo | Promotion + Time Plan/Policy, Context Rules em promocao, Account-based Discount com aprovacao | Um motor por decisao (Context Rules para elegibilidade, aprovacao para N3) e explicitar que a volta ao preco de tabela e do billing (SAP) |

---

## W-000051 | US EPC-01 - Attribute Categories

1. ESCRITA: Persona, objetivo e regras claras; 3 AC verificaveis (existencia, vinculo, auditoria de sequencia). Ponto fraco: a afirmacao "o tipo e definido no nivel da categoria" nao confere com a documentacao (o Data Type e do atributo; a categoria tem Display Sequence e Applicable Types). O bloco "CONSOLIDACAO 15/09" (identico nas W-000051/052/055) mistura pendencias P1-P8 de outras frentes com esta historia.
2. NATIVO: Attribute Categories criadas em Product Console/Product Designer, com codigo, sequencia e tipos aplicaveis; atributos nascem ligados a uma categoria. Refs: https://help.salesforce.com/s/articleView?id=ind.v_admin_attribute_categories_26269.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.v_admin_create_new_product_attribute_categories.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.v_admin_attribute_data_types_25326.htm&language=en_US&type=5 ; https://trailhead.salesforce.com/content/learn/modules/industries-picklists-and-product-attributes/create-attribute-categories-and-attributes
3. DESVIO: nenhum; 100% configuracao. Risco baixo: taxonomia de 8 categorias e nomenclatura CAT_ colidem visualmente com os codigos CAT_ de catalogo da W-000070 (a propria W-000070 reconhece).
4. NOTA: Verde.
5. AJUSTE: corrigir a frase sobre o tipo; mover o bloco de consolidacao para a work filha "EPC-01 Conectividade"; adicionar AC de Applicable Types (Product) e status ativo; trocar o prefixo CAT_ das categorias (ex.: ATC_) para nao confundir com catalogos.

## W-000052 | US EPC-04 - Hierarquia de Object Types, atribuicao por nivel e layouts

1. ESCRITA: Tecnicamente densa e correta sobre heranca (campos/atributos dinamicos; layout copiado na criacao). Problema: tres camadas de revisao (35.3, 10/09, 15/09) coexistem no texto; a AC1 ainda cita "hierarquia 35.3 com extensao de gerenciados" enquanto a revisao diz "arvore em dois niveis, 3 familias". Conflito registrado e nao resolvido: Codigo SAP e Descricao Fiscal como atributo (W-000041) x campo do Product2 (v3).
2. NATIVO: Object Types com Parent Object Type, heranca de campos e atributos, layout herdado por copia; um Product2 aponta para um unico Object Type; recomendacao oficial de um base object type com campos comuns. Refs: https://help.salesforce.com/s/articleView?id=ind.comms_product_object_types_in_epc.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_layout_inheritance_within_the_object_type_hierarchy.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.energy_epc_best_practices_for_product_object_types.htm&language=en_US&type=5 ; https://trailhead.salesforce.com/content/learn/modules/industries-object-types/set-up-the-object-type-hierarchy
3. DESVIO: nenhum. Boa pratica confirmada: segmento B2B/B2C nao e object type (e elegibilidade + price list) e a quebra tecnica nao e object type comercial (e decomposicao). Risco de manutencao: mudar parent com descendentes obriga recompilacao (EPC-09).
4. NOTA: Amarelo.
5. AJUSTE: reescrever o corpo com a arvore v3 como unica hierarquia normativa (apagar 35.3 e "extensao gerenciados" ou marcar como historico); decidir Codigo SAP/Descricao Fiscal como CAMPO do Product2 (nao e caracteristica vendavel, nao precisa compilar atributo e e lido pela decomposicao); AC1 passa a citar a arvore v3.

## W-000053 | US EPC-05 - Product Specifications da Onda 1

1. ESCRITA: Objetivo e regra de reuso (REUSE_EXISTING) claros, 2 AC verificaveis. Desatualizada: lista PS_MANAGED_* e componentes (Fail-Over, Bastidor, NOC, Anti-DDoS) sao anteriores a v3 e a CAT-CHD-01 (NOC/Anti-DDoS viram produtos filhos). AC1 "sem redefinicao local" contradiz o uso legitimo de override por produto. Falta o vinculo produto comercial -> spec.
2. NATIVO: Product/Offer/Service/Resource Specifications como padroes de design reutilizaveis; produtos e ofertas realizam a spec; specs de servico/recurso nao sao vendidas. Refs: https://help.salesforce.com/s/articleView?id=ind.comms_product_specifications_in_epc.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_offer_specification_in_epc.htm&language=en_US&type=5 ; https://trailhead.salesforce.com/content/learn/modules/industries-products-and-product-bundles/explore-products-and-product-specifications
3. DESVIO: nenhum. Risco: criar spec por oferta (duplicacao) se a lista nao for alinhada as 3 familias.
4. NOTA: Amarelo.
5. AJUSTE: substituir a lista de specs pela derivada da v3 (Conectividade, Adicional, Equipamento Gerenciado + specs de servico/recurso da W-000137); AC novo: "todo Product2 comercial da Onda 1 referencia exatamente uma Product Spec ativa"; trocar "sem redefinicao local" por "override so no produto, justificado".

## W-000054 | US EPC-09 - Compilacao, batch jobs e integridade

1. ESCRITA: Persona, gatilhos (atribuir atributo a OT com produtos; overrides), evidencias (contagem de registros), relatorio de impacto e DoD ampliada. AC verificaveis. Falta so a lista completa de jobs e a ordem.
2. NATIVO: EPCProductAttribJSONBatchJob (regenera JSONAttribute) e EPCFixCompiledAttributeOverrideBatchJob (overrides), EPC Jobs no Vlocity CMT Administration (Generate Compile Data por price list, Winter '24+), Product Hierarchy Maintenance. Refs: https://trailhead.salesforce.com/content/learn/modules/shared-catalog-management/calibrate-attribute-data ; https://help.salesforce.com/s/articleView?id=ind.comms_epc_fix_compiled_attribute_override.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_running_epc_jobs.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_epc_generate_compile_data.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_administration_jobs_for_industries_communications_media_and_energy.htm&language=en_US&type=5
3. DESVIO: nenhum; e operacao de jobs nativos. Risco tecnico real: produtos legados da org com JSONAttribute desatualizado; tempo de execucao com catalogo grande.
4. NOTA: Verde.
5. AJUSTE: listar a sequencia (JSON batch -> Fix Override -> Generate Compile Data por price list -> Product Hierarchy Maintenance -> jobs de cache DC da CAT-API-01) e registrar tempos/contagens como evidencia no DoD.

## W-000055 | US EPC-03 (P) - Dicionario de atributos

1. ESCRITA: Escopo parcial bem delimitado; AC1/AC2 verificaveis. Problemas: metadados "visibilidade/editabilidade por canal, Assetizable, PricingImpact, OMImpact, EligibilityImpact, lifecycle, owner" nao dizem onde vivem (dicionario ou campos custom no Attribute); AC3 (derivacao por Mapping Rule para o OM) e da US de decomposicao; bloco de consolidacao 15/09 repetido.
2. NATIVO: Attribute com Data Type e Picklist, atribuicao por Object Type com heranca, override de valor/obrigatoriedade/visibilidade por OT ou produto. Refs: https://help.salesforce.com/s/articleView?id=ind.comms_product_attributes_in_epc.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_attributes_and_overrides_for_products_in_epc.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_attribute_and_picklist_overrides_for_the_object_type_and_at_the_product_level.htm&language=en_US&type=5
3. DESVIO: risco de criar campos custom no objeto Attribute para os "impactos" (desnecessario; e governanca documental). "Visibilidade por canal" nativa e via override/Context Rule, nao metadado do atributo.
4. NOTA: Amarelo.
5. AJUSTE: declarar que os metadados de governanca ficam na planilha do dicionario; mover AC3 para W-000137/decomposicao; AC explicito de que FIREWALL_VENDOR/WIFI_VENDOR e defaults "a confirmar" ficam fora da verificacao desta work.

## W-000056 | US QUAL-01 (P) - Qualificacao Tetra-pe

1. ESCRITA: Duas personas na mesma frase; parte de regras (4 rule sets reutilizaveis) e clara e testavel; parte de estrutura de catalogo (5 catalogos por mercado, "proibido catalogo por familia") contradiz frontalmente a W-000070 e a nota de 04/09 deixa a materializacao das familias em aberto. AC nao aparecem no texto. GeographicCommercialPolicy e objeto custom (aceitavel, mas nao esta dito).
2. NATIVO: Context Rules = dimensoes + context mapping em sObjects + rule sets aplicados a produtos, promocoes, price lists e PLEs; no Digital Commerce, context eligibility com valores absolutos. Refs: https://help.salesforce.com/s/articleView?id=ind.comms_availability_and_eligibility_rules.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_products.htm&language=en_US&type=5 ; https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/create-a-qualification-context-rule ; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-defining-context-eligibility-rules.html
3. DESVIO: usar Cidade IBGE (milhares de valores) como dimensao cacheavel explode as combinacoes de contexto do Populate Cache; a dimensao deve ser a ZONA resolvida (CAT-ZON-01). O objeto custom de politica geografica e um custom justificado (nao ha objeto nativo IBGE->zona).
4. NOTA: Amarelo.
5. AJUSTE: retirar daqui a definicao de catalogos (fica na W-000070 depois do ADR), manter so rule sets e dimensoes; trocar QUAL_CIDADE por QUAL_ZONA_DISPONIBILIDADE; escrever AC por dimensao (dado contexto X, oferta Y aparece/nao aparece no carrinho e no GetOffersByCatalog).

## W-000070 | US EPC-10 - Catalogos comerciais por familia

1. ESCRITA: Narrativa clara, mas o conteudo esta em conflito interno e externo: catalogos por familia aqui x por mercado na QUAL-01; lista de familias sem Movel/Camera e com TV "reservada" contra decisao de 03/09; nomes com marca contra o rebranding; numeracao P-17/P-18/P-19 divergente; o dump de decisoes P-01..P-18 (Onda 0) esta dentro da historia e nao e regra desta work. A propria nota de 08/09 lista 5 pendencias abertas.
2. NATIVO: Catalog e Category (produto publicado N:N via relacao catalogo-produto), navegacao por categoria, filtragem por Context Rules; Digital Commerce consulta ofertas por catalogo (GetOffersByCatalog). Refs: https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_enterprise_product_catalog__epc_.htm&type=5 ; https://developer.salesforce.com/docs/industries/cme/guide/comms-get-catalog-information.html ; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-get-offers-by-catalog-api.html ; https://developer.salesforce.com/docs/platform/data-models/guide/product-catalog-management.html
3. DESVIO: nenhum custom; os dois modelos sao nativos. Criterio para o ADR: cache do Digital Commerce e gerado por catalogo x combinacoes de contexto; menos catalogos (vitrine por mercado, familia como categoria) reduz jobs e cache; catalogo por familia facilita GetOffersByCatalog por vitrine de familia. Escolher um e parar.
4. NOTA: Vermelho.
5. AJUSTE: reescrever apos ADR unico "estrutura de catalogo" (recomendacao: poucos catalogos por vitrine + categorias por familia, N:N mantido); lista de familias/ofertas alinhada a 03/09 e nomes genericos; remover o bloco P-01..P-18 para a ata; AC do tipo "GetOffersByCatalog(CAT_X) retorna oferta Y na categoria Z para contexto W".

## W-000102 | US CAT-TPL-01 - Planilha mestre do catalogo

1. ESCRITA: Objetivo claro (fonte de verdade da carga), abas bem enumeradas. Faltam: de-para aba -> objeto/campo EPC, mecanismo de carga, criterio de "chance de erro proxima de zero" (nao verificavel), AC fora do texto. Coluna STATUS por linha sugere ferramenta propria de carga.
2. NATIVO: carga por Bulk API 2.0/Data Loader com upsert por External Id; DataPacks para mover catalogo entre orgs; EPC REST APIs para criar/versionar produtos; jobs de compilacao (EPC-09) apos a carga. Refs: https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/bulk_api_2_0_upsert.htm ; https://help.salesforce.com/s/articleView?id=000320964&language=en_US&mode=1&type=1 ; https://help.salesforce.com/s/articleView?id=sf.os_data_migration_with_vlocity_datapacks.htm&language=en_US&type=5 ; https://developer.salesforce.com/docs/industries/cme/references/epc
3. DESVIO: nao existe "loader de planilha" nativo; se virar script/app custom de carga com rastreio de status, e ferramenta de projeto (aceitavel) mas nao pode ir para producao como processo permanente. Matriz de precos com 4-5 dimensoes precisa nascer no formato de Calculation Matrix (colunas de entrada/saida) e Promotion Items, senao a planilha nao carrega.
4. NOTA: Amarelo.
5. AJUSTE: acrescentar aba de mapeamento (coluna -> objeto/campo/External Id: Product2, AttributeAssignment, Picklist/PicklistValue, PriceListEntry, CalculationMatrix rows, Promotion/PromotionItem, Catalog/Category); definir carga = Bulk API upsert + DataPack para estruturas; AC: "carga da aba X gera N registros sem erro e EPC-09 passa".

## W-000103 | US CAT-MIG-01 - Migracao da base legada de ativos

1. ESCRITA: Volumetria e ordem de carga (contas -> billing -> service/premises -> assets -> contratos) bem documentadas. Problemas: mistura 3 migracoes (contas, ativos, contratos); "tabelas temporarias de banco" e infraestrutura externa nao especificada; nao lista os campos Vlocity que o Asset precisa para o carrinho ABO funcionar; AC fora do texto.
2. NATIVO: Asset com hierarquia (RootItemId/ParentItemId/AssetReferenceId, LineNumber, JSONAttribute) para Asset-Based Ordering; Bulk API upsert por External Id; ExternalId por sistema (SAP, Customer Core). Refs: https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5 ; https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/bulk_api_2_0_upsert.htm ; https://help.salesforce.com/s/articleView?id=000385174&language=en_US&type=1
3. DESVIO: risco alto de ativo "morto": carregado sem JSONAttribute compilado, sem PricebookEntry/PriceList e sem hierarquia raiz/pai, o Change to Order nao abre nem reprecifica. "Staging em banco" fora do Salesforce e custom de projeto (aceitavel). Ativos legados amarrados a produtos que ainda nao existem no EPC bloqueiam MACD.
4. NOTA: Amarelo.
5. AJUSTE: dividir em US-contas (ja CAT-ACC-01), US-ativos e US-contratos; na US-ativos, especificar os campos obrigatorios e a regeneracao de atributos (EPC-09) apos a carga; AC: "ativo migrado abre em Change to Order, reprecifica pela price list e gera ordem MACD".

## W-000104 | US CAT-TAG-01 - Service Tag

1. ESCRITA: Excelente tecnicamente (unicidade no banco, retry em DUPLICATE_VALUE, fronteira com AssetReferenceId), mas prescreve implementacao (Base32 Crockford, Apex) antes de esgotar o nativo; nao diz como a tag gerada no OrderItem chega ao Asset na assetizacao; AC fora do texto.
2. NATIVO: campo custom Unique + External ID (restricao no banco, indice), Auto Number como gerador nativo sem codigo, Auto Task no plano de orquestracao do OM (criacao de asset como ultimo item antes de Complete Order), UUID.randomUUID() e Crypto em Apex quando precisar. Refs: https://help.salesforce.com/s/articleView?id=000385174&language=en_US&type=1 ; https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_t_assetization_and_activation_in_industries_ordermanagement_231201.htm&language=en_US&type=5 ; https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_UUID.htm
3. DESVIO: Apex proprio e justificavel so se o formato de 16 posicoes com timestamp for exigencia dos sistemas downstream; Auto Number (ex.: SV-{0000000000}) resolve unicidade sem codigo, mas nao serve como External Id de upsert (limitacao documentada: https://help.salesforce.com/s/articleView?id=000004514&language=en_US&type=1). Trigger e desaconselhado; usar Auto Task/Flow do OM.
4. NOTA: Amarelo.
5. AJUSTE: registrar a decisao Auto Number x Apex com o motivo; gerar na Auto Task de orquestracao; definir o mapeamento OrderItem.ServiceTag__c -> Asset.ServiceTag__c na assetizacao (configuracao de field mapping do CPQ/OM) e AC de colisao/imutabilidade.

## W-000108 | US CAT-PRC-01 - Regra de desconto em combos e promocoes regionais

1. ESCRITA: RN-01 a RN-07 sao regras de negocio de verdade e a persona/objetivo sao claros. Os exemplos numericos estao em documento anexo, nao nos AC; RN-06 (floor) nao diz como bloquear; "desconto contratual" nao nomeia o mecanismo; AC fora do texto.
2. NATIVO: Promotion com Promotion Items e ajuste fixo por item, Time Plan; Context Rules qualificando PLE por zona; Discounts account/contract-based; sequencia de pricing plan (base -> adjustments -> discounts); rastreio nativo de promocao aplicada nos itens. Refs: https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion ; https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/adjust-the-behavior-of-promotions ; https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_price_list_entries_and_child_price_lists.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5 ; https://developer.salesforce.com/docs/industries/cme/guide/comms-validate-cart-action.html
3. DESVIO: nao existe "floor" nativo; opcoes nativas: coluna de saida da Calculation Matrix + passo de expression set no pricing plan que sinaliza erro, ou aprovacao de desconto abaixo do limite. RN-04 (remover SVA desfaz o combo) depende do comportamento deep/shallow delete da Promotion e da cardinalidade. Limitacoes do DC citadas (penalidade, expiracao) estao corretas.
4. NOTA: Amarelo.
5. AJUSTE: colocar 3-4 exemplos numericos como AC (combo, troca de velocidade, remocao de SVA, fora de zona); escolher e escrever o mecanismo do floor; nomear "desconto contratual" como Contract-based Discount com aprovacao.

## W-000111 | US CAT-FAM-01 - Familias Movel, Streaming e Camera

1. ESCRITA: Regras por familia claras (niveis, franquias, cardinalidade de cameras). Mistura escopo de outros dominios: estoque e Work Order (RN-03), regra fiscal de NF do MVNO (RN-02), RN-06 cita "catalogos por mercado" (conflito da W-000070). AC fora do texto.
2. NATIVO: Object Types filhos com atributos/picklists reutilizados, Product Specs, camera como bundle (filho equipamento + filho servico com cardinalidade), venda em combo via Promotion, familia como Category. Refs: https://help.salesforce.com/s/articleView?id=ind.comms_product_bundles_and_cardinality_in_epc.htm&language=en_US&type=5 ; https://trailhead.salesforce.com/content/learn/modules/industries-products-and-product-bundles/create-product-bundles ; https://help.salesforce.com/s/articleView?id=ind.comms_product_object_types_in_epc.htm&language=en_US&type=5
3. DESVIO: nenhum no catalogo. Estoque nao e nativo do Salesforce (fica no SAP/Voalle via OM); Work Order vem do Field Service via orquestracao, nao do catalogo.
4. NOTA: Amarelo.
5. AJUSTE: limitar a US a object types, atributos, specs, bundle e publicacao; apontar estoque/WO/NF para as US de OM, FSL e fiscal; RN-06 passa a "categoria de navegacao conforme ADR de catalogo"; AC por familia (ex.: "Camera 4 unidades + nuvem 30 dias precifica X e gera 2 linhas").

## W-000112 | US CAT-CHD-01 - Componentes como produtos filhos

1. ESCRITA: Criterio de modelagem objetivo (preco/SLA/estoque -> filho; caracteristica -> atributo), lista fechada de filhos, cardinalidade, default por ausencia, impacto em picklists e decomposicao. AC fora do texto, mas as RN sao testaveis.
2. NATIVO: ProductChildItem com min 0 (opcional), atributo Nivel no filho (um produto, N valores), PLE por filho, regras de compatibilidade/Product Relationships (requires/excludes), decomposicao por filho no OM. Refs: https://help.salesforce.com/s/articleView?id=ind.comms_product_bundles_and_cardinality_in_epc.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_compatibility_rules.htm&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_rules_overview.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_t_multiple_decomposition_relationships_in_product_hierarchy_230382.htm&language=en_US&type=5
3. DESVIO: nenhum. Ponto a validar: "Porta Secundaria exige meio de acesso diferente do primario" compara atributos entre duas linhas; Product Relationship simples nao faz isso, Advanced Rule com filtro de atributo ou validacao no pricing/validation plan faz.
4. NOTA: Verde.
5. AJUSTE: acrescentar AC por filho (adicionar, precificar, remover) e um AC para a regra de meio de acesso, indicando o mecanismo (Advanced Rule) apos prova em sandbox.

## W-000113 | US CAT-API-01 - Cache das APIs de oferta

1. ESCRITA: Persona, gatilhos, janela, validacao e limites bem definidos; especificacao lista os jobs na ordem correta e cita limitacoes reais do DC. RN-05 (paridade carrinho x API) e rotina de teste, nao feature. AC fora do texto.
2. NATIVO: jobs de cache do Digital Commerce (Product Hierarchy Maintenance, Clear/Refresh Cache, ContextEligibilityGenerator, Populate API Cache) executaveis remotamente; consideracoes de uso (penalidades nao suportadas, dimensoes com valores absolutos, datas de venda). Refs: https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-batch-jobs.html ; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-cache-management.html ; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-running-maintenance-and-digital-commerce-cache-jobs-remotely.html ; https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-api-usage-considerations.html ; https://developer.salesforce.com/docs/industries/cme/guide/comms-run-admin-jobs-for-sdc.html
3. DESVIO: nenhum; "job diario de expiracao" e so agendamento dos jobs nativos. Risco: o conjunto de jobs e diferente entre Digital Commerce do managed package (cacheable APIs) e Standard Digital Commerce; UseAssetReferenceIdForParentAndRoot tem comportamento documentado como known issue (https://help.salesforce.com/s/issue?id=a028c00000gAzHsAAK&language=en_US).
4. NOTA: Verde.
5. AJUSTE: declarar qual sabor de Digital Commerce a org usa; mover RN-05 para o plano de testes; AC com tempo maximo de refresh e evidencia de que promocao expirada some da resposta.

## W-000114 | US CAT-ZON-01 - Zonas de disponibilidade e de preco

1. ESCRITA: Regras claras (chave IBGE, nivel unico, idempotencia, cidade sem zona bloqueia). Lacunas: RN-05 vigencia exige chave composta (IBGE + vigencia) que contradiz RN-04 (chave = IBGE); "Create Cart passa PriceZoneCode ao contexto" nao explica de onde o CPQ le a zona; AC fora do texto.
2. NATIVO: Context dimension mapeada por context mapping a campo de sObject (Account/Premises/Order); qualificacao de PLE por dimensao; carga por upsert com External Id. Refs: https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/create-context-rules-for-price-list-entries ; https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_price_list_entries_and_child_price_lists.htm&language=en_US&type=5 ; https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/bulk_api_2_0_upsert.htm
3. DESVIO: objeto custom IBGE -> zona e custom justificado (nao ha nativo). Para o carrinho CPQ a zona precisa estar gravada num campo do escopo de contexto (Account/ServicePoint/Order) lido pelo mapping; para o DC ela vai como parametro de contexto. Isso deve estar escrito, senao vira Apex no Create Cart.
4. NOTA: Amarelo.
5. AJUSTE: definir onde a zona resolvida e persistida e quem grava (viabilidade W-B2C-02); resolver vigencia (registro vigente por data ou sem vigencia na Onda 1); AC: "cidade X -> PLE da zona B aplicada no carrinho e no GetOfferDetails".

## W-000121 | US CAT-CPX-01 - Taxa Unica (CAPEX)

1. ESCRITA: Persona, RN e 3 cenarios Gherkin verificaveis (boa). O desenho e ambiguo: RN-02 fala em "duas PLEs por produto qualificadas pela modalidade" e RN-03 em Pricing Matrix por prazo e banda; sao dois mecanismos para o mesmo valor.
2. NATIVO: Pricing Variables distinguem one-time de recurring; PLE por pricing variable; Attribute-Based Pricing com Calculation Matrix (entradas: atributos; saidas: MRC/NRC) e pricing plan; Context Rule para visibilidade. Refs: https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/get-to-know-industries-pricing ; https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_pricing_matrices_for_attribute_based_pricing.htm&language=en_US&type=5 ; https://trailhead.salesforce.com/content/learn/modules/industries-attribute-based-pricing/configure-standard-attribute-based-pricing
3. DESVIO: qualificar PLE por VALOR DE ATRIBUTO da linha via Context Rule nao esta documentado como padrao (context rules leem sObjects mapeados); o caminho nativo comprovado e a matriz com Modalidade, Prazo e Banda como colunas de entrada e MRC/NRC como saida (Taxa Unica: NRC preenchido, MRC 0 por dado da matriz, sem regra). Sem produto duplicado.
4. NOTA: Amarelo.
5. AJUSTE: reescrever RN-02/RN-03 como um unico mecanismo (matriz ABP com Modalidade como entrada, PLE recorrente e PLE one-time no mesmo produto) e manter o cenario 1 como prova.

## W-000127 | US CAT-EQP-01 - CPE e matriz de compatibilidade

1. ESCRITA: Cenarios Gherkin bons. Mas sao tres historias: (a) equipamento comercial como produto filho, (b) CPE tecnico como Resource Spec via decomposicao, (c) matriz CPE x plano no upgrade; mais regras de posse/cobranca (RN-06/07) que sao politica comercial. Nao diz por onde a Decision Matrix e invocada no carrinho.
2. NATIVO: Product2 por modelo com atributos de ficha tecnica; Resource Specification ligada por Decomposition Relationship e resolvida no OM; Decision Matrix do Business Rules Engine chamada por Expression Set/Integration Procedure; carrinho ABO (Change to Order). Refs: https://help.salesforce.com/s/articleView?id=sf.decision_matrices.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?id=sf.expression_sets.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&language=en_US&type=5
3. DESVIO: a matriz e nativa, mas o "carrinho indica Sem visita / inclui troca de CPE" exige orquestrar: OmniScript de upgrade -> Integration Procedure -> Decision Matrix -> Cart API (auto-add do produto CPE). E cola OmniStudio, nao Apex, desde que escrito assim. Asset filho sincronizado do SAP e integracao (TEC-INT-03).
4. NOTA: Amarelo.
5. AJUSTE: dividir em 3 US; na de matriz, especificar entradas/saidas e o caminho de invocacao (IP + Cart API), e mover posse/cobranca para US comercial propria.

## W-000128 | US CAT-RET-01 - Promotions de retencao

1. ESCRITA: Boa narrativa e 3 cenarios verificaveis; regua em niveis clara. Fragilidades: RN-02 mistura dimensoes de conta, ativo e transacao (motivo de cancelamento) sem dizer onde cada uma e lida; RN-03 promete que "o billing volta ao preco" (sistema externo); usa dois motores (Context Rules e Decision Matrix) para a mesma decisao de elegibilidade; percentuais pendentes.
2. NATIVO: Promotion com Time Plan/Time Policy (duracao e gatilho de inicio), Context Rules qualificando promocoes por dimensoes mapeadas (Account/Asset), Account-based Discount com submissao e aprovacao de desconto, carrinho ABO. Refs: https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/create-time-plans-and-time-policies ; https://help.salesforce.com/s/articleView?id=ind.comms_availability_and_eligibility_rules.htm&language=en_US&type=5 ; https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5 ; https://help.salesforce.com/s/articleView?id=ind.comms_submit_discounts_for_approval_in_industries_cpq.htm&language=en_US&type=5
3. DESVIO: "campo de ultimo uso no Asset" + carimbo por Flow e custom pequeno e aceitavel; "motivo de cancelamento" como dimensao exige campo no Order/Account antes do carrinho; fim automatico no billing depende do SAP/Voalle consumirem as datas do time plan no payload (nao e o Salesforce que "volta o preco").
4. NOTA: Amarelo.
5. AJUSTE: uma engine por decisao (Context Rules para N1/N2, aprovacao de Discount para N3; Decision Matrix so se houver calculo de faixa); RN-03 reescrita como "a ordem leva data fim do time plan e o billing aplica"; marcar percentuais como parametro, nao regra.

---

## Padroes encontrados

1. Conflito de estrutura de catalogo nao resolvido (por mercado na W-000056 x por familia na W-000070), replicado na W-000111 RN-06. E a decisao que mais trava o grupo; ambos os modelos sao nativos, falta um ADR e limpar as outras works.
2. Blocos de governanca colados dentro das historias (consolidacao 15/09 identica em W-000051/052/055; decisoes P-01..P-18 dentro da W-000070; pendencias P1-P8 repetidas). Isso deixa as US sem uma versao unica e cria numeracao divergente de pendencias (P-17/P-18/P-19 com significados diferentes).
3. Criterios de aceite "migrados para related list" e ausentes do texto em 10 das 18 works; quem constroi nao ve o AC junto da regra. As works com Gherkin no corpo (W-000121, 127, 128) sao as mais construiveis.
4. Mistura de dominios na mesma US: estoque, Work Order, NF, billing e integracao SAP aparecem em historias de catalogo (W-000111, 127, 128, 103). Catalogo deve parar na publicacao/precificacao; fulfilment fica em OM/FSL/integracao.
5. Ambiguidade de mecanismo de precificacao: "PLE por modalidade" x matriz (W-000121), floor sem mecanismo (W-000108), Context Rules e Decision Matrix para a mesma decisao (W-000128). Escolher um caminho nativo por regra e escrever.
6. Dimensao de contexto no nivel errado: Cidade IBGE como dimensao (W-000056) em vez de zona resolvida (W-000114); em cache do Digital Commerce isso multiplica combinacoes.
7. Positivo: nenhuma historia pede carrinho proprio, LWC proprio ou objeto custom onde ha nativo; os customs identificados (objeto IBGE->zona, Service Tag, campo de ultimo uso) sao pequenos e justificados. O grupo e native-first no desenho; o problema e escrita e governanca.

## Referencias

- https://help.salesforce.com/s/articleView?id=ind.v_admin_attribute_categories_26269.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_admin_create_new_product_attribute_categories.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.v_admin_attribute_data_types_25326.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-picklists-and-product-attributes/create-attribute-categories-and-attributes
- https://help.salesforce.com/s/articleView?id=ind.comms_product_attributes_in_epc.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_attributes_and_overrides_for_products_in_epc.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_attribute_and_picklist_overrides_for_the_object_type_and_at_the_product_level.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_product_object_types_in_epc.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_layout_inheritance_within_the_object_type_hierarchy.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.energy_epc_best_practices_for_product_object_types.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-object-types/set-up-the-object-type-hierarchy
- https://help.salesforce.com/s/articleView?id=ind.comms_product_specifications_in_epc.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_offer_specification_in_epc.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-products-and-product-bundles/explore-products-and-product-specifications
- https://trailhead.salesforce.com/content/learn/modules/shared-catalog-management/calibrate-attribute-data
- https://help.salesforce.com/s/articleView?id=ind.comms_epc_fix_compiled_attribute_override.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_running_epc_jobs.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_epc_generate_compile_data.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_administration_jobs_for_industries_communications_media_and_energy.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_availability_and_eligibility_rules.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_products.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_qualification_rules_for_price_list_entries_and_child_price_lists.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/create-a-qualification-context-rule
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-context-rules/create-context-rules-for-price-list-entries
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-defining-context-eligibility-rules.html
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_enterprise_product_catalog__epc_.htm&type=5
- https://developer.salesforce.com/docs/industries/cme/guide/comms-get-catalog-information.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-get-offers-by-catalog-api.html
- https://developer.salesforce.com/docs/platform/data-models/guide/product-catalog-management.html
- https://developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/api_asynch/bulk_api_2_0_upsert.htm
- https://help.salesforce.com/s/articleView?id=000320964&language=en_US&mode=1&type=1
- https://help.salesforce.com/s/articleView?id=000004514&language=en_US&type=1
- https://help.salesforce.com/s/articleView?id=sf.os_data_migration_with_vlocity_datapacks.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.Comms_Migrate_Salesforce_IndustriesVlocity_Components.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/industries/cme/references/epc
- https://help.salesforce.com/s/articleView?id=ind.comms_asset_based_ordering.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_create_an_asset_based_order_in_industries_cpq.htm&type=5
- https://help.salesforce.com/s/issue?id=a028c00000gAzHsAAK&language=en_US
- https://help.salesforce.com/s/articleView?id=000385174&language=en_US&type=1
- https://help.salesforce.com/s/articleView?id=ind.comms_t_orchestration_plan_definition_231046.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_assetization_and_activation_in_industries_ordermanagement_231201.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_UUID.htm
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/build-a-promotion
- https://trailhead.salesforce.com/content/learn/modules/industries-cpq-promotions/adjust-the-behavior-of-promotions
- https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/create-time-plans-and-time-policies
- https://trailhead.salesforce.com/content/learn/modules/industries-pricing-exploration/get-to-know-industries-pricing
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_discounts_in_industries_cpq_and_epc_203126.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_submit_discounts_for_approval_in_industries_cpq.htm&language=en_US&type=5
- https://developer.salesforce.com/docs/industries/cme/guide/comms-validate-cart-action.html
- https://help.salesforce.com/s/articleView?id=ind.comms_product_bundles_and_cardinality_in_epc.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-products-and-product-bundles/create-product-bundles
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_compatibility_rules.htm&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_rules_overview.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_t_multiple_decomposition_relationships_in_product_hierarchy_230382.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?language=en_US&id=ind.comms_t_order_decomposition_configuration_230231.htm&type=5
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-batch-jobs.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-cache-management.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-running-maintenance-and-digital-commerce-cache-jobs-remotely.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-t-digital-commerce-api-usage-considerations.html
- https://developer.salesforce.com/docs/industries/cme/guide/comms-run-admin-jobs-for-sdc.html
- https://help.salesforce.com/s/articleView?id=ind.comms_attribute_based_pricing.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=ind.comms_pricing_matrices_for_attribute_based_pricing.htm&language=en_US&type=5
- https://trailhead.salesforce.com/content/learn/modules/industries-attribute-based-pricing/configure-standard-attribute-based-pricing
- https://help.salesforce.com/s/articleView?id=sf.decision_matrices.htm&language=en_US&type=5
- https://help.salesforce.com/s/articleView?id=sf.expression_sets.htm&language=en_US&type=5
