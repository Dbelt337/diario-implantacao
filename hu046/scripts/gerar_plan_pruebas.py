#!/usr/bin/env python3
# HU-046 — Plan de pruebas funcional (ES) — xlsx a mano (sin openpyxl en el ambiente).
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

STYLES = open(os.path.join(os.path.dirname(__file__), '_styles_cache.xml')).read() if os.path.exists(os.path.join(os.path.dirname(__file__), '_styles_cache.xml')) else '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
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
# 0 normal | 1 título | 2 nota | 3 header | 4 amarillo input | 5 ejemplo gris | 6 borde | 7 bold | 8 borde bold | 9 ámbar

def sheet_xml(cols_widths, rows, freeze_row=None):
    cols = ''.join(f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i, w in enumerate(cols_widths))
    views = '<sheetViews><sheetView workbookViewId="0">'
    if freeze_row:
        views += f'<pane ySplit="{freeze_row}" topLeftCell="A{freeze_row+1}" activePane="bottomLeft" state="frozen"/>'
    views += '</sheetView></sheetViews>'
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            + views + f'<cols>{cols}</cols><sheetData>' + ''.join(rows) + '</sheetData></worksheet>')

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
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ct)
        z.writestr('_rels/.rels', root_rels)
        z.writestr('xl/workbook.xml', wb)
        z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
        z.writestr('xl/styles.xml', STYLES)
        for i, (_, xml) in enumerate(sheets):
            z.writestr(f'xl/worksheets/sheet{i+1}.xml', xml)
    print('OK', path)

def hdr_row(n, headers):
    return row_xml(n, [cell(f'{col_letter(i)}{n}', 3, h) for i, h in enumerate(headers)], ht=28)

def data_row(n, values, styles_):
    return row_xml(n, [cell(f'{col_letter(i)}{n}', s, v) for i, (v, s) in enumerate(zip(values, styles_))])

# ---------------- Hoja 1: Preparación ----------------
r = []
r.append(row_xml(1, [cell('A1', 1, 'HU-046 · Plan de pruebas funcional — Vehículos Demo/Exhibición')], ht=22))
r.append(row_xml(2, [cell('A2', 2, 'Sandbox DevSales · Ejecutar ANTES de liberar a validación del cliente y QA · 06/08/2026')]))
prep = [
 '', 'ALCANCE',
 'Cubre los 6 flows de la HU-046 (2 subflows, guarda de venta en Opportunity, scheduled de liberación, 2 pantallas), los 2 permission sets, la visibilidad de las App Pages y la regresión de la validation rule de HU-025. NO cubre: CBSF (T01/T02, config aparte), fin de ciclo por km (T12, bloqueado por D6) y derivación automática de marca/sucursal (v2, espera datos de inventario).',
 '', 'CÓMO PROBAR FLOWS SIN APEX (guía rápida)',
 '1) Pantallas (Manage / Execute): botón Debug del Flow Builder ANTES de activar — ojo: el Debug de pantallas EJECUTA DML real (crea Tasks, actualiza Vehicles). Usar solo datos DEMO-TEST-*.',
 '2) Record-triggered (Opportunity Before Handler): activar el flow y probar creando/editando Opportunities reales de prueba. En Debug se puede elegir un registro y "rollback mode" para ensayar sin guardar.',
 '3) Scheduled (Release Expired): Debug del Builder con un registro de muestra; para la corrida real, activar y esperar las 06:00 UTC o ajustar la hora de inicio.',
 '4) Orden de activación: ValidateDemoQuota + LogDemoActivity → OpportunityBeforeHandler → ReleaseExpiredDemoAssignments → pantallas.',
 '5) Nota prod: los flows se despliegan inactivos por defecto; si se decide desplegarlos activos, Salesforce exige cobertura de pruebas de flow (75%) — decisión para el plan de release, no bloquea sandbox.',
 '', 'DATOS DE PRUEBA (crear una vez, prefijo DEMO-TEST)',
 'VEHÍCULOS (Object Manager > Vehicle > New, con VehicleDefinition cualquiera): V1 "DEMO-TEST-001" Status = En ubicación de concesionario · V2 "DEMO-TEST-002" Status = En demostración · V3 "DEMO-TEST-003" Status = En exhibicion (SIN acento) · V4 "DEMO-TEST-004" Status = En servicio.',
 'CUPOS: usar los registros reales del CMDT; para probar "cupo lleno" crear registro DemoCapacityConfig "TEST_TEST_Test" con MaxDemo=1, MaxExhibition=0 (Setup > Custom Metadata Types) y solicitar 2 designaciones.',
 'USUARIOS: U1 Gerente = usuario con PS Demo Vehicle Management · U2 Encargado = usuario con PS Demo Vehicle Execution · U3 Vendedor = usuario SIN los PS demo · U4 Integración/Admin = usuario con custom permission Bypass_Gates_Automacao (el mismo de los gates HU-025).',
 'CUENTA + OPPS: 1 Account de prueba; Opportunities con record type GQOpportunitiesAutos y GQOpportunitiesRepuestosPA.',
 '', 'CRITERIO DE SALIDA',
 'Todos los casos en PASA (o fallos documentados con defecto abierto). Evidencia = captura de pantalla o Id del registro en la columna Evidencia. Solo entonces liberar a validación del cliente / QA.',
]
for i, t in enumerate(prep, start=3):
    st = 7 if t in ('ALCANCE', 'CÓMO PROBAR FLOWS SIN APEX (guía rápida)', 'DATOS DE PRUEBA (crear una vez, prefijo DEMO-TEST)', 'CRITERIO DE SALIDA') else 0
    r.append(row_xml(i, [cell(f'A{i}', st, t)], ht=None if st == 7 or not t else 40))
