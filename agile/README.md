# Radar de Works - Agile Accelerator (SysMap)

Snapshot de 24/08/2026 das 19 works criadas no Agile Accelerator para o programa
Communications Cloud (5 EPC de catalogo + QUAL-01 + 13 B2C), extraidas de
`agf__ADM_Work__c` e `agf__ADM_Acceptance_Criterion__c` via Salesforce Inspector.

Finalidade: base de validacao das entregas da SysMap. Um PDF por work, no modelo
de impressao do Agile, gerado a partir destes dados.

## Conteudo

- `works_data.py` - W-000056 a W-000069 (QUAL-01 + B2C-01..13), campo Details completo
- `epc_data.py` - W-000051 a W-000055 (EPC-01, 04, 05, 09, 03P), criterios embutidos no Details
- `criterios_raw.tsv` - registros de Acceptance Criterion (so existem para W-000056..069)
- `gen_html.py` / `gen_html_epc.py` - geradores dos HTML; PDF via Chromium headless
  (`chromium --headless --no-pdf-header-footer --print-to-pdf`)

## Como regerar

```
python3 gen_html.py && python3 gen_html_epc.py
for f in html/*.html; do chromium --headless --no-sandbox --no-pdf-header-footer \
  --print-to-pdf="pdfs/$(basename $f .html).pdf" "file://$PWD/$f"; done
```

## Apontamentos do snapshot (para o radar)

1. Todas as 19 works em status New, sem sprint e sem story points - falta planejamento.
2. As 5 works EPC tem criterios de aceite apenas como texto no Details, sem registros
   filhos de Acceptance Criterion; EPC criadas em 17/08 com Scrum Team "Salesforce",
   demais em 19-20/08 com Scrum Team "SysMap".
3. W-B2C-14 (Acervo de Contratos Assinados) NAO foi criada no Agile - nossa base tem
   14 works B2C, la existem 13. Buraco de escopo a registrar.
4. Dados: W-000056 tem dois criterios com Name="4"; textos das works B2C carregam
   aspas duplicadas herdadas do import (normalizado nos PDFs).

Queries de reextracao: ver historico da sessao (filtro CreatedDate ou Name IN).
