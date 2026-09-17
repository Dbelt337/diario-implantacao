# 17/09/2026 - Revisao das sprints e works do Agile Accelerator (pedido do Gerson)

Pedido do Gerson de manha: "revisar as sprints e works que estao la para ver se esta tudo certinho". Auditoria SOMENTE
LEITURA na btp-prod (consultas por arquivo, Apex sem DML para a lixeira), cruzando com docs/2026-09-15-works-validadas-pacote-marcelo.csv
e as decisoes de 16/09 (briefing docs/2026-09-17-briefing-revisao-agile-gerson.md). Nada foi gravado. Horarios em Brasilia.

## Resumo

A org esta consistente, mas nao com o CSV: **o Gerson replanejou as sprints na noite de 16/09** (17:42 a 19:43), depois do
script 40 v2 (17:23). Ele criou as Sprints 2, 3 e 4 da SysMap, distribuiu as 16 US B2B (096 a 101, 119, 120, 122 a 125,
142 a 145) por elas e ajustou a prioridade para casar com a sprint (Sprint 1 = P0/P1, Sprint 2 = P2, Sprint 3 = P3,
Sprint 4 = P4). O campo Sprint nao tem rastreamento de historico, mas LastModifiedBy das 8 works da divergencia conhecida e o
Gerson, e os scripts do diario que rodaram depois (38, 39, 40 v2, como Diego) nao tocam em Sprint dessas works. E replanejamento
consciente, nao erro: **a proposta e aceitar o plano do Gerson e atualizar o CSV**, e nao reverter.

O que de fato falta na org: 7 works em sprint corrente sem responsavel, 8 works antigas do BTP sem prioridade (6 presas em
sprints de junho/julho), 1 sem epico, 1 P0 fora de sprint e 5 sprints antigas vazias ou com data invertida.

## A. Divergencias em relacao ao CSV do pacote (93 works)

Conferido work a work: time, sprint, prioridade, responsavel, status. Time: 88 SysMap + 5 Brasil TecPar, igual ao CSV.
Status: New nas 93. Responsavel: igual ao CSV (Davi nas US da SysMap; 140, 141 e 133 a 137 sem responsavel, decisao de 15/09).
Tag: Salesforce nas 88 da SysMap. Nenhuma work em sprint de outro time. As divergencias estao todas em Sprint e Prioridade:

| Work | Campo | CSV (15-16/09) | Org hoje | Quem | Quando |
|---|---|---|---|---|---|
| W-000096 | Sprint / Priority | backlog / P2 | Sprint 1 SysMap / P1 | Gerson | 16/09 19:43 |
| W-000097 | Sprint / Priority | backlog / P2 | Sprint 1 SysMap / P1 | Gerson | 16/09 19:43 |
| W-000107 | Sprint | backlog | Sprint 1 SysMap (P1, igual) | Gerson | 16/09 17:44 |
| W-000123 | Sprint / Priority | backlog / P4 | Sprint 1 SysMap / P1 | Gerson | 16/09 19:43 |
| W-000142 | Sprint | Sprint 1 SysMap (P4) | Sprint 4 SysMap (P4, igual) | Gerson | 16/09 17:44 |
| W-000143 | Sprint | Sprint 1 SysMap (P4) | Sprint 4 SysMap (P4, igual) | Gerson | 16/09 17:44 |
| W-000144 | Sprint / Priority | Sprint 1 SysMap / P3 | Sprint 2 SysMap / P2 | Gerson | 16/09 19:43 |
| W-000145 | Sprint / Priority | Sprint 1 SysMap / P3 | Sprint 2 SysMap / P2 | Gerson | 16/09 19:43 |
| W-000098 | Sprint / Priority | backlog / P3 | Sprint 2 SysMap / P2 | Gerson | 16/09 19:43 |
| W-000101 | Sprint / Priority | backlog / P3 | Sprint 2 SysMap / P2 | Gerson | 16/09 19:43 |
| W-000119 | Sprint | backlog (P2) | Sprint 2 SysMap (P2, igual) | Gerson | 16/09 17:44 |
| W-000120 | Sprint | backlog (P2) | Sprint 2 SysMap (P2, igual) | Gerson | 16/09 17:44 |
| W-000122 | Sprint / Priority | backlog / P3 | Sprint 2 SysMap / P2 | Gerson | 16/09 19:43 |
| W-000124 | Sprint / Priority | backlog / P4 | Sprint 2 SysMap / P2 | Gerson | 16/09 19:43 |
| W-000100 | Sprint / Priority | backlog / P4 | Sprint 3 SysMap / P3 | Gerson | 16/09 19:43 |
| W-000125 | Sprint / Priority | backlog / P4 | Sprint 3 SysMap / P3 | Gerson | 16/09 19:43 |
| W-000099 | Sprint | backlog (P4) | Sprint 4 SysMap (P4, igual) | Gerson | 16/09 17:44 |

