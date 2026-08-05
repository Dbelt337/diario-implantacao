#!/usr/bin/env python3
"""Analisa a lista de preços do GrupoQ (LISTA_DE_PRECIOS_REPUESTOS_PRUEBASAUTO.xlsx)
e valida a fórmula do waterfall com arredondamento por etapa.

Uso: python3 analisar_lista_grupoq.py <arquivo.xlsx>

A lista original NÃO está versionada neste repo (dados sensíveis do cliente:
preços, custos reais e margens de 2.207 materiais). Fonte: thread do Teams
"HU-028 Pricing REP Y PA", enviada pelo GrupoQ em 05/08/2026.

Fórmula verificada (2.206/2.207 linhas exatas):
  FOB_usd = FOB / tasa            (se moneda FOB = CRC; tasa única 452,51)
  N = arred2(FOB_usd * %FN/100)   (FN por origem: JP/TH 55,51 | KR 50 | MX 42,61)
  P = arred2((FOB_usd + N) * %MK/100)   (MK por material, 73 valores, 4,69%-234%)
  Precio = arred2(FOB_usd + N + P)      == coluna Q "Precio Calculado" (USD)

O ARREDONDAMENTO OCORRE EM CADA ETAPA — sem isso, 702 linhas desviam centavos.
Única exceção: material 000000000023828034 (TRANSEJE CVT), cujo %MK exibido
(4,69) está arredondado; o implícito é 4,687% — pendente confirmação GrupoQ.
"""
import sys, zipfile, re
import xml.etree.ElementTree as ET
from collections import Counter

M = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
r2 = lambda x: round(x + 1e-9, 2)

def carregar(path):
    z = zipfile.ZipFile(path)
    shared = [''.join(t.text or '' for t in si.iter(M + 't'))
              for si in ET.fromstring(z.read('xl/sharedStrings.xml')).findall(M + 'si')]
    ws = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    data = []
    for row in list(ws.iter(M + 'row'))[1:]:
        d = {}
        for c in row:
            v = c.find(M + 'v')
            if v is None:
                continue
            col = re.match(r'[A-Z]+', c.get('r')).group()
            d[col] = shared[int(v.text)] if c.get('t') == 's' else v.text
        if d:
            data.append(d)
    return data

def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None

def main(path):
    data = carregar(path)
    print(f'linhas: {len(data)}')
    print('origem:', Counter(d.get('G') for d in data))
    print('moneda FOB:', Counter(d.get('I') for d in data))
    ok = bad = 0
    for i, d in enumerate(data):
        L, Mp, O, Q = f(d.get('L')), f(d.get('M')), f(d.get('O')), f(d.get('Q'))
        if None in (L, Mp, O, Q):
            continue
        n = r2(L * Mp / 100)
        p = r2((L + n) * O / 100)
        q = r2(L + n + p)
        if abs(q - Q) <= 0.005:
            ok += 1
        else:
            bad += 1
            print(f'  desvio linha {i+2}: {d.get("E")} calc={q} lista={Q}')
    print(f'paridade formula: {ok} ok, {bad} desvios')

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'LISTA_DE_PRECIOS_REPUESTOS_PRUEBASAUTO.xlsx')
