"""Gera o status de entrega dos relatorios da pasta Performance Arquitetura (Markdown e PDF).

Uso (na raiz do repo): python tools/relatorios/gerar_status_relatorios_arquitetura.py
Saidas: docs/2026-09-23-status-relatorios-arquitetura.md e docs/2026-09-23-status-relatorios-arquitetura.pdf
Os numeros de 23/09 vieram da execucao dos relatorios pela API de Analytics na org de producao.
"""
import os
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

DATA = '23/09/2026'
ORG = 'https://prod-brasiltecpar.my.salesforce.com'
PASTA_ID = '00lV2000009ZdSkIAK'
MD = 'docs/2026-09-23-status-relatorios-arquitetura.md'
PDF = 'docs/2026-09-23-status-relatorios-arquitetura.pdf'

RELATORIOS = [
    ('Arquitetura - Fila pendente por idade', '00OV2000009cR6rMAE',
     'Itens de aprovação de arquitetura pendentes, por semana de entrada, com quem assumiu e a idade em dias, do mais antigo ao mais novo.',
     '248 itens pendentes; idade média 10,4 dias; item mais antigo com 77,9 dias (era 200,8 antes da limpeza).'),
    ('Arq - Fila pendente por arquiteto', '00OV2000009dQn6MAE',
     'Os mesmos itens pendentes agrupados pelo arquiteto que assumiu; sem nome significa que ainda está na fila, sem dono.',
     '225 itens sem dono; Paul Nabih Raad 21; Gilmar Balbinot 2.'),
    ('Arquitetura - Opps aguardando (abertas)', '00OV2000009cqy5MAA',
     'Oportunidades B2B abertas aguardando arquitetura, apenas nas fases Viabilidade e desenho da solução e Validação técnica, com dias na fase atual.',
     '249 oportunidades: 231 em Viabilidade e desenho da solução (média 10,9 dias) e 18 em Validação técnica (média 3,8 dias).'),
    ('Arquitetura - Validações por arquiteto', '00OV2000009cR6sMAE',
     'Itens concluídos nos últimos 30 dias por arquiteto, só os 17 nomes da lista e só passos concluídos de verdade: quantidade, horas e dias (soma, média e máximo).',
     '1.267 validações concluídas em 30 dias por 15 arquitetos; tempo médio de 117 horas (4,9 dias) entre entrada e conclusão.'),
    ('Arquitetura - Volume mensal', '00OV2000009cR6tMAE',
     'Matriz arquiteto x mês de conclusão dos últimos 90 dias, com a mesma lista de 17 arquitetos.',
     '3.938 validações concluídas em 90 dias; média de 108,7 horas por item.'),
    ('Arq - Viabilidade: dias por arquiteto', '00OV2000009dQn5MAE',
     'Tempo de cada oportunidade na fase Viabilidade e desenho da solução (90 dias), por quem encerrou a fase.',
     '1.816 saídas da fase em 90 dias; média de 7,1 dias na fase; máximo 213 dias.'),
    ('Arq - Viabilidade: saídas por destino', '00OV2000009dQn4MAE',
     'Para onde a oportunidade foi ao sair de Viabilidade: Análise cliente (aprovada, segue para proposta) ou Em negociação (devolvida ao vendedor), com a taxa de cada destino.',
     'Taxa de aprovação de 86,3% (1.567 seguiram para proposta) e 13,7% devolvidas (249).'),
    ('Arq - Validação técnica: dias por mês', '00OV2000009dQn3MAE',
     'Tempo de cada oportunidade na fase Validação técnica, por mês de saída, 90 dias.',
     '1.225 saídas em 90 dias; média de 1,3 dia na fase; setembro com 269 saídas e média de 1,35 dia.'),
]

