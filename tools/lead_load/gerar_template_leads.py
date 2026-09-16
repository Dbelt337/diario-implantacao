#!/usr/bin/env python3
"""
Gera o template de carga massiva de Leads B2B (BrasilTecPar) como .xlsx, sem depender de
openpyxl (escreve o OOXML direto). Uso:

  python3 gerar_template_leads.py                      -> Template_Carga_Leads_B2B.xlsx (1 linha de exemplo)
  python3 gerar_template_leads.py --dados Massiva.xlsx -> despeja a planilha da SDR (formato "Massiva_SDR")
                                                          no template, ja com as conferencias por linha

Abas: Leads (dados + colunas de conferencia com formulas), Listas (valores das picklists), Instrucoes.
As formulas sao recalculadas pelo Excel ao abrir (fullCalcOnLoad).
"""
import argparse, html, re, sys, zipfile
from xml.sax.saxutils import escape as esc

NROWS = 1000  # linhas de dados com formulas/validacao pre-aplicadas (2..1001)

# ---- colunas de dados: (cabecalho, campo Salesforce, obrigatorio, largura, exemplo)
COLS = [
    ('SDR',                        'SDR__c',              False, 26, 'Vitoria da Costa Hyppolito'),
    ('Proprietário do Lead *',     'OwnerId (nome ou e-mail do usuário)', True, 30, 'vitoria.hyppolito@brasiltecpar.com.br'),
    ('Origem do Lead *',           'LeadSource',          True,  20, 'Listas GRs ALT'),
    ('CNPJ *',                     'DocumentNumber__c',   True,  20, '01.145.642/0001-41'),
    ('Razão Social *',             'Company',             True,  40, 'Phonoway Locacoes Ltda'),
    ('Nome Fantasia',              'FantasyName__c',      False, 26, 'Phonoway'),
    ('Nome do contato',            'FirstName',           False, 18, 'Jeferson'),
    ('Sobrenome do contato *',     'LastName',            True,  26, 'Benedito Castelucci'),
    ('Cargo',                      'Title',               False, 18, 'Sócio'),
    ('Telefone principal',         'Phone',               False, 18, '(11) 3874-7111'),
    ('Telefone secundário',        'MobilePhone',         False, 18, '(11) 3486-0653'),
    ('E-mail',                     'Email',               False, 32, 'relacionamento@phonoway.com.br'),
    ('Cidade',                     'City',                False, 18, 'São Paulo'),
    ('UF',                         'State',               False, 6,  'SP'),
    ('Observações',                'Description',         False, 40, 'Outros e-mails validados: financeiro@phonoway.com.br'),
]
# colunas de conferencia (formulas), a partir da coluna P
CHK = [('CNPJ (só dígitos)', 16), ('CNPJ válido?', 22), ('Duplicado na planilha?', 20),
       ('Telefone?', 18), ('E-mail?', 18), ('Obrigatórios?', 34), ('LINHA', 10)]
ORIGENS = ['Listas GRs ALT', 'Indicação', 'Site', 'Evento', 'Prospecção ativa (SDR)', 'Base própria', 'Parceiro']
SDRS = ['Vitoria da Costa Hyppolito']
UFS = ['AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT','PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO']

def col(n):  # 1 -> A
    s = ''
    while n: n, r = divmod(n - 1, 26); s = chr(65 + r) + s
    return s

def digits_formula(ref):
    return f'SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(SUBSTITUTE(TRIM({ref}),".",""),"/",""),"-","")," ",""),"(",""),")",""),"+","")'

def dv(p, n, pesos):
    w = '{' + ','.join(str(x) for x in pesos) + '}'
    idx = '{' + ','.join(str(i) for i in range(1, n + 1)) + '}'
    s = f'MOD(SUMPRODUCT(--MID({p},{idx},1),{w}),11)'
    return f'IF({s}<2,0,11-{s})'

