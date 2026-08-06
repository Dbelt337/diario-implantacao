#!/usr/bin/env python3
# Mapeo de cargas SAP -> Salesforce (GrupoQ) — xlsx a mano (sin openpyxl).
import zipfile, html, os

def esc(s): return html.escape(str(s), quote=False)
def cell(ref, style, text=None):
    if text is None: return f'<c r="{ref}" s="{style}"/>'
    return f'<c r="{ref}" t="inlineStr" s="{style}"><is><t xml:space="preserve">{esc(text)}</t></is></c>'
def col_letter(i):
    s=''
    while i>=0: s=chr(65+i%26)+s; i=i//26-1
    return s
def row_xml(n, cells, ht=None):
    h=f' ht="{ht}" customHeight="1"' if ht else ''
    return f'<row r="{n}"{h}>{"".join(cells)}</row>'

STYLES='''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="6"><font><sz val="10"/><name val="Arial"/></font><font><b/><sz val="10"/><name val="Arial"/></font><font><b/><sz val="14"/><color rgb="FF16325C"/><name val="Arial"/></font><font><i/><sz val="9"/><color rgb="FF808080"/><name val="Arial"/></font><font><b/><sz val="10"/><color rgb="FFFFFFFF"/><name val="Arial"/></font><font><b/><sz val="10"/><color rgb="FF9C6500"/><name val="Arial"/></font></fonts>
<fills count="6"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFF2CC"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FF16325C"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFF2F2F2"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFE699"/><bgColor indexed="64"/></patternFill></fill></fills>
<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border><border><left style="thin"><color rgb="FFB0B7BD"/></left><right style="thin"><color rgb="FFB0B7BD"/></right><top style="thin"><color rgb="FFB0B7BD"/></top><bottom style="thin"><color rgb="FFB0B7BD"/></bottom><diagonal/></border></borders>
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
</cellXfs></styleSheet>'''
# 0 normal | 1 titulo | 2 nota | 3 header | 4 amarillo | 6 borde | 7 bold | 8 borde bold | 9 ambar

def sheet_xml(cols, rows, freeze=None):
    c=''.join(f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i,w in enumerate(cols))
    v='<sheetViews><sheetView workbookViewId="0">'
    if freeze: v+=f'<pane ySplit="{freeze}" topLeftCell="A{freeze+1}" activePane="bottomLeft" state="frozen"/>'
    v+='</sheetView></sheetViews>'
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            +v+f'<cols>{c}</cols><sheetData>'+''.join(rows)+'</sheetData></worksheet>')

def build(path, sheets):
    n=len(sheets)
    ct=('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        +''.join(f'<Override PartName="/xl/worksheets/sheet{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(n))
        +'<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>')
    rr='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'
    wb=('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
        +''.join(f'<sheet name="{esc(nm)}" sheetId="{i+1}" r:id="rId{i+1}"/>' for i,(nm,_) in enumerate(sheets))+'</sheets></workbook>')
    wr=('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        +''.join(f'<Relationship Id="rId{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i+1}.xml"/>' for i in range(n))
        +f'<Relationship Id="rId{n+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>')
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml',ct); z.writestr('_rels/.rels',rr)
        z.writestr('xl/workbook.xml',wb); z.writestr('xl/_rels/workbook.xml.rels',wr)
        z.writestr('xl/styles.xml',STYLES)
        for i,(_,x) in enumerate(sheets): z.writestr(f'xl/worksheets/sheet{i+1}.xml',x)
    print('OK',path)

def hdr(n,hs): return row_xml(n,[cell(f'{col_letter(i)}{n}',3,h) for i,h in enumerate(hs)],ht=26)
def dr(n,vals,sts): return row_xml(n,[cell(f'{col_letter(i)}{n}',s,v) for i,(v,s) in enumerate(zip(vals,sts))])

H=['Origen SAP (tabla/campo)','Destino Salesforce (objeto.campo)','Tipo SF','Regla / Transformación','Clave / Upsert','Estado','Observación']
def tab(title, rows, note=None):
    r=[row_xml(1,[cell('A1',1,title)],ht=22)]
    if note: r.append(row_xml(2,[cell('A2',2,note)]))
    r.append(hdr(3,H))
    for i,(vals,pend) in enumerate(rows,start=4):
        base=9 if pend else 6
        r.append(dr(i,vals,[base]*7))
    return sheet_xml([30,34,14,36,22,13,36],r,freeze=3)

