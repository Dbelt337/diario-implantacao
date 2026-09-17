#!/usr/bin/env python3
"""FASE 1 (leitura): cruza saida/usuarios_solicitados.csv com os JSONs das consultas 12 (por e-mail/username) e 13 (por nome),
classifica em A (existe igual aos modelos), B (existe mas diverge/inativo) e C (nao existe) e gera saida/cruzamento.csv,
saida/C_criar.csv e saida/B_ajustar.csv. Se saida/psa_existentes.json existir, confere tambem o permission set do Romulo.
Alvo (decisao da Priscila, 17/09): perfil da Fernanda (B2B - Backoffice), role do Romulo (B2B - Delivery) e o permission set
do Romulo (App BTP B2B - Visibilidade). Uso: python cruzar.py [--saida saida]"""
import argparse, csv, glob, json, os, re, unicodedata

PERFIL_ALVO = 'B2B - Backoffice'
ROLE_ALVO = 'B2B - Delivery'
PS_ALVO = 'App_BTP_B2B_Visibilidade'
PROFILE_ID = '00eV200000Bj8MTIAZ'
ROLE_ID = '00EV2000001cwdiMAA'
MODELO = dict(TimeZoneSidKey='America/Sao_Paulo', LocaleSidKey='pt_BR', LanguageLocaleKey='pt_BR', EmailEncodingKey='ISO-8859-1')


def norm(s):
    return re.sub(r'\s+', ' ', unicodedata.normalize('NFKD', s or '').encode('ascii', 'ignore').decode().lower()).strip()


def recs(path):
    if not os.path.exists(path):
        return []
    j = json.load(open(path, encoding='utf8'))
    return j.get('result', {}).get('records', []) if j.get('status') == 0 else []


def g(r, *ks):
    for k in ks:
        r = (r or {}).get(k)
    return r


def alias(nome):
    p = norm(nome).split()
    base = (p[0][:1] + p[-1]) if len(p) > 1 else p[0]
    return re.sub(r'[^a-z0-9]', '', base)[:8]


