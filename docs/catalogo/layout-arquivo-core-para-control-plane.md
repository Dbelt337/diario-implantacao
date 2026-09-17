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

## Correção (17/09, tarde): OPCAO_VALOR não é preço

Na planilha completa (Ofertas_Atuais_migracao.xlsx, 9.953 linhas, 115 ofertas, 111 serviços, 183 componentes, 2.353 opções)
a coluna OPCAO_VALOR é o **valor técnico** da opção (Banda "1 Gbit/s" = 1000; Tipo de Prazo "Normal" = 1), preenchida em
2.252 linhas. **O Core não traz preço nenhum.** A coluna "OPCAO_VALOR_MRC" do exemplo Smart Authenticator (100/200/300/0)
era essa mesma coluna renomeada. Preço, SAP, catálogo, lista, segmento, canal, zona e vigência vêm de outra fonte.

Pacote gerado por `tools/catalogo/core_para_control_plane.py`: `saida/core_control_plane.xlsx` (LEIA-ME, OFERTAS,
COMPONENTES com decisão de modelagem proposta e confiança, OPCOES com 56 colunas, DICIONARIO), `core_control_plane.json`
(oferta > serviço > componente > opção) e `core_control_plane_opcoes.csv`. Decisões propostas: 125 picklists, 30 booleanos,
13 filhos com quantidade, 7 filhos fixos, 5 grupos de escolha (SKU), 3 componentes sem opção (ICCID, Ponta A, Ponta B).
Confiança BAIXA em 7 componentes (listas com mais de 100 valores: armazenamento cloud, modelos de appliance, estação de
telefonia). 1.135 linhas com IGNORAR, 445 opções com viabilidade, 24 de ativação (cobrança única).

## Valores por coluna e o motivo de cada um (17/09, para a pergunta do presidente)

