# Gera os .docx das works novas no mesmo formato dos 82 docs do export de 11/09 (template: W-000125).
# Uso: python3 gerar_docx_works.py <template.docx> <saida_dir>
import sys, os, re, zipfile, shutil, datetime, unicodedata
from xml.sax.saxutils import escape as esc

TPL, OUT = sys.argv[1], sys.argv[2]
SZ = '<w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>'
def run(t, b=False, i=False, color=None, sz=24):
    rpr = ('<w:b/><w:bCs/>' if b else '') + ('<w:i/><w:iCs/>' if i else '') + (f'<w:color w:val="{color}"/>' if color else '') + f'<w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/>'
    return f'<w:r><w:rPr>{rpr}</w:rPr><w:t xml:space="preserve">{esc(t)}</w:t></w:r>'
def p(runs, ppr=''):
    return f'<w:p><w:pPr>{ppr}{SZ}</w:pPr>{runs}</w:p>'
def heading(t): return p(run(t, b=True), '<w:keepNext/><w:spacing w:before="240" w:after="80"/>')
def plain(t): return p(run(t))
def labeled(label, t): return p(run(label, b=True) + run(t))
def bullet(numId, lvl, runs, keep=False):
    return p(runs, ('<w:keepNext/>' if keep else '') + f'<w:numPr><w:ilvl w:val="{lvl}"/><w:numId w:val="{numId}"/></w:numPr>')
def empty(): return p('')
def cell(t, w, b=False, fill=None):
    shd = f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>' if fill else ''
    return (f'<w:tc><w:tcPr><w:tcW w:w="{w}" w:type="dxa"/>{shd}</w:tcPr>'
            f'<w:p><w:pPr><w:spacing w:before="40" w:after="40"/>{SZ}</w:pPr>{run(t, b=b, sz=20)}</w:p></w:tc>')
def table(rows):
    b = '<w:tblBorders>' + ''.join(f'<w:{s} w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>' for s in ['top','left','bottom','right','insideH','insideV']) + '</w:tblBorders>'
    trs = ''.join(f'<w:tr>{cell(k,2400,True,"EEF3FA")}{cell(v,6104)}</w:tr>' for k, v in rows)
    return f'<w:tbl><w:tblPr><w:tblW w:w="8504" w:type="dxa"/>{b}<w:tblLook w:val="04A0"/></w:tblPr><w:tblGrid><w:gridCol w:w="2400"/><w:gridCol w:w="6104"/></w:tblGrid>{trs}</w:tbl>'

