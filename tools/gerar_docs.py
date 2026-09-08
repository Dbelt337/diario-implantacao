#!/usr/bin/env python3
"""Gera os .docx de requisitos (um por work) a partir do works.json do script 13, usando um .docx
existente como modelo de visual (capa, cabecalho, rodape, estilos). Ordem fixa: capa, tabela de
metadados, corpo, Criterios de Aceite (related list; se nao houver, os do corpo), Notas de Refinamento.
Uso: gerar_docs.py works.json modelo.docx saida/ "dd/mm/aaaa hh:mm da extracao" [pacote.zip]"""
import sys, os, re, json, zipfile, unicodedata, datetime
from xml.sax.saxutils import escape

works = json.load(open(sys.argv[1], encoding='utf-8'))
modelo = zipfile.ZipFile(sys.argv[2])
out = sys.argv[3]; os.makedirs(out, exist_ok=True)
fonte = sys.argv[4]
zip_out = sys.argv[5] if len(sys.argv) > 5 else None
agora = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-3)))
GERADO = f"{agora.strftime('%d/%m/%Y %H:%M')} (BRT), a partir da extração integral do Agile Accelerator de {fonte}: campos, Details, related list Acceptance Criteria e notas de refinamento"

tpl = modelo.read('word/document.xml').decode('utf-8')
head = tpl.split('<w:body>')[0] + '<w:body>'
body_tpl = tpl.split('<w:body>')[1]
capa = body_tpl[:body_tpl.find('<w:p><w:pPr><w:spacing w:after="100"/>')]      # paragrafo com os logos + espacador
sect = body_tpl[body_tpl.rfind('<w:sectPr'):]                                     # sectPr + fechamento
HR = '<w:p><w:pPr><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr></w:pPr><w:r><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr><w:pict><v:rect id="_x0000_i1037" style="width:0;height:1.5pt" o:hralign="center" o:hrstd="t" o:hr="t" fillcolor="#a0a0a0" stroked="f"/></w:pict></w:r></w:p>'

