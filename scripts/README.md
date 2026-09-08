# Scripts Apex (Execute Anonymous) do backlog Agile Accelerator

| # | Arquivo | O que faz | Grava? |
|---|---|---|---|
| 04 v4 | 04_ValidarWorks_Catalogo_0409_v4.apex | Valida notas dos scripts 01/02/03/05/07 (esperado 72 OK). A v7 (não guardada) espera 79 OK. | Não |
| 10 | 10_DumpWorks_CAT-ACC-01_0809.apex | Dump completo do Details de W-000117 e W-000103 | Não |
| 11 | 11_CorrigirNotas_CAT-ACC-01_0809.apex | Grava as notas de correção de 08/09 em W-000117 e W-000103 | Sim (2 updates) |

Para validar o 11 com o 04 v7, acrescentar ao mapa `e05`:
```
'W-000117' => '--- CORRECAO APOS AUDITORIA DAS CONTAS BILLING (08/09) ---'
'W-000103' => '--- CORRECAO DO PASSO 2 DA CARGA (08/09) ---'
```
(esperado passa de 79 para 81 OK). Scripts 01, 02, 03, 05, 07, 08, 09 e 04 v7 ficaram na sessão anterior e não estão neste repositório.
