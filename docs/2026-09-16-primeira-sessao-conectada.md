# 16/09/2026 - Primeira sessao conectada na org (btp-prod): fila da secao 8

Diego abriu o Claude Code no VS Code com o repositorio e disse "conectado, org btp-prod". Segui a fila de
docs/como-conectar-claude-na-org.md, secao 8. Tudo aqui foi LEITURA na producao; nenhum registro foi alterado.
Licoes de ambiente (sf no Git Bash, HTTP 431, Python) estao na secao 9 do mesmo doc.

## 1. Conexao

`sf org display -o btp-prod`: Connected, usuario diegomoraes.t@brasiltecpar.com.br, org 00DHu00000FcxIgMAJ
(https://prod-brasiltecpar.my.salesforce.com), API 67.0. `sf org list`: so a prod esta valida; `uat` e `galcorr` com token
expirado; nao existe `btp-preprod`. O ensaio em sandbox pedido na secao 7 depende de um `sf org login web` novo.

## 2. Gerente da conta do Marcelo: passada online do validador (na prod, leitura)

Planilhas do comercial estavam em Downloads (Contas_Alterar_Gerente.xlsx e Oportunidade_para_Aprovacao.xlsx, de 16/07;
as copias "(1)" sao identicas). Fluxo do README de tools/gerente_conta:
- `gerar_template_gerente.py` -> Alterar_Gerente_Marcelo.xlsx: 1.512 contas + 6 oportunidades.
- Passada offline: 1.518 linhas com formato OK (1 aviso de DV, linha 270).
- Consultas de `saida/consultas.soql` rodadas na prod: contas em 13 lotes de 250 CNPJs (`exportar_contas_lotes.js`, novo,
  por causa do HTTP 431): 1.517 registros para 1.512 CNPJs; oportunidades: 6; usuarios: 1 (Marcelo Barbosa De Carvalho,
  005V200000N5I0fIAF, ativo, cluster SEMPRE; nome confirmado).
- Passada online (`relatorio.txt`):

| Saida | Qtde | Detalhe |
|---|---|---|
| A) contas a atualizar | 22 | 10 sem ClusterManual__c (precisam de cluster no executor); todas LegalEntity_B2B; 9 SEMPRE, 3 AVATO |
| A) oportunidades a atualizar | 4 | todas em "Aprovacao comercial" com Send4Approval__c = true: reatribuir o item, campo depois |
| B) retidas | 90 | 84 nome divergente, 5 CNPJ com 2 contas na org, 1 oportunidade nao encontrada |
| C) sem mudanca | 1.402 | ja estao com o Marcelo |

**Achado principal: a carga ja foi feita em grande parte.** Na org o Marcelo e gerente de 1.602 contas B2B PJ, e 1.488 das
1.517 contas exportadas ja estao com ele. As planilhas sao de 16/07; alguem aplicou a troca entre essa data e hoje (nao foi
por script do diario). Sobram 22 contas do arquivo A, mais as que se escondem nas retidas:
- **84 "nome divergente"**: 83 ja estao com o Marcelo; a divergencia e acento corrompido na planilha ("Ã?" no lugar de C, A,
  E) ou "SA" x "S.A.". Nao precisam voltar ao comercial. A unica pendente e a linha 345: planilha "PROCURADORIA GERAL DE
  JUSTICA" x org "PROCURADORIA GERAL DE JUSTICA DE MINAS GERAIS" (001V200000loWWaIAM, gerente atual 005V200000JWLWDIA5,
  cluster SEMPRE). E a mesma entidade; entra na lista se o Diego confirmar.
- **5 CNPJs duplicados** (SITELBRA, LINX, RODORRISO, GALI, S R DE MATOS): em cada par ha uma conta B2B (LegalEntity_B2B, 4
  delas ja com o Marcelo) e uma conta LegalEntity/Individual sem gerente, todas do mesmo dono 005V200000JhDNFIA3 (parece
  carga de integracao). Duplicidade e chamado a parte; para o gerente so falta SITELBRA B2B (001V200000log6rIAA, gerente
  005V200000JWLZRIA5).
- **1 oportunidade nao encontrada**: planilha "MILPLAN_SDC" x org "MILPLAN_SDC_Business" (006V200000w46ILIAY, "Aguardando
  instalacao", gerente Eduardo Alessandro Afonso). Fase sem trava de edicao; se for a mesma, e um update simples.
- As 4 oportunidades do arquivo A: Projeto Toda Rede JMD (Paul Raad -> Marcelo), HOREBE_Conectividade_Betim/MG (Eduardo ->
  Marcelo), PATRUS_Sao Jose dos Pinhais/PR (Rafael Mendonca -> Marcelo), COL.BATISTA_Conectividade Rede (Eduardo -> Marcelo).
  SPECIAL DOG (MANFRIM) ja esta com o Marcelo.

**Script 37 fase 1 nao rodou.** Subir os CSVs A como arquivo (`sf data create file`) e o `sf apex run` do script 37 sao
escrita na prod e o modo automatico bloqueou os dois. Ficam para o "vai" do Diego (fase 1 lista, fase 2 grava). Carga
final: 22 contas (4 janelas viram 1) e 4 oportunidades; nada perto dos 1.512 previstos.

## 3. Decisao 056, 070 e 102 na Sprint 1 (script 41, fase 1)

O script 39 nao pode ser reexecutado: o script 40 v2 colocou todo o catalogo em P1 e o 39 devolveria P2/P3. Criei
`scripts/41_PuxarSprint1_056_070_102_1609.apex`, que so mexe em Sprint. Fase 1 na prod (sem DML):
- Sprint 1 - SysMap (15-26/09) tem 11 works hoje: W-000140 (P0), 051, 052, 053, 054, 055, 107, 141 (P1), 096, 097 (P2), 123 (P4).
- W-000056 QUAL-01, W-000070 EPC-10 e W-000102 CAT-TPL-01: time SysMap, P1, New, sem sprint. Os 3 entrariam; sprint iria a 14 works.
Decisao do Diego: "vai" roda o 41 com EXECUTAR = true.

## 4. Retrieve para o diario

Projeto SFDX em `org/`. Vieram Account (162 campos, 12 regras, 16 record types), Opportunity (126 campos, 18 regras, 4
record types), Lead (77 campos, 14 regras, 2 record types) e 18 flows. Resumo com as formulas e a tabela de flows em
docs/2026-09-16-regras-validacao-flows-account-opportunity-lead.md.

## Pendencias para o Diego

1. "vai" para subir os CSVs A e rodar o script 37 fase 1 e 2 na prod (22 contas + 4 opps). Se preferir ensaiar antes,
   `sf org login web --alias btp-preprod --instance-url https://test.salesforce.com`.
2. Confirmar se entram na carga: Procuradoria (linha 345), SITELBRA B2B (001V200000log6rIAA) e MILPLAN_SDC_Business.
3. Decidir 056, 070 e 102 na Sprint 1 (script 41).
4. Avisar o comercial que 1.402 contas ja estavam com o Marcelo antes desta carga.
