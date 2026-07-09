#!/usr/bin/env python3
"""
Carga de Contas MG (cluster SEMPRE) - BrasilTecPar.

DRY_RUN por padrao. NAO faz DML. Le a planilha + dois exports de SOQL
(contas existentes e usuarios) e produz, de forma deterministica:

  - Arquivo A (UPDATE existentes)   -> saida/A_update.csv
  - Arquivo B (INSERT/UPSERT novas) -> saida/B_insert_upsert.csv
  - Arquivo C (conflitos/retidos)   -> saida/C_retidos.csv
  - Relatorio DRY_RUN               -> stdout + saida/relatorio.txt

Como obter os exports de SOQL (rodar na SANDBOX):

  sf data query -o <sandbox> --json -q \
    "SELECT Id, Name, DocumentNumber__c, ExternalId__c, OwnerId, RecordType.DeveloperName FROM Account \
     WHERE DocumentNumber__c IN (<mascarados>) OR DocumentNumber__c IN (<sem_mascara>)" \
    > accounts.json

  sf data query -o <sandbox> --json -q \
    "SELECT Id, Name, Email, IsActive, UserRole.DeveloperName FROM User \
     WHERE Email IN (<emails>) OR Name IN (<nomes>)" \
    > users.json

Uso:
  python3 mg_load.py --csv contas_MG_415_limpo.csv \
      --accounts accounts.json --users users.json --out saida/

Aceita accounts/users como JSON (saida `sf ... --json`, com data.records)
ou CSV plano com as mesmas colunas (RecordType.DeveloperName -> coluna
RecordType_DeveloperName; UserRole.DeveloperName -> UserRole_DeveloperName).
"""

import argparse
import csv
import json
import os
import sys
import unicodedata

# --- Constantes de negocio (instrucao) ---
RECORDTYPE_LEGALENTITY_B2B = "012V2000002CjppIAC"
CLUSTER = "SEMPRE"
REGIONAL = "MG"
MANAGEMENT = "MG"

# Excecoes explicitas fornecidas na instrucao (autoritativas).
# CNPJ normalizado -> motivo de retencao.
EXCECOES_NOME_DIVERGENTE = {
    "18715391000196": "Nome divergente (MUNICIPIO DE BETIM vs CERSAM CITROLANDIA) - revisar Ana Luiza",
    "38486817000194": "Nome divergente (FUNDO INVESTIMENTO MG vs BDMG) - revisar Ana Luiza",
}
# Acento-only: escolher grafia acentuada. Nao retem, apenas normaliza o nome.
EXCECOES_ACENTO = {"21154554000113", "08715327000151", "20971057000145"}


def strip_accentless(s):
    """Remove pontuacao de documento, preserva letras e digitos, uppercase."""
    if s is None:
        return ""
    out = []
    for ch in str(s):
        if ch.isalnum():
            out.append(ch)
    return "".join(out).upper()


def normaliza_cnpj(doc):
    """Normaliza para 14 posicoes (sem mascara, uppercase). zfill defensivo
    apenas quando todo numerico e curto (perda de zero a esquerda)."""
    s = strip_accentless(doc)
    # zfill defensivo apenas para 12-13 digitos (zero a esquerda perdido pelo
    # Excel). NAO zfill 11 digitos: isso e CPF e precisa ser detectado como tal.
    if s.isdigit() and 12 <= len(s) < 14:
        s = s.zfill(14)
    return s


def mascara_cnpj(norm):
    """XX.XXX.XXX/XXXX-XX a partir do normalizado de 14 posicoes."""
    s = norm.upper()
    return f"{s[0:2]}.{s[2:5]}.{s[5:8]}/{s[8:12]}-{s[12:14]}"


def _char_val(ch):
    """Valor para calculo de DV. Numerico = int; CNPJ alfanumerico 2026
    usa ASCII-48 (0-9 -> 0-9, A-Z -> 17-42)."""
    return ord(ch) - 48


def cnpj_dv_valido(norm):
    """Valida os 2 digitos verificadores de um CNPJ de 14 posicoes.
    Aceita 12 primeiras alfanumericas [0-9A-Z] e DV numerico."""
    if len(norm) != 14:
        return False
    corpo, dv = norm[:12], norm[12:]
    if not dv.isdigit():
        return False
    if not all(c.isdigit() or ("A" <= c <= "Z") for c in corpo):
        return False
    pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    soma1 = sum(_char_val(corpo[i]) * pesos1[i] for i in range(12))
    d1 = soma1 % 11
    d1 = 0 if d1 < 2 else 11 - d1
    base2 = corpo + str(d1)
    soma2 = sum(_char_val(base2[i]) * pesos2[i] for i in range(13))
    d2 = soma2 % 11
    d2 = 0 if d2 < 2 else 11 - d2
    return dv == f"{d1}{d2}"


