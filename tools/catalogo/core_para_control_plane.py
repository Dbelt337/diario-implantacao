#!/usr/bin/env python3
"""Converte a planilha do Customer Core (Ofertas_Atuais_migracao.xlsx, aba OFERTAS ATUAIS) no pacote que o Catalog
Control Plane lê: xlsx (LEIA-ME, OFERTAS, COMPONENTES, OPCOES, DICIONARIO), JSON aninhado (oferta > serviço >
componente > opção) e CSV plano. Normaliza ids, gera GlobalKey e código canônico, propõe a decisão de modelagem por
componente (atributo picklist, booleano, filho com quantidade, filho de escolha, filho fixo) com grau de confiança, e
marca o que o Core não traz (preço, SAP, catálogo, lista, segmento, canal, zona, vigência).
Uso: python core_para_control_plane.py Ofertas_Atuais_migracao.xlsx [--saida saida]
Não grava nada na org. Reaproveita o leitor/escritor de xlsx de tools/lead_load."""
import argparse, collections, csv, datetime, json, os, re, sys, unicodedata, zipfile
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lead_load'))
from gerar_template_leads import STYLES, c_str, sheet_xml  # noqa: E402
from xml.sax.saxutils import escape as esc  # noqa: E402

# ---------- leitura (shared strings + inline) ----------
def ler_aba(path, nome_aba):
    z = zipfile.ZipFile(path)
    ss = []
    if 'xl/sharedStrings.xml' in z.namelist():
        import html
        ss = [html.unescape(''.join(re.findall(r'<t[^>]*>(.*?)</t>', si, re.S))) for si in re.findall(r'<si>(.*?)</si>', z.read('xl/sharedStrings.xml').decode(), re.S)]
    wb = z.read('xl/workbook.xml').decode()
    rels = dict(re.findall(r'Id="(rId\d+)"[^>]*Target="([^"]+)"', z.read('xl/_rels/workbook.xml.rels').decode()))
    alvo = None
    for nm, rid in re.findall(r'<sheet [^>]*name="([^"]+)"[^>]*r:id="(rId\d+)"', wb):
        if nm.strip().lower() == nome_aba.lower():
            alvo = rels[rid]
    if not alvo:
        sys.exit('aba "%s" nao encontrada' % nome_aba)
    x = z.read('xl/' + alvo.replace('xl/', '').lstrip('/')).decode()
    def val(c):
        t = re.search(r' t="([^"]+)"', c); v = re.search(r'<v>(.*?)</v>', c, re.S); isv = re.search(r'<is>(.*?)</is>', c, re.S)
        if isv: return ''.join(re.findall(r'<t[^>]*>(.*?)</t>', isv.group(1), re.S))
        if not v: return ''
        return ss[int(v.group(1))] if t and t.group(1) == 's' else v.group(1)
    rows = []
    for r in re.findall(r'<row[^>]*>(.*?)</row>', x, re.S):
        d = {}
        for c in re.findall(r'(<c [^>]*?(?:/>|>.*?</c>))', r, re.S):
            ref = re.search(r'r="([A-Z]+)\d+"', c).group(1); v = val(c)
            if v != '': d[ref] = v
        if d: rows.append(d)
    hdr = rows[0]
    return [{hdr[k]: v for k, v in r.items() if k in hdr} for r in rows[1:]]

# ---------- normalizacao ----------
def inteiro(s):
    s = (s or '').strip()
    if not s: return ''
    try: return str(int(float(s)))
    except ValueError: return s

def num(s):
    s = (s or '').strip()
    if s in ('', '-'): return ''
    try:
        f = float(s); return str(int(f)) if f == int(f) else str(f)
    except ValueError: return s

def slug(s, n=40):
    s = unicodedata.normalize('NFKD', s or '').encode('ascii', 'ignore').decode().upper()
    s = re.sub(r'[^A-Z0-9]+', '_', s).strip('_')
    return s[:n].rstrip('_')

def limpa(s):
    return re.sub(r'\s+', ' ', (s or '')).strip()

CLASSE = {'SCI': 'Conectividade', 'SCM': 'Conectividade', 'STFC': 'Voz', 'SVA': 'Servicos de Valor Agregado', 'TI': 'TI e Cloud',
          'Locação': 'Wi-Fi e Dispositivos', 'Locacao': 'Wi-Fi e Dispositivos', 'Imobilizado': 'Wi-Fi e Dispositivos',
          'Serviço': 'Servicos', 'Servico': 'Servicos', 'Engenharia': 'Servicos'}

