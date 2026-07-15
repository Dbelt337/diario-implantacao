# HU-025 — Conversão de Lead com Line Items e Preferred Sellers (Automotive Cloud)

## FECHAMENTO (16/07/2026, ~00h) — multicurrency-complete TAMBÉM gack

Multicurrency CONFIRMADO na Company Information: "Activate Multiple
Currencies: Checked", Corporate Currency = Costa Rica Colon. Org ID
00DWK000005VFeD (keyspace WK nativo).

Testado o mapping EXATO que a doc prescreve p/ multicurrency: 2 registros
nativos (Y52/Y62) com mappingField CurrencyIsoCode->CurrencyIsoCode, sem
duplicata. API → UNKNOWN_EXCEPTION 814372279-867065 (918409590). Gack.

Matriz final (toggle ON salvo linha 1):
- Toggle OFF                          → FUNCTIONALITY_NOT_ENABLED (limpo)
- 0 mappings                          → INVALID_INPUT (limpo)
- mappings foreign (marco, aZ)        → gack
- mappings nativos vazios (WK)        → gack
- mappings nativos + CurrencyIsoCode  → gack  <== doc-complete p/ multicurrency

Conclusao inequivoca: o motor de transformacao gack-eia ao executar QUALQUER
mapping valido nesta org. Nao e config (toggle, permissoes, automacoes,
moeda, price book, duplicata, keyspace, multicurrency mapping — todos
verificados/eliminados). Bug de plataforma. Case.

Estado da org: 2 mappings nativos completos (Y52/Y62 com CurrencyIsoCode),
toggle ON. Deixar assim — corretos, funcionarao quando SF corrigir o motor.

---

## VEREDITO DEFINITIVO (15/07/2026, ~23h50) — BUG DE PLATAFORMA CONFIRMADO POR RESET COMPLETO

Repro minimal determinístico estabelecido:
- ObjectHierarchyRelationship com ZERO registros (toggle ON) → API retorna
  INVALID_INPUT limpo ("Specify a mapping ... and try again").
- Adicionar UM mapping válido → API retorna UNKNOWN_EXCEPTION (gack 918409590).
  Vale para os registros de março (foreign, keyspace aZ) E para registros
  recriados NATIVOS nesta org (0kFWK00000002Y52AI / 0kFWK00000002Y62AI).

Portanto a origem/keyspace dos registros é IRRELEVANTE — o motor quebra ao
executar qualquer mapping válido LeadLineItem→OpportunityLineItem nesta org.
Erro limpo quando não há o que fazer; crash quando há. Defeito de plataforma.

Ocorrências do gack observadas (todas assinatura 918409590):
210204039-197303, 246717173-1939784, 814372279-855789, 1102452587-240393,
246717173-1952457 (e 1236512795-531785 citada em análise paralela).

Reset executado (backup → delete OOB → toggle off/on → recriar nativo):
- Toggle OFF → API retorna FUNCTIONALITY_NOT_ENABLED (gate funciona).
- Religar o toggle NÃO re-provisiona os mappings (aprendizado p/ promoção:
  habilitar o toggle no ambiente destino NÃO cria os ObjectHierarchyRelationship;
  é preciso deployar os registros — pacote em backup/redeploy-native-mappings.zip).
- Os OOB de março (LeadItemToOppItemOOBMappings / LeadPrefToOppPrefOOBMappings,
  0kFaZ...) foram criados por OSF Digital em 25/03 e vieram via refresh de
  sandbox; NÃO são provisionados pelo toggle.

Estado atual da org: 2 mappings nativos presentes (Y52/Y62), toggle ON.
Deixar como está — corretos, apenas disparam o bug; funcionarão quando a
Salesforce corrigir o motor.

PENDÊNCIAS: (1) reativar automações de desconto da Opp (Opp RT Discount
Approval + Opp_AS_RequestDiscountApproval); (2) abrir case; (3) decidir
workaround declarativo Lead_AS_CopiaLineItemsOpp para destravar a HU.

---

## VEREDITO (15/07/2026, ~19h) — BUG DE PLATAFORMA, escalar para Salesforce

Chamada manual da Transformations API no Workbench (REST Explorer), payload
completo e válido, retornou **UNKNOWN_EXCEPTION** com ErrorId
**210204039-197303 (918409590)** — erro interno da plataforma. É a mesma
falha que ocorre silenciosamente na conversão automática.

Requisição que reproduz (POST /services/data/v65.0/connect/manufacturing/transformations):
```json
{
  "inputObjectIds": ["0wkWK0000000O5ZYAU"],
  "inputObjectName": "LeadLineItem",
  "outputObjectName": "OpportunityLineItem",
  "usageType": "TransformationMapping"
}
```
Observações da investigação via API:
- `/connect/automotive/transformations` → NOT_FOUND (alias não existe na org)
- `/connect/manufacturing/transformations` → existe; validação de argumentos
  funciona (MISSING_ARGUMENT em cadeia); execução quebra com gack.

