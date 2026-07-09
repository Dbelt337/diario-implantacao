# Carga de Contas MG (cluster SEMPRE) — BrasilTecPar

Pipeline DRY_RUN deterministico para carregar 415 contas B2B (regional MG)
**sem criar duplicatas**: conta existente vira UPDATE por Id, inexistente vira
INSERT/UPSERT por `DocumentNumber__c`. Nao faz DML — apenas gera os arquivos de
carga segregados (A/B/C) e o relatorio.

> **Dados do cliente ficam fora do git** (ver `.gitignore`): a planilha, os
> exports de SOQL e as saidas contem CNPJs/emails/nomes. Só o codigo e versionado.

## Pre-requisitos
- Python 3 (stdlib apenas).
- Acesso a SANDBOX via `sf` CLI (ou qualquer forma de exportar as 2 consultas SOQL).

## Passo a passo (rodar na SANDBOX)

1. **Gerar as consultas** a partir da planilha (produz `query_accounts.soql` e
   `query_users.soql` com os valores reais ja embutidos):
   ```bash
   # As queries sao geradas junto do processamento; para so gera-las, veja o
   # bloco no topo de mg_load.py. Alternativamente rode direto o passo 3 depois
   # de ter os exports.
   ```

2. **Exportar do org** (crossmatch cobre os DOIS formatos — estoque misto):
   ```bash
   sf data query -o <sandbox> --json -f query_accounts.soql > accounts.json
   sf data query -o <sandbox> --json -f query_users.soql    > users.json
   ```

3. **Rodar o DRY_RUN**:
   ```bash
   python3 mg_load.py \
     --csv contas_MG_415_limpo.csv \
     --accounts accounts.json \
     --users users.json \
     --out saida/
   ```
   Saidas em `saida/`:
   - `A_update.csv`  — Action=Update. Colunas: `Id, OwnerId, Regional__c, Management__c, ClusterManual__c`. **Nao toca `Name`/`DocumentNumber__c`.**
   - `B_insert_upsert.csv` — Action=Upsert (chave `DocumentNumber__c`). RecordTypeId=`012V2000002CjppIAC` (LegalEntity_B2B), ClusterManual__c=SEMPRE.
   - `C_retidos.csv` — conflitos/retidos para revisao humana (Ana Luiza).
   - `relatorio.txt` — X atualizadas, Y criadas, Z retidas, total=415.

4. **Execucao controlada** (fora deste script — via Data Loader / `sf data upsert`):
   - `threads = 1` (evita UNABLE_TO_LOCK_ROW na cadeia de triggers Account).
   - Testar **2 linhas** por arquivo, conferir no org (RecordType, CNPJ mascarado
     intacto, owner e cluster gravados), só entao o lote completo.
   - Upsert de B por `DocumentNumber__c` garante idempotencia (re-rodar nao duplica).

## Regras implementadas
- **Documento invalido** (DV) ou **CPF** (11 digitos, inclusive zero-fillado) → retido (Arquivo C).
- **Nome divergente conhecido** (BETIM/CERSAM, FDI-MG/BDMG) → retido. Ver `EXCECOES_NOME_DIVERGENTE` em `mg_load.py`.
- **Owner**: email bate → usa; só nome, match unico e ativo → usa; ambiguo/inativo/sem match → retido. **Nunca chuta owner.**
- **Crossmatch tolerante a formato**: normaliza os dois lados (sem pontuacao, uppercase) antes de casar.

## Teste
```bash
python3 test_mg_load.py
```
Cobre DV, classificacao CPF/CNPJ, mascara, crossmatch cruzando formatos,
resolucao de owner (email/nome/ambiguo/inativo) e o pipeline ponta-a-ponta.

## Excecoes ja conhecidas (retidas automaticamente)
| CNPJ (origem) | Razao | Motivo |
|---|---|---|
| 00075209462668 | FLAVIO DE FREITAS ALVES PINTO | CPF (11 digitos zero-fillado) |
| 59896558000167 | FUNDO DESENV. MINISTERIO PUBLICO | DV invalido |
| 60239950000122 | FUNDO ESPECIAL ADVOCACIA-GERAL | DV invalido |
| 99999999992103 | FUNDO ESTADUAL DE HABITACAO | placeholder / DV invalido |
| 38486817000194 | FDI-MG vs BDMG | nome divergente |
| 18715391000196 | BETIM vs CERSAM CITROLANDIA | nome divergente |
