#!/usr/bin/env python3
# HU-046 — planilhas cliente (ES), xlsx construído à mão (openpyxl indisponível no ambiente).
# Gera: GrupoQ_HU046_Mapeo_Cupos_x_Cuentas.xlsx e GrupoQ_HU046_Codigos_SAP_Centros.xlsx
import zipfile, html, os

def esc(s): return html.escape(str(s), quote=False)

def cell(ref, style, text=None):
    if text is None:
        return f'<c r="{ref}" s="{style}"/>'
    return f'<c r="{ref}" t="inlineStr" s="{style}"><is><t xml:space="preserve">{esc(text)}</t></is></c>'

def col_letter(i):
    s = ''
    while i >= 0:
        s = chr(65 + i % 26) + s
        i = i // 26 - 1
    return s

def row_xml(n, cells, ht=None):
    h = f' ht="{ht}" customHeight="1"' if ht else ''
    return f'<row r="{n}"{h}>{"".join(cells)}</row>'

STYLES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="6">
<font><sz val="10"/><name val="Arial"/></font>
<font><b/><sz val="10"/><name val="Arial"/></font>
<font><b/><sz val="14"/><color rgb="FF16325C"/><name val="Arial"/></font>
<font><i/><sz val="9"/><color rgb="FF808080"/><name val="Arial"/></font>
<font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font>
<font><b/><sz val="10"/><color rgb="FF9C6500"/><name val="Arial"/></font>
</fonts>
<fills count="6">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFF2CC"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF16325C"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF2F2F2"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFE699"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="2">
<border><left/><right/><top/><bottom/><diagonal/></border>
<border><left style="thin"><color rgb="FFB0B7BD"/></left><right style="thin"><color rgb="FFB0B7BD"/></right><top style="thin"><color rgb="FFB0B7BD"/></top><bottom style="thin"><color rgb="FFB0B7BD"/></bottom><diagonal/></border>
</borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="10">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="4" fillId="3" borderId="1" xfId="0" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="2" borderId="1" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="3" fillId="4" borderId="1" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="0" borderId="1" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
<xf numFmtId="0" fontId="5" fillId="5" borderId="1" xfId="0" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>
</cellXfs>
</styleSheet>'''
# estilos: 0 normal | 1 título | 2 nota | 3 header | 4 AMARILLO input | 5 ejemplo gris
#          6 borde  | 7 bold    | 8 borde bold | 9 destaque ámbar (por confirmar)

def sheet_xml(cols_widths, rows, freeze_row=None, merges=None):
    cols = ''.join(f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i, w in enumerate(cols_widths))
    views = '<sheetViews><sheetView workbookViewId="0">'
    if freeze_row:
        views += f'<pane ySplit="{freeze_row}" topLeftCell="A{freeze_row+1}" activePane="bottomLeft" state="frozen"/>'
    views += '</sheetView></sheetViews>'
    mx = f'<mergeCells count="{len(merges)}">' + ''.join(f'<mergeCell ref="{m}"/>' for m in merges) + '</mergeCells>' if merges else ''
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            + views + f'<cols>{cols}</cols><sheetData>' + ''.join(rows) + '</sheetData>' + mx + '</worksheet>')

def build_xlsx(path, sheets):
    n = len(sheets)
    ct = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          + ''.join(f'<Override PartName="/xl/worksheets/sheet{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(n))
          + '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '</Types>')
    root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                 '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
                 '</Relationships>')
    wb = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
          + ''.join(f'<sheet name="{esc(name)}" sheetId="{i+1}" r:id="rId{i+1}"/>' for i, (name, _) in enumerate(sheets))
          + '</sheets></workbook>')
    wb_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
               '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
               + ''.join(f'<Relationship Id="rId{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i+1}.xml"/>' for i in range(n))
               + f'<Relationship Id="rId{n+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
               '</Relationships>')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct)
        z.writestr('_rels/.rels', root_rels)
        z.writestr('xl/workbook.xml', wb)
        z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
        z.writestr('xl/styles.xml', STYLES)
        for i, (_, xml) in enumerate(sheets):
            z.writestr(f'xl/worksheets/sheet{i+1}.xml', xml)
    print('OK', path)

def hdr_row(n, headers, start=0):
    return row_xml(n, [cell(f'{col_letter(start+i)}{n}', 3, h) for i, h in enumerate(headers)], ht=28)

def data_row(n, values, styles_):
    return row_xml(n, [cell(f'{col_letter(i)}{n}', s, v) for i, (v, s) in enumerate(zip(values, styles_))])

# ============================================================================
# PLANILHA 1 — Mapeo cupos × cuentas
# ============================================================================
plain = {'Ayarco':'GrupoQ Ayarco','Guapiles':'GrupoQ Guapiles','Liberia':'GrupoQ Liberia',
         'Lindora':'GrupoQ Lindora','Pérez Zeledón':'GrupoQ Perez Zeledon','San Carlos':'GrupoQ San Carlos',
         'Uruca':'GrupoQ La Uruca'}
forland = {'Guapiles':'GrupoQ Forland Guapiles','Liberia':'GrupoQ Forland Liberia',
           'Pérez Zeledón':'GrupoQ Forland Perez Zeledon','San Carlos':'GrupoQ Forland San Carlos',
           'Uruca':'GrupoQ Forland La Uruca Sucursal Central'}
cr = [('Ayarco',['CADILLAC','CHEVROLET','HYUNDAI']),
      ('Guapiles',['CHEVROLET','FORLAND','HYUNDAI','ISUZU']),
      ('Liberia',['CHEVROLET','FORLAND','GWM','HYUNDAI','ISUZU']),
      ('Lindora',['CADILLAC','CHEVROLET','HYUNDAI']),
      ('Pérez Zeledón',['CHEVROLET','FORLAND','HYUNDAI','ISUZU']),
      ('San Carlos',['CHEVROLET','FORLAND','HYUNDAI','ISUZU']),
      ('Terrazas',['ARCFOX','GWM']),
      ('Uruca',['CADILLAC','CHEVROLET','FORLAND','HYUNDAI','ISUZU'])]
ni = [('Managua',['CHERY','CHEVROLET','FORLAND','NISSAN']),
      ('Chinandega',['CHERY','CHEVROLET','FORLAND','NISSAN']),
      ('Estelí',['CHEVROLET','NISSAN'])]

map_rows = []
for suc, marcas in cr:
    for m in marcas:
        if suc == 'Terrazas':
            map_rows.append(('CR', m, suc, 'GrupoQ Terrazas Lindora', 'C105', 'POR CONFIRMAR', 'Ver pregunta 2'))
        elif m == 'FORLAND':
            map_rows.append(('CR', m, suc, forland[suc], 'C105', 'OK', 'Cuenta dedicada de la marca'))
        elif m == 'GWM' and suc == 'Liberia':
            map_rows.append(('CR', m, suc, '(por definir)', '¿?', 'POR CONFIRMAR', 'Ver pregunta 1'))
        else:
            map_rows.append(('CR', m, suc, plain[suc], 'C101', 'OK', ''))
for suc, marcas in ni:
    for m in marcas:
        if suc == 'Managua':
            map_rows.append(('NI', m, suc, 'GrupoQ Active Motors Managua', 'N105', 'POR CONFIRMAR', 'Ver pregunta 3'))
        else:
            map_rows.append(('NI', m, suc, '(no existe cuenta)', '—', 'SIN CUENTA', 'Se creará con el rollout de NI'))

# --- Hoja Instrucciones ---
r = []
r.append(row_xml(1, [cell('A1', 1, 'Cupos Demo/Exhibición × Cuentas (Sucursales) en Salesforce')], ht=22))
r.append(row_xml(2, [cell('A2', 2, 'HU-046 · Vehículos de demostración y exhibición · Preparado por el equipo de implementación · 06/08/2026')]))
textos = [
 '', 'OBJETIVO',
 'Estamos enlazando cada cupo de Demo/Exhibición (lista 202606 DEMOEXH) con la cuenta de sucursal (dealer) que ya existe en Salesforce, para que el sistema encuentre el cupo de una unidad automáticamente. Necesitamos que confirmen el mapeo propuesto y respondan 5 preguntas.',
 '', 'CÓMO COMPLETAR',
 '1) Hoja "Preguntas clave": respondan las 5 preguntas en las celdas AMARILLAS.',
 '2) Hoja "Mapeo CR y NI": revisen la columna "Cuenta Salesforce propuesta" y marquen SÍ/NO en la celda amarilla "¿Correcto?". Si es NO, indiquen la cuenta correcta en "Corrección".',
 '3) Hoja "Cuentas sin cupo": para cada cuenta, indiquen si hace demo/exhibición y, si aplica, sus cupos.',
 '', 'LEYENDA',
 'AMARILLO = celda a completar por GrupoQ · ÁMBAR = fila que requiere su confirmación · Ejemplo de respuesta: ¿Correcto? = "SÍ" / o "NO" + Corrección = "GrupoQ Forland Liberia".',
 '', 'NOTA',
 'Guatemala, Honduras, Panamá y El Salvador aún no tienen cuentas de sucursal en Salesforce; sus cupos se enlazarán durante el rollout de cada país. Este ejercicio cubre Costa Rica y Nicaragua.',
]
for i, t in enumerate(textos, start=3):
    st = 7 if t in ('OBJETIVO', 'CÓMO COMPLETAR', 'LEYENDA', 'NOTA') else 0
    r.append(row_xml(i, [cell(f'A{i}', st, t)], ht=None if st == 7 or not t else 26))
hoja_instr1 = sheet_xml([120], r)

# --- Hoja Preguntas clave ---
pregs = [
 ('1', 'GWM en Liberia', 'No existe una cuenta GWM en Liberia. ¿Qué sucursal (cuenta) vende GWM en Liberia: GrupoQ Liberia (C101) o GrupoQ Forland Liberia (C105)? ¿U otra?'),
 ('2', 'Terrazas', '¿Los cupos de ARCFOX y GWM de la sucursal "Terrazas" corresponden a la cuenta "GrupoQ Terrazas Lindora" (C105)?'),
 ('3', 'Nicaragua — Managua', '¿La cuenta "GrupoQ Active Motors Managua" (N105) atiende los 4 cupos de Managua (Chery, Chevrolet, Forland, Nissan)? (Detalle: el nombre en Salesforce tiene un espacio doble — lo corregiremos.)'),
 ('4', 'Cuentas C105 sin cupo', 'Las cuentas Active Motors Paseo Las Flores / SABANA / Sucursal Central, Vehículos La Uruca y Ventas Guapiles NO tienen fila en la lista de cupos. ¿Hacen demo/exhibición? Si sí, ¿cuáles son sus cupos por marca?'),
 ('5', 'Alcance', '¿Confirman que La Uruca Repuestos, Uruca Flotas y Uruca Usados quedan FUERA del modelo de cupos demo (aplica solo a venta de vehículo nuevo)?'),
]
r = []
r.append(row_xml(1, [cell('A1', 1, 'Preguntas clave (5)')], ht=22))
r.append(hdr_row(3, ['#', 'Tema', 'Pregunta', 'Respuesta GrupoQ', 'Comentario']))
for i, (num, tema, preg) in enumerate(pregs, start=4):
    r.append(data_row(i, [num, tema, preg, '', ''], [6, 8, 6, 4, 4]))
hoja_pregs = sheet_xml([4, 22, 78, 30, 30], r, freeze_row=3)

# --- Hoja Mapeo ---
r = []
r.append(row_xml(1, [cell('A1', 1, 'Mapeo de cupos × cuentas — Costa Rica y Nicaragua')], ht=22))
r.append(hdr_row(3, ['País', 'Marca (cupo)', 'Sucursal (lista de cupos)', 'Cuenta Salesforce propuesta', 'Sociedad', 'Estado', 'Observación', '¿Correcto? (SÍ/NO)', 'Corrección / Comentario']))
for i, (pais, m, suc, cta, soc, est, obs) in enumerate(map_rows, start=4):
    base = 6 if est == 'OK' else 9
    r.append(data_row(i, [pais, m, suc, cta, soc, est, obs, '', ''], [base, base, base, base, base, base, base, 4, 4]))
hoja_mapeo = sheet_xml([6, 13, 17, 34, 9, 15, 26, 12, 26], r, freeze_row=3)

# --- Hoja Cuentas sin cupo ---
extras = [
 ('GrupoQ La Uruca Repuestos', 'C101', 'Línea de repuestos — asumimos FUERA del alcance demo'),
 ('GrupoQ Uruca Flotas', 'C101', 'Flotas — asumimos FUERA del alcance demo'),
 ('GrupoQ Uruca Usados', 'C101', 'Usados — demo aplica a vehículo nuevo; asumimos FUERA'),
 ('GrupoQ Active Motors Paseo Las Flores', 'C105', 'Sin fila en la lista de cupos'),
 ('GrupoQ Active Motors SABANA', 'C105', 'Sin fila en la lista de cupos'),
 ('GrupoQ Active Motors Sucursal Central', 'C105', 'Sin fila en la lista de cupos'),
 ('GrupoQ Vehículos La Uruca', 'C105', 'Sin fila en la lista de cupos — ¿qué marca/línea vende?'),
 ('GrupoQ Ventas Guapiles', 'C105', 'Sin fila en la lista de cupos — ¿qué marca/línea vende?'),
]
r = []
r.append(row_xml(1, [cell('A1', 1, 'Cuentas de sucursal SIN fila en la lista de cupos')], ht=22))
r.append(hdr_row(3, ['Cuenta en Salesforce', 'Sociedad', 'Situación', '¿Hace demo/exhibición? (SÍ/NO)', 'Cupos por marca / Comentario']))
for i, (cta, soc, sit) in enumerate(extras, start=4):
    r.append(data_row(i, [cta, soc, sit, '', ''], [6, 6, 6, 4, 4]))
hoja_extras = sheet_xml([36, 9, 42, 16, 34], r, freeze_row=3)

build_xlsx('hu046/GrupoQ_HU046_Mapeo_Cupos_x_Cuentas.xlsx', [
    ('Instrucciones', hoja_instr1),
    ('Preguntas clave', hoja_pregs),
    ('Mapeo CR y NI', hoja_mapeo),
    ('Cuentas sin cupo', hoja_extras),
])

# ============================================================================
# PLANILHA 2 — Códigos SAP de centro por cuenta
# ============================================================================
dealers = [
 ('GrupoQ Ayarco', 'C101', 'CR'), ('GrupoQ Guapiles', 'C101', 'CR'), ('GrupoQ La Uruca', 'C101', 'CR'),
 ('GrupoQ La Uruca Repuestos', 'C101', 'CR'), ('GrupoQ Liberia', 'C101', 'CR'), ('GrupoQ Lindora', 'C101', 'CR'),
 ('GrupoQ Perez Zeledon', 'C101', 'CR'), ('GrupoQ San Carlos', 'C101', 'CR'), ('GrupoQ Uruca Flotas', 'C101', 'CR'),
 ('GrupoQ Uruca Usados', 'C101', 'CR'),
 ('GrupoQ Active Motors Paseo Las Flores', 'C105', 'CR'), ('GrupoQ Active Motors SABANA', 'C105', 'CR'),
 ('GrupoQ Active Motors Sucursal Central', 'C105', 'CR'), ('GrupoQ Forland Guapiles', 'C105', 'CR'),
 ('GrupoQ Forland La Uruca Sucursal Central', 'C105', 'CR'), ('GrupoQ Forland Liberia', 'C105', 'CR'),
 ('GrupoQ Forland Perez Zeledon', 'C105', 'CR'), ('GrupoQ Forland San Carlos', 'C105', 'CR'),
 ('GrupoQ Terrazas Lindora', 'C105', 'CR'), ('GrupoQ Vehiculos La Uruca', 'C105', 'CR'),
 ('GrupoQ Ventas Guapiles', 'C105', 'CR'),
 ('GrupoQ Active Motors Managua', 'N105', 'NI'),
]
r = []
r.append(row_xml(1, [cell('A1', 1, 'Códigos SAP de centro por sucursal (cuenta) en Salesforce')], ht=22))
r.append(row_xml(2, [cell('A2', 2, 'HU-046 · Preparado por el equipo de implementación · 06/08/2026')]))
textos2 = [
 '', 'OBJETIVO',
 'Necesitamos el código SAP del centro que corresponde a cada sucursal (cuenta dealer) de Salesforce. Lo usaremos para: (1) guardarlo como "Account Number" de la cuenta, y (2) enlazar automáticamente cada unidad con su cupo de Demo/Exhibición por código (más robusto que por nombre).',
 '', 'CÓMO COMPLETAR',
 'Completen la columna AMARILLA "Código SAP del centro" en la hoja "Códigos", según su catálogo de centros SAP. La primera fila es un EJEMPLO del formato (gris) — no la modifiquen ni la tomen como dato real. Si una sucursal tiene más de un centro, indíquenlo en Comentario.',
 '', 'NOTA',
 'Las sucursales de GT, HN, PA y SV se agregarán cuando existan sus cuentas en Salesforce (rollout por país).',
]
for i, t in enumerate(textos2, start=3):
    st = 7 if t in ('OBJETIVO', 'CÓMO COMPLETAR', 'NOTA') else 0
    r.append(row_xml(i, [cell(f'A{i}', st, t)], ht=None if st == 7 or not t else 26))
hoja_instr2 = sheet_xml([120], r)

r = []
r.append(row_xml(1, [cell('A1', 1, 'Códigos SAP de centro')], ht=22))
r.append(hdr_row(3, ['#', 'Cuenta (sucursal) en Salesforce', 'Sociedad', 'País', 'Código SAP del centro', 'Comentario']))
r.append(data_row(4, ['—', '(EJEMPLO) GrupoQ Sucursal Modelo', 'C101', 'CR', 'C0XX', 'Formato de ejemplo — no es un dato real'], [5, 5, 5, 5, 5, 5]))
for i, (cta, soc, pais) in enumerate(dealers, start=5):
    r.append(data_row(i, [str(i-4), cta, soc, pais, '', ''], [6, 6, 6, 6, 4, 4]))
hoja_cod = sheet_xml([4, 40, 9, 6, 18, 32], r, freeze_row=3)

build_xlsx('hu046/GrupoQ_HU046_Codigos_SAP_Centros.xlsx', [
    ('Instrucciones', hoja_instr2),
    ('Códigos', hoja_cod),
])
