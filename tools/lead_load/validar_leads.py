#!/usr/bin/env python3
"""
Validador a seco da carga massiva de Leads B2B (BrasilTecPar). Mesmo metodo de tools/mg_load:
NAO faz DML. Le o template preenchido (xlsx ou csv) e, opcionalmente, tres exports da org, e produz:

  saida/A_leads_inserir.csv   linhas aprovadas, ja com os nomes de campo do Salesforce (Data Loader / sf data import)
  saida/B_retidos.csv         linhas com erro ou duvida (motivo em cada linha) - voltam para a SDR
  saida/C_ja_cliente.csv      CNPJ que ja e Conta ativa na org -> abrir Oportunidade na Conta (regra B2B-01), nao Lead
  saida/consultas.soql        as 3 consultas para exportar da org (rodar antes da 2a passada)
  saida/relatorio.txt

Uso:
  python3 validar_leads.py --arquivo Leads.xlsx [--leads leads.json --accounts accounts.json --users users.json] [--out saida/]

Exports (sf CLI, na org alvo):
  sf data query -o <org> --json -f saida/consultas.soql  (uma consulta por vez; ver o arquivo)

Sem os exports roda em modo OFFLINE: valida formato, obrigatorios e duplicidade dentro do arquivo, e nao aprova
nenhuma linha para insercao (todas ficam em B com motivo "sem cruzamento com a org").
"""
import argparse, csv, html, json, os, re, sys, unicodedata, zipfile

# ---- colunas do template (aba Leads, A..O) -> campo Salesforce
TEMPLATE = ['SDR', 'Proprietario', 'Origem', 'CNPJ', 'RazaoSocial', 'NomeFantasia', 'Nome', 'Sobrenome', 'Cargo',
            'Telefone1', 'Telefone2', 'Email', 'Cidade', 'UF', 'Observacoes']
SF_FIELDS = ['SDR__c', 'OwnerId', 'LeadSource', 'DocumentNumber__c', 'Company', 'FantasyName__c', 'FirstName', 'LastName', 'Title',
             'Phone', 'MobilePhone', 'Email', 'City', 'State', 'Description', 'Status', 'RecordTypeId', 'LegalEntityType__c']
STATUS_NOVO = 'Novo'            # regra 3 da B2B-01: Lead nasce em "Novo" (confirmar API name do valor na org)
RECORDTYPE_LEAD_B2B = ''        # preencher com o Id do RecordType de Lead B2B da org alvo (sandbox e prod diferem)
LEGAL_ENTITY_PJ = 'PJ'          # confirmar valor da picklist LegalEntityType__c

# ---- documento (copiado de tools/mg_load/mg_load.py)
def so_alnum(s): return ''.join(ch for ch in str(s or '') if ch.isalnum()).upper()
def normaliza_cnpj(doc):
    s = so_alnum(doc)
    if s.isdigit() and 12 <= len(s) < 14: s = s.zfill(14)
    return s
def mascara_cnpj(n): return f'{n[0:2]}.{n[2:5]}.{n[5:8]}/{n[8:12]}-{n[12:14]}'
def cnpj_dv_valido(n):
    if len(n) != 14 or not n[12:].isdigit() or not all(c.isdigit() or 'A' <= c <= 'Z' for c in n[:12]): return False
    if len(set(n)) == 1: return False
    v = lambda ch: ord(ch) - 48
    p1 = [5,4,3,2,9,8,7,6,5,4,3,2]; p2 = [6] + p1
    d1 = sum(v(n[i]) * p1[i] for i in range(12)) % 11; d1 = 0 if d1 < 2 else 11 - d1
    b2 = n[:12] + str(d1)
    d2 = sum(v(b2[i]) * p2[i] for i in range(13)) % 11; d2 = 0 if d2 < 2 else 11 - d2
    return n[12:] == f'{d1}{d2}'
