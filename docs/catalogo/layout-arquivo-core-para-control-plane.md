# Layout do arquivo do Customer Core para importar no Control Plane (17/09)

Uma linha por **opção de componente** (o nível mais baixo do Core). O sistema do presidente lê este arquivo, monta a
oferta e gera as abas do template v1.1. Colunas vistas no CSV de 17/09 (Smart Authenticator) marcadas "existe".

| # | Coluna | Existe | O que é | Vai para (template / EPC) |
|---|---|---|---|---|
| **Identificação** |
| 1 | OFERTA_ID | sim | id da oferta no Core | GlobalKey da oferta (BTP-OF-<id>) |
| 2 | SERVICO_ID | sim | id do agrupamento | Decisão de Modelagem (grupo de escolha ou ignorado) |
| 3 | COMPONENTE_ID | sim | id do componente | GlobalKey do produto (BTP-PR-<id>) quando o componente é o produto |
| 4 | COMPONENTE_OPCAO_ID | sim | id da opção | GlobalKey do produto ou do valor de picklist (BTP-PV-<id>) |
| 5 | IDENTIFICADOR_UNICO | sim | chave composta do Core | Produtos.Origem no Core |
| 6 | CODIGO_CANONICO | **falta** | código EPC definido pelo painel (OF_, CH_, PL_) | Produtos.Código = ProductCode |
| **Hierarquia e nomes** |
| 7 | OFERTA | sim | nome comercial da oferta | Produtos.Nome (camada Oferta) |
| 8 | SERVICO | sim | nome do agrupamento | não vira produto |
| 9 | COMPONENTE | sim | nome do componente | Produtos.Nome (camada Produto comercial) ou Atributo |
| 10 | COMPONENTE_OPCAO | sim | nome da opção | Produto filho ou Valor de picklist |
| 11 | TIPO_ELEMENTO | **falta** | PRODUTO ou VALOR_PICKLIST (decisão de modelagem) | define se a opção vira filho ou valor de atributo |
| **Estrutura** |
| 12 | COMPONENTE_OBRIGATORIO | sim | 0/1 | Estrutura Comercial.Qtd mínima (1 se obrigatório) |
| 13 | COMPONENTE_IGNORAR | sim | 0/1 | Ação = Ignorar |
| 14 | OPCAO_VIABILIDADE | sim | 0/1: opção depende de viabilidade técnica | Elegibilidade / Decomposição (registrar) |
| 15 | OPCAO_PESO | sim | ordem/peso | Estrutura Comercial.Sequência |
| 16 | QTD_MINIMA, QTD_PADRAO, QTD_MAXIMA | **falta** | cardinalidade da opção no bundle | Estrutura Comercial |
| 17 | GRUPO_ESCOLHA | **falta** | nome do grupo quando é "escolha um" | Estrutura Comercial.Grupo de escolha |
| 18 | UNIDADE | **falta** | peça, usuário, licença, mês | Produtos.Unidade |
| **Preço** |
| 19 | OPCAO_VALOR_MRC | sim | recorrente mensal | Preços (variável recorrente) |
| 20 | OPCAO_VALOR_NRC | **falta** | valor único (adesão, instalação, equipamento) | Preços (variável única) |
| 21 | TIPO_COBRANCA | **falta** | UNICA, RECORRENTE, AMBAS | Preços.Tipo de cobrança |
| 22 | LISTA_PRECO | **falta** | PL_B2B_EVO, PL_B2C_EVO | Preços.Lista de preço |
| 23 | SITUACAO_VALOR | **falta** | Ilustrativo ou Validado Core | Preços.Situação do valor |
| 24 | MOEDA | **falta** | BRL | Preços.Moeda |
| **Fiscal e SAP** |
| 25 | COD_SAP | sim | material SAP | Produtos.Código material SAP (por produto comercial, não por oferta) |
| 26 | DESCRICAO_FISCAL | **falta** | texto da nota | Produtos.Descrição fiscal |
| 27 | TIPO_FISCAL | sim | NFS-e, Fatura, NFCom | Produtos.Documento fiscal |
| 28 | TIPO_SERVICO | sim | TI, Telecom... | Produtos.Família (classe) com tabela de-para |
| **Comercial e disponibilidade** |
| 29 | SEGMENTO | sim | B2B, B2C | Elegibilidade (não é tipo de produto) |
| 30 | CATALOGO | sim | CAT_B2B_EVO | Catálogos |
| 31 | CANAL_VENDA | sim (vazio) | CH_DIRECT_SALES, CH_ECOMMERCE | Elegibilidade.Dimensão canal |
| 32 | ZONA | sim (vazio) | ZN_... ou vazio = nacional | Listas de Preço (zona) ou Elegibilidade |
| 33 | VIGENCIA_INICIO, VIGENCIA_FIM | **falta** | datas | Produtos e Preços |
| 34 | STATUS_CORE | **falta** | ativo/descontinuado no Core | Ação = Criar / Descontinuar |
| **Técnico (opcional nesta fase)** |
| 35 | CFS, RFS, RECURSO | **falta** | códigos técnicos se já conhecidos | Decomposição Técnica |
| 36 | GERA_ATIVO | **falta** | 0/1 | Produtos.Gera ativo |
| **Governança** |
| 37 | DECIDIDO_POR, DATA_DECISAO, MOTIVO | **falta** | quem validou a modelagem | Decisão de Modelagem |

## Regras de preenchimento

1. Uma linha por opção; oferta e componente se repetem nas linhas (é assim que o Core já vem).
2. Toda opção com MRC = 0 e NRC vazio é erro, não produto grátis: ou é valor único ou está faltando preço.
3. COD_SAP igual para opções diferentes (1005 nas quatro linhas do Smart Authenticator) precisa confirmação: token físico,
   licença e suporte normalmente não são o mesmo material.
4. CANAL_VENDA e ZONA vazios significam "todos" e "nacional"; o sistema não deve criar zona nova por isso.
5. IDENTIFICADOR_UNICO nunca muda; CODIGO_CANONICO é definido uma vez e também não muda.

## Observado no Smart Authenticator (17/09)

MRC 100, 200, 300 e 0 nas quatro opções; COD SAP 1005 em todas; segmento B2B; catálogo CAT_B2B_EVO; canal e zona
vazios. Falta: NRC, tipo de cobrança, unidade (peça, licença, usuário), cardinalidade, descrição fiscal, vigência.