def nick(email):
    return re.sub(r'[^a-z0-9._-]', '', email.split('@')[0])[:40]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--saida', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida'))
    a = ap.parse_args()
    S = a.saida
    sol = list(csv.DictReader(open(os.path.join(S, 'usuarios_solicitados.csv'), encoding='utf-8'), delimiter=';'))
    users = {}
    for f in sorted(glob.glob(os.path.join(S, '1[23]*.json'))):
        for r in recs(f):
            users[r['Id']] = r
    by_email, by_user, by_name = {}, {}, {}
    for u in users.values():
        by_email.setdefault(norm(u.get('Email')), []).append(u)
        by_user.setdefault(norm(u.get('Username')), []).append(u)
        by_name.setdefault(norm(u.get('Name')), []).append(u)
    psa = {}
    for r in recs(os.path.join(S, 'psa_existentes.json')):
        psa.setdefault(r['AssigneeId'], set()).add(g(r, 'PermissionSet', 'Name'))

    out, A, B, C = [], [], [], []
    for s in sol:
        email, nome = norm(s.get('Email')), norm(s.get('Nome'))
        hits = by_email.get(email) or by_user.get(email) or []
        via = 'email' if hits else ''
        if not hits and by_name.get(nome):
            hits, via = by_name[nome], 'nome'
        row = dict(Linha=s.get('Linha', ''), Nome=s.get('Nome'), Cargo=s.get('Cargo', ''), Email=s.get('Email'), Obs=s.get('Obs', ''))
        if not hits:
            row.update(Lista='C', Match='', UserId='', Username='', EmailOrg='', Ativo='', Perfil='', Role='', PS='', Divergencia='nao existe')
            C.append(row)
        else:
            u = hits[0]
            div = []
            if len(hits) > 1:
                div.append('%d usuarios com esse %s' % (len(hits), via))
            if via == 'nome' and norm(u.get('Email')) != email:
                div.append('e-mail na org: %s' % u.get('Email'))
            if not u.get('IsActive'):
                div.append('INATIVO')
            if g(u, 'Profile', 'Name') != PERFIL_ALVO:
                div.append('perfil %s' % g(u, 'Profile', 'Name'))
            if g(u, 'UserRole', 'Name') != ROLE_ALVO:
                div.append('role %s' % (g(u, 'UserRole', 'Name') or '(vazia)'))
            tem_ps = (PS_ALVO in psa.get(u['Id'], set())) if psa else None
            if tem_ps is False:
                div.append('sem PS %s' % PS_ALVO)
            row.update(Lista='B' if div else 'A', Match=via, UserId=u['Id'], Username=u.get('Username'), EmailOrg=u.get('Email'),
                       Ativo=u.get('IsActive'), Perfil=g(u, 'Profile', 'Name'), Role=g(u, 'UserRole', 'Name'),
                       PS=('sim' if tem_ps else 'nao' if tem_ps is False else '?'), Divergencia='; '.join(div))
            (B if div else A).append(row)
        out.append(row)

    cols = ['Lista', 'Linha', 'Nome', 'Cargo', 'Email', 'Match', 'UserId', 'Username', 'EmailOrg', 'Ativo', 'Perfil', 'Role', 'PS', 'Divergencia', 'Obs']
    with open(os.path.join(S, 'cruzamento.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=cols, extrasaction='ignore')
        w.writeheader()
        w.writerows(out)

    usados = set(by_user) | set(by_email)
    cc = ['Linha', 'Nome', 'Cargo', 'Email', 'Username', 'UsernameLivre', 'FirstName', 'LastName', 'Alias', 'CommunityNickname', 'Title',
          'ProfileId', 'UserRoleId', 'TimeZoneSidKey', 'LocaleSidKey', 'LanguageLocaleKey', 'EmailEncodingKey', 'PermissionSet', 'Obs']
    with open(os.path.join(S, 'C_criar.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=cc)
        w.writeheader()
        for r in C:
            p = (r['Nome'] or '').split()
            e = (r['Email'] or '').lower()
            w.writerow(dict(Linha=r['Linha'], Nome=r['Nome'], Cargo=r['Cargo'], Email=e, Username=e,
                            UsernameLivre='nao' if norm(e) in usados else 'sim',
                            FirstName=' '.join(p[:-1]) if len(p) > 1 else '', LastName=p[-1] if p else '',
                            Alias=alias(r['Nome']), CommunityNickname=nick(e), Title=r['Cargo'],
                            ProfileId=PROFILE_ID, UserRoleId=ROLE_ID, PermissionSet=PS_ALVO, Obs=r['Obs'], **MODELO))
    bc = ['Linha', 'Nome', 'Email', 'UserId', 'Username', 'Ativo', 'PerfilAtual', 'RoleAtual', 'PS', 'Divergencia',
          'ProfileId', 'UserRoleId', 'PermissionSet', 'Title', 'Obs']
    with open(os.path.join(S, 'B_ajustar.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=bc)
        w.writeheader()
        for r in B:
            w.writerow(dict(Linha=r['Linha'], Nome=r['Nome'], Email=r['Email'], UserId=r['UserId'], Username=r['Username'],
                            Ativo=r['Ativo'], PerfilAtual=r['Perfil'], RoleAtual=r['Role'], PS=r['PS'], Divergencia=r['Divergencia'],
                            ProfileId=PROFILE_ID, UserRoleId=ROLE_ID, PermissionSet=PS_ALVO, Title=r['Cargo'], Obs=r['Obs']))
    open(os.path.join(S, 'ids_existentes.txt'), 'w').write('\n'.join(sorted({r['UserId'] for r in out if r['UserId']})))
    print('solicitados %d | usuarios encontrados na org %d | A %d | B %d | C %d | PSA carregado: %s'
          % (len(sol), len(users), len(A), len(B), len(C), 'sim' if psa else 'nao'))
    for r in out:
        print(r['Lista'], '|', r['Linha'], '|', r['Nome'], '|', r['Email'], '|', r['Match'] or '-', '|', r['Perfil'] or '-', '|',
              r['Role'] or '-', '|', r['Ativo'], '|', r['Divergencia'])


if __name__ == '__main__':
    main()
