#!/usr/bin/env python3
"""Testes do validador (python3 test_validar_leads.py). Cobre DV, CPF, obrigatorios, listas, telefones, duplicidade no
arquivo, cruzamento com Lead/Conta existentes e resolucao de proprietario/SDR. Template v2 (19 colunas)."""
import unittest
import validar_leads as v

def linha(**kw):
    base = dict(SDR='Vitoria da Costa Hyppolito', Proprietario='vitoria@btp.com.br', Origem='Outbound - Listas GRs ALT', Temperatura='10',
                Segmento='B2W - Wholesale', Cluster='ALT/GGNET', CNPJ='01.145.642/0001-41', RazaoSocial='Phonoway Ltda', NomeFantasia='',
                Nome='Jeferson', Sobrenome='Castelucci', Cargo='', TelefoneFixo='(11) 3874-7111', Celular='', Email='a@b.com.br',
                Cidade='', UF='SP', ProdutoInteresse='', Observacoes='')
    base.update(kw); return base

USERS = [{'Id': '005A', 'Name': 'Vitoria da Costa Hyppolito', 'Email': 'vitoria@btp.com.br', 'IsActive': True},
         {'Id': '005B', 'Name': 'Joao Silva', 'Email': 'joao@btp.com.br', 'IsActive': False},
         {'Id': '005C', 'Name': 'Maria Souza', 'Email': 'maria1@btp.com.br', 'IsActive': True},
         {'Id': '005D', 'Name': 'Maria Souza', 'Email': 'maria2@btp.com.br', 'IsActive': True}]

class T(unittest.TestCase):
    def test_dv(self):
        self.assertTrue(v.cnpj_dv_valido('01145642000141'))
        self.assertFalse(v.cnpj_dv_valido('01145642000142'))
        self.assertFalse(v.cnpj_dv_valido('11111111111111'))
        self.assertEqual(v.classifica_documento(v.normaliza_cnpj('123.456.789-09'))[0], 'CPF')
        self.assertEqual(v.classifica_documento(v.normaliza_cnpj('00012345678909'))[0], 'CPF')
        self.assertEqual(v.classifica_documento('0114564200014')[0], 'CNPJ_INVALIDO')
    def test_telefones(self):
        self.assertEqual(v.roteia_telefones('(11) 3874-7111', '(11) 97607-8975'), ('1138747111', '11976078975', []))
        # trocados de coluna: o roteamento corrige pelo formato
        self.assertEqual(v.roteia_telefones('11976078975', '1138747111'), ('1138747111', '11976078975', []))
        self.assertEqual(v.roteia_telefones('0800 123 4567', ''), ('08001234567', '', []))
        fone, cel, sobra = v.roteia_telefones('11 3874-711', '')
        self.assertEqual((fone, cel), ('', '')); self.assertEqual(sobra, ['11 3874-711'])
    def test_offline(self):
        A, B, C = v.processa([linha(), linha(CNPJ='01.145.642/0001-42'), linha(Email='', TelefoneFixo=''), linha(Sobrenome=''),
                              linha(Temperatura='50'), linha(Cluster=''), linha(CNPJ='01.655.910/0001-75', TelefoneFixo='11976078975'),
                              linha(CNPJ='02.954.620/0001-95', Celular='1138747111')], [], [], [], online=False)
        self.assertEqual(len(A), 0)
        self.assertTrue(B[0]['Motivo'].startswith('FORMATO OK'))
        self.assertIn('digito verificador', B[1]['Motivo'])
        self.assertIn('sem telefone e sem e-mail', B[2]['Motivo'])
        self.assertIn('Sobrenome do contato vazio', B[3]['Motivo'])
        self.assertIn('Temperatura fora da lista: 50', B[4]['Motivo'])
        self.assertIn('Time/Cluster vazio', B[5]['Motivo'])
        self.assertTrue(B[6]['Motivo'].startswith('FORMATO OK'))  # celular na coluna de fixo: roteado, nao retido
        self.assertIn('telefone nao aproveitado', B[7]['Motivo'])     # dois fixos na mesma linha: o segundo e retido
    def test_duplicado_no_arquivo(self):
        A, B, C = v.processa([linha(), linha(CNPJ='01145642000141')], [], [], USERS, online=True)
        self.assertEqual(len(A), 1); self.assertIn('duplicado no arquivo (linha 2)', B[0]['Motivo'])
    def test_online(self):
        leads = [{'Id': '00Q1', 'DocumentNumber__c': '01.655.910/0001-75', 'Status': 'New', 'OwnerId': '005A'}]
        accounts = [{'Id': '001X', 'Name': 'TBNET', 'DocumentNumber__c': '02954620000195', 'OwnerId': '005C'}]
        rows = [linha(Celular='11 97607-8975', ProdutoInteresse='Fibra'), linha(CNPJ='01655910000175'), linha(CNPJ='02.954.620/0001-95'),
                linha(CNPJ='03.232.670/0001-21', Proprietario='Joao Silva'), linha(CNPJ='03.254.681/0001-02', Proprietario='Maria Souza'),
                linha(CNPJ='03.971.465/0001-88', Proprietario='Vitoria da Costa Hyppolito', SDR='Joao Silva')]
        A, B, C = v.processa(rows, leads, accounts, USERS, online=True)
        self.assertEqual([a['DocumentNumber__c'] for a in A], ['01.145.642/0001-41'])
        a = A[0]
        self.assertEqual((a['OwnerId'], a['SDR__c'], a['Status'], a['RecordTypeId']), ('005A', '005A', v.STATUS_NOVO, v.RECORDTYPE_LEAD_B2B))
        self.assertEqual((a['Phone'], a['MobilePhone'], a['StateCode'], a['CountryCode']), ('1138747111', '11976078975', 'SP', 'BR'))
        self.assertEqual((a['Stage__c'], a['Segment__c'], a['ClusterManual__c'], a['ProductInterestNew__c']), ('10', 'B2W - Wholesale', 'ALT/GGNET', 'Fibra'))
        self.assertEqual(list(a.keys()), v.SF_FIELDS)
        self.assertEqual(len(C), 1); self.assertEqual(C[0]['AccountId'], '001X')
        motivos = [b['Motivo'] for b in B]
        self.assertTrue(any('Lead ja existe na org: 00Q1' in m for m in motivos))
        self.assertTrue(any('proprietario inativo' in m for m in motivos))
        self.assertTrue(any('proprietario ambiguo' in m for m in motivos))
        self.assertTrue(any('SDR inativo' in m for m in motivos))

if __name__ == '__main__':
    unittest.main(verbosity=1)
