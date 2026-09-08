# W-000111 — US CAT-FAM-01 — Modelagem EPC das famílias Móvel, Streaming e Câmera

Épico: Catálogo Comercial Unificado - B2B/B2C | Time: Salesforce | Product Tag: Salesforce | Status: New | Responsável: Davi Israel de Abreu
Criado: 08/09/2026 14:21 por Diego Beltrão de Moraes | Alterado: 08/09/2026 14:21 por Diego Beltrão de Moraes

US de catálogo (agenda presencial 03/09: temas "Transição para Produtos de Streaming", "Unificação de CNPJs e Simplificação de Planos Móveis", "Configuração de Produtos de Câmeras e Armazenamento em Nuvem"; revisão da planilha de Object Types de 04/09).

NARRATIVA
Como Gestão de Produtos, quero as famílias Móvel, Streaming e Câmera modeladas no EPC como ofertas comerciais próprias, com seus Object Types, atributos e regras de composição, para que possam ser vendidas isoladamente ou em combo com internet na Onda 1 e apareçam na navegação por família.

CONTEXTO E CENÁRIO DE NEGÓCIO
A TEC-B2C-02 (W-000085) modela planos de internet, SVAs e promotions. As três famílias novas só existem como atributos propostos na revisão da planilha (Franquia de Dados, Nível de Streaming, Limite de Licenças, Quantidade de Câmeras, Armazenamento em Nuvem). Decisões de 03/09: somente streaming, sem TV tradicional ou TV Box; móvel em pacotes fixos de dados sem aparelho; câmera é equipamento com estoque mais serviço de nuvem por 7 ou 30 dias.

REGRAS DE NEGÓCIO
RN-01 Streaming: oferta de serviço digital sem equipamento e sem visita; níveis Básico, Premium e Hub; limite de licenças de 1 a 3 conforme o item; nomes genéricos, sem marca.
RN-02 Móvel: pacotes fixos de 6, 10, 15, 25, 50 e 75 GB; sem aparelho; prazo de contrato como atributo; sem emissão de NF pela BTP (MVNO).
RN-03 Câmera: produto composto por equipamento (1 a 10 unidades, movimenta estoque, gera Work Order) e serviço de armazenamento em nuvem (7 ou 30 dias, sem visita); ambiente Indoor ou Outdoor.
RN-04 Herança: as três famílias nascem de Object Types filhos de Especificação de Oferta, com categorias e picklists reutilizadas (Prazo de Contrato, Ambiente).
RN-05 Composição: cada família pode ser vendida sozinha ou como componente de Promotion com internet; nunca como bundle físico.
RN-06 Navegação: cada família é uma categoria de navegação dentro dos catálogos por mercado (decisão de navegação por família).
RN-07 Preço: as três famílias entram na matriz de preços com as mesmas dimensões (zona de preço, prazo, segmento) quando aplicável.

ESPECIFICAÇÃO TÉCNICA
Object Types Oferta Móvel, Oferta de Streaming e Oferta de Câmera (aba Object Type da revisão v2); atributos e picklists conforme a aba Valores (PL_FRANQUIA_DADOS, PL_NIVEL_STREAMING, PL_LIMITE_LICENCAS, PL_QTD_CAMERAS, PL_ARMAZENAMENTO_NUVEM, reuso de PL_PRAZO_MESES e PL_AMBIENTE); Product Specs e produtos comerciais; câmera como produto com filho de equipamento (inventário) e filho de serviço; identificador técnico do fornecedor separado (US TEC-INT-02); publicação nos catálogos por mercado e categorias de navegação.

DEPENDÊNCIAS E RISCOS
Dependências: EPC-01/03/04/05; revisão da planilha de atributos aprovada (categoria CAT_SERVICOS_DIGITAIS ratificada); US CAT-TPL-01; contratos com fornecedores (US TEC-INT-02); parceiro móvel.
Riscos: integração móvel sem prazo; controle de estoque de câmeras fora do Salesforce; limite de licenças divergente por fornecedor.

CRITÉRIOS DE ACEITE
Cenário 1: Streaming isolado. Dado um cliente sem internet BTP, quando o vendedor buscar a família Streaming, então consegue vender Streaming Premium com 3 licenças sem Work Order e sem equipamento.
Cenário 2: Câmera. Dado uma venda de 2 câmeras Outdoor com nuvem de 30 dias, quando confirmada, então o pedido tem linha de equipamento com quantidade 2 e baixa de estoque, linha de serviço de nuvem e uma Work Order.
Cenário 3: Móvel. Dado uma venda de plano móvel 15 GB, quando confirmada, então não há aparelho, não há campos fiscais de NF e o prazo de contrato está na linha.
Cenário 4: Combo. Dado internet 600M + streaming, quando montado, então os dois produtos permanecem registros separados unidos por Promotion e a navegação mostra cada um na sua família.
