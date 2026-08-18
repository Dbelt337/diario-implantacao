import zipfile, html, re

def col(n):
    s=''
    while n>0:
        n,r=divmod(n-1,26); s=chr(65+r)+s
    return s

def sheet_xml(rows):
    out=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
         '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
         '<cols>',
         '<col min="1" max="1" width="7"/><col min="2" max="2" width="52"/>',
         '<col min="3" max="3" width="20"/><col min="4" max="4" width="46"/>',
         '<col min="5" max="5" width="70"/><col min="6" max="6" width="14"/>',
         '<col min="7" max="7" width="26"/><col min="8" max="8" width="34"/>',
         '<col min="9" max="9" width="40"/><col min="10" max="10" width="22"/>',
         '</cols><sheetData>']
    for ri,row in enumerate(rows,1):
        cells=[]
        for ci,v in enumerate(row,1):
            if v is None or v=='' : continue
            t=html.escape(str(v), quote=False)
            cells.append(f'<c r="{col(ci)}{ri}" t="inlineStr"><is><t xml:space="preserve">{t}</t></is></c>')
        out.append(f'<row r="{ri}">' + ''.join(cells) + '</row>')
    out.append('</sheetData></worksheet>')
    return ''.join(out)

def build(path, sheets):
    ct=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
        '<Default Extension="xml" ContentType="application/xml"/>',
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>']
    for i in range(1,len(sheets)+1):
        ct.append(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>')
    ct.append('</Types>')
    rels=('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>')
    wb=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>']
    wbr=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
         '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">']
    for i,(name,_) in enumerate(sheets,1):
        wb.append(f'<sheet name="{html.escape(name)}" sheetId="{i}" r:id="rId{i}"/>')
        wbr.append(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>')
    wb.append('</sheets></workbook>'); wbr.append('</Relationships>')
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ''.join(ct))
        z.writestr('_rels/.rels', rels)
        z.writestr('xl/workbook.xml', ''.join(wb))
        z.writestr('xl/_rels/workbook.xml.rels', ''.join(wbr))
        for i,(_,rows) in enumerate(sheets,1):
            z.writestr(f'xl/worksheets/sheet{i}.xml', sheet_xml(rows))
