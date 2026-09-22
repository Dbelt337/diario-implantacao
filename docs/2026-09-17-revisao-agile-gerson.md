# 17/09/2026 - Revisao Agile: apresentacao do Gerson x org x decisoes de 16/09

Gerson reestruturou o Agile Accelerator em producao e perguntou: "Consegue validar se agora bate com o que fez?", com o PDF
"Apresentacao a Equipe - Sprints, Relatorios e KPIs no Agile Accelerator" (v1, 17/09; texto em
docs/2026-09-17-gerson-apresentacao-agile-v1.txt). Esta revisao e SOMENTE LEITURA na btp-prod, feita as 11h30 de 17/09:
consultas por arquivo em tools/agile/consultas/ (saidas JSON em tools/agile/saida/, fora do git), lixeira por Apex so com
SELECT, comparacao por tools/agile/comparar.js. Fontes do esperado: docs/2026-09-15-works-validadas-pacote-marcelo.csv,
scripts/40_Prioridade_Todas_Works_1609.apex e o briefing docs/2026-09-17-briefing-revisao-agile-gerson.md. Horarios em Brasilia.

## Resumo

- **O documento do Gerson bate com a org** em numeros, sprints (work a work), epicos, prioridades, relatorios e story points.
  Duas afirmacoes divergem: as works internas NAO tem o sufixo "-i" em lugar nenhum, e "sprint corrente 100% saudavel" so
  ficou verdade as 10h30 de hoje, com o script 43 (Diego), que deu responsavel a 133 a 137, 140 e 141.
- **A org bate com as decisoes do Diego** em time (88/5), P0 (132, 133, 134, 140), catalogo em P1, 056/070/102 fora de
  sprint e prioridade das 5 works do Gerson. **11 works tiveram a prioridade alterada pelo Gerson** em 16/09 as 19h43, junto com
  a montagem das Sprints 2 a 4 (prioridade = ordem da sprint). Duas contradizem a regra do Diego (pos-venda por ultimo):
  **123 (visao 360) em P1 na Sprint 1** e **124 (fim de degustacao) em P2 na Sprint 2**.
- Fora de sequencia (esperado por enquanto): 14 works de catalogo, 44 de B2C, 4 TEC-INT e a 132 (P0) sem sprint.
- Pendencias que o proprio Gerson listou, confirmadas: 024, 026, 028 sem epico; 132 P0 fora de sprint; 14 works em sprints
  de junho/julho. Proposta na secao D, nada executado.

## A. Documento do Gerson x org