# ---- Hoja 1: Patrones ----
r=[row_xml(1,[cell('A1',1,'Mapeo de cargas SAP → Salesforce · GrupoQ Automotive')],ht=22),
   row_xml(2,[cell('A2',2,'v1.0 · 07/08/2026 · basado en describes reales de la org (Account 07/08, Vehicle/Asset/Product2/VehicleDefinition 05-06/08) · alcance: rollout Costa Rica')])]
pat=[
 '','PRINCIPIO','SAP = libro razón (stock, movimientos, bloqueos, finanzas). Salesforce = capa de engagement (unidad individual, estado comercial, pipeline). No replicar lo consultable: precio on-line (RFC), stock cuantitativo no se copia.',
 '','PATRONES (industria / MuleSoft)',
 '1) CATÁLOGO (maestro de materiales): IDoc MATMAS event-driven o delta batch — accelerator MuleSoft "product sync". Cadencia: por cambio.',
 '2) UNIDADES (inventario de vehículos, SAP VMS/VLCVEHICLE): batch programado cada X horas vía Bulk API 2.0, upsert IDEMPOTENTE por VIN. 10k registros = 1 job Bulk, nunca 10k llamadas.',
 '3) TIEMPO REAL SF→SAP: platform events (patrón SapOrderResponse__e / RegisterUsedVehicleEvent__e de la org) — sin callouts síncronos en flows.',
 '4) CLAVES: lookups resueltos por External ID en el payload (relationship by external key) — elimina prefetch; Ids NUNCA (cambian entre sandboxes).',
 '5) SEGURIDAD: usuario de integración con PS propio (FLS a los campos del mapping — hoy le falta Sociedad__c), OAuth/cert.',
 '','ESTRATEGIA DE CLAVES EN CUENTAS (decisión 07/08)',
 'HOY: AccountNumber = código visible (C101/C105 sociedades; centro en dealers cuando el cliente lo devuelva). SEMÁNTICO: SourceSystemIdentifier (standard, Text 85) disponible en Account Y Vehicle — candidato a convención cross-objeto para el ID de origen SAP.',
 'ESCALA: ninguno de los dos es indexado/External ID → para upsert-por-clave e índice: campo custom External ID (p.ej. SAPCode__c) O pedir índice custom a soporte SF. Decisión de arquitectura pendiente de aprobación.',
 'Sociedad__c (Text Area 255) EXISTE — filtrable; semántica probable: sociedad DEL CLIENTE (no la cuenta-sociedad). Verificar población antes de usar (query pendiente).',
]
for i,t in enumerate(pat,start=3):
    st=7 if t in ('PRINCIPIO','PATRONES (industria / MuleSoft)','ESTRATEGIA DE CLAVES EN CUENTAS (decisión 07/08)') else 0
    r.append(row_xml(i,[cell(f'A{i}',st,t)],ht=None if st==7 or not t else 40))
h_pat=sheet_xml([135],r)