RE_SKU = re.compile(r'\(SKU-|\bLic \d+M\b', re.I)
RE_QTD = re.compile(r'^(\d+)\s+(.+)$')
RE_UNID = re.compile(r'^\d+([.,]\d+)?\s*(bit/s|mbit|gbit|kbit|mbps|gbps|g|t|gb|tb|w|u|vcpu|fxs|ramais|canais|caixas?|hosts?|licen)', re.I)

def decidir(nome_comp, opcoes, tipo_comp):
    """Retorna (decisao, confianca, motivo) para um componente a partir das opcoes dele."""
    ops = [limpa(o) for o in opcoes if limpa(o)]
    low = [o.lower() for o in ops]
    n = len(ops)
    if n == 0:
        return 'SEM_OPCAO', 'BAIXA', 'componente sem opcao (linha sem COMPONENTE_OPCAO_ID)'
    if tipo_comp == 'Ativação':
        return 'ATRIBUTO_BOOLEANO', 'ALTA', 'componente de ativacao (cobranca unica), Sim/Nao'
    if set(low) <= {'sim', 'não', 'nao'}:
        return 'ATRIBUTO_BOOLEANO', 'ALTA', 'opcoes Sim/Nao'
    if n == 1:
        return 'FILHO_FIXO', 'MEDIA', 'uma opcao so: produto filho fixo (ou atributo com valor unico)'
    if sum(1 for o in ops if RE_SKU.search(o)) >= n * 0.6:
        return 'FILHO_ESCOLHA', 'ALTA', 'opcoes com SKU/prazo de licenca: cada opcao e um produto vendavel'
    qtd = [RE_QTD.match(o) for o in ops if o.lower() != 'nenhum']
    if qtd and all(qtd):
        sufixos = {re.sub(r'(es|s)$', '', m.group(2).lower()) for m in qtd}
        if len(sufixos) <= 2 and not any(RE_UNID.match(o) for o in ops):
            return 'FILHO_COM_QUANTIDADE', 'ALTA', 'opcoes "N <item>": produto filho com quantidade %s..%s' % (0 if 'nenhum' in low else 1, max(int(m.group(1)) for m in qtd))
    conf = 'ALTA' if n <= 40 else 'MEDIA'
    if n > 100:
        conf = 'BAIXA'
    descritivas = n <= 10 and not any(re.search(r'\d', o) or o.lower() in ('nenhum', 'sim', 'não', 'nao') for o in ops) and sum(len(o.split()) for o in ops) / n >= 3
    if descritivas:
        return 'ATRIBUTO_PICKLIST', 'MEDIA', 'opcoes descritivas (%d): picklist, mas podem ser produtos filhos em grupo de escolha se tiverem preco proprio' % n
    return 'ATRIBUTO_PICKLIST', conf, 'lista de valores (%d); %s' % (n, 'conferir se sao modelos vendaveis (virariam filhos)' if n > 40 else 'picklist')