def classifica_documento(n):
    if n.isdigit() and len(n.lstrip('0')) == 11: return ('CPF', 'CPF (11 digitos): esta carga e so de CNPJ')
    if len(n) != 14: return ('CNPJ_INVALIDO', f'tamanho {len(n)} != 14')
    if not cnpj_dv_valido(n): return ('CNPJ_INVALIDO', 'digito verificador invalido')
    return ('OK', '')

def norm_nome(s):
    nfkd = unicodedata.normalize('NFKD', str(s or ''))
    return ' '.join(''.join(c for c in nfkd if not unicodedata.combining(c)).upper().split())
def digitos(s): return re.sub(r'\D', '', s or '')
def telefone_ok(t):
    d = digitos(t); return d == '' or len(d) in (10, 11)
def email_ok(e): return bool(re.fullmatch(r'[\w.+-]+@[\w-]+(\.[\w-]+)+', (e or '').strip()))

# ---- leitura
def read_xlsx(path):
    z = zipfile.ZipFile(path)
    ss = []
    if 'xl/sharedStrings.xml' in z.namelist():
        sx = z.read('xl/sharedStrings.xml').decode('utf8')
        ss = [''.join(html.unescape(t) for t in re.findall(r'<t[^>]*>(.*?)</t>', si, flags=re.S)) for si in re.findall(r'<si>.*?</si>', sx, flags=re.S)]
    x = z.read('xl/worksheets/sheet1.xml').decode('utf8')
    rows = []
    for row in re.findall(r'<row [^>]*>(.*?)</row>', x, flags=re.S):
        d = {}
        for m in re.finditer(r'<c r="([A-Z]+)\d+"([^>]*?)(?:/>|>(.*?)</c>)', row, flags=re.S):
            c, attrs, inner = m.group(1), m.group(2), m.group(3) or ''
            v = re.search(r'<v>(.*?)</v>', inner); t = re.search(r't="(\w+)"', attrs)
            if v:
                val = v.group(1)
                if t and t.group(1) == 's': val = ss[int(val)]
                d[c] = html.unescape(str(val))
            elif '<is>' in inner: d[c] = html.unescape(''.join(re.findall(r'<t[^>]*>(.*?)</t>', inner, flags=re.S)))
        rows.append(d)
    out = []
    for r in rows[1:]:
        vals = [(r.get(chr(65 + i)) or '').strip() for i in range(len(TEMPLATE))]
        if any(vals): out.append(dict(zip(TEMPLATE, vals)))
    return out
def read_csv(path):
    with open(path, encoding='utf-8-sig', newline='') as f:
        rd = csv.reader(f, delimiter=';' if ';' in f.readline() else ','); f.seek(0); rd = csv.reader(f, delimiter=rd.dialect.delimiter)
        rows = list(rd)
    return [dict(zip(TEMPLATE, [c.strip() for c in r[:len(TEMPLATE)]])) for r in rows[1:] if any(c.strip() for c in r)]
def load_records(path):
    if not path: return []
    with open(path, encoding='utf-8-sig') as f:
        head = f.read(1); f.seek(0)
        if head in '{[':
            data = json.load(f)
            if isinstance(data, list): return data
            for k in ('result', 'data'):
                if isinstance(data.get(k), dict) and 'records' in data[k]: return data[k]['records']
            return data.get('records', [])
        return list(csv.DictReader(f))
def g(rec, *names):
    for n in names:
        if n in rec and rec[n] not in (None, ''): return rec[n]
    return ''

# ---- indices da org
def indexa_por_cnpj(recs, campo='DocumentNumber__c'):
    idx = {}
    for r in recs:
        n = normaliza_cnpj(g(r, campo))
        if n: idx.setdefault(n, []).append(r)
    return idx
def indexa_users(recs):
    by_email, by_name = {}, {}
    for r in recs:
        u = {'Id': g(r, 'Id'), 'Name': g(r, 'Name'), 'Email': g(r, 'Email'), 'IsActive': str(g(r, 'IsActive')).lower() in ('true', '1')}
        if u['Email']: by_email[u['Email'].strip().lower()] = u
        by_name.setdefault(norm_nome(u['Name']), []).append(u)
    return by_email, by_name
