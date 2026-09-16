# 16/09/2026 - Alteracao do Gerente da conta para o time do Marcelo: template + validador + script 37

Pedido do Diego: template "como o de leads" para alterar o Gerente da conta, com a regra da casa: nao duplicar dados,
sempre consultar antes de atualizar ou criar. Duas planilhas do comercial:
1. Oportunidade_para_Aprovacao (6 oportunidades, fase "Aprovacao comercial", urgentes): JMD HAMOA (Rafael Mendonca),
   HOREBE, PATRUS, MANFRIM/SPECIAL DOG, MILPLAN e mais uma (Wills Kenio). PATRUS e HOREBE ja apareceram no script 26 de 15/09
   (gerente da opp diferente do gerente da conta).
2. Contas_Alterar_Gerente (1.512 contas, todas com CNPJ mascarado, 0 duplicados): donos = 9 GRs (Lucas Pacheco 384,
   Wills Kenio 274, Erica Rosena 265, Euler Rosa 167, Flavio Sandro 143, Gabriela Medeiros 104, Rafael Mendonca 89,
   Kaio Mathias 49, Nicolly Rodrigues 37); gerente atual = Eduardo Alessandro Afonso 847, Matheus Nardoni 564,
   Rafael Mendonca 37, em branco 33, Paul Raad 11, Euler 10, Marcelo Barbosa De Carvalho 8, Daniela Abreu 2;
   clusters SEMPRE 1.257, AVATO 254, BLINK 1. Todas devem passar a ter o Marcelo como gerente.
   Achados: 1 CNPJ com DV invalido (09.569.214/0001-31, tratado como aviso: se a org tiver o mesmo valor, atualiza pelo Id);
   5 filiais do Banco do Brasil com raiz 00.000.000 (validas); 65 nomes de conta repetidos com CNPJ diferente (filiais).
   Nome do gerente alvo assumido: "Marcelo Barbosa De Carvalho" (ja e gerente de 8 contas na planilha). Confirmar.

E o mesmo campo dos chamados de 15 e 16/09: Account.AccountManager__c e Opportunity.ManagerAccount__c (aprovador da etapa
"Aprovacao - Comercial"). Dono nunca muda.

## Entregue
- tools/gerente_conta/gerar_template_gerente.py -> Template_Alterar_Gerente_Conta.xlsx (abas Contas, Oportunidades, Listas,
  Instrucoes; conferencia por formula: CNPJ, duplicado, obrigatorios, LINHA) e Alterar_Gerente_Marcelo.xlsx (1.512 + 6 linhas).
- tools/gerente_conta/validar_gerente.py: gera as 3 consultas (contas por CNPJ nos dois formatos, oportunidades por nome,
  usuarios) e, com os exports, casa cada linha com exatamente um registro. Saidas por Id: A_contas_update.csv (flag
  PrecisaClusterExecutor), A_opps_update.csv (flags PrecisaBypass e EmAprovacao), B_retidos, C_sem_mudanca. 3 testes OK.
  Offline na planilha real: 1.518 linhas com formato OK (1 aviso de DV).
- scripts/37_AlterarGerente_Planilha_1609.apex: le os dois CSVs do ContentVersion, duas fases, janelas de 500; cluster
  temporario no executor (script 31), Bypass__c junto com a troca nas fases bloqueadas (script 31), reatribuicao do item
  "Aprovacao - Comercial" nas travadas em aprovacao (script 27). Ainda nao executado.

## Proximos passos
1. Confirmar o nome completo do Marcelo e rodar as consultas na sandbox/prod.
2. Passada online do validador; devolver B_retidos ao comercial.
3. Script 37 fase 1 e fase 2, comecando pelas 6 oportunidades urgentes (arquivo A_opps): as que estao em aprovacao terao
   o item reatribuido ao Marcelo na hora; o campo ManagerAccount__c dessas fica para depois da aprovacao (regra de
   validacao de 15/09 barra ate com unlock).
4. Contas em 4 janelas de 500; conferir o DEPOIS e registrar aqui.
