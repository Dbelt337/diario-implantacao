"""Gera o PDF das works do programa ligadas ao licenciamento do Order Management e ao MuleSoft,
com as pendencias que dependem da Salesforce e da Brasil Tecpar.

Uso (na raiz do repo, org btp-prod autenticada):
    python tools/agile/gerar_pdf_works_om_mule.py
    python tools/agile/gerar_pdf_works_om_mule.py --json caminho/consulta.json   (usa um retorno salvo do sf data query)

Saida: docs/2026-09-23-works-licenciamento-om-mulesoft.pdf
"""
import json
import os
import subprocess
import sys
import tempfile
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (KeepTogether, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table,
                                TableStyle)

ORG = 'btp-prod'
SAIDA = 'docs/2026-09-23-works-licenciamento-om-mulesoft.pdf'
DATA = '23/09/2026'

# Works com texto completo no PDF, na ordem de leitura
TEMA = ['W-000134', 'W-000135', 'W-000136', 'W-000137', 'W-000140', 'W-000133',
        'W-000087', 'W-000088', 'W-000118', 'W-000093', 'W-000105', 'W-000110', 'W-000131']

# Works cuja entrega depende da provisao das licencas de Order Management (W-000134)
BLOQUEADAS_OM = ['W-000080', 'W-000088', 'W-000093', 'W-000094', 'W-000099', 'W-000100', 'W-000101', 'W-000116',
                 'W-000118', 'W-000124', 'W-000125', 'W-000137', 'W-000143', 'W-000160', 'W-000164', 'W-000166']

