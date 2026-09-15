# Gera os .docx das works novas (B2B-13 a 16) no formato do export de 11/09. Uso: python3 gerar_docx_works.py <template.docx> <saida>
import sys, os, importlib.util
from docx_tpl import *
TPL, OUT = sys.argv[1], sys.argv[2]
def build_body(w):
    code, subj = w['codigo'], w['titulo']
    out = []
    out.append(p(run('Requisitos de negócio Projeto Salesforce', b=True, color='0C3C8C', sz=44), '<w:spacing w:after="100"/><w:jc w:val="center"/>'))
    out.append(p(run(f'US {code} — {subj}', b=True, color='0C3C8C', sz=28), '<w:spacing w:before="600" w:after="200"/><w:jc w:val="center"/>'))
    out.append(p(run(f'{w["work"]}  ·  {w["epico"]}', color='595959', sz=22), '<w:jc w:val="center"/>'))
    out.append(p(run(f'Time: {w["time"]}  ·  Status: {w["status"]}', color='595959', sz=22), '<w:jc w:val="center"/>'))
    out.append(empty())
    out.append(p(run(f'US - {code} — {subj}', b=True), '<w:spacing w:after="120"/>'))
    out.append(table([('Work', w['work']), ('Épico', w['epico']), ('Time (Scrum Team)', w['time']), ('Status', w['status']),
                      ('Responsável', w['responsavel']), ('Documento gerado em', w['gerado'])]))
    out.append(empty())
    out.append(p(run(w['nota'], i=True, color='595959', sz=20), '<w:spacing w:after="60"/>'))
    out.append(heading('Descrição'))
    out.append(bullet(1, 0, run('Como ', b=True) + run(w['como'])))
    out.append(bullet(1, 0, run('Quero ', b=True) + run(w['quero'])))
    out.append(bullet(1, 0, run('Para que ', b=True) + run(w['para_que'])))
    out.append(empty())
    out.append(heading('Contexto e Cenário de Negócio'))
    for t in w['contexto']: out.append(plain(t))
    out.append(heading('Regras de Negócio Associadas'))
    for t in w['regras']: out.append(plain(t))
    out.append(heading('Especificação Técnica (Salesforce)'))
    for t in w['especificacao']: out.append(plain(t))
    out.append(heading('Dependências, Riscos e Estimativa'))
    out.append(labeled('Dependências: ', w['dependencias']))
    out.append(labeled('Riscos: ', w['riscos']))
    out.append(labeled('Estimativa: ', w['estimativa']))
    out.append(heading('Critérios de Aceite'))
    for i, (t, d, q, e) in enumerate(w['criterios'], 1):
        out.append(bullet(3, 0, run(f'Critério {i}: {t}.', b=True), keep=True))
        out.append(bullet(3, 1, run('Dado ', b=True) + run(d)))
        out.append(bullet(3, 1, run('Quando ', b=True) + run(q)))
        out.append(bullet(3, 1, run('Então ', b=True) + run(e)))
    out.append(empty())
    out.append(labeled('Massa de Teste Sugerida: ', w['massa']))
    if w.get('fundamentacao'):
        out.append(heading('Fundamentação Técnica (Salesforce Help)'))
        for t in w['fundamentacao']: out.append(plain(t))
    return ''.join(out)


spec = importlib.util.spec_from_file_location('conteudo', os.path.join(os.path.dirname(__file__), 'conteudo_works_b2b13a16.py'))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
for w in m.WORKS:
    print('gerado:', gerar_docx(TPL, OUT, dict(work=w['work'], codigo=w['codigo'], titulo=w['titulo']), build_body(w)))
