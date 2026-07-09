#!/usr/bin/env python3
"""Self-test do pipeline de carga MG. Nao depende de org nem da planilha real.
Roda: python3 test_mg_load.py"""
import io
import mg_load as m


def test_dv():
    assert m.cnpj_dv_valido("05262608000108")
    assert m.cnpj_dv_valido("11393866000126")
    # placeholder e DV invalidos da instrucao
    assert not m.cnpj_dv_valido("99999999992103")
    assert not m.cnpj_dv_valido("59896558000167")
    assert not m.cnpj_dv_valido("60239950000122")


def test_classifica():
    assert m.classifica_documento("11393866000126")[0] == "OK"
    assert m.classifica_documento(m.normaliza_cnpj("75209462668"))[0] == "CPF"
    # CPF zero-fillado ate 14 na origem
    assert m.classifica_documento("00075209462668")[0] == "CPF"
    assert m.classifica_documento("59896558000167")[0] == "CNPJ_INVALIDO"


def test_mascara_e_norm():
    assert m.mascara_cnpj("11393866000126") == "11.393.866/0001-26"
    # crossmatch tolerante a formato: mascarado e sem mascara -> mesma chave
    assert m.normaliza_cnpj("11.393.866/0001-26") == m.normaliza_cnpj("11393866000126")


def test_owner_resolucao():
    users = [
        {"Id": "005A", "Name": "Euler Rosa Miguel", "Email": "euler@x.com", "IsActive": "true"},
        {"Id": "005B", "Name": "Ambiguo Nome", "Email": "", "IsActive": "true"},
        {"Id": "005C", "Name": "Ambiguo Nome", "Email": "", "IsActive": "true"},
        {"Id": "005D", "Name": "Inativo User", "Email": "inativo@x.com", "IsActive": "false"},
    ]
    be, bn = m.indexa_users(users)
    # email bate -> usa
    assert m.resolve_owner("qualquer", "euler@x.com", be, bn)[0] == "005A"
    # nome ambiguo -> retido
    assert m.resolve_owner("Ambiguo Nome", "", be, bn)[0] is None
    # inativo -> retido
    assert m.resolve_owner("Inativo User", "inativo@x.com", be, bn)[0] is None
    # sem match -> retido
    assert m.resolve_owner("Ninguem", "", be, bn)[0] is None


def test_pipeline_end_to_end(tmp_csv):
    users = [{"Id": "005OWN", "Name": "Dono Um", "Email": "dono@x.com", "IsActive": "true"}]
    # conta existente em formato SEM mascara (estoque misto) deve casar a linha mascarada
    accounts = [{"Id": "001EXIST", "Name": "Empresa Existente",
                 "DocumentNumber__c": "11393866000126", "OwnerId": "005OLD",
                 "RecordType": {"DeveloperName": "LegalEntity_B2B"}}]
    A, B, C, st = m.processa(tmp_csv, accounts, users)
    # 1 existe (update), 1 nova (insert), 1 invalida (retida)
    assert st == {"existe": 1, "nova": 1, "retida": 1, "total": 3}
    # update preserva Id, seta owner+cluster, NAO carrega Name/DocumentNumber
    assert A[0]["Id"] == "001EXIST" and A[0]["OwnerId"] == "005OWN"
    assert "Name" not in A[0] and "DocumentNumber__c" not in A[0]
    assert A[0]["ClusterManual__c"] == "SEMPRE"
    # insert com mascara, recordtype e cluster corretos
    assert B[0]["DocumentNumber__c"] == "20.520.862/0001-52"
    assert B[0]["RecordTypeId"] == m.RECORDTYPE_LEGALENTITY_B2B
    assert B[0]["ClusterManual__c"] == "SEMPRE"
    # invalido retido
    assert C[0]["CNPJ_NORMALIZADO"] == "99999999992103"


def _make_tmp_csv(path):
    import csv
    rows = [
        # existente (sera update): mesmo CNPJ do account, mas com mascara na planilha
        {"CNPJ_NORMALIZADO": "11393866000126", "RAZAO_SOCIAL": "Empresa Existente Planilha",
         "RESPONSAVEL_NOME": "Dono Um", "RESPONSAVEL_EMAIL": "dono@x.com"},
        # nova (sera insert)
        {"CNPJ_NORMALIZADO": "20520862000152", "RAZAO_SOCIAL": "Empresa Nova",
         "RESPONSAVEL_NOME": "Dono Um", "RESPONSAVEL_EMAIL": "dono@x.com"},
        # invalida (retida)
        {"CNPJ_NORMALIZADO": "99999999992103", "RAZAO_SOCIAL": "Fundo Placeholder",
         "RESPONSAVEL_NOME": "Dono Um", "RESPONSAVEL_EMAIL": "dono@x.com"},
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


if __name__ == "__main__":
    import tempfile, os, traceback
    tmp = os.path.join(tempfile.gettempdir(), "mg_test.csv")
    _make_tmp_csv(tmp)
    failed = 0
    for name, fn in sorted(globals().items()):
        if not name.startswith("test_"):
            continue
        try:
            fn(tmp) if fn.__code__.co_argcount else fn()
            print(f"ok   {name}")
        except Exception:
            failed += 1
            print(f"FAIL {name}")
            traceback.print_exc()
    print("\nRESULTADO:", "TODOS OK" if not failed else f"{failed} FALHA(S)")
    raise SystemExit(1 if failed else 0)