| Coluna | Valores | Motivo |
|---|---|---|
| TIPO_FISCAL | NFS-e, Fatura, NFCom | São os três documentos que o Core já emite (6.112 / 2.458 / 1.383 linhas). O template grava em Documento fiscal e o SAP precisa do tipo para o handoff. Sem valor novo porque não existe quarto documento. |
| TIPO_SERVICO | SCI, SCM, STFC, SVA, TI, Locação, Imobilizado, Serviço, Engenharia | Domínio que já está no Core. É a base da classe de produto e do tratamento fiscal e regulatório (SCM e STFC são serviços de telecom regulados; SVA e TI não). |
| COMPONENTE_TIPO | Comercial, Ativação | Vem do Core. Ativação é o único sinal de cobrança única que o Core dá; sem ele todo preço vira recorrente. |
| 0/1 (obrigatório, ignorar, viabilidade, avulsa, mensurado) | 0, 1 | Booleanos do Core. Ficam como 0/1 para o sistema ler sem interpretar Sim/Não em português. |
| OPCAO_PESO | inteiro | Ordem na tela do carrinho (Sequência no EPC). |
| VALOR_TECNICO | número | É o OPCAO_VALOR original: valor da opção em unidade técnica (banda em Mbit/s). Alimenta o atributo técnico que o provisionamento lê; não é preço. |
| TIPO_ELEMENTO | ATRIBUTO_PICKLIST, ATRIBUTO_BOOLEANO, FILHO_FIXO, FILHO_ESCOLHA, FILHO_COM_QUANTIDADE | Os cinco jeitos que o EPC tem de representar uma opção do Core: valor de atributo (picklist ou checkbox), produto filho fixo, produto filho em grupo de escolha, produto filho com quantidade. Não há sexto caso. |
| CODIGO_CANONICO | OF_, CH_, AT_, PV_, GRP_ + nome | Vira ProductCode e código de atributo/picklist no EPC, que aceita só letras, números e sublinhado. O prefixo diz o tipo sem abrir o registro e evita colisão entre atributo e produto com o mesmo nome. Até 40 para caber nos campos Code do pacote. |
| GRUPO_ESCOLHA | GRP_<componente> | Virtual item do EPC: agrupa opções onde o cliente escolhe uma. Sem nome de grupo o carrinho mostra tudo solto. |
| CARD MIN, DEFAULT, MAX | inteiros | É como o Product Child Item do EPC guarda obrigatoriedade e quantidade. Obrigatório = min 1; "Nenhum" no Core = min 0; "3 Extensores" = quantidade, não três produtos. |
| UNIDADE | UN, PECA, LICENCA, USUARIO, MES, HORA, GB, MBPS | Unidade da quantidade na linha do carrinho e na fatura. Sem unidade, "10" não diz se é usuário ou gigabyte. |
| CLASSE DE PROD | classes do painel (CLASS_INTERNET_HOME...) | Object Type do EPC: define quais atributos o produto herda. Mapa por TIPO_SERVICO para não criar classe por oferta. Classe nova só com decisão. |
| GERA_ATIVO | 0, 1 | Campo IsNotAssetizable do EPC, invertido. Sem ativo não há MACD (mudança, upgrade, cancelamento) depois da venda. |
| OM | 0, 1 | Diz se a linha passa pelo Order Management (decomposição e orquestração). Licença do OM está pendente, então isso hoje é só marcação. |
| SEGMENTO | B2B, B2C | Não é tipo de produto no EPC; é elegibilidade e lista de preço. Dois valores porque são as duas jornadas do projeto. |
| CATALOGO | CAT_B2B_EVO, CAT_B2C_EVO | Vitrines que já existem no painel. Catálogo é onde o canal vê o produto; um por segmento. |
| LISTA DE PRECO | PL_B2B_EVO, PL_B2C_EVO; zona vira lista filha | Price List do EPC. Zona de preço no EPC não existe como objeto: é lista filha que herda da lista pai e sobrescreve o que muda. |
| MERCADO | MK_SUL, MK_SUDESTE, MK_CENTRO_OESTE, MK_NORDESTE, MK_NORTE; vazio = todos | Dimensão de contexto para elegibilidade regional. Códigos com prefixo MK_ como o painel já usa (exemplo Smart Authenticator: MK_SUDESTE; MK_SUL). |
| CANAL VENDA | VENDA_ASSISTIDA, ECOMMERCE, PARCEIRO; vazio = todos | Dimensão de contexto canal. Os três canais do projeto (venda assistida no CPQ, e-commerce B2C, parceiros). |
| ZONA_DISP | ZN_ do painel; vazio = nacional | Disponibilidade é regra de contexto, não lista de preço. Vazio = sem restrição, para não criar zona "todas as cidades". |
| OPCAO_VALOR_MRC, OPCAO_VALOR_NRC | número, ponto decimal | Recorrente mensal e único: são as duas variáveis de preço do EPC (charge type recurring e one-time). Ponto decimal porque o JSON e o DataPack não aceitam vírgula. |
| MOEDA | BRL | Código ISO que o EPC e o SAP usam. |
| SITUACAO_VLR | ILUSTRATIVO, VALIDADO_CORE | Princípio do template: preço ilustrativo serve para testar estrutura e não sobe para QA; validado é o da tabela vigente. |
| VIGENCIA_INICIO, VIGENCIA_FIM | AAAA-MM-DD | Formato ISO, que o EPC, o JSON e o Excel leem sem ambiguidade de dia e mês. Fim vazio = sem prazo. |
| DECIDIDO_POR, DATA_DECISAO | nome, data | A aba Decisão de Modelagem exige quem decidiu. É o que transforma proposta em decisão. |

Regra geral: código, nunca rótulo, porque o EPC casa por código e o rótulo pode mudar de idioma ou de marketing. Vazio só
significa "todos" em MERCADO, CANAL VENDA e ZONA_DISP; em qualquer outra coluna vazio é pendência.