# ---------- processamento ----------
def processar(rows):
    for r in rows:
        for k in ('OFERTA_ID', 'SERVICO_ID', 'COMPONENTE_ID', 'COMPONENTE_OPCAO_ID', 'COMPONENTE_OBRIGATORIO', 'COMPONENTE_IGNORAR', 'OPCAO_VIABILIDADE', 'OPCAO_PESO'):
            r[k] = inteiro(r.get(k, ''))
        for k in ('OFERTA', 'SERVICO', 'COMPONENTE', 'COMPONENTE_OPCAO', 'TIPO_FISCAL', 'TIPO_SERVICO', 'COMPONENTE_TIPO', 'COMPONENTE_VIABILIDADE'):
            r[k] = limpa(r.get(k, ''))
        r['VALOR_TECNICO'] = num(r.get('OPCAO_VALOR', ''))
    # decisao por componente (nome + conjunto de opcoes e o mesmo em todas as ofertas; decidimos por nome)
    por_comp = collections.defaultdict(lambda: {'opcoes': [], 'tipo': collections.Counter(), 'ofertas': set()})
    for r in rows:
        c = por_comp[r['COMPONENTE']]
        if r['COMPONENTE_OPCAO'] and r['COMPONENTE_OPCAO'] not in c['opcoes']:
            c['opcoes'].append(r['COMPONENTE_OPCAO'])
        c['tipo'][r['COMPONENTE_TIPO']] += 1; c['ofertas'].add(r['OFERTA_ID'])
    decisoes = {}
    for nome, c in por_comp.items():
        d, conf, mot = decidir(nome, c['opcoes'], c['tipo'].most_common(1)[0][0])
        decisoes[nome] = dict(decisao=d, confianca=conf, motivo=mot, n_opcoes=len(c['opcoes']), n_ofertas=len(c['ofertas']),
                              exemplos='; '.join(c['opcoes'][:6]), tem_nenhum=any(o.lower() == 'nenhum' for o in c['opcoes']))
    # linhas de saida
    saida = []
    for r in rows:
        d = decisoes[r['COMPONENTE']]
        dec = d['decisao']
        obrig = r['COMPONENTE_OBRIGATORIO'] == '1'
        nenhum = r['COMPONENTE_OPCAO'].lower() == 'nenhum'
        elemento = 'VALOR_PICKLIST' if dec in ('ATRIBUTO_PICKLIST', 'ATRIBUTO_BOOLEANO') else ('QUANTIDADE_DO_FILHO' if dec == 'FILHO_COM_QUANTIDADE' else 'PRODUTO_FILHO')
        pref_comp = 'AT_' if dec.startswith('ATRIBUTO') else 'CH_'
        pref_op = 'PV_' if elemento == 'VALOR_PICKLIST' else 'CH_'
        qmin = '0' if (not obrig or d['tem_nenhum']) else '1'
        qmax = '1'; quantidade = ''
        if dec == 'FILHO_COM_QUANTIDADE':
            m = RE_QTD.match(r['COMPONENTE_OPCAO'])
            qmax = m.group(1) if m else '1'; quantidade = m.group(1) if m else ('0' if nenhum else '')
        pend = []
        if not r['COMPONENTE_OPCAO_ID']: pend.append('sem COMPONENTE_OPCAO_ID')
        if r['OPCAO_VIABILIDADE'] == '1': pend.append('opcao depende de viabilidade')
        if d['confianca'] == 'BAIXA': pend.append('decisao de modelagem a confirmar')
        if r['COMPONENTE_TIPO'] == 'Ativação': pend.append('cobranca unica: informar NRC')
        o = collections.OrderedDict()
        o['ACAO'] = 'IGNORAR' if r['COMPONENTE_IGNORAR'] == '1' else 'CRIAR'
        o['OFERTA_ID'] = r['OFERTA_ID']; o['OFERTA'] = r['OFERTA']
        o['OFERTA_CODIGO'] = 'OF_' + slug(r['OFERTA']); o['OFERTA_GLOBALKEY'] = 'BTP-OF-' + r['OFERTA_ID']
        o['SERVICO_ID'] = r['SERVICO_ID']; o['SERVICO'] = r['SERVICO']; o['SERVICO_VIRA'] = 'AGRUPAMENTO (nao vira produto)'
        o['COMPONENTE_ID'] = r['COMPONENTE_ID']; o['COMPONENTE'] = r['COMPONENTE']
        o['COMPONENTE_CODIGO'] = pref_comp + slug(r['COMPONENTE']); o['COMPONENTE_GLOBALKEY'] = 'BTP-CO-' + r['COMPONENTE_ID']
        o['COMPONENTE_TIPO'] = r['COMPONENTE_TIPO']; o['DECISAO_PROPOSTA'] = dec; o['CONFIANCA'] = d['confianca']; o['MOTIVO_DECISAO'] = d['motivo']
        o['TIPO_ELEMENTO'] = elemento
        o['COMPONENTE_OPCAO_ID'] = r['COMPONENTE_OPCAO_ID']; o['COMPONENTE_OPCAO'] = r['COMPONENTE_OPCAO']
        o['OPCAO_CODIGO'] = '' if elemento == 'QUANTIDADE_DO_FILHO' else ((pref_op + slug(r['COMPONENTE_OPCAO'])) if r['COMPONENTE_OPCAO'] else '')
        o['QUANTIDADE'] = quantidade
        o['OPCAO_GLOBALKEY'] = ('BTP-OP-' + r['COMPONENTE_OPCAO_ID']) if r['COMPONENTE_OPCAO_ID'] else ''
        o['IDENTIFICADOR_UNICO'] = r.get('IDENTIFICADOR_UNICO', '')
        o['VALOR_TECNICO'] = r['VALOR_TECNICO']; o['SEQUENCIA'] = r['OPCAO_PESO']
        o['OBRIGATORIO'] = '1' if obrig else '0'; o['QTD_MIN'] = qmin; o['QTD_PADRAO'] = '0' if nenhum else qmin; o['QTD_MAX'] = qmax
        o['GRUPO_ESCOLHA'] = ('GRP_' + slug(r['COMPONENTE'], 30)) if dec == 'FILHO_ESCOLHA' else ''
        o['VIABILIDADE'] = r['OPCAO_VIABILIDADE'] or '0'
        o['TIPO_COBRANCA'] = 'UNICA' if r['COMPONENTE_TIPO'] == 'Ativação' else 'RECORRENTE'
        o['TIPO_SERVICO'] = r['TIPO_SERVICO']; o['CLASSE_PROPOSTA'] = CLASSE.get(r['TIPO_SERVICO'], r['TIPO_SERVICO'])
        o['TIPO_FISCAL'] = r['TIPO_FISCAL']
        for k in ('PRECO_MRC', 'PRECO_NRC', 'LISTA_PRECO', 'MOEDA', 'SITUACAO_VALOR', 'COD_SAP', 'DESC_FISCAL', 'SEGMENTO', 'CATALOGO', 'MERCADO',
                  'CANAL_VENDA', 'ZONA_DISP', 'VIGENCIA_INICIO', 'VIGENCIA_FIM', 'GERA_ATIVO', 'CFS', 'RFS', 'RECURSO', 'DECIDIDO_POR', 'DATA_DECISAO'):
            o[k] = 'BRL' if k == 'MOEDA' else ''
        o['PENDENCIAS'] = '; '.join(pend)
        saida.append(o)
    return saida, decisoes

