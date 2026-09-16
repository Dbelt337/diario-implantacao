# Gera o deck v3 "Catalogo: carga e manutencao com template + Claude via CLI" (6 slides, enxuto, a pedido do Davi em 16/09).
# Reaproveita tema/master/layouts do deck original (pasta deckx = Template_vs_Catalogo_Manual.pptx descompactado).
# Uso: cd <pasta com deckx/> && python3 gerar_deck_catalogo_v3.py
import os, re, shutil, zipfile
from xml.sax.saxutils import escape as esc
SRC = 'deckx'; OUT = 'deck_new'; shutil.rmtree(OUT, ignore_errors=True); shutil.copytree(SRC, OUT)
NAVY, BLUE, LIGHT, PALE, GREEN, RED, GRAY, WHITE, AMBER = '1F3864', '2E75B6', 'F0F4F8', 'D9E2F3', '1B7A4E', 'A62626', '444444', 'FFFFFF', 'B7791F'
EMU = 914400
def emu(inches): return int(round(inches * EMU))
_id = [1]
def nid(): _id[0] += 1; return _id[0]

def run(t, sz=13, b=False, color=GRAY, i=False):
    return (f'<a:r><a:rPr lang="pt-BR" sz="{int(round(sz*100))}" b="{1 if b else 0}" i="{1 if i else 0}" dirty="0"><a:solidFill><a:srgbClr val="{color}"/></a:solidFill>'
            f'<a:latin typeface="Calibri"/><a:cs typeface="Calibri"/></a:rPr><a:t>{esc(t)}</a:t></a:r>')
def para(runs, algn='l', bullet=False, space_after=6, lvl=0):
    ppr = f'<a:pPr algn="{algn}"' + (f' marL="{228600 + lvl*228600}" indent="-228600"' if bullet else '') + f'><a:spcAft><a:spcPts val="{int(round(space_after*100))}"/></a:spcAft>'
    ppr += ('<a:buFont typeface="Arial"/><a:buChar char="&#8226;"/>' if bullet else '<a:buNone/>') + '</a:pPr>'
    return f'<a:p>{ppr}{runs}</a:p>'
def P(t, sz=13, b=False, color=GRAY, algn='l', bullet=False, space_after=6, lvl=0):
    return para(run(t, sz, b, color), algn, bullet, space_after, lvl)
def PL(label, text, sz=13, color=GRAY, lcolor=None, bullet=True, space_after=6):
    return para(run(label, sz, True, lcolor or color) + run(text, sz, False, color), 'l', bullet, space_after)

def shape(x, y, cx, cy, paras, fill=None, line=None, lw=25400, round_=False, anchor='t', ins=0.12, name='Shape', txbox=False, geom=None):
    geom = geom or ('roundRect' if round_ else 'rect')
    fillx = f'<a:solidFill><a:srgbClr val="{fill}"/></a:solidFill>' if fill else '<a:noFill/>'
    linex = f'<a:ln w="{lw}"><a:solidFill><a:srgbClr val="{line}"/></a:solidFill></a:ln>' if line else '<a:ln><a:noFill/></a:ln>'
    cnv = '<p:cNvSpPr txBox="1"/>' if txbox else '<p:cNvSpPr/>'
    body = ''.join(paras) if paras else '<a:p><a:endParaRPr lang="pt-BR"/></a:p>'
    i = emu(ins)
    return (f'<p:sp><p:nvSpPr><p:cNvPr id="{nid()}" name="{name}"/>{cnv}<p:nvPr/></p:nvSpPr>'
            f'<p:spPr><a:xfrm><a:off x="{emu(x)}" y="{emu(y)}"/><a:ext cx="{emu(cx)}" cy="{emu(cy)}"/></a:xfrm>'
            f'<a:prstGeom prst="{geom}"><a:avLst/></a:prstGeom>{fillx}{linex}</p:spPr>'
            f'<p:txBody><a:bodyPr wrap="square" lIns="{i}" tIns="{i}" rIns="{i}" bIns="{i}" rtlCol="0" anchor="{anchor}"><a:normAutofit/></a:bodyPr><a:lstStyle/>{body}</p:txBody></p:sp>')

