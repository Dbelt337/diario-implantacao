# 18/09/2026 - Planilha1 (Core -> Control Plane) preenchida a partir do catalogo B2C atual

Pedido do Diego: a aba "Planilha1" de Ofertas_Atuais_migracao (1).xlsx preenchida no formato das duas linhas do Sky TV (uma
linha por produto vendavel, 48 colunas), com os dados vindos da aba "B2C catalogo atual". Uma primeira versao com decomposicao
por componente (Ebook, Audiobook etc. como filhos) foi descartada: nao era o que ele queria.

Entregue: docs/Ofertas_Atuais_migracao_Planilha1_preenchida.xlsx, copia do arquivo com a Planilha1 preenchida: as 2 linhas do
Sky TV mantidas e 67 linhas novas, uma por produto do catalogo B2C (67 produtos: 3 Amigo Residencial, 4 planos + 12 add-ons Amigo
Negocios, 2 Retencao, 5 Movel, 6 Fone Fixo, 19 Streaming, 16 Camera). Gerador: tools/catalogo/planilha1_de_b2c.py (reexecutavel).

## Como cada coluna foi preenchida

| Coluna | Regra |
|---|---|
| OFERTA_ID | id do Core quando a oferta existe la: Amigo Negocios 383, Amigo Movel 521, Amigo Camera 541, Playhub Top/Prime/Avancado 1001, Sky+ 1002. Residencial, Retencao, Fone, Globoplay e CeletiHub: vazio (nao estao no Core). SERVICO_ID, COMPONENTE_ID e COMPONENTE_OPCAO_ID vazios (opcoes novas). |
| IDENTIFICADOR_UNICO | ProductCode do catalogo (B2S_NEG_0, MOVEL_13, STREAM_31, CAM_0_7D...); onde nao ha codigo, B2C_<oferta>_<n>. |
| OFERTA / SERVICO | familia do produto: Amigo Residencial, Amigo Negocios, Amigo Retencao, Amigo Movel, Fone Fixo, Streaming Top / Prime / Avancado / Sky+ / Globoplay / CeletiHub, Amigo Camera. |
| COMPONENTE / COMPONENTE_OPCAO | Velocidade (600 Mb, 700 Mb, 1 GB), Plano (Basico 350 Mb, Controle, Prime I), Franquia de dados (10 GB), Pacote (1 Produto, Light Urbano), Armazenamento nuvem 7 ou 30 dias (N Cameras, como os componentes 504/505 do Core), e nos add-ons do Amigo Negocios: Wi-Fi adicional, IP fixo, Servico avulso, Cameras. |
| TIPO_FISCAL / TIPO_SERVICO | Internet residencial NFCom/SCM; Internet MPE NFS-e/SCI (como a oferta 383 do Core); Movel NFS-e/SVA (como a 521); Fone NFCom/STFC; Streaming NFS-e/SVA; Camera e Wi-Fi Fatura/Locacao ou TI; Chamado NFS-e/Servico; IP fixo NFCom/SCM. |
| OPCAO_VALOR_MRC = VALOR MENSAL | Price 01 (preco do produto). Price 02, 03 e 04 registrados em REGRA PORTFOLIO como "24m / 36m / 48m" (premissa: sao prazos; confirmar). |
| SEGMENTO / CATALOGO / LISTA DE PRECO / CANAL VENDA | B2C: B2C / CAT_B2C_EVO / PL_B2C_EVO / VENDA_ASSISTIDA, ECOMMERCE. B2S_NEG: B2S / CAT_B2B_EVO / PL_B2B_EVO / VENDA_ASSISTIDA. MERCADO e ZONA_DISP vazios = todos. |
| CLASSE DE PROD | CLASS_INTERNET_HOME, CLASS_INTERNET_BUSINESS, CLASS_MOBILE, CLASS_VOICE, CLASS_SVA, CLASS_CPE (propostas, no padrao CLASS_TV do exemplo). |
| SITUACAO_VLR | VALIDADO_CORE (preco da tabela vigente); PENDENTE na unica linha sem preco (Amigo Negocios 1 Camera). |
| DESC_FISCAL_SAP | nome do produto em caixa alta sem acento. COD. SAP vazio (Fiscal). |
| VIGENCIA | 2026-09-18 a 2031-09-18, como o exemplo. MOEDA BRL. |
| GERA_ATIVO / OM | 1/1 em movel, fone, camera e equipamentos; 0/1 em internet (provisiona, nao gera ativo); 0/0 em streaming. |
| CARD MIN/DEFAULT/MAX | 1/1/1 nos planos; 0/0/1 nos add-ons opcionais; 0/0/8 em Wi-Fi adicional e cameras do Negocios. CARDINALIDADE = MAX. |
| VALOR_TECNICO / UNIDADE | velocidade em MBPS (1 GB = 1000), franquia em GB, cameras = quantidade; demais UN. |
| TIPO_ELEMENTO / CODIGO_CANONICO | ATRIBUTO_PICKLIST com PV_<oferta>_<opcao> nos planos (como PV_LITE do exemplo); FILHO_FIXO com CH_ nos add-ons. COMPONENTE_TIPO Comercial. |
| DECIDIDO_POR / DATA_DECISAO | Diego Beltrao, 2026-09-18. |

## Pendencias que ficaram na planilha

- Fone Fixo Controle aparece duas vezes no catalogo (FONE_0 e FONE_5): as duas linhas entraram; apagar uma.
- Amigo Negocios 1 Camera sem preco (SITUACAO_VLR = PENDENTE).
- Price 02 a 04 como prazos 24/36/48 e premissa; se forem zonas, muda para ZONA_DISP e lista filha.
- COD. SAP em branco em todas.
