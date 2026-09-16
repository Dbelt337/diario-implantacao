# 16/09/2026 - Carga massiva de Leads B2B: template + validador (pedido do Diego)

Pergunta: a SDR (Vitoria) manda a planilha "Massiva_SDR_Vitoria_1.xlsx" e a carga precisa ser validada antes;
tem algo no projeto sobre isso? Sim, tres coisas:

1. `tools/mg_load` (branch account-cpf-cnpj-normalize, agosto): pipeline a seco da carga de 415 contas B2B de MG.
   Regras reaproveitadas: DV do CNPJ, CPF retido, crossmatch por DocumentNumber__c nos dois formatos (com e sem
   mascara), proprietario por e-mail ou nome unico ativo (nunca chuta), arquivos A/B/C, threads=1 e 2 linhas de teste.
2. W-000071 (US B2C-14): carga massiva de leads e contingencial, restrita a Coordenacao e Marketing pelo permission
   set PS_B2C_Lead_Importer (a construir); Import Leads sai do perfil de vendedor.
3. W-000096 (US B2B-01): CNPJ que ja e Conta ativa (ou grupo economico) nao vira Lead; vira Oportunidade na Conta.
   Lead nasce em "Novo". Inventario do org (desenho-tecnico-b2c, 19-20/08): Lead ja tem DocumentNumber__c,
   LegalEntityType__c, CNAE__c, FantasyName__c, SDR__c, Segment__c; VRs de qualidade existem e estao INATIVAS
   (ValidaCPFeCNPJ, DocumentValidation, PhoneValidationFormat); duplicate rules so as standard (Lead x Lead,
   Lead x Contact), sem dedup contra Conta por CNPJ; Lead.assignmentRules vazio.

## Diagnostico da planilha da SDR (1.000 linhas, 125 com dados)
- 875 linhas "vazias" tem 0 na coluna "ATUALIZADO SF?": arrastaram a formula; tem de filtrar antes de importar.
- "Origem do Lead" = "Listas GRs ALT" com quebra de linha no fim em TODAS as 125 linhas: quebra a picklist LeadSource.
- Contato ("Cliente") em um campo so: o Lead exige LastName; 13 com espaco no fim, 12 com capitalizacao irregular.
- 7 linhas sem telefone (todas com e-mail); 84 com segundo telefone; 18 numeros 0800.
- CNPJ: 125 validos (DV), 0 duplicados, 0 fora da mascara. 1 e-mail repetido e 5 telefones repetidos entre CNPJs
  diferentes (mesmo contador/socio; nao e erro).
- Proprietario so por nome ("Vitoria da Costa Hyppolito"): precisa bater com usuario ativo unico.
- Razoes sociais longas (5 com 60+ chars): cabem em Company (255).

## Entregue (tools/lead_load)
- `gerar_template_leads.py`: gera `Template_Carga_Leads_B2B.xlsx` em OOXML puro (sem openpyxl no ambiente).
  Aba Leads: 15 colunas mapeadas a campos do Lead (obrigatorias em amarelo), listas suspensas (Origem, SDR, UF) e
  7 colunas de conferencia por formula (CNPJ so digitos, DV, duplicado, telefone, e-mail, obrigatorios, LINHA
  OK/REVISAR) com formatacao condicional. Abas Listas e Instrucoes. `--dados Massiva.xlsx` despeja a planilha da
  SDR no template (Origem sem quebra, contato separado em Nome/Sobrenome, e-mails extras em Observacoes).
- `validar_leads.py`: validador a seco (stdlib). Offline: formato, obrigatorios, duplicidade no arquivo.
  Online (exports leads/accounts/users via sf CLI, consultas geradas em saida/consultas.soql): Lead ja existente,
  CNPJ ja Conta (arquivo C -> Oportunidade), proprietario resolvido. Saida A com nomes de API do Lead.
- `test_validar_leads.py`: 4 testes, OK. Resultado na planilha da SDR (offline): 125 linhas com formato OK.
- Limitacao: as formulas do template nao foram recalculadas aqui (sem LibreOffice); XML validado com xmllint.
  Abrir no Excel e conferir a coluna LINHA na linha de exemplo antes de mandar para a SDR.

## Pendente de confirmar na org
Valores de LeadSource; tipo de SDR__c; Id do RecordType de Lead B2B (sandbox e prod); valor "Novo" de Status e
"PJ" de LegalEntityType__c; se as VRs inativas serao reativadas; quem recebe PS_B2C_Lead_Importer.
