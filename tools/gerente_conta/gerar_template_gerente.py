#!/usr/bin/env python3
"""
Template de alteracao do "Gerente da conta" (Account.AccountManager__c) e do "Gerente da Conta" da oportunidade
(Opportunity.ManagerAccount__c, aprovador da etapa comercial). Nunca altera dono (OwnerId).

  python3 gerar_template_gerente.py                                   -> Template_Alterar_Gerente_Conta.xlsx (exemplos)
  python3 gerar_template_gerente.py --contas Contas.xlsx --opps Opps.xlsx --gerente "Nome Completo do Gerente" --saida X.xlsx
       despeja as planilhas do comercial (formatos "Contas_Alterar_Gerente" e "Oportunidade_para_Aprovacao") no template.

Abas: Contas, Oportunidades (com colunas de conferencia por formula), Listas, Instrucoes. Escreve OOXML direto (sem openpyxl).
"""
import argparse, os, sys, zipfile
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lead_load'))
from gerar_template_leads import c_str, c_f, sheet_xml, STYLES, col, digits_formula, dv, read_xlsx_rows

NROWS = 2000
COLS_C = [('CNPJ da conta *', 20, '16.939.019/0008-04'), ('Nome da conta (conferência)', 44, 'DIOCESE DE SETE LAGOAS'),
          ('Proprietário atual (informativo)', 28, 'Erica Rosena De Aguilar'), ('Gerente atual (informativo)', 28, 'Matheus Nardoni Benevides'),
          ('Novo gerente da conta *', 30, 'Marcelo Barbosa De Carvalho'), ('Observação', 30, '')]
CHK_C = [('CNPJ (só dígitos)', 16), ('CNPJ válido?', 22), ('Duplicado?', 12), ('Obrigatórios?', 30), ('LINHA', 10)]
COLS_O = [('Nome da conta *', 40, 'PATRUS TRANSPORTES LTDA'), ('Nome da oportunidade *', 44, 'PATRUS_São José dos Pinhais/PR'),
          ('Proprietário da oportunidade (informativo)', 30, 'Wills Kenio Bento Da Silva'), ('Fase (informativo)', 22, 'Aprovação comercial'),
          ('Novo gerente da conta *', 30, 'Marcelo Barbosa De Carvalho'), ('Urgência / motivo', 34, 'Aguardando aprovação comercial')]
CHK_O = [('Duplicado?', 12), ('Obrigatórios?', 30), ('LINHA', 10)]
GERENTES = ['Marcelo Barbosa De Carvalho', 'Rodrigo Nascimento Piccolo', 'Eduardo Alessandro Afonso', 'Matheus Nardoni Benevides']
REQ_C = {0, 4}; REQ_O = {0, 1, 4}

def f_contas(r):
    A, B, E, G = f'A{r}', f'B{r}', f'E{r}', f'G{r}'
    d1 = dv(G, 12, [5,4,3,2,9,8,7,6,5,4,3,2]); d2 = dv(G, 13, [6,5,4,3,2,9,8,7,6,5,4,3,2])
    fG = f'IF({A}="","",{digits_formula(A)})'
    fH = (f'IF({G}="","",IF(LEN({G})<>14,"ERRO: "&LEN({G})&" dígitos",IF(NOT(ISNUMBER(VALUE({G}))),"ERRO: não numérico",'
          f'IF(AND(VALUE(MID({G},13,1))={d1},VALUE(MID({G},14,1))={d2}),"OK","AVISO: dígito verificador (conferir na org)"))))')
    fI = f'IF({G}="","",IF(COUNTIF($G$2:$G${NROWS+1},{G})>1,"DUPLICADO","OK"))'
    fJ = f'IF(COUNTA(A{r}:F{r})=0,"",IF(AND({A}<>"",{E}<>""),"OK","ERRO: faltam "&IF({A}="","CNPJ; ","")&IF({E}="","Novo gerente; ","")))'
    fK = f'IF(COUNTA(A{r}:F{r})=0,"",IF(AND(LEFT(H{r},4)<>"ERRO",{f"I{r}"}="OK",J{r}="OK"),"OK","REVISAR"))'
    return [fG, fH, fI, fJ, fK]

def f_opps(r):
    A, B, E = f'A{r}', f'B{r}', f'E{r}'
    fG = f'IF(AND({A}="",{B}=""),"",IF(COUNTIFS($A$2:$A${NROWS+1},{A},$B$2:$B${NROWS+1},{B})>1,"DUPLICADO","OK"))'
    fH = f'IF(COUNTA(A{r}:F{r})=0,"",IF(AND({A}<>"",{B}<>"",{E}<>""),"OK","ERRO: faltam "&IF({A}="","Conta; ","")&IF({B}="","Oportunidade; ","")&IF({E}="","Novo gerente; ","")))'
    fI = f'IF(COUNTA(A{r}:F{r})=0,"",IF(AND(G{r}="OK",H{r}="OK"),"OK","REVISAR"))'
    return [fG, fH, fI]

