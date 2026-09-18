#!/usr/bin/env python3
"""Gera exemplos de preenchimento da aba "Planilha1" (48 colunas, layout Core -> Control Plane) a partir da aba
"B2C catalogo atual" de Ofertas_Atuais_migracao.xlsx. Escreve uma COPIA do arquivo com duas abas novas:
"Planilha1_exemplos" (linhas prontas, uma por opcao de componente) e "Regras_B2C_para_Planilha1" (de-para coluna a coluna).
Nao altera as abas originais. Uso: python exemplos_planilha1_b2c.py <origem.xlsx> <destino.xlsx>"""
import sys
from openpyxl import load_workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

src, dst = sys.argv[1], sys.argv[2]
wb = load_workbook(src)
CAB = [c.value for c in wb['Planilha1'][1]]  # 48 colunas, na ordem original (inclui SITUACAO_VLR duplicada)
HOJE = '2026-09-18'

def linha(**kw):
    """Monta uma linha na ordem de CAB. Chaves com espaco/ponto entram como no cabecalho."""
    base = {c: '' for c in CAB}
    base.update({'MOEDA': 'BRL', 'VIGENCIA_INICIO': HOJE, 'DECIDIDO_POR': 'Diego Beltrao', 'DATA_DECISAO': HOJE, 'SITUACAO_VLR': 'VALIDADO_CORE'})
    for k, v in kw.items():
        key = k.replace('__', ' ').replace('_dot_', '.')
        assert key in base, 'coluna inexistente: ' + key
        base[key] = v
    if base['OPCAO_VALOR_MRC'] != '': base['VALOR MENSAL'] = base['OPCAO_VALOR_MRC']
    if base['OPCAO_VALOR_NRC'] != '': base['VALOR ATIVACAO'] = base['OPCAO_VALOR_NRC']
    if base['TIPO_FISCAL'] and not base['TIPO FISCAL']: base['TIPO FISCAL'] = base['TIPO_FISCAL']
    if base['CARD MAX'] != '' and base['CARDINALIDADE'] == '': base['CARDINALIDADE'] = base['CARD MAX']
    return [base[c] for c in CAB]

def picklist(oferta, oid, servico, comp, cid, opcao, codigo, ts, fiscal, vt='', unidade='', mrc='', seg='B2C', obrig=1, **extra):
    d = dict(OFERTA_ID=oid, OFERTA=oferta, SERVICO=servico, COMPONENTE_ID=cid, COMPONENTE=comp, COMPONENTE_OPCAO=opcao,
             TIPO_FISCAL=fiscal, TIPO_SERVICO=ts, COMPONENTE_TIPO='Comercial', TIPO_ELEMENTO='ATRIBUTO_PICKLIST', CODIGO_CANONICO=codigo,
             VALOR_TECNICO=vt, UNIDADE=unidade, OPCAO_VALOR_MRC=mrc, GERA_ATIVO=0, OM=0, CARD__MIN=obrig, CARD__DEFAULT=1, CARD__MAX=1)
    d.update(segmento(seg)); d.update(extra); return linha(**d)

def filho(oferta, oid, servico, comp, cid, opcao, codigo, ts, fiscal, mrc, tipo='FILHO_FIXO', cmin=1, cdef=1, cmax=1, unidade='UN', seg='B2C', nrc='', grupo='', desc='', om=1, ativo=1, **extra):
    d = dict(OFERTA_ID=oid, OFERTA=oferta, SERVICO=servico, COMPONENTE_ID=cid, COMPONENTE=comp, COMPONENTE_OPCAO=opcao,
             TIPO_FISCAL=fiscal, TIPO_SERVICO=ts, COMPONENTE_TIPO='Comercial', TIPO_ELEMENTO=tipo, CODIGO_CANONICO=codigo,
             UNIDADE=unidade, OPCAO_VALOR_MRC=mrc, OPCAO_VALOR_NRC=nrc, GERA_ATIVO=ativo, OM=om, CARD__MIN=cmin, CARD__DEFAULT=cdef, CARD__MAX=cmax,
             GRUPO_ESCOLHA=grupo, DESC_FISCAL_SAP=desc)
    d.update(segmento(seg)); d.update(extra); return linha(**d)

