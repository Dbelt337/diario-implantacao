#!/usr/bin/env python3
"""Preenche a aba "Planilha1" de Ofertas_Atuais_migracao.xlsx no formato das linhas do Sky TV (uma linha por produto
vendavel, 48 colunas), a partir da aba "B2C catalogo atual". Grava uma COPIA do arquivo; as outras abas nao mudam.
Uso: python planilha1_de_b2c.py <origem.xlsx> <destino.xlsx>"""
import re, sys, unicodedata
from openpyxl import load_workbook
from openpyxl.styles import Font, PatternFill

src, dst = sys.argv[1], sys.argv[2]
wb = load_workbook(src)
for extra in ('Planilha1_exemplos', 'Regras_B2C_para_Planilha1'):
    if extra in wb.sheetnames: del wb[extra]
p1 = wb['Planilha1']
CAB = [c.value for c in p1[1]]
HOJE, FIM = '2026-09-18', '2031-09-18'

def slug(s, n=30):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().upper()
    return re.sub(r'_+', '_', re.sub(r'[^A-Z0-9]+', '_', s)).strip('_')[:n]

def limpa(s):
    return re.sub(r'\s+', ' ', str(s or '').replace('\n', ' ')).strip()

# regras por tipo de produto: (OFERTA, SERVICO, COMPONENTE, tipo fiscal, tipo servico, classe, gera ativo, OM, unidade, oferta_id_core)
def classificar(code, name, kind, cpe):
    n = limpa(name); code = code or ''
    if kind == 'INTERNET_ACCESS':
        if code.startswith('B2S_NEG') and not re.search(r'\d+ ?Mb', n):
            # add-ons do Amigo Negocios (AP wifi, chamado, IP fixo, cameras)
            comp = 'Câmeras' if 'Câmera' in n else ('Wi-Fi adicional' if 'Wifi' in n else ('IP fixo' if 'IP' in n else 'Serviço avulso'))
            ts, tf = ('Locação', 'Fatura') if comp in ('Câmeras', 'Wi-Fi adicional') else (('SCM', 'NFCom') if comp == 'IP fixo' else ('Serviço', 'NFS-e'))
            opcao = re.sub(r'^Amigo Negócios\s*', '', n); opcao = re.sub(r'\s*\d+(\.\d+)?$', '', opcao)
            return dict(OFERTA='Amigo Negócios', SERVICO='Amigo Negócios', COMPONENTE=comp, OPCAO=opcao, TF=tf, TS=ts, CL='CLASS_CPE' if ts == 'Locação' else 'CLASS_INTERNET_BUSINESS',
                        ATIVO=1 if ts == 'Locação' else 0, OM=1, UN='UN', OID=383, SEG='B2S', ELEM='FILHO_FIXO', CMIN=0, CDEF=0, CMAX=8 if comp in ('Câmeras', 'Wi-Fi adicional') else 1, VT='')
        m = re.search(r'(\d+)\s*(Mb|Mbps|GB)', n)
        vt = int(m.group(1)) * (1000 if m and m.group(2) == 'GB' else 1) if m else ''
        if code.startswith('B2S_NEG'):
            fam = 'Amigo Negócios'; plano = ('Avançado ' if 'Avançado' in n else 'Básico ') + (m.group(0) if m else '')
            return dict(OFERTA=fam, SERVICO=fam, COMPONENTE='Plano', OPCAO=plano.strip(), TF='NFS-e', TS='SCI', CL='CLASS_INTERNET_BUSINESS', ATIVO=0, OM=1, UN='MBPS', OID=383, SEG='B2S', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT=vt)
        fam = 'Amigo Retenção' if 'Retenção' in n else 'Amigo Residencial'
        return dict(OFERTA=fam, SERVICO=fam, COMPONENTE='Velocidade', OPCAO=(m.group(0) if m else n), TF='NFCom', TS='SCM', CL='CLASS_INTERNET_HOME', ATIVO=0, OM=1, UN='MBPS', OID='', SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT=vt)
    if kind == 'MOBILE':
        m = re.search(r'(\d+)\s*GB', n)
        return dict(OFERTA='Amigo Móvel', SERVICO='Amigo Móvel', COMPONENTE='Franquia de dados', OPCAO=m.group(0) if m else n, TF='NFS-e', TS='SVA', CL='CLASS_MOBILE', ATIVO=1, OM=1, UN='GB', OID=521, SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT=int(m.group(1)) if m else '')
    if kind == 'VOICE':
        return dict(OFERTA='Fone Fixo', SERVICO='Fone Fixo', COMPONENTE='Plano', OPCAO=re.sub(r'^Fone Fixo\s*', '', n), TF='NFCom', TS='STFC', CL='CLASS_VOICE', ATIVO=1, OM=1, UN='UN', OID='', SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT='')
    if kind == 'DIGITAL_SERVICE':
        if code.startswith('CAM'):
            m = re.search(r'(\d+)\s*Câmeras?', n); dias = '30' if code.endswith('30D') else '7'
            return dict(OFERTA='Amigo Câmera', SERVICO='Amigo Câmera', COMPONENTE='Armazenamento nuvem %s dias' % dias, OPCAO=m.group(0) if m else n, TF='Fatura', TS='TI', CL='CLASS_CPE', ATIVO=1, OM=1, UN='UN', OID=541, SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT=int(m.group(1)) if m else '')
        m = re.match(r'Streaming\s+(Top|Prime|Avançado|Sky\+|Globoplay|CeletiHub)\s*(.*)', n)
        if m:
            fam = 'Streaming ' + m.group(1); oid = 1001 if m.group(1) in ('Top', 'Prime', 'Avançado') else (1002 if m.group(1) == 'Sky+' else '')
            return dict(OFERTA=fam, SERVICO=fam, COMPONENTE='Pacote', OPCAO=m.group(2) or m.group(1), TF='NFS-e', TS='SVA', CL='CLASS_SVA', ATIVO=0, OM=0, UN='UN', OID=oid, SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT='')
        return dict(OFERTA=n, SERVICO=n, COMPONENTE='Tipo', OPCAO=n, TF='NFS-e', TS='SVA', CL='CLASS_SVA', ATIVO=0, OM=0, UN='UN', OID='', SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT='')
    return dict(OFERTA=n, SERVICO=n, COMPONENTE='Tipo', OPCAO=n, TF='', TS='', CL='', ATIVO=0, OM=0, UN='UN', OID='', SEG='B2C', ELEM='ATRIBUTO_PICKLIST', CMIN=1, CDEF=1, CMAX=1, VT='')