Cadeia de prioridade no historico (campo rastreado), exemplo W-000123: 16/09 10:09 Gerson vazio -> P2 (passada em massa dele
em 91 works); 17:23 Diego P2 -> P4 (script 40 v2); 19:43 Gerson P4 -> P1 (junto com a entrada na Sprint 1). O mesmo padrao vale
para 096, 097, 098, 100, 101, 122, 124, 125, 144 e 145: o Gerson corrigiu a prioridade para a da sprint escolhida.

Linha do tempo de 16/09: 10:09 Gerson define Priority em 91 works; 15:35 consulta da sessao conectada ja mostra a Sprint 1 com
096, 097, 107, 123 e sem 142 a 145 (a troca aconteceu entre a noite de 15/09 e 15:35, provavelmente na passada das 10:09); 16:35
Gerson toca 135, 136, 137; 17:23 script 40 v2 (Diego); 17:42 Gerson cria Sprints 2, 3 e 4; 17:44 e 19:43 Gerson distribui as
US B2B e acerta prioridades.

## B. Composicao atual das sprints (17/09 de manha)

Sprint 1 - SysMap (15-26/09), 11 works:

| Work | Prio | Responsavel | Status | Assunto |
|---|---|---|---|---|
| W-000051 | P1 | Davi Israel de Abreu | New | US EPC-01 Attribute Categories do catalogo |
| W-000052 | P1 | Davi Israel de Abreu | New | US EPC-04 Hierarquia de Object Types |
| W-000053 | P1 | Davi Israel de Abreu | New | US EPC-05 Product Specifications da Onda 1 |
| W-000054 | P1 | Davi Israel de Abreu | New | US EPC-09 Compilacao de atributos e batch jobs |
| W-000055 | P1 | Davi Israel de Abreu | New | US EPC-03 (P) Dicionario de atributos |
| W-000096 | P1 | Davi Israel de Abreu | New | US B2B-01 Escalonamento de inatividade de leads |
| W-000097 | P1 | Davi Israel de Abreu | New | US B2B-02 Enderecamento geocodificado e viabilidade |
| W-000107 | P1 | Davi Israel de Abreu | New | US CPQ-BRE-01 Motor de regras de precificacao |
| W-000123 | P1 | Davi Israel de Abreu | New | US B2B-10 Visao 360 de contratos e ativos |
| W-000140 | P0 | (sem responsavel) | New | B2B - Habilitar integracao B2B para testes |
| W-000141 | P1 | (sem responsavel) | New | B2B - Escrever historias B2B (onboarding SysMap) |

- Sprint 1 - Brasil TecPar (15-26/09), 5 works: 133 (P0), 134 (P0), 135, 136, 137 (P1), todas New e sem responsavel.
- Sprint 2 - SysMap (29/09-10/10), 8 works P2: 098, 101, 119, 120, 122, 124, 144, 145 (Davi).
- Sprint 3 - SysMap (13-24/10), 2 works P3: 100, 125 (Davi).
- Sprint 4 - SysMap (27/10-07/11), 3 works P4: 099, 142, 143 (Davi).
- Backlog SysMap sem sprint: 64 works (1 P0, 23 P1, 14 P2, 19 P3, 7 P4). Entre as P1: 056, 070, 102 (decisao pendente,
  script 41 fase 1 mostrou que entrariam na Sprint 1) e 11 do catalogo (103, 104, 108, 111 a 114, 121, 127, 128).

Lixeira: 041, 042, 043, 044, 138, 139 com IsDeleted = true (apagadas em 15/09 pelo Diego), como esperado; 24 works na lixeira
no total. Criterios de aceite: 142 a 145 com 9/8/7/8; 133 a 137 com 5/4/3/4/4; 140 e 141 com 4 e 3; 070 com 3; igual ao esperado.

## C. Works fora do pacote (18) e campos vazios

Internas do BTP (010 a 028, criadas em junho/julho por Thiago e Diego) mais W-000021 (Governanca, Gerson). 10 fechadas, 8 abertas:

