#!/usr/bin/env python3
# Template POC pricing — xlsx construido a mano (sin openpyxl disponible).
import zipfile, html, os

def esc(s): return html.escape(str(s), quote=False)

def cell(ref, style, text=None, num=None, formula=None):
    if formula is not None:
        return f'<c r="{ref}" s="{style}"><f>{esc(formula)}</f></c>'
    if num is not None:
        return f'<c r="{ref}" s="{style}"><v>{num}</v></c>'
    if text is not None:
        return f'<c r="{ref}" t="inlineStr" s="{style}"><is><t xml:space="preserve">{esc(text)}</t></is></c>'
    return f'<c r="{ref}" s="{style}"/>'

def row(n, cells, ht=None):
    h = f' ht="{ht}" customHeight="1"' if ht else ''
    return f'<row r="{n}"{h}>{"".join(cells)}</row>'

# ---------- styles ----------
# fonts: 0 Arial10, 1 bold, 2 title 14 bold dark, 3 italic gray, 4 header white bold
styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="5">
<font><sz val="10"/><name val="Arial"/></font>
<font><b/><sz val="10"/><name val="Arial"/></font>
<font><b/><sz val="14"/><color rgb="FF16325C"/><name val="Arial"/></font>
<font><i/><sz val="9"/><color rgb="FF808080"/><name val="Arial"/></font>
<font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font>
</fonts>
<fills count="5">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFFF00"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF16325C"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF2F2F2"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
<border><left/><right/><top/><bottom/><diagonal/></border>
<border><left style="thin"><color rgb="FFB0B7BD"/></left><right style="thin"><color rgb="FFB0B7BD"/></right><top style="thin"><color rgb="FFB0B7BD"/></top><bottom style="thin"><color rgb="FFB0B7BD"/></bottom><diagonal/></border>
</borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="11">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0"/>
<xf numFmtId="0" fontId="3" fillId="4" borderId="1" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="2" fontId="3" fillId="4" borderId="1" xfId="0"/>
<xf numFmtId="2" fontId="0" fillId="2" borderId="1" xfId="0"/>
<xf numFmtId="2" fontId="0" fillId="0" borderId="1" xfId="0"/>
<xf numFmtId="10" fontId="0" fillId="0" borderId="1" xfId="0"/>
<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0"/>
</cellXfs>
</styleSheet>'''
# style idx: 0 normal | 1 titulo | 2 nota | 3 header | 4 input-amarillo texto
# 5 ejemplo-texto | 6 ejemplo-num | 7 input-amarillo num | 8 formula 0.00 | 9 formula % | 10 borde plano

# ---------- hoja 1 : Datos Materiales ----------
H1 = ["Código material","Descripción","Marca","Origen","Sociedad / Destino",
      "Grupo / Jerarquía de producto","FOB (USD)","Factor de nacionalización",
      "Mark-up (fracción, ej. 0.40)","Moneda destino","Tipo de cambio","Fecha de precio",
      "ZPRT oficial SAP (moneda destino)","Observaciones"]
cols_1 = 'ABCDEFGHIJKLMN'
rows1 = []
rows1.append(row(1, [cell('A1',1, text='POC Simulador de Precios — Datos de materiales (Repuestos)')], ht=20))
rows1.append(row(2, [cell('A2',2, text='Completar una fila por material (2-3 materiales reales). Celdas AMARILLAS = a completar por el punto focal SAP de Grupo Q. La fila gris es un EJEMPLO con valores ilustrativos y puede borrarse. El ZPRT oficial debe calcularse en SAP con la misma fecha de precio informada — es el valor de referencia de la validación de paridad.')], ht=42))
rows1.append(row(4, [cell(f'{c}4',3, text=h) for c,h in zip(cols_1,H1)], ht=30))
# ejemplo: ZPRT = 12.50 * 1.35 * 1.40 * 7.85 = 185.46 (redondeado)
ex = ['REP-12345','Filtro de aceite 1.8L','Toyota','Japón','GT10 Guatemala','G100 Filtros']
c5 = [cell(f'{c}5',5, text=v) for c,v in zip('ABCDEF',ex)]
c5 += [cell('G5',6,num=12.5), cell('H5',6,num=1.35), cell('I5',6,num=0.4)]
c5 += [cell('J5',5,text='GTQ'), cell('K5',6,num=7.85), cell('L5',5,text='05/08/2026')]
c5 += [cell('M5',6,num=185.46), cell('N5',5,text='Ejemplo — ZPRT = FOB × factor × (1 + mark-up) × tipo de cambio')]
rows1.append(row(5, c5, ht=24))
for r in (6,7,8):
    cs = [cell(f'{c}{r}',4) for c in 'ABCDEF'] + [cell(f'{c}{r}',7) for c in 'GHI'] + \
         [cell(f'J{r}',4), cell(f'K{r}',7), cell(f'L{r}',4), cell(f'M{r}',7), cell(f'N{r}',4)]
    rows1.append(row(r, cs))
widths1 = [16,26,12,12,16,22,10,14,14,10,11,12,16,42]
cols1 = '<cols>' + ''.join(f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i,w in enumerate(widths1)) + '</cols>'
sheet1 = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
 + cols1 + '<sheetData>' + ''.join(rows1) + '</sheetData></worksheet>')

# ---------- hoja 2 : Validación Paridad ----------
H2 = ["Código material","ZPRT oficial SAP","Precio simulado (waterfall Salesforce)",
      "Desvío absoluto","Desvío %","Resultado"]
rows2 = []
rows2.append(row(1, [cell('A1',1, text='Validación de paridad — SAP vs Salesforce Pricing')], ht=20))
rows2.append(row(2, [cell('A2',2, text='Completar tras la simulación (Fase 5): pegar el ZPRT oficial (hoja Datos Materiales, col. M) y el precio final del waterfall simulado. Los desvíos se calculan solos al abrir en Excel. Criterio de salida de la POC: desvío = 0 (paridad exacta con los mismos parámetros y fecha). Resultado OK = desvío absoluto < 0.005 (medio centavo, redondeo).')], ht=42))
rows2.append(row(4, [cell(f'{c}4',3, text=h) for c,h in zip('ABCDEF',H2)], ht=30))
rows2.append(row(5, [cell('A5',5, text='REP-12345 (ejemplo)'), cell('B5',6,num=185.46), cell('C5',6,num=185.46),
                     cell('D5',8, formula='IF(C5="","",C5-B5)'),
                     cell('E5',9, formula='IF(OR(B5="",C5=""),"",(C5-B5)/B5)'),
                     cell('F5',10, formula='IF(C5="","",IF(ABS(D5)<0.005,"OK","REVISAR"))')]))
for r in (6,7,8):
    rows2.append(row(r, [cell(f'A{r}',4), cell(f'B{r}',7), cell(f'C{r}',7),
                         cell(f'D{r}',8, formula=f'IF(C{r}="","",C{r}-B{r})'),
                         cell(f'E{r}',9, formula=f'IF(OR(B{r}="",C{r}=""),"",(C{r}-B{r})/B{r})'),
                         cell(f'F{r}',10, formula=f'IF(C{r}="","",IF(ABS(D{r})<0.005,"OK","REVISAR"))')]))
widths2 = [22,18,26,14,12,12]
cols2 = '<cols>' + ''.join(f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i,w in enumerate(widths2)) + '</cols>'
sheet2 = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
 + cols2 + '<sheetData>' + ''.join(rows2) + '</sheetData></worksheet>')

# ---------- paquete ----------
workbook = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
 '<sheets><sheet name="Datos Materiales" sheetId="1" r:id="rId1"/>'
 '<sheet name="Validación Paridad" sheetId="2" r:id="rId2"/></sheets></workbook>')
wb_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
 '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
 '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>'
 '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
 '</Relationships>')
root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
 '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
 '</Relationships>')
content_types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
 '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
 '<Default Extension="xml" ContentType="application/xml"/>'
 '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
 '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
 '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
 '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
 '</Types>')

out = 'POC_Pricing_Datos_y_Paridad.xlsx'
if os.path.exists(out): os.remove(out)
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', root_rels)
    z.writestr('xl/workbook.xml', workbook)
    z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
    z.writestr('xl/styles.xml', styles)
    z.writestr('xl/worksheets/sheet1.xml', sheet1)
    z.writestr('xl/worksheets/sheet2.xml', sheet2)

import xml.etree.ElementTree as ET
zz = zipfile.ZipFile(out)
for n in zz.namelist():
    ET.fromstring(zz.read(n)); print('wf-ok', n)
print('size', os.path.getsize(out))
# verificación del ejemplo: 12.5*1.35*1.4*7.85
print('ZPRT ejemplo =', round(12.5*1.35*1.4*7.85, 2))