def slide(shapes, bg=LIGHT):
    _id[0] = 1
    body = ''.join(shapes)
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
            f'<p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="{bg}"/></a:solidFill><a:effectLst/></p:bgPr></p:bg><p:spTree>'
            '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
            f'{body}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>')

def header(title, sub=None, h=1.0):
    ps = [P(title, 24, True, WHITE, 'l', space_after=2)]
    if sub: ps.append(P(sub, 13, False, PALE, 'l', space_after=0))
    return shape(0, 0, 10, h, ps, fill=NAVY, anchor='ctr', ins=0.5, name='Header')
def footer(n):
    return shape(0.5, 7.12, 9, 0.3, [P(f'Brasil TecPar | SysMap | Catálogo EPC (Vlocity)  ·  {n}', 9, False, '7F8C9A', 'r', space_after=0)], name='Footer', txbox=True, ins=0)
def card(x, y, cx, cy, title, items, border=BLUE, tcolor=None, sz=12, bullet=True, fill=WHITE, title_sz=14):
    ps = [P(title, title_sz, True, tcolor or border, space_after=6)] if title else []
    for it in items:
        if isinstance(it, tuple): ps.append(PL(it[0], it[1], sz, GRAY, None, bullet, 5))
        else: ps.append(P(it, sz, False, GRAY, 'l', bullet, 5))
    return shape(x, y, cx, cy, ps, fill=fill, line=border, round_=True, ins=0.15, name='Card')
def pill(x, y, cx, cy, text, fill=BLUE, sz=12, color=WHITE, b=True):
    return shape(x, y, cx, cy, [P(text, sz, b, color, 'ctr', space_after=0)], fill=fill, round_=True, anchor='ctr', ins=0.06, name='Pill')
def num(x, y, n, fill=BLUE, d=0.42):
    return shape(x, y, d, d, [P(str(n), 14, True, WHITE, 'ctr', space_after=0)], fill=fill, round_=True, anchor='ctr', ins=0.02, name='Num')
def arrow(x, y, cx=0.3, cy=0.3, fill=BLUE):
    return shape(x, y, cx, cy, [], fill=fill, name='Arrow', geom='rightArrow', ins=0)

S = []
# 1. Capa
S.append(slide([
    shape(0.7, 1.5, 8.6, 1.3, [P('Catálogo comercial no SFA:', 34, True, WHITE, space_after=0), P('carga e manutenção', 34, True, WHITE, space_after=0)], name='T', txbox=True, ins=0),
    shape(0.7, 3.15, 8.6, 1.0, [P('O negócio preenche o template. O Claude lê e executa a carga na sandbox via CLI. Pessoas homologam e publicam.', 18, False, PALE, space_after=0)], name='S', txbox=True, ins=0),
    shape(0.7, 4.35, 8.6, 0.6, [P('Proposta para decisão da presidência', 15, False, PALE, space_after=0)], name='S2', txbox=True, ins=0),
    shape(0.7, 6.2, 8.6, 0.4, [P('Brasil TecPar | SysMap | Catálogo EPC (Vlocity) | setembro de 2026', 12, False, PALE, space_after=0)], name='F', txbox=True, ins=0),
], bg=NAVY))

# 2. Como funciona (fluxo em 5 passos)
steps = [('Negócio preenche o template', 'Planilha com ofertas, componentes, atributos e preços, nos códigos da org.', GREEN),
         ('Claude lê e confere', 'Valida o template contra a org antes de gravar: códigos, tipos, cardinalidade, preços. Erro volta para a planilha.', BLUE),
         ('Claude executa na sandbox', 'Via CLI, com as ferramentas oficiais (Vlocity Build, DataPacks, sf CLI). Roda os jobs pós-carga e confere o resultado.', BLUE),
         ('Comercial homologa', 'Testa as ofertas no carrinho da sandbox. Ajuste volta para o template, não para a mão do analista.', NAVY),
         ('Pessoas publicam', 'DataPack aprovado migra para produção pelo IDX, em janela, com evidência guardada.', NAVY)]