def classifica_documento(norm):
    """Retorna ('CPF'|'CNPJ_INVALIDO'|'OK', motivo)."""
    if len(norm) == 11 and norm.isdigit():
        return ("CPF", "11 digitos = CPF, nao CNPJ")
    # CPF que a origem zerou a esquerda ate 14 (ex.: 000+11 digitos)
    if norm.isdigit() and len(norm.lstrip("0")) == 11:
        return ("CPF", "11 digitos (com zero-fill na origem) = CPF, nao CNPJ")
    if len(norm) != 14:
        return ("CNPJ_INVALIDO", f"tamanho {len(norm)} != 14")
    if not cnpj_dv_valido(norm):
        return ("CNPJ_INVALIDO", "DV invalido")
    return ("OK", "")


def _load_records(path):
    """Le JSON (sf --json: {result:{records:[...]}} ou {records:[...]} ou
    lista) ou CSV plano. Retorna lista de dicts."""
    with open(path, encoding="utf-8-sig") as f:
        head = f.read(1)
        f.seek(0)
        if head == "{" or head == "[":
            data = json.load(f)
            if isinstance(data, list):
                return data
            for key in ("result", "data"):
                if isinstance(data.get(key), dict) and "records" in data[key]:
                    return data[key]["records"]
            if "records" in data:
                return data["records"]
            raise ValueError(f"{path}: JSON sem 'records'")
        return list(csv.DictReader(f))


def _get(rec, *names):
    """Pega o primeiro campo presente; achata RecordType.DeveloperName
    tanto no formato aninhado (sf) quanto plano (CSV)."""
    for n in names:
        if n in rec and rec[n] not in (None, ""):
            return rec[n]
    # aninhado sf: RecordType -> {DeveloperName: ...}
    if "RecordType" in rec and isinstance(rec["RecordType"], dict):
        v = rec["RecordType"].get("DeveloperName")
        if v and "RecordType_DeveloperName" in names:
            return v
    if "UserRole" in rec and isinstance(rec["UserRole"], dict):
        v = rec["UserRole"].get("DeveloperName")
        if v and "UserRole_DeveloperName" in names:
            return v
    return ""


def indexa_contas(accounts):
    """Mapa cnpj_normalizado -> conta do org (dedup por Id)."""
    idx = {}
    for rec in accounts:
        norm = normaliza_cnpj(_get(rec, "DocumentNumber__c"))
        if not norm:
            continue
        idx[norm] = {
            "Id": _get(rec, "Id"),
            "Name": _get(rec, "Name"),
            "DocumentNumber__c": _get(rec, "DocumentNumber__c"),
            "OwnerId": _get(rec, "OwnerId"),
            "RecordType": _get(rec, "RecordType_DeveloperName"),
        }
    return idx


def resolve_owner(nome, email, users_by_email, users_by_name):
    """Email bate -> usa. So nome unico e ativo -> usa. Senao retido.
    Retorna (owner_id | None, motivo_se_retido)."""
    e = (email or "").strip().lower()
    if e and e in users_by_email:
        u = users_by_email[e]
        if not u["IsActive"]:
            return (None, f"owner por email inativo: {email}")
        return (u["Id"], "")
    n = _norm_nome(nome)
    cands = users_by_name.get(n, [])
    ativos = [u for u in cands if u["IsActive"]]
    if len(ativos) == 1:
        return (ativos[0]["Id"], "")
    if len(cands) == 0:
        return (None, f"owner sem match: {nome} / {email}")
    if len(ativos) == 0:
        return (None, f"owner inativo: {nome}")
    return (None, f"owner ambiguo ({len(ativos)} ativos): {nome}")


def _norm_nome(s):
    if not s:
        return ""
    nfkd = unicodedata.normalize("NFKD", str(s))
    sem = "".join(c for c in nfkd if not unicodedata.combining(c))
    return " ".join(sem.upper().split())


def indexa_users(users):
    by_email, by_name = {}, {}
    for rec in users:
        u = {
            "Id": _get(rec, "Id"),
            "Name": _get(rec, "Name"),
            "Email": _get(rec, "Email"),
            "IsActive": str(_get(rec, "IsActive")).lower() in ("true", "1"),
        }
        if u["Email"]:
            by_email[u["Email"].strip().lower()] = u
        by_name.setdefault(_norm_nome(u["Name"]), []).append(u)
    return by_email, by_name


