#!/usr/bin/env python3
# Gera Carga_Productos_Precios_Inventario.xlsx (OOXML direto, sem openpyxl).
import zipfile, html

def esc(s):
    return html.escape(str(s), quote=False)

def col_letter(i):
    s = ''
    while i >= 0:
        s = chr(65 + i % 26) + s
        i = i // 26 - 1
    return s

def sheet_xml(widths, title, header, rows):
    cols = ''.join(
        f'<col min="{i+1}" max="{i+1}" width="{w}" customWidth="1"/>' for i, w in enumerate(widths))
    out = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
           '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
           f'<cols>{cols}</cols><sheetData>']
    rnum = 1
    def emit(vals, style):
        nonlocal rnum
        cells = ''.join(
            f'<c r="{col_letter(i)}{rnum}" s="{style}" t="inlineStr"><is><t xml:space="preserve">{esc(v)}</t></is></c>'
            for i, v in enumerate(vals))
        out.append(f'<row r="{rnum}">{cells}</row>')
        rnum += 1
    emit([title] + [''] * (len(header) - 1), 3)
    emit([''] * len(header), 0)
    emit(header, 1)
    for r in rows:
        emit(r, 2)
    out.append('</sheetData></worksheet>')
    return ''.join(out)

carga_header = ['#', 'Objeto (API)', 'Papel en el modelo', 'Campos mínimos a cargar',
                'Clave de upsert / External ID', 'Origen SAP sugerido', 'Volumen / frecuencia', 'Observaciones y decisiones']

carga = [
 ['1', 'Location',
  'Centros/sucursales físicos. Ancla del inventario de vehículos y del Vehicle Inventory Search (búsqueda multi-tienda).',
  'Name, LocationType, ExternalReference, IsInventoryLocation=true',
  'ExternalReference = código del centro (WERKS)',
  'T001W (centros/plantas)',
  'Decenas · carga única + mantenimiento',
  'PENDIENTE T09: lista oficial de centros del GrupoQ. Sin Location no hay búsqueda por ubicación ni traslados (US-037).'],
 ['2', 'Pricebook2',
  'Una lista de precios por sociedad/canal (p.ej. C101-Q1, C105-Q1, N101-Q1, N105-Q1). La Standard ya existe en la org.',
  'Name, IsActive, Description',
  'Name (convención sociedad-canal)',
  'Estructura comercial (org. de ventas / canal de distribución)',
  'Unidades · carga única',
  'La moneda NO vive en la lista: vive en cada PricebookEntry (org multi-moneda).'],
 ['3', 'Product2',
  'Catálogo completo: vehículos, repuestos (ZREP), accesorios y P&A. Base de TODO el flujo guiado.',
  'Name, ProductCode, SapMaterialCode__c, IsActive, Family, Description',
  'SapMaterialCode__c (único + External ID → upsert idempotente y a prueba de duplicados)',
  'MARA + MVKE (maestro de materiales por sociedad/canal) vía réplica Mule',
  'Miles · carga inicial + delta diario/near-real-time',
  'Backfill obligatorio: SapMaterialCode__c = MATNR también en los legados. Family distingue Vehículo / Repuesto / Accesorio (StandardValueSet Product2Family ya en el manifest).'],
 ['4', 'PricebookEntry (Standard)',
  'Entrada en la lista Standard — OBLIGATORIA antes de cualquier lista custom (regla de la plataforma).',
  'Pricebook2Id (Std), Product2Id, UnitPrice, CurrencyIsoCode, IsActive',
  'No hay external id nativo: cargar por Data Loader relacionando Product2 vía SapMaterialCode__c',
  'Condición de precio de lista (ZGQREF / precio base)',
  '= productos × monedas',
  'Sin la entrada Standard, el insert en la lista custom FALLA. Orden de carga: siempre después de Product2.'],
 ['5', 'PricebookEntry (listas sociedad/canal)',
  'Precio vigente por lista comercial.',
  '+ UseStandardPrice=false',
  'ídem fila 4',
  'Condiciones por org. de ventas/canal',
  '= productos × listas',
  'Para repuestos el precio AUTORITATIVO en la cotización sigue siendo SAP (consulta viva); la lista local es el soporte del modelo nativo (toda QuoteLineItem apunta a un PricebookEntry). Pricing/descuentos = US-024/025/066/092; vigencia = US-103.'],
 ['6', 'ProductRelationshipType',
  'Tipo del vínculo kit→componente. Prerrequisito del ProductRelatedComponent.',
  'Name, MainProductRole, AssociatedProductRole',
  'n/a (1 registro)',
  'n/a',
  '1 registro',
  'Verificar valores de picklist disponibles en la org (script GAP).'],
 ['7', 'ProductRelatedComponent',
  'Kits/combos/agrupaciones (GQ-PV-02-029). El grid ya expande y renderiza componentes.',
  'ParentProductId, ChildProductId, Quantity, ProductRelationshipTypeId',
  'Parent+Child resueltos vía SapMaterialCode__c de ambos lados',
  'BOM comercial / listas técnicas del DBM',
  'Centenas',
  'Objeto confirmado habilitado en DevSales (12/08).'],
 ['8', 'VehicleDefinition',
  'Modelo/versión (ficha técnica) de cada Product2 de vehículo. Cadena oficial: VehicleDefinition.ProductId → Product2.',
  'Name, ProductId, atributos del modelo (marca, carrocería, transmisión, año...)',
  'ProductId (1:1 con el Product2 del vehículo)',
  'Maestro de modelos del DBM (VELO/VLC)',
  'Centenas',
  'Base del Inventory Search: VehicleSearchableField apunta a campos de aquí. OJO: VehicleDefinitions con ProductId nulo rompen subqueries (bug 3 de la suite) — cargar SIEMPRE con ProductId.'],
 ['9', 'Vehicle',
  'Inventario PROPIO de vehículos: cada unidad física con VIN. Cadena: Vehicle.VehicleDefinitionId → VehicleDefinition; Vehicle.AssetId → Asset al vender.',
  'Name, VehicleDefinitionId, VIN, Status, LocationId (verificar API name con el script GAP)',
  'VIN (único en la org)',
  'Stock de vehículos del DBM (VLC) por centro',
  'Miles · delta por movimiento (ingreso/venta/traslado)',
  'Usados: entran por HU-045 (Appraisal → Vehicle). LocationId liga la unidad al centro para la búsqueda multi-tienda.'],
 ['10', 'Asset',
  'Vehículo VENDIDO/entregado — relación cliente↔vehículo para posventa. Asset.Product2Id → Product2.',
  'AccountId, Product2Id, SerialNumber=VIN, Status, PurchaseDate',
  'SerialNumber + AccountId',
  'Histórico de ventas del DBM',
  'Miles (histórico retroactivo)',
  'El flujo NUEVO ya lo crea solo (Order_Facturado_Handler al facturar). La carga aquí es únicamente el histórico anterior al go-live.'],
 ['11', 'VehicleSearchableField (setup)',
  'Configuración del Vehicle Inventory Search: qué campos son criterio, cuáles se muestran, ordenan y agregan.',
  'Es CONFIGURACIÓN (Setup), no carga de datos',
  'n/a',
  'n/a',
  'Decenas de campos',
  'Configurar DESPUÉS de cargar VehicleDefinition + Vehicle + Location, y probar la búsqueda con datos reales.'],
]

