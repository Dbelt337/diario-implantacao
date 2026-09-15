# Gera os .docx (formato do export de 11/09) das works que nao tinham doc, a partir do dump do script 16
# (Details + criterios de aceite). Uso: python3 gerar_docx_from_dump.py <template.docx> <dump16.json> <saida>
import sys, os, re, json
sys.path.insert(0, os.path.dirname(__file__))
from docx_tpl import *
TPL, DUMP, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
GERADO = '15/09/2026 (conteúdo integral da work no Agile Accelerator, incluindo notas de refinamento)'
EPC = 'Catálogo Comercial Unificado - B2B/B2C'
# Cabecalho vindo do DOC16| SEM DOC (log do script 16, org de producao, 15/09)
META = {
 'W-000042': dict(codigo='', titulo='Catalogo - Definir a fronteira campo × atributo e os campos estáticos do produto', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint 1 - SysMap (15-26/09)', criada='29/07/2026 por Diego Beltrão de Moraes'),
 'W-000043': dict(codigo='', titulo='Catalogo - Construir picklists, attribute categories e atributos reutilizáveis', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint 1 - SysMap (15-26/09)', criada='29/07/2026 por Diego Beltrão de Moraes'),
 'W-000044': dict(codigo='', titulo='Catalogo - Fixar padrão comercial × técnico (Offer × Specification)', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint 1 - SysMap (15-26/09)', criada='29/07/2026 por Diego Beltrão de Moraes'),
 'W-000045': dict(codigo='', titulo='Comercial - Filtro de viabilidade e disponibilidade dinâmica no catálogo', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint Catálogo - 1a e 2a Semana', criada='30/07/2026 por Priscila De Lima'),
 'W-000046': dict(codigo='', titulo='Comercial - Montagem de propostas com bundles guiados e cross-sell', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint Catálogo - 1a e 2a Semana', criada='30/07/2026 por Priscila De Lima'),
 'W-000047': dict(codigo='', titulo='Comercial - Seleção de oferta com automatização de tecnologia', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint Catálogo - 1a e 2a Semana', criada='30/07/2026 por Priscila De Lima'),
 'W-000048': dict(codigo='', titulo='Comercial - Precificação dinâmica regionalizada', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint Catálogo - 1a e 2a Semana', criada='30/07/2026 por Priscila De Lima'),
 'W-000049': dict(codigo='', titulo='Comercial - Alteração via Asset-to-Order e histórico de base', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint Catálogo - 1a e 2a Semana', criada='30/07/2026 por Priscila De Lima'),
 'W-000050': dict(codigo='', titulo='Comercial - Cotação de múltiplas filiais em lote e geração do código RGC', epico=EPC, time='SysMap', status='New', responsavel='Thiago Campos Almeida', sprint='Sprint Catálogo - 1a e 2a Semana', criada='30/07/2026 por Priscila De Lima'),
 'W-000070': dict(codigo='EPC-10', titulo='Criação dos catálogos comerciais por família e estrutura B2B/B2C', epico=EPC, time='SysMap', status='New', responsavel='Davi Israel de Abreu', sprint='(sem sprint)', criada='26/08/2026 por Diego Beltrão de Moraes'),
 'W-000133': dict(codigo='', titulo='INTEGRAÇÕES - CI/CD: subir repositório GitLab e implementar esteira básica de CI/CD', epico='Integração, Barramento (MuleSoft) e CI/CD', time='Brasil TecPar', status='New', responsavel='(a definir)', sprint='Sprint 1 - Brasil TecPar (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
 'W-000134': dict(codigo='', titulo='INTEGRAÇÕES - Ambientes: formalizar licenciamento e ajustes das Sandboxes junto à Salesforce (destravar O&M)', epico='Integração, Barramento (MuleSoft) e CI/CD', time='Brasil TecPar', status='New', responsavel='(a definir)', sprint='Sprint 1 - Brasil TecPar (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
 'W-000135': dict(codigo='', titulo='INTEGRAÇÕES - MuleSoft: cobrar orçamento da avaliação do arquiteto e mapear demandas pendentes do barramento', epico='Integração, Barramento (MuleSoft) e CI/CD', time='Brasil TecPar', status='New', responsavel='(a definir)', sprint='Sprint 1 - Brasil TecPar (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
 'W-000136': dict(codigo='', titulo='ARQUITETURA - Mapear fluxo e arquitetura das APIs do B2B (sessão Victor/David/Zildo/Priscila/Fernanda)', epico='Arquitetura da Solução e Ambientes', time='Brasil TecPar', status='New', responsavel='(a definir)', sprint='Sprint 1 - Brasil TecPar (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
 'W-000137': dict(codigo='', titulo='ARQUITETURA - Finalizar decomposição e camada técnica do catálogo (discussão de OM)', epico='Arquitetura da Solução e Ambientes', time='Brasil TecPar', status='New', responsavel='(a definir)', sprint='Sprint 1 - Brasil TecPar (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
 'W-000140': dict(codigo='', titulo='B2B - Habilitar integração B2B para permitir execução de testes (urgente)', epico='B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente', time='SysMap', status='New', responsavel='(a definir)', sprint='Sprint 1 - SysMap (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
 'W-000141': dict(codigo='', titulo='B2B - Escrever histórias funcionais/técnicas B2B (onboarding 3 novos profissionais SysMap)', epico='B2B - Jornadas de Venda e Gestão do Ciclo de Vida do Cliente', time='SysMap', status='New', responsavel='(a definir)', sprint='Sprint 1 - SysMap (15-26/09)', criada='15/09/2026 por Gerson Da Silva Pereira'),
}
HEADINGS = {  # texto normalizado -> titulo da secao no doc
 'contexto da funcionalidade': 'Contexto da Funcionalidade', '(user story classica)': 'Descrição', '(user story)': 'Descrição',
 'descricao': 'Descrição', 'descricao (user story classica)': 'Descrição', 'titulo padrao': 'Título Padrão',
 'criterios de aceite': 'Critérios de Aceite', 'criterios de aceite (formato gherkin/bdd)': 'Critérios de Aceite',
 'direcionamento de arquitetura cpq': 'Direcionamento de Arquitetura CPQ (Para Admins/Devs)',
 'direcionamento de arquitetura cpq (para admins/devs)': 'Direcionamento de Arquitetura CPQ (Para Admins/Devs)',
 'riscos e impactos no sistema': 'Riscos e Impactos no Sistema', 'cenario e contexto de negocio': 'Cenário e Contexto de Negócio',
 'regras de negocio associadas': 'Regras de Negócio Associadas', 'configuracao de componentes': 'Configuração de Componentes',
 'configuracao de componentes no epc/cpq': 'Configuração de Componentes no EPC/CPQ',
 'objetivo': 'Objetivo', 'escopo': 'Escopo', 'escopo (esteira basica)': 'Escopo (esteira básica)', 'escopo da sessao': 'Escopo da Sessão',
 'entregas': 'Entregas', 'fora de escopo nesta work': 'Fora de Escopo nesta Work', 'dependencias e riscos': 'Dependências e Riscos',
 'situacao encontrada em 15/09 (producao)': 'Situação Encontrada em 15/09 (produção)', 'situacao em 15/09': 'Situação em 15/09',
 'premissas ja decididas': 'Premissas já Decididas', 'inventario inicial de demandas do barramento (extraido das works, 15/09)': 'Inventário Inicial de Demandas do Barramento (extraído das works, 15/09)',
}
def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower().strip()
    s = re.sub(r'^\d+\.\s*', '', s); return s.rstrip(':').strip()
GH = re.compile(r'^(Como|Eu quero|Quero|Para que|Dado|Quando|Então)\b\s*', re.I)
CEN = re.compile(r'^(Cenário|Critério)\s*\d+\s*[:—–-]\s*(.*)$')

def prep(text):
    """Limpa o Details: remove linhas so com pontuacao, junta linhas iniciadas por virgula/', ' e 'Cenario N:' vazio com a seguinte."""
    raw = [l.rstrip() for l in text.replace('\r', '').split('\n')]
    out = []
    for l in raw:
        s = l.strip()
        if s in ('', '.', ','): continue
        if s.startswith('•'): s = '•' + s[1:].lstrip('\t ').strip()
        if out and s.startswith('. '): out[-1] = out[-1].rstrip() + s; continue
        if out and (s.startswith(',') or s.startswith(') ') or (s[0].islower() and not out[-1].endswith(('.', ':')))):
            out[-1] = (out[-1].rstrip() + ('' if s.startswith(',') else ' ') + s); continue
        if out and re.match(r'^(Cenário|Critério)\s*\d+\s*:\s*$', out[-1]):
            out[-1] = out[-1].strip() + ' ' + s; continue
        if out and out[-1].endswith(':') and len(out[-1]) < 45 and norm(out[-1]) not in HEADINGS:
            out[-1] = out[-1] + ' ' + s; continue
        out.append(s)
    return out

def labeled_runs(s):
    """'Rotulo: texto' -> runs com rotulo em negrito; senao None."""
    m = re.match(r'^([^:]{2,60}):\s+(.+)$', s)
    if m and '. ' not in m.group(1): return run(m.group(1) + ': ', b=True) + run(m.group(2))
    return None

def linhas_para_xml(lines):
    out = []; em_cenario = False
    for s in lines:
        bul = s.startswith('•')
        if bul: s = s[1:].strip()
        n = norm(s)
        if not bul and n in HEADINGS:
            out.append(heading(HEADINGS[n])); em_cenario = False; continue
        m = re.match(r'^---\s*(.+?)\s*---$', s)
        if m: out.append(heading(m.group(1))); em_cenario = False; continue
        if not bul and re.match(r'^\d+\.\s+\S', s) and len(s) < 90 and s.endswith(':'):
            out.append(heading(re.sub(r'^\d+\.\s*', '', s).rstrip(':'))); continue
        m = CEN.match(s)
        if m:
            out.append(bullet(3, 0, run(s, b=True), keep=True)); em_cenario = True; continue
        g = GH.match(s)
        if g:
            lab = g.group(1); rest = s[g.end():]
            if lab.lower() in ('dado', 'quando', 'então'):
                out.append(bullet(3, 1, run(lab + ' ', b=True) + run(rest)))
            else:
                out.append(bullet(1, 0, run(lab + ' ', b=True) + run(rest)))
            continue
        m = re.match(r'^(P-\d+\s+—\s+[^.]+\.)\s*(.*)$', s)
        if m: out.append(p(run(m.group(1) + ' ', b=True) + run(m.group(2)))); continue
        lr = labeled_runs(s)
        if bul: out.append(bullet(1, 0, lr if lr else run(s)))
        elif lr: out.append(p(lr))
        elif re.match(r'^\[EPC\]', s): out.append(p(run(s, b=True)))
        else: out.append(plain(s))
    return out

def criterios_xml(crits):
    out = [heading('Critérios de Aceite (registros de Acceptance Criteria no Agile Accelerator)')]
    for c in crits:
        parts = re.split(r'\s*\|\s*', c, maxsplit=5)  # DOC16 | W | criterio | Name | Status | Descricao
        status, texto = parts[4].strip(), ' | '.join(parts[5:])
        lines = prep(texto)
        for i, s in enumerate(lines):
            s = s[1:].strip() if s.startswith('•') else s
            if i == 0: out.append(bullet(3, 0, run(s + f' (status: {status})', b=True), keep=True)); continue
            g = GH.match(s)
            if g: out.append(bullet(3, 1, run(g.group(1) + ' ', b=True) + run(s[g.end():])))
            else: out.append(bullet(3, 1, run(s)))
    return out

def build_body(work, m, d):
    code, subj = m['codigo'], m['titulo']
    us = (f'US {code} — {subj}') if code else subj
    out = []
    out.append(p(run('Requisitos de negócio Projeto Salesforce', b=True, color='0C3C8C', sz=44), '<w:spacing w:after="100"/><w:jc w:val="center"/>'))
    out.append(p(run(us, b=True, color='0C3C8C', sz=28), '<w:spacing w:before="600" w:after="200"/><w:jc w:val="center"/>'))
    out.append(p(run(f'{work}  ·  {m["epico"]}', color='595959', sz=22), '<w:jc w:val="center"/>'))
    out.append(p(run(f'Time: {m["time"]}  ·  Status: {m["status"]}', color='595959', sz=22), '<w:jc w:val="center"/>'))
    out.append(empty())
    out.append(p(run(('US - ' + code + ' — ' + subj) if code else subj, b=True), '<w:spacing w:after="120"/>'))
    out.append(table([('Work', work), ('Épico', m['epico']), ('Time (Scrum Team)', m['time']), ('Status', m['status']),
                      ('Responsável', m['responsavel']), ('Sprint', m['sprint']), ('Documento gerado em', GERADO)]))
    out.append(empty())
    out.append(p(run(f'Work criada em {m["criada"]}. Texto abaixo transcrito integralmente do campo Details da work.', i=True, color='595959', sz=20), '<w:spacing w:after="60"/>'))
    lines = prep(d['details'])
    # criterios registrados como AC entram antes da primeira nota "--- ... ---" (se houver), senao no fim
    cut = next((i for i, l in enumerate(lines) if l.startswith('---')), len(lines))
    out += linhas_para_xml(lines[:cut])
    if d['criterios']: out += criterios_xml(d['criterios'])
    if cut < len(lines):
        out.append(heading('Notas de Refinamento'))
        out += linhas_para_xml(lines[cut:])
    return ''.join(out)

dump = json.load(open(DUMP, encoding='utf8'))
for work in sorted(dump):
    if work not in META: print('sem META, pulando:', work); continue
    m = META[work]
    print('gerado:', gerar_docx(TPL, OUT, dict(work=work, codigo=m['codigo'], titulo=m['titulo']), build_body(work, m, dump[work])))