def resumo_ofertas(saida):
    of = collections.OrderedDict()
    for o in saida:
        k = o['OFERTA_ID']
        if k not in of:
            of[k] = dict(OFERTA_ID=k, OFERTA=o['OFERTA'], OFERTA_CODIGO=o['OFERTA_CODIGO'], OFERTA_GLOBALKEY=o['OFERTA_GLOBALKEY'],
                         CAMADA='Oferta', SUBTIPO='Bundle', servicos=set(), componentes=set(), opcoes=0, atributos=set(), filhos=set(),
                         tipo_serv=collections.Counter(), fiscal=collections.Counter(), ignorados=set(), viab=0, baixa=set())
        x = of[k]
        x['servicos'].add(o['SERVICO_ID']); x['componentes'].add(o['COMPONENTE_ID']); x['opcoes'] += 1
        (x['atributos'] if o['TIPO_ELEMENTO'] == 'VALOR_PICKLIST' else x['filhos']).add(o['COMPONENTE'])
        x['tipo_serv'][o['TIPO_SERVICO']] += 1; x['fiscal'][o['TIPO_FISCAL']] += 1
        if o['ACAO'] == 'IGNORAR': x['ignorados'].add(o['COMPONENTE'])
        if o['VIABILIDADE'] == '1': x['viab'] += 1
        if o['CONFIANCA'] == 'BAIXA': x['baixa'].add(o['COMPONENTE'])
    linhas = []
    for x in of.values():
        ts = x['tipo_serv'].most_common(1)[0][0]
        linhas.append(collections.OrderedDict([
            ('OFERTA_ID', x['OFERTA_ID']), ('OFERTA', x['OFERTA']), ('OFERTA_CODIGO', x['OFERTA_CODIGO']), ('OFERTA_GLOBALKEY', x['OFERTA_GLOBALKEY']),
            ('CAMADA', 'Oferta'), ('SUBTIPO', 'Bundle'), ('CLASSE_PROPOSTA', CLASSE.get(ts, ts)), ('TIPO_SERVICO_PREDOMINANTE', ts),
            ('TIPO_FISCAL_PREDOMINANTE', x['fiscal'].most_common(1)[0][0]), ('N_SERVICOS', len(x['servicos'])), ('N_COMPONENTES', len(x['componentes'])),
            ('N_OPCOES', x['opcoes']), ('N_ATRIBUTOS', len(x['atributos'])), ('N_FILHOS', len(x['filhos'])), ('COMPONENTES_IGNORADOS', len(x['ignorados'])),
            ('OPCOES_COM_VIABILIDADE', x['viab']), ('COMPONENTES_A_CONFIRMAR', '; '.join(sorted(x['baixa']))),
            ('CATALOGO', ''), ('LISTA_PRECO', ''), ('SEGMENTO', ''), ('CANAL_VENDA', ''), ('ZONA_DISP', ''), ('VIGENCIA_INICIO', ''), ('VIGENCIA_FIM', ''),
            ('PENDENCIAS', 'preco, SAP, catalogo, lista, segmento, canal, zona e vigencia nao vem do Core')]))
    return linhas

