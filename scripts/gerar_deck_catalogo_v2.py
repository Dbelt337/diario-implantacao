# Gera o deck "Catalogo: carga inicial e manutencao" a partir do pacote do deck original (tema/master/layouts preservados).
import os, re, shutil, zipfile
from xml.sax.saxutils import escape as esc
SRC = 'deckx'; OUT = 'deck_new'; shutil.rmtree(OUT, ignore_errors=True); shutil.copytree(SRC, OUT)
NAVY, BLUE, LIGHT, PALE, GREEN, RED, GRAY, WHITE, AMBER = '1F3864', '2E75B6', 'F0F4F8', 'D9E2F3', '1B7A4E', 'A62626', '444444', 'FFFFFF', 'B7791F'
EMU = 914400
def emu(inches): return int(round(inches * EMU))
_id = [1]
def nid(): _id[0] += 1; return _id[0]

def run(t, sz=13, b=False, color=GRAY, i=False):
    return (f'<a:r><a:rPr lang="pt-BR" sz="{sz*100}" b="{1 if b else 0}" i="{1 if i else 0}" dirty="0"><a:solidFill><a:srgbClr val="{color}"/></a:solidFill>'
            f'<a:latin typeface="Calibri"/><a:cs typeface="Calibri"/></a:rPr><a:t>{esc(t)}</a:t></a:r>')
def para(runs, algn='l', bullet=False, space_after=6, lvl=0):
    ppr = f'<a:pPr algn="{algn}"' + (f' marL="{228600 + lvl*228600}" indent="-228600"' if bullet else '') + f'><a:spcAft><a:spcPts val="{space_after*100}"/></a:spcAft>'
    ppr += ('<a:buFont typeface="Arial"/><a:buChar char="&#8226;"/>' if bullet else '<a:buNone/>') + '</a:pPr>'
    return f'<a:p>{ppr}{runs}</a:p>'
def P(t, sz=13, b=False, color=GRAY, algn='l', bullet=False, space_after=6, lvl=0):
    return para(run(t, sz, b, color), algn, bullet, space_after, lvl)
def PL(label, text, sz=13, color=GRAY, lcolor=None, bullet=True, space_after=6):
    return para(run(label, sz, True, lcolor or color) + run(text, sz, False, color), 'l', bullet, space_after)

def shape(x, y, cx, cy, paras, fill=None, line=None, lw=25400, round_=False, anchor='t', ins=0.12, name='Shape', txbox=False):
    geom = 'roundRect' if round_ else 'rect'
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
    ps = [P(title, title_sz, True, tcolor or border, space_after=6)]
    for it in items:
        if isinstance(it, tuple): ps.append(PL(it[0], it[1], sz, GRAY, None, bullet, 5))
        else: ps.append(P(it, sz, False, GRAY, 'l', bullet, 5))
    return shape(x, y, cx, cy, ps, fill=fill, line=border, round_=True, ins=0.15, name='Card')
def pill(x, y, cx, cy, text, fill=BLUE, sz=12, color=WHITE, b=True):
    return shape(x, y, cx, cy, [P(text, sz, b, color, 'ctr', space_after=0)], fill=fill, round_=True, anchor='ctr', ins=0.06, name='Pill')
def num(x, y, n, fill=BLUE):
    return shape(x, y, 0.42, 0.42, [P(str(n), 14, True, WHITE, 'ctr', space_after=0)], fill=fill, round_=True, anchor='ctr', ins=0.02, name='Num')