REQUISITOS = [
    ('Fila geral: responsável por item e há quanto tempo está na fila', 'Atendido', 'Fila pendente por idade'),
    ('Detalhe por arquiteto: quem está com o quê e há quanto tempo', 'Atendido', 'Fila pendente por arquiteto'),
    ('Fórmulas de tempo revisadas (entrada até conclusão) e coerência entre média, máximo e quantidade', 'Atendido', 'Validações por arquiteto'),
    ('Tempo médio de atendimento por profissional', 'Atendido', 'Validações por arquiteto'),
    ('Tempo total na fila de arquitetura e tempo de elaboração do desenho no setor', 'Atendido', 'Viabilidade: dias por arquiteto; Validação técnica: dias por mês'),
    ('Volume atendido no mês e visão de 90 dias', 'Atendido', 'Volume mensal'),
    ('Filtro pela lista de 17 arquitetos, incluindo Jeferson Manfio', 'Atendido', 'Validações por arquiteto; Volume mensal'),
    ('Taxa de conversão: desenhos que avançam para proposta', 'Atendido', 'Viabilidade: saídas por destino'),
    ('Oportunidades aguardando arquitetura só nas fases técnicas (sem Em negociação)', 'Atendido', 'Opps aguardando (abertas)'),
    ('Limpeza de itens fora do fluxo', 'Atendido', '47 oportunidades fechadas limpas em 18/09; item de 191 dias (Em negociação) cancelado em 21/09; idade máxima da fila caiu de 200,8 para 77,9 dias'),
    ('Acesso da liderança aos relatórios', 'Atendido', 'Pasta Performance Arquitetura compartilhada com Vilson de Moura Hopf Junior (acesso de edição)'),
    ('Duas versões por fase nos relatórios de itens (Viabilidade x Validação técnica)', 'Parcial, decisão pendente',
     'Nos relatórios de histórico de oportunidade a fase já é separada. Nos itens de aprovação a plataforma usa o mesmo passo nas duas fases e o item não guarda a fase; a alternativa é um campo na oportunidade preenchido pela automação, a combinar'),
    ('Expurgar da Validação técnica o tempo de espera de terceiros (BKO, vendedor, cliente)', 'Parcial, decisão pendente',
     'Fases próprias (aprovação comercial, crédito, análise cliente) já ficam fora. A espera do formulário do BKO dentro da mesma fase exige uma fase "Pendente BKO" ou um campo de data preenchido pela automação; decisão da Priscila'),
]

PRATICAS = [
    'Assumir o item ao começar a análise: hoje 225 dos 248 itens pendentes estão sem dono, e a visão por arquiteto só fica completa com essa prática combinada em 18/09.',
    'Manter a fila limpa de forma permanente: a limpeza feita até aqui foi por rotina manual; o próximo passo é a automação que cancela o item quando a oportunidade sai das fases técnicas ou fecha, a construir e testar em sandbox antes de ir para produção.',
    'Definir a meta de SLA por fase para a fila (proposta em aberto com a Priscila), o que permite destacar no relatório os itens fora do prazo.',
]


def md():
    L = [f'# Status dos relatórios de Performance de Arquitetura - {DATA}', '',
         'Programa Salesforce Brasil Tecpar. Pasta "Performance Arquitetura" na org de produção, compartilhada com Vilson de Moura '
         'Hopf Junior. Os números abaixo são da execução dos relatórios em ' + DATA + '.', '',
         f'Pasta: {ORG}/lightning/r/Folder/{PASTA_ID}/view', '',
         '## Relatórios entregues', '', '| Relatório | O que responde | Leitura em ' + DATA + ' | Link |', '|---|---|---|---|']
    for n, i, o, l in RELATORIOS:
        L.append(f'| {n} | {o} | {l} | {ORG}/lightning/r/Report/{i}/view |')
    L += ['', '## Requisitos solicitados e situação', '', '| Requisito | Situação | Onde está atendido |', '|---|---|---|']
    for r, s, o in REQUISITOS:
        L.append(f'| {r} | {s} | {o} |')
    L += ['', '## Práticas e decisões que dependem da área', '']
    L += [f'- {p}' for p in PRATICAS]
    L += ['', 'Documentação técnica dos relatórios e das decisões no repositório do programa (docs/2026-09-18-relatorios-arquitetura-v2-plano.md).', '']
    return '\n'.join(L)


