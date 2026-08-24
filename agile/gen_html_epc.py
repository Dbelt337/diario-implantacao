# -*- coding: utf-8 -*-
import re, os, sys, html
from datetime import datetime, timedelta
sys.path.insert(0, '.')
from epc_data import EPC_WORKS
from gen_html import CSS, esc, dtfmt   # reutiliza estilo e helpers

def details_html(details):
    paras = [p.strip() for p in details.split('\n\n') if p.strip()]
    out = ['<h2>User Story</h2><div class="us"><p>%s</p></div>' % esc(paras[0])]
    rest = paras[1:]
    if rest:
        out.append('<h2>Descrição e Solução Técnica</h2>')
        for p in rest:
            txt = esc(' '.join(x.strip() for x in p.split('\n')))
            for h in ('Contexto:', 'Regras:', 'Escopo:', 'ESCOPO PARCIAL DESTA WORK:',
                      'Dependências:', 'Fonte:'):
                if txt.startswith(h):
                    txt = '<b>%s</b>%s' % (h, txt[len(h):]); break
            out.append('<p>%s</p>' % txt)
    return '\n'.join(out)

def build_html(w):
    code = w['id']
    meta_rows = [
        ('Código da Work', code, 'Status', 'New'),
        ('Tipo', 'User Story', 'Story Points', '(não atribuído)'),
        ('Épico', w['epic'], 'Sprint', '(não planejado)'),
        ('Time (Scrum Team)', w['team'], 'Product Tag', 'Salesforce'),
        ('Atribuído a', 'Davi Israel de Abreu', 'Criado por',
         'Diego Beltrão de Moraes, %s' % dtfmt(w['created'])),
        ('Última modificação', 'Diego Beltrão de Moraes, %s' % dtfmt('2026-08-21T20:34:54'), '', ''),
    ]
    meta = ['<table class="meta">']
    for l1, v1, l2, v2 in meta_rows:
        meta.append('<tr><td class="l">%s</td><td>%s</td><td class="l">%s</td><td>%s</td></tr>'
                    % (esc(l1), esc(v1), esc(l2), esc(v2)))
    meta.append('</table>')
    items = ''.join('<li>%s</li>' % esc(t) for t in w['criteria'])
    note = ('<p class="sub">Critérios registrados no campo Details da work '
            '(não há registros filhos de Acceptance Criterion no Agile para esta work).</p>')
    return '''<!doctype html><html><head><meta charset="utf-8">
<title>%s - %s</title><style>%s</style></head><body>
<div class="doc-head"><h1>%s - %s</h1>
<div class="sub">Agile Accelerator - Brasil TecPar - extração de 24/08/2026</div></div>
%s
%s
<h2>Critérios de Aceite</h2>
<ol class="crit">%s</ol>
%s
</body></html>''' % (code, esc(w['subject']), CSS, code, esc(w['subject']),
                     ''.join(meta), details_html(w['details']), items, note)

os.makedirs('html', exist_ok=True)
for w in EPC_WORKS:
    short = re.sub(r'[^A-Za-z0-9]+', '_', w['subject'].split('—')[0].strip()).strip('_')
    base = '%s_%s' % (w['id'], short)
    with open(os.path.join('html', base + '.html'), 'w') as f:
        f.write(build_html(w))
    print(base)
