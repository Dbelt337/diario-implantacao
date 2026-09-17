#!/usr/bin/env python3
"""Gera o arquivo no cabecalho do Diego (17/09) a partir da saida do conversor core_para_control_plane.py:
uma linha por opcao do Core, ids de volta, sem colunas duplicadas, colunas novas preenchidas com o que se deriva.
Uso: python gerar_arquivo_diego.py [--saida saida]"""
import argparse, collections, csv, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from core_para_control_plane import tabela, texto, write_xlsx  # noqa: E402

CAB = ['OFERTA_ID', 'SERVICO_ID', 'COMPONENTE_ID', 'COMPONENTE_OPCAO_ID', 'IDENTIFICADOR_UNICO', 'OFERTA', 'SERVICO', 'COMPONENTE', 'COMPONENTE_OPCAO',
       'TIPO_FISCAL', 'SERVICO_VENDA_AVULSA', 'SERVICO_MENSURADO', 'COMPONENTE_VIABILIDADE', 'COMPONENTE_OBRIGATORIO', 'COMPONENTE_IGNORAR', 'OPCAO_VIABILIDADE', 'OPCAO_PESO',
       'OPCAO_VALOR_MRC', 'OPCAO_VALOR_NRC', 'COD_SAP', 'SEGMENTO', 'CATALOGO', 'MERCADO', 'CANAL_VENDA', 'ZONA_DISP', 'CLASSE_DE_PROD', 'MOEDA', 'LISTA_DE_PRECO',
       'REGRA_PORTFOLIO', 'SITUACAO_VLR', 'DESC_FISCAL_SAP', 'VIGENCIA_INICIO', 'VIGENCIA_FIM', 'GERA_ATIVO', 'OM', 'LAYOUT_FISCAL', 'CARD_MIN', 'CARD_DEFAULT', 'CARD_MAX',
       'VALOR_MINIMO_MENSAL', 'VALOR_MINIMO_INSTALACAO', 'VALOR_TECNICO', 'TIPO_ELEMENTO', 'CODIGO_CANONICO', 'CODIGO_COMPONENTE', 'CODIGO_OFERTA',
       'COMPONENTE_TIPO', 'TIPO_SERVICO', 'GRUPO_ESCOLHA', 'UNIDADE', 'ACAO', 'PENDENCIAS', 'DECIDIDO_POR', 'DATA_DECISAO']

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--saida', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'saida')); a = ap.parse_args()
    src = list(csv.DictReader(open(os.path.join(a.saida, 'core_control_plane_opcoes.csv'), encoding='utf-8-sig'), delimiter=';'))
    out = []
    for r in src:
        prod = r['TIPO_ELEMENTO'] != 'VALOR_PICKLIST'
        o = collections.OrderedDict((c, '') for c in CAB)
        for c in ('OFERTA_ID', 'SERVICO_ID', 'COMPONENTE_ID', 'COMPONENTE_OPCAO_ID', 'IDENTIFICADOR_UNICO', 'OFERTA', 'SERVICO', 'COMPONENTE', 'COMPONENTE_OPCAO',
                  'TIPO_FISCAL', 'COMPONENTE_TIPO', 'TIPO_SERVICO', 'GRUPO_ESCOLHA', 'VALOR_TECNICO', 'ACAO', 'PENDENCIAS'):
            o[c] = r[c]
        o['SERVICO_VENDA_AVULSA'] = '0'; o['SERVICO_MENSURADO'] = '0'; o['COMPONENTE_VIABILIDADE'] = 'Não necessita'
        o['COMPONENTE_OBRIGATORIO'] = r['OBRIGATORIO']; o['COMPONENTE_IGNORAR'] = '1' if r['ACAO'] == 'IGNORAR' else '0'
        o['OPCAO_VIABILIDADE'] = r['VIABILIDADE']; o['OPCAO_PESO'] = r['SEQUENCIA']
        o['CLASSE_DE_PROD'] = r['CLASSE_PROPOSTA']; o['MOEDA'] = 'BRL'
        o['CARD_MIN'] = r['QTD_MIN']; o['CARD_DEFAULT'] = r['QTD_PADRAO']; o['CARD_MAX'] = r['QTD_MAX']
        o['TIPO_ELEMENTO'] = r['DECISAO_PROPOSTA']
        o['CODIGO_CANONICO'] = r['OPCAO_CODIGO'] or (r['COMPONENTE_CODIGO'] if r['TIPO_ELEMENTO'] == 'QUANTIDADE_DO_FILHO' else '')
        o['CODIGO_COMPONENTE'] = r['COMPONENTE_CODIGO']; o['CODIGO_OFERTA'] = r['OFERTA_CODIGO']
        o['UNIDADE'] = 'UN' if prod else ''; o['GERA_ATIVO'] = '1' if prod else ''
        if r['TIPO_COBRANCA'] == 'UNICA': o['PENDENCIAS'] = (o['PENDENCIAS'] + '; ' if o['PENDENCIAS'] else '') + 'preco vai em OPCAO_VALOR_NRC'
        out.append(o)
    leia = ['Arquivo do Core no cabecalho do Diego (17/09): uma linha por opcao, %d linhas' % len(out), '',
            '## O que ja esta preenchido', 'Ids, nomes, hierarquia, fiscal, tipo de servico, obrigatorio, ignorar, viabilidade, ordem (tudo do Core).',
            'CLASSE_DE_PROD (proposta por TIPO_SERVICO), MOEDA = BRL, CARD_MIN/DEFAULT/MAX (obrigatorio e "Nenhum"), TIPO_ELEMENTO (decisao proposta),',
            'CODIGO_CANONICO / CODIGO_COMPONENTE / CODIGO_OFERTA (propostos), UNIDADE = UN e GERA_ATIVO = 1 nos produtos filhos, VALOR_TECNICO (o antigo OPCAO_VALOR), ACAO, PENDENCIAS.',
            '', '## O que voce (ou o Comercial) preenche', 'OPCAO_VALOR_MRC, OPCAO_VALOR_NRC, COD_SAP, SEGMENTO, CATALOGO, MERCADO, CANAL_VENDA, ZONA_DISP, LISTA_DE_PRECO,',
            'REGRA_PORTFOLIO, SITUACAO_VLR, DESC_FISCAL_SAP, VIGENCIA_INICIO, VIGENCIA_FIM, OM, LAYOUT_FISCAL, VALOR_MINIMO_*, DECIDIDO_POR, DATA_DECISAO.',
            'Vazio = todos so em MERCADO, CANAL_VENDA e ZONA_DISP. Datas AAAA-MM-DD. Valores com ponto decimal.', '',
            '## Cabecalho', 'Ids de volta; SITUACAO_VLR, TIPO FISCAL, VALOR MENSAL, VALOR ATIVACAO e CARDINALIDADE duplicados removidos; espacos viraram sublinhado.',
            'TIPO_ELEMENTO e CODIGO_* sao propostas: mude na linha e registre DECIDIDO_POR e DATA_DECISAO.']
    write_xlsx(os.path.join(a.saida, 'Core_Control_Plane_Diego.xlsx'), [('LEIA-ME', texto(leia)), ('OPCOES', tabela(out, CAB))])
    with open(os.path.join(a.saida, 'Core_Control_Plane_Diego.csv'), 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=CAB, delimiter=';'); w.writeheader(); w.writerows(out)
    print(len(out), 'linhas,', len(CAB), 'colunas')

if __name__ == '__main__':
    main()
