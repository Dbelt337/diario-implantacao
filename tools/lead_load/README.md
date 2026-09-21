# Carga massiva de Leads B2B — BrasilTecPar

Template para a SDR preencher + validador a seco (mesmo método de `tools/mg_load`, a carga de 415 contas de MG):
validar antes, reter dúvidas, gravar em lotes pequenos, conferir depois.

> Dados de clientes (planilhas da SDR, exports da org, saídas) ficam fora do git (`.gitignore`). Só o código e o template vazio são versionados.

## Arquivos

| Arquivo | O que é |
|---|---|
| `gerar_template_leads.py` | Gera `Template_Carga_Leads_B2B.xlsx` (aba Leads com conferência por fórmula, aba Listas, aba Instrucoes). Com `--dados Massiva.xlsx` despeja a planilha da SDR no template. |
| `validar_leads.py` | Lê o template preenchido, cruza com a org e separa em A (inserir), B (retidos) e C (já cliente). Não faz DML. |
| `Template_Carga_Leads_B2B.xlsx` | Template vazio, com uma linha de exemplo. |

## Fluxo

1. **SDR** preenche o template (uma linha por CNPJ) e só envia quando a coluna LINHA estiver OK em todas as linhas.
2. **Governança** roda o validador em modo offline para ver os erros de formato:
   ```bash
   python3 validar_leads.py --arquivo Leads_SDR.xlsx --out saida/
   ```
3. Exporta da org (sandbox primeiro) as três consultas que o validador gravou em `saida/consultas.soql`:
   ```bash
   sf data query -o <org> --json -q "<consulta 1>" > leads.json
   sf data query -o <org> --json -q "<consulta 2>" > accounts.json
   sf data query -o <org> --json -q "<consulta 3>" > users.json
   ```
4. Roda de novo, agora cruzando com a org:
   ```bash
   python3 validar_leads.py --arquivo Leads_SDR.xlsx --leads leads.json --accounts accounts.json --users users.json --out saida/
   ```
   - `A_leads_inserir.csv`: colunas já com os nomes de API do Lead. Preencher `RECORDTYPE_LEAD_B2B` no script com o Id do tipo de registro da org alvo antes.
   - `B_retidos.csv`: volta para a SDR com o motivo por linha.
   - `C_ja_cliente.csv`: CNPJ que já é Conta. Pela B2B-01 (W-000096) vira Oportunidade na Conta, não Lead.
5. **Carga controlada** (Data Loader ou `sf data import bulk`): 2 linhas primeiro, conferir na org (dono, CNPJ mascarado, origem, status), depois o lote; `threads = 1` por causa da cadeia de automações do Lead.
6. Devolver para a SDR a lista com o Id do Lead criado (substitui a coluna "ATUALIZADO SF?" da planilha antiga).

## Regras aplicadas

- CNPJ: 14 dígitos, dígito verificador, sem repetição; CPF é retido (carga só de PJ).
- Obrigatórios: proprietário, origem, CNPJ, razão social, sobrenome do contato, e telefone ou e-mail.
- Telefone com DDD (10 ou 11 dígitos); um e-mail por linha.
- Duplicidade: no arquivo, contra Lead aberto e contra Conta (por `DocumentNumber__c`, nos dois formatos, com e sem máscara).
- Proprietário: e-mail bate ou nome único e ativo. Nunca chuta.
- Gravados pela governança: `Status = New` (rótulo Novo), tipo de registro Prospecto - B2B, `Stage__c = 10`, `Segment__c` e
  `ClusterManual__c` padrão da carga (constantes no topo do validador).
- Telefones: as validações ativas `VRPhoneMask` e `VRCellphoneMask` só aceitam dígitos (fixo DD+8 ou 0800+7; celular DD+9+8).
  O validador roteia os dois telefones da planilha pelo formato (fixo -> Phone, celular -> MobilePhone) e manda o excedente
  para Description.

## Confirmado na btp-prod (21/09/2026, primeira carga real: 104 leads da SDR)

- `LeadSource`: o rótulo "Listas GRs ALT" da aba Listas corresponde ao valor **"Outbound - Listas GRs ALT"** (mapa `ORIGENS`).
- `SDR__c` é lookup de User: recebe o mesmo Id do proprietário.
- RecordType "Prospecto - B2B" na prod: `012V2000002CjpsIAC` (sandbox tem outro Id).
- `Stage__c` (Temperatura do lead) é obrigatório e sem padrão: sem ele o insert falha.
- `LegalEntityType__c` não tem valor "PJ" (Sociedade Limitada, LTDA, Simples, MEI): fica vazio.
- `MainEmail__c` não é gravável via API (INVALID_FIELD_FOR_INSERT_UPDATE); só `Email`.
- Estado/país com picklist: enviar `StateCode` (UF) e `CountryCode = BR`.
- Trigger do Lead não faz nada no insert; único flow acionado por registro é de lead perdido. Carga via `sf data import bulk`
  em dois jobs (piloto de 2 e o restante) passou sem falhas.

## O que ainda precisa ser confirmado na org

- Regras de validação inativas do Lead (`ValidaCPFeCNPJ`, `DocumentValidation`, `PhoneValidationFormat`): se forem reativadas, a carga passa a respeitá-las.
- Permissão de importar: a W-000071 prevê o permission set `PS_B2C_Lead_Importer` só para Coordenação e Marketing.