# Pendencias que dependem da Salesforce (AE) ou de decisao da Brasil Tecpar
PENDENCIAS = [
    ('W-000134', 'Provisão das licenças de Order Management do aditivo comercial: entitlement de ordens B2C e B2B '
                 '(hoje Allowance 0, vigência encerrada em 16/06/2026, 252 ordens usadas, sem linha B2B). Case aberto; '
                 'falta data prevista e confirmação das quantidades.', 'Salesforce (AE) / Gerson'),
    ('W-000134', 'Após a provisão em produção: Match Production Licenses em preprod e radardev; realocação da licença do '
                 'pacote Vlocity CMT (1/1, hoje com usuário de Field Service) para o usuário de integração ou administrador '
                 'do projeto; teste de fumaça de submissão de pedido em preprod.', 'Brasil Tecpar (Diego) / Salesforce'),
    ('W-000134', 'PSL Communications Cloud Plus com 2.100 de 2.100 atribuídas: revisar a atribuição e confirmar se o '
                 'contrato cobre os usuários do programa (perfis B2B e B2C).', 'Brasil Tecpar / Salesforce (AE)'),
    ('W-000135', 'Confirmar se o add-on MuleSoft Direct for Communications Cloud está contratado; sem confirmação, as '
                 'integrações TMF prontas não entram como premissa e o barramento constrói os endpoints.', 'Salesforce (AE)'),
    ('W-000135', 'Orçamento da avaliação de arquitetura MuleSoft (architect assessment): escopo, prazo e valor, com '
                 'decisão de contratação do gestor.', 'MuleSoft / parceiro via Salesforce; Gerson'),
    ('W-000135', 'Ambientes de homologação do MuleSoft (qas) e credenciais para radardev e preprod; sem eles os testes '
                 'das jornadas B2B ficam no mock (W-000140).', 'Brasil Tecpar (time Mule) / SysMap'),
    ('W-000136', 'Sessão de arquitetura das APIs B2B (Victor, David, Zildo, Priscila, Fernanda) e registro do ADR do '
                 'Order Management: Plan A (Industries OM do pacote), Plan B (MuleSoft só para parceiro sem contrato TMF), '
                 'Plan C (DRO no Core, roadmap).', 'Brasil Tecpar (Diego)'),
    ('W-000137', 'Plan C: Dynamic Revenue Orchestrator no Core (Agentforce Revenue Management) implica novo licenciamento; '
                 'avaliação em 2027 e decisão a levar ao presidente. Pedir a Salesforce roadmap e condições comerciais.',
     'Salesforce (AE) / presidência Brasil Tecpar'),
    ('W-000137', 'De-para de material SAP dos 16 produtos filhos (pendência P6, Rodrigo/fiscal) para fechar a decomposição.',
     'Brasil Tecpar (Rodrigo)'),
    ('W-000069', 'Seats on-core de Product Catalog Management e Unified Catalog (PSLs atribuídas a 5 administradores, sem '
                 'uso): confirmar com o AE o que destravam e se entram no Plan C.', 'Salesforce (AE)'),
    ('W-000107', 'Sandbox dedicada sem dados de clientes para o motor de regras de precificação (ação do Bismarck).',
     'Salesforce (AE)'),
    ('W-000094', 'Parceiros de delivery que entram por TMF641 (ordem de campo): quem são e se entram na Onda 1; escopo '
                 'em aberto com Bismarck e Gerson.', 'Salesforce (AE) / Gerson'),
    ('W-000131', 'Contrato do TMF641 do btp-tmf-service sem enums: validação funcional fica no Salesforce; escopo de Onda '
                 'a confirmar.', 'Salesforce (AE) / Brasil Tecpar'),
    ('W-000129', 'Fronteira Zendesk x Salesforce da célula de retenção B2C (recomendação: retenção roda no Salesforce); '
                 'decisão com Bismarck.', 'Salesforce (AE) / Brasil Tecpar'),
    ('W-000092', 'WhatsApp no Marketing Cloud Engagement (GroupConnect) e add-on a confirmar no contrato do MC; sem a '
                 'licença, a fundação Marketing Cloud não começa (impacta W-000066 e W-000076).', 'Salesforce (AE) / Brasil Tecpar'),
    ('W-000105', 'Motor de assinatura eletrônica: nenhum licenciado na org (DocuSign, Adobe Sign ou equivalente); até a '
                 'decisão de fornecedor o aceite é por evidência no Salesforce (impacta W-000065, W-000082, W-000087, W-000122).',
     'Brasil Tecpar (jurídico e compras)'),
    ('W-000140', 'Janela de refresh das sandboxes combinada com SysMap; MFA obrigatória em sandbox (Summer 26) exige '
                 'método de verificação para os usuários de teste.', 'Brasil Tecpar / SysMap'),
    ('W-000141', 'Licenças para os 3 novos profissionais SysMap nas sandboxes (Salesforce full, OmniStudio Designer, '
                 'BREDesigner) e acessos de Brasil Tecpar.', 'Brasil Tecpar (Thiago)'),
    ('W-000133', 'Acesso ao GitLab de Brasil Tecpar para a SysMap, usuário de integração e certificado por org, aprovador '
                 'de Brasil Tecpar para deploy em produção.', 'Brasil Tecpar (Victor / Diego)'),
]


def carregar(json_path=None):
    if json_path:
        return json.load(open(json_path, encoding='utf8'))['result']['records']
    soql = ("SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Priority__c, agf__Status__c, agf__Epic__r.Name, "
            "agf__Sprint__r.Name, agf__Product_Owner__r.Name FROM agf__ADM_Work__c WHERE agf__Subject__c LIKE 'US %' ORDER BY Name")
    with tempfile.NamedTemporaryFile('w', suffix='.soql', delete=False, encoding='utf8') as f:
        f.write(soql)
        p = f.name
    out = subprocess.run(['sf', 'data', 'query', '--file', p, '--target-org', ORG, '--json'],
                         capture_output=True, text=True, encoding='utf8', shell=(os.name == 'nt'))
    os.unlink(p)
    return json.loads(out.stdout)['result']['records']


