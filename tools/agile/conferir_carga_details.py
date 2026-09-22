"""Confere se o campo agf__Details__c das works em producao bate com o CSV carregado.

Uso (na raiz do repo, org btp-prod autenticada):
    python tools/agile/conferir_carga_details.py [caminho/do/csv]
    python tools/agile/conferir_carga_details.py --gerar-rollback   (recorta o backup para Id + agf__Details__c)

Padrao do CSV: org/tmp/agile_carga/carga_details_2026-09-22_v2.csv
"""
import csv
import json
import os
import subprocess
import sys
import tempfile

ORG = 'btp-prod'
CARGA = 'org/tmp/agile_carga/carga_details_2026-09-22_v2.csv'
BACKUP = 'org/tmp/agile_backup/rollback_details_2026-09-22_v2.csv'
ROLLBACK = 'org/tmp/agile_carga/rollback_details_2026-09-22_v2.csv'


def gerar_rollback():
    linhas = list(csv.DictReader(open(BACKUP, encoding='utf8')))
    with open(ROLLBACK, 'w', newline='', encoding='utf8') as f:
        w = csv.writer(f)
        w.writerow(['Id', 'agf__Details__c'])
        for r in linhas:
            w.writerow([r['Id'], r['agf__Details__c']])
    print(f'rollback gerado: {ROLLBACK} ({len(linhas)} linhas)')


def conferir(caminho):
    esperado = {r['Id']: r['agf__Details__c'].replace('\r\n', '\n') for r in csv.DictReader(open(caminho, encoding='utf8'))}
    ids = "','".join(esperado)
    soql = "SELECT Id, Name, agf__Details__c FROM agf__ADM_Work__c WHERE Id IN ('" + ids + "')"
    with tempfile.NamedTemporaryFile('w', suffix='.soql', delete=False, encoding='utf8') as f:
        f.write(soql)
        soql_path = f.name
    out = subprocess.run(['sf', 'data', 'query', '--file', soql_path, '--target-org', ORG, '--json'],
                         capture_output=True, text=True, encoding='utf8', shell=(os.name == 'nt'))
    os.unlink(soql_path)
    recs = json.loads(out.stdout)['result']['records']
    atual = {r['Id']: (r['Name'], (r['agf__Details__c'] or '').replace('\r\n', '\n')) for r in recs}
    div = [(atual[i][0], len(esperado[i]), len(atual[i][1])) for i in esperado if i in atual and atual[i][1].strip() != esperado[i].strip()]
    falt = [i for i in esperado if i not in atual]
    print(f'works no CSV: {len(esperado)} | lidas na org: {len(atual)} | divergentes: {len(div)} | nao encontradas: {len(falt)}')
    for n, e, a in sorted(div):
        print(f'  {n}: esperado {e} chars, na org {a} chars')
    for i in falt:
        print('  nao encontrada:', i)
    return 1 if div or falt else 0


if __name__ == '__main__':
    if '--gerar-rollback' in sys.argv:
        gerar_rollback()
    else:
        sys.exit(conferir(sys.argv[1] if len(sys.argv) > 1 else CARGA))
