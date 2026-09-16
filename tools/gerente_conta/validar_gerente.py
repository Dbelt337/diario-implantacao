#!/usr/bin/env python3
"""
Validador a seco da alteracao de Gerente da conta (Account.AccountManager__c) e Gerente da Conta da oportunidade
(Opportunity.ManagerAccount__c). NAO faz DML. Regra da casa: primeiro consulta, depois atualiza pelo Id. Le o template
preenchido e, opcionalmente, os exports da org, e produz em saida/:

  consultas.soql              3 consultas (contas por CNPJ nos dois formatos, oportunidades por nome, usuarios)
  A_contas_update.csv         Id, AccountManager__c (novo), colunas informativas e a flag PrecisaClusterExecutor
  A_opps_update.csv           Id, ManagerAccount__c (novo), fase, flags PrecisaBypass e EmAprovacao
  B_retidos.csv               linhas sem registro, com mais de um registro, nome divergente, gerente nao resolvido...
  C_sem_mudanca.csv           registros que ja estao com o gerente alvo
  relatorio.txt

Uso:
  python3 validar_gerente.py --arquivo Alterar_Gerente.xlsx [--accounts accounts.json --opps opps.json --users users.json] [--out saida/]
"""
import argparse, csv, json, os, re, sys, unicodedata, zipfile, html
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lead_load'))
from validar_leads import normaliza_cnpj, mascara_cnpj, classifica_documento, norm_nome, load_records, g, indexa_users, resolve_owner

COLS_C = ['CNPJ', 'NomeConta', 'ProprietarioAtual', 'GerenteAtual', 'NovoGerente', 'Obs']
COLS_O = ['NomeConta', 'NomeOpp', 'ProprietarioOpp', 'Fase', 'NovoGerente', 'Obs']
FASES_BYPASS = {'Análise cliente', 'Analise cliente', 'Aguardando contrato'}   # regras BloqueiaAlteracaoAnaliseCliente / AguardandoContrato
RT_CONTA_CLUSTER = 'B2B - Pessoa jurídica'                                     # regra do cluster: RT B2B PJ e ClusterManual__c vazio

def nested(rec, parent, field):
    """Campo de relacionamento no formato do sf --json (dict aninhado) ou plano (CSV: 'Parent.Field' / 'Parent_Field')."""
    v = rec.get(parent)
    if isinstance(v, dict): return v.get(field) or ''
    return g(rec, f'{parent}.{field}', f'{parent}_{field}')

def read_sheet(path, idx, cols):
    z = zipfile.ZipFile(path)
    ss = []
    if 'xl/sharedStrings.xml' in z.namelist():
        sx = z.read('xl/sharedStrings.xml').decode('utf8')
        ss = [''.join(html.unescape(t) for t in re.findall(r'<t[^>]*>(.*?)</t>', si, flags=re.S)) for si in re.findall(r'<si>.*?</si>', sx, flags=re.S)]
    x = z.read(f'xl/worksheets/sheet{idx}.xml').decode('utf8')
    out = []
    for i, row in enumerate(re.findall(r'<row [^>]*>(.*?)</row>', x, flags=re.S)):
        if i == 0: continue
        d = {}
        for m in re.finditer(r'<c r="([A-Z]+)\d+"([^>]*?)(?:/>|>(.*?)</c>)', row, flags=re.S):
            c, attrs, inner = m.group(1), m.group(2), m.group(3) or ''
            v = re.search(r'<v>(.*?)</v>', inner); t = re.search(r't="(\w+)"', attrs)
            if v:
                val = v.group(1)
                if t and t.group(1) == 's': val = ss[int(val)]
                d[c] = html.unescape(str(val))
            elif '<is>' in inner: d[c] = html.unescape(''.join(re.findall(r'<t[^>]*>(.*?)</t>', inner, flags=re.S)))
        vals = [' '.join((d.get(chr(65 + k)) or '').split()) for k in range(len(cols))]
        if any(vals): out.append({**dict(zip(cols, vals)), 'Linha': i + 1})
    return out