sh = [header('Como funciona', 'Um artefato de negócio (o template) e um executor (o Claude conectado à org)')]
for i, (t, d, col) in enumerate(steps):
    x = 0.5 + i * 1.86
    sh.append(num(x + 0.62, 1.3, i + 1, col, 0.5))
    sh.append(shape(x, 1.95, 1.74, 3.5, [P(t, 12.5, True, col, 'ctr', space_after=6), P(d, 10.5, False, GRAY, 'ctr', space_after=0)], fill=WHITE, line=col, round_=True, ins=0.1, name='Step'))
    if i < 4: sh.append(arrow(x + 1.74 + 0.02, 3.55, 0.1, 0.3, col))
sh.append(card(0.5, 5.65, 9.0, 1.25, '', [
    ('Sem Apex, sem Flow, sem wizard. ', 'Nada é instalado na org: o Claude usa as ferramentas oficiais de linha de comando e o template é o único artefato que o negócio mantém.'),
    ('O que continua com especialista: ', 'tipo de objeto, atributo ou regra nova (modelagem), como já é hoje.')], border=NAVY, sz=11, bullet=False))
sh.append(footer(2)); S.append(slide(sh))

# 3. Por que não o wizard e não o manual
sh = [header('Por que este caminho', 'Resolve o que o wizard e o cadastro manual não resolvem')]
sh.append(card(0.5, 1.25, 2.9, 4.6, 'Wizard custom', [
    'Código Apex/LWC na org: 2 a 3 semanas de desenvolvimento antes da primeira carga.',
    'Reimplementa validações que a interface já faz; erro só aparece no carrinho.',
    'Manutenção a cada release do pacote, fora do suporte Salesforce.',
    'Modelagem congelada durante o desenvolvimento.'], border=RED, sz=11))
sh.append(card(3.55, 1.25, 2.9, 4.6, 'Cadastro manual', [
    'Sem código, mas não escala: 1 a 1,5 mês para o legado.',
    'Consistência depende de cada analista; conhecimento concentrado.',
    'Cadastro repetitivo: erro em preço, cardinalidade e catálogo.',
    'Jobs pós-carga esquecidos após alterações em lote.'], border=AMBER, sz=11))
sh.append(card(6.6, 1.25, 2.9, 4.6, 'Template + Claude via CLI', [
    'Nada instalado na org; ferramentas oficiais (DataPacks, Vlocity Build, sf CLI).',
    'Começa na semana 1: não há conversor para construir.',
    'Valida antes de gravar e confere depois; log de cada carga.',
    'Escala para a carga completa e para a manutenção repetida.',
    'Modelagem nova continua com o especialista.'], border=GREEN, sz=11))
sh.append(pill(0.5, 6.05, 9.0, 0.75, 'O template já existe e foi validado. O que muda é quem executa: em vez de código na org ou de um analista campo a campo, o Claude roda o roteiro pela CLI e a pessoa aprova.', NAVY, 11.5))
sh.append(footer(3)); S.append(slide(sh))

# 4. Seguranca
g = [('Sandbox primeiro', 'Toda carga nasce na sandbox. Produção só recebe DataPack homologado, em janela, por uma pessoa.'),
     ('Validar antes, conferir depois', 'O Claude confere o template contra a org antes de gravar e relê o resultado depois. Erro de código, cardinalidade ou preço para a carga antes de existir a oferta.'),
     ('Evidência e versionamento', 'Template aprovado, DataPack gerado e log da execução ficam guardados (Git). Cada carga tem dono, data e resultado.'),
     ('Ferramentas oficiais', 'DataPacks e IDX são a rota documentada pela Salesforce para mover catálogo entre orgs. Jobs pós-carga na ordem da documentação.')]