def formulas(r):
    P, Q, R, S, T, U, V = (f'{c}{r}' for c in 'PQRSTUV')
    A, B, C, D, E, H, J, K, L = (f'{c}{r}' for c in 'ABCDEHJKL')
    d1 = dv(P, 12, [5,4,3,2,9,8,7,6,5,4,3,2]); d2 = dv(P, 13, [6,5,4,3,2,9,8,7,6,5,4,3,2])
    fP = f'IF({D}="","",{digits_formula(D)})'
    fQ = (f'IF({P}="","",IF(LEN({P})<>14,"ERRO: "&LEN({P})&" dígitos",IF(NOT(ISNUMBER(VALUE({P}))),"ERRO: não numérico",'
          f'IF(LEN(SUBSTITUTE({P},LEFT({P},1),""))=0,"ERRO: dígitos repetidos",'
          f'IF(AND(VALUE(MID({P},13,1))={d1},VALUE(MID({P},14,1))={d2}),"OK","ERRO: dígito verificador")))))')
    fR = f'IF({P}="","",IF(COUNTIF($P$2:$P${NROWS+1},{P})>1,"DUPLICADO","OK"))'
    dj = digits_formula(J); dk = digits_formula(K)
    fS = (f'IF(AND({J}="",{K}=""),"vazio",IF(AND(OR({J}="",LEN({dj})=10,LEN({dj})=11),OR({K}="",LEN({dk})=10,LEN({dk})=11)),"OK",'
          f'"ERRO: use DDD + número (10 ou 11 dígitos)"))')
    fT = (f'IF({L}="","vazio",IF(AND(ISNUMBER(FIND("@",{L})),ISNUMBER(FIND(".",MID({L},FIND("@",{L}),99))),'
          f'NOT(ISNUMBER(FIND(" ",TRIM({L})))),NOT(ISNUMBER(FIND(";",{L}))),NOT(ISNUMBER(FIND(",",{L})))),"OK","ERRO: um e-mail válido por linha"))')
    fU = (f'IF(COUNTA(A{r}:O{r})=0,"",IF(AND({B}<>"",{C}<>"",{D}<>"",{E}<>"",{H}<>"",OR({J}<>"",{L}<>"")),"OK",'
          f'"ERRO: faltam "&IF({B}="","Proprietário; ","")&IF({C}="","Origem; ","")&IF({D}="","CNPJ; ","")&IF({E}="","Razão Social; ","")'
          f'&IF({H}="","Sobrenome; ","")&IF(AND({J}="",{L}=""),"telefone ou e-mail; ","")))')
    fV = (f'IF(COUNTA(A{r}:O{r})=0,"",IF(AND({Q}="OK",{R}="OK",LEFT({S},4)<>"ERRO",LEFT({T},4)<>"ERRO",{U}="OK"),"OK","REVISAR"))')
    return [fP, fQ, fR, fS, fT, fU, fV]

