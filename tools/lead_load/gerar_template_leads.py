#!/usr/bin/env python3
"""
Gera o template de carga massiva de Leads B2B (BrasilTecPar) como .xlsx, sem depender de
openpyxl (escreve o OOXML direto). Versao 2 (21/09/2026), depois da primeira carga real de 104 leads.

  python3 gerar_template_leads.py                      -> Template_Carga_Leads_B2B.xlsx (1 linha de exemplo)
  python3 gerar_template_leads.py --dados Massiva.xlsx -> despeja a planilha antiga da SDR (formato "Massiva_SDR")
                                                          no template, ja com as conferencias por linha

Abas: Leads (dados + colunas de conferencia com formulas), Listas (valores reais das picklists da org), Instrucoes.
As formulas sao recalculadas pelo Excel ao abrir (fullCalcOnLoad).

O que mudou da v1 para a v2 (tudo aprendido na carga de 21/09, ver docs/2026-09-21-carga-leads-sdr-vitoria.md):
- Temperatura do lead (Stage__c) e obrigatoria na org e nao existia no template: coluna nova com lista.
- Segmento e Time/Cluster: colunas novas com lista, para nao depender de padrao escondido no validador.
- Telefone fixo e Celular em colunas separadas: a org valida os dois com mascaras diferentes (so digitos).
- Origem do Lead com os valores reais da picklist LeadSource (a v1 trazia "Listas GRs ALT", que nao existe na org).
- SDR e Proprietario escolhidos de lista com nome e e-mail exatos da org (a v1 aceitava e-mail digitado, que veio errado).
- Produto de interesse (opcional) para a SDR registrar o que o cliente quer.
"""
import argparse, html, re, sys, zipfile
from xml.sax.saxutils import escape as esc

NROWS = 1000  # linhas de dados com formulas/validacao pre-aplicadas (2..1001)

# ---- colunas de dados: (cabecalho, campo Salesforce, obrigatorio, largura, exemplo)
COLS = [
    ('SDR *',                      'SDR__c (usuário)',       True,  28, 'Vitoria da Costa Hyppolito'),
    ('Proprietário do Lead *',     'OwnerId (usuário)',      True,  28, 'Vitoria da Costa Hyppolito'),
    ('Origem do Lead *',           'LeadSource',             True,  28, 'Outbound - Listas GRs ALT'),
    ('Temperatura *',              'Stage__c',               True,  12, '10'),
    ('Segmento *',                 'Segment__c',             True,  16, 'B2W - Wholesale'),
    ('Time/Cluster *',             'ClusterManual__c',       True,  12, 'ALT/GGNET'),
    ('CNPJ *',                     'DocumentNumber__c',      True,  20, '01.145.642/0001-41'),
    ('Razão Social *',             'Company',                True,  40, 'Phonoway Locacoes Ltda'),
    ('Nome Fantasia',              'FantasyName__c',         False, 26, 'Phonoway'),
    ('Nome do contato',            'FirstName',              False, 18, 'Jeferson'),
    ('Sobrenome do contato *',     'LastName',               True,  26, 'Benedito Castelucci'),
    ('Cargo',                      'Title',                  False, 18, 'Sócio'),
    ('Telefone fixo',              'Phone',                  False, 16, '1138747111'),
    ('Celular',                    'MobilePhone',            False, 16, '11976078975'),
    ('E-mail',                     'Email',                  False, 32, 'relacionamento@phonoway.com.br'),
    ('Cidade',                     'City',                   False, 18, 'São Paulo'),
    ('UF',                         'StateCode',              False, 6,  'SP'),
    ('Produto de interesse',       'ProductInterestNew__c',  False, 20, 'Fibra'),
    ('Observações',                'Description',            False, 40, 'Outros e-mails validados: financeiro@phonoway.com.br'),
]
# colunas de conferencia (formulas), a partir da coluna T
CHK = [('CNPJ (só dígitos)', 16), ('CNPJ válido?', 22), ('Duplicado na planilha?', 20), ('Telefone fixo?', 26), ('Celular?', 26),
       ('E-mail?', 22), ('Obrigatórios?', 40), ('LINHA', 10)]

# ---- listas (valores reais da btp-prod em 21/09/2026)
ORIGENS = ['Outbound - Listas GRs ALT', 'Outbound - Econodata', 'Outbound - Neoway', 'Outbound - Indicação', 'Outbound indicação GR p/ aquecer',
           'Outbound Mailing Last Mile', 'Outbound Mailing Cancelados', 'Outbound - Allrede', 'Atividade comercial',
           'Inbound - WhatsApp Comercial', 'Inbound - Email Comercial', 'Inbound - Call Center', 'Inbound - Website Digital',
           'MKT Cloud E-mail', 'MKT Cloud - Allrede', 'MKT Cloud - LinkISP26', 'Telefone', 'Email', 'WhatsApp', 'Website', 'Callcenter']