def fontes():
    base = 'C:/Windows/Fonts'
    if os.path.exists(f'{base}/calibri.ttf'):
        pdfmetrics.registerFont(TTFont('Corpo', f'{base}/calibri.ttf'))
        pdfmetrics.registerFont(TTFont('CorpoB', f'{base}/calibrib.ttf'))
        return 'Corpo', 'CorpoB'
    return 'Helvetica', 'Helvetica-Bold'


def estilos(reg, neg):
    return {
        'titulo': ParagraphStyle('t', fontName=neg, fontSize=20, leading=26, spaceAfter=10, textColor=colors.HexColor('#0B3D91')),
        'sub': ParagraphStyle('s', fontName=reg, fontSize=12, leading=16, spaceAfter=6, textColor=colors.HexColor('#333333')),
        'h1': ParagraphStyle('h1', fontName=neg, fontSize=14, leading=18, spaceBefore=12, spaceAfter=6, textColor=colors.HexColor('#0B3D91')),
        'h2': ParagraphStyle('h2', fontName=neg, fontSize=11, leading=14, spaceBefore=8, spaceAfter=3),
        'p': ParagraphStyle('p', fontName=reg, fontSize=9.5, leading=12.5, spaceAfter=4, alignment=TA_LEFT),
        'mono': ParagraphStyle('m', fontName=reg, fontSize=8.5, leading=11, spaceAfter=3, leftIndent=8),
        'cel': ParagraphStyle('c', fontName=reg, fontSize=8.5, leading=10.5),
        'celb': ParagraphStyle('cb', fontName=neg, fontSize=8.5, leading=10.5),
        'meta': ParagraphStyle('me', fontName=reg, fontSize=8.5, leading=11, textColor=colors.HexColor('#555555'), spaceAfter=6),
    }


SECOES = ('NARRATIVA', 'CONTEXTO E CENARIO DE NEGOCIO', 'CONTEXTO E CENÁRIO DE NEGÓCIO', 'REGRAS DE NEGOCIO', 'REGRAS DE NEGÓCIO',
          'CRITERIOS DE ACEITE', 'CRITÉRIOS DE ACEITE', 'SOLUCAO NATIVA', 'SOLUÇÃO NATIVA', 'DEPENDENCIAS E LICENCAS',
          'DEPENDÊNCIAS E LICENÇAS', 'LICENCAS E CAPACIDADES UTILIZADAS', 'LICENÇAS E CAPACIDADES UTILIZADAS',
          'CHAMADAS SINCRONAS E ASSINCRONAS', 'CHAMADAS SÍNCRONAS E ASSÍNCRONAS', 'OBJETOS', 'REFERENCIAS', 'REFERÊNCIAS',
          'HISTORICO DE DECISOES', 'HISTÓRICO DE DECISÕES', 'FORA DE ESCOPO', 'PONTOS EM ABERTO', 'DEFINITION OF DONE',
          'NOTAS TECNICAS', 'NOTAS TÉCNICAS', 'INTEGRACOES', 'INTEGRAÇÕES')


def detalhes_para_fluxo(texto, st):
    itens = []
    for linha in (texto or '').replace('\r\n', '\n').split('\n'):
        l = linha.rstrip()
        if not l:
            continue
        chave = l.strip().rstrip(':')
        if chave in SECOES or (chave.isupper() and len(chave) < 60 and ' ' in chave):
            itens.append(Paragraph(escape(chave), st['h2']))
        elif ' | ' in l and l.count(' | ') >= 2:
            itens.append(Paragraph(escape(l), st['mono']))
        else:
            itens.append(Paragraph(escape(l), st['p']))
    return itens


def rodape(canvas, doc):
    canvas.saveState()
    canvas.setFont('Corpo' if 'Corpo' in pdfmetrics.getRegisteredFontNames() else 'Helvetica', 8)
    canvas.setFillColor(colors.HexColor('#666666'))
    canvas.drawString(2 * cm, 1.2 * cm, 'Brasil Tecpar - Programa Salesforce - Works de licenciamento do Order Management e MuleSoft')
    canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f'{DATA} - página {doc.page}')
    canvas.restoreState()