# ---- estilos (indices em cellXfs)
# 0 padrao | 1 cabecalho | 2 cabecalho obrigatorio | 3 cabecalho conferencia | 4 dado | 5 dado obrigatorio (amarelo) | 6 conferencia (cinza) | 7 titulo | 8 texto instrucoes | 9 negrito
STYLES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="5"><font><sz val="10"/><name val="Arial"/></font><font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font>
<font><b/><sz val="14"/><color rgb="FF1F3864"/><name val="Arial"/></font><font><b/><sz val="10"/><name val="Arial"/></font><font><sz val="10"/><color rgb="FF444444"/><name val="Arial"/></font></fonts>
<fills count="6"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF1F3864"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFB7791F"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFF9C4"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFEDEDED"/></patternFill></fill></fills>
<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFBFBFBF"/></left><right style="thin"><color rgb="FFBFBFBF"/></right><top style="thin"><color rgb="FFBFBFBF"/></top><bottom style="thin"><color rgb="FFBFBFBF"/></bottom><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="10">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="1" fillId="3" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="3" fillId="5" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf numFmtId="49" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1"/>
<xf numFmtId="49" fontId="0" fillId="4" borderId="1" xfId="0" applyNumberFormat="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="4" fillId="5" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1"/>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyFont="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
</cellXfs>
<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
<dxfs count="3"><dxf><font><color rgb="FF9C0006"/></font><fill><patternFill><bgColor rgb="FFFFC7CE"/></patternFill></fill></dxf>
<dxf><font><color rgb="FF006100"/></font><fill><patternFill><bgColor rgb="FFC6EFCE"/></patternFill></fill></dxf>
<dxf><font><color rgb="FF9C5700"/></font><fill><patternFill><bgColor rgb="FFFFEB9C"/></patternFill></fill></dxf></dxfs>
</styleSheet>'''

def c_str(ref, s, style=0):
    if s is None or s == '': return f'<c r="{ref}" s="{style}"/>'
    return f'<c r="{ref}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{esc(str(s))}</t></is></c>'
def c_f(ref, f, style=0):
    return f'<c r="{ref}" s="{style}"><f>{esc(f)}</f></c>'

def sheet_xml(rows, cols_w=None, freeze=None, cf='', dv='', autofilter=None, tabcolor=None):
    colsx = '<cols>' + ''.join(f'<col min="{i}" max="{i}" width="{w}" customWidth="1"/>' for i, w in cols_w) + '</cols>' if cols_w else ''
    pr = f'<sheetPr><tabColor rgb="{tabcolor}"/></sheetPr>' if tabcolor else ''
    views = '<sheetViews><sheetView workbookViewId="0"' + ('' if not freeze else f'><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/><selection pane="bottomLeft" activeCell="A2" sqref="A2"/></sheetView>' if freeze else '/>') + ('</sheetViews>' if freeze else '</sheetViews>')
    if not freeze: views = '<sheetViews><sheetView workbookViewId="0"/></sheetViews>'
    body = ''.join(f'<row r="{r}">{"".join(cells)}</row>' for r, cells in rows)
    af = f'<autoFilter ref="{autofilter}"/>' if autofilter else ''
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            f'{pr}{views}<sheetFormatPr defaultRowHeight="14"/>{colsx}<sheetData>{body}</sheetData>{af}{cf}{dv}<pageMargins left="0.5" right="0.5" top="0.5" bottom="0.5" header="0.3" footer="0.3"/></worksheet>')

def build_leads_sheet(data_rows):
    nd = len(COLS); nchk = len(CHK); last = NROWS + 1
    rows = []
    hdr = [c_str(f'{col(i+1)}1', h, 2 if req else 1) for i, (h, _, req, _, _) in enumerate(COLS)]
    hdr += [c_str(f'{col(nd+i+1)}1', h, 3) for i, (h, _) in enumerate(CHK)]
    rows.append((1, hdr))
    for r in range(2, last + 1):
        vals = data_rows[r - 2] if r - 2 < len(data_rows) else [''] * nd
        cells = [c_str(f'{col(i+1)}{r}', vals[i] if i < len(vals) else '', 5 if COLS[i][2] else 4) for i in range(nd)]
        cells += [c_f(f'{col(nd+i+1)}{r}', f, 6) for i, f in enumerate(formulas(r))]
        rows.append((r, cells))
    widths = [(i + 1, w) for i, (_, _, _, w, _) in enumerate(COLS)] + [(nd + i + 1, w) for i, (_, w) in enumerate(CHK)]
    pc, vc = col(nd + 1), col(nd + nchk)
    cf = (f'<conditionalFormatting sqref="{pc}2:{vc}{last}"><cfRule type="containsText" dxfId="0" priority="1" operator="containsText" text="ERRO"><formula>NOT(ISERROR(SEARCH("ERRO",{pc}2)))</formula></cfRule>'
          f'<cfRule type="containsText" dxfId="0" priority="2" operator="containsText" text="DUPLICADO"><formula>NOT(ISERROR(SEARCH("DUPLICADO",{pc}2)))</formula></cfRule>'
          f'<cfRule type="containsText" dxfId="0" priority="3" operator="containsText" text="REVISAR"><formula>NOT(ISERROR(SEARCH("REVISAR",{pc}2)))</formula></cfRule></conditionalFormatting>'
          f'<conditionalFormatting sqref="{vc}2:{vc}{last}"><cfRule type="cellIs" dxfId="1" priority="4" operator="equal"><formula>"OK"</formula></cfRule></conditionalFormatting>')
    dv = ('<dataValidations count="4">'
          f'<dataValidation type="list" allowBlank="1" showErrorMessage="1" errorTitle="Origem do Lead" error="Escolha um valor da lista (aba Listas). Se faltar uma origem, peça à governança para incluir." sqref="C2:C{last}"><formula1>Listas!$A$2:$A$50</formula1></dataValidation>'
          f'<dataValidation type="list" allowBlank="1" showErrorMessage="0" sqref="A2:A{last}"><formula1>Listas!$B$2:$B$50</formula1></dataValidation>'
          f'<dataValidation type="list" allowBlank="1" showErrorMessage="1" errorTitle="UF" error="Use a sigla do estado (2 letras)." sqref="N2:N{last}"><formula1>Listas!$C$2:$C$28</formula1></dataValidation>'
          f'<dataValidation type="textLength" operator="between" allowBlank="1" showErrorMessage="1" errorTitle="Razão Social" error="Até 255 caracteres." sqref="E2:E{last}"><formula1>1</formula1><formula2>255</formula2></dataValidation>'
          '</dataValidations>')
    return sheet_xml(rows, widths, freeze=True, cf=cf, dv=dv, autofilter=f'A1:{vc}1', tabcolor='1F3864')

def build_listas_sheet():
    rows = [(1, [c_str('A1', 'Origem do Lead (LeadSource)', 1), c_str('B1', 'SDR', 1), c_str('C1', 'UF', 1), c_str('E1', 'Nota', 1)])]
    n = max(len(ORIGENS), len(SDRS), len(UFS))
    notas = ['Os valores de Origem do Lead devem bater com a picklist LeadSource da org (confirmar com a governança antes da primeira carga).',
             'Acrescente linhas nesta aba para novas origens ou SDRs; as listas suspensas da aba Leads leem até a linha 50.']
    for i in range(n):
        r = i + 2; cells = []
        if i < len(ORIGENS): cells.append(c_str(f'A{r}', ORIGENS[i], 4))
        if i < len(SDRS): cells.append(c_str(f'B{r}', SDRS[i], 4))
        if i < len(UFS): cells.append(c_str(f'C{r}', UFS[i], 4))
        if i < len(notas): cells.append(c_str(f'E{r}', notas[i], 8))
        rows.append((r, cells))
    return sheet_xml(rows, [(1, 30), (2, 30), (3, 6), (5, 90)], tabcolor='2E75B6')

def build_instrucoes_sheet():
    linhas = [
        ('Template de carga massiva de Leads B2B — BrasilTecPar', 7),
        ('', 0),
        ('Como usar', 9),
        ('1. Preencha uma linha por empresa na aba Leads. Colunas com * e fundo amarelo são obrigatórias. Não altere a linha 1 nem as colunas cinza (conferência automática).', 8),
        ('2. Confira a coluna LINHA: só siga com a carga quando todas as linhas preenchidas estiverem OK. REVISAR indica o motivo nas colunas ao lado.', 8),
        ('3. Envie o arquivo para a governança Salesforce. Antes de gravar, o validador (tools/lead_load/validar_leads.py) confere de novo cada linha e cruza com a org: CNPJ que já é Conta ativa, Lead já existente, proprietário válido.', 8),
        ('4. A carga é feita pela governança na sandbox primeiro, depois em produção, em lotes pequenos, com o resultado (Id do Lead) devolvido para a SDR.', 8),
        ('', 0),
        ('Regras de preenchimento', 9),
        ('Proprietário do Lead: nome completo ou e-mail do usuário Salesforce. Usuário inativo, inexistente ou ambíguo trava a linha (a governança nunca "chuta" o dono).', 8),
        ('Origem do Lead: escolha da lista. Não digite espaços nem quebras de linha (a planilha da SDR de setembro veio com quebra de linha em todas as origens).', 8),
        ('CNPJ: com ou sem máscara. São conferidos tamanho (14 dígitos) e dígitos verificadores. CPF (11 dígitos) não entra nesta carga.', 8),
        ('Razão Social: como consta na Receita. Nome Fantasia é opcional.', 8),
        ('Contato: Nome e Sobrenome em colunas separadas (o Salesforce exige Sobrenome). Um contato por linha; outros contatos vão em Observações ou em uma segunda carga de Contatos.', 8),
        ('Telefones: DDD + número, 10 ou 11 dígitos. 0800 é aceito como 11 dígitos.', 8),
        ('E-mail: um por linha, sem ponto e vírgula. E-mails adicionais validados vão em Observações.', 8),
        ('É obrigatório ter telefone ou e-mail.', 8),
        ('Duplicidade: o mesmo CNPJ não pode aparecer duas vezes no arquivo; o validador também barra CNPJ que já é Lead aberto ou Conta ativa na org (nesse caso a regra B2B-01 manda abrir Oportunidade na Conta, não Lead).', 8),
        ('', 0),
        ('O que a governança grava além das colunas', 9),
        ('Status = Novo; Tipo de registro = Lead B2B; LegalEntityType = PJ; campos de integração e enriquecimento (Get_CNPJ_Details / Econodata) preenchidos pela automação depois da criação.', 8),
        ('', 0),
        ('Referências no diário do projeto', 9),
        ('W-000071 (US B2C-14): carga massiva restrita a Coordenação e Marketing via permission set PS_B2C_Lead_Importer. W-000096 (US B2B-01): CNPJ já cliente vira Oportunidade, não Lead. tools/mg_load: pipeline de carga de contas MG (mesmo método: validar a seco, reter dúvidas, gravar em lotes).', 8),
    ]
    rows = [(i + 1, [c_str(f'A{i+1}', t, s)]) for i, (t, s) in enumerate(linhas)]
    return sheet_xml(rows, [(1, 140)], tabcolor='1B7A4E')

def write_xlsx(path, leads_xml):
    ct = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          + ''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in (1, 2, 3)) +
          '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
          '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
            '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
            '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>')
    wb = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<bookViews><workbookView xWindow="0" yWindow="0" windowWidth="24000" windowHeight="12000"/></bookViews>'
          '<sheets><sheet name="Leads" sheetId="1" r:id="rId1"/><sheet name="Listas" sheetId="2" r:id="rId2"/><sheet name="Instrucoes" sheetId="3" r:id="rId3"/></sheets>'
          '<calcPr calcId="191029" fullCalcOnLoad="1"/></workbook>')
    wbrels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
              '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
              '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>'
              '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>'
              '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
    core = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
            '<dc:title>Template de carga massiva de Leads B2B</dc:title><dc:creator>Governança Salesforce BTP</dc:creator></cp:coreProperties>')
    app = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Microsoft Excel</Application></Properties>')
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct); z.writestr('_rels/.rels', rels)
        z.writestr('xl/workbook.xml', wb); z.writestr('xl/_rels/workbook.xml.rels', wbrels); z.writestr('xl/styles.xml', STYLES)
        z.writestr('xl/worksheets/sheet1.xml', leads_xml); z.writestr('xl/worksheets/sheet2.xml', build_listas_sheet()); z.writestr('xl/worksheets/sheet3.xml', build_instrucoes_sheet())
        z.writestr('docProps/core.xml', core); z.writestr('docProps/app.xml', app)

# ---- leitura da planilha da SDR (formato Massiva_SDR: SDR | Proprietario | Origem | CNPJ | Razao | Tel1 | Tel2 | Cliente | E-mails | Atualizado)
def read_xlsx_rows(path):
    z = zipfile.ZipFile(path)
    ss = []
    if 'xl/sharedStrings.xml' in z.namelist():
        sx = z.read('xl/sharedStrings.xml').decode('utf8')
        ss = [''.join(html.unescape(t) for t in re.findall(r'<t[^>]*>(.*?)</t>', si, flags=re.S)) for si in re.findall(r'<si>.*?</si>', sx, flags=re.S)]
    x = z.read('xl/worksheets/sheet1.xml').decode('utf8')
    out = []
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
        out.append(d)
    return out

def sdr_to_template(rows):
    hdr = rows[0]; data = []
    for r in rows[1:]:
        g = lambda c: (r.get(c) or '').replace('\n', ' ').strip()
        if not any(g(c) for c in 'ABCDEFGHI'): continue
        nome = ' '.join(g('H').split())
        parts = nome.split(' ', 1)
        first, last = (parts[0], parts[1]) if len(parts) == 2 else ('', nome)
        emails = [e for e in re.split(r'[;,/ ]+', g('I')) if e]
        obs = ('Outros e-mails validados: ' + '; '.join(emails[1:])) if len(emails) > 1 else ''
        data.append([g('A'), g('B'), g('C'), g('D'), g('E'), '', first.title() if first.isupper() or first.islower() else first, last, '',
                     g('F'), g('G'), emails[0] if emails else '', '', '', obs])
    return data

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--dados', help='planilha no formato Massiva_SDR para despejar no template'); ap.add_argument('--saida')
    a = ap.parse_args()
    if a.dados:
        data = sdr_to_template(read_xlsx_rows(a.dados)); out = a.saida or 'Leads_no_template.xlsx'
    else:
        data = [[ex for (_, _, _, _, ex) in COLS]]; out = a.saida or 'Template_Carga_Leads_B2B.xlsx'
    write_xlsx(out, build_leads_sheet(data))
    print('ok', out, len(data), 'linha(s) de dados')
