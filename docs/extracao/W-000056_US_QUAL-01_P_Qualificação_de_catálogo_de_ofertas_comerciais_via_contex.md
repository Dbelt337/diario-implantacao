# W-000056 — US QUAL-01 (P) — Qualificação de catálogo de ofertas comerciais via contexto de elegibilidade (Tetra-pé)

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: SysMap | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 19/08/2026 19:13 por Diego Beltrão de Moraes | Alterado: 04/09/2026 15:38 por Diego Beltrão de Moraes

Como Consultor de Vendas ou Cliente da jornada de autosserviço (E-commerce/App),
quero que o motor de regras do Salesforce filtre dinamicamente as ofertas do catálogo
usando o contexto de qualificação Tetra-pé — Mercado/Segmento, Canal de Venda,
Tipo de Cliente (CPF/CNPJ) e Cidade (código IBGE) —
para que apenas as opções elegíveis ao perfil e localização sejam exibidas,
sem duplicação de ofertas por contexto.

ESTRUTURA DE CATÁLOGOS DESTA WORK (Manual v2.2 §9.1): catálogos por mercado —
CAT_B2C_EVO, CAT_B2S_EVO, CAT_B2B_EVO, CAT_B2G_EVO, CAT_WHOLESALE_EVO.
Famílias (Internet, TV, Streaming etc.) são Categorias de navegação dentro dos
catálogos, não catálogos próprios. Proibido catálogo por canal (§28.3) e por família.
Publicação N:N: a mesma oferta pode estar em múltiplos catálogos. CAT_B2G_EVO não
é publicado no e-commerce (venda assistida apenas; CreditPolicyCode =
CREDIT_NOT_REQUIRED, sem análise de crédito).

ESCOPO PARCIAL DESTA WORK: criar os 5 catálogos, as categorias por família e os
Rule Sets globais de qualificação (máx. 4, reutilizáveis — QUAL_MERCADO, QUAL_CANAL,
QUAL_TIPO_CLIENTE, QUAL_CIDADE), aplicados a Products e Promotions. A resolução
cidade→zona usa a GeographicCommercialPolicy (P-17, modelo do §37.2). Os domínios
de valores de mercado, canal e segmento aguardam formalização do Joel (P-19) —
entram como "a confirmar". Diferenciação de preço B2C/B2B via Price Lists separadas
(PL_B2C_EVO, PL_B2B_EVO), produto único no catálogo.

Dependências: P-19 (domínios de qualificação — Joel); P-17 (solução técnica IBGE);
EPC-01/EPC-04 (estrutura base). Não depende da EPC-02 (picklists de produto).

Fonte: US original "Qualificação de Catálogo de Ofertas Comerciais via Contexto de
Elegibilidade (Tetra-pé)"; Manual v2.2 §9, §14.2, §28.3, §37.

## Critérios de Aceite (related list)

**1. 4** (New)
5. Preço sem duplicação — Dado que a mesma oferta é vendida em B2C e B2B, quando o
   contexto for identificado, então preços distintos vêm de Price Lists separadas,
   mantendo o produto unificado no catálogo.

**2. 4** (New)
4. Sequenciamento — Dado que o cliente navega no funil, quando o catálogo for
   apresentado, então primeiro listam-se as ofertas qualificadas pelos 4 parâmetros;
   a viabilidade técnica por endereço só dispara após a escolha da oferta.

**3. 3** (New)
3. Máximo 4 Rule Sets globais — Dado que as ofertas precisam ser qualificadas,
   quando o catálogo for parametrizado, então a qualificação usa no máximo 4
   conjuntos de regras de contexto globais e reutilizáveis, sem regra individual
   por oferta.

**4. 2** (New)
2. Filtro por zona (IBGE) — Dado que o cliente informou a cidade, quando a
   elegibilidade local for validada, então o sistema resolve CityIBGECode →
   AvailabilityZoneCode via GeographicCommercialPolicy e habilita/oculta as ofertas
   da zona, sem relação direta Oferta×Cidade.

**5. 1** (New)
1. Captura do contexto — Dado que uma jornada de venda inicia, quando os dados de
   identificação e localização são inseridos, então o sistema captura e repassa ao
   motor de regras os 4 parâmetros obrigatórios: Mercado/Segmento, Canal, Tipo de
   Cliente (CPF/CNPJ) e Cidade (código IBGE).

## Notas de Refinamento e Decisões Registradas

--- NAVEGACAO POR FAMILIA (04/09, ata de 03/09) ---
Decisao das sessoes de pratica: a navegacao da vitrine/carrinho ocorre por FAMILIA de produtos (Internet, Stream, Camera, Movel), conforme demonstrado em 03/09. Ajustar a estrutura desta work para que a experiencia de navegacao siga esse modelo, mantendo a qualificacao tetra-pe e a publicacao N:N. Registrar na especificacao como as familias se materializam (catalogos de navegacao ou categorias), garantindo compatibilidade com GetOffersByCatalog e com a estrutura de price lists por segmento.

--- REAPROVEITAMENTO AS-IS (consultoria BTP, base 21/08) ---
SITUACAO: reuso comprovado (matriz #6).
REUSAR: PL_B2C (price list ativa) e os catalogos Jornada-PF, Internet-Residencial e TV-Residencial; configuradores CPQ da jornada PF.
EVIDENCIA: vlocity-backup/PriceList/PL_B2C | vlocity-backup/Catalog/Jornada-PF | vlocity-backup/Catalog/Internet-Residencial | vlocity-backup/Catalog/TV-Residencial.
CONSTRUIR: os 5 catalogos por mercado e os 4 Rule Sets globais nascem SOBRE essa base - PL_B2C_EVO e evolucao/migracao da PL_B2C existente, nao criacao do zero; produto movel e regras por canal sao novos.
DIRETRIZ SYSMAP: comecar inventariando os itens da PL_B2C e dos 3 catalogos atuais; montar o de-para para a nova estrutura ANTES de criar registros novos, evitando catalogo duplicado na org.

## Comentários

- Diego Beltrão de Moraes 21/08/2026 17:34: Epic__c, Catálogo Comercial Unificado - B2B/B2C, has been added.