def build_body(w):
    code, subj = w['codigo'], w['titulo']
    out = []
    out.append(p(run('Requisitos de negócio Projeto Salesforce', b=True, color='0C3C8C', sz=44), '<w:spacing w:after="100"/><w:jc w:val="center"/>'))
    out.append(p(run(f'US {code} — {subj}', b=True, color='0C3C8C', sz=28), '<w:spacing w:before="600" w:after="200"/><w:jc w:val="center"/>'))
    out.append(p(run(f'{w["work"]}  ·  {w["epico"]}', color='595959', sz=22), '<w:jc w:val="center"/>'))
    out.append(p(run(f'Time: {w["time"]}  ·  Status: {w["status"]}', color='595959', sz=22), '<w:jc w:val="center"/>'))
    out.append(empty())
    out.append(p(run(f'US - {code} — {subj}', b=True), '<w:spacing w:after="120"/>'))
    out.append(table([('Work', w['work']), ('Épico', w['epico']), ('Time (Scrum Team)', w['time']), ('Status', w['status']),
                      ('Responsável', w['responsavel']), ('Documento gerado em', w['gerado'])]))
    out.append(empty())
    out.append(p(run(w['nota'], i=True, color='595959', sz=20), '<w:spacing w:after="60"/>'))
    out.append(heading('Descrição'))
    out.append(bullet(1, 0, run('Como ', b=True) + run(w['como'])))
    out.append(bullet(1, 0, run('Quero ', b=True) + run(w['quero'])))
    out.append(bullet(1, 0, run('Para que ', b=True) + run(w['para_que'])))
    out.append(empty())
    out.append(heading('Contexto e Cenário de Negócio'))
    for t in w['contexto']: out.append(plain(t))
    out.append(heading('Regras de Negócio Associadas'))
    for t in w['regras']: out.append(plain(t))
    out.append(heading('Especificação Técnica (Salesforce)'))
    for t in w['especificacao']: out.append(plain(t))
    out.append(heading('Dependências, Riscos e Estimativa'))
    out.append(labeled('Dependências: ', w['dependencias']))
    out.append(labeled('Riscos: ', w['riscos']))
    out.append(labeled('Estimativa: ', w['estimativa']))
    out.append(heading('Critérios de Aceite'))
    for i, (t, d, q, e) in enumerate(w['criterios'], 1):
        out.append(bullet(3, 0, run(f'Critério {i}: {t}.', b=True), keep=True))
        out.append(bullet(3, 1, run('Dado ', b=True) + run(d)))
        out.append(bullet(3, 1, run('Quando ', b=True) + run(q)))
        out.append(bullet(3, 1, run('Então ', b=True) + run(e)))
    out.append(empty())
    out.append(labeled('Massa de Teste Sugerida: ', w['massa']))
    if w.get('fundamentacao'):
        out.append(heading('Fundamentação Técnica (Salesforce Help)'))
        for t in w['fundamentacao']: out.append(plain(t))
    return ''.join(out)

def gerar(w):
    tmp = os.path.join(OUT, '_tmp'); shutil.rmtree(tmp, ignore_errors=True)
    with zipfile.ZipFile(TPL) as z: z.extractall(tmp)
    dx = os.path.join(tmp, 'word', 'document.xml'); x = open(dx, encoding='utf8').read()
    ps = list(re.finditer(r'<w:p[ >].*?</w:p>', x, re.S))
    head = x[:ps[1].end()]                       # ate o fim do paragrafo 1 (logo + espacamento)
    tail = x[x.rindex('<w:sectPr'):]
    open(dx, 'w', encoding='utf8').write(head + build_body(w) + tail)
    cx = os.path.join(tmp, 'docProps', 'core.xml'); c = open(cx, encoding='utf8').read()
    now = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:00Z')
    c = re.sub(r'<dc:title>.*?</dc:title>', f'<dc:title>{esc(w["work"] + " - US " + w["codigo"] + " — " + w["titulo"])}</dc:title>', c, flags=re.S)
    c = re.sub(r'<dcterms:created[^>]*>.*?</dcterms:created>', f'<dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created>', c)
    c = re.sub(r'<dcterms:modified[^>]*>.*?</dcterms:modified>', f'<dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified>', c)
    open(cx, 'w', encoding='utf8').write(c)
    # mesmo padrao do export de 11/09: acentos transliterados, nao alfanumericos viram '_', base limitada a 79 caracteres
    trans = unicodedata.normalize('NFKD', w['titulo']).encode('ascii', 'ignore').decode()
    prefix = f'{w["work"]}_US_{w["codigo"].replace("-", "_")}_'
    safe = re.sub(r'[^A-Za-z0-9]+', '_', trans).strip('_')[:79 - len(prefix)].rstrip('_')
    name = prefix + safe + '.docx'
    outp = os.path.join(OUT, name)
    if os.path.exists(outp): os.remove(outp)
    with zipfile.ZipFile(outp, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(tmp):
            for f in files:
                full = os.path.join(root, f); z.write(full, os.path.relpath(full, tmp))
    shutil.rmtree(tmp); print('gerado:', outp)

import importlib.util
spec = importlib.util.spec_from_file_location('conteudo', os.path.join(os.path.dirname(__file__), 'conteudo_works_b2b13a16.py'))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
for w in m.WORKS: gerar(w)