SDRS = [('Vitoria da Costa Hyppolito', 'vitoriahyppolito@brasiltecpar.com.br'), ('Jessica dos Santos', 'jessicadossantos@avato.com.br'),
        ('Alisson Cunha Chaves', 'alissonchaves@avato.com.br'), ('Anderson Carvalho Cruz De Santana', 'andersonsantana@brasiltecpar.com.br'),
        ('Fabio Norberto Ressener', 'fabioressener@avato.com.br'), ('Lorena Gisele Dos Santos Israel', 'lorenaisrael@avato.com.br'),
        ('Clayton Lopes', 'claytonlopes@brasiltecpar.com.br')]
UFS = ['AC','AL','AM','AP','BA','CE','DF','ES','GO','MA','MG','MS','MT','PA','PB','PE','PI','PR','RJ','RN','RO','RR','RS','SC','SE','SP','TO']
TEMPERATURAS = [('0', 'sem contato ainda'), ('10', 'frio: primeiro contato feito'), ('30', 'morno: interesse identificado'),
                ('60', 'quente: reunião ou proposta em andamento'), ('90', 'muito quente: fechamento próximo'), ('100', 'convertido (não usar na carga)')]
SEGMENTOS = ['Corporativo', 'Governo', 'Varejo', 'B2W - Wholesale']
CLUSTERS = ['ALT/GGNET', 'AVATO', 'BLINK', 'SEMPRE']
PRODUTOS = ['Fibra', 'TV', 'TelefoniaMovel', 'CamerasSegurança', 'Outros']

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

ND = len(COLS); LASTD = col(ND)  # S

def formulas(r):
    A, B, C, D, E, F, G, H, K, M, N, O = (f'{c}{r}' for c in 'ABCDEFGHKMNO')
    T, U, V, W, X, Y, Z = (f'{c}{r}' for c in 'TUVWXYZ')
    d1 = dv(T, 12, [5,4,3,2,9,8,7,6,5,4,3,2]); d2 = dv(T, 13, [6,5,4,3,2,9,8,7,6,5,4,3,2])
    fT = f'IF({G}="","",{digits_formula(G)})'
    fU = (f'IF({T}="","",IF(LEN({T})<>14,"ERRO: "&LEN({T})&" dígitos",IF(NOT(ISNUMBER(VALUE({T}))),"ERRO: não numérico",'
          f'IF(LEN(SUBSTITUTE({T},LEFT({T},1),""))=0,"ERRO: dígitos repetidos",'
          f'IF(AND(VALUE(MID({T},13,1))={d1},VALUE(MID({T},14,1))={d2}),"OK","ERRO: dígito verificador")))))')
    fV = f'IF({T}="","",IF(COUNTIF($T$2:$T${NROWS+1},{T})>1,"DUPLICADO","OK"))'
    dm = digits_formula(M); dn = digits_formula(N)
    fW = (f'IF({M}="","vazio",IF(OR(AND(LEN({dm})=10,LEFT({dm},1)<>"0"),AND(LEN({dm})=11,LEFT({dm},4)="0800")),"OK",'
          f'IF(AND(LEN({dm})=11,MID({dm},3,1)="9"),"ERRO: é celular, use a coluna Celular","ERRO: DDD + 8 dígitos ou 0800 + 7")))')
    fX = (f'IF({N}="","vazio",IF(AND(LEN({dn})=11,MID({dn},3,1)="9",LEFT({dn},1)<>"0"),"OK",'
          f'IF(LEN({dn})=10,"ERRO: é fixo (ou falta o 9), use a coluna Telefone fixo","ERRO: DDD + 9 + 8 dígitos")))')
    fY = (f'IF({O}="","vazio",IF(AND(ISNUMBER(FIND("@",{O})),ISNUMBER(FIND(".",MID({O},FIND("@",{O}),99))),'
          f'NOT(ISNUMBER(FIND(" ",TRIM({O})))),NOT(ISNUMBER(FIND(";",{O}))),NOT(ISNUMBER(FIND(",",{O})))),"OK","ERRO: um e-mail válido por linha"))')
    fZ = (f'IF(COUNTA(A{r}:{LASTD}{r})=0,"",IF(AND({A}<>"",{B}<>"",{C}<>"",{D}<>"",{E}<>"",{F}<>"",{G}<>"",{H}<>"",{K}<>"",OR({M}<>"",{N}<>"",{O}<>"")),"OK",'
          f'"ERRO: faltam "&IF({A}="","SDR; ","")&IF({B}="","Proprietário; ","")&IF({C}="","Origem; ","")&IF({D}="","Temperatura; ","")'
          f'&IF({E}="","Segmento; ","")&IF({F}="","Time/Cluster; ","")&IF({G}="","CNPJ; ","")&IF({H}="","Razão Social; ","")'
          f'&IF({K}="","Sobrenome; ","")&IF(AND({M}="",{N}="",{O}=""),"telefone, celular ou e-mail; ","")))')
    fAA = (f'IF(COUNTA(A{r}:{LASTD}{r})=0,"",IF(AND({U}="OK",{V}="OK",LEFT({W},4)<>"ERRO",LEFT({X},4)<>"ERRO",LEFT({Y},4)<>"ERRO",{Z}="OK"),"OK","REVISAR"))')
    return [fT, fU, fV, fW, fX, fY, fZ, fAA]

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
    if freeze:
        views = ('<sheetViews><sheetView workbookViewId="0"><pane xSplit="8" ySplit="1" topLeftCell="I2" activePane="bottomRight" state="frozen"/>'
                 '<selection pane="bottomRight" activeCell="A2" sqref="A2"/></sheetView></sheetViews>')
    else:
        views = '<sheetViews><sheetView workbookViewId="0"/></sheetViews>'
    body = ''.join(f'<row r="{r}">{"".join(cells)}</row>' for r, cells in rows)
    af = f'<autoFilter ref="{autofilter}"/>' if autofilter else ''
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            f'{pr}{views}<sheetFormatPr defaultRowHeight="14"/>{colsx}<sheetData>{body}</sheetData>{af}{cf}{dv}<pageMargins left="0.5" right="0.5" top="0.5" bottom="0.5" header="0.3" footer="0.3"/></worksheet>')