def segmento(seg):
    if seg == 'B2C':
        return dict(SEGMENTO='B2C', CATALOGO='CAT_B2C_EVO', LISTA__DE__PRECO='PL_B2C_EVO', CANAL__VENDA='VENDA_ASSISTIDA, ECOMMERCE', MERCADO='', ZONA_DISP='')
    return dict(SEGMENTO='B2S', CATALOGO='CAT_B2B_EVO', LISTA__DE__PRECO='PL_B2B_EVO', CANAL__VENDA='VENDA_ASSISTIDA', MERCADO='', ZONA_DISP='')

rows = []
# ---------------------------------------------------------------- Exemplo 1: Amigo Residencial 600 Mb (B2C; nao existe no Core: ids vazios)
O, OID, SEG = 'Amigo Residencial 600 Mb', '', 'B2C'
CL = 'CLASS_INTERNET_HOME'
rows += [
    picklist(O, OID, 'Serviço de Conexão Internet Home', 'Banda', '', '600 Mbit/s', 'PV_BANDA_600M', 'SCM', 'NFCom', vt=600, unidade='MBPS', mrc=42.90, seg=SEG,
             IDENTIFICADOR_UNICO='NOVO-B2C-RES600-BANDA', CLASSE__DE__PROD=CL, DESC_FISCAL_SAP='INTERNET BANDA LARGA 600MB', OM=1,
             REGRA__PORTFOLIO='ABP por Prazo: 24m 39.90 / 36m 36.90 / 48m 33.90 (Price 02-04 menos SVAs)'),
    picklist(O, OID, 'Porta de Acesso à Rede', 'Meio de acesso', 1, 'Fibra Multiponto (GPON)', 'PV_MEIO_GPON', 'SCM', 'NFCom', seg=SEG, IDENTIFICADOR_UNICO='NOVO-B2C-RES600-MEIO', CLASSE__DE__PROD=CL),
    picklist(O, OID, 'Serviço de Conexão Internet Home', 'Perfil de Upload', '', 'Padrão', 'PV_UPLOAD_PADRAO', 'SCM', 'NFCom', seg=SEG, IDENTIFICADOR_UNICO='NOVO-B2C-RES600-UPLOAD', CLASSE__DE__PROD=CL),
    picklist(O, OID, 'Serviço de Conexão Internet Home', 'Perfil IPv4', '', 'CGNAT', 'PV_IPV4_CGNAT', 'SCM', 'NFCom', seg=SEG, IDENTIFICADOR_UNICO='NOVO-B2C-RES600-IPV4', CLASSE__DE__PROD=CL),
    picklist(O, OID, 'Serviço de Conexão Internet Home', 'Perfil IPv6', '', 'Bloco /64', 'PV_IPV6_64', 'SCM', 'NFCom', seg=SEG, IDENTIFICADOR_UNICO='NOVO-B2C-RES600-IPV6', CLASSE__DE__PROD=CL),
    picklist(O, OID, 'Serviço de Conexão Internet Home', 'Prazo de Contrato', '', '12 meses', 'PV_PRAZO_12M', 'SCM', 'NFCom', vt=12, unidade='MES', seg=SEG, IDENTIFICADOR_UNICO='NOVO-B2C-RES600-PRAZO', CLASSE__DE__PROD=CL),
    filho(O, OID, 'Locação Wifi', 'Tipo Wifi', 11, 'Roteador WI-FI 6 integrado na CPE', 'CH_CPE_WIFI6', 'Locação', 'Fatura', 0.00, seg=SEG, desc='LOCACAO ROTEADOR WIFI 6',
          IDENTIFICADOR_UNICO='NOVO-B2C-RES600-CPE', CLASSE__DE__PROD='CLASS_CPE', REGRA__PORTFOLIO='Incluso na oferta (preco dentro da banda)'),
    filho(O, OID, 'Locação Wifi', 'Extensores de Sinal', 742, 'Wi-Fi Adicional', 'CH_WIFI_ADICIONAL', 'Locação', 'Fatura', 20.00, tipo='FILHO_COM_QUANTIDADE', cmin=0, cdef=0, cmax=8, seg=SEG,
          desc='LOCACAO AP WIFI ADICIONAL', IDENTIFICADOR_UNICO='NOVO-B2C-RES600-WIFIADIC', CLASSE__DE__PROD='CLASS_CPE', REGRA__PORTFOLIO='"Nenhum" no catalogo = quantidade 0'),
    filho(O, OID, 'Aya Books', 'Pacote de Serviços Digitais', 9, 'Ebook (Básico)', 'CH_SVA_EBOOK', 'SVA', 'NFS-e', 18.90, seg=SEG, om=0, ativo=0, desc='EBOOK AYA BOOKS',
          IDENTIFICADOR_UNICO='NOVO-B2C-RES600-EBOOK', CLASSE__DE__PROD='CLASS_SVA'),
    filho(O, OID, 'Aya Books Audiolivro', 'Aya Books Audiolivro', 582, 'Audiobook (Básico)', 'CH_SVA_AUDIOBOOK', 'SVA', 'NFS-e', 13.50, seg=SEG, om=0, ativo=0, desc='AUDIOBOOK AYA BOOKS',
          IDENTIFICADOR_UNICO='NOVO-B2C-RES600-AUDIO', CLASSE__DE__PROD='CLASS_SVA'),
    filho(O, OID, 'Aya Bancah', 'Aya Bancah', 583, 'Banca (Básico)', 'CH_SVA_BANCA', 'SVA', 'NFS-e', 14.60, seg=SEG, om=0, ativo=0, desc='BANCA DIGITAL AYA',
          IDENTIFICADOR_UNICO='NOVO-B2C-RES600-BANCA', CLASSE__DE__PROD='CLASS_SVA'),
    filho(O, OID, 'Aya Books', 'Livro Educacional', '', 'Livro Educacional (Básico)', 'CH_SVA_LIVRO_EDU', 'SVA', 'NFS-e', 10.00, seg=SEG, om=0, ativo=0, desc='LIVRO EDUCACIONAL AYA',
          IDENTIFICADOR_UNICO='NOVO-B2C-RES600-LIVRO', CLASSE__DE__PROD='CLASS_SVA'),
]
# ---------------------------------------------------------------- Exemplo 2: Amigo Negócios Básico 350 Mb (B2S; oferta 383 do Core)
O, OID, SEG = 'Amigo Negócios', 383, 'B2S'
CL = 'CLASS_INTERNET_BUSINESS'
rows += [
    picklist(O, OID, 'Serviço de Conexão Internet Home e MPE', 'Banda', 3, '350 Mbit/s', 'PV_BANDA_350M', 'SCI', 'NFS-e', vt=350, unidade='MBPS', mrc=62.00, seg=SEG,
             IDENTIFICADOR_UNICO='383-?-3-? (conferir id da opcao 350 no Core)', CLASSE__DE__PROD=CL, DESC_FISCAL_SAP='INTERNET DEDICADA MPE 350MB', OM=1,
             REGRA__PORTFOLIO='B2S_NEG_0; ABP por Prazo: 24m 59.00 / 36m 56.00 / 48m 53.00'),
    picklist(O, OID, 'Porta de Acesso à Rede', 'Meio de acesso', 1, 'Fibra Multiponto (GPON)', 'PV_MEIO_GPON', 'SCM', 'NFCom', seg=SEG, CLASSE__DE__PROD=CL),
    picklist(O, OID, 'Porta de Acesso à Rede', 'Tipo de Porta', 2, 'Gigabit Ethernet (1G)', 'PV_PORTA_1G', 'SCM', 'NFCom', vt=1000, unidade='MBPS', seg=SEG, CLASSE__DE__PROD=CL),
    picklist(O, OID, 'Serviço de Conexão Internet Home e MPE', 'Perfil IPv4', '', 'CGNAT', 'PV_IPV4_CGNAT', 'SCI', 'NFS-e', seg=SEG, CLASSE__DE__PROD=CL,
             REGRA__PORTFOLIO='Avancado 500/700 = "1 fixo (/32) na WAN" (PV_IPV4_FIXO_32)'),
    picklist(O, OID, 'Pacote SVA Negócios', 'Tipo NOC', 22, 'Amigo Negócios Básico', 'PV_NOC_BASICO', 'SVA', 'NFS-e', seg=SEG, CLASSE__DE__PROD=CL),
    filho(O, OID, 'Locação Wifi', 'Tipo Wifi', 11, 'AP Wifi adicional na CPE (WI-FI 6)', 'CH_CPE_WIFI6', 'Locação', 'Fatura', 0.00, seg=SEG, desc='LOCACAO ROTEADOR WIFI 6',
          CLASSE__DE__PROD='CLASS_CPE', REGRA__PORTFOLIO='Incluso na oferta'),
    filho(O, OID, 'Locação Wifi', 'Extensores de Sinal', 742, 'AP Wifi Adicional até 35m (roteador padrão)', 'CH_WIFI_ADICIONAL', 'Locação', 'Fatura', 20.00,
          tipo='FILHO_COM_QUANTIDADE', cmin=0, cdef=0, cmax=8, seg=SEG, desc='LOCACAO AP WIFI ADICIONAL', CLASSE__DE__PROD='CLASS_CPE', REGRA__PORTFOLIO='B2S_NEG_4'),
    filho(O, OID, 'Locação Wifi', 'Extensores de Sinal', 742, 'AP Wifi Adicional até 35m com Rede Mesh (Unifi Lite)', 'CH_WIFI_MESH', 'Locação', 'Fatura', 49.90,
          tipo='FILHO_COM_QUANTIDADE', cmin=0, cdef=0, cmax=8, seg=SEG, desc='LOCACAO AP WIFI MESH', CLASSE__DE__PROD='CLASS_CPE', REGRA__PORTFOLIO='B2S_NEG_5'),
    filho(O, OID, 'Serviço de Conexão Internet Home e MPE', 'IP Válido/Fixo', '', 'IP Válido/Fixo', 'CH_IP_FIXO', 'SCM', 'NFCom', 49.90, cmin=0, cdef=0, cmax=1, seg=SEG,
          desc='ENDERECO IP FIXO', CLASSE__DE__PROD=CL, ativo=0, REGRA__PORTFOLIO='B2S_NEG_7; opcional'),
    filho(O, OID, 'Serviço de Conexão Internet Home e MPE', 'Chamado Extraordinário', '', 'Chamado Extraordinário', 'CH_CHAMADO_EXTRA', 'Serviço', 'NFS-e', '', nrc=65.00,
          cmin=0, cdef=0, cmax=1, seg=SEG, desc='VISITA TECNICA EXTRAORDINARIA', CLASSE__DE__PROD=CL, ativo=0, om=0, REGRA__PORTFOLIO='B2S_NEG_6; cobranca UNICA, por isso NRC'),
    filho(O, OID, 'Locação de Ponto de Câmeras', 'Câmera Interna', 502, '2 Câmeras + 2 cartões memória SD', 'CH_CAMERA_INT_2', 'Locação', 'Fatura', 39.90,
          tipo='FILHO_ESCOLHA', cmin=0, cdef=0, cmax=1, seg=SEG, grupo='GRP_CAMERA_INTERNA', desc='LOCACAO CAMERA INTERNA 2 PONTOS', CLASSE__DE__PROD='CLASS_CPE',
          REGRA__PORTFOLIO='B2S_NEG_9; preco por faixa (2=39.90, 3=49.90, 4=69.90...) nao e linear, por isso grupo de escolha e nao quantidade'),
    filho(O, OID, 'Locação de Ponto de Câmeras', 'Câmera Interna', 502, '3 Câmeras + 3 cartões memória SD', 'CH_CAMERA_INT_3', 'Locação', 'Fatura', 49.90,
          tipo='FILHO_ESCOLHA', cmin=0, cdef=0, cmax=1, seg=SEG, grupo='GRP_CAMERA_INTERNA', desc='LOCACAO CAMERA INTERNA 3 PONTOS', CLASSE__DE__PROD='CLASS_CPE', REGRA__PORTFOLIO='B2S_NEG_10'),
    filho(O, OID, 'Aya Books', 'Tipo de Pacote de Serviços Digitais', 9, 'Ebook (Basic)', 'CH_SVA_EBOOK', 'SVA', 'NFS-e', 18.90, seg=SEG, om=0, ativo=0, desc='EBOOK AYA BOOKS', CLASSE__DE__PROD='CLASS_SVA'),
    filho(O, OID, 'Aya Books Audiolivro', 'Aya Books Audiolivro', 582, 'Audiobook (Basic)', 'CH_SVA_AUDIOBOOK', 'SVA', 'NFS-e', 13.50, seg=SEG, om=0, ativo=0, desc='AUDIOBOOK AYA BOOKS', CLASSE__DE__PROD='CLASS_SVA'),
    filho(O, OID, 'Aya Bancah', 'Aya Bancah', 583, 'Banca (Basic)', 'CH_SVA_BANCA', 'SVA', 'NFS-e', 14.60, seg=SEG, om=0, ativo=0, desc='BANCA DIGITAL AYA', CLASSE__DE__PROD='CLASS_SVA'),
    filho(O, OID, 'Aya Books', 'Livro Educacional', '', 'Livro Educacional (Basic)', 'CH_SVA_LIVRO_EDU', 'SVA', 'NFS-e', 10.00, seg=SEG, om=0, ativo=0, desc='LIVRO EDUCACIONAL AYA', CLASSE__DE__PROD='CLASS_SVA'),
]
# ---------------------------------------------------------------- Exemplo 3: Amigo Móvel 10 GB (oferta 521 do Core)
O, OID, SEG = 'Amigo Móvel', 521, 'B2C'
rows += [
    filho(O, OID, 'Gestão de Serviços Móveis', 'Pacote recorrente (Móvel)', 462, 'Pacote 10 GB', 'CH_MOVEL_10GB', 'SVA', 'NFS-e', 35.00, tipo='FILHO_ESCOLHA', cmin=1, cdef=1, cmax=1,
          unidade='GB', seg=SEG, grupo='GRP_PACOTE_MOVEL', desc='PACOTE DADOS MOVEL 10GB', VALOR_TECNICO=10, CLASSE__DE__PROD='CLASS_MOBILE', ativo=0,
          REGRA__PORTFOLIO='MOVEL_13; ABP por Prazo: 24m 32.00 / 36m 29.00 / 48m 26.00'),
    filho(O, OID, 'Gestão de Serviços Móveis', 'Pacote recorrente (Móvel)', 462, 'Pacote 15 GB', 'CH_MOVEL_15GB', 'SVA', 'NFS-e', 40.00, tipo='FILHO_ESCOLHA', cmin=1, cdef=1, cmax=1,
          unidade='GB', seg=SEG, grupo='GRP_PACOTE_MOVEL', desc='PACOTE DADOS MOVEL 15GB', VALOR_TECNICO=15, CLASSE__DE__PROD='CLASS_MOBILE', ativo=0, REGRA__PORTFOLIO='MOVEL_14'),
    picklist(O, OID, 'Serviço SMP Prest Terc', 'Tipo de Chip', 782, 'Físico', 'PV_CHIP_FISICO', 'Locação', 'Fatura', seg=SEG, CLASSE__DE__PROD='CLASS_MOBILE', GERA_ATIVO=1,
             REGRA__PORTFOLIO='outra opcao: E-SIM (PV_CHIP_ESIM)'),
    linha(OFERTA_ID=OID, OFERTA=O, SERVICO='Serviço SMP Prest Terc', COMPONENTE_ID=463, COMPONENTE='ICCID', COMPONENTE_OPCAO='', TIPO_FISCAL='Fatura', TIPO_SERVICO='Locação',
          COMPONENTE_TIPO='Comercial', TIPO_ELEMENTO='ATRIBUTO_TEXTO', CODIGO_CANONICO='AT_ICCID', CLASSE__DE__PROD='CLASS_MOBILE', GERA_ATIVO=0, OM=1,
          CARD__MIN=0, CARD__DEFAULT=0, CARD__MAX=1, REGRA__PORTFOLIO='componente sem opcao no Core: atributo de texto preenchido na ativacao', **segmento(SEG)),
]
# ---------------------------------------------------------------- Exemplo 4: Streaming Top (oferta 1001 EVO Streaming Playhub)
O, OID, SEG = 'EVO Streaming Playhub Prime', 1001, 'B2C'
rows += [
    filho(O, OID, 'Streaming', 'Pacotes', 862, 'PlayHub Top', 'CH_STREAM_TOP', 'SVA', 'NFS-e', 10.00, tipo='FILHO_COM_QUANTIDADE', cmin=1, cdef=1, cmax=3, unidade='UN', seg=SEG,
          grupo='', desc='STREAMING PLAYHUB TOP', CLASSE__DE__PROD='CLASS_SVA', om=0, ativo=0,
          REGRA__PORTFOLIO='STREAM_31/32/33: 1 produto 10.00, 2 = 20.00, 3 = 30.00 (linear) -> quantidade 1..3 com preco unitario'),
    filho(O, OID, 'Streaming', 'Pacotes', 862, 'PlayHub Prime', 'CH_STREAM_PRIME', 'SVA', 'NFS-e', 27.00, tipo='FILHO_COM_QUANTIDADE', cmin=1, cdef=1, cmax=3, unidade='UN', seg=SEG,
          desc='STREAMING PLAYHUB PRIME', CLASSE__DE__PROD='CLASS_SVA', om=0, ativo=0, REGRA__PORTFOLIO='STREAM_34/35/36: 27 / 54 / 81 (linear)'),
    filho(O, OID, 'Streaming', 'Pacotes', 862, 'PlayHub Sky Light', 'CH_STREAM_SKY_LIGHT', 'SVA', 'NFS-e', 14.90, tipo='FILHO_ESCOLHA', cmin=0, cdef=0, cmax=1, seg=SEG,
          grupo='GRP_STREAMING_SKY', desc='STREAMING SKY+ LIGHT', CLASSE__DE__PROD='CLASS_SVA', om=0, ativo=0, REGRA__PORTFOLIO='STREAM_17; preco igual nos 4 prazos'),
]

