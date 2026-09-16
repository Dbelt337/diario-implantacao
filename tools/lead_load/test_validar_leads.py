#!/usr/bin/env python3
"""Testes do validador (python3 test_validar_leads.py). Cobre DV, CPF, obrigatorios, duplicidade no arquivo,
cruzamento com Lead/Conta existentes e resolucao de proprietario."""
import unittest
import validar_leads as v

def linha(**kw):
    base = dict(SDR='Vitoria', Proprietario='vitoria@btp.com.br', Origem='Listas GRs ALT', CNPJ='01.145.642/0001-41', RazaoSocial='Phonoway Ltda',
                NomeFantasia='', Nome='Jeferson', Sobrenome='Castelucci', Cargo='', Telefone1='(11) 3874-7111', Telefone2='', Email='a@b.com.br',
                Cidade='', UF='', Observacoes='')
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
    def test_offline(self):
        A, B, C = v.processa([linha(), linha(CNPJ='01.145.642/0001-42'), linha(Email='', Telefone1=''), linha(Sobrenome='')], [], [], [], online=False)
        self.assertEqual(len(A), 0)
        self.assertTrue(B[0]['Motivo'].startswith('FORMATO OK'))
        self.assertIn('digito verificador', B[1]['Motivo'])
        self.assertIn('sem telefone e sem e-mail', B[2]['Motivo'])
        self.assertIn('Sobrenome do contato vazio', B[3]['Motivo'])
    def test_duplicado_no_arquivo(self):
        A, B, C = v.processa([linha(), linha(CNPJ='01145642000141')], [], [], USERS, online=True)
        self.assertEqual(len(A), 1); self.assertIn('duplicado no arquivo (linha 2)', B[0]['Motivo'])
    def test_online(self):
        leads = [{'Id': '00Q1', 'DocumentNumber__c': '01.655.910/0001-75', 'Status': 'Novo', 'OwnerId': '005A'}]
        accounts = [{'Id': '001X', 'Name': 'TBNET', 'DocumentNumber__c': '02954620000195', 'OwnerId': '005C'}]
        rows = [linha(), linha(CNPJ='01655910000175'), linha(CNPJ='02.954.620/0001-95'),
                linha(CNPJ='03.232.670/0001-21', Proprietario='Joao Silva'), linha(CNPJ='03.254.681/0001-02', Proprietario='Maria Souza'),
                linha(CNPJ='03.971.465/0001-88', Proprietario='Vitoria da Costa Hyppolito')]
        A, B, C = v.processa(rows, leads, accounts, USERS, online=True)
        self.assertEqual([a['DocumentNumber__c'] for a in A], ['01.145.642/0001-41', '03.971.465/0001-88'])
        self.assertEqual(A[0]['OwnerId'], '005A'); self.assertEqual(A[1]['OwnerId'], '005A'); self.assertEqual(A[0]['Status'], v.STATUS_NOVO)
        self.assertEqual(len(C), 1); self.assertEqual(C[0]['AccountId'], '001X')
        motivos = [b['Motivo'] for b in B]
        self.assertTrue(any('Lead ja existe na org: 00Q1' in m for m in motivos))
        self.assertTrue(any('proprietario inativo' in m for m in motivos))
        self.assertTrue(any('proprietario ambiguo' in m for m in motivos))

if __name__ == '__main__':
    unittest.main(verbosity=1)