def lista(sq, ref, titulo, msg, mostra_erro=1):
    return (f'<dataValidation type="list" allowBlank="1" showErrorMessage="{mostra_erro}" errorTitle="{esc(titulo)}" error="{esc(msg)}" sqref="{sq}">'
            f'<formula1>{ref}</formula1></dataValidation>')

def build_leads_sheet(data_rows):
    nd = ND; nchk = len(CHK); last = NROWS + 1
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
    dvs = [
        lista(f'A2:A{last}', 'Listas!$B$2:$B$30', 'SDR', 'Escolha o SDR da lista (aba Listas). Se faltar alguém, peça à governança para incluir.'),
        lista(f'B2:B{last}', 'Listas!$B$2:$B$30', 'Proprietário do Lead', 'Escolha o usuário da lista (aba Listas). Nome exato da org, sem digitar e-mail.'),
        lista(f'C2:C{last}', 'Listas!$A$2:$A$40', 'Origem do Lead', 'Escolha um valor da lista (aba Listas). São os valores reais da picklist da org.'),
        lista(f'D2:D{last}', 'Listas!$E$2:$E$7', 'Temperatura', 'Use 0, 10, 30, 60 ou 90 (ver significado na aba Listas). Carga nova costuma ser 10.'),
        lista(f'E2:E{last}', 'Listas!$G$2:$G$10', 'Segmento', 'Escolha um valor da lista.'),
        lista(f'F2:F{last}', 'Listas!$H$2:$H$10', 'Time/Cluster', 'Escolha um valor da lista.'),
        lista(f'Q2:Q{last}', 'Listas!$D$2:$D$28', 'UF', 'Use a sigla do estado (2 letras).'),
        lista(f'R2:R{last}', 'Listas!$I$2:$I$10', 'Produto de interesse', 'Escolha um valor da lista ou deixe vazio.'),
        f'<dataValidation type="textLength" operator="between" allowBlank="1" showErrorMessage="1" errorTitle="Razão Social" error="Até 255 caracteres." sqref="H2:H{last}"><formula1>1</formula1><formula2>255</formula2></dataValidation>',
    ]
    dv = f'<dataValidations count="{len(dvs)}">' + ''.join(dvs) + '</dataValidations>'
    return sheet_xml(rows, widths, freeze=True, cf=cf, dv=dv, autofilter=f'A1:{vc}1', tabcolor='1F3864')