# ---- Hoja 2: Cuentas ----
cuentas=[
 (['BUKRS (sociedad, ej. C101)','Account (nivel 3).AccountNumber','Text(40)','código tal cual','clave de resolución (WHERE AccountNumber = :BUKRS)','LISTO','C101/C105/N105 a poblar por nosotros (CSV enviado a Diego)'],False),
 (['WERKS (centro)','Account (dealer nivel 4).AccountNumber','Text(40)','código del centro','clave de resolución','PENDIENTE','esperando planilla de códigos del cliente (CR primero)'],True),
 (['BUKRS/WERKS (id de origen)','Account.SourceSystemIdentifier','Text(85)','espejo del código (convención cross-objeto propuesta)','alternativa semántica','DECISIÓN','no indexado; ver hoja Patrones'],True),
 (['nivel jerárquico (derivado)','Account.AccountLevel__c','Picklist','Holding/País/Sociedad/Dealer (VALORES POR CONFIRMAR)','filtro de listados (Flavio)','PENDIENTE','query GROUP BY enviada'],True),
 (['land/país','Account.Country__c','Picklist','código o nombre de país','—','LISTO','existe en la org'],False),
 (['moneda de la sociedad','Account.CurrencyIsoCode','Picklist','CRC/USD/NIO... por sociedad','—','LISTO','org multicurrency'],False),
 (['jerarquía','Account.ParentId','Hierarchy','resolver padre por AccountNumber del nivel superior','por clave, nunca Id fijo','LISTO','holding→país→sociedad→dealer (28 cuentas en DevSales; INT vacío — carga pendiente)'],True),
 (['KUNNR (cliente RPA)','Account.CustomerCodeRPA__c','Text Area(255)','código de cliente SAP','NO sirve de External ID (Text Area)','EXISTENTE','clave de clientes: decisión aparte (fuera del flujo de inventario)'],True),
 (['(atributo del cliente)','Account.Sociedad__c','Text Area(255)','sociedad a la que pertenece el cliente','filtrable (Text Area 255 SÍ filtra)','VERIFICAR','semántica/población por confirmar; dar FLS al usuario de integración'],True),
]
h_cuentas=tab('Cuentas (sociedades, dealers, clientes)',cuentas,'Describe completo de Account 07/08 · Person Accounts habilitadas (clientes = person account; jerarquía GrupoQ = business account, RT BusinessAccount)')

# ---- Hoja 3: Vehículo + Asset ----
veh=[
 (['VLCVEHICLE-VIN','Vehicle.Name','Name','VIN 17 chars (ISO 3779); el punto (.) del re-ingreso queda SOLO en SAP','CLAVE DE UPSERT (unique en la org)','LISTO','identidad de la unidad'],False),
 (['nº inventario VMS','Vehicle.StockCode','Text','número de inventario SAP','por VIN','LISTO','re-ingreso usado = MISMO Vehicle, StockCode nuevo (HU-045 D2)'],False),
 (['id origen','Vehicle.SourceSystemIdentifier','Text','id del registro en SAP','—','LISTO','T18 HU-045'],False),
 (['WERKS del stock','Vehicle.CurrentOwnerId','Lookup(Account)','resolver dealer por código de centro','vía AccountNumber/External ID','PENDIENTE códigos','posesión operativa; alimenta cupos demo HU-046'],True),
 (['marca/modelo/año/versión','Vehicle.Make/Model/ModelYear/TrimLevel','Text/Picklist','del maestro del vehículo','—','LISTO','nativos (D7 HU-045)'],False),
 (['país','Vehicle.LocationCountry/LocationCountryCode','Text','país de la unidad','—','LISTO','único Location* poblado hoy'],False),
 (['sucursal (nombre)','Vehicle.LocationCity','Text','PREMISA DE CARGA: nombre de sucursal igual a lista de cupos','—','PREMISA','sin esto no hay derivación automática de sucursal (wire B v2)'],True),
 (['estado comercial','Vehicle.Status','Picklist','SOLO estado comercial; stock/bloqueos NO se replican','—','LISTO','máquina de estados única (demo/exh/consignación/reparación) — doc con Meli'],True),
 (['— (no viene de SAP)','Vehicle.LastOdometerReading','Number','km capturado en SF (RN2 HU-045)','—','LISTO','NO mapear desde SAP'],False),
 (['BUKRS del stock','Asset.AccountId','Lookup(Account)','resolver SOCIEDAD por código','vía AccountNumber/External ID','LISTO (códigos soc.)','dueño contable del par'],False),
 (['LGORT (almacén)','Asset.LocationId','Lookup(Location)','resolver Location por código/nombre de almacén','ExternalReference de Location','PENDIENTE','Locations no existen aún (T09 — dato del cliente)'],True),
 (['fecha compra original','Asset.PurchaseDate','Date','—','—','LISTO','historial HU-045'],False),
 (['proveedor/entregó','Asset.AssetProvidedById','Lookup','quién entregó la unidad','—','LISTO','HU-045'],False),
 (['MATNR del vehículo','Asset.Product2Id / VehicleDefinition','Lookup','resolver modelo por ProductCode=MATNR','MATNR','LISTO catálogo nuevos','usados de terceros: VD genérica "Used Vehicle" (decisión HU-045)'],False),
 (['comprador (venta)','transferencia CurrentOwnerId → cliente + AssetAccountParticipant','—','proceso de venta, no carga','—','DISEÑO','histórico de dueños'],False),
]
h_veh=tab('Vehículo + Asset (el par de la unidad)',veh,'Regla: TODO Vehicle nace con su par Asset (master-detail). El payload necesita DOS códigos: sociedad (Asset) y centro (CurrentOwner). Bulk API 2.0, upsert por VIN.')