ws = wb.create_sheet('Planilha1_exemplos')
ws.append(CAB)
for r in rows: ws.append(r)
for c in ws[1]: c.font = Font(bold=True, color='FFFFFF'); c.fill = PatternFill('solid', fgColor='1F4E79'); c.alignment = Alignment(wrap_text=True, vertical='center')
for i, c in enumerate(CAB, start=1): ws.column_dimensions[get_column_letter(i)].width = 14 if len(str(c)) < 14 else min(40, len(str(c)) + 2)
ws.column_dimensions['F'].width = 26; ws.column_dimensions['G'].width = 30; ws.column_dimensions['H'].width = 28; ws.column_dimensions['I'].width = 38; ws.column_dimensions['V'].width = 60
ws.freeze_panes = 'J2'; ws.auto_filter.ref = ws.dimensions

REGRAS = [
    ('Coluna Planilha1', 'De onde vem (B2C catalogo atual)', 'Regra / exemplo'),
    ('OFERTA_ID, SERVICO_ID, COMPONENTE_ID, COMPONENTE_OPCAO_ID', 'Core (aba OFERTAS ATUAIS)', 'Quando a oferta existe no Core, use os ids de la (Amigo Negocios = 383, Amigo Movel = 521, Playhub = 1001). Oferta so do catalogo B2C (Amigo Residencial): ids vazios e IDENTIFICADOR_UNICO = NOVO-B2C-<oferta>-<componente>.'),
    ('OFERTA', 'Name (parte comum)', '"Amigo Residencial  600 Mb" -> oferta "Amigo Residencial 600 Mb"; a banda vai para a opcao, nao para o nome.'),
    ('SERVICO / COMPONENTE / COMPONENTE_OPCAO', 'cada coluna de atributo do catalogo', 'Uma linha por atributo com valor: Banda, Meio de Acesso, Perfil de Upload, IPV4_PROFILE, Perfil IPv6, Locacao de Roteador/Wi-Fi, Wi-Fi Adicional, Pacote de Servicos Digitais, Prazo de Contrato, CPE_PROFILE. Nomes de componente iguais aos do Core (Banda = comp 3, Meio de acesso = comp 1, Tipo Wifi = 11, Extensores = 742, Tipo NOC = 22, Aya Books = 9/582/583).'),
    ('TIPO_ELEMENTO', 'natureza do atributo', 'Lista descritiva sem preco proprio -> ATRIBUTO_PICKLIST (Banda, Meio, IPv4, IPv6, Prazo). Item com preco e documento fiscal proprio -> produto filho: FILHO_FIXO (Ebook, Audiobook, Banca, Livro, roteador incluso), FILHO_COM_QUANTIDADE (Wi-Fi adicional 0..8, Streaming Top 1..3 com preco linear), FILHO_ESCOLHA em GRUPO_ESCOLHA (cameras por faixa, pacote movel).'),
    ('OPCAO_VALOR_MRC', 'Price 01 e "conectividade (Price 01)"', 'Price 01 e o preco do bundle. Decomponha: conectividade (Price 01) vai na Banda; Ebook, AUDIOBOOK, BANCA, LIVRO EDUCACIONAL vao cada um no seu filho. 42.90 + 18.90 + 13.50 + 14.60 + 10.00 = 99.90. Ponto decimal.'),
    ('Price 02, 03, 04', 'colunas Price 02-04', 'Interpretados como prazos 24, 36 e 48 meses (caem 3.00 por degrau, como a Estrutura_preco). Registrados em REGRA PORTFOLIO como ABP por Prazo ate a lista filha por prazo existir. CONFIRMAR com o Comercial se sao prazos ou zonas.'),
    ('OPCAO_VALOR_NRC', 'itens de cobranca unica', 'Chamado Extraordinario 65.00 e cobranca unica: vai em NRC, MRC vazio.'),
    ('TIPO_FISCAL / TIPO_SERVICO', 'ServiceKind + natureza', 'Conectividade B2C = SCM / NFCom; conectividade MPE (B2S) = SCI / NFS-e (como o Core 383); servicos digitais = SVA / NFS-e; roteador, AP, camera, chip = Locacao / Fatura; visita = Servico / NFS-e. E o que faz a nota sair certa.'),
    ('SEGMENTO / CATALOGO / LISTA DE PRECO', 'ProductCode (B2S_, B2C_, MOVEL_, STREAM_, CAM_)', 'B2C -> B2C / CAT_B2C_EVO / PL_B2C_EVO. B2S_NEG -> B2S / CAT_B2B_EVO / PL_B2B_EVO (B2S anda com B2B nas zonas da Estrutura_preco).'),
    ('MERCADO / CANAL VENDA / ZONA_DISP', '-', 'Vazio = todos/nacional. B2C: VENDA_ASSISTIDA, ECOMMERCE. B2S: VENDA_ASSISTIDA.'),
    ('CLASSE DE PROD', 'ServiceKind', 'INTERNET_ACCESS residencial -> CLASS_INTERNET_HOME; MPE -> CLASS_INTERNET_BUSINESS; DIGITAL_SERVICE -> CLASS_SVA; MOBILE -> CLASS_MOBILE; equipamentos -> CLASS_CPE. Proposta: confirmar no painel.'),
    ('CODIGO_CANONICO', 'gerado', 'PV_ para valor de picklist, CH_ para produto filho, AT_ para atributo, GRP_ para grupo. So letras, numeros e sublinhado, ate 40.'),
    ('VALOR_TECNICO / UNIDADE', 'DOWNLOAD_SPEED, Prazo, GB', 'Banda 600 Mb -> 600 / MBPS; Prazo 12 -> 12 / MES; Movel 10 GB -> 10 / GB. Produto filho sem medida -> UN.'),
    ('CARD MIN / DEFAULT / MAX', 'obrigatoriedade', 'Atributo obrigatorio 1/1/1. Filho incluso 1/1/1. Opcional 0/0/1. Com quantidade 0/0/8 (Wi-Fi adicional) ou 1/1/3 (Streaming Top). "Nenhum" no catalogo = min 0.'),
    ('GERA_ATIVO / OM', 'natureza', 'Equipamento e chip geram ativo (1) e passam pelo OM (1). Banda passa pelo OM (provisionamento) mas nao gera ativo. SVA: 0 / 0.'),
    ('DESC_FISCAL_SAP / COD. SAP', 'texto da nota', 'Descricao curta em caixa alta por produto. COD. SAP fica vazio ate o Fiscal informar o material.'),
    ('SITUACAO_VLR / MOEDA / VIGENCIA', 'fixos', 'VALIDADO_CORE quando o preco vem da tabela vigente (esta aba); BRL; VIGENCIA_INICIO = data da carga, fim vazio.'),
    ('DECIDIDO_POR / DATA_DECISAO', 'quem validou', 'Sem isso a linha e proposta, nao decisao.'),
    ('Linhas que NAO viram produto', 'Amigo Negocios 1 Camera 0 (sem preco); Fone Fixo Controle duplicado (FONE_0 e FONE_5)', 'Pendencias: preco faltando e duplicidade; nao carregar ate resolver.'),
]
wr = wb.create_sheet('Regras_B2C_para_Planilha1')
for r in REGRAS: wr.append(list(r))
for c in wr[1]: c.font = Font(bold=True, color='FFFFFF'); c.fill = PatternFill('solid', fgColor='1F4E79')
wr.column_dimensions['A'].width = 42; wr.column_dimensions['B'].width = 40; wr.column_dimensions['C'].width = 120
for row in wr.iter_rows(min_row=2):
    for c in row: c.alignment = Alignment(wrap_text=True, vertical='top')
wb.save(dst)
print('ok', dst, len(rows), 'linhas de exemplo,', len(CAB), 'colunas')