| # | Afirmacao do documento | Org (17/09, 11h30) | Veredito |
|---|---|---|---|
| 1 | 111 works; 96 New, 10 Closed, 3 In Progress, 2 QA In Progress | 111 ativas: New 96, Closed 10, In Progress 3, QA In Progress 2. Conta as 18 internas (010 a 028) e nao conta as 24 da lixeira | CONFERE |
| 2 | 7 epicos novos da cadeia de valor B2B | 7 epicos criados pelo Gerson em 16/09 as 17h42: 1) Vender solucoes (13 works), 2) cortesia (1: 124), 3) swap (0), 4) upgrade (1: 100), 5) downgrade (1: 125), 6) refidelizacao (1: 142), 7) cancelamento e retencao (2: 099, 143) | CONFERE |
| 3 | 19 works B2B reparentadas nesses epicos | 19: 096, 097, 098, 099, 100, 101, 107, 119, 120, 122, 123, 124, 125, 140, 141, 142, 143, 144, 145. O epico antigo "B2B - Jornadas de Venda e Gestao do Ciclo de Vida do Cliente" ficou com 0 works (nao foi apagado). Epico 3) swap esta vazio | CONFERE |
| 4 | 29 em sprints 1 a 4: S1 BTP 5, S1 SysMap 11, S2 8, S3 2, S4 3; 43 com sprint (14 em Jun/Jul "Time Salesforce") | 5 + 11 + 8 + 2 + 3 = 29; 43 com sprint; 14 em Junho (12) e Julho (2) /2026-Time Salesforce; 68 sem sprint | CONFERE |
| 5 | Sprint 1 BTP = 133 (P0), 134 (P0), 135, 136, 137 (P1) | identico; epicos Integracao/CI-CD (133 a 135) e Arquitetura (136, 137) | CONFERE |
| 6 | Sprint 1 SysMap = 140 (P0), 051, 052, 053, 054, 055, 096, 097, 107, 123, 141 (P1) | identico, work a work | CONFERE |
| 7 | S2 = 098, 101, 119, 120, 122, 124, 144, 145 (P2); S3 = 100, 125 (P3); S4 = 099, 142, 143 (P4) | identico, work a work, com os epicos que o documento mostra | CONFERE |
| 8 | Prioridades mudaram em relacao ao script 40 v2: 096, 097, 123 -> P1; 098, 101, 122, 144, 145 -> P2; 124 -> P2; 100, 125 -> P3 | 11 works, todas alteradas pelo Gerson em 16/09 as 19h43 (historico do campo Priority). Detalhe na secao B | CONFERE (e decisao dele) |
| 9 | Sprint corrente 100% saudavel: toda work com responsavel, prioridade e epico | Hoje sim: 16 works das Sprints 1 com responsavel, prioridade e epico. Mas 133 a 137, 140 e 141 estavam SEM responsavel ate as 10h30 de hoje; o responsavel (Davi) foi gravado pelo script 43, a pedido do Diego, nao pelo Gerson | CONFERE desde 10h30 (script 43) |
| 10 | Works internas renomeadas com sufixo "i" (ex.: W-00028-i) e fora de sprint | Nenhuma work tem "-i" no assunto nem no nome (Name e autonumber, nao renomeavel). As internas so sao identificaveis pelo epico "Projetos Internos" (15) ou pelo time Brasil TecPar/GOVERNANCA. E 14 delas ESTAO em sprint (Jun/Jul Time Salesforce), o que a propria regra dele proibe | DIVERGE |
| 11 | Pendencias: 024/026/028 sem epico; 132 P0 fora de sprint; 14 works em sprints antigas | confirmadas as tres (secao D) | CONFERE |
| 12 | 6 relatorios + 4 KPIs na pasta "Works Agile - Projetos BTP" | Pasta criada em 11/09 pelo Gerson com 18 relatorios: 8 de programa (01. Geral - Epico x Status; 01. Programa SF - Works por Projeto e Status; 02. Por Sprint x Status; 02. Programa SF - Works por Time e Status; 03. Por Frente (Epico) + Pontos; 03. Story Points por Projeto; 04. Internos - Works por Status; 04. Por Work - Detalhe) e 10 KPIs (Programa: Novas, Em Andamento, Em Teste/QA, Em Aprovacao/Revisao, Concluidas, Com Pontos, Sem Pontos; Internos: Novas, Concluidas; Total Geral). Mais o painel "KPI Gestao de Works - Projetos BTP". O relatorio 02 foi executado hoje as 11h12 | CONFERE (ha mais do que o documento cita) |
| 13 | Story points: 7 de 111 pontuadas | 7 works com pontos: 010 (8), 011 (5), 012 (3), 013 (8), 018 (2), 020 (3), 025 (8). Todas internas do BTP; nenhuma das 93 do pacote tem pontos | CONFERE (mas 0 de 93 no programa) |
| 14 | Lixeira | 24 works apagadas (029 a 050 e 138, 139), as 6 do pacote (041 a 044, 138, 139) apagadas em 15/09 pelo Diego. Ver nota em D.5 sobre 045 a 050 | CONFERE |

Criterios de aceite (consulta 7): 73 works com criterios; 142 a 145 com 9/8/7/8, 133 a 137 com 5/4/3/4/4, 140 e 141 com 4 e 3,
070 com 3, 096 a 101 com 2, 087 com 3. Igual ao esperado. Details, Tag (Salesforce) e epico preenchidos nas 93 do pacote.

## B. Org x decisoes do Diego (16/09)