S = []
S = []
# 1. Capa
S.append(slide([
    shape(0.7, 1.5, 8.6, 1.3, [P('Catálogo comercial no SFA:', 34, True, WHITE, space_after=0), P('carga inicial e manutenção', 34, True, WHITE, space_after=0)], name='T', txbox=True, ins=0),
    shape(0.7, 3.15, 8.6, 1.0, [P('Template como levantamento, cadastro pela interface padrão do EPC, Agentforce como apoio às pessoas', 18, False, PALE, space_after=0)], name='S', txbox=True, ins=0),
    shape(0.7, 4.25, 8.6, 0.6, [P('Proposta revisada para decisão da presidência', 15, False, PALE, space_after=0)], name='S2', txbox=True, ins=0),
    shape(0.7, 6.2, 8.6, 0.4, [P('Brasil TecPar | SysMap | Catálogo EPC (Vlocity) | setembro de 2026', 12, False, PALE, space_after=0)], name='F', txbox=True, ins=0),
], bg=NAVY))
# 2. Resumo para decisao
S.append(slide([
    header('Resumo para decisão', 'É possível carregar e manter o catálogo sem desenvolvimento custom'),
    card(0.5, 1.3, 2.9, 4.6, 'O que a documentação confirma', [
        'A interface padrão (Product Designer) cria produto, estrutura, atributos, preço, promoção e regras com as dependências validadas.',
        'A migração sandbox para produção é feita por DataPacks e IDX Workbench, ferramentas oficiais.',
        'Os jobs pós-carga têm ordem definida e podem ser disparados por API.'], border=GREEN),
    card(3.55, 1.3, 2.9, 4.6, 'O risco do wizard', [
        'Um conversor sobre o template é código custom: reimplementa validações que a interface já faz.',
        'Erro de dependência (tipo, atributo, cardinalidade, preço) só aparece no carrinho.',
        'Precisa de manutenção a cada release do pacote e fica fora do suporte Salesforce.'], border=RED),
    card(6.6, 1.3, 2.9, 4.6, 'Decisões pedidas hoje', [
        ('1. ', 'Carga pela interface padrão, em ondas, com o template como planilha de levantamento.'),
        ('2. ', 'Wizard suspenso; retomar só se o volume justificar, sobre as APIs oficiais.'),
        ('3. ', 'Nomear o dono do catálogo e o substituto.'),
        ('4. ', 'Agentforce como assistente, fase 2, após avaliar licença.')], border=NAVY, bullet=False),
    pill(0.5, 6.15, 9.0, 0.6, 'Recomendação: rota padrão para a carga; manual de configuração e papéis nomeados para a manutenção; agente como apoio, nunca como autor.', NAVY, 12),
    footer(2)]))
# 3. O que a documentacao diz
S.append(slide([
    header('O que a documentação oficial diz', 'Salesforce Help, Developer Docs e anúncio oficial, conferidos em 16/09'),
    card(0.5, 1.25, 4.4, 2.35, 'Product Designer (interface padrão do EPC)', [
        'Help: aplicação de administração do catálogo, para negócio e TI. Sequência oficial: tipos de objeto e atributos, especificação, oferta, pacote com cardinalidade, preço e promoção.',
        'Projetos do EPC registram toda mudança (Add, Change, Delete) no projeto padrão; versionamento e ciclo de vida (atual, futuro, passado, aposentado) são nativos.'], border=BLUE, sz=10.5),
    card(5.1, 1.25, 4.4, 2.35, 'DataPacks, IDX Workbench e Vlocity Build', [
        'Help do EPC: para mover de desenvolvimento para produção, usa-se Vlocity DataPacks e o IDX Workbench.',
        'O IDX Workbench migra exatamente as mudanças de um Projeto do EPC em status Released; produtos não migram entre orgs por CSV.'], border=BLUE, sz=10.5),
    card(0.5, 3.75, 4.4, 2.35, 'EPC REST APIs', [
        'CRUD oficial só de Product2, versão, filho, picklist e promoção. Não cobrem preço nem atributo: um carregador teria de gravar isso por fora, sem validação.',
        'Se algum dia um carregador for justificado, é sobre estas APIs, não gravando registros direto.'], border=BLUE, sz=10.5),
    card(5.1, 3.75, 4.4, 2.35, 'Jobs pós-carga e Agentforce', [
        'Jobs de manutenção (Help): Product Hierarchy Maintenance antes do Refresh Platform Cache; Full na carga, Incremental na manutenção; Clear Managed Platform Cache limpa a partição do CPQ. Nunca em produção ao vivo.',
        'Agentforce pronto no pacote CME: ações e flows para o carrinho (cotação, pedido, navegar produtos, atributos, promoções). Agentforce for Communications: 5 agentes de venda e serviço. Nenhum cria catálogo.'], border=BLUE, sz=10.5),
    pill(0.5, 6.25, 9.0, 0.55, 'Atenção: a importação por CSV com templates DPE é do Revenue Cloud (Product Catalog Management), não do EPC do Communications Cloud.', AMBER, 10.5),
    footer(3)]))