def t(s): return escape(re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', s).replace('\t', ' '))
def run(txt, b=False, i=False, color=None, sz=24):
    rpr = ('<w:b/><w:bCs/>' if b else '') + ('<w:i/><w:iCs/>' if i else '') + (f'<w:color w:val="{color}"/>' if color else '') + f'<w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/>'
    return f'<w:r><w:rPr>{rpr}</w:rPr><w:t xml:space="preserve">{t(txt)}</w:t></w:r>'
def p(runs, ppr=''):
    return f'<w:p><w:pPr>{ppr}<w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr></w:pPr>{runs}</w:p>'
def para(txt, **k): return p(run(txt, **k))
def lead(l, rest):  # "ROTULO: texto"
    return p(run(l + ' ', b=True) + run(rest))
def h1(txt): return p(run(txt, b=True), '<w:keepNext/><w:spacing w:before="240" w:after="80"/>')
def h2(txt): return p(run(txt, b=True, i=True), '<w:keepNext/><w:spacing w:before="200" w:after="60"/>')
def bullet(runs, num=1, lvl=0): return p(runs, f'<w:numPr><w:ilvl w:val="{lvl}"/><w:numId w:val="{num}"/></w:numPr>')
def center(txt, **k): return p(run(txt, **k), '<w:jc w:val="center"/>')
def cell(txt, w, fill=None, b=False):
    shd = f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>' if fill else ''
    sp = '<w:spacing w:before="40" w:after="40"/>'
    return f'<w:tc><w:tcPr><w:tcW w:w="{w}" w:type="dxa"/>{shd}</w:tcPr>{p(run(txt, b=b, sz=20), sp)}</w:tc>'
def tabela(rows):
    x = '<w:tbl><w:tblPr><w:tblW w:w="8504" w:type="dxa"/><w:tblBorders>' + ''.join(f'<w:{s} w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>' for s in ['top','left','bottom','right','insideH','insideV']) + '</w:tblBorders><w:tblLook w:val="04A0"/></w:tblPr><w:tblGrid><w:gridCol w:w="2400"/><w:gridCol w:w="6104"/></w:tblGrid>'
    for k, v in rows: x += '<w:tr>' + cell(k, 2400, 'EEF3FA', True) + cell(v, 6104) + '</w:tr>'
    return x + '</w:tbl>'

TITULOS = {'NARRATIVA': 'Descrição', 'NARRATIVA DE NEGÓCIO': 'Descrição', 'DESCRIÇÃO': 'Descrição', 'ESCOPO': 'Escopo',
    'CONTEXTO E CENÁRIO DE NEGÓCIO': 'Contexto e Cenário de Negócio', 'CENÁRIO E CONTEXTO DE NEGÓCIO': 'Cenário e Contexto de Negócio',
    'REGRAS DE NEGÓCIO': 'Regras de Negócio Associadas', 'REGRAS DE NEGÓCIO ASSOCIADAS': 'Regras de Negócio Associadas',
    'ESPECIFICAÇÃO TÉCNICA': 'Especificação Técnica (Salesforce)', 'ESPECIFICAÇÃO TÉCNICA (SALESFORCE)': 'Especificação Técnica (Salesforce)',
    'DEPENDÊNCIAS E RISCOS': 'Dependências, Riscos e Estimativa', 'DEPENDENCIAS': 'Dependências, Riscos e Estimativa', 'DEPENDÊNCIAS': 'Dependências, Riscos e Estimativa',
    'DEPENDÊNCIAS, RISCOS E ESTIMATIVA': 'Dependências, Riscos e Estimativa', 'CRITÉRIOS DE ACEITE': 'Critérios de Aceite', 'CRITERIOS DE ACEITE': 'Critérios de Aceite',
    'PRINCIPIO CENTRAL': 'Princípio central', 'DEFINITION OF DONE (DOD) & MASSA DE TESTES': 'Definition of Done (DoD) e Massa de Testes',
    'RISCO & VIABILIDADE': 'Risco e Viabilidade'}
CONHECIDOS = {'descrição', 'cenário e contexto de negócio', 'contexto e cenário de negócio', 'regras de negócio associadas', 'regras de negócio', 'regras', 'escopo', 'escopo técnico',
    'especificação técnica (salesforce)', 'especificação técnica', 'critérios de aceite', 'critérios de aceite (formato gherkin)', 'dependências, riscos e estimativa',
    'contexto e regras de negócio (telecom)', 'definition of done (dod) & massa de testes', 'definition of done (dod) e massa de testes', 'notas de refinamento', 'contexto e cenário',
    'estimativa, dependências e governor limits'}
SUBTITULOS = {'automação / lógica', 'integração / apis', 'automação / front-end', 'integração / apis tm forum', 'regras', 'escopo técnico'}
def norm(s): return re.sub(r'\s+', ' ', s.strip().rstrip(':')).upper()
def sem_parens(s): return re.sub(r'\s*\([^)]*\)', '', s).strip()
def is_heading(l):
    s = l.strip()
    if len(s) < 3 or len(s) > 80 or s.endswith('.'): return False
    s2 = re.sub(r'^\d+\.\s*', '', s).rstrip(':')
    if s2.lower() in CONHECIDOS or s2.lower() in SUBTITULOS or re.match(r'(?i)^acceptance criteria \(\d+ registros?\)$', s2): return True
    s3 = sem_parens(s2)
    return bool(re.fullmatch(r"[A-ZÀ-Ú0-9][A-ZÀ-Ú0-9 \-/&,.º'’]*", s3)) and bool(re.search(r'[A-ZÀ-Ú]{3}', s3))
def is_criterios(l):
    s2 = re.sub(r'^\d+\.\s*', '', l.strip()).rstrip(':').lower()
    return s2.startswith(('critérios de aceite', 'criterios de aceite', 'acceptance criteria'))
def titulo_de(l):
    s2 = re.sub(r'^\d+\.\s*', '', l.strip()).rstrip(':')
    if s2.lower() in CONHECIDOS or s2.lower() in SUBTITULOS: return TITULOS.get(norm(s2), s2[0].upper() + s2[1:])
    base = TITULOS.get(norm(sem_parens(s2)))
    if base: return base + (' ' + re.search(r'\(.*\)', s2).group(0) if '(' in s2 else '')
    return s2[0] + s2[1:].lower()

def juntar_linhas(txt):
    """reune linhas quebradas no meio da frase (quebra seguida de letra minuscula)"""
    out = []
    MARCA = re.compile(r"^(?:[-•*☐]\s|\[ \]\s|Como\s|Quero\s|Eu quero\s|Para que\s|Dado\s|Quando\s|Então\s|Entao\s|RN-\d|Crit[ée]rio\s|Cen[áa]rio\s|\d+\.\s|[A-ZÀ-Ú][A-Za-zÀ-ú0-9 /&\-]{1,40}:\s|Narrativa:|Fonte:|Referência:|P-\d\d)")
    txt = txt.replace('\r\n', '\n').strip()
    if txt.startswith('"') and txt.endswith('"'): txt = txt[1:-1]
    for l in txt.split('\n'):
        prev = out[-1].strip() if out else ''
        cont = bool(prev) and bool(l.strip()) and not is_heading(prev) and not re.search(r'[.:;!?)"»]$', prev) and not MARCA.match(l.strip()) and not is_heading(l)
        if cont or (out and l and l[0].islower() and prev and not re.match(r'^(-|•|\*|☐|\d+\.)\s', prev)):
            out[-1] = out[-1].rstrip() + ' ' + l.strip()
        else: out.append(l)
    return out

def dqe_runs(txt):
    """quebra 'Dado ..., quando ..., então ...' em sub-itens; devolve lista de xml"""
    parts = re.split(r'(?i)(?:;\s*|,\s*)(?=(?:quando|então|entao)\s)', txt.strip())
    if len(parts) < 2: return [bullet(run(txt.strip()), 3, 1)]
    xs = []
    for pt in parts:
        m = re.match(r'(?i)^(dado|quando|então|entao)\s+(.*)$', pt.strip())
        if m: xs.append(bullet(run(m.group(1).capitalize().replace('Entao', 'Então') + ' ', b=True) + run(m.group(2)), 3, 1))
        else: xs.append(bullet(run(pt.strip()), 3, 1))
    return xs

def criterio_xml(titulo, corpo):
    xs = [p(run(titulo, b=True), '<w:keepNext/><w:spacing w:before="120" w:after="40"/>')]
    linhas = [l.strip() for l in corpo.replace('\r\n', '\n').split('\n') if l.strip()]
    if len(linhas) == 1: xs += dqe_runs(linhas[0])
    else:
        for l in linhas:
            m = re.match(r'(?i)^(dado|quando|então|entao)\s+(.*)$', l)
            xs.append(bullet(run(m.group(1).capitalize().replace('Entao', 'Então') + ' ', b=True) + run(m.group(2)), 3, 1) if m else bullet(run(l), 3, 1))
    return xs

def render_ac(acs):
    def chave(ac):
        m = re.search(r'\d+', ac.get('Name', '')) or re.search(r'\d+', ac.get('Description', '')[:40])
        return int(m.group()) if m else 99
    xs = [h1('Critérios de Aceite')]
    for i, ac in enumerate(sorted(acs, key=chave), 1):
        nome, desc = ac.get('Name', '').strip(), ac.get('Description', '').strip()
        desc = re.sub(r'^[•\-\s]+', '', desc)
        if nome.isdigit():                       # importado: "Critério 2: Titulo\nDado..." ou "Titulo — Dado...; Quando...; Então..."
            first, _, rest = desc.partition('\n')
            if ' — ' in first and not rest: first, _, rest = first.partition(' — ')
            titulo = re.sub(r'^Crit[ée]rio\s*\d+\s*:\s*', '', first).strip(); desc = rest
            titulo = f'Critério {i}: {titulo}' if titulo else f'Critério {i}'
        elif re.match(r'^\d+\.\s', desc):        # migrado do corpo (formato numerado)
            titulo = f'Critério {i}'; desc = re.sub(r'^\d+\.\s*', '', desc)
        elif ' — ' in desc and not desc.lower().startswith('dado'):   # "Titulo — Dado...; Quando...; Então..."
            first, _, rest = desc.partition(' — '); titulo = f'Critério {i}: {first.strip()}'; desc = rest
        else:
            titulo = nome if nome.lower().startswith(('cen', 'crit')) else f'Critério {i}: {nome}'
            desc = re.sub(r'^' + re.escape(nome) + r'\.?\s*', '', desc)   # migrado: "Cenário 1: Titulo. Dado..."
        xs += criterio_xml(titulo, desc)
    return xs

def render_corpo(linhas, tem_ac):
    xs, intro, i, n = [], True, 0, len(linhas)
    while i < n:
        l = linhas[i].rstrip(); s = l.strip(); i += 1
        if not s: continue
        if is_heading(s):
            if is_criterios(s) and tem_ac:                    # pula a secao do corpo: a related list e a fonte
                while i < n and not is_heading(linhas[i]): i += 1
                continue
            tit = titulo_de(s)
            xs.append(p(run(tit, b=True), '<w:keepNext/><w:spacing w:before="120" w:after="40"/>') if s.rstrip(':').lower() in SUBTITULOS else h1(tit)); intro = False; continue
        m = re.match(r'^(?:Narrativa:\s*)?Como\s+(.+?),\s*(?:eu\s+)?quero\s+(.+?),\s*(para\s+(?:que\s+)?)(.+)$', s, re.I | re.S)
        if m:
            xs += [h1('Descrição') if not xs or 'Descrição' not in xs[-1] else '', bullet(run('Como ', b=True) + run(m.group(1))), bullet(run('Quero ', b=True) + run(m.group(2))), bullet(run(m.group(3).strip().capitalize() + ' ', b=True) + run(m.group(4))), HR]; intro = False; continue
        m = re.match(r'^(Como|Eu quero|Quero|Para que)\s+(.*)$', s)
        if m and m.group(1) == 'Como' and i < n and re.match(r'^(Eu quero|Quero)\s', linhas[i].strip()):
            if not xs or 'Descrição' not in xs[-1]: xs.append(h1('Descrição'))
            xs.append(bullet(run('Como ', b=True) + run(m.group(2))))
            while i < n and re.match(r'^(Eu quero|Quero|Para que)\s+(.*)$', linhas[i].strip()):
                mm = re.match(r'^(Eu quero|Quero|Para que)\s+(.*)$', linhas[i].strip()); i += 1
                xs.append(bullet(run(('Quero ' if mm.group(1) != 'Para que' else 'Para que '), b=True) + run(mm.group(2))))
            xs.append(HR); intro = False; continue
        if intro and re.match(r'^(Referência|US de |US técnica|US tecnica|US B2C|US B2B|US de catálogo|US de CPQ|US-\d)', s):
            xs.append(para(s, i=True, color='595959', sz=20)); continue
        intro = False
        m = re.match(r'^(Crit[ée]rio\s+\d+(?:\s*[:—-]\s*.*)?|Cen[áa]rio\s+\d+\s*:\s*[^.]{0,80}?)(?:\.\s+|\s*$)(.*)$', s)
        if m and not tem_ac:
            titulo = m.group(1).strip(); rest = m.group(2).strip()
            while i < n and re.match(r'(?i)^(dado|quando|então|entao)\s', linhas[i].strip()): rest += '\n' + linhas[i].strip(); i += 1
            xs += criterio_xml(titulo, rest); continue
        m = re.match(r'^(\d+)\.\s+(Dado\s.*)$', s)
        if m and not tem_ac: xs += criterio_xml(f'Critério {m.group(1)}', m.group(2)); continue
        m = re.match(r'^(RN-\d+)\s+(.*)$', s)
        if m: xs.append(lead(m.group(1), m.group(2))); continue
        m = re.match(r'^([-•*☐]|\[ \])\s*(.*)$', s)
        if m: xs.append(bullet(run(('☐ ' if m.group(1) in ('☐', '[ ]') else '') + m.group(2)))); continue
        m = re.match(r'^([A-ZÀ-Ú][^:]{1,80}):\s+(.+)$', s)
        if m and re.fullmatch(r"[A-ZÀ-Ú0-9 \-/&,.º#]+", sem_parens(m.group(1))) and re.search(r'[A-ZÀ-Ú]{3}', m.group(1)): xs.append(lead(m.group(1) + ':', m.group(2))); continue
        m = re.match(r'^([A-Za-zÀ-ú][A-Za-zÀ-ú0-9 /&\-]{2,40}):\s+(.+)$', s)
        if m and m.group(1) in ('Contexto', 'Regras', 'Fonte', 'Dependências', 'Riscos', 'Riscos/Premissas', 'Automação', 'Automação / Lógica', 'Integração / APIs', 'Segurança e Acessos', 'Objetos Impactados', 'Estimativa de Esforço', 'Estimativa Sugerida', 'Estimativa Automática de Esforço', 'Massa de Teste Sugerida', 'Mapeamento eTOM', 'Governor Limits & Edge Cases', 'Nota de arquitetura', 'Nota de arquitetura BTP', 'Referência', 'Automação / Front-end', 'Integração / APIs TM Forum'):
            xs.append(lead(m.group(1) + ':', m.group(2))); continue
        xs.append(para(s))
    return [x for x in xs if x]

def render_notas(notas):
    xs = [h1('Notas de Refinamento e Decisões Registradas')]
    for tit, corpo in notas:
        xs.append(h2(tit))
        for l in juntar_linhas(corpo):
            s = l.strip()
            if not s: continue
            m = re.match(r'^([A-ZÀ-Ú][A-ZÀ-Ú0-9 \-/&(),.º#]{1,60}):\s+(.+)$', s)
            if m and re.search(r'[A-ZÀ-Ú]{3}', m.group(1)): xs.append(lead(m.group(1) + ':', m.group(2)))
            elif re.match(r'^[-•]\s', s): xs.append(bullet(run(s[2:])))
            else: xs.append(para(s))
    return xs

def nome_arquivo(w, subj):
    s = unicodedata.normalize('NFKD', subj).encode('ascii', 'ignore').decode()
    s = re.sub(r'[^A-Za-z0-9]+', '_', s).strip('_')[:70].rstrip('_')
    return f'{w}_{s}.docx'

def delta_w70(d):
    """extracao anterior ao script 15: move o texto de decisoes da AC 3 para as duas notas, como o script fez na org"""
    for ac in d.get('acceptance_criteria', []):
        desc = ac.get('Description', '')
        k = desc.find('Decisões do cliente')
        if k > -1:
            decisoes = desc[k:].strip(); ac['Description'] = desc[:k].strip()
            src = open(os.path.join(os.path.dirname(__file__), '..', 'scripts', '15_W70_MoverDecisoesDaAC_0809.apex'), encoding='utf-8').read()
            cab1 = re.search(r"String CAB1 = '(.*?)';", src).group(1); cab2 = re.search(r"String CAB2 = '(.*?)';", src).group(1)
            bloco = re.search(r"String pend = (.*?);\s*\nw\.agf__Details__c", src, re.S).group(1)
            pend = ''.join(re.findall(r"'((?:[^'\\]|\\.)*)'", bloco)).replace("\\n", "\n").replace("\\'", "'")
            d['Details'] = d['Details'].rstrip() + '\n\n' + cab1 + '\n' + decisoes + '\n\n' + cab2 + '\n' + pend
    return d

def gerar(w, d):
    if w == 'W-000070': d = delta_w70(d)
    det = d['Details'].replace('\r\n', '\n')
    partes = re.split(r'\n*^--- (.+?) ---\s*\n', det, flags=re.M)
    corpo, notas = partes[0], list(zip(partes[1::2], partes[2::2]))
    acs = d.get('acceptance_criteria', [])
    subj = d.get('Subject', '')
    x = capa
    x += center('Requisitos de negócio Projeto Salesforce', b=True, color='0C3C8C', sz=44).replace('<w:pPr>', '<w:pPr><w:spacing w:after="100"/>', 1)
    x += center(subj, b=True, color='0C3C8C', sz=28).replace('<w:pPr>', '<w:pPr><w:spacing w:before="600" w:after="200"/>', 1)
    x += center(f"{w}  ·  {d.get('Epic','')}", color='595959', sz=22)
    x += center(f"Time: {d.get('ScrumTeam','')}  ·  Status: {d.get('Status','')}", color='595959', sz=22)
    x += p('<w:r><w:br w:type="page"/></w:r>')
    x += p(run(subj, b=True), '<w:spacing w:after="120"/>')
    x += tabela([('Work', w), ('Épico', d.get('Epic', '')), ('Time (Scrum Team)', d.get('ScrumTeam', '')), ('Product Tag', d.get('ProductTag', '')),
                 ('Status', d.get('Status', '')), ('Responsável', d.get('Assignee', '') or '(sem responsável)'), ('Product Owner', d.get('ProductOwner', '') or '(sem Product Owner)'),
                 ('Última alteração na org', f"{d.get('LastModifiedDate','')} por {d.get('LastModifiedBy','')}"), ('Documento gerado em', GERADO)])
    x += p('', '<w:spacing w:after="60"/>')
    x += ''.join(render_corpo(juntar_linhas(corpo), bool(acs)))
    if acs: x += ''.join(render_ac(acs))
    if notas: x += ''.join(render_notas(notas))
    x += sect
    doc = head + x
    core = modelo.read('docProps/core.xml').decode('utf-8')
    core = re.sub(r'<dc:title>.*?</dc:title>', f'<dc:title>{t(w + " - " + subj)}</dc:title>', core, flags=re.S)
    iso = agora.astimezone(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    core = re.sub(r'(<dcterms:(created|modified)[^>]*>)[^<]*', lambda m: m.group(1) + iso, core)
    fn = os.path.join(out, nome_arquivo(w, subj))
    with zipfile.ZipFile(fn, 'w', zipfile.ZIP_DEFLATED) as z:
        for item in modelo.infolist():
            zi = zipfile.ZipInfo(item.filename, date_time=agora.timetuple()[:6]); zi.compress_type = zipfile.ZIP_DEFLATED
            if item.filename == 'word/document.xml': z.writestr(zi, doc.encode('utf-8'))
            elif item.filename == 'docProps/core.xml': z.writestr(zi, core.encode('utf-8'))
            else: z.writestr(zi, modelo.read(item.filename))
    return fn

files = [gerar(w, d) for w, d in sorted(works.items())]
# validacao: XML bem formado
import xml.etree.ElementTree as ET
for f in files:
    ET.fromstring(zipfile.ZipFile(f).read('word/document.xml'))
print(f'{len(files)} docs gerados em {out}')
if zip_out:
    with zipfile.ZipFile(zip_out, 'w', zipfile.ZIP_DEFLATED) as z:
        for f in files: z.write(f, os.path.basename(f))
    print('pacote:', zip_out, os.path.getsize(zip_out), 'bytes')