Config toda verificada e correta antes do veredito: toggle On, mappings
CurrencyIsoCode deployados (0kFWK00000002WT2AY / 0kFWK00000002WU2AY),
entry CRC ativa no price book da Opp, usuário sysadmin com permset Partner
Lead Management, massa de teste confirmada por query.

AÇÃO: abrir case Salesforce com o ErrorId + repro. Enquanto o case corre,
avaliar workaround declarativo (flow copiando LeadLineItem→OLI na conversão,
desenho já feito — "Opção 1" no histórico deste diário).

### Ocorrências do gack (todas com assinatura 918409590)
1. 210204039-197303 — 1ª chamada REST (payload completo)
2. 246717173-1939784 — 2ª chamada (após permset Partner Lead Management
   no usuário Diego)
3. 814372279-855789 — 3ª chamada, COM as automações de desconto da
   Opportunity DESATIVADAS (Opp RT Discount Approval +
   Opp_AS_RequestDiscountApproval, desativadas por Santiago às 19:10 de
   15/07) — elimina automação da org como causa.
4. 1102452587-240393 — 4ª chamada, APÓS DELETAR os 2 mappings custom
   (destructive deploy 22:47Z), org em estado de fábrica: só os OOB
   LeadItemToOppItemOOBMappings / LeadPrefToOppPrefOOBMappings
   (IDs 0kFaZ0000016gnBUAQ / 0kFaZ0000016gnCUAQ, provisionados pelo toggle).
   Elimina a teoria de mapping duplicado como causa do gack. Os mappings
   custom NÃO devem ser recriados (sem campos custom, OOB basta).

Suspeitos eliminados: toggle, mappings OHR/CurrencyIsoCode, moeda/price
book/entry CRC, permissões (sysadmin + permset nos 2 usuários), automações
de Opportunity. Achado colateral: "Opp RT Discount Approval" tem fault não
tratado próprio (Error ID 388533351-685040, logs de 15/07 12:42) — corrigir
fault path independente deste case. REATIVAR as automações de desconto no
DevSales após os testes.

### Prova final (15/07, ~16:30 org time)
Conversão VÁLIDA via Database.convertLead (lead 00QWK00000PBZgn2AH, owner
usuário, validações ok, LeadLineItem 0wkWK0000000OGrYAM presente, automações
da Opp desativadas) criou a Opp 006WK00000NDJ7dYAH SEM nenhum
OpportunityLineItem/OpportunityPreferredSeller. Hipótese de validation rule
da Opp descartada (Opp do 1º teste tem PreferredContactMethod/Sociedad/Marca
preenchidos). CASO ENCERRADO DO NOSSO LADO → case Salesforce aberto com 3
ErrorIds (assinatura 918409590).

### Evidência final — log FINEST da conversão (16:34 org time)
Conversão completa e válida do lead "Prueba Postman Producto 6" logada em
FINEST: account/contact criados, validações do Lead e da Opp todas PASSam
(inclusive Metodo_Preferido — Map Lead Fields FUNCIONANDO), Lead_AS_EstampaRTOpp
ok, Opp 006WK00000NDJM9 criada — e NENHUM evento de transformação na
transação: a feature nem é invocada na conversão. Log arquivado para anexar
ao case (apex07LWK00000PYdRx2AL).

