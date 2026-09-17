# 17/09/2026 - Briefing: revisão das sprints e works no Agile Accelerator (pedido do Gerson)

Gerson (Governança SF), 17/09 de manhã: "Consegue dar uma revisada nas sprints e works que estão lá para ver se está tudo
certinho?". Este briefing é para a sessão do Claude Code conectada na org (btp-prod). **Somente leitura.** O resultado é um
relatório de divergências para o Diego decidir; nada é gravado sem o "vai" dele.

## Estado esperado (fonte: docs/2026-09-15-works-validadas-pacote-marcelo.csv + decisões de 16/09)

93 works do pacote validado (W-000051 a W-000145, menos as 6 excluídas em 15/09: 041 a 044, 138, 139).
O Pacote_Works_SysMap_1609.zip enviado ao Michel tem os 88 docs da SysMap; os 5 do Gerson ficam fora.

| Item | Esperado |
|---|---|
| Time | 88 SysMap; 5 Brasil TecPar (133, 134, 135, 136, 137). Scripts 21 e 38. |
| Sprint 1 - SysMap (15-26/09) | 051, 052, 053, 054, 055, 140, 141, 142, 143, 144, 145 (11 works). Scripts 17, 20, 39. |
| Sprint 1 - Brasil TecPar (15-26/09) | 133, 134, 135, 136, 137. |
| Backlog (sem sprint) | todas as outras 77 da SysMap, inclusive 056, 070 e 102 (decisão de 16/09: próxima onda, script 41 não rodou). |
| Priority | Script 40 v2 (16/09): P0 = 132, 133, 134, 140; P1 = fundação + catálogo + integrações (33); P2 = lead/opp (18); P3 = cotação a instalação (24); P4 = pós-venda (14). Lista completa no CSV, coluna "Prioridade (Agile, 16/09)". |
| Responsável | Davi Israel de Abreu nas US da SysMap; 140, 141 e as 5 do Gerson sem responsável (decisão de 15/09). |
| Status | New em todas. |
| Lixeira | 041, 042, 043, 044, 138, 139 com IsDeleted = true até 30/09. |
| Tag | Salesforce em todas as 88 da SysMap. |

## Divergência já conhecida (consulta de 16/09 18:35, sessão conectada)

A Sprint 1 - SysMap tinha 11 works na org, mas **não as mesmas do CSV**: 140, 051, 052, 053, 054, 055, 107, 141, 096, 097, 123.
Ou seja: **142, 143, 144, 145 saíram** da sprint e **096, 097, 107, 123 entraram**, entre a noite de 15/09 e a tarde de 16/09,
por alguém fora dos scripts do diário (provavelmente Gerson ou Davi ao montar a sprint). O relatório precisa mostrar quem e
quando (LastModifiedBy/LastModifiedDate e, se houver rastreamento, o histórico do campo Sprint).

## O que conferir (consultas por arquivo, `sf data query -o btp-prod --json --file ...`; ver seção 9 do doc de conexão)

1. **Todas as works** (não só as 93): `SELECT Name, agf__Subject__c, agf__Scrum_Team__r.Name, agf__Sprint__r.Name, agf__Priority__c,
   agf__Assignee__r.Name, agf__Status__c, agf__Epic__r.Name, agf__Product_Tag__r.Name, RecordType.Name, CreatedBy.Name, CreatedDate,
   LastModifiedBy.Name, LastModifiedDate FROM agf__ADM_Work__c ORDER BY Name`. Cruzar com o CSV, work a work: time, sprint,
   prioridade, responsável, status. Listar também works fora do CSV: internas de BTP (010 a 028) e qualquer W acima de 145
   (criadas depois de 15/09).
2. **Sprints**: `SELECT Id, Name, agf__Scrum_Team__r.Name, agf__Start_Date__c, agf__End_Date__c, agf__Committed_Points__c,
   agf__Completed_Points__c FROM agf__ADM_Sprint__c ORDER BY agf__Start_Date__c DESC`. Conferir nomes, datas (15 a 26/09), time
   dono, e se há sprint antiga ainda com works ("Sprint Catálogo - 1a e 2a Semana", de julho).
3. **Work em sprint de outro time**: sprint cujo agf__Scrum_Team__c difere do agf__Scrum_Team__c da work (caso 053/054 de ontem).
4. **Histórico**: `SELECT ParentId, Field, OldValue, NewValue, CreatedBy.Name, CreatedDate FROM agf__ADM_Work__History WHERE
   CreatedDate = LAST_N_DAYS:3 AND Field IN ('agf__Sprint__c','agf__Priority__c','agf__Scrum_Team__c','agf__Assignee__c') ORDER BY
   CreatedDate` (se o objeto de histórico não existir, usar LastModifiedBy/LastModifiedDate da consulta 1).
5. **Lixeira**: `SELECT Name, IsDeleted FROM agf__ADM_Work__c WHERE Name IN ('W-000041','W-000042','W-000043','W-000044','W-000138',
   'W-000139') ALL ROWS` (via `sf apex run` sem DML, porque `sf data query` não aceita ALL ROWS).
6. **Campos vazios que o Gerson vai reparar**: Priority nula, Epic nulo, Product Tag nulo, Details vazio.
7. **Critérios de aceite**: contagem por work (`SELECT agf__Work__r.Name, COUNT(Id) FROM agf__ADM_Acceptance_Criterion__c GROUP BY
   agf__Work__r.Name`); esperado: 142 a 145 com 9/8/7/8, 133 a 137 e 140/141 com 3 a 5, 070 com 3, 087 e 096 a 101 com 2 a 3.

## Saída

- `docs/2026-09-17-revisao-agile-gerson.md` com: (a) tabela de divergências por categoria (time, sprint, prioridade, responsável,
  status, campos vazios), cada linha com work, esperado, encontrado, quem alterou e quando; (b) composição atual das duas
  Sprint 1; (c) works novas ou fora do pacote; (d) proposta de correção para cada divergência, sem executar.
- Rascunho de resposta ao Gerson (curto: o que está certo, o que diverge, o que o Diego decide).
- Commit e push. Antes, `git pull --rebase origin claude/vigilant-planck-db8yo7`: o commit e7c4295 de ontem ainda não foi
  enviado e este briefing entrou pela sessão remota.

## Regras

- Nenhum DML, nenhum deploy. Se uma correção for óbvia (ex.: 142 a 145 de volta à Sprint 1), propor no relatório e esperar o "vai".
- 142 a 145 na Sprint 1 com P3/P4 é o estado decidido em 16/09 (sprint e prioridade dizem coisas diferentes de propósito).
- Não mexer nas 5 works do Gerson nem propor prioridade para elas além da que o script 40 já gravou.