nocarga_header = ['Qué', 'Decisión', 'Por qué / dónde vive']
nocarga = [
 ['Stock de repuestos (saldos por centro)', 'NO SE CARGA',
  'SAP es el sistema maestro del inventario (RN4 de la HU-043): Salesforce consulta CONSULTA_MATERIALES vía Mule en tiempo/casi tiempo real y solo refleja. La cotización guarda el snapshot en QuoteLineItem.AvailabilityStatus__c / AvailabilityDetail__c.'],
 ['Precio "vivo" de repuestos al cotizar', 'Consulta SAP, no carga',
  'La lista local lleva precio de referencia/soporte; el autoritativo llega en la consulta. Motor de pricing y descuentos = US-024/US-025/US-066/US-092; vigencia y "precio vencido" = US-103.'],
 ['Reservas de stock', 'No en la cotización',
  'Ciclo de reserva = US-045, a nivel PEDIDO y con reglas definidas en SAP. En la cotización la reserva solo se REFLEJA como lectura (GQ-PV-03-023).'],
 ['Sincronización catálogo OEM', 'GAP registrado',
  'La propia HU-043 (Esc. 7) lo registra como GAP / historia futura.'],
 ['ATP / multiestado / traslados / SOLPED / intercompany', 'Otras historias',
  'US-035/US-036 (ATP), US-037 (traslado), US-038 (SOLPED), US-039/US-041 (intercompany).'],
]