| Work | Sprint | Status | Faltando | Assunto |
|---|---|---|---|---|
| W-000010 | Junho/2026-Time Salesforce (encerrada) | QA In Progress | Priority | Avaliacao de payload do Ary (Consul) |
| W-000011 | Junho/2026-Time Salesforce (encerrada) | QA In Progress | Priority | Data Map para TMF Forum |
| W-000018 | Junho/2026-Time Salesforce (encerrada) | In Progress | Priority | Dashboard para Lorena Israel |
| W-000019 | Julho/2026-Time Salesforce (encerrada) | New | Priority | Integracao Salesforce com Slack |
| W-000021 | (backlog) | New | Priority | HUB Governanca Salesforce (time GOVERNANCA) |
| W-000023 | Julho/2026-Time Salesforce (encerrada) | New | Priority | DEMO da planilha financeira |
| W-000025 | Junho/2026-Time Salesforce (encerrada) | In Progress | Priority | Esteira CI/CD |
| W-000028 | (backlog) | In Progress | Priority, Epic | Carga de contas no Salesforce |

Nenhuma work nova acima de W-000145. Details, Epic e Tag preenchidos em todas as 93 do pacote.

Sprints antigas: "Julho/2026-Time SysMap-1a e 2a Sem" com data invertida (inicio 01/07, fim 15/06) e quatro vazias
("Junho/2026-Time SysMap-3a e 4a Sem", "Julho/2026-Time SysMap-3a e 4a Sem", "Sprint Catalogo - 1a e 2a Semana", "Sprint
Catalogo - 3 e 4 Semana"), todas de junho a agosto, criadas por Thiago e Marcelo Matias.

## D. Proposta de correcao (nada executado; espera o "vai")

| # | Divergencia | Proposta |
|---|---|---|
| 1 | 17 works com Sprint/Priority diferentes do CSV (secao A) | Aceitar o replanejamento do Gerson (e coerente: prioridade = ordem da sprint). Atualizar as colunas "Sprint" e "Prioridade" do CSV e registrar no diario; nao reverter. Confirmar com o Gerson que 142 a 145 sairem da Sprint 1 foi intencional (tinham 9/8/7/8 criterios de aceite e eram a entrega B2B da sprint). |
| 2 | W-000056, 070, 102 no backlog | Mantem a decisao de 16/09 (proxima onda). Se o Gerson quiser na Sprint 1, script 41 com EXECUTAR = true. |
| 3 | W-000132 (TEC-DEV-01, CI/CD) P0 sem sprint | Ou entra na Sprint 1 ou 2 da SysMap, ou volta a P1. E par da 133 (BTP) e da 025 (Esteira CI/CD, BTP, em andamento). |
| 4 | 7 works em sprint corrente sem responsavel (133 a 137, 140, 141) | Gerson define os 5 do BTP (provavelmente ele, Victor e Diego); 140 e 141 com a SysMap (Davi ou o novo responsavel). Script 42. |
| 5 | 8 works antigas do BTP sem Priority, 6 presas em sprint de junho/julho | Gerson decide: fechar (010, 011, 018 estao em QA/andamento ha 2 meses) ou repriorizar e mover para a Sprint 1 - Brasil TecPar. Script 42. |
| 6 | W-000028 sem epico | Epico "Projetos Internos". Script 42. |
| 7 | 5 sprints antigas vazias ou com data invertida | Apagar (sem work dentro). Script 42, com "vai" separado por ser delete. |

Script 42 (a escrever): duas fases, so os campos acima, sem tocar na prioridade das 5 works do Gerson nem nas 93 do pacote.

## Rascunho de resposta ao Gerson

> Bom dia, Gerson! Revisei agora na org. As duas Sprints 1 estao consistentes: 11 na SysMap e 5 no BTP, todas com epico,
> time e prioridade, e as Sprints 2, 3 e 4 que voce montou ontem a noite estao coerentes (prioridade acompanhando a sprint).
> So preciso confirmar uma coisa: as US 142 a 145 (B2B-13 a 16) sairam da Sprint 1 para as Sprints 2 e 4 e entraram
> 096, 097, 107 e 123 no lugar; foi essa a intencao? Se sim, atualizo o pacote enviado ao Michel.
> O que falta ajustar: (1) responsavel nas 5 works do BTP da Sprint 1 (133 a 137) e nas 140/141; (2) 8 works antigas do
> Time Salesforce sem prioridade, 6 delas presas em sprints de junho/julho (010, 011, 018, 019, 023, 025), voce decide se
> fecha ou repriorizamos; (3) a W-000132 (CI/CD) esta P0 mas fora de sprint. Tem tambem 5 sprints antigas vazias que
> posso apagar. Me passa os responsaveis e o destino das antigas que eu ajusto tudo de uma vez.