def pdf():
    base = 'C:/Windows/Fonts'
    reg, neg = 'Helvetica', 'Helvetica-Bold'
    if os.path.exists(f'{base}/calibri.ttf'):
        pdfmetrics.registerFont(TTFont('Corpo', f'{base}/calibri.ttf'))
        pdfmetrics.registerFont(TTFont('CorpoB', f'{base}/calibrib.ttf'))
        reg, neg = 'Corpo', 'CorpoB'
    st = {
        'titulo': ParagraphStyle('t', fontName=neg, fontSize=17, leading=22, spaceAfter=6, textColor=colors.HexColor('#0B3D91')),
        'sub': ParagraphStyle('s', fontName=reg, fontSize=10.5, leading=14, spaceAfter=8, textColor=colors.HexColor('#333333')),
        'h1': ParagraphStyle('h1', fontName=neg, fontSize=13, leading=17, spaceBefore=12, spaceAfter=6, textColor=colors.HexColor('#0B3D91')),
        'p': ParagraphStyle('p', fontName=reg, fontSize=9.5, leading=12.5, spaceAfter=4),
        'cel': ParagraphStyle('c', fontName=reg, fontSize=8.5, leading=10.5),
        'celb': ParagraphStyle('cb', fontName=neg, fontSize=8.5, leading=10.5),
        'link': ParagraphStyle('lk', fontName=reg, fontSize=7.5, leading=9.5, textColor=colors.HexColor('#1155CC')),
    }
    estilo_tb = TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#DCE6F5')), ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#999999')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'), ('LEFTPADDING', (0, 0), (-1, -1), 4), ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 3), ('BOTTOMPADDING', (0, 0), (-1, -1), 3)])

    def rodape(canvas, doc):
        canvas.saveState(); canvas.setFont(reg, 8); canvas.setFillColor(colors.HexColor('#666666'))
        canvas.drawString(2 * cm, 1.2 * cm, 'Brasil Tecpar - Programa Salesforce - Relatórios de Performance de Arquitetura')
        canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f'{DATA} - página {doc.page}'); canvas.restoreState()

    doc = SimpleDocTemplate(PDF, pagesize=A4, leftMargin=2 * cm, rightMargin=2 * cm, topMargin=2 * cm, bottomMargin=2 * cm,
                            title='Status dos relatórios de Performance de Arquitetura', author='Brasil Tecpar')
    s = [Paragraph('Status dos relatórios de Performance de Arquitetura', st['titulo']),
         Paragraph(f'Programa Salesforce Brasil Tecpar. Pasta "Performance Arquitetura" na org de produção, compartilhada com '
                   f'Vilson de Moura Hopf Junior. Números da execução dos relatórios em {DATA}.', st['sub']),
         Paragraph(f'Pasta: <link href="{ORG}/lightning/r/Folder/{PASTA_ID}/view">{ORG}/lightning/r/Folder/{PASTA_ID}/view</link>', st['link']),
         Paragraph('1. Relatórios entregues', st['h1'])]
    linhas = [[Paragraph('Relatório', st['celb']), Paragraph('O que responde', st['celb']), Paragraph(f'Leitura em {DATA}', st['celb'])]]
    for n, i, o, l in RELATORIOS:
        url = f'{ORG}/lightning/r/Report/{i}/view'
        linhas.append([Paragraph(f'{escape(n)}<br/><link href="{url}"><font color="#1155CC" size="7">abrir relatório</font></link>', st['cel']),
                       Paragraph(escape(o), st['cel']), Paragraph(escape(l), st['cel'])])
    tb = Table(linhas, colWidths=[4.2 * cm, 7.3 * cm, 5.5 * cm], repeatRows=1); tb.setStyle(estilo_tb); s.append(tb)
    s.append(Paragraph('2. Requisitos solicitados e situação', st['h1']))
    linhas = [[Paragraph('Requisito', st['celb']), Paragraph('Situação', st['celb']), Paragraph('Onde está atendido', st['celb'])]]
    for r, sit, o in REQUISITOS:
        linhas.append([Paragraph(escape(r), st['cel']), Paragraph(escape(sit), st['cel']), Paragraph(escape(o), st['cel'])])
    tb = Table(linhas, colWidths=[6.2 * cm, 2.8 * cm, 8 * cm], repeatRows=1); tb.setStyle(estilo_tb); s.append(tb)
    s.append(Paragraph('3. Práticas e decisões que dependem da área', st['h1']))
    for p in PRATICAS:
        s.append(Paragraph('- ' + escape(p), st['p']))
    doc.build(s, onFirstPage=rodape, onLaterPages=rodape)


if __name__ == '__main__':
    open(MD, 'w', encoding='utf8').write(md())
    pdf()
    print('gerados:', MD, 'e', PDF)