def build_sheet(cols, chk, req, ffun, data, gerente_col, tabcolor):
    nd = len(cols); last = NROWS + 1
    rows = [(1, [c_str(f'{col(i+1)}1', h, 2 if i in req else 1) for i, (h, _, _) in enumerate(cols)] + [c_str(f'{col(nd+i+1)}1', h, 3) for i, (h, _) in enumerate(chk)])]
    for r in range(2, last + 1):
        vals = data[r - 2] if r - 2 < len(data) else [''] * nd
        cells = [c_str(f'{col(i+1)}{r}', vals[i] if i < len(vals) else '', 5 if i in req else 4) for i in range(nd)]
        cells += [c_f(f'{col(nd+i+1)}{r}', f, 6) for i, f in enumerate(ffun(r))]
        rows.append((r, cells))
    widths = [(i + 1, w) for i, (_, w, _) in enumerate(cols)] + [(nd + i + 1, w) for i, (_, w) in enumerate(chk)]
    pc, vc = col(nd + 1), col(nd + len(chk))
    cf = (f'<conditionalFormatting sqref="{pc}2:{vc}{last}"><cfRule type="containsText" dxfId="0" priority="1" operator="containsText" text="ERRO"><formula>NOT(ISERROR(SEARCH("ERRO",{pc}2)))</formula></cfRule>'
          f'<cfRule type="containsText" dxfId="0" priority="2" operator="containsText" text="DUPLICADO"><formula>NOT(ISERROR(SEARCH("DUPLICADO",{pc}2)))</formula></cfRule>'
          f'<cfRule type="containsText" dxfId="0" priority="3" operator="containsText" text="REVISAR"><formula>NOT(ISERROR(SEARCH("REVISAR",{pc}2)))</formula></cfRule>'
          f'<cfRule type="containsText" dxfId="2" priority="4" operator="containsText" text="AVISO"><formula>NOT(ISERROR(SEARCH("AVISO",{pc}2)))</formula></cfRule></conditionalFormatting>'
          f'<conditionalFormatting sqref="{vc}2:{vc}{last}"><cfRule type="cellIs" dxfId="1" priority="5" operator="equal"><formula>"OK"</formula></cfRule></conditionalFormatting>')
    g = col(gerente_col)
    dvx = (f'<dataValidations count="1"><dataValidation type="list" allowBlank="1" showErrorMessage="1" errorTitle="Novo gerente" '
           f'error="Use o nome completo do usuário Salesforce como está na aba Listas (ou inclua o nome lá)." sqref="{g}2:{g}{last}"><formula1>Listas!$A$2:$A$50</formula1></dataValidation></dataValidations>')
    return sheet_xml(rows, widths, freeze=True, cf=cf, dv=dvx, autofilter=f'A1:{vc}1', tabcolor=tabcolor)

def build_listas():
    rows = [(1, [c_str('A1', 'Gerentes (nome completo do usuário)', 1), c_str('C1', 'Nota', 1)])]
    notas = ['O nome precisa bater com exatamente um usuário ATIVO na org; o validador barra nome sem match, inativo ou ambíguo (nunca chuta).',
             'Acrescente linhas para outros gerentes; as listas suspensas leem até a linha 50.']
    for i in range(max(len(GERENTES), len(notas))):
        cells = []
        if i < len(GERENTES): cells.append(c_str(f'A{i+2}', GERENTES[i], 4))
        if i < len(notas): cells.append(c_str(f'C{i+2}', notas[i], 8))
        rows.append((i + 2, cells))
    return sheet_xml(rows, [(1, 36), (3, 100)], tabcolor='2E75B6')