# ---------- escrita ----------
def tabela(linhas, cabec=None, largura=18):
    cab = cabec or list(linhas[0].keys())
    rows = [(1, [c_str(f'{colx(i)}1', h, 1) for i, h in enumerate(cab, 1)])]
    for n, l in enumerate(linhas, 2):
        rows.append((n, [c_str(f'{colx(i)}{n}', l.get(h, ''), 4) for i, h in enumerate(cab, 1)]))
    w = [(i, min(60, max(10, len(h) + 2)) if h not in ('OFERTA', 'COMPONENTE', 'COMPONENTE_OPCAO', 'MOTIVO_DECISAO', 'EXEMPLOS', 'PENDENCIAS') else 40) for i, h in enumerate(cab, 1)]
    return sheet_xml(rows, cols_w=w, freeze=True, autofilter=f'A1:{colx(len(cab))}{len(linhas) + 1}')

def colx(n):
    s = ''
    while n: n, r = divmod(n - 1, 26); s = chr(65 + r) + s
    return s

def texto(linhas):
    rows = [(i, [c_str(f'A{i}', t, 7 if i == 1 else (9 if t.startswith('##') else 8))]) for i, t in enumerate(linhas, 1)]
    return sheet_xml(rows, cols_w=[(1, 150)])

def write_xlsx(path, abas):
    ct = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          + ''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(1, len(abas) + 1)) + '</Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
    wb = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
          + ''.join(f'<sheet name="{esc(n)}" sheetId="{i}" r:id="rId{i}"/>' for i, (n, _) in enumerate(abas, 1)) + '</sheets></workbook>')
    wbrels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
              + ''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>' for i in range(1, len(abas) + 1))
              + f'<Relationship Id="rId{len(abas) + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct); z.writestr('_rels/.rels', rels); z.writestr('xl/workbook.xml', wb)
        z.writestr('xl/_rels/workbook.xml.rels', wbrels); z.writestr('xl/styles.xml', STYLES)
        for i, (_, xml) in enumerate(abas, 1):
            z.writestr(f'xl/worksheets/sheet{i}.xml', xml)