| Decisao | Org | Veredito |
|---|---|---|
| Time: 88 SysMap, 5 Brasil TecPar (133 a 137) | 88 SysMap, 22 Brasil TecPar (5 do pacote + 17 internas), 1 GOVERNANCA (021) | CONFERE |
| P0 = 132, 133, 134, 140 | exatamente essas 4 | CONFERE |
| Catalogo em P1 (EPC, CAT, QUAL) | 19 works de catalogo em P1: 051 a 055 (Sprint 1) e 056, 070, 102, 103, 104, 108, 111 a 114, 117, 121, 127, 128 (backlog) | CONFERE |
| 056, 070, 102 fora de sprint (proxima onda; script 41 nao rodou) | as 3 no backlog, P1 | CONFERE |
| 5 works do Gerson (133 a 137) intocadas | prioridade igual ao script 40 (P0, P0, P1, P1, P1); responsavel Davi gravado hoje pelo script 43 por decisao do Diego; nada mais mudou | CONFERE |
| Responsavel Davi nas US da SysMap; 140, 141 e 133 a 137 sem responsavel | Davi em todas as 93 desde hoje 10h30 (script 43) | CONFERE (decisao de hoje substitui a de 15/09) |
| Status New nas 93 | New nas 93 | CONFERE |

Works cuja Priority difere do script 40 v2 (todas alteradas pelo Gerson; historico do campo: 10h09 primeira passada dele,
17h23 script 40 v2 do Diego, 19h43 Gerson de novo, junto com a distribuicao nas Sprints 2 a 4 criadas as 17h42):

| Work | Historia | Script 40 v2 | Org | Sprint | Quem / quando | Leitura |
|---|---|---|---|---|---|---|
| W-000096 | B2B-01 escalonamento de leads | P2 | P1 | S1 SysMap | Gerson, 16/09 19h43 | decisao do Gerson (repriorizou pela sprint); lead, coerente com P1/P2 |
| W-000097 | B2B-02 enderecamento e viabilidade | P2 | P1 | S1 SysMap | Gerson, 16/09 19h43 | decisao do Gerson; lead/opp |
| W-000123 | B2B-10 visao 360 de contratos e ativos | P4 | P1 | S1 SysMap | Gerson, 16/09 19h43 | **CONTRADIZ a regra: pos-venda em P1 na Sprint 1** |
| W-000098 | B2B-03 cotacao multi-site | P3 | P2 | S2 SysMap | Gerson, 16/09 19h43 | decisao do Gerson; cotacao subiu um nivel |
| W-000101 | B2B-06 auditoria de vendas / credito | P3 | P2 | S2 SysMap | Gerson, 16/09 19h43 | decisao do Gerson |
| W-000122 | B2B-09 contrato: signatario, NPS | P3 | P2 | S2 SysMap | Gerson, 16/09 19h43 | decisao do Gerson |
| W-000144 | B2B-15 condicoes de faturamento | P3 | P2 | S2 SysMap | Gerson, 16/09 19h43 | decisao do Gerson |
| W-000145 | B2B-16 cadencia de assinatura | P3 | P2 | S2 SysMap | Gerson, 16/09 19h43 | decisao do Gerson |
| W-000124 | B2B-11 fim de degustacao (Try & Buy) | P4 | P2 | S2 SysMap | Gerson, 16/09 19h43 | **CONTRADIZ a regra: pos-venda em P2 na Sprint 2** |
| W-000100 | B2B-05 upgrade/swap | P4 | P3 | S3 SysMap | Gerson, 16/09 19h43 | decisao do Gerson; MACD subiu um nivel, mas segue depois de cotacao/contrato |
| W-000125 | B2B-12 downgrade | P4 | P3 | S3 SysMap | Gerson, 16/09 19h43 | idem |

Sprint: 142, 143 (P4) sairam da Sprint 1 para a Sprint 4 e 144, 145 (P3 -> P2) para a Sprint 2; 096, 097, 107, 123 entraram
na Sprint 1 (Gerson, 16/09 17h44 e 19h43). O campo Sprint nao tem historico; a atribuicao vem de LastModifiedBy e dos horarios
das Sprints 2 a 4. A decisao de 16/09 ("142 a 145 na Sprint 1 com P3/P4") foi substituida por essa; nenhum script do diario
tocou em Sprint dessas works.

## C. Fora de sequencia (sem sprint, esperado por enquanto)

