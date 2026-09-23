"""Carga retroativa dos marcos de conclusao da fila de Arquitetura na Oportunidade (ArchViabilityConcludedAt__c,
ArchTechValidConcludedAt__c, Architect__c) a partir dos itens de orquestracao "Aprovacao - Arquitetura" ja concluidos.

Regra: cada item concluido e atribuido a fase cujo marco de inicio (SLAViability__c ou SLAArchitect__c) foi gravado ate
15 minutos antes da criacao do item. Se a oportunidade teve mais de um item na mesma fase, vale o ultimo concluido.
O arquiteto e o LastModifiedBy do item (quem concluiu). Nao faz DML: gera o CSV para "sf data update bulk".

Uso (na raiz do repo, org btp-prod autenticada, apos o deploy dos campos):
    python tools/relatorios/gerar_backfill_marcos_arquitetura.py [--dias 120]
Saida: org/tmp/arquitetura_marcos/backfill_marcos_arquitetura.csv (fora do git) e resumo no terminal.
Carga (Diego): sf data update bulk --sobject Opportunity --file org/tmp/arquitetura_marcos/backfill_marcos_arquitetura.csv --target-org btp-prod --wait 10
"""
import csv
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta

ORG = 'btp-prod'
OUT_DIR = 'org/tmp/arquitetura_marcos'
JANELA = timedelta(minutes=15)
LOTE = 200


def soql(q):
    with tempfile.NamedTemporaryFile('w', suffix='.soql', delete=False, encoding='utf8') as f:
        f.write(q)
        p = f.name
    out = subprocess.run(['sf', 'data', 'query', '--file', p, '--target-org', ORG, '--json'], capture_output=True, text=True,
                         encoding='utf8', shell=(os.name == 'nt'))
    os.unlink(p)
    d = json.loads(out.stdout)
    if d.get('status') != 0:
        raise SystemExit(d.get('message'))
    return d['result']['records']


def dt(s):
    return datetime.strptime(s[:19], '%Y-%m-%dT%H:%M:%S')


def main(dias):
    itens = soql("SELECT Id, RelatedRecordId, CreatedDate, LastModifiedDate, LastModifiedById FROM FlowOrchestrationWorkItem "
                 f"WHERE Label = 'Aprovação - Arquitetura' AND Status = 'Completed' AND LastModifiedDate = LAST_N_DAYS:{dias} "
                 "AND RelatedRecordId != null ORDER BY LastModifiedDate")
    ids = sorted({i['RelatedRecordId'] for i in itens if i['RelatedRecordId'].startswith('006')})
    opps = {}
    for k in range(0, len(ids), LOTE):
        lote = "','".join(ids[k:k + LOTE])
        for o in soql("SELECT Id, SLAViability__c, SLAArchitect__c "
                      f"FROM Opportunity WHERE Id IN ('{lote}')"):
            opps[o['Id']] = o
    linhas, sem_fase, resumo = {}, 0, {'viab': 0, 'tec': 0}
    for it in itens:
        o = opps.get(it['RelatedRecordId'])
        if not o:
            continue
        criado = dt(it['CreatedDate'])
        fase = None
        for campo, chave in (('SLAViability__c', 'viab'), ('SLAArchitect__c', 'tec')):
            if o.get(campo) and 0 <= (criado - dt(o[campo])).total_seconds() <= JANELA.total_seconds():
                fase = chave
        if not fase:
            sem_fase += 1
            continue
        l = linhas.setdefault(o['Id'], {'Id': o['Id']})
        col = 'ArchViabilityConcludedAt__c' if fase == 'viab' else 'ArchTechValidConcludedAt__c'
        if not l.get(col) or it['LastModifiedDate'] > l[col]:
            l[col] = it['LastModifiedDate']
            l['Architect__c'] = it['LastModifiedById']
            resumo[fase] += 1
    os.makedirs(OUT_DIR, exist_ok=True)
    caminho = os.path.join(OUT_DIR, 'backfill_marcos_arquitetura.csv')
    with open(caminho, 'w', newline='', encoding='utf8') as f:
        w = csv.DictWriter(f, fieldnames=['Id', 'ArchViabilityConcludedAt__c', 'ArchTechValidConcludedAt__c', 'Architect__c'])
        w.writeheader()
        for l in linhas.values():
            w.writerow(l)
    print(f'itens concluidos ({dias} dias): {len(itens)} | oportunidades: {len(ids)} | linhas no CSV: {len(linhas)}')
    print(f'atribuidos: Viabilidade {resumo["viab"]}, Validacao tecnica {resumo["tec"]} | itens sem marco de inicio na janela (ciclos antigos ou reenvio): {sem_fase}')
    print('csv:', caminho)


if __name__ == '__main__':
    main(int(sys.argv[sys.argv.index('--dias') + 1]) if '--dias' in sys.argv else 120)