def build_listas_sheet():
    hdr = [('A', 'Origem do Lead (LeadSource)'), ('B', 'SDR / Proprietário (nome na org)'), ('C', 'E-mail na org'), ('D', 'UF'),
           ('E', 'Temperatura'), ('F', 'Significado'), ('G', 'Segmento'), ('H', 'Time/Cluster'), ('I', 'Produto de interesse'), ('K', 'Nota')]
    rows = [(1, [c_str(f'{c}1', t, 1) for c, t in hdr])]
    notas = ['Valores copiados da btp-prod em 21/09/2026 (picklists LeadSource, Stage__c, Segment__c, ClusterManual__c, ProductInterestNew__c e usuários ativos com leads como SDR).',
             'Para acrescentar SDR ou origem, peça à governança: o valor precisa existir na org antes da carga, senão a linha é retida.',
             'As listas suspensas da aba Leads leem até a linha 30 (SDR), 40 (origem) e 10 (segmento, cluster, produto). Não deixe linhas vazias no meio.',
             'Significado da temperatura: descrição sugerida pela governança; confirmar com a coordenação comercial.']
    n = max(len(ORIGENS), len(SDRS), len(UFS), len(TEMPERATURAS), len(SEGMENTOS), len(CLUSTERS), len(PRODUTOS), len(notas))
    for i in range(n):
        r = i + 2; cells = []
        if i < len(ORIGENS): cells.append(c_str(f'A{r}', ORIGENS[i], 4))
        if i < len(SDRS): cells.append(c_str(f'B{r}', SDRS[i][0], 4)); cells.append(c_str(f'C{r}', SDRS[i][1], 4))
        if i < len(UFS): cells.append(c_str(f'D{r}', UFS[i], 4))
        if i < len(TEMPERATURAS): cells.append(c_str(f'E{r}', TEMPERATURAS[i][0], 4)); cells.append(c_str(f'F{r}', TEMPERATURAS[i][1], 4))
        if i < len(SEGMENTOS): cells.append(c_str(f'G{r}', SEGMENTOS[i], 4))
        if i < len(CLUSTERS): cells.append(c_str(f'H{r}', CLUSTERS[i], 4))
        if i < len(PRODUTOS): cells.append(c_str(f'I{r}', PRODUTOS[i], 4))
        if i < len(notas): cells.append(c_str(f'K{r}', notas[i], 8))
        rows.append((r, cells))
    return sheet_xml(rows, [(1, 34), (2, 34), (3, 38), (4, 6), (5, 12), (6, 40), (7, 18), (8, 14), (9, 20), (11, 100)], tabcolor='2E75B6')