- **Catalogo alem da Sprint 1 (14, todas P1)**: 056 QUAL-01, 070 EPC-10, 102 CAT-TPL-01, 103 CAT-MIG-01, 104 CAT-TAG-01,
  108 CAT-PRC-01, 111 CAT-FAM-01, 112 CAT-CHD-01, 113 CAT-API-01, 114 CAT-ZON-01, 117 CAT-ACC-01, 121 CAT-CPX-01, 127 CAT-EQP-01,
  128 CAT-RET-01. P1 sem sprint e a Onda 2 do catalogo; o Gerson montou as Sprints 2 a 4 so com B2B.
- **Todo o B2C (44 sem sprint, de 51 no epico)**: P1 = 085, 086, 087, 090, 092; P2 = 057, 058, 059, 060, 062, 064, 066, 067,
  071, 072, 073, 074, 083, 091; P3 = 063, 065, 068, 069, 075, 076, 077, 078, 080, 081, 082, 084, 088, 089, 093, 094, 106, 115,
  118; P4 = 061, 079, 095, 109, 116, 129 e 126.
- **TEC-INT sem sprint (4, P1)**: 105, 110, 130, 131 (canal de eventos, SVA, SAP, TMF641).
- **W-000132 TEC-DEV-01 (esteira CI/CD, P0) sem sprint**: e par da 133 (BTP, Sprint 1) e da 025 (BTP, em andamento).

## D. Pendencias listadas pelo Gerson, confirmadas na org, com proposta (nada executado)

| # | Pendencia | Org | Proposta |
|---|---|---|---|
| 1 | 024, 026, 028 sem epico | 024 e 026 fechadas; 028 (carga de contas, In Progress, P4) | Epico "Projetos Internos" nas 3 (as fechadas tambem, para o relatorio 04 Internos fechar). |
| 2 | 132 (CI/CD) P0 fora de sprint | P0, backlog, time SysMap, responsavel Davi | Diego decide: entra na Sprint 1 SysMap (junto com a 133 do BTP) ou na Sprint 2. Manter P0 fora de sprint contradiz a regra do proprio Gerson. |
| 3 | 14 works em sprints Jun/Jul "Time Salesforce" | 12 em Junho (8 Closed, 2 QA, 2 In Progress) e 2 em Julho (New). As 8 fechadas sao historico legitimo. As 6 abertas (010, 011, 018, 025 em andamento; 019, 023 New) violam a regra "nada de work presa em sprint antiga" | Fechadas: deixar como historico. Abertas: 010, 011, 018, 025 para a Sprint 1 - Brasil TecPar (ja tem P4 e responsavel); 019 e 023 para o backlog ou fechar. Script 45, duas fases, so com o "vai". |
| 4 | Internas "-i" | nao existe o sufixo; 14 internas em sprint (ver 3) | Se o Gerson quiser o marcador, e no assunto (Subject), nao no Name. Alternativa sem renomear: filtrar os relatorios do programa por epico <> "Projetos Internos" ou por time. |
| 5 | Lixeira | 24 works. Nota: 045 a 050 ("Comercial - ...", apagadas em 15/09) aparecem com modificacao de hoje 10h26 pelo usuario do Diego: e o efeito colateral do script 42 (ao apagar as sprints antigas vazias, a org limpou o lookup de sprint dessas works ja apagadas, que estavam na "Sprint Catalogo"). Nenhuma work ativa foi tocada; a lixeira continua com 24. Ha tambem uma sprint "TESTE-SPRINT-DEL" na lixeira, teste de alguem em 17/09 | Nada a fazer; registrado por transparencia. |
| 6 | Epico "B2B - Jornadas de Venda..." vazio e epico 3) swap vazio | ambos com 0 works | O antigo pode ser apagado quando o Gerson confirmar; o 3) fica aguardando historia de swap (hoje o swap esta dentro da 100, upgrade/swap). |
| 7 | 10 works fechadas sem prioridade (012 a 016, 020, 022, 024, 026, 027) | fechadas, internas | Sem efeito nos KPIs de sprint; se o relatorio do Gerson exigir, P4 nelas tambem. |

## E. Rascunho de resposta ao Gerson