def gerar(records, saida):
    reg, neg = fontes()
    st = estilos(reg, neg)
    by = {r['Name']: r for r in records}
    doc = SimpleDocTemplate(saida, pagesize=A4, leftMargin=2 * cm, rightMargin=2 * cm, topMargin=2 * cm, bottomMargin=2 * cm,
                            title='Works de licenciamento do Order Management e MuleSoft', author='Brasil Tecpar',
                            subject='Pendências com a Salesforce e a Brasil Tecpar')
    s = []
    s.append(Spacer(1, 4 * cm))
    s.append(Paragraph('Programa Salesforce Brasil Tecpar', st['sub']))
    s.append(Paragraph('Works de licenciamento do Order Management e MuleSoft', st['titulo']))
    s.append(Paragraph('Pendências com a Salesforce e a Brasil Tecpar para a agenda com a Salesforce', st['sub']))
    s.append(Spacer(1, 1 * cm))
    s.append(Paragraph(f'Extraído do Agile Accelerator da org de produção em {DATA}.', st['p']))
    s.append(Paragraph('Preparado por Diego Beltrão de Moraes, arquitetura de Catálogo, CPQ e Order Management.', st['p']))
    s.append(Paragraph('Para Bismarck Muniz Araujo, Salesforce. Cópia: Gerson Da Silva Pereira.', st['p']))
    s.append(PageBreak())

    s.append(Paragraph('1. Situação do licenciamento e decisão de arquitetura', st['h1']))
    for t in [
        'Order Management: em produção, Usage-Based Entitlements mostra "Maximum B2C orders submitted via Industries Order '
        'Management" com Allowance 0, vigência encerrada em 16/06/2026, 252 ordens usadas e último uso em 29/05/2026; não há '
        'linha de ordens B2B. A licença anterior era cortesia de 12 meses; o novo aditivo comercial inclui OM, mas ainda não '
        'foi provisionado. Enquanto isso, nenhuma jornada que submete pedido ao Industries OM pode ir a produção, e as '
        'sandboxes preprod e radardev herdam a mesma situação no próximo refresh.',
        'Communications Cloud: pacote Vlocity CMT Summer 2026 instalado (EPC, CPQ, CLM e OM no mesmo pacote); PSL '
        'Communications Cloud Plus com 2.100 licenças e 2.100 atribuídas; Document Generation com 646 usuários; Business '
        'Rules Engine licenciado e sem uso; PSLs de Product Catalog Management e Unified Catalog atribuídas a 5 '
        'administradores, sem uso.',
        'Decisão de arquitetura registrada nas works: Plan A, Industries Order Management do pacote, com System Interfaces e '
        'adapters já em produção (padrão da Onda 1); Plan B, MuleSoft apenas para parceiro sem contrato TMF (SAP e Voalle '
        'hoje, sem crescer); Plan C, Dynamic Revenue Orchestrator no Core (Agentforce Revenue Management), roadmap com '
        'avaliação em 2027 e decisão do presidente por implicar novo licenciamento.',
        'MuleSoft: o barramento btp-salesforce-eapi (Experience API) e o domínio btp-tmf-service (TMF645 v5, TMF641 v4 mock, '
        'TMF638 v5) estão em produção. Pendem o orçamento da avaliação de arquitetura, a confirmação do add-on MuleSoft '
        'Direct for Communications Cloud e os ambientes de homologação para as sandboxes.',
        'Releases consideradas: Spring 26 e Summer 26 (Flow Approval Orchestration, Apex em user mode na API 67.0, External '
        'Client Apps no lugar de Connected Apps, MFA obrigatória em sandbox, retirada das APIs 31 a 40, Decision Tables '
        'versionadas, cart trim mode e deep clone do Industries CPQ).',
    ]:
        s.append(Paragraph(t, st['p']))

    s.append(Paragraph('2. Pendências com a Salesforce e a Brasil Tecpar', st['h1']))
    s.append(Paragraph('Cada linha aponta a work de origem, a pendência como está escrita na work e quem precisa responder.', st['p']))
    cab = [Paragraph('Work', st['celb']), Paragraph('Pendência', st['celb']), Paragraph('Quem responde', st['celb'])]
    linhas = [cab]
    for w, p, q in PENDENCIAS:
        titulo = by.get(w, {}).get('agf__Subject__c', '')
        linhas.append([Paragraph(f'{w}<br/>{escape(titulo[:60])}', st['cel']), Paragraph(escape(p), st['cel']), Paragraph(escape(q), st['cel'])])
    tb = Table(linhas, colWidths=[3.6 * cm, 9.9 * cm, 3.5 * cm], repeatRows=1)
    tb.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#DCE6F5')),
        ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#999999')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 4), ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('TOPPADDING', (0, 0), (-1, -1), 3), ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    s.append(tb)

    s.append(Paragraph('3. Works bloqueadas até a provisão das licenças de Order Management', st['h1']))
    s.append(Paragraph('Works que submetem pedido ao Industries OM ou dependem do entitlement de ordens (W-000134). '
                       'Podem ser construídas e testadas em sandbox após o Match Production Licenses, mas não vão a produção antes da provisão.', st['p']))
    linhas = [[Paragraph('Work', st['celb']), Paragraph('Título', st['celb']), Paragraph('Prioridade', st['celb']), Paragraph('Sprint', st['celb'])]]
    for w in BLOQUEADAS_OM:
        r = by.get(w)
        if not r:
            continue
        linhas.append([Paragraph(w, st['cel']), Paragraph(escape(r['agf__Subject__c']), st['cel']),
                       Paragraph(r['agf__Priority__c'] or '', st['cel']), Paragraph(escape((r['agf__Sprint__r'] or {}).get('Name') or ''), st['cel'])])
    tb = Table(linhas, colWidths=[2.2 * cm, 9.3 * cm, 1.9 * cm, 3.6 * cm], repeatRows=1)
    tb.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#DCE6F5')),
        ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#999999')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 4), ('RIGHTPADDING', (0, 0), (-1, -1), 4),
    ]))
    s.append(tb)

    s.append(PageBreak())
    s.append(Paragraph('4. Works do tema: texto completo', st['h1']))
    s.append(Paragraph('Texto como está no Agile Accelerator na data da extração. Ordem: works de ambientes e barramento de '
                       'Brasil Tecpar, depois as fundações técnicas de integração e Order Management.', st['p']))
    for i, w in enumerate(TEMA):
        r = by.get(w)
        if not r:
            continue
        if i:
            s.append(PageBreak())
        cab = [Paragraph(escape(f"{w} - {r['agf__Subject__c']}"), st['h1']),
               Paragraph(escape(f"Prioridade {r['agf__Priority__c'] or '-'} | Status {r['agf__Status__c'] or '-'} | "
                                f"Sprint {(r['agf__Sprint__r'] or {}).get('Name') or '-'} | Épico {(r['agf__Epic__r'] or {}).get('Name') or '-'} | "
                                f"Product Owner {(r['agf__Product_Owner__r'] or {}).get('Name') or '-'}"), st['meta'])]
        s.append(KeepTogether(cab))
        s.extend(detalhes_para_fluxo(r['agf__Details__c'], st))
    doc.build(s, onFirstPage=rodape, onLaterPages=rodape)


if __name__ == '__main__':
    jp = sys.argv[sys.argv.index('--json') + 1] if '--json' in sys.argv else None
    recs = carregar(jp)
    gerar(recs, SAIDA)
    print('gerado:', SAIDA, '| works na org:', len(recs))
