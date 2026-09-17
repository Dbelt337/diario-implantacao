#!/usr/bin/env python3
"""Normaliza a planilha "Acesso Salesforce" (colunas Nome, Cargo, Email) e gera o que a sessao conectada precisa
para a FASE 1 (leitura): saida/usuarios_solicitados.csv, saida/consultas.soql (User por e-mail em lotes de 250,
usuarios-modelo, licencas, roles, permission sets) e saida/relatorio_planilha.txt.
Uso: python normalizar_planilha.py Acesso_Salesforce_Delivery_3.xlsx --modelo-perfil "Fernanda Ientzn da Rosa" --modelo-role "Romulo Gustavo Ramos da Silva"
Nao grava nada na org. Reaproveita o leitor de xlsx de tools/lead_load."""
import argparse, collections, csv, os, re, sys, unicodedata
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lead_load'))
from gerar_template_leads import read_xlsx_rows  # noqa: E402

LOTE = 250
EMAIL_RE = re.compile(r'^[a-z0-9._+-]+@[a-z0-9.-]+\.[a-z]{2,}$')

def limpa(s):
    return re.sub(r'\s+', ' ', (s or '').replace('\r', ' ').replace('\n', ' ')).strip()

def nome_titulo(s):
    """CAIXA ALTA -> Titulo (preposicoes minusculas). Nomes ja em caixa mista ficam como estao."""
    if s != s.upper():
        return s
    peq = {'da', 'de', 'do', 'das', 'dos', 'e'}
    return ' '.join(w.lower() if w.lower() in peq else w.capitalize() for w in s.lower().split())

def sem_acento(s):
    return unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()