def processa(contas, opps, org_acc, org_opp, users, online):
    by_email, by_name = indexa_users(users)
    idx_acc = {}
    for a in org_acc:
        n = normaliza_cnpj(g(a, 'DocumentNumber__c'))
        if n: idx_acc.setdefault(n, []).append(a)
    idx_opp = {}
    for o in org_opp:
        idx_opp.setdefault((norm_nome(nested(o, 'Account', 'Name')), norm_nome(g(o, 'Name'))), []).append(o)
    A_c, A_o, B, C = [], [], [], []
    gerentes = {}
    def gerente_id(nome):
        if nome not in gerentes: gerentes[nome] = resolve_owner(nome, by_email, by_name) if online else ('', '')
        return gerentes[nome]
    vistos = {}
    for r in contas:
        m = []
        n = normaliza_cnpj(r['CNPJ']); tipo, mdoc = classifica_documento(n)
        if not r['CNPJ']: m.append('CNPJ vazio')
        elif tipo == 'CPF': m.append('CPF: esta carga e de contas PJ')
        if not r['NovoGerente']: m.append('Novo gerente vazio')
        if n in vistos: m.append(f'CNPJ duplicado no arquivo (linha {vistos[n]})')
        else: vistos[n] = r['Linha']
        aviso = f'AVISO: {mdoc}' if tipo == 'CNPJ_INVALIDO' else ''
        if online and not m:
            gid, mg = gerente_id(r['NovoGerente'])
            if mg: m.append(mg)
            cands = idx_acc.get(n, [])
            if len(cands) == 0: m.append('conta nao encontrada na org por CNPJ' + (f' ({aviso})' if aviso else ''))
            elif len(cands) > 1: m.append(f'{len(cands)} contas com este CNPJ na org: ' + ', '.join(g(a, 'Id') for a in cands) + ' (resolver duplicidade antes)')
            else:
                a = cands[0]
                if r['NomeConta'] and norm_nome(r['NomeConta']) != norm_nome(g(a, 'Name')): m.append(f'nome divergente: planilha "{r["NomeConta"]}" x org "{g(a, "Name")}"')
                if not m:
                    if g(a, 'AccountManager__c') == gid:
                        C.append({'Tipo': 'Conta', 'Id': g(a, 'Id'), 'Nome': g(a, 'Name'), 'Linha': r['Linha'], 'Motivo': 'ja esta com o gerente alvo'}); continue
                    rt = nested(a, 'RecordType', 'DeveloperName')
                    precisa_cluster = (not g(a, 'ClusterManual__c')) and ('B2B' in str(rt))
                    A_c.append({'Id': g(a, 'Id'), 'AccountManager__c': gid, 'Name': g(a, 'Name'), 'DocumentNumber__c': g(a, 'DocumentNumber__c'),
                                'GerenteAtualId': g(a, 'AccountManager__c'), 'OwnerId': g(a, 'OwnerId'), 'ClusterManual__c': g(a, 'ClusterManual__c'),
                                'RecordType': rt, 'PrecisaClusterExecutor': 'SIM' if precisa_cluster else '', 'NovoGerenteNome': r['NovoGerente'], 'Linha': r['Linha'], 'Aviso': aviso})
                    continue
        elif not online and not m: m.append('FORMATO OK; aguarda cruzamento com a org' + (f' ({aviso})' if aviso else ''))
        if m: B.append({'Tipo': 'Conta', 'Linha': r['Linha'], 'Motivo': ' | '.join(m), **{k: r[k] for k in COLS_C}})
    vistos = {}
    for r in opps:
        m = []
        if not r['NomeConta']: m.append('Nome da conta vazio')
        if not r['NomeOpp']: m.append('Nome da oportunidade vazio')
        if not r['NovoGerente']: m.append('Novo gerente vazio')
        k = (norm_nome(r['NomeConta']), norm_nome(r['NomeOpp']))
        if k in vistos: m.append(f'oportunidade duplicada no arquivo (linha {vistos[k]})')
        else: vistos[k] = r['Linha']
        if online and not m:
            gid, mg = gerente_id(r['NovoGerente'])
            if mg: m.append(mg)
            cands = [o for o in idx_opp.get(k, []) if str(g(o, 'IsClosed')).lower() not in ('true', '1')]
            if len(cands) == 0: m.append('oportunidade aberta nao encontrada na org (conta + nome exatos)')
            elif len(cands) > 1: m.append(f'{len(cands)} oportunidades abertas com este nome nesta conta: ' + ', '.join(g(o, 'Id') for o in cands))
            else:
                o = cands[0]
                if not m:
                    if g(o, 'ManagerAccount__c') == gid:
                        C.append({'Tipo': 'Oportunidade', 'Id': g(o, 'Id'), 'Nome': g(o, 'Name'), 'Linha': r['Linha'], 'Motivo': 'ja esta com o gerente alvo'}); continue
                    fase = g(o, 'StageName'); em_aprov = str(g(o, 'Send4Approval__c')).lower() in ('true', '1')
                    A_o.append({'Id': g(o, 'Id'), 'ManagerAccount__c': gid, 'Name': g(o, 'Name'), 'AccountName': r['NomeConta'], 'StageName': fase,
                                'GerenteAtualId': g(o, 'ManagerAccount__c'), 'OwnerId': g(o, 'OwnerId'), 'PrecisaBypass': 'SIM' if fase in FASES_BYPASS else '',
                                'EmAprovacao': 'SIM: reatribuir item Aprovacao - Comercial; campo apos a aprovacao' if em_aprov else '',
                                'NovoGerenteNome': r['NovoGerente'], 'Linha': r['Linha']})
                    continue
        elif not online and not m: m.append('FORMATO OK; aguarda cruzamento com a org')
        if m: B.append({'Tipo': 'Oportunidade', 'Linha': r['Linha'], 'Motivo': ' | '.join(m), **{k2: r[k2] for k2 in COLS_O}})
    return A_c, A_o, B, C