def processa(csv_path, accounts, users):
    idx_contas = indexa_contas(accounts)
    users_by_email, users_by_name = indexa_users(users)

    A_update, B_insert, C_retidos = [], [], []
    stats = {"existe": 0, "nova": 0, "retida": 0, "total": 0}

    with open(csv_path, encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            stats["total"] += 1
            norm = normaliza_cnpj(
                row.get("CNPJ_NORMALIZADO") or row.get("CNPJ_MASCARADO")
            )
            nome = (row.get("RAZAO_SOCIAL") or "").strip()
            resp_nome = (row.get("RESPONSAVEL_NOME") or "").strip()
            resp_email = (row.get("RESPONSAVEL_EMAIL") or "").strip()

            # 1) Documento invalido (CPF / DV) -> retido antes de tudo
            tipo, motivo_doc = classifica_documento(norm)
            if tipo != "OK":
                stats["retida"] += 1
                C_retidos.append(_ret(norm, nome, f"{tipo}: {motivo_doc}"))
                continue

            # 2) Nome divergente conhecido -> retido
            if norm in EXCECOES_NOME_DIVERGENTE:
                stats["retida"] += 1
                C_retidos.append(_ret(norm, nome, EXCECOES_NOME_DIVERGENTE[norm]))
                continue

            # 3) Resolver owner (nunca chutar)
            owner_id, motivo_owner = resolve_owner(
                resp_nome, resp_email, users_by_email, users_by_name
            )
            if owner_id is None:
                stats["retida"] += 1
                C_retidos.append(_ret(norm, nome, motivo_owner))
                continue

            # 4) Crossmatch existe vs nova
            existente = idx_contas.get(norm)
            if existente:
                stats["existe"] += 1
                A_update.append({
                    "Id": existente["Id"],
                    "OwnerId": owner_id,
                    # Regional/Management/ClusterManual apenas se vazios no org
                    # (nao sabemos os valores atuais desses campos aqui;
                    #  preencher e idempotente e atravessa ValidaPreenchimentoCluster)
                    "Regional__c": REGIONAL,
                    "Management__c": MANAGEMENT,
                    "ClusterManual__c": CLUSTER,
                })
            else:
                stats["nova"] += 1
                B_insert.append({
                    "DocumentNumber__c": mascara_cnpj(norm),
                    "Name": nome,
                    "OwnerId": owner_id,
                    "RecordTypeId": RECORDTYPE_LEGALENTITY_B2B,
                    "Regional__c": REGIONAL,
                    "Management__c": MANAGEMENT,
                    "ClusterManual__c": CLUSTER,
                })

    return A_update, B_insert, C_retidos, stats


def _ret(norm, nome, motivo):
    return {"CNPJ_NORMALIZADO": norm, "RAZAO_SOCIAL": nome, "MOTIVO": motivo}


def _write_csv(path, rows, fieldnames):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for r in rows:
            w.writerow(r)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", required=True)
    ap.add_argument("--accounts", required=True, help="export SOQL Account (json/csv)")
    ap.add_argument("--users", required=True, help="export SOQL User (json/csv)")
    ap.add_argument("--out", default="saida/")
    args = ap.parse_args()

    accounts = _load_records(args.accounts)
    users = _load_records(args.users)
    A, B, C, stats = processa(args.csv, accounts, users)

    _write_csv(os.path.join(args.out, "A_update.csv"), A,
               ["Id", "OwnerId", "Regional__c", "Management__c", "ClusterManual__c"])
    _write_csv(os.path.join(args.out, "B_insert_upsert.csv"), B,
               ["DocumentNumber__c", "Name", "OwnerId", "RecordTypeId",
                "Regional__c", "Management__c", "ClusterManual__c"])
    _write_csv(os.path.join(args.out, "C_retidos.csv"), C,
               ["CNPJ_NORMALIZADO", "RAZAO_SOCIAL", "MOTIVO"])

    linhas = [
        "=== RELATORIO DRY_RUN — Carga MG (SEMPRE) ===",
        f"Atualizadas (UPDATE por Id) : {stats['existe']}",
        f"Criadas (INSERT/UPSERT)     : {stats['nova']}",
        f"Retidas/Conflito            : {stats['retida']}",
        f"Total processado            : {stats['total']}",
        f"Soma (deve == total)        : {stats['existe'] + stats['nova'] + stats['retida']}",
        "",
        "Arquivo A -> Action=Update    (Id, OwnerId, Regional__c, Management__c, ClusterManual__c)",
        "Arquivo B -> Action=Upsert    (chave externa DocumentNumber__c; RecordTypeId=" + RECORDTYPE_LEGALENTITY_B2B + ")",
        "Arquivo C -> revisao humana (Ana Luiza)",
        "",
        "Execucao: threads=1; testar 2 linhas por arquivo antes do lote.",
    ]
    rel = "\n".join(linhas)
    print(rel)
    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "relatorio.txt"), "w", encoding="utf-8") as f:
        f.write(rel + "\n")


if __name__ == "__main__":
    main()