sh = [header('Segurança para decidir', 'Quatro garantias do modelo')]
for i, (t, d) in enumerate(g):
    col = i % 2; row = i // 2
    x = 0.5 + col * 4.6; y = 1.3 + row * 2.3
    sh.append(num(x + 0.15, y + 0.15, i + 1))
    sh.append(shape(x, y, 4.4, 2.1, [], fill=WHITE, line=BLUE, round_=True, name='Box'))
    sh.append(shape(x + 0.7, y + 0.1, 3.6, 1.9, [P(t, 14, True, NAVY, space_after=4), P(d, 11.5, False, GRAY, space_after=0)], name='Txt', txbox=True, ins=0.05))
sh.append(pill(0.5, 6.1, 9.0, 0.6, 'É o mesmo método já usado no projeto desde julho: validar antes, executar, conferir depois, registrar no diário.', NAVY, 11.5))
sh.append(footer(4)); S.append(slide(sh))

# 5. Prazo e pre-requisitos
trows = [('Etapa', 'Prazo', 'Observação'),
         ('Onda 1: conectividade (11 ofertas, 16 componentes)', '1 a 2 semanas', 'Carga na sandbox, homologação no carrinho e publicação'),
         ('Demais famílias', 'Por onda, pelo mesmo trilho', 'Total sai do inventário preenchido no template'),
         ('Manutenção por oferta', 'Horas', 'Alterar o template e rodar de novo; sem recarregar o catálogo')]
