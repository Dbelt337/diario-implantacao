#!/usr/bin/env python3
"""Gera a planilha de extracao das works do Agile Accelerator a partir do JSON do `sf data query --json`.
Abas: Works (lista completa), Por Epico, Por Sprint, Por Prioridade, Epico x Sprint, Epico x Prioridade.
Somente leitura. Uso: python extrair_works_xlsx.py <works.json> <saida.xlsx>"""
import json, sys
from collections import Counter, defaultdict
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment
from openpyxl.utils import get_column_letter

src, out = sys.argv[1], sys.argv[2]
recs = json.load(open(src, encoding='utf8'))['result']['records']
g = lambda r, *ks: (lambda v: v)(__import__('functools').reduce(lambda a, k: (a or {}).get(k) if isinstance(a, dict) else None, ks, r))
rows = []
for r in recs:
    rows.append(dict(
        Work=r['Name'], Assunto=r.get('agf__Subject__c') or '', Epico=g(r, 'agf__Epic__r', 'Name') or '(sem epico)',
        Sprint=g(r, 'agf__Sprint__r', 'Name') or '(backlog)', Prioridade=r.get('agf__Priority__c') or '(vazia)',
        Status=r.get('agf__Status__c') or '', Time=g(r, 'agf__Scrum_Team__r', 'Name') or '', Responsavel=g(r, 'agf__Assignee__r', 'Name') or '',
        PO=g(r, 'agf__Product_Owner__r', 'Name') or '', Pontos=r.get('agf__Story_Points__c') or '',
        Criada=(r.get('CreatedDate') or '')[:10], Modificada=(r.get('LastModifiedDate') or '')[:10]))
PRIO = ['P0', 'P1', 'P2', 'P3', 'P4', '(vazia)']
def spr_key(s):
    return (0, s) if s.startswith('Sprint 1') else (1, s) if s.startswith('Sprint') else (2, s) if s != '(backlog)' else (3, s)

wb = Workbook()
head = Font(bold=True, color='FFFFFF'); fill = PatternFill('solid', fgColor='1F4E79'); bold = Font(bold=True)
def sheet(title, header, data, widths=None, totals=False):
    ws = wb.create_sheet(title)
    ws.append(header)
    for c in ws[1]:
        c.font = head; c.fill = fill; c.alignment = Alignment(vertical='center', wrap_text=True)
    for d in data: ws.append(d)
    if totals:
        ws.append(['Total'] + [(sum(d[i] for d in data if isinstance(d[i], (int, float))) if any(isinstance(d[i], (int, float)) for d in data) else '') for i in range(1, len(header))])
        for c in ws[ws.max_row]: c.font = bold
    for i, w in enumerate(widths or [18] * len(header), start=1): ws.column_dimensions[get_column_letter(i)].width = w
    ws.freeze_panes = 'A2'; ws.auto_filter.ref = ws.dimensions
    return ws

cols = ['Work', 'Assunto', 'Epico', 'Sprint', 'Prioridade', 'Status', 'Time', 'Responsavel', 'PO', 'Pontos', 'Criada', 'Modificada']
sheet('Works', cols, [[r[c] for c in cols] for r in sorted(rows, key=lambda r: (r['Epico'], spr_key(r['Sprint']), PRIO.index(r['Prioridade']) if r['Prioridade'] in PRIO else 9, r['Work']))],
      [10, 70, 42, 34, 10, 14, 14, 26, 18, 8, 11, 11])

def resumo(title, key, order=None):
    cnt = defaultdict(lambda: Counter())
    for r in rows:
        cnt[r[key]]['total'] += 1; cnt[r[key]][r['Prioridade']] += 1
        cnt[r[key]]['abertas' if r['Status'] != 'Closed' else 'fechadas'] += 1
    keys = sorted(cnt, key=order) if order else sorted(cnt)
    data = [[k, cnt[k]['total'], cnt[k]['abertas'], cnt[k]['fechadas']] + [cnt[k][p] for p in PRIO] for k in keys]
    sheet(title, [key, 'Works', 'Abertas', 'Fechadas'] + PRIO, data, [44, 8, 9, 9] + [7] * len(PRIO), totals=True)

resumo('Por Epico', 'Epico')
resumo('Por Sprint', 'Sprint', spr_key)
# prioridade: linhas por prioridade, colunas por status/time
cntp = defaultdict(Counter)
for r in rows:
    cntp[r['Prioridade']]['total'] += 1; cntp[r['Prioridade']][r['Time']] += 1
    cntp[r['Prioridade']]['em sprint' if r['Sprint'] not in ('(backlog)',) and r['Sprint'].startswith('Sprint') else ('sprint antiga' if r['Sprint'] != '(backlog)' else 'backlog')] += 1
times = sorted({r['Time'] for r in rows})
sheet('Por Prioridade', ['Prioridade', 'Works', 'Em sprint 1-4', 'Sprint antiga', 'Backlog'] + times,
      [[p, cntp[p]['total'], cntp[p]['em sprint'], cntp[p]['sprint antiga'], cntp[p]['backlog']] + [cntp[p][t] for t in times] for p in PRIO if p in cntp],
      [12, 8, 13, 13, 9] + [14] * len(times), totals=True)
# matrizes
def matriz(title, rk, ck, corder=None):
    m = defaultdict(Counter); cks = set()
    for r in rows: m[r[rk]][r[ck]] += 1; cks.add(r[ck])
    cks = sorted(cks, key=corder) if corder else sorted(cks)
    sheet(title, [rk] + cks + ['Total'], [[k] + [m[k][c] for c in cks] + [sum(m[k].values())] for k in sorted(m)], [44] + [16] * len(cks) + [8], totals=True)
matriz('Epico x Sprint', 'Epico', 'Sprint', spr_key)
matriz('Epico x Prioridade', 'Epico', 'Prioridade', lambda p: PRIO.index(p) if p in PRIO else 9)
del wb['Sheet']
wb.save(out)
print('ok', out, len(rows), 'works')