# 4. Opcao 1: template + wizard
S.append(slide([
    header('Opção 1: template com conversor (wizard)', 'A equipe preenche a planilha e um código custom cria produto, estrutura, catálogo e preço'),
    pill(0.5, 1.2, 9.0, 0.55, 'Desenvolvimento custom: 2 a 3 semanas + testes  ·  Carga: 1 a 2 semanas após o conversor  ·  Manutenção do código a cada release', BLUE, 11),
    card(0.5, 1.95, 4.4, 4.1, 'Prós', [
        'Escala para dezenas de variações da mesma oferta.',
        'Padroniza código, cardinalidade, preço e catálogo.',
        'Arquivo aprovado antes de publicar: evidência de cada carga.',
        'Existe precedente na comunidade (EPC on Steroids), o que mostra que é viável.'], border=GREEN, sz=11),
    card(5.1, 1.95, 4.4, 4.1, 'Contras', [
        'Reimplementa validações que o Product Designer já faz; as APIs oficiais nem cobrem preço e atributo, então o wizard gravaria isso direto na base.',
        'Fora do suporte Salesforce; quebra silenciosa a cada atualização do pacote.',
        'Não cria tipo de objeto, atributo ou regra nova: o especialista continua necessário.',
        'Exige congelar a modelagem durante o desenvolvimento e manter template e código sincronizados.',
        'O precedente da comunidade é um projeto pessoal, sem garantia.'], border=RED, sz=11),
    pill(0.5, 6.2, 9.0, 0.55, 'Situação em 16/09: template entregue e validado; wizard em construção pela SysMap. Proposta: suspender o wizard.', AMBER, 11),
    footer(4)]))
# 5. Opcao 2: interface padrao
S.append(slide([
    header('Opção 2: interface padrão com migração por DataPacks', 'O analista cadastra em sandbox, valida no carrinho e publica em produção com ferramenta oficial'),
    pill(0.5, 1.2, 9.0, 0.55, 'Desenvolvimento: nenhum  ·  Onda 1 (11 ofertas): 1 a 2 semanas  ·  Manutenção por oferta: horas, com procedimento do manual', BLUE, 11),
    card(0.5, 1.95, 4.4, 4.1, 'Prós', [
        'Dependências validadas ao salvar: tipo de objeto, atributos herdados, cardinalidade, lista de preço.',
        'Suportado pela Salesforce e alinhado às releases; sem código para manter.',
        'DataPack exportado é a evidência e o versionamento da carga (pode ir para o Git).',
        'Histórico nativo de alteração; correção pontual sem recarregar nada.',
        'O template continua útil: vira a planilha de levantamento e o roteiro de cadastro.'], border=GREEN, sz=11),
    card(5.1, 1.95, 4.4, 4.1, 'Contras', [
        'Tempo de analista treinado; não escala para centenas de ofertas de uma vez.',
        'Consistência depende do procedimento escrito, não da ferramenta.',
        'Jobs pós-carga precisam estar no checklist (ou disparados por API).',
        'Exige treinamento formal de duas pessoas no Product Designer.'], border=RED, sz=11),
    pill(0.5, 6.2, 9.0, 0.55, 'Responde ao ponto do presidente: o problema são pessoas e manutenção; a resposta é procedimento, papéis e ferramenta padrão.', GREEN, 11),
    footer(5)]))
