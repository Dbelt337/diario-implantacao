# Scripts Apex (Execute Anonymous) do backlog Agile Accelerator

| # | Arquivo | O que faz | Grava? |
|---|---|---|---|
| 04 v4 | 04_ValidarWorks_Catalogo_0409_v4.apex | Valida notas dos scripts 01/02/03/05/07 (esperado 72 OK) | Não |
| 04 v8 | 04_ValidarWorks_Catalogo_0409_v8.apex | v4 + notas dos scripts 08/09 (v7, 79 OK) + notas do script 11. Esperado: 81 OK | Não |
| 04 v8c | 04_ValidarWorks_Catalogo_0409_v8_compacto.apex | Mesmo v8 sem comentários e sem DUMP (8 KB), para o Developer Console não dar HTTP 431 | Não |
| 10 | 10_DumpWorks_CAT-ACC-01_0809.apex | Dump completo do Details de W-000117 e W-000103 | Não |
| 11 | 11_CorrigirNotas_CAT-ACC-01_0809.apex | Grava as notas de correção de 08/09 em W-000117 e W-000103 | Sim (2 updates) |
| 12 | 12_LimparFragmentosMarkdown_0809.apex | Remove fragmentos "## n." colados no Details de W-000073, 075 e 083 | Sim (3 updates) |
| 13 | 13_ExtrairWorks_Completo.apex | Extração completa (campos, Details, Acceptance Criteria, comentários, tasks) em linhas EXT\|; log lido por tools/parse_ext_log.py | Não |
| 14 | 14_MigrarCriteriosParaRelatedList.apex | Cria Acceptance Criteria a partir dos critérios escritos no corpo, nas works sem related list; DRY_RUN=true por padrão | Sim (com DRY_RUN=false) |

Ordem em 08/09: rodar o 11 (grava 2 notas) e depois o 04 v8 (esperado 81 OK). O v8 foi reconstruído a partir do v4 e do log do v7; os scripts 01, 02, 03, 05, 07, 08, 09 e o 04 v7 ficaram na sessão anterior e não estão neste repositório.
