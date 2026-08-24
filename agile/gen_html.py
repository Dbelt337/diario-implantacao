# -*- coding: utf-8 -*-
import re, os, sys, html
from datetime import datetime, timedelta
sys.path.insert(0, '.')
from works_data import WORKS, COMMON

CRITERIA = {}
with open('criterios_raw.tsv') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line.strip(): continue
        wid, num, txt = line.split('\t', 2)
        CRITERIA.setdefault(wid, []).append(txt.strip())

CSS = '''
@page { size: A4; margin: 16mm 15mm 18mm 15mm; }
* { box-sizing: border-box; }
body { font-family: Arial, Helvetica, sans-serif; font-size: 10pt; color: #16325c;
       line-height: 1.45; margin: 0; }
.doc-head { border-bottom: 2px solid #d8dde6; padding-bottom: 8px; margin-bottom: 12px; }
h1 { font-size: 14.5pt; margin: 0 0 2px 0; color: #16325c; }
.sub { font-size: 8pt; color: #54698d; }
h2 { font-size: 11pt; color: #16325c; border-bottom: 1px solid #d8dde6;
     padding-bottom: 2px; margin: 16px 0 6px 0; }
table.meta { width: 100%; border-collapse: collapse; margin: 8px 0 4px 0; }
table.meta td { border: 1px solid #d8dde6; padding: 4px 7px; font-size: 8.8pt;
                vertical-align: top; }
table.meta td.l { background: #f4f6f9; font-weight: bold; color: #54698d;
                  width: 17%; white-space: nowrap; }
p { margin: 0 0 6px 0; text-align: justify; }
.us p { margin-bottom: 3px; }
ol.crit { margin: 4px 0 0 0; padding-left: 20px; }
ol.crit li { margin-bottom: 7px; text-align: justify; }
.empty { color: #a0530f; font-style: italic; }
.tag { display: inline-block; }
'''

def esc(t): return html.escape(t, quote=False)

def dtfmt(iso):
    return (datetime.fromisoformat(iso) - timedelta(hours=3)).strftime('%d/%m/%Y %H:%M')

def details_html(details):
    paras = [p.strip() for p in details.split('\n\n') if p.strip()]
    out = ['<h2>User Story</h2><div class="us">']
    for ln in paras[0].split('\n'):
        ln = ln.strip()
        m = re.match(r'^(Como|Quero|Para que|Para)\b', ln)
        if m:
            out.append('<p><b>%s</b>%s</p>' % (esc(m.group(1)), esc(ln[len(m.group(1)):])))
        else:
            out.append('<p>%s</p>' % esc(ln))
    out.append('</div>')
    rest = paras[1:]
    if rest:
        out.append('<h2>Descrição e Solução Técnica</h2>')
        for p in rest:
            txt = esc(' '.join(x.strip() for x in p.split('\n')))
            for h in ('SOLUÇÃO TÉCNICA', 'ESTRUTURA DE CATÁLOGOS DESTA WORK',
                      'ESCOPO PARCIAL DESTA WORK', 'Dependências:', 'Fonte:'):
                if txt.startswith(h):
                    txt = '<b>%s</b>%s' % (h, txt[len(h):]); break
            txt = txt.replace('CONSTRUIR:', '<b>CONSTRUIR:</b>').replace('REUSO:', '<b>REUSO:</b>')
            out.append('<p>%s</p>' % txt)
    return '\n'.join(out)

def build_html(w):
    c = COMMON
    code = w['id']
    meta_rows = [
        ('Código da Work', code, 'Status', c['status']),
        ('Tipo', c['tipo'], 'Story Points', c['points'] or '(não atribuído)'),
        ('Épico', w['epic'], 'Sprint', c['sprint'] or '(não planejado)'),
        ('Time (Scrum Team)', c['team'], 'Product Tag', c['product_tag']),
        ('Atribuído a', c['assignee'], 'Criado por', '%s, %s' % (c['created_by'], dtfmt(w['created']))),
        ('Última modificação', '%s, %s' % (c['modified_by'], dtfmt(c['modified'])), '', ''),
    ]
    meta = ['<table class="meta">']
    for l1, v1, l2, v2 in meta_rows:
        meta.append('<tr><td class="l">%s</td><td>%s</td><td class="l">%s</td><td>%s</td></tr>'
                    % (esc(l1), esc(v1), esc(l2), esc(v2)))
    meta.append('</table>')

    crits = CRITERIA.get(code, [])
    if crits:
        items = ''.join('<li>%s</li>' % esc(re.sub(r'^\d+\.\s+', '', t)) for t in crits)
        crit_html = '<ol class="crit">%s</ol>' % items
    else:
        crit_html = '<p class="empty">Nenhum critério de aceite registrado no Agile para esta work.</p>'

    return '''<!doctype html><html><head><meta charset="utf-8">
<title>%s - %s</title><style>%s</style></head><body>
<div class="doc-head"><h1>%s - %s</h1>
<div class="sub">Agile Accelerator - Brasil TecPar - extração de 24/08/2026</div></div>
%s
%s
<h2>Critérios de Aceite</h2>
%s
</body></html>''' % (code, esc(w['subject']), CSS, code, esc(w['subject']),
                     ''.join(meta), details_html(w['details']), crit_html)

os.makedirs('html', exist_ok=True)
os.makedirs('pdfs', exist_ok=True)
for w in WORKS:
    short = re.sub(r'[^A-Za-z0-9]+', '_', w['subject'].split('—')[0].strip()).strip('_')
    base = '%s_%s' % (w['id'], short)
    path = os.path.join('html', base + '.html')
    with open(path, 'w') as f:
        f.write(build_html(w))
    print(base)