# ---- Hoja 4: Catálogo ----
cat=[
 (['MARA-MATNR','Product2.ProductCode','Text','código de material','CLAVE upsert catálogo','LISTO','IDoc MATMAS / accelerator'],False),
 (['descripción','Product2.Name','Text','—','—','LISTO',''],False),
 (['marca','Product2.BusinessBrandId','Lookup(BusinessBrand)','resolver marca','por nombre de marca','VERIFICAR población','cadena marca: Vehicle→VD→Product2→BusinessBrand'],True),
 (['familia/categoría','Product2.Family / MakeName','Picklist/Text','—','—','LISTO','Family ej. "Autos"'],False),
 (['modelo configurable','VehicleDefinition (Name, ModelCode, VariantName, BodyType)','—','1 VD por modelo/versión','ModelCode','LISTO (224 VD nuevos)','usados terceros: VD genérica compartida'],False),
]
h_cat=tab('Catálogo (modelos) — Product2 / VehicleDefinition',cat,'Cadencia propia (por cambio de maestro), separada de la carga de unidades. ~150k materiales en la región (dimensionamiento HU-030).')

# ---- Hoja 5: Location ----
loc=[
 (['LGORT + WERKS','Location.Name','Text','nombre del almacén','—','PENDIENTE','lista de almacenes = dato del cliente (T09)'],True),
 (['código LGORT','Location.ExternalReference','Text','código SAP del almacén','CLAVE de resolución','PENDIENTE','campo standard de Location para referencia externa'],True),
 (['tipo','Location.LocationType','Picklist','Almacén / Consignación...','—','DEFINIR','consignación usa Location específica (HU-045 RN4)'],True),
]
h_loc=tab('Location (almacenes / bodegas)',loc,'Referenciadas por Asset.LocationId. Crear con la lista del cliente (T09) antes de la carga de unidades que las use.')

# ---- Hoja 6: Pendientes ----
pend=[
 (['1','Códigos SAP de centros CR (planilla con el cliente)','GrupoQ','bloquea CurrentOwnerId por código y BranchCode de cupos'],True),
 (['2','Valores de AccountLevel__c (GROUP BY) + población de Sociedad__c','Diego (query enviada)','define el filtro de listados de Flavio'],True),
 (['3','FLS de Sociedad__c (y demás campos del mapping) al usuario de integración','Admin','error "no existe" de Flavio era FLS'],True),
 (['4','Decisión de clave definitiva: SourceSystemIdentifier vs custom External ID (SAPCode__c)','Arquitectura (Diego+Santiago)','índice + upsert por clave a escala'],True),
 (['5','Lista de almacenes (T09) → crear Locations','GrupoQ → Admin','bloquea Asset.LocationId'],True),
 (['6','Carga de jerarquía de cuentas en INT (CSV en preparación)','Diego/Flavio','INT sin datos hoy'],True),
 (['7','Premisa LocationCity = nombre de sucursal en la carga de unidades','Integración (mapping Mule)','habilita derivación automática (wire B v2 HU-046)'],True),
]
r=[row_xml(1,[cell('A1',1,'Pendientes para cerrar el flujo de cargas')],ht=22), hdr(3,['#','Pendiente','Owner','Impacto'])]
for i,(vals,_) in enumerate(pend,start=4):
    r.append(dr(i,vals,[6,9,6,6]))
h_pend=sheet_xml([4,52,26,42],r,freeze=3)

os.makedirs('integracion',exist_ok=True)
build('integracion/GrupoQ_Mapeo_Cargas_SAP_Salesforce.xlsx',[
 ('Patrones y Claves',h_pat),('Cuentas',h_cuentas),('Vehículo y Asset',h_veh),
 ('Catálogo',h_cat),('Locations',h_loc),('Pendientes',h_pend),
])
