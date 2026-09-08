#!/usr/bin/env python3
"""Le o log do script 13 (EXT|) e gera works.json + um .md por work em ordem correta
(corpo, criterios de aceite, notas de refinamento). Uso: parse_ext_log.py <log> [saida/]"""
import re, sys, json, html, os
log = open(sys.argv[1], encoding='utf-8').read()
out = sys.argv[2] if len(sys.argv) > 2 else 'extracao'
os.makedirs(out, exist_ok=True)
# cada entrada do log comeca com timestamp; USER_DEBUG pode ter varias linhas
entries = re.split(r'\n(?=\d{2}:\d{2}:\d{2}\.\d+ \(\d+\)\|)', log)
works = {}
for e in entries:
    if '|USER_DEBUG|' not in e: continue
    body = html.unescape(e.split('|DEBUG|', 1)[1]).rstrip('\n')
    if not body.startswith('EXT| '): continue
    parts = body[5:].split(' | ', 4)
    w = parts[0]
    if w in ('INICIO', 'FIM'): continue
    wk = works.setdefault(w, {'fields': {}, 'Details': [], 'Description': [], 'ac': {}, 'comments': {}, 'tasks': {}})
    if parts[1] == 'FIM': continue
    tipo = parts[1]
    if tipo == 'F':
        k, v = parts[2], ' | '.join(parts[3:])
        if k.startswith('AC'):
            n, f = k.split('.', 1); wk['ac'].setdefault(n, {})[f] = v
        elif k.startswith('CM'):
            n, f = k.split('.', 1); wk['comments'].setdefault(n, {})[f] = v
        elif k.startswith('TK'):
            wk['tasks'][k] = v
        else:
            wk['fields'][k] = v
    else:  # D / A / C: blocos numerados
        k, seq, txt = parts[2], parts[3], parts[4] if len(parts) > 4 else ''
        if tipo == 'D': wk[k].append((int(seq), txt))
        elif tipo == 'A':
            n, f = k.split('.', 1); wk['ac'].setdefault(n, {}).setdefault('_blk', []).append((int(seq), txt))
        elif tipo == 'C':
            n, f = k.split('.', 1); wk['comments'].setdefault(n, {}).setdefault('_blk', []).append((int(seq), txt))
def join(bl): return ''.join(t for _, t in sorted(bl))
result = {}
for w, wk in sorted(works.items()):
    d = {'work': w, **wk['fields'], 'Details': join(wk['Details']), 'Description': join(wk['Description'])}
    d['acceptance_criteria'] = [{**{k: v for k, v in ac.items() if k != '_blk'}, 'Description': join(ac.get('_blk', []))}
                                for _, ac in sorted(wk['ac'].items())]
    d['comments'] = [{**{k: v for k, v in c.items() if k != '_blk'}, 'Body': join(c.get('_blk', []))}
                     for _, c in sorted(wk['comments'].items())]
    d['tasks'] = [v for _, v in sorted(wk['tasks'].items())]
    result[w] = d
    # markdown: corpo (antes da 1a nota), criterios, notas
    det = d['Details']
    m = re.search(r'\n*--- .*? ---\n', det)
    corpo, notas = (det[:m.start()], det[m.start():]) if m else (det, '')
    md = [f"# {w} — {d.get('Subject','')}", '',
          f"Épico: {d.get('Epic','')} | Time: {d.get('ScrumTeam','')} | Product Tag: {d.get('ProductTag','')} | Status: {d.get('Status','')} | Responsável: {d.get('Assignee','') or '(sem assignee)'}",
          f"Criado: {d.get('CreatedDate','')} por {d.get('CreatedBy','')} | Alterado: {d.get('LastModifiedDate','')} por {d.get('LastModifiedBy','')}", '',
          corpo.strip(), '']
    if d['acceptance_criteria']:
        md += ['## Critérios de Aceite (related list)', '']
        for i, ac in enumerate(d['acceptance_criteria'], 1):
            md += [f"**{i}. {ac.get('Name','')}** ({ac.get('Status','')})", ac.get('Description','').strip(), '']
    if notas.strip():
        md += ['## Notas de Refinamento e Decisões Registradas', '', notas.strip(), '']
    if d['comments']:
        md += ['## Comentários', ''] + [f"- {c.get('Autor','')}: {c.get('Body','').strip()}" for c in d['comments']] + ['']
    safe = re.sub(r'[^\w\-]+', '_', d.get('Subject', ''))[:70]
    open(os.path.join(out, f'{w}_{safe}.md'), 'w', encoding='utf-8').write('\n'.join(md))
json.dump(result, open(os.path.join(out, 'works.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
semac = [w for w, d in result.items() if not d['acceptance_criteria'] and re.search(r'CRIT[EÉ]RIOS DE ACEITE', d['Details'], re.I)]
print(f'{len(result)} works; sem Acceptance Criteria mas com criterios no corpo: {len(semac)} -> {", ".join(semac)}')