def resolve_owner(texto, by_email, by_name):
    t = (texto or '').strip()
    if '@' in t:
        u = by_email.get(t.lower())
        if not u: return (None, f'proprietario sem match por e-mail: {t}')
        return (u['Id'], '') if u['IsActive'] else (None, f'proprietario inativo: {t}')
    cands = by_name.get(norm_nome(t), []); ativos = [u for u in cands if u['IsActive']]
    if len(ativos) == 1: return (ativos[0]['Id'], '')
    if not cands: return (None, f'proprietario sem match por nome: {t}')
    if not ativos: return (None, f'proprietario inativo: {t}')
    return (None, f'proprietario ambiguo ({len(ativos)} usuarios ativos com esse nome): {t}')

def processa(rows, leads, accounts, users, online):
    idx_leads = indexa_por_cnpj(leads); idx_acc = indexa_por_cnpj(accounts)
    by_email, by_name = indexa_users(users)
    vistos = {}
    A, B, C = [], [], []
    for i, r in enumerate(rows, 2):
        motivos = []
        n = normaliza_cnpj(r['CNPJ'])
        tipo, m = classifica_documento(n)
        if not r['CNPJ']: motivos.append('CNPJ vazio')
        elif tipo != 'OK': motivos.append(f'{tipo}: {m}')
        for campo, rotulo in (('Proprietario', 'Proprietario do Lead'), ('Origem', 'Origem do Lead'), ('RazaoSocial', 'Razao Social'), ('Sobrenome', 'Sobrenome do contato')):
            if not r[campo]: motivos.append(f'{rotulo} vazio')
        if not r['Telefone1'] and not r['Telefone2'] and not r['Email']: motivos.append('sem telefone e sem e-mail')
        for campo in ('Telefone1', 'Telefone2'):
            if r[campo] and not telefone_ok(r[campo]): motivos.append(f'{campo} com {len(digitos(r[campo]))} digitos: {r[campo]}')
        if r['Email'] and not email_ok(r['Email']): motivos.append(f'e-mail invalido: {r["Email"]}')
        if len(r['RazaoSocial']) > 255: motivos.append('Razao Social > 255')
        if '\n' in r['Origem'] or r['Origem'] != r['Origem'].strip(): motivos.append('Origem com espaco/quebra de linha')
        if n and tipo == 'OK':
            if n in vistos: motivos.append(f'CNPJ duplicado no arquivo (linha {vistos[n]})')
            else: vistos[n] = i
        owner_id = ''
        if online:
            if n in idx_acc:
                a = idx_acc[n][0]
                C.append({**r, 'Linha': i, 'AccountId': g(a, 'Id'), 'ContaNome': g(a, 'Name'), 'ContaOwnerId': g(a, 'OwnerId'),
                          'Motivo': 'CNPJ ja e Conta na org: abrir Oportunidade na Conta (B2B-01), nao Lead'})
                continue
            if n in idx_leads:
                l = idx_leads[n][0]
                motivos.append(f'Lead ja existe na org: {g(l, "Id")} ({g(l, "Status")}, dono {g(l, "OwnerId")})')
            owner_id, mo = resolve_owner(r['Proprietario'], by_email, by_name)
            if mo: motivos.append(mo)
        elif not motivos:
            motivos.append('FORMATO OK; aguarda cruzamento com a org (rode com --leads/--accounts/--users)')
        if motivos:
            B.append({**r, 'Linha': i, 'Motivo': ' | '.join(motivos)})
        else:
            A.append({'SDR__c': r['SDR'], 'OwnerId': owner_id, 'LeadSource': r['Origem'], 'DocumentNumber__c': mascara_cnpj(n),
                      'Company': r['RazaoSocial'], 'FantasyName__c': r['NomeFantasia'], 'FirstName': r['Nome'], 'LastName': r['Sobrenome'],
                      'Title': r['Cargo'], 'Phone': r['Telefone1'], 'MobilePhone': r['Telefone2'], 'Email': r['Email'].lower(),
                      'City': r['Cidade'], 'State': r['UF'], 'Description': r['Observacoes'], 'Status': STATUS_NOVO,
                      'RecordTypeId': RECORDTYPE_LEAD_B2B, 'LegalEntityType__c': LEGAL_ENTITY_PJ})
    return A, B, C