# 6. Opcao 3: hibrido com Agentforce
S.append(slide([
    header('Opção 3: híbrido com Agentforce', 'É possível, mas hoje é desenvolvimento custom com licença; cabe como assistente, não como autor'),
    card(0.5, 1.2, 2.9, 2.55, 'O que existe pronto', [
        'Ações e flows prontos no pacote CME para operações de carrinho: criar cotação e pedido, navegar produtos, configurar atributos, aplicar promoções, sem Apex custom. Tudo consome o catálogo; nada o cria.'], border=BLUE, sz=11, bullet=False),
    card(3.55, 1.2, 2.9, 2.55, 'O que teria de ser construído', [
        'Ações em Flow ou Apex sobre as EPC REST APIs (que não cobrem preço nem atributo), prompt templates, testes e guardrails. Volta a ser código custom.'], border=BLUE, sz=11, bullet=False),
    card(6.6, 1.2, 2.9, 2.55, 'Onde cabe bem', [
        'Explicar o manual, montar o checklist do evento, conferir a planilha de levantamento contra a org e validar o pós-carga. Sem publicar nada.'], border=BLUE, sz=11, bullet=False),
    card(0.5, 3.95, 4.4, 2.2, 'Prós', [
        'O ganho real e pronto é na venda: vendedor monta cotação e pedido pelo agente, sem Apex custom.',
        'Como assistente da manutenção, padroniza o cadastro ao seguir o manual.',
        'Publicação continua humana, em sandbox e com homologação.'], border=GREEN, sz=11),
    card(5.1, 3.95, 4.4, 2.2, 'Contras e condições', [
        'Licença e consumo do Agentforce a avaliar com a Salesforce.',
        'Ações custom para escrever no catálogo: mesmo risco do wizard, mais a variabilidade do agente.',
        'Só faz sentido depois do manual e de uma onda executada.'], border=RED, sz=11),
    pill(0.5, 6.3, 9.0, 0.5, 'Sequência: carga pela rota padrão e manual primeiro; fase 2 com Agentforce onde está pronto (carrinho) e como assistente do manual, se a licença compensar.', NAVY, 11),
    footer(6)]))
# 7. Comparativo
rows = [('Critério', 'Template + wizard', 'Interface padrão + DataPacks', 'Híbrido + Agentforce'),
        ('Código custom', 'Sim: conversor e validações', 'Nenhum', 'Sim: ações sobre as APIs'),
        ('Suporte Salesforce', 'Fora do suporte', 'Suportado', 'Plataforma suportada; ações não'),
        ('Onda 1 (11 ofertas)', '3 a 5 semanas (dev + carga)', '1 a 2 semanas', '1 a 2 semanas (mesma rota)'),
        ('Manutenção por oferta', 'Horas, se o código estiver ok', 'Horas, por procedimento', 'Horas, guiada pelo agente'),
        ('Dependência de especialista', 'Média: código e modelagem', 'Média: treinamento', 'Baixa na rotina'),
        ('Risco de erro de dependência', 'Alto: aparece no carrinho', 'Baixo: validado ao salvar', 'Baixo, se não publicar'),
        ('Evidência e auditoria', 'Arquivo por carga', 'DataPack + histórico', 'DataPack + registro do agente'),
        ('Custo adicional', 'Desenvolvimento e manutenção', 'Horas de analista', 'Licença Agentforce')]