def soql_in(vals):
    return ', '.join("'" + v.replace("'", "\\'") + "'" for v in vals)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('xlsx')
    ap.add_argument('--modelo-perfil', default='Fernanda Ientzn da Rosa', help='usuario cujo Profile sera copiado')
    ap.add_argument('--modelo-role', default='Romulo Gustavo Ramos da Silva', help='usuario cuja Role/permissoes servem de referencia')
    ap.add_argument('--saida', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida'))
    a = ap.parse_args()
    os.makedirs(a.saida, exist_ok=True)

    rows = read_xlsx_rows(a.xlsx)
    cab = {k: limpa(v).lower() for k, v in rows[0].items()}
    col = {v: k for k, v in cab.items()}
    for c in ('nome', 'email'):
        if c not in col:
            sys.exit('coluna "%s" nao encontrada no cabecalho %s' % (c, cab))
    ccargo = col.get('cargo')

    itens, avisos = [], []
    vistos = {}
    for i, r in enumerate(rows[1:], start=2):
        nome, email = limpa(r.get(col['nome'], '')), limpa(r.get(col['email'], '')).lower()
        cargo = limpa(r.get(ccargo, '')) if ccargo else ''
        if not nome and not email:
            continue
        obs = []
        if not email:
            obs.append('SEM E-MAIL')
        elif not EMAIL_RE.match(email):
            obs.append('E-MAIL INVALIDO')
        if not cargo:
            obs.append('sem cargo')
        if email in vistos:
            obs.append('duplicado no arquivo (linha %d)' % vistos[email])
        elif email:
            vistos[email] = i
        if r.get(col['nome'], '') != nome or r.get(col['email'], '').lower() != email:
            obs.append('espacos/quebras removidos')
        if nome != nome_titulo(nome):
            obs.append('nome em caixa alta')
        if '.t@' in email:
            obs.append('e-mail .t (temporario/terceiro?)')
        itens.append(dict(Linha=i, Nome=nome_titulo(nome), NomeOriginal=nome, Cargo=cargo, Email=email,
                          Dominio=email.split('@')[-1] if '@' in email else '', Obs='; '.join(obs)))

    with open(os.path.join(a.saida, 'usuarios_solicitados.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['Linha', 'Nome', 'NomeOriginal', 'Cargo', 'Email', 'Dominio', 'Obs'], delimiter=';')
        w.writeheader(); w.writerows(itens)

    emails = [x['Email'] for x in itens if x['Email'] and 'INVALIDO' not in x['Obs']]
    nomes = [x['Nome'] for x in itens]
    modelos = [a.modelo_perfil, a.modelo_role]
    q = []
    q.append("-- 1. usuarios-modelo (perfil = %s; role/permissoes = %s)" % (a.modelo_perfil, a.modelo_role))
    q.append("SELECT Id, Name, Username, Email, IsActive, Profile.Name, Profile.UserLicense.Name, UserRole.Name, UserRole.DeveloperName, UserType, Title, Department, CompanyName, TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, EmailEncodingKey, UserPermissionsSupportUser, UserPermissionsKnowledgeUser, UserPermissionsMarketingUser, UserPermissionsSFContentUser, FederationIdentifier, LastLoginDate FROM User WHERE Name IN (%s)" % soql_in(modelos))
    q.append("-- 2. permission sets e grupos dos modelos (PermissionSet.IsOwnedByProfile = false sao os atribuidos de fato)")
    q.append("SELECT Assignee.Name, PermissionSet.Name, PermissionSet.Label, PermissionSet.IsOwnedByProfile, PermissionSet.License.Name, PermissionSetGroupId, PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE Assignee.Name IN (%s) ORDER BY Assignee.Name, PermissionSet.Label" % soql_in(modelos))
    q.append("SELECT Assignee.Name, PermissionSetLicense.MasterLabel, PermissionSetLicense.DeveloperName FROM PermissionSetLicenseAssign WHERE Assignee.Name IN (%s)" % soql_in(modelos))
    q.append("SELECT UserOrGroup.Name, Group.Name, Group.Type, Group.DeveloperName FROM GroupMember WHERE UserOrGroupId IN (SELECT Id FROM User WHERE Name IN (%s))" % soql_in(modelos))
    q.append("SELECT User.Name, PackageLicense.NamespacePrefix FROM UserPackageLicense WHERE UserId IN (SELECT Id FROM User WHERE Name IN (%s))" % soql_in(modelos))
    q.append("-- 3. licencas disponiveis (User, permission set license, pacotes gerenciados)")
    q.append("SELECT Name, MasterLabel, TotalLicenses, UsedLicenses, Status FROM UserLicense WHERE Status = 'Active' ORDER BY MasterLabel")
    q.append("SELECT MasterLabel, DeveloperName, TotalLicenses, UsedLicenses, Status FROM PermissionSetLicense WHERE Status = 'Active' ORDER BY MasterLabel")
    q.append("SELECT NamespacePrefix, AllowedLicenses, UsedLicenses, Status FROM PackageLicense ORDER BY NamespacePrefix")
    q.append("-- 4. roles e perfis candidatos")
    q.append("SELECT Id, Name, DeveloperName, ParentRole.Name, PortalType FROM UserRole WHERE PortalType = 'None' ORDER BY Name")
    q.append("SELECT Id, Name, UserLicense.Name, UserType FROM Profile ORDER BY Name")
    q.append("SELECT Profile.Name, UserRole.Name, COUNT(Id) n FROM User WHERE IsActive = true GROUP BY Profile.Name, UserRole.Name ORDER BY Profile.Name")
    q.append("-- 5. quem da planilha ja existe na org (por e-mail, lotes de %d; conferir tambem por Username e por nome)" % LOTE)
    for k in range(0, len(emails), LOTE):
        q.append("SELECT Id, Name, Username, Email, IsActive, Profile.Name, UserRole.Name, UserType, Title, LastLoginDate, CreatedDate, CreatedBy.Name FROM User WHERE Email IN (%s) OR Username IN (%s)" % (soql_in(emails[k:k + LOTE]), soql_in(emails[k:k + LOTE])))
    for k in range(0, len(nomes), LOTE):
        q.append("SELECT Id, Name, Username, Email, IsActive, Profile.Name, UserRole.Name FROM User WHERE Name IN (%s)" % soql_in(nomes[k:k + LOTE]))
    q.append("-- 6. historico: quem foi criado com o perfil da modelo nos ultimos 90 dias (responde 'essa planilha e nova?')")
    q.append("SELECT Name, Email, IsActive, UserRole.Name, CreatedDate, CreatedBy.Name FROM User WHERE Profile.Id IN (SELECT ProfileId FROM User WHERE Name = '%s') AND CreatedDate = LAST_N_DAYS:90 ORDER BY CreatedDate DESC" % a.modelo_perfil.replace("'", "\\'"))
    with open(os.path.join(a.saida, 'consultas.soql'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(q) + '\n')
    # um arquivo por consulta, porque sf data query --file aceita uma consulta por arquivo
    d = os.path.join(a.saida, 'consultas'); os.makedirs(d, exist_ok=True)
    n = 0
    for linha in q:
        if linha.startswith('--'):
            continue
        n += 1
        with open(os.path.join(d, '%02d.soql' % n), 'w', encoding='utf-8') as f:
            f.write(linha + '\n')

    cargos = collections.Counter(x['Cargo'] or '(sem cargo)' for x in itens)
    doms = collections.Counter(x['Dominio'] for x in itens)
    rel = ['Planilha: %s' % os.path.basename(a.xlsx), 'Pessoas: %d' % len(itens), 'Dominios: %s' % dict(doms),
           'Com observacao: %d' % sum(1 for x in itens if x['Obs']), '', 'Cargos:']
    rel += ['  %3d  %s' % (v, k) for k, v in cargos.most_common()]
    rel += ['', 'Observacoes por linha:'] + ['  linha %d  %s  %s  -> %s' % (x['Linha'], x['Nome'], x['Email'], x['Obs']) for x in itens if x['Obs']]
    rel += ['', 'Consultas geradas: %d (saida/consultas/NN.soql)' % n]
    open(os.path.join(a.saida, 'relatorio_planilha.txt'), 'w', encoding='utf-8').write('\n'.join(rel) + '\n')
    print('\n'.join(rel))

if __name__ == '__main__':
    main()