fuentes_header = ['Tema', 'Fuente oficial']
fuentes = [
 ['Cadena Product2 → VehicleDefinition → Vehicle/Asset',
  'developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehicledefinition.htm'],
 ['Objetos estándar del Automotive Cloud',
  'developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm'],
 ['Campos Automotive en Product2',
  'developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_product2.htm'],
 ['Data Model Gallery — Automotive Cloud',
  'developer.salesforce.com/docs/platform/data-models/guide/automotive-cloud.html'],
 ['Vehicle Inventory — mapeo de recursos (Integrations API)',
  'developer.salesforce.com/docs/industries/automotive/guide/vehicle-inventory-resource-mapping.html'],
 ['Set Up Vehicle Inventory Search',
  'help.salesforce.com/s/articleView?id=sf.auto_search_configure_parent.htm'],
 ['Search Criteria Configuration (VehicleSearchableField)',
  'help.salesforce.com/s/articleView?id=sf.auto_search_setupconfigure_a_vehicle_inventory_search_configuration.htm'],
 ['Manage Products and Locations in Automotive Cloud',
  'help.salesforce.com/s/articleView?id=sf.auto_inventory_task.htm'],
 ['Carga de Pricebook/PricebookEntry (Standard primero)',
  'help.salesforce.com/s/articleView?id=000385493 y 000383989'],
]

sheets = [
 ('Plan de Carga', [4, 22, 40, 38, 30, 28, 20, 48], carga_header, carga,
  'Carga de productos, precios, stock e inventario - modelagem oficial Automotive Cloud (12/08/2026) - ordem de carga obrigatoria de cima para baixo'),
 ('No se carga', [34, 20, 90], nocarga_header, nocarga,
  'Decisiones: lo que NO se carga en Salesforce y por que'),
 ('Fuentes', [42, 90], fuentes_header, fuentes,
  'Fuentes oficiales (Automotive Cloud Developer Guide / Salesforce Help)'),
]

content_types = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
 '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
 '<Default Extension="xml" ContentType="application/xml"/>'
 '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
 '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
 + ''.join(f'<Override PartName="/xl/worksheets/sheet{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(len(sheets)))
 + '</Types>')

root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
 '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
 '</Relationships>')

workbook = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
 'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
 + ''.join(f'<sheet name="{esc(s[0])}" sheetId="{i+1}" r:id="rId{i+1}"/>' for i, s in enumerate(sheets))
 + '</sheets></workbook>')

wb_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
 + ''.join(f'<Relationship Id="rId{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i+1}.xml"/>' for i in range(len(sheets)))
 + f'<Relationship Id="rId{len(sheets)+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
 '</Relationships>')

styles = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
 '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
 '<fonts count="3">'
 '<font><sz val="10"/><name val="Arial"/></font>'
 '<font><b/><color rgb="FFFFFFFF"/><sz val="10"/><name val="Arial"/></font>'
 '<font><b/><sz val="13"/><color rgb="FF0F172A"/><name val="Arial"/></font>'
 '</fonts>'
 '<fills count="3">'
 '<fill><patternFill patternType="none"/></fill>'
 '<fill><patternFill patternType="gray125"/></fill>'
 '<fill><patternFill patternType="solid"><fgColor rgb="FF1D4ED8"/><bgColor indexed="64"/></patternFill></fill>'
 '</fills>'
 '<borders count="2">'
 '<border><left/><right/><top/><bottom/><diagonal/></border>'
 '<border><left style="thin"><color rgb="FFCBD5E1"/></left><right style="thin"><color rgb="FFCBD5E1"/></right>'
 '<top style="thin"><color rgb="FFCBD5E1"/></top><bottom style="thin"><color rgb="FFCBD5E1"/></bottom><diagonal/></border>'
 '</borders>'
 '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
 '<cellXfs count="4">'
 '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
 '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
 '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment wrapText="1" vertical="top"/></xf>'
 '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
 '</cellXfs>'
 '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
 '</styleSheet>')

out = '/tmp/claude-0/-home-user-diario-implantacao/893746cb-45f5-5d03-a6b1-46d670b73ed0/scratchpad/carga/Carga_Productos_Precios_Inventario.xlsx'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', content_types)
    z.writestr('_rels/.rels', root_rels)
    z.writestr('xl/workbook.xml', workbook)
    z.writestr('xl/_rels/workbook.xml.rels', wb_rels)
    z.writestr('xl/styles.xml', styles)
    for i, (name, widths, header, rows, title) in enumerate(sheets):
        z.writestr(f'xl/worksheets/sheet{i+1}.xml', sheet_xml(widths, title, header, rows))
print('xlsx ok:', out)