def escreve(out, A_c, A_o, B, C, contas, opps, online):
    os.makedirs(out, exist_ok=True)
    def w(nome, cols, data):
        with open(os.path.join(out, nome), 'w', encoding='utf-8-sig', newline='') as f:
            wr = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore'); wr.writeheader(); wr.writerows(data)
    w('A_contas_update.csv', ['Id', 'AccountManager__c', 'Name', 'DocumentNumber__c', 'GerenteAtualId', 'OwnerId', 'ClusterManual__c', 'RecordType', 'PrecisaClusterExecutor', 'NovoGerenteNome', 'Linha', 'Aviso'], A_c)
    w('A_opps_update.csv', ['Id', 'ManagerAccount__c', 'Name', 'AccountName', 'StageName', 'GerenteAtualId', 'OwnerId', 'PrecisaBypass', 'EmAprovacao', 'NovoGerenteNome', 'Linha'], A_o)
    w('B_retidos.csv', ['Tipo', 'Linha', 'Motivo'] + sorted(set(COLS_C) | set(COLS_O)), B)
    w('C_sem_mudanca.csv', ['Tipo', 'Id', 'Nome', 'Linha', 'Motivo'], C)
    cnpjs = sorted({normaliza_cnpj(r['CNPJ']) for r in contas if len(normaliza_cnpj(r['CNPJ'])) == 14})
    lista = ','.join(f"'{x}'" for x in cnpjs) + ',' + ','.join(f"'{mascara_cnpj(x)}'" for x in cnpjs) if cnpjs else "''"
    nomes_opp = ','.join("'" + r['NomeOpp'].replace("\\", "\\\\").replace("'", "\\'") + "'" for r in opps) or "''"
    donos = sorted({r['NovoGerente'] for r in contas + opps if r['NovoGerente']})
    emails = ','.join(f"'{d.lower()}'" for d in donos if '@' in d) or "''"; nomes = ','.join(f"'{d}'" for d in donos if '@' not in d) or "''"
    with open(os.path.join(out, 'consultas.soql'), 'w', encoding='utf8') as f:
        f.write(f"-- 1) accounts.json\nSELECT Id, Name, DocumentNumber__c, OwnerId, AccountManager__c, ClusterManual__c, RecordType.DeveloperName FROM Account WHERE DocumentNumber__c IN ({lista})\n\n")
        f.write(f"-- 2) opps.json\nSELECT Id, Name, Account.Name, StageName, IsClosed, OwnerId, ManagerAccount__c, Send4Approval__c, RecordType.DeveloperName FROM Opportunity WHERE Name IN ({nomes_opp})\n\n")
        f.write(f"-- 3) users.json\nSELECT Id, Name, Email, IsActive FROM User WHERE Email IN ({emails}) OR Name IN ({nomes})\n")
    from collections import Counter
    fmt_ok = sum(1 for b in B if b['Motivo'].startswith('FORMATO OK'))
    rel = [f'Modo: {"ONLINE (cruzado com a org)" if online else "OFFLINE (sem exports da org)"}',
           f'Linhas lidas: {len(contas)} contas, {len(opps)} oportunidades',
           f'A) contas a atualizar: {len(A_c)}  (precisam de cluster no executor: {sum(1 for a in A_c if a["PrecisaClusterExecutor"])})',
           f'A) oportunidades a atualizar: {len(A_o)}  (bypass: {sum(1 for a in A_o if a["PrecisaBypass"])}; em aprovacao: {sum(1 for a in A_o if a["EmAprovacao"])})',
           f'B) retidas: {len(B) - fmt_ok}' + (f'  (+{fmt_ok} com formato OK, aguardando cruzamento)' if fmt_ok else ''),
           f'C) sem mudanca (ja com o gerente alvo): {len(C)}', '', 'Motivos de retencao:']
    cnt = Counter(m.split(':')[0] for b in B for m in b['Motivo'].split(' | '))
    rel += [f'  {v:5d}  {k}' for k, v in cnt.most_common()]
    txt = '\n'.join(rel); print(txt)
    with open(os.path.join(out, 'relatorio.txt'), 'w', encoding='utf8') as f: f.write(txt + '\n')

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--arquivo', required=True); ap.add_argument('--accounts'); ap.add_argument('--opps'); ap.add_argument('--users'); ap.add_argument('--out', default='saida')
    a = ap.parse_args()
    contas = read_sheet(a.arquivo, 1, COLS_C); opps = read_sheet(a.arquivo, 2, COLS_O)
    online = bool(a.accounts and a.opps and a.users)
    A_c, A_o, B, C = processa(contas, opps, load_records(a.accounts), load_records(a.opps), load_records(a.users), online)
    escreve(a.out, A_c, A_o, B, C, contas, opps, online)