DICIONARIO = [
    ('ACAO', 'CRIAR ou IGNORAR (COMPONENTE_IGNORAR = 1 do Core). Descontinuar/Atualizar nao existem no Core; o painel decide.'),
    ('OFERTA_ID / OFERTA', 'Id e nome da oferta no Core. A oferta vira Product2 camada Oferta, subtipo Bundle.'),
    ('OFERTA_CODIGO', 'Codigo canonico proposto: OF_ + nome. Pode ser trocado uma vez, antes de publicar; depois e imutavel.'),
    ('OFERTA_GLOBALKEY', 'BTP-OF-<OFERTA_ID>. Identidade entre ambientes (DataPack). Nunca gerada pela org.'),
    ('SERVICO_ID / SERVICO', 'Agrupamento do Core. Nao vira produto; serve de secao na tela e de grupo de escolha quando houver.'),
    ('COMPONENTE_ID / COMPONENTE', 'Componente do Core. Vira atributo (AT_) ou produto filho (CH_) conforme DECISAO_PROPOSTA.'),
    ('COMPONENTE_GLOBALKEY', 'BTP-CO-<COMPONENTE_ID>.'),
    ('COMPONENTE_TIPO', 'Comercial (recorrente) ou Ativacao (cobranca unica), como vem do Core.'),
    ('DECISAO_PROPOSTA', 'ATRIBUTO_PICKLIST: atributo com lista de valores. ATRIBUTO_BOOLEANO: Sim/Nao. FILHO_COM_QUANTIDADE: produto filho com quantidade (opcoes "N item"). FILHO_ESCOLHA: cada opcao e um produto vendavel (SKU), em grupo de escolha. FILHO_FIXO: uma opcao so. SEM_OPCAO: linha sem opcao no Core.'),
    ('CONFIANCA / MOTIVO_DECISAO', 'ALTA, MEDIA ou BAIXA e a regra usada. BAIXA = alguem de Produtos confirma na Decisao de Modelagem.'),
    ('TIPO_ELEMENTO', 'VALOR_PICKLIST (a opcao vira PicklistValue), PRODUTO_FILHO (a opcao vira Product2 filho; em FILHO_FIXO o componente e o produto e a opcao e o seu nome completo) ou QUANTIDADE_DO_FILHO (a opcao e so a quantidade do produto filho = componente; ver QUANTIDADE).'),
    ('QUANTIDADE', 'So em FILHO_COM_QUANTIDADE: o N da opcao ("3 Extensores" = 3; "Nenhum" = 0). A opcao nao vira registro; vira a cardinalidade do filho.'),
    ('COMPONENTE_OPCAO_ID / COMPONENTE_OPCAO', 'Opcao do Core. OPCAO_CODIGO = PV_ (valor) ou CH_ (filho) + nome. OPCAO_GLOBALKEY = BTP-OP-<id>.'),
    ('IDENTIFICADOR_UNICO', 'Chave composta do Core, guardada como Origem no Core. Nao e usada como chave no EPC.'),
    ('VALOR_TECNICO', 'E o OPCAO_VALOR do Core. NAO E PRECO: e o valor tecnico da opcao (ex.: Banda 1 Gbit/s = 1000). Vai para o atributo tecnico.'),
    ('SEQUENCIA', 'OPCAO_PESO do Core: ordem na tela.'),
    ('OBRIGATORIO / QTD_MIN / QTD_PADRAO / QTD_MAX', 'Cardinalidade proposta: obrigatorio -> min 1; opcao "Nenhum" -> min 0; FILHO_COM_QUANTIDADE -> max = maior N.'),
    ('GRUPO_ESCOLHA', 'Preenchido so em FILHO_ESCOLHA: GRP_<componente>.'),
    ('VIABILIDADE', 'OPCAO_VIABILIDADE do Core. 1 = a opcao depende de analise de viabilidade (vai para Elegibilidade/Decomposicao).'),
    ('TIPO_COBRANCA', 'UNICA (componente de Ativacao) ou RECORRENTE. Confirmar por opcao quando houver NRC.'),
    ('TIPO_SERVICO / CLASSE_PROPOSTA', 'SCI, SCM, STFC, SVA, TI, Locacao, Imobilizado, Servico, Engenharia -> classe (Object Type) proposta.'),
    ('TIPO_FISCAL', 'NFS-e, Fatura ou NFCom, como vem do Core. Vai para Produtos.Documento fiscal.'),
    ('PRECO_MRC / PRECO_NRC / LISTA_PRECO / MOEDA / SITUACAO_VALOR', 'NAO VEM DO CORE. Preencher a partir da tabela de precos vigente. SITUACAO_VALOR = ILUSTRATIVO ou VALIDADO_CORE.'),
    ('COD_SAP / DESC_FISCAL', 'NAO VEM DO CORE. Obrigatorios por produto comercial (handoff fiscal).'),
    ('SEGMENTO / CATALOGO / MERCADO / CANAL_VENDA / ZONA_DISP', 'NAO VEM DO CORE. Vazio = todos / nacional; o painel nao deve criar zona ou canal por ausencia.'),
    ('VIGENCIA_INICIO / VIGENCIA_FIM / GERA_ATIVO', 'NAO VEM DO CORE. Preencher no painel.'),
    ('CFS / RFS / RECURSO', 'Camada tecnica, opcional nesta fase (Decomposicao Tecnica).'),
    ('DECIDIDO_POR / DATA_DECISAO', 'Governanca da Decisao de Modelagem: quem confirmou a DECISAO_PROPOSTA.'),
    ('PENDENCIAS', 'Pendencias especificas da linha (sem id de opcao, viabilidade, decisao a confirmar, NRC de ativacao).'),
]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('xlsx'); ap.add_argument('--aba', default='OFERTAS ATUAIS')
    ap.add_argument('--saida', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida'))
    a = ap.parse_args()
    os.makedirs(a.saida, exist_ok=True)
    rows = ler_aba(a.xlsx, a.aba)
    saida, decisoes = processar(rows)
    ofertas = resumo_ofertas(saida)
    comps = [collections.OrderedDict([('COMPONENTE', n), ('DECISAO_PROPOSTA', d['decisao']), ('CONFIANCA', d['confianca']), ('N_OPCOES', d['n_opcoes']),
                                      ('N_OFERTAS', d['n_ofertas']), ('TEM_NENHUM', '1' if d['tem_nenhum'] else '0'), ('EXEMPLOS', d['exemplos']), ('MOTIVO', d['motivo']),
                                      ('DECISAO_FINAL', ''), ('DECIDIDO_POR', ''), ('DATA_DECISAO', '')])
             for n, d in sorted(decisoes.items(), key=lambda kv: (kv[1]['confianca'] != 'BAIXA', -kv[1]['n_ofertas']))]
    hoje = datetime.date.today().isoformat()
    cont = collections.Counter(d['decisao'] for d in decisoes.values())
    conf = collections.Counter(d['confianca'] for d in decisoes.values())
    leia = [
        'Customer Core -> Catalog Control Plane: pacote de importacao (gerado em %s)' % hoje,
        'Fonte: %s, aba %s. %d linhas (opcoes), %d ofertas, %d servicos, %d componentes, %d opcoes distintas.' % (
            os.path.basename(a.xlsx), a.aba, len(saida), len(ofertas), len({o['SERVICO_ID'] for o in saida}), len(decisoes), len({o['COMPONENTE_OPCAO_ID'] for o in saida if o['COMPONENTE_OPCAO_ID']})),
        '',
        '## Como ler',
        'Uma linha da aba OPCOES = uma opcao de componente do Core (o nivel mais baixo). Oferta > Servico > Componente > Opcao.',
        'A aba OFERTAS resume as %d ofertas (uma linha cada, e o que vira Product2 camada Oferta / Bundle).' % len(ofertas),
        'A aba COMPONENTES traz a decisao de modelagem proposta por componente (%d), ordenada com as de confianca BAIXA primeiro: %s.' % (
            len(decisoes), ', '.join('%s %d' % kv for kv in conf.most_common())),
        'Decisoes propostas: ' + ', '.join('%s %d' % kv for kv in cont.most_common()) + '.',
        'A aba DICIONARIO explica cada coluna.',
        '',
        '## O que o Core traz e o que NAO traz',
        'Traz: ids, nomes, hierarquia, obrigatorio, ignorar, viabilidade, ordem, tipo fiscal, tipo de servico, tipo do componente (comercial/ativacao), valor tecnico da opcao.',
        'NAO traz (colunas vazias para o painel preencher): preco recorrente e unico, lista de preco, situacao do valor, codigo SAP, descricao fiscal, segmento, catalogo, mercado, canal, zona, vigencia, gera ativo, camada tecnica.',
        'ATENCAO: OPCAO_VALOR do Core NAO e preco. E o valor tecnico (Banda 1 Gbit/s = 1000; Tipo de Prazo Normal = 1). Esta em VALOR_TECNICO. Preco vem de outra tabela.',
        '',
        '## Regras aplicadas',
        '1. Ids normalizados para inteiro. GlobalKey deterministica: BTP-OF-<oferta>, BTP-CO-<componente>, BTP-OP-<opcao>.',
        '2. Codigo canonico proposto por nome (OF_, AT_, CH_, PV_), sem acento, maiusculo, ate 40 caracteres. Definido uma vez; depois nao muda.',
        '3. Servico do Core nao vira produto (agrupamento).',
        '4. Decisao de modelagem por componente pelas opcoes: Sim/Nao = booleano; "N item" = filho com quantidade; SKU/Lic = filhos em grupo de escolha; 1 opcao = filho fixo; resto = picklist. Listas com mais de 100 valores ficam com confianca BAIXA (podem ser modelos vendaveis).',
        '5. Cardinalidade: obrigatorio -> min 1; opcao "Nenhum" no componente -> min 0; filho com quantidade -> max = maior N.',
        '6. COMPONENTE_IGNORAR = 1 -> ACAO = IGNORAR (%d linhas). Componente de Ativacao -> cobranca UNICA (%d linhas).' % (
            sum(1 for o in saida if o['ACAO'] == 'IGNORAR'), sum(1 for o in saida if o['TIPO_COBRANCA'] == 'UNICA')),
        '7. Linhas sem COMPONENTE_OPCAO_ID (%d) ficam marcadas em PENDENCIAS; opcoes com viabilidade = 1 (%d) idem.' % (
            sum(1 for o in saida if not o['COMPONENTE_OPCAO_ID']), sum(1 for o in saida if o['VIABILIDADE'] == '1')),
        '',
        '## Arquivos do pacote',
        'core_control_plane.xlsx (este), core_control_plane.json (oferta > servico > componente > opcao, com as mesmas chaves) e core_control_plane_opcoes.csv (aba OPCOES, UTF-8, separador ;).',
        'O painel deve ler o JSON; o xlsx e para as pessoas revisarem a Decisao de Modelagem (aba COMPONENTES, colunas DECISAO_FINAL, DECIDIDO_POR, DATA_DECISAO).',
    ]
    dic = [collections.OrderedDict([('COLUNA', k), ('SIGNIFICADO', v)]) for k, v in DICIONARIO]
    abas = [('LEIA-ME', texto(leia)), ('OFERTAS', tabela(ofertas)), ('COMPONENTES', tabela(comps)), ('OPCOES', tabela(saida)), ('DICIONARIO', tabela(dic))]
    write_xlsx(os.path.join(a.saida, 'core_control_plane.xlsx'), abas)
    with open(os.path.join(a.saida, 'core_control_plane_opcoes.csv'), 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=list(saida[0].keys()), delimiter=';'); w.writeheader(); w.writerows(saida)
    # JSON aninhado
    ofs = collections.OrderedDict()
    for o in saida:
        of = ofs.setdefault(o['OFERTA_ID'], collections.OrderedDict(id=o['OFERTA_ID'], nome=o['OFERTA'], codigo=o['OFERTA_CODIGO'], globalkey=o['OFERTA_GLOBALKEY'],
                                                                     camada='Oferta', subtipo='Bundle', servicos=collections.OrderedDict()))
        sv = of['servicos'].setdefault(o['SERVICO_ID'], collections.OrderedDict(id=o['SERVICO_ID'], nome=o['SERVICO'], vira='agrupamento', componentes=collections.OrderedDict()))
        cp = sv['componentes'].setdefault(o['COMPONENTE_ID'], collections.OrderedDict(
            id=o['COMPONENTE_ID'], nome=o['COMPONENTE'], codigo=o['COMPONENTE_CODIGO'], globalkey=o['COMPONENTE_GLOBALKEY'], acao=o['ACAO'],
            tipo_core=o['COMPONENTE_TIPO'], decisao_proposta=o['DECISAO_PROPOSTA'], confianca=o['CONFIANCA'], motivo=o['MOTIVO_DECISAO'],
            tipo_elemento=o['TIPO_ELEMENTO'], obrigatorio=o['OBRIGATORIO'] == '1', qtd_min=int(o['QTD_MIN']), qtd_max=None, grupo_escolha=o['GRUPO_ESCOLHA'] or None,
            tipo_cobranca=o['TIPO_COBRANCA'], tipo_servico=o['TIPO_SERVICO'], classe_proposta=o['CLASSE_PROPOSTA'], tipo_fiscal=o['TIPO_FISCAL'],
            a_preencher=dict(preco_mrc=None, preco_nrc=None, lista_preco=None, cod_sap=None, desc_fiscal=None, gera_ativo=None, cfs=None, rfs=None, recurso=None),
            decidido_por=None, data_decisao=None, opcoes=[]))
        cp['qtd_max'] = max(cp['qtd_max'] or 0, int(o['QTD_MAX']))
        cp['opcoes'].append(collections.OrderedDict(id=o['COMPONENTE_OPCAO_ID'] or None, nome=o['COMPONENTE_OPCAO'], codigo=o['OPCAO_CODIGO'] or None,
                                                    globalkey=o['OPCAO_GLOBALKEY'] or None, identificador_unico=o['IDENTIFICADOR_UNICO'], valor_tecnico=o['VALOR_TECNICO'] or None,
                                                    sequencia=int(o['SEQUENCIA']) if o['SEQUENCIA'] else None, viabilidade=o['VIABILIDADE'] == '1',
                                                    pendencias=o['PENDENCIAS'] or None))
    def lista(d):
        for of in d.values():
            of['servicos'] = list(of['servicos'].values())
            for sv in of['servicos']:
                sv['componentes'] = list(sv['componentes'].values())
        return list(d.values())
    pacote = collections.OrderedDict(
        gerado_em=hoje, fonte=os.path.basename(a.xlsx), versao_layout='1.0',
        regras=leia[leia.index('## Regras aplicadas') + 1: leia.index('')] if False else [l for l in leia if re.match(r'^\d\. ', l)],
        nao_vem_do_core=['preco_mrc', 'preco_nrc', 'lista_preco', 'situacao_valor', 'cod_sap', 'desc_fiscal', 'segmento', 'catalogo', 'mercado', 'canal_venda', 'zona_disp', 'vigencia', 'gera_ativo', 'cfs', 'rfs', 'recurso'],
        totais=dict(ofertas=len(ofs), linhas=len(saida), componentes=len(decisoes), decisoes=dict(cont), confianca=dict(conf)),
        ofertas=lista(ofs))
    with open(os.path.join(a.saida, 'core_control_plane.json'), 'w', encoding='utf-8') as f:
        json.dump(pacote, f, ensure_ascii=False, indent=1)
    print('\n'.join(leia))
    print('\nCOMPONENTES com confianca BAIXA:'); [print('  ', c['COMPONENTE'], '|', c['N_OPCOES'], 'opcoes |', c['EXEMPLOS'][:70]) for c in comps if c['CONFIANCA'] == 'BAIXA']

if __name__ == '__main__':
    main()