sh = [header('Comparativo das três opções', 'Mesmos critérios, lado a lado')]
y = 1.25; colx = [0.5, 2.75, 5.05, 7.35]; colw = [2.2, 2.25, 2.25, 2.15]
for r, row in enumerate(rows):
    hgt = 0.5 if r == 0 else 0.56
    for c, txt in enumerate(row):
        if r == 0: sh.append(shape(colx[c], y, colw[c], hgt, [P(txt, 11, True, WHITE, 'l', space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
        else:
            fill = WHITE if r % 2 else PALE
            sh.append(shape(colx[c], y, colw[c], hgt, [P(txt, 10, c == 0, NAVY if c == 0 else GRAY, 'l', space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    y += hgt + 0.03
sh.append(pill(0.5, 6.45, 9.0, 0.45, 'Prazos são estimativas de prática, a calibrar no piloto da Onda 1; a documentação não publica tempos.', BLUE, 10))
sh.append(footer(7)); S.append(slide(sh))
# 8. Quanto tempo leva
trows = [('Item', 'Tempo por unidade', 'Observação'),
         ('Base do EPC (tipos, atributos, listas de preço, regras)', 'Pronta', 'Já configurada; não entra na conta'),
         ('Produto simples (sem filhos)', '20 a 40 min', 'Produto, atributos, preço, catálogo'),
         ('Pacote ou combo (3 a 6 componentes)', '2 a 4 h', 'Estrutura, cardinalidade, preço por filho'),
         ('Promoção', '1 a 2 h', 'Regra de elegibilidade e desconto'),
         ('Teste no carrinho por família', 'Meio dia', 'Cenários de venda e de erro'),
         ('Migração por DataPack + jobs, por onda', 'Meio dia', 'Sandbox para preprod e produção'),
         ('Onda 1: 11 ofertas e 16 componentes', '5 a 8 dias úteis', '1 analista; 2 semanas com homologação')]
sh = [header('Quanto tempo leva pela interface padrão', 'Estimativa por unidade; o total do catálogo sai do inventário do Customer Core')]
y = 1.25; cx = [0.5, 4.3, 6.55]; cw = [3.75, 2.2, 2.95]
for r, row in enumerate(trows):
    hgt = 0.45 if r == 0 else 0.5
    for c, txt in enumerate(row):
        if r == 0: sh.append(shape(cx[c], y, cw[c], hgt, [P(txt, 11, True, WHITE, 'l', space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
        else:
            fill = WHITE if r % 2 else PALE
            sh.append(shape(cx[c], y, cw[c], hgt, [P(txt, 10, c == 1 or r == 7, NAVY if c == 0 else GRAY, 'l', space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    y += hgt + 0.03
sh.append(card(0.5, 5.6, 9.0, 1.3, 'Como fechar o número do catálogo completo', [
    'Inventário no template: quantas ofertas simples, quantos pacotes, quantas promoções por família. Total = soma das unidades + 1 dia por família para teste e migração.',
    'Hipótese: 60 ofertas (30 simples, 20 pacotes, 10 promoções) em 5 famílias = 4 a 6 semanas com 1 analista, 2 a 3 semanas com 2.'], border=GREEN, sz=10.5))
sh.append(footer(8)); S.append(slide(sh))
# 9. Antecipacao da carga em ondas
waves = [('Onda 0', 'Semana 1', ['Congelar a modelagem v3 e fechar as pendências P1 e P2 com o comercial.', 'Inventário das ofertas do Customer Core no template (levantamento).', 'Treinar duas pessoas no Product Designer.'], GREEN),
         ('Onda 1', 'Semanas 1 e 2', ['Projeto do EPC da onda aberto como padrão; 11 ofertas de conectividade cadastradas em sandbox.', 'Teste no carrinho por família; projeto Released e exportado.', 'Checklist de jobs pós-carga validado.'], BLUE),
         ('Onda 2', 'Semanas 2 a 4', ['Demais famílias em sandbox, uma por vez, pelo mesmo procedimento.', 'Homologação do comercial no carrinho.', 'Manual de configuração revisado com quem operou.'], BLUE),
         ('Onda 3', 'Semanas 4 e 5', ['Publicação em preprod e produção pelo IDX Workbench a partir dos projetos Released, jobs na ordem, em janela.', 'Treinamento do time e entrega do manual.', 'Decisão sobre a fase 2 do Agentforce.'], NAVY)]
sh = [header('Antecipar a carga: execução em ondas', 'Começa na semana 1, sem esperar conversor; cada onda entrega algo utilizável')]
for i, (t, w, items, col) in enumerate(waves):
    x = 0.5 + i * 2.3
    sh.append(pill(x, 1.25, 2.15, 0.5, f'{t}  ·  {w}', col, 11))
    sh.append(card(x, 1.85, 2.15, 4.15, '', items, border=col, sz=10, title_sz=4))
sh.append(pill(0.5, 6.15, 9.0, 0.6, 'Ganho: a conectividade entra em produção em 4 a 5 semanas e o resto segue pelo mesmo trilho. Calendário a validar com a SysMap na sprint 1 (15 a 26/09).', GREEN, 11))
sh.append(footer(9)); S.append(slide(sh))
# 10. Garantias
g = [('Ferramenta padrão, suportada', 'Product Designer e DataPacks são os caminhos documentados pela Salesforce; nada depende de código nosso.'),
     ('Validação ao salvar', 'Tipo de objeto, atributos, cardinalidade e preço são conferidos pela interface antes de existir a oferta.'),
     ('Sandbox antes de produção', 'Toda oferta nasce em sandbox, é testada no carrinho e só então migra, pelo IDX Workbench, a partir do projeto Released.'),
     ('Evidência e versionamento', 'O projeto do EPC lista cada item alterado (Add, Change, Delete); o DataPack de cada onda fica guardado; versionamento é nativo.'),
     ('Pós-carga em janela', 'Product Hierarchy Maintenance e Refresh Platform Cache na ordem documentada, em janela fora do horário de venda: a Help manda não rodar jobs em produção ao vivo.'),
     ('Reversibilidade e donos', 'Oferta errada é aposentada pelo ciclo de vida, não excluída; cada etapa tem dono e substituto nomeados.')]
sh = [header('Segurança para decidir', 'Seis garantias da rota padrão')]
for i, (t, d) in enumerate(g):
    col = i % 2; row = i // 2
    x = 0.5 + col * 4.6; y = 1.3 + row * 1.6
    sh.append(num(x + 0.15, y + 0.15, i + 1))
    sh.append(shape(x, y, 4.4, 1.45, [], fill=WHITE, line=BLUE, round_=True, name='Box'))
    sh.append(shape(x + 0.7, y + 0.08, 3.6, 1.3, [P(t, 13, True, NAVY, space_after=3), P(d, 10.5, False, GRAY, space_after=0)], name='Txt', txbox=True, ins=0.05))
sh.append(pill(0.5, 6.25, 9.0, 0.55, 'O mesmo método já usado no projeto: validar antes, executar, conferir depois, registrar no diário.', NAVY, 11))
sh.append(footer(10)); S.append(slide(sh))
# 11. Manual de configuracao
procs = [('Produto novo', 'tipo de objeto + oferta'), ('Pacote ou combo', 'estrutura e cardinalidade'), ('Promoção', 'promoção no pacote'), ('Alteração de preço', 'Pricing Designer'), ('Descontinuação', 'ciclo de vida: aposentar')]
sh = [header('Manual de configuração do catálogo', 'Um procedimento por evento: o que fazer, quem faz, quem aprova, o que conferir')]
for i, (t, via) in enumerate(procs):
    x = 0.5 + i * 1.84
    sh.append(shape(x, 1.25, 1.74, 1.0, [P(t, 12, True, WHITE, 'ctr', space_after=2), P(via, 9.5, False, PALE, 'ctr', space_after=0)], fill=BLUE, round_=True, anchor='ctr', ins=0.06, name='Proc'))
sh.append(card(0.5, 2.45, 4.4, 3.6, 'Cada procedimento tem', [
    ('Pré-requisitos: ', 'oferta aprovada pelo comercial, códigos e preços na planilha de levantamento; projeto do EPC do evento aberto e definido como padrão.'),
    ('Quem cadastra e quem aprova: ', 'nomes, não áreas.'),
    ('Passo a passo com telas: ', 'sequência exata no Product Designer, campo a campo.'),
    ('Pós-carga: ', 'Product Hierarchy Maintenance e Refresh Platform Cache (Incremental) em janela; roteiro de teste no carrinho.'),
    ('Evidência: ', 'projeto do EPC Released e migrado pelo IDX, resultado do teste e registro no diário.')], border=NAVY, sz=10.5))
sh.append(card(5.1, 2.45, 4.4, 3.6, 'Anexos do manual', [
    'Dicionário de códigos: catálogos, categorias, picklists e atributos.',
    'Planilha de levantamento (o template) preenchida por tipo de oferta.',
    'Calendário: janela mensal de manutenção e 3 a 4 cargas por ano.',
    'Erros comuns e como corrigir (oferta não aparece no carrinho, job não executado, preço errado, vírgula em valor de picklist).',
    'Roteiro do Agentforce, quando entrar: o que faz e o que sempre pede aprovação.'], border=NAVY, sz=10.5))
sh.append(pill(0.5, 6.25, 9.0, 0.55, 'Entrega: rascunho na Onda 2, versão final e treinamento na Onda 3. Mantido pela governança Salesforce a cada mudança de modelagem.', GREEN, 11))
sh.append(footer(11)); S.append(slide(sh))
# 12. Papeis e rotina
roles = [('Dono do catálogo (Comercial)', 'Define e aprova ofertas, preços e promoções; responde às pendências de negócio; assina a homologação no carrinho.', GREEN),
         ('Analistas de catálogo (2 pessoas)', 'Cadastram no Product Designer pelo manual; exportam o DataPack; rodam o checklist pós-carga.', BLUE),
         ('Governança Salesforce (BTP)', 'Valida o levantamento contra a org, aprova a publicação, mantém o manual e o diário de cargas.', NAVY),
         ('SysMap (projeto)', 'Modelagem nova (tipo, atributo, regra), migração das ondas e correções em produção sob demanda.', BLUE),
         ('Agentforce (fase 2)', 'Vendedor: cotação e pedido pelo carrinho, pronto no pacote. Catálogo: explica o manual, monta checklist, confere pós-carga. Nunca publica.', AMBER)]
sh = [header('Pessoas e rotina', 'Quem faz o quê, para o catálogo não depender de uma pessoa só')]
for i, (t, d, col) in enumerate(roles):
    y = 1.25 + i * 0.93
    sh.append(shape(0.5, y, 2.6, 0.83, [P(t, 11.5, True, WHITE, 'l', space_after=0)], fill=col, round_=True, anchor='ctr', ins=0.1, name='Role'))
    sh.append(shape(3.2, y, 6.3, 0.83, [P(d, 10.5, False, GRAY, 'l', space_after=0)], fill=WHITE, line=col, round_=True, anchor='ctr', ins=0.1, name='Desc'))
sh.append(pill(0.5, 6.0, 9.0, 0.8, 'Rotina proposta: reunião de catálogo quinzenal de 30 minutos (comercial + governança + SysMap); janela mensal de manutenção; toda carga com dono, substituto e evidência.', NAVY, 11))
sh.append(footer(12)); S.append(slide(sh))
# 13. Recomendacao e proximos passos
steps = [('Aprovar a rota padrão e o calendário em ondas; suspender o wizard', 'Presidência', 'esta semana'),
         ('Nomear o dono do catálogo e os dois analistas', 'Presidência e Comercial', 'esta semana'),
         ('Fechar P1 e P2 (prazo e valores dos adicionais)', 'Comercial (Joel)', 'semana 1'),
         ('Inventário das ofertas no template e treinamento no Product Designer', 'Governança com SysMap', 'semana 1'),
         ('Onda 1: conectividade em sandbox, teste no carrinho, DataPack', 'Analistas com SysMap', 'semanas 1 e 2'),
         ('Manual de configuração e treinamento', 'Governança Salesforce', 'semanas 2 a 5'),
         ('Avaliar licença e escopo do piloto do Agentforce', 'Gerson com a Salesforce', 'após a Onda 1')]
sh = [header('Recomendação e próximos passos', 'Rota padrão para a carga, manual e papéis para a manutenção, Agentforce como apoio em fase 2')]
sh.append(shape(0.5, 1.25, 4.6, 0.45, [P('Ação', 11, True, WHITE, space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
sh.append(shape(5.15, 1.25, 2.4, 0.45, [P('Responsável', 11, True, WHITE, space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
sh.append(shape(7.6, 1.25, 1.9, 0.45, [P('Quando', 11, True, WHITE, space_after=0)], fill=NAVY, anchor='ctr', ins=0.08, name='Th'))
for i, (a, r, w) in enumerate(steps):
    y = 1.75 + i * 0.58; fill = WHITE if i % 2 == 0 else PALE
    sh.append(shape(0.5, y, 4.6, 0.53, [P(f'{i+1}. {a}', 10.5, False, GRAY, space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    sh.append(shape(5.15, y, 2.4, 0.53, [P(r, 10.5, False, GRAY, space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
    sh.append(shape(7.6, y, 1.9, 0.53, [P(w, 10.5, False, GRAY, space_after=0)], fill=fill, anchor='ctr', ins=0.08, name='Td'))
sh.append(pill(0.5, 6.0, 9.0, 0.85, 'O que a presidência ganha: a conectividade publicada em 4 a 5 semanas sem código custom, um catálogo que dois analistas treinados mantêm pelo manual, e a opção de reduzir ainda mais a dependência de pessoas com o agente, sem perder o controle da publicação.', GREEN, 11))
sh.append(footer(13)); S.append(slide(sh))
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
# presentation.xml e rels
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
outp = 'Catalogo_Carga_e_Manutencao_v2_Rota_Padrao.pptx'
if os.path.exists(outp): os.remove(outp)
with zipfile.ZipFile(outp, 'w', zipfile.ZIP_DEFLATED) as z:
    z.write(os.path.join(OUT, '[Content_Types].xml'), '[Content_Types].xml')
    for root, _, files in os.walk(OUT):
        for f in files:
            full = os.path.join(root, f); arc = os.path.relpath(full, OUT)
            if arc == '[Content_Types].xml': continue
            z.write(full, arc)
print('ok', outp, len(S), 'slides')
