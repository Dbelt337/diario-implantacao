# W-000113 — US CAT-API-01 — Cache das APIs de oferta (Digital Commerce) e rotina de atualização do catálogo

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:22 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:22 por Diego Beltrão de Moraes

US de catálogo/e-commerce (agenda presencial 03/09: tema "Detalhes Técnicos de APIs e Cache" sobre getOffers e getOfferDetails; considerações de uso do Digital Commerce).

NARRATIVA
Como time de plataforma, quero uma rotina definida de atualização do cache das APIs de oferta sempre que catálogo, preço ou promoção mudar, para que o e-commerce e o app exibam as ofertas e preços vigentes e nunca uma promoção expirada ou um preço antigo.

CONTEXTO E CENÁRIO DE NEGÓCIO
As APIs cacheáveis do Digital Commerce (GetOffersByCatalog, GetOfferDetails) dependem de jobs de cache: manutenção da hierarquia de produtos, limpeza e refresh, geração de contexto de elegibilidade e população do cache. Ofertas expiradas não são removidas automaticamente do cache, penalidades de promoção não são suportadas nas APIs cacheáveis e as dimensões de contexto aceitam apenas valores absolutos com operadores de igualdade e diferença. Sem rotina, a alteração de preço de uma promotion não chega ao canal digital.

REGRAS DE NEGÓCIO
RN-01 Toda publicação de catálogo, preço ou promoção termina com a atualização do cache; a mudança só é considerada em produção quando o cache reflete o novo estado.
RN-02 Expiração: promoções com data de fim são retiradas do cache na data, por job agendado, e não apenas pela expiração lógica.
RN-03 Janela: refresh completo fora do horário comercial; refresh incremental permitido em horário comercial apenas para preço e promoção.
RN-04 Contexto: as dimensões de elegibilidade usadas no cache (mercado, canal, tipo de cliente, zona) são valores absolutos e sensíveis a maiúsculas; o dicionário de valores é único com a QUAL-01.
RN-05 Validação: após cada refresh, uma verificação automática compara uma amostra de ofertas e preços entre carrinho do vendedor e API cacheada; divergência bloqueia a publicação.
RN-06 Limite de combinações: o número de combinações de contexto é monitorado contra o limite do produto; novas dimensões exigem análise de impacto.

ESPECIFICAÇÃO TÉCNICA
Jobs do Digital Commerce em sequência: Product Hierarchy Maintenance, Clear Cache, Refresh Cache, ContextEligibilityGenerator e Populate API Cache, agendados e também acionáveis remotamente ao final da carga da planilha mestre; job diário de expiração de promoções; rotina de paridade (SOQL no carrinho versus resposta da API) com relatório; parâmetro UseAssetReferenceIdForParentAndRoot alinhado com MACD (US B2C-32); retenção de 72 horas do cache considerada no planejamento de lançamentos.

DEPENDÊNCIAS E RISCOS
Dependências: US CAT-TPL-01 (carga do catálogo); QUAL-01 e US CAT-ZON-01 (dimensões de contexto); TEC-B2C-02; canal e-commerce (B2C-18).
Riscos: conflito de configuração entre MACD e APIs cacheáveis; tempo de refresh completo com catálogo grande; promoções com penalidade fora do e-commerce.

CRITÉRIOS DE ACEITE
Cenário 1: Alteração de preço de promoção. Dado uma promotion com preço alterado, quando a rotina de publicação concluir, então GetOfferDetails devolve o novo preço em todos os contextos afetados.
Cenário 2: Expiração. Dado uma promotion com data de fim ontem, quando o job diário rodar, então ela não aparece mais em GetOffersByCatalog.
Cenário 3: Paridade. Dado uma amostra de 20 ofertas, quando a verificação pós-refresh rodar, então carrinho e API cacheada apresentam os mesmos preços; em caso de divergência a publicação é marcada como falha.
Cenário 4: Contexto inválido. Dado um valor de dimensão com grafia diferente do dicionário, quando o cache for gerado, então o erro é apontado antes da publicação.
