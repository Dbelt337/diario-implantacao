# 21/09/2026 - Carga de leads B2B da SDR (planilha Template_Carga_Leads_B2B, 125 linhas)

Pedido do Diego (21/09): verificar se os leads da planilha `docs/Template_Carga_Leads_B2B (1).xlsx` ja existem na org, se
as colunas cobrem os campos necessarios para criar Lead, e criar os que faltam. Planilha preenchida pela SDR Vitoria da Costa
Hyppolito: 125 linhas, todas com origem "Listas GRs ALT", todas em SP, proprietaria Vitoria. A planilha e a saida ficam fora
do git (`.gitignore` na raiz e em `tools/lead_load`).

## Resultado

| Situacao | Linhas | O que foi feito |
|---|---|---|
| Criadas na btp-prod | **104** | Bulk API 2.0, dois jobs: piloto de 2 (750V200000mWIr0IAG) e 102 (750V200000mWW4LIAW), 0 falhas |
| Lead ja existia | 10 | 9 da propria Vitoria (8 Nurturing, 1 New, criados entre mar/mai) e 1 do Ricardo Carnicelli. Nao criado; Id do lead existente devolvido na planilha |
| CNPJ ja e Conta | 10 | 8 contas B2B - Pessoa juridica (donos Ricardo Galvao Pires x3, Priscila, Luan, Tatiane, Alexsandro, Claudia) e 2 com tipo de registro "Pessoa Fisica" apesar de CNPJ. Regra B2B-01: abrir Oportunidade na Conta, nao Lead |
| Retida | 1 | linha 61, sem sobrenome do contato (obrigatorio) |

Retorno para a SDR: `tools/lead_load/saida/Retorno_Carga_Leads_Vitoria_2026-09-21.xlsx` (planilha original + colunas ID LEAD
SF e RESULTADO CARGA 21/09).

Conferencia depois da carga: 104 leads criados hoje com origem "Outbound - Listas GRs ALT", todos Prospecto - B2B, status New,
dona e SDR Vitoria, Brazil / Sao Paulo.

## Campos: a planilha cobre o que o Lead exige

Obrigatorios do objeto (describe): `LastName`, `Company`, `Stage__c` (Temperatura do lead, picklist 0/10/30/60/90/100, sem
padrao). A planilha tem os dois primeiros; o terceiro nao existe nela e foi fixado em **10**, valor que a propria Vitoria usa
nos leads recentes (10 e 30). Sem ele o insert falha.

Mapeamento aplicado (planilha -> Lead):

| Planilha | Lead | Valor / regra |
|---|---|---|
| Proprietario (e-mail) | OwnerId, SDR__c (lookup User) | e-mail da planilha (`vitoria.hyppolito@`) nao bate com o da org (`vitoriahyppolito@`); resolvido por nome unico e ativo: 005V200000JWKtVIAX |
| Origem "Listas GRs ALT" | LeadSource | valor real da picklist e **"Outbound - Listas GRs ALT"** |
| CNPJ | DocumentNumber__c | formato com mascara XX.XXX.XXX/XXXX-XX (padrao dos leads B2B da org) |
| Razao Social, Nome Fantasia | Company, FantasyName__c | |
| Nome, Sobrenome, Cargo | FirstName, LastName, Title | Cargo veio vazio nas 125 |
| Telefone principal / secundario | Phone / MobilePhone | ver regra de telefone abaixo |
| E-mail | Email | `MainEmail__c` nao e gravavel pelo meu perfil (INVALID_FIELD_FOR_INSERT_UPDATE); ficou so Email |
| Cidade, UF | City, StateCode + CountryCode = BR | picklists de estado/pais ativas; State/Country preenchem sozinhos |
| Observacoes | Description | |
| (fixos) | RecordTypeId 012V2000002CjpsIAC (Prospecto - B2B), Status New, Segment__c B2W - Wholesale, ClusterManual__c ALT/GGNET | copiados dos leads recentes da Vitoria |

**Regra de telefone (validacoes ativas VRPhoneMask e VRCellphoneMask, so digitos):** Phone aceita `DD + 8 digitos` ou
`0800 + 7`; MobilePhone aceita `DD + 9 + 8 digitos`. A planilha traz "principal" e "secundario" sem distinguir fixo de
celular, entao cada numero foi roteado pelo formato: fixo -> Phone, celular -> MobilePhone; o segundo numero do mesmo tipo (45
linhas) e 1 numero fora do padrao foram para Description como "Outros telefones". 7 linhas sem telefone (tem e-mail).

Primeira tentativa do piloto falhou nas duas linhas por `MainEmail__c` nao gravavel; a segunda pela mascara de celular
(`(11) 97607-8975` com formatacao). Terceira passou.

## O que roda na criacao de Lead (verificado antes da carga)

- `LeadTrigger` -> `LeadHandler`: beforeInsert e afterInsert vazios. Na atualizacao valida CNPJ (B2B) e, na conversao, liga
  produtos de interesse a oportunidade. Nada de callout no insert.
- Flow acionado por registro ativo no Lead: so `ModifyLostLead` (lead perdido). Regra de duplicidade ativa: so a padrao de
  contatos duplicados (nao bloqueou).
- Regras de validacao de CNPJ (ValidaCPFeCNPJ, DocumentValidation) inativas: a conferencia de digito verificador foi feita
  na planilha (coluna "CNPJ valido?", 125 OK) e no cruzamento.

## Pendencias para a SDR / governanca

1. Linha 61: completar o sobrenome e criar manualmente (ou reenviar).
2. 10 CNPJs que ja sao Conta: abrir oportunidade na conta existente; as 2 contas com tipo "Pessoa Fisica" e CNPJ sao erro
   de cadastro para corrigir (donos: Guilherme Elsas Ferreira De Carvalho).
3. 10 leads que ja existiam: 9 sao da propria Vitoria em Nurturing desde marco/maio; retomar em vez de recriar.
4. Template: trocar o valor "Listas GRs ALT" da aba Listas pelo nome real da picklist e acrescentar a coluna Temperatura
   (Stage__c), obrigatoria; separar Telefone fixo de Celular em vez de principal/secundario.
