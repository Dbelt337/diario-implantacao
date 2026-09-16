#!/usr/bin/env python3
"""Testes do validador de gerente (python3 test_validar_gerente.py): casamento por CNPJ e por conta+nome, duplicidade
na org e no arquivo, nome divergente, gerente nao resolvido, sem mudanca, flags de cluster/bypass/aprovacao."""
import unittest
import validar_gerente as v

USERS = [{'Id': '005M', 'Name': 'Marcelo Barbosa De Carvalho', 'Email': 'marcelo@btp.com.br', 'IsActive': True},
         {'Id': '005X', 'Name': 'Fulano Inativo', 'Email': 'fulano@btp.com.br', 'IsActive': False}]
ACC = [{'Id': '001A', 'Name': 'DIOCESE DE SETE LAGOAS', 'DocumentNumber__c': '16.939.019/0008-04', 'OwnerId': '005E', 'AccountManager__c': '005N', 'ClusterManual__c': '', 'RecordType': {'DeveloperName': 'LegalEntity_B2B'}},
       {'Id': '001B', 'Name': 'FORNAC FUNDICAO', 'DocumentNumber__c': '01040520000271', 'OwnerId': '005E', 'AccountManager__c': '005M', 'ClusterManual__c': 'SEMPRE', 'RecordType': {'DeveloperName': 'LegalEntity_B2B'}},
       {'Id': '001C', 'Name': 'DUPLICADA 1', 'DocumentNumber__c': '22.753.982/0005-59', 'OwnerId': '005E', 'AccountManager__c': '', 'ClusterManual__c': 'SEMPRE', 'RecordType': {'DeveloperName': 'LegalEntity_B2B'}},
       {'Id': '001D', 'Name': 'DUPLICADA 2', 'DocumentNumber__c': '22753982000559', 'OwnerId': '005E', 'AccountManager__c': '', 'ClusterManual__c': 'SEMPRE', 'RecordType': {'DeveloperName': 'LegalEntity_B2B'}},
       {'Id': '001E', 'Name': 'MINERACAO USIMINAS SA', 'DocumentNumber__c': '12.056.613/0004-72', 'OwnerId': '005E', 'AccountManager__c': '005N', 'ClusterManual__c': 'SEMPRE', 'RecordType': {'DeveloperName': 'LegalEntity_B2B'}},
       {'Id': '001F', 'Name': 'ADVANTA', 'DocumentNumber__c': '03.232.670/0001-21', 'OwnerId': '005E', 'AccountManager__c': '005N', 'ClusterManual__c': 'SEMPRE', 'RecordType': {'DeveloperName': 'LegalEntity_B2B'}}]
OPP = [{'Id': '006A', 'Name': 'PATRUS_Sao Jose', 'Account': {'Name': 'PATRUS TRANSPORTES LTDA'}, 'StageName': 'Aprovação comercial', 'IsClosed': False, 'OwnerId': '005W', 'ManagerAccount__c': '005W', 'Send4Approval__c': True},
       {'Id': '006B', 'Name': 'HOREBE_Betim', 'Account': {'Name': 'HOREBE SOLUCOES LTDA'}, 'StageName': 'Análise cliente', 'IsClosed': False, 'OwnerId': '005W', 'ManagerAccount__c': '', 'Send4Approval__c': False},
       {'Id': '006C', 'Name': 'HOREBE_Betim', 'Account': {'Name': 'HOREBE SOLUCOES LTDA'}, 'StageName': 'Fechada', 'IsClosed': True, 'OwnerId': '005W', 'ManagerAccount__c': '', 'Send4Approval__c': False},
       {'Id': '006D', 'Name': 'MILPLAN_SDC', 'Account': {'Name': 'MILPLAN ENGENHARIA S.A.'}, 'StageName': 'Aprovação comercial', 'IsClosed': False, 'OwnerId': '005W', 'ManagerAccount__c': '005M', 'Send4Approval__c': True}]

def conta(cnpj, nome='', ger='Marcelo Barbosa De Carvalho', linha=2):
    return dict(CNPJ=cnpj, NomeConta=nome, ProprietarioAtual='', GerenteAtual='', NovoGerente=ger, Obs='', Linha=linha)
def opp(conta_, nome, ger='Marcelo Barbosa De Carvalho', linha=2):
    return dict(NomeConta=conta_, NomeOpp=nome, ProprietarioOpp='', Fase='', NovoGerente=ger, Obs='', Linha=linha)

class T(unittest.TestCase):
    def test_contas(self):
        contas = [conta('16.939.019/0008-04', 'DIOCESE DE SETE LAGOAS', linha=2), conta('01.040.520/0002-71', linha=3), conta('22.753.982/0005-59', linha=4),
                  conta('12.056.613/0004-72', 'OUTRO NOME', linha=5), conta('99.999.999/0001-99', linha=6), conta('16939019000804', linha=7),
                  conta('03.232.670/0001-21', 'ADVANTA', ger='Fulano Inativo', linha=8)]
        A_c, A_o, B, C = v.processa(contas, [], ACC, OPP, USERS, online=True)
        self.assertEqual([a['Id'] for a in A_c], ['001A']); self.assertEqual(A_c[0]['AccountManager__c'], '005M'); self.assertEqual(A_c[0]['PrecisaClusterExecutor'], 'SIM')
        self.assertEqual([c['Id'] for c in C], ['001B'])
        mot = {b['Linha']: b['Motivo'] for b in B}
        self.assertIn('2 contas com este CNPJ', mot[4]); self.assertIn('nome divergente', mot[5]); self.assertIn('nao encontrada', mot[6])
        self.assertIn('duplicado no arquivo (linha 2)', mot[7]); self.assertIn('inativo', mot[8])
    def test_opps(self):
        opps = [opp('PATRUS TRANSPORTES LTDA', 'PATRUS_Sao Jose', linha=2), opp('HOREBE SOLUCOES LTDA', 'HOREBE_Betim', linha=3),
                opp('MILPLAN ENGENHARIA S.A.', 'MILPLAN_SDC', linha=4), opp('JMD', 'Projeto X', linha=5)]
        A_c, A_o, B, C = v.processa([], opps, ACC, OPP, USERS, online=True)
        self.assertEqual([a['Id'] for a in A_o], ['006A', '006B'])
        self.assertTrue(A_o[0]['EmAprovacao'].startswith('SIM')); self.assertEqual(A_o[0]['PrecisaBypass'], '')
        self.assertEqual(A_o[1]['PrecisaBypass'], 'SIM'); self.assertEqual(A_o[1]['EmAprovacao'], '')
        self.assertEqual([c['Id'] for c in C], ['006D'])
        self.assertEqual(len(B), 1); self.assertIn('nao encontrada', B[0]['Motivo'])
    def test_offline(self):
        A_c, A_o, B, C = v.processa([conta('16.939.019/0008-04'), conta('123.456.789-09')], [opp('X', '')], [], [], [], online=False)
        self.assertEqual(len(A_c) + len(A_o), 0)
        self.assertTrue(B[0]['Motivo'].startswith('FORMATO OK')); self.assertIn('CPF', B[1]['Motivo']); self.assertIn('oportunidade vazio', B[2]['Motivo'])

if __name__ == '__main__':
    unittest.main(verbosity=1)