hoja_prep = sheet_xml([130], r)

# ---------------- Hoja 2: Casos ----------------
C = []  # (id, componente, titulo, precondicion, pasos, esperado)
C.append(('PRE-01','Setup','Flows activos en orden','Deploy v3/v4 completo (handler v3 + ExecuteDemoRequest con Vehiculo__c)','Setup > Flows: verificar versión ACTIVA de los 6 flows','Subflows, handler, scheduled y pantallas activos; sin versión Draft posterior a la activa'))
C.append(('PRE-02','Setup','Datos y usuarios de prueba listos','—','Crear V1–V4, CMDT TEST, U1–U4 según hoja Preparación','Todo creado; V3 con API name "En exhibicion" SIN acento'))
C.append(('MDV-01','Pantalla gerencia','Visibilidad por custom permission','App Page "Vehículos Demo" publicada con component visibility {!$Permission.RequestDemoVehicle}','Entrar como U1 y como U3 a la app GrupoQ Ventas','U1 ve la pantalla; U3 NO ve el componente'))
C.append(('MDV-02','Pantalla gerencia','Solicitar designación Demo con cupo disponible','V1 en estado concesionario; cupo TEST con espacio','U1: rama Solicitar, VIN DEMO-TEST-001, tipo Demo, marca/sucursal del cupo TEST','Task "[Demo] Solicitud..." creada al encargado + notificación + Task de traza; V1 NO cambia de estado todavía'))
C.append(('MDV-03','Pantalla gerencia','Cupo lleno bloquea la solicitud','CMDT TEST MaxDemo=1 y ya hay 1 unidad en demo de esa marca/sucursal','U1 solicita una 2ª designación Demo','Mensaje de cupo no disponible; NO se crean Tasks'))
C.append(('MDV-04','Pantalla gerencia','Marca/sucursal sin fila de cupo','Combinación inexistente en el CMDT','U1 solicita con esa combinación','Mensaje de "sin configuración de cupo" (no error técnico)'))
C.append(('MDV-05','Pantalla gerencia','VIN inexistente','—','U1 ingresa VIN "NO-EXISTE"','Pantalla "No se encontró la unidad"; permite volver'))
C.append(('MDV-06','Pantalla gerencia','Asignar/reasignar asesor','V2 en demostración','U1: rama Asignar, asesor destino','SerializedProduct.OwnerId actualizado + Task de traza "[Demo] Asignación"'))
C.append(('MDV-07','Pantalla gerencia','Solicitar liberación para venta','V2 en demostración','U1: rama Liberar','Task "[Demo] Solicitud..." al encargado + notificación; estado aún sin cambio'))
C.append(('MDV-08','Pantalla gerencia','Cancelar asignación excepcional','Asignación vigente de MDV-06','U1: rama Cancelar, owner anterior','OwnerId revertido + traza; SIN otros cambios'))
C.append(('EDR-01','Pantalla encargado','Solo mis solicitudes pendientes','Tasks [Demo] de U2 y de otro usuario','U2 abre Execute Demo Request','El selector lista SOLO Tasks "[Demo] Solicitud" de U2 no completadas'))
C.append(('EDR-02','Pantalla encargado','Ejecutar designación Demo','Solicitud pendiente de MDV-02','U2 ejecuta designación, tipo Demo, VIN V1','Vehicle.Status = En demostración; Task de solicitud Completed; traza creada'))
C.append(('EDR-03','Pantalla encargado','Ejecutar designación Exhibición','Nueva solicitud tipo Exhibición','U2 ejecuta con tipo Exhibición','Vehicle.Status = "En exhibicion" (SIN acento) — verificar valor exacto'))
C.append(('EDR-04','Pantalla encargado','Liberación destino concesionario','Solicitud de liberación de MDV-07','U2 ejecuta liberación, destino "En ubicación de concesionario"','Status actualizado; Opportunity creada RT GQOpportunitiesAutos, Vehiculo__c = unidad, Stage Prospecting, CloseDate +30; Task Completed; traza'))
C.append(('EDR-05','Pantalla encargado','Liberación destino Demo venta','Otra unidad en demo','U2 libera con destino "Demo venta"','Status = Demo venta; ConditionType SIGUE Nuevo; Opportunity creada con Vehiculo__c'))
C.append(('EDR-06','Pantalla encargado','VIN inexistente','—','U2 ingresa VIN inválido','Pantalla de no encontrado; nada se ejecuta'))
C.append(('OBH-01','Guarda Opportunity','Bloquea unidad En demostración','Handler v3 activo','Como U3/U1: crear Opp RT Autos con Vehiculo__c = V2','Error visible: "Esta unidad está designada como Demo/Exhibición..." — la Opp NO se guarda'))
C.append(('OBH-02','Guarda Opportunity','Bloquea unidad En exhibicion','—','Crear Opp RT Autos con Vehiculo__c = V3','Bloqueada igual (cubre el valor sin acento)'))
C.append(('OBH-03','Guarda Opportunity','Permite unidad vendible','—','Crear Opp RT Autos con Vehiculo__c = V4 (En servicio)','Se guarda sin error'))
C.append(('OBH-04','Guarda Opportunity','Bloquea cambio de link a unidad demo','Opp de OBH-03 guardada','Editar la Opp y cambiar Vehiculo__c a V2','Bloqueada al guardar'))
C.append(('OBH-05','Guarda Opportunity','NO re-dispara en ediciones ajenas','Opp con Vehiculo__c = V2 creada ANTES de activar el handler (o vía bypass)','Editar solo el monto/fecha sin tocar Vehiculo__c','Se guarda: la guarda solo evalúa cuando el link es nuevo o cambia'))
C.append(('OBH-06','Guarda Opportunity','Repuestos/PA exento','—','Crear Opp RT GQOpportunitiesRepuestosPA con Vehiculo__c = V2','Se guarda: repuestos para unidad demo es legítimo'))
C.append(('OBH-07','Guarda Opportunity','Bypass gates org','U4 con Bypass_Gates_Automacao','U4 crea Opp RT Autos con Vehiculo__c = V2','Se guarda (bypass del patrón HU-025)'))
C.append(('OBH-08','Guarda Opportunity','Bypass demo-específico','Usuario con BypassAllocationValidation','Crear Opp RT Autos con V2','Se guarda'))
C.append(('OBH-09','Guarda Opportunity','No bloquea la liberación del propio flow','—','Repetir EDR-04 con handler ACTIVO','La Opportunity de liberación se crea sin error (el status cambia antes)'))
C.append(('SCH-01','Scheduled liberación','Cierra asignación vencida','Task "[Demo] Asignación" abierta con ActivityDate de ayer (editar fecha)','Debug/corrida del flow ReleaseExpiredDemoAssignments','Task marcada Completed (asignación terminada)'))
C.append(('SCH-02','Scheduled liberación','Regla de día hábil (WEEKDAY)','Task de un viernes','Simular corrida de sábado/domingo/lunes','Vence recién el lunes (día hábil siguiente), no el fin de semana'))
C.append(('SCH-03','Scheduled liberación','No toca asignaciones vigentes','Task [Demo] Asignación de HOY','Corrida del flow','Task sigue abierta'))
C.append(('LOG-01','Traza','Toda acción deja Task de traza','Ejecutar MDV-02, EDR-02, EDR-04, MDV-08','Revisar Activity del Vehicle','Una Task "[Demo] <acción>" por acción, con detalles y owner correcto'))
C.append(('PSV-01','Permisos','Accesos del PS Management','U1 sin otros PS de más','U1: leer Vehicle, editar SerializedProduct.OwnerId, intentar editar Vehicle.Status a mano','Lectura OK; edición SP OK; el estado lo cambia solo el flow del encargado (U1 no tiene edit de Vehicle)'))
C.append(('PSV-02','Permisos','Accesos del PS Execution','U2','U2 ejecuta designación y liberación completas (EDR-02/04)','Sin errores de permisos (Vehicle edit, SP edit, Opportunity create)'))
C.append(('PSV-03','Permisos','Sin PS = sin acceso','U3','U3 intenta abrir las 2 App Pages (incluso por URL directa)','No ve el componente de gerencia; el flow del encargado falla o no es visible según diseño'))
C.append(('REG-01','Regresión HU-025','VR Reserva Confirmada intacta','VR Opp_Retail_Vehiculo_Cotizacion activa','Opp RT Autos → pasar a Reserva Confirmada SIN Vehiculo__c','Error de la VR (comportamiento previo intacto)'))
C.append(('REG-02','Regresión HU-025','VR Cotización Confirmada intacta','—','Opp RT Autos → Cotización Confirmada sin productos','Error de la VR exigiendo producto'))
C.append(('REG-03','Regresión Repuestos','Búsqueda de vehículo sigue poblando el campo','Flujo Repuestos/PA operativo','Crear Opp Repuestos vía búsqueda de vehículo (VIN/Placa)','Vehiculo__c poblado normal; sin interferencia de la guarda'))
C.append(('FHT-01','Field History','Historial de Status/Owner (T13)','FHT habilitado en Vehicle y SerializedProduct','Ejecutar EDR-02 y MDV-06; revisar History','Cambios de Status y Owner registrados con usuario y fecha/hora'))

r = []
r.append(row_xml(1, [cell('A1', 1, 'Casos de prueba (36) — ejecutar en orden; OBH requiere handler v3 activo')], ht=22))
r.append(hdr_row(3, ['ID', 'Componente', 'Título', 'Precondición', 'Pasos', 'Resultado esperado', 'Resultado obtenido', 'Estado (PASA/FALLA/BLOQ)', 'Evidencia (Id/captura)']))
for i, (cid, comp, tit, pre, pasos, esp) in enumerate(C, start=4):
    r.append(data_row(i, [cid, comp, tit, pre, pasos, esp, '', '', ''], [8, 6, 8, 6, 6, 6, 4, 4, 4]))
hoja_casos = sheet_xml([9, 15, 26, 30, 40, 44, 24, 12, 18], r, freeze_row=3)

build_xlsx('hu046/GrupoQ_HU046_Plan_de_Pruebas.xlsx', [
    ('Preparación', hoja_prep),
    ('Casos de prueba', hoja_casos),
])
