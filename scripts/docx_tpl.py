# Helpers do layout dos docs de work (template: W-000125 do export de 11/09).
import os, re, zipfile, shutil, datetime, unicodedata
from xml.sax.saxutils import escape as esc
SZ = '<w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/></w:rPr>'
def run(t, b=False, i=False, color=None, sz=24):
    rpr = ('<w:b/><w:bCs/>' if b else '') + ('<w:i/><w:iCs/>' if i else '') + (f'<w:color w:val="{color}"/>' if color else '') + f'<w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/>'
    return f'<w:r><w:rPr>{rpr}</w:rPr><w:t xml:space="preserve">{esc(t)}</w:t></w:r>'
def p(runs, ppr=''):
    return f'<w:p><w:pPr>{ppr}{SZ}</w:pPr>{runs}</w:p>'
def heading(t): return p(run(t, b=True), '<w:keepNext/><w:spacing w:before="240" w:after="80"/>')
def plain(t): return p(run(t))
def labeled(label, t): return p(run(label, b=True) + run(t))
def bullet(numId, lvl, runs, keep=False):
    return p(runs, ('<w:keepNext/>' if keep else '') + f'<w:numPr><w:ilvl w:val="{lvl}"/><w:numId w:val="{numId}"/></w:numPr>')
def empty(): return p('')
def cell(t, w, b=False, fill=None):
    shd = f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/>' if fill else ''
    return (f'<w:tc><w:tcPr><w:tcW w:w="{w}" w:type="dxa"/>{shd}</w:tcPr>'
            f'<w:p><w:pPr><w:spacing w:before="40" w:after="40"/>{SZ}</w:pPr>{run(t, b=b, sz=20)}</w:p></w:tc>')
def table(rows):
    b = '<w:tblBorders>' + ''.join(f'<w:{s} w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>' for s in ['top','left','bottom','right','insideH','insideV']) + '</w:tblBorders>'
    trs = ''.join(f'<w:tr>{cell(k,2400,True,"EEF3FA")}{cell(v,6104)}</w:tr>' for k, v in rows)
    return f'<w:tbl><w:tblPr><w:tblW w:w="8504" w:type="dxa"/>{b}<w:tblLook w:val="04A0"/></w:tblPr><w:tblGrid><w:gridCol w:w="2400"/><w:gridCol w:w="6104"/></w:tblGrid>{trs}</w:tbl>'


def gerar_docx(tpl, out_dir, meta, body_xml):
    """meta: work, codigo (pode ser ''), titulo. body_xml: paragrafos do corpo (apos o logo)."""
    tmp = os.path.join(out_dir, '_tmp'); shutil.rmtree(tmp, ignore_errors=True)
    with zipfile.ZipFile(tpl) as z: z.extractall(tmp)
    dx = os.path.join(tmp, 'word', 'document.xml'); x = open(dx, encoding='utf8').read()
    ps = list(re.finditer(r'<w:p[ >].*?</w:p>', x, re.S))
    head = x[:ps[1].end()]; tail = x[x.rindex('<w:sectPr'):]
    open(dx, 'w', encoding='utf8').write(head + body_xml + tail)
    cx = os.path.join(tmp, 'docProps', 'core.xml'); c = open(cx, encoding='utf8').read()
    now = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:00Z')
    titulo_doc = meta['work'] + ' - ' + (('US ' + meta['codigo'] + ' — ') if meta.get('codigo') else '') + meta['titulo']
    c = re.sub(r'<dc:title>.*?</dc:title>', '<dc:title>' + esc(titulo_doc) + '</dc:title>', c, flags=re.S)
    c = re.sub(r'<dcterms:created[^>]*>.*?</dcterms:created>', f'<dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created>', c)
    c = re.sub(r'<dcterms:modified[^>]*>.*?</dcterms:modified>', f'<dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified>', c)
    open(cx, 'w', encoding='utf8').write(c)
    trans = unicodedata.normalize('NFKD', meta['titulo']).encode('ascii', 'ignore').decode()
    prefix = meta['work'] + '_' + (('US_' + meta['codigo'].replace('-', '_') + '_') if meta.get('codigo') else '')
    safe = re.sub(r'[^A-Za-z0-9]+', '_', trans).strip('_')[:79 - len(prefix)].rstrip('_')
    outp = os.path.join(out_dir, prefix + safe + '.docx')
    if os.path.exists(outp): os.remove(outp)
    with zipfile.ZipFile(outp, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, _, files in os.walk(tmp):
            for f in files:
                full = os.path.join(root, f); z.write(full, os.path.relpath(full, tmp))
    shutil.rmtree(tmp); return outp