ws = load_workbook(src, data_only=True)['B2C catalogo atual']  # valores calculados, nao formulas
rows = list(ws.iter_rows(values_only=True)); hdr = [str(h) if h else '' for h in rows[0]]
ix = {h: i for i, h in enumerate(hdr)}
def val(r, h):
    v = r[ix[h]] if h in ix and ix[h] < len(r) else None
    return '' if v in (None, '') else v

n_out = 0; seq = 0
for r in rows[1:]:
    if not any(v not in (None, '') for v in r): continue
    code, name, kind, cpe = val(r, 'ProductCode'), limpa(val(r, 'Name')), val(r, 'ServiceKind'), val(r, 'CPE_PROFILE')
    if not name: continue
    seq += 1
    c = classificar(code, name, kind, cpe)
    p1_, p2, p3, p4 = (val(r, 'Price 01'), val(r, 'Price 02'), val(r, 'Price 03'), val(r, 'Price 04'))
    mrc = float(p1_) if p1_ != '' else ''
    ident = code or ('B2C_%s_%d' % (slug(c['OFERTA'], 12), seq))
    codigo = ('PV_' if c['ELEM'] == 'ATRIBUTO_PICKLIST' else 'CH_') + slug(c['OFERTA'][:14] + '_' + c['OPCAO'], 34)
    regra = ('24m %s / 36m %s / 48m %s' % (p2, p3, p4)) if p2 != '' else ''
    linha = {k: '' for k in CAB}
    linha.update({
        'OFERTA_ID': c['OID'], 'SERVICO_ID': '', 'COMPONENTE_ID': '', 'COMPONENTE_OPCAO_ID': '', 'IDENTIFICADOR_UNICO': ident,
        'OFERTA': c['OFERTA'], 'SERVICO': c['SERVICO'], 'COMPONENTE': c['COMPONENTE'], 'COMPONENTE_OPCAO': c['OPCAO'],
        'TIPO_FISCAL': c['TF'], 'OPCAO_VALOR_MRC': mrc, 'OPCAO_VALOR_NRC': '', 'COD. SAP': '',
        'SEGMENTO': c['SEG'], 'CATALOGO': 'CAT_B2B_EVO' if c['SEG'] == 'B2S' else 'CAT_B2C_EVO', 'MERCADO': '',
        'CANAL VENDA': 'VENDA_ASSISTIDA' if c['SEG'] == 'B2S' else 'VENDA_ASSISTIDA, ECOMMERCE', 'ZONA_DISP': '',
        'CLASSE DE PROD': c['CL'], 'MOEDA': 'BRL', 'LISTA DE PRECO': 'PL_B2B_EVO' if c['SEG'] == 'B2S' else 'PL_B2C_EVO',
        'REGRA PORTFOLIO': regra, 'SITUACAO_VLR': 'VALIDADO_CORE' if mrc != '' else 'PENDENTE', 'DESC_FISCAL_SAP': slug(name, 40).replace('_', ' '),
        'VIGENCIA_INICIO': HOJE, 'VIGENCIA_FIM': FIM, 'GERA_ATIVO': c['ATIVO'], 'VALOR MENSAL': mrc, 'VALOR ATIVACAO': '', 'OM': c['OM'],
        'LAYOUT FISCAL': '', 'TIPO FISCAL': c['TF'], 'CARDINALIDADE': c['CMAX'], 'CARD MIN': c['CMIN'], 'CARD MAX': c['CMAX'], 'CARD DEFAULT': c['CDEF'],
        'VALOR MINIMO MENSAL': '', 'VALOR MINIMO INSTALACAO': '', 'VALOR_TECNICO': c['VT'], 'TIPO_ELEMENTO': c['ELEM'], 'CODIGO_CANONICO': codigo,
        'COMPONENTE_TIPO': 'Comercial', 'TIPO_SERVICO': c['TS'], 'GRUPO_ESCOLHA': '', 'UNIDADE': c['UN'], 'DECIDIDO_POR': 'Diego Beltrao', 'DATA_DECISAO': HOJE,
    })
    # SITUACAO_VLR aparece duas vezes no cabecalho: preenche as duas
    out = []
    for k in CAB: out.append(linha[k])
    p1.append(out); n_out += 1
for c in p1[1]: c.font = Font(bold=True, color='FFFFFF'); c.fill = PatternFill('solid', fgColor='1F4E79')
p1.freeze_panes = 'J2'; p1.auto_filter.ref = p1.dimensions
wb.save(dst)
print('ok', dst, n_out, 'linhas acrescentadas na Planilha1 (abaixo das 2 do Sky TV)')