def build_instrucoes_sheet():
    linhas = [
        ('Template de carga massiva de Leads B2B — BrasilTecPar (v2, 21/09/2026)', 7),
        ('', 0),
        ('Como usar', 9),
        ('1. Preencha uma linha por empresa na aba Leads. Colunas com * e fundo amarelo são obrigatórias. Não altere a linha 1 nem as colunas cinza (conferência automática). As 8 primeiras colunas ficam congeladas para facilitar a rolagem.', 8),
        ('2. Confira a coluna LINHA: só envie quando todas as linhas preenchidas estiverem OK. REVISAR indica o motivo nas colunas cinza ao lado.', 8),
        ('3. Envie o arquivo para a governança Salesforce. O validador confere de novo cada linha e cruza com a org: CNPJ que já é Conta, Lead já existente, usuário válido.', 8),
        ('4. A governança carrega em dois lotes (piloto de 2 linhas, depois o restante) e devolve o arquivo com duas colunas a mais: ID LEAD SF e RESULTADO. Linhas retidas voltam com o motivo.', 8),
        ('', 0),
        ('Regras de preenchimento', 9),
        ('SDR e Proprietário do Lead: escolha da lista. São os nomes exatos dos usuários na org. Em geral os dois são a mesma pessoa; se o lead nasce já com um vendedor (GR) como dono, coloque o GR em Proprietário e o SDR em SDR.', 8),
        ('Origem do Lead: escolha da lista. São os valores reais da picklist da org. Lista comprada ou fornecida pelos GRs = "Outbound - Listas GRs ALT".', 8),
        ('Temperatura: obrigatória na org. Carga de prospecção nova = 10 (frio). Só use 30 ou mais se já houve contato com interesse. Nunca 100.', 8),
        ('Segmento e Time/Cluster: escolha da lista. Lista de provedores (wholesale) = "B2W - Wholesale"; empresa usuária final = "Corporativo".', 8),
        ('CNPJ: com ou sem máscara. São conferidos tamanho (14 dígitos) e dígitos verificadores. CPF (11 dígitos) não entra nesta carga.', 8),
        ('Razão Social: como consta na Receita. Nome Fantasia é opcional.', 8),
        ('Contato: Nome e Sobrenome em colunas separadas (o Salesforce exige Sobrenome). Um contato por linha; outros contatos vão em Observações.', 8),
        ('Telefone fixo: DDD + 8 dígitos (ex.: 1138747111) ou 0800 + 7 dígitos. Celular: DDD + 9 + 8 dígitos (ex.: 11976078975). Pode digitar com máscara, a conferência tira. Um número de cada tipo; outros vão em Observações. Número no tipo errado é retido pela org.', 8),
        ('E-mail: um por linha, sem ponto e vírgula. E-mails adicionais validados vão em Observações.', 8),
        ('É obrigatório ter telefone fixo, celular ou e-mail.', 8),
        ('Produto de interesse: opcional, escolha da lista.', 8),
        ('Duplicidade: o mesmo CNPJ não pode aparecer duas vezes no arquivo. CNPJ que já é Lead na org não é recriado (volta com o Id do lead existente). CNPJ que já é Conta não vira Lead: a regra B2B-01 manda abrir Oportunidade na Conta.', 8),
        ('', 0),
        ('O que a governança grava além das colunas', 9),
        ('Status = Novo; Tipo de registro = Prospecto - B2B; País = Brasil. Campos de integração e enriquecimento são preenchidos pela automação depois da criação.', 8),
        ('', 0),
        ('Referências no diário do projeto', 9),
        ('docs/2026-09-21-carga-leads-sdr-vitoria.md (primeira carga real, 104 leads, e o que a org exigiu). W-000071 (US B2C-14): carga massiva restrita a Coordenação e Marketing. W-000096 (US B2B-01): CNPJ já cliente vira Oportunidade, não Lead.', 8),
    ]
    rows = [(i + 1, [c_str(f'A{i+1}', t, s)]) for i, (t, s) in enumerate(linhas)]
    return sheet_xml(rows, [(1, 150)], tabcolor='1B7A4E')

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
            '<dc:title>Template de carga massiva de Leads B2B v2</dc:title><dc:creator>Governança Salesforce BTP</dc:creator></cp:coreProperties>')
    app = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Microsoft Excel</Application></Properties>')
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct); z.writestr('_rels/.rels', rels)
        z.writestr('xl/workbook.xml', wb); z.writestr('xl/_rels/workbook.xml.rels', wbrels); z.writestr('xl/styles.xml', STYLES)
        z.writestr('xl/worksheets/sheet1.xml', leads_xml); z.writestr('xl/worksheets/sheet2.xml', build_listas_sheet()); z.writestr('xl/worksheets/sheet3.xml', build_instrucoes_sheet())
        z.writestr('docProps/core.xml', core); z.writestr('docProps/app.xml', app)

# ---- leitura da planilha antiga da SDR (formato Massiva_SDR: SDR | Proprietario | Origem | CNPJ | Razao | Tel1 | Tel2 | Cliente | E-mails | Atualizado)
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

def separa_telefones(*tels):
    """Devolve (fixo, celular, sobra) pelo formato de cada numero (so digitos)."""
    fixos, cels, sobra = [], [], []
    for t in tels:
        d = re.sub(r'\D', '', t or '')
        if not d: continue
        if len(d) == 11 and d[2] == '9' and d[0] != '0': cels.append(d)
        elif (len(d) == 10 and d[0] != '0') or (len(d) == 11 and d.startswith('0800')): fixos.append(d)
        else: sobra.append(t)
    return (fixos[0] if fixos else ''), (cels[0] if cels else ''), fixos[1:] + cels[1:] + sobra

def sdr_to_template(rows):
    data = []
    for r in rows[1:]:
        g = lambda c: (r.get(c) or '').replace('\n', ' ').strip()
        if not any(g(c) for c in 'ABCDEFGHI'): continue
        nome = ' '.join(g('H').split()); parts = nome.split(' ', 1)
        first, last = (parts[0], parts[1]) if len(parts) == 2 else ('', nome)
        emails = [e for e in re.split(r'[;,/ ]+', g('I')) if e]
        fixo, cel, sobra = separa_telefones(g('F'), g('G'))
        obs = '; '.join(x for x in [('Outros e-mails validados: ' + '; '.join(emails[1:])) if len(emails) > 1 else '',
                                    ('Outros telefones: ' + ', '.join(sobra)) if sobra else ''] if x)
        origem = {'Listas GRs ALT': 'Outbound - Listas GRs ALT'}.get(g('C'), g('C'))
        data.append([g('A'), g('B') if '@' not in g('B') else g('A'), origem, '10', 'B2W - Wholesale', 'ALT/GGNET', g('D'), g('E'), '',
                     first.title() if first.isupper() or first.islower() else first, last, '', fixo, cel, emails[0] if emails else '', '', '', '', obs])
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
