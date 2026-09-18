# 18/09/2026 - Exemplos de preenchimento da Planilha1 (Core -> Control Plane) com o catalogo B2C atual

Pedido do Diego: exemplos de como preencher a aba "Planilha1" (48 colunas) de Ofertas_Atuais_migracao (1).xlsx usando a aba
"B2C catalogo atual" (67 produtos: Amigo Residencial, Amigo Negocios, Retencao, Movel, Fone Fixo, Streaming, Cameras).

Entregue: docs/Ofertas_Atuais_migracao_exemplos_Planilha1.xlsx, copia do arquivo com duas abas novas: **Planilha1_exemplos**
(35 linhas, 4 ofertas, uma linha por opcao de componente) e **Regras_B2C_para_Planilha1** (de-para coluna a coluna). Gerador:
tools/catalogo/exemplos_planilha1_b2c.py. As abas originais nao mudaram.

## Os 4 exemplos e o que cada um ensina

1. **Amigo Residencial 600 Mb** (B2C, nao existe no Core: ids vazios, IDENTIFICADOR_UNICO = NOVO-B2C-RES600-...). 12 linhas:
   6 atributos picklist (Banda 600 com VALOR_TECNICO 600 MBPS, Meio GPON, Upload, IPv4 CGNAT, IPv6 /64, Prazo 12 meses),
   roteador Wi-Fi 6 como filho fixo incluso (MRC 0 com REGRA PORTFOLIO "incluso"), Wi-Fi adicional como filho com quantidade
   0..8 a 20.00, e os 4 servicos digitais como filhos fixos com preco e nota propria. **O preco 99.90 do catalogo se decompoe:
   42.90 (conectividade, na Banda, SCM/NFCom) + 18.90 Ebook + 13.50 Audiobook + 14.60 Banca + 10.00 Livro (SVA/NFS-e)**.
   E a decomposicao por documento fiscal que o EPC precisa.
2. **Amigo Negocios Basico 350 Mb** (B2S, oferta 383 do Core, componentes com os ids do Core: Banda 3, Meio 1, Porta 2, Tipo
   Wifi 11, Extensores 742, Tipo NOC 22, Aya 9/582/583, Camera interna 502). Mostra: conectividade MPE como SCI/NFS-e (igual
   ao Core), add-ons opcionais (IP fixo 49.90, CARD 0/0/1), cobranca unica (Chamado Extraordinario 65.00 em NRC), cameras por
   faixa como grupo de escolha (2 cameras 39.90, 3 cameras 49.90: preco nao linear), Wi-Fi mesh 49.90 com quantidade.
3. **Amigo Movel 10 GB** (oferta 521): pacotes como filhos em grupo de escolha (10 GB 35.00, 15 GB 40.00, VALOR_TECNICO em GB),
   Tipo de Chip picklist, ICCID como atributo de texto (componente sem opcao no Core).
4. **Streaming Playhub** (oferta 1001): "Top 1/2/3 Produtos" a 10/20/30 e linear, entao vira filho com quantidade 1..3 a 10.00
   por unidade; Sky Light vira filho em grupo de escolha com preco igual nos 4 prazos.

## Premissas que precisam de confirmacao

- **Price 01 a 04** foram lidos como prazos de 12, 24, 36 e 48 meses (caem 3.00 por degrau, como a Estrutura_preco). Ate a
  lista filha por prazo existir, os outros tres precos ficam em REGRA PORTFOLIO ("ABP por Prazo"). Se forem zonas a/b/c/d, muda
  a coluna: ZONA_DISP e lista filha por zona.
- **CLASSE DE PROD** (CLASS_INTERNET_HOME, CLASS_INTERNET_BUSINESS, CLASS_SVA, CLASS_MOBILE, CLASS_CPE) e proposta; confirmar
  no painel do presidente.
- **COD. SAP** ficou vazio em todas: depende do Fiscal.
- Segmento B2S usa catalogo e lista B2B (CAT_B2B_EVO, PL_B2B_EVO), como a Estrutura_preco agrupa B2B;B2S.
- Duas linhas do catalogo nao viram produto ate resolver: "Amigo Negocios 1 Camera" sem preco e "Fone Fixo Controle" duplicado
  (FONE_0 e FONE_5).