### Aprendizados operacionais dos testes (para o time)
- Lead em FILA não converte ("Converted objects can only be owned by
  users") — o roteamento joga leads para fila Leads_CR_Offline; o processo
  precisa de take-ownership antes da conversão.
- Validação exige EstimatedPurchaseTime__c + contato para converter.
- Validation rules da Opp NÃO têm o bypass $Permission.Bypass_Gates_Automacao
  (as do Lead têm) — padronizar, senão derrubam automações silenciosamente.
- Workaround da HU-025 enquanto o case corre: flow declarativo
  Lead_AS_CopiaLineItemsOpp (Get/Loop/Create, sem Apex) — a construir.

## ATUALIZAÇÃO (15/07/2026, noite) — pacote ressuscitado por causa de MULTICURRENCY

Teste do Santiago falhou: conversão não copiou line item nem preferred seller,
com toggle On, massa correta, Opp no Standard Price Book com entry CRC ativa,
usuário System Administrator. Causa provável identificada NA DOC: em org
**multicurrency** é preciso deployar o `ObjectHierarchyRelationship` com o
mapping `CurrencyIsoCode → CurrencyIsoCode` (mesmo sem campos custom).
Pacote recriado nesta pasta com apenas esse mapping nos dois pares de objetos.
Deploy: `mappings-hu025-currency.zip` via Workbench (migration → deploy,
Single Package). Re-testar conversão após deploy.

Descoberta colateral do teste: a Opp convertida recebe o **Standard Price
Book**, não o book da sociedade (C101). Flow before-save de price book por
sociedade segue no backlog (ver seção de flows).

## Decisão anterior (15/07/2026, tarde) — SUPERSEDIDA PELA ATUALIZAÇÃO ACIMA

**Solução 100% nativa — sem Apex, sem flow novo e sem pacote de mappings.**

1. **Partner Lead Management Default Mappings** habilitado no Setup
   (Sandbox DevSales, 15/07/2026). A conversão do Lead passa a copiar
   automaticamente, via Transformations API interna:
   - `LeadLineItem` → `OpportunityLineItem`
   - `LeadPreferredSeller` → `OpportunityPreferredSeller`
2. **Describe dos 4 objetos filhos conferido via Anonymous Apex
   (log 07LWK00000PXu9w2AD): nenhum campo custom.** Portanto o metadado
   `ObjectHierarchyRelationship` (TransformationMapping) NÃO é necessário —
   o pacote de placeholders que existia nesta pasta foi removido.
3. O flow `Lead_AS_EstampaRTOpp` (versionado em `deploy/flows/`) permanece
   inalterado: estampa RecordType e etapa inicial na Opp convertida conforme
   `Lead.Industry`.

## Campos custom Lead → Opportunity (fora do escopo deste metadado)

Os campos custom estão nos objetos PAI. Mapeiam via *Map Lead Fields*
(Setup → Object Manager → Lead → Map Lead Fields / metadado
`LeadConvertSettings`). Pares identificados:

| Lead | Opportunity | Obs |
|---|---|---|
| `Brand__c` | `Brand__c` | Marca |
| `CompanyCode__c` | `CompanyCode__c` | Sociedad — define Price Book |
| `NationalId__c` | `NationalId__c` | Text 17 → TextArea 255 |
| `PreferredContactMethod__c` | `PreferredContactMethod__c` | |
| `BlacklistStatus__c` | `ListaNegraStatus__c` | confirmar intenção |

Sem mapeamento: `Country__c` → `Pais__c` (destino é fórmula na Opp).

CUIDADO: deploy de `LeadConvertSettings` substitui o arquivo inteiro —
aplicar os pares na UI e depois fazer retrieve para versionar aqui, ou
mesclar com o retrieve atual antes de qualquer deploy.

## Lacuna conhecida — DESCARTADA (15/07/2026)

Os campos standard do `LeadLineItem` `PriceType`, `InterestType`,
`Classification`, `Condition` e `ItemType` não têm equivalente no
`OpportunityLineItem` e se perdem na conversão. **Decisão: não precisa**
carregá-los para a Opp. Se o negócio mudar de ideia: criar campos custom no
`OpportunityLineItem` e criar o pacote `ObjectHierarchyRelationship`
(modelo no histórico do git deste repo, commit 563f646).

## Estado dos flows de Record Type (15/07/2026)

Dois flows para o mesmo problema (estampar RT da linha na Opp), ambos
versionados em `deploy/flows/`. NENHUM chama a Transformations API — a
cópia de line items é 100% do toggle nativo, camada independente.

- `Lead_AS_EstampaRTOpp` — **Active**. After-save no Lead convertido.
  Estampa RT + etapa inicial, lê `Lead.Industry`. É o que vale hoje.
- `Opp_BS_EstampaRT` v3 — **Obsolete (inativo)**. Before-save no create da
  Opp (banda 10), lê `Account.Industry`, cobre todos os canais de criação.
  Substituto planejado ("Desactivar Lead_AS_EstampaRTOpp tras validar").

Lacunas a resolver ANTES de ativar o Opp_BS e desativar o Lead_AS:
- [ ] Opp_BS não estampa etapa inicial (Open_Stage só existe no Lead_AS).
- [ ] Conversão para Account EXISTENTE: `Account.Industry` pode divergir do
      Lead ou estar vazio → RT errado ou default Autos indevido.
- [ ] Confirmar divergências de regra: Repuestos/PA (D-REP-01: sem RT no
      Opp_BS vs. GQOpportunitiesRepuestosPA no Lead_AS) e default quando
      Industry vazio (Autos no Opp_BS vs. no-op no Lead_AS).
- [ ] Pendências da própria description: braço Venta_Mayorista e fallback
      `TipoAutoQueVende__c` (deploy rejeitou o campo — investigar).

## Checklist de teste (DevSales)

- [ ] Converter Lead com line items + preferred seller e conferir cópia dos filhos.
- [ ] Conferir qual Price Book a Opp convertida recebe (desenho: 1 book por
      sociedade; `OpportunityLineItem` depende de `PricebookEntry` do book certo).
- [ ] Conferir interação com `Lead_AS_EstampaRTOpp` (RT + etapa) na mesma transação.
- [ ] Aplicar os 5 pares no Map Lead Fields e testar campos do pai.