sh = [header('Quanto tempo leva', 'A primeira onda começa assim que os pré-requisitos estiverem prontos')]
y = 1.25; cx = [0.5, 4.3, 6.35]; cw = [3.75, 2.0, 3.15]
for r, row in enumerate(trows):
    hgt = 0.45 if r == 0 else 0.6
    for c, txt in enumerate(row):
        if r == 0: sh.append(shape(cx[c], y, cw[c], hgt, [P(txt, 11.5, True, WHITE, 'l', space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
        else:
            fill = WHITE if r % 2 else PALE
            sh.append(shape(cx[c], y, cw[c], hgt, [P(txt, 11, c == 1, NAVY if c == 0 else GRAY, 'l', space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    y += hgt + 0.03
sh.append(card(0.5, 3.75, 4.4, 2.3, 'Pré-requisitos para começar', [
    'Acesso do Claude à sandbox (usuário de integração com permissão no EPC).',
    'Vlocity Build e sf CLI configurados no ambiente de execução.',
    'Template preenchido com os códigos da org (catálogos, categorias, picklists).'], border=BLUE, sz=11))
sh.append(card(5.1, 3.75, 4.4, 2.3, 'Pendências de negócio que travam a Onda 1', [
    'P1: prazo de contrato na oferta ou no componente (Joel).',
    'P2: valores dos adicionais por oferta (Joel).',
    'Dono do catálogo nomeado para homologar no carrinho.'], border=AMBER, sz=11))
sh.append(pill(0.5, 6.25, 9.0, 0.55, 'Prazos são estimativas de prática, a calibrar na Onda 1.', BLUE, 10.5))
sh.append(footer(5)); S.append(slide(sh))

# 6. Decisoes e proximos passos
steps = [('Aprovar o modelo: template + Claude via CLI, sem wizard', 'Presidência', 'esta semana'),
         ('Nomear o dono do catálogo (homologa no carrinho)', 'Presidência e Comercial', 'esta semana'),
         ('Fechar P1 e P2', 'Comercial (Joel)', 'semana 1'),
         ('Acesso à sandbox e ambiente de execução do Claude', 'Governança Salesforce com SysMap', 'semana 1'),
         ('Onda 1: conectividade na sandbox e homologação', 'SysMap com Comercial', 'semanas 1 e 2'),
         ('Publicação em produção e roteiro de manutenção', 'Governança Salesforce', 'semanas 2 e 3')]
sh = [header('Decisões e próximos passos', 'O que precisa ser aprovado hoje e o que acontece em seguida')]
sh.append(shape(0.5, 1.25, 4.6, 0.45, [P('Ação', 11.5, True, WHITE, space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
sh.append(shape(5.15, 1.25, 2.6, 0.45, [P('Responsável', 11.5, True, WHITE, space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
sh.append(shape(7.8, 1.25, 1.7, 0.45, [P('Quando', 11.5, True, WHITE, space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
for i, (a, r, w) in enumerate(steps):
    y = 1.75 + i * 0.66; fill = WHITE if i % 2 == 0 else PALE
    sh.append(shape(0.5, y, 4.6, 0.6, [P(f'{i+1}. {a}', 11, False, GRAY, space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    sh.append(shape(5.15, y, 2.6, 0.6, [P(r, 11, False, GRAY, space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    sh.append(shape(7.8, y, 1.7, 0.6, [P(w, 11, False, GRAY, space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
sh.append(pill(0.5, 6.0, 9.0, 0.85, 'O que a presidência ganha: a conectividade publicada em 2 a 3 semanas sem código na org, um catálogo mantido pelo template em vez de por pessoas específicas, e a publicação em produção sempre sob aprovação humana.', GREEN, 11.5))
sh.append(footer(6)); S.append(slide(sh))

# ---- escreve o pacote
sd = os.path.join(OUT, 'ppt', 'slides'); rd = os.path.join(sd, '_rels')
for f in os.listdir(sd):
    if f.endswith('.xml'): os.remove(os.path.join(sd, f))
for f in os.listdir(rd): os.remove(os.path.join(rd, f))
rel = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
       '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout7.xml"/></Relationships>')
for i, x in enumerate(S, 1):
    open(os.path.join(sd, f'slide{i}.xml'), 'w', encoding='utf8').write(x)
    open(os.path.join(rd, f'slide{i}.xml.rels'), 'w', encoding='utf8').write(rel)
pp = os.path.join(OUT, 'ppt', 'presentation.xml'); p = open(pp, encoding='utf8').read()
p = re.sub(r'<p:sldIdLst>.*?</p:sldIdLst>', '<p:sldIdLst>' + ''.join(f'<p:sldId id="{256+i}" r:id="rIdS{i+1}"/>' for i in range(len(S))) + '</p:sldIdLst>', p, flags=re.S)
open(pp, 'w', encoding='utf8').write(p)
rp = os.path.join(OUT, 'ppt', '_rels', 'presentation.xml.rels'); r = open(rp, encoding='utf8').read()
r = re.sub(r'<Relationship Id="rId\d+" Type="[^"]*/slide" Target="slides/slide\d+\.xml"/>', '', r)
r = r.replace('</Relationships>', ''.join(f'<Relationship Id="rIdS{i+1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide{i+1}.xml"/>' for i in range(len(S))) + '</Relationships>')
open(rp, 'w', encoding='utf8').write(r)
cp = os.path.join(OUT, '[Content_Types].xml'); c = open(cp, encoding='utf8').read()
c = re.sub(r'<Override PartName="/ppt/slides/slide\d+\.xml"[^>]*/>', '', c)
c = c.replace('</Types>', ''.join(f'<Override PartName="/ppt/slides/slide{i+1}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>' for i in range(len(S))) + '</Types>')
open(cp, 'w', encoding='utf8').write(c)
ap = os.path.join(OUT, 'docProps', 'app.xml')
if os.path.exists(ap):
    a = open(ap, encoding='utf8').read(); a = re.sub(r'<Slides>\d+</Slides>', f'<Slides>{len(S)}</Slides>', a); open(ap, 'w', encoding='utf8').write(a)
outp = 'Catalogo_Carga_e_Manutencao_v3_Template_Claude_CLI.pptx'
if os.path.exists(outp): os.remove(outp)
with zipfile.ZipFile(outp, 'w', zipfile.ZIP_DEFLATED) as z:
    z.write(os.path.join(OUT, '[Content_Types].xml'), '[Content_Types].xml')
    for root, _, files in os.walk(OUT):
        for f in files:
            full = os.path.join(root, f); arc = os.path.relpath(full, OUT)
            if arc == '[Content_Types].xml': continue
            z.write(full, arc)
print('ok', outp, len(S), 'slides')