def escreve(out, A, B, C, rows, online):
    os.makedirs(out, exist_ok=True)
    def w(nome, cols, data):
        with open(os.path.join(out, nome), 'w', encoding='utf-8-sig', newline='') as f:
            wr = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore'); wr.writeheader(); wr.writerows(data)
    w('A_leads_inserir.csv', SF_FIELDS, A)
    w('B_retidos.csv', ['Linha', 'Motivo'] + TEMPLATE, B)
    w('C_ja_cliente.csv', ['Linha', 'Motivo', 'AccountId', 'ContaNome', 'ContaOwnerId'] + TEMPLATE, C)
    cnpjs = sorted({normaliza_cnpj(r['CNPJ']) for r in rows if len(normaliza_cnpj(r['CNPJ'])) == 14})
    lista = ','.join(f"'{x}'" for x in cnpjs) + ',' + ','.join(f"'{mascara_cnpj(x)}'" for x in cnpjs)
    donos = sorted({r['Proprietario'] for r in rows if r['Proprietario']})
    emails = ','.join(f"'{d.lower()}'" for d in donos if '@' in d) or "''"; nomes = ','.join(f"'{d}'" for d in donos if '@' not in d) or "''"
    with open(os.path.join(out, 'consultas.soql'), 'w', encoding='utf8') as f:
        f.write(f"-- 1) leads.json\nSELECT Id, Name, Company, DocumentNumber__c, Status, OwnerId FROM Lead WHERE IsConverted = false AND DocumentNumber__c IN ({lista})\n\n")
        f.write(f"-- 2) accounts.json\nSELECT Id, Name, DocumentNumber__c, OwnerId, RecordType.DeveloperName FROM Account WHERE DocumentNumber__c IN ({lista})\n\n")
        f.write(f"-- 3) users.json\nSELECT Id, Name, Email, IsActive FROM User WHERE Email IN ({emails}) OR Name IN ({nomes})\n")
    fmt_ok = sum(1 for b in B if b['Motivo'].startswith('FORMATO OK'))
    rel = [f'Modo: {"ONLINE (cruzado com a org)" if online else "OFFLINE (sem exports da org)"}',
           f'Linhas lidas: {len(rows)}', f'A) aprovadas para inserir: {len(A)}',
           f'B) retidas (erro/duvida): {len(B) - fmt_ok}' + (f'  (+{fmt_ok} com formato OK, aguardando cruzamento com a org)' if fmt_ok else ''),
           f'C) ja cliente (abrir Oportunidade): {len(C)}', '']
    from collections import Counter
    cnt = Counter(m.split(':')[0] for b in B for m in b['Motivo'].split(' | '))
    rel += ['Motivos de retencao:'] + [f'  {v:4d}  {k}' for k, v in cnt.most_common()]
    txt = '\n'.join(rel); print(txt)
    with open(os.path.join(out, 'relatorio.txt'), 'w', encoding='utf8') as f: f.write(txt + '\n')

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--arquivo', required=True); ap.add_argument('--leads'); ap.add_argument('--accounts'); ap.add_argument('--users'); ap.add_argument('--out', default='saida')
    a = ap.parse_args()
    rows = read_xlsx(a.arquivo) if a.arquivo.lower().endswith('.xlsx') else read_csv(a.arquivo)
    online = bool(a.leads and a.accounts and a.users)
    A, B, C = processa(rows, load_records(a.leads), load_records(a.accounts), load_records(a.users), online)
    escreve(a.out, A, B, C, rows, online)