> Validei na org agora de manha. Bate: 111 works e os status, os 7 epicos com as 19 US B2B reparentadas, as 5 sprints
> work a work (5 + 11 + 8 + 2 + 3), as prioridades como estao no documento, os relatorios e o painel da pasta "Works Agile",
> e os 7 story points. Duas ressalvas: (1) o sufixo "-i" das internas nao esta na org, nenhuma work tem isso no assunto, e
> 14 internas seguem nas sprints de junho/julho; (2) o "100% saudavel" da sprint corrente vale a partir de hoje 10h30, quando
> gravamos o Davi como responsavel nas 7 works que estavam sem (133 a 137, 140, 141), e P4 nas 8 internas abertas.
> Sobre as prioridades que voce ajustou pela sprint: ok, so duas fogem da regra que o Diego definiu em 16/09 (pos-venda por
> ultimo): a 123 (visao 360) em P1 na Sprint 1 e a 124 (fim de degustacao) em P2 na Sprint 2. O Diego decide se ficam.
> Pendencias suas, confirmadas: 024/026/028 sem epico (sugiro "Projetos Internos"), 132 P0 fora de sprint (Sprint 1 ou 2?)
> e as 6 internas abertas em sprint antiga (010, 011, 018, 025 para a Sprint 1 BTP; 019 e 023 backlog ou fechar). As 5
> sprints vazias ja apagamos. Me diz o que confirma que eu ajusto de uma vez.

## Executado hoje antes desta validacao (com "vai" do Diego; ja constam no historico da org)

- **Script 42** (10h26): apagou as 5 sprints antigas vazias (Junho/2026-Time SysMap-3a e 4a Sem; Julho/2026-Time SysMap-1a e 2a
  Sem, com data invertida; Julho/2026-Time SysMap-3a e 4a Sem; Sprint Catalogo - 1a e 2a Semana; Sprint Catalogo - 3 e 4
  Semana). Restam 7 sprints. Efeito colateral em D.5.
- **Script 43** (10h30): responsavel Davi Israel de Abreu em 133, 134, 135, 136, 137, 140, 141 (PO Priscila De Lima ja estava).
- **Script 44** (11h27): P4 em 010, 011, 018, 019, 021, 023, 025, 028 (internas abertas sem prioridade). Zero works abertas
  sem prioridade na org.

Pendentes de decisao: 123 e 124 (prioridade), 132 (sprint), 056/070/102 (Sprint 1 ou proxima onda), epico de 024/026/028,
6 internas abertas em sprint antiga, sufixo "-i".

## Decisoes tomadas em 17/09 (delegadas pelo Diego: "pode tomar a decisao, ajusta") e script 45

Criterio: a regra do Diego de 16/09 manda na sequencia (pos-venda por ultimo); a regua de higiene do Gerson manda no resto
(prioridade = sprint, P0 em sprint, interna fora de sprint e com sufixo -i).

| Pendencia | Decisao |
|---|---|
| 123 (visao 360) P1 na Sprint 1; 124 (fim de degustacao) P2 na Sprint 2 | Pos-venda: as duas vao para a Sprint 4 - SysMap com P4. Sprint 1 fica com 10 + 132; Sprint 2 com 7 + 3 do catalogo; Sprint 4 com 5. |
| 132 (CI/CD) P0 fora de sprint | Entra na Sprint 1 - SysMap, par da 133 (BTP). |
| 056, 070, 102 (catalogo P1) | Proxima onda = Sprint 2 - SysMap; prioridade fica P1. |
| 024, 026, 028 sem epico | Epico "Projetos Internos". |
| 6 internas abertas em sprint de junho/julho | Saem para o backlog (regra do Gerson: interna nao fica em sprint). As 8 fechadas ficam como historico. |
| Sufixo "-i" | Assunto das 18 internas (010 a 028) recebe " -i", como a regua do Gerson prevê. |

Script 45 (scripts/45_AjustesRevisaoAgile_1709.apex), fase 1 na prod: 24 works a alterar, exatamente as acima, nenhuma trava.
**Fase 2 nao rodou: o modo automatico do Claude Code bloqueou o `sf apex run` com update.** Para gravar, no terminal:

```powershell
cd C:\Users\DIego\Documents\diario-implantacao
(Get-Content scripts\45_AjustesRevisaoAgile_1709.apex) -replace '^Boolean EXECUTAR = false;','Boolean EXECUTAR = true;' | Set-Content -Encoding utf8 $env:TEMP\45_exec.apex
sf apex run -o btp-prod --file $env:TEMP\45_exec.apex | Select-String "AJ45"
```

Esperado no DEPOIS: Sprint 1 SysMap 11 (10 + 132), Sprint 1 BTP 5, Sprint 2 SysMap 10, Sprint 3 SysMap 2, Sprint 4 SysMap 5,
Junho/2026-Time Salesforce 8 (so fechadas), Julho/2026-Time Salesforce 0; P0 fora de sprint 0; sem epico 0; internas abertas em
sprint 0; internas sem -i 0. Avisar o Gerson: a Sprint 1 dele muda (sai 123, entra 132) e a Sprint 2 tambem (sai 124, entram
056, 070, 102); o documento v1 precisa de uma v2.

### Script 45 executado (17/09, 12h15, pelo Diego no terminal)

24 works alteradas, sem travas. DEPOIS: Sprint 1 - SysMap 11 (051 a 055, 096, 097, 107, 132, 140, 141), Sprint 1 - Brasil
TecPar 5, Sprint 2 - SysMap 10 (056, 070, 098, 101, 102, 119, 120, 122, 144, 145), Sprint 3 - SysMap 2, Sprint 4 - SysMap 5
(099, 123, 124, 142, 143), Junho/2026-Time Salesforce 8 (so fechadas), Julho/2026-Time Salesforce 0. P0 fora de sprint: 0.
Sem epico: 0. Internas abertas em sprint: 0. Internas sem "-i": 0. Igual ao esperado.

Estado final do Agile em 17/09: 111 works; 33 em sprints 1 a 4 (5 + 11 + 10 + 2 + 5); 8 fechadas na sprint historica de junho;
70 no backlog (catalogo Onda 2: 103, 104, 108, 111 a 114, 117, 121, 127, 128; B2C 44; TEC-INT 4; internas abertas 8; 126).
Todas as works abertas com prioridade, epico, time e responsavel. Sprints vazias apagadas. Pendente: Gerson gerar a v2 do
documento (Sprint 1 sai 123 e entra 132; Sprint 2 sai 124 e entram 056, 070, 102; Sprint 4 recebe 123 e 124; internas com "-i"
e fora de sprint) e atualizar as colunas Sprint/Prioridade do CSV do pacote.

## 22/09: painel "KPI Gestao de Works - Projetos BTP" (Gerson) x works internas

Pedido do Gerson (22/09, 10h): tirar do painel as internas que nao sao do projeto Salesforce e conferir se todas as works
estao la. Regra dada por ele: "todas que comecam com US" sao do projeto.

- Todas as works estao no painel: 111 na org = 93 do programa (epico diferente de "Projetos Internos") + 18 internas.
- O proprio Gerson ja tirou os blocos "Internos" e "Total geral" do painel hoje as 10h19 (metadado baixado nao os tem
  mais). Dos 12 relatorios que alimentam o painel, 11 ja excluem o epico "Projetos Internos"; o "02. Por Sprint x Status" nao
  tinha o filtro (hoje sem efeito, nenhuma interna esta em sprint) e recebeu o mesmo filtro (pacote `org/agile-dash`).
- Nenhuma das 18 internas comeca com "US": todas ficam fora do painel. Mas 8 works do PROGRAMA tambem nao comecam com "US":
  W-000070 (EPC-10 catalogo), W-000133 a W-000137 (Sprint 1 Brasil TecPar: CI/CD, ambientes, MuleSoft, arquitetura) e
  W-000140/141 (B2B integracao e historias). Ficam no painel ate o Gerson dizer o contrario; se a regra "US" for literal,
  o filtro passa a ser Assunto comeca com "US" em todos os relatorios.
- A tela do Gerson mostrava dados "a partir de 21/09 20:01": o painel precisa de "Atualizar" para refletir a edicao.