def build_instrucoes():
    L = [('Alteração do Gerente da conta (contas e oportunidades) — BrasilTecPar', 7), ('', 0),
         ('O que este template altera', 9),
         ('Conta: campo "Gerente da conta" (AccountManager__c). Oportunidade: campo "Gerente da Conta" (ManagerAccount__c), que define o aprovador da etapa "Aprovação - Comercial". O dono (proprietário) da conta e da oportunidade NUNCA é alterado por esta carga.', 8),
         ('', 0), ('Como usar', 9),
         ('1. Aba Contas: uma linha por CNPJ. Aba Oportunidades: uma linha por oportunidade (nome da conta + nome da oportunidade). Colunas amarelas são obrigatórias; as cinzas são conferência automática.', 8),
         ('2. Só envie quando a coluna LINHA estiver OK em todas as linhas preenchidas.', 8),
         ('3. A governança NÃO grava a partir desta planilha. Primeiro consulta a org (validar_gerente.py gera as consultas), casa cada linha com exatamente um registro pelo Id e só então gera os arquivos de update. Linha sem registro, com mais de um registro ou com nome divergente fica retida.', 8),
         ('4. A gravação é feita pelo script Apex 37 em duas fases (listar, depois executar), em lotes, com conferência antes e depois.', 8),
         ('', 0), ('O que pode segurar uma linha na org', 9),
         ('Conta B2B sem "Cluster manual": a regra de validação exige cluster no usuário que executa; o script 37 preenche um cluster temporário no executor e limpa depois (mesmo método do chamado do Rodrigo, script 31).', 8),
         ('Oportunidade em "Análise cliente" ou "Aguardando contrato": bloqueada por regra de validação; o script 37 grava junto com Bypass__c = true (mecanismo previsto na org).', 8),
         ('Oportunidade em aprovação (Send4Approval = true, registro travado): o campo não aceita edição; o script 37 reatribui o item pendente "Aprovação - Comercial" ao novo gerente (como no script 27) e o campo é ajustado depois da aprovação.', 8),
         ('Registro que já está com o gerente alvo: fica no arquivo C (sem mudança), não é reenviado.', 8),
         ('', 0), ('Referências no diário', 9),
         ('docs/2026-09-16-sustentacao-hierarquia-b2b.md (chamado do Rodrigo: scripts 29 a 33, regras de validação e bypass); scripts 24 a 28 (aprovação comercial SENAC: item de orquestração designado ao Gerente da Conta).', 8)]
    return sheet_xml([(i + 1, [c_str(f'A{i+1}', t, s)]) for i, (t, s) in enumerate(L)], [(1, 150)], tabcolor='1B7A4E')

def write_xlsx(path, sheets):
    names = [n for n, _ in sheets]
    ct = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          + ''.join(f'<Override PartName="/xl/worksheets/sheet{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(len(sheets))) + '</Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
    wb = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/></bookViews><sheets>'
          + ''.join(f'<sheet name="{n}" sheetId="{i+1}" r:id="rId{i+1}"/>' for i, n in enumerate(names)) + '</sheets><calcPr calcId="191029" fullCalcOnLoad="1"/></workbook>')
    wbrels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
              + ''.join(f'<Relationship Id="rId{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i+1}.xml"/>' for i in range(len(sheets)))
              + f'<Relationship Id="rId{len(sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct); z.writestr('_rels/.rels', rels); z.writestr('xl/workbook.xml', wb)
        z.writestr('xl/_rels/workbook.xml.rels', wbrels); z.writestr('xl/styles.xml', STYLES)
        for i, (_, x) in enumerate(sheets): z.writestr(f'xl/worksheets/sheet{i+1}.xml', x)

def from_contas(path, gerente):
    rows = read_xlsx_rows(path); out = []
    for r in rows[1:]:
        g = lambda c: ' '.join((r.get(c) or '').split())
        if not g('B'): continue
        out.append([g('B'), g('C'), g('D'), g('E'), gerente, f'cluster {g("A")}' if g('A') else ''])
    return out
def from_opps(path, gerente):
    rows = read_xlsx_rows(path); out = []
    for r in rows[1:]:
        g = lambda c: ' '.join((r.get(c) or '').split())
        if not g('A') and not g('B'): continue
        out.append([g('A'), g('B'), g('G'), g('F'), gerente, 'Aguardando aprovação comercial' if 'aprova' in g('F').lower() else ''])
    return out

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--contas'); ap.add_argument('--opps'); ap.add_argument('--gerente', default=GERENTES[0]); ap.add_argument('--saida')
    a = ap.parse_args()
    if a.contas or a.opps:
        dc = from_contas(a.contas, a.gerente) if a.contas else []; do = from_opps(a.opps, a.gerente) if a.opps else []
        out = a.saida or 'Alterar_Gerente_preenchido.xlsx'
    else:
        dc = [[ex for (_, _, ex) in COLS_C]]; do = [[ex for (_, _, ex) in COLS_O]]; out = a.saida or 'Template_Alterar_Gerente_Conta.xlsx'
    write_xlsx(out, [('Contas', build_sheet(COLS_C, CHK_C, REQ_C, f_contas, dc, 5, '1F3864')),
                     ('Oportunidades', build_sheet(COLS_O, CHK_O, REQ_O, f_opps, do, 5, 'B7791F')),
                     ('Listas', build_listas()), ('Instrucoes', build_instrucoes())])
    print('ok', out, len(dc), 'conta(s),', len(do), 'oportunidade(s)')
