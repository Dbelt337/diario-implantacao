# ✅✅ HU-025 RESOLVIDA — conversão nativa cria OLI com produto e preço (16/07)

Conversão do lead "Japa" (00QWK00000PBhT32AL) criou o OpportunityLineItem
00kWK000009T8wHYAS na Opp 006WK00000NDNG6YAP:
- Produto Tucson Turbo FL Elegant resolvido automaticamente
- ListPrice 54900 (preço de catálogo, resolvido sozinho do PricebookEntry)
- Quantity 1, CRC
SEM flow de price book, SEM Apex. O mecanismo nativo funciona.

O QUE DESTRAVOU (resumo definitivo):
1. Mapping NÃO pode ter Product2Id (campo derivado do OLI) — a transformação
   resolve o produto sozinha a partir de LeadLineItem.ProductId + PricebookEntry.
2. Mapping final = só Quantity + CurrencyIsoCode. (UnitPrice removido para o
   Sales Price vir automático do catálogo em vez de copiar o preço do lead.)
3. O produto precisa ter PricebookEntry ativa em CRC no price book da Opp.

PREÇO POR SOCIEDADE — verificado: para o Tucson, Standard e C101 têm o MESMO
preço (54900). Logo a Opp no Standard traz o preço correto para este produto.
CAVEAT DE ARQUITETURA: isso só vale enquanto todas as sociedades precificarem
igual. O modelo "6 books por sociedade" existe para permitir preços diferentes;
no dia em que C101 != Standard para algum produto, a Opp no Standard traz preço
ERRADO. Salvaguarda robusta (sem flow novo): dobrar o carimbo de Pricebook2Id
por CompanyCode__c DENTRO do Opp_BS_EstampaRT já existente. Decisão do negócio:
se a precificação for uniforme entre sociedades, dispensa; se puder divergir,
aplicar a salvaguarda.

PENDENTE para fechar 100%:
- [ ] Deploy do mapping final (Quantity + CurrencyIsoCode) e reconverter →
      confirmar Sales Price automático = 54900.
- [ ] Testar o VENDEDOR: LeadPreferredSeller -> OpportunityPreferredSeller
      (mapping LeadPrefToOppPrefOOBMappings). A Opp de teste veio Preferred
      Seller (0); precisa um lead COM LeadPreferredSeller para validar a
      outra metade da HU.
- [ ] Reativar automações de desconto desativadas nos testes (Santiago).

---

# 🎯 CAUSA RAIZ AMARRADA (16/07) — Product2Id é DERIVADO + Opp no Standard

Dois achados que fecham o caso:

1. REST Explorer deu **INVALID_INPUT**: "field mappings ... invalid or derived
   mappings. {LeadLineItem=[Product2Id]}". `OpportunityLineItem.Product2Id` é
   campo DERIVADO (vem do PricebookEntryId) — NÃO pode ser mapeado. Eu quebrei
   o mapping ao adicioná-lo. Quem resolve o PRODUTO é a própria transformação
   OOB, a partir de LeadLineItem.ProductId + o PricebookEntry do price book DA OPP.
   FIX: mapping sem Product2Id. Fica só Quantity, UnitPrice, CurrencyIsoCode
   (todos aceitos pela API; não-derivados).

2. Query pós-conversão (Opp 006WK00000NDQSeYAP): CompanyCode__c=C101, mas
   **Pricebook2.Name = "Standard Price Book"** e 0 OLI. Ou seja: a Opp convertida
   NÃO nasce sem book — nasce com **Standard**. No Standard o produto não tem
   entry CRC → transformação não resolve → 0 OLI. Precisa nascer no C101.

BUG do flow Opp_BS_EstampaPricebook (corrigido): a condição era "carimba só se
Pricebook2Id vazio". Como a conversão já põe Standard, nunca disparava. Nova
condição: carimba sempre que CompanyCode__c preenchido (no create é seguro
sobrescrever o Standard — ainda não há OLI). LeadLineItem de origem estava OK
(ProductId 01tWK00000G1C4XYAV, Qty 1, UnitPrice 1, CRC).

DESENHO FINAL (caminho nativo escolhido pelo usuário):
- Mapping OOB sem Product2Id (só Quantity/UnitPrice/CurrencyIsoCode).
- Flow before-save carimba Pricebook2Id = book da sociedade (por CompanyCode__c).
- Conversão nativa resolve produto+preço sozinha com a Opp já no C101.

---

# ✅ MAPPING ENRIQUECIDO — DEPLOY OK (16/07)

Deploy do `conversion-fix.zip` bem-sucedido (id 0kFWK00000002Y52AI). O mapping
`LeadItemToOppItemOOBMappings` agora carrega os campos reais (nomes conferidos
no describe, log 07LWK00000PXu9w2AD):

| LeadLineItem (input) | OpportunityLineItem (output) |
|---|---|
| `ProductId`          | `Product2Id`                 |
| `Quantity`           | `Quantity`                   |
| `UnitPrice`          | `UnitPrice`                  |
| `CurrencyIsoCode`    | `CurrencyIsoCode`            |

Cuidado registrado: LeadLineItem usa `ProductId` (não `Product2Id`) e NÃO tem
`Description`. Deploy inicial falhou por isso.

PEÇA 2 pendente — price book por sociedade: a Opp convertida cai no Standard.
Sociedade = campo `CompanyCode__c` (já no Map Lead Fields). Desenho: flow
before-save de Opp (Create) que lê `CompanyCode__c` e carimba `Pricebook2Id`
do book da sociedade (6 books). Decisão pendente: convenção de nome vs
Custom Metadata `Sociedad_Pricebook__mdt` (recomendado). TESTE útil antes:
converter um lead com o produto que também existe no Standard/CRC — se o OLI
aparecer, prova o fix do mapping isolado.

---

# ✅ SUCESSO CONFIRMADO (16/07) — motor da transformação FUNCIONA

Chamada manual da Transformations API criou o OpportunityLineItem
`00kWK000009T8WT` (isSuccess: true, status: Success, errorReason: NULL).
Payload que funcionou:
```json
{
  "inputObjectIds": ["0wkWK0000000O5ZYAU"],
  "inputObjectName": "LeadLineItem",
  "usageType": "TransformationMapping",
  "outputObjectName": "OpportunityLineItem",
  "outputObjectDefaultValues": {
    "OpportunityLineItem": {
      "OpportunityId": "006WK00000ND5j0YAD",
      "CurrencyIsoCode": "CRC",
      "Quantity": 1,
      "TotalPrice": 26900
    }
  }
}
```
Prova definitiva: NUNCA foi bug de plataforma. Todos os vereditos anteriores
de "bug de plataforma" (mantidos abaixo como registro do processo) estão
INCORRETOS. O que faltava era o parâmetro `outputObjectDefaultValues` — que
carrega OpportunityId (target), CurrencyIsoCode (obrigatório em org
multimoeda) e os campos obrigatórios do OLI (Quantity, TotalPrice). A
insistência em voltar à doc oficial do Automotive foi o que destravou.

## CAUSA RAIZ da conversão (zero OLI) e o FIX

O mapping `LeadItemToOppItemOOBMappings` (ObjectHierarchyRelationship) só
carregava `CurrencyIsoCode`. Não carregava Product2Id, Quantity nem UnitPrice.
Na conversão nativa, a plataforma fornece o OpportunityId (target), mas os
demais campos obrigatórios do OLI precisam VIR DO MAPPING — e não vinham.
Resultado: a transformação não conseguia montar um OLI válido → zero OLI.

FIX preparado em `conversion-fix/` — enriquece o mapping com os campos:
Product2Id, Quantity, UnitPrice, Description (+ CurrencyIsoCode que já havia).
Deploy: `conversion-fix/conversion-fix.zip` (atualiza o registro existente
LeadItemToOppItemOOBMappings, não cria novo).

### Passos de validação após o deploy
1. Deploy do `conversion-fix.zip`.
2. Criar lead novo, adicionar 1 LeadLineItem com Product2 + Quantity + UnitPrice.
3. Aguardar o OmniRouting liberar o lead (PendingServiceRouting) — senão dá
   RECORD_IN_USE_BY_WORKFLOW.
4. Converter o lead.
5. Verificar OpportunityLineItem na oportunidade gerada.
6. Se AINDA vier zero OLI mesmo com o mapping completo → hipótese seguinte:
   a conversão nativa não está invocando a transformação (wiring), e aí o
   caminho é o workaround em Flow `Lead_AS_CopiaLineItemsOpp` chamando a
   Transformations API — que agora está PROVADO que funciona.
7. Reativar as automações de desconto (Opp RT Discount Approval +
   Opp_AS_RequestDiscountApproval) que o Santiago desativou nos testes.

---

# ⚠️ REVIRAVOLTA (16/07) — NÃO É BUG DE PLATAFORMA; payload incompleto

A doc oficial do Automotive (Transformations) mostra o parâmetro
`outputObjectDefaultValues` que faltava em TODOS os nossos testes manuais:
```json
"outputObjectDefaultValues": {
  "OpportunityLineItem": { "OpportunityId": "...", "CurrencyIsoCode": "CRC" }
}
```
Com ele, a API PAROU de dar UNKNOWN_EXCEPTION e passou a dar erro limpo:
MISSING_ARGUMENT "{OpportunityLineItem=[Quantity]}". Ou seja, o gack o dia
todo era payload incompleto (sem target Opp + moeda + campos obrigatórios do
OLI), NÃO bug de plataforma. Os vereditos anteriores de "bug de plataforma"
estão INCORRETOS — mantidos abaixo como registro do processo.

CAUSA RAIZ provável: o mapping ObjectHierarchyRelationship está quase vazio
(só CurrencyIsoCode). Não carrega os campos obrigatórios do OLI
(Product/PricebookEntry, Quantity, UnitPrice) do LeadLineItem. Por isso a
conversão real também falha em silêncio (zero OLI). FIX: adicionar mappingFields
dos campos obrigatórios ao ObjectHierarchyRelationship (ProductId, Quantity,
UnitPrice) para a transformação carregá-los na conversão.

Iterando o payload manual (add Quantity, depois UnitPrice/PricebookEntry se
pedir) para provar o motor. Depois: corrigir os mappings e re-testar a conversão.

---

# HU-025 — Conversão de Lead com Line Items e Preferred Sellers (Automotive Cloud)

## CORREÇÃO (16/07) — async industriesintegrationfwk é RED HERRING

Correção de leitura anterior: o job async industriesintegrationfwk.IntegrationHandler
(~9s após conversão, log apex07LWK00000PYeeB2AT) NÃO é a transformação.
A doc oficial mostra que industriesintegrationfwk é o framework do Service
Process Studio / Data Consumption Framework para CALLOUT a sistemas EXTERNOS
(MuleSoft/Named Credential), "enquanto o agente espera" — exemplos Fee Reversal
e Address Update; método central executeCallout(). Requer CRM Plus + Service
Process Studio. A transformação LeadLineItem→OLI é INTERNA (cria registro),
não callout externo. Logo esse async é outra coisa (service process/integração
externa, possivelmente relacionada a MuleSoft/SAP) — red herring para o
problema dos OLI. NÃO usar no case como "mecanismo da transformação".

A transformação continua falhando (provado: manual API gack 918409590; zero
OLI na conversão; FINEST sem eventos de transformação). O ponto exato da
falha fica dentro da camada managed do Automotive, que não conseguimos abrir.
Conclusão inalterada: bug de plataforma. Case + workaround.

Nota separada (backlog): investigar POR QUE um job de Service Process Studio
(industriesintegrationfwk) dispara na conversão se Integration Definitions
está vazio — pode ser outro problema/integração à parte.

---

## EVIDÊNCIA CLINCHER (16/07) — FINEST de conversão nova mostra não-invocação

Conversão fresca do lead "Maduro" (00QWK00000PBeTZ) → Opp 006WK00000NDOs8,
FINEST: account/contact criados, validações Lead+Opp todas PASS,
Lead_AS_EstampaRTOpp ok — e a transação encerra SEM nenhum evento de
transformação (nenhum LeadLineItem read, nenhum OpportunityLineItem DML,
nenhum code unit de transformação). A plataforma NÃO invoca a transformação
na conversão. Log = apex07LWK00000PYcxK2AT. É a evidência mais forte (caminho
real, sem chamada manual/target/pricebook envolvidos).

Achado operacional: criação do lead dispara OmniRouting (Lead_TriggerOmniRouting)
→ cria PendingServiceRouting (0JRWK00000Ff7he) que trava o lead
(RECORD_IN_USE_BY_WORKFLOW) → conversão imediata falha até o routing liberar.
Config da org, não bug — mas relevante para o processo (backlog).

---

## FLANCO PRICE BOOK ELIMINADO (16/07) — 7ª ocorrência

Hipótese: produto em 2 price books ativos (Standard + C101, ambos CRC)
causaria ambiguidade na resolução do PricebookEntry → gack. Testado:
desativada a entry do C101 (01uWK000008Y4B3YAK), deixando só a do Standard
(que casa com o Pricebook2 da Opp 006WK00000ND5j0YAD). API → UNKNOWN_EXCEPTION
65233853-724444 (918409590). Gack persiste com 1 só price book ativo.
Price books ELIMINADOS. (Entry do C101 reativada após o teste.)

Variáveis testadas e eliminadas (lista completa): toggle, permissões (2
usuários), automações da Opp, moeda, mapping multicurrency (CurrencyIsoCode),
mappings duplicados, keyspace estrangeiro, registros nativos, target
Opportunity (lead convertido), ambiguidade de price book. O gack é invariante
a TUDO exceto a existência de um mapping válido para executar. Bug de
plataforma, exaustivamente comprovado. 7 ErrorIds, assinatura 918409590.

---

## ÚLTIMA RESSALVA FECHADA (16/07) — chamada manual TINHA target Opportunity

Query: LeadLineItem 0wkWK0000000O5ZYAU → Lead 00QWK00000PBSaT2AX,
Lead.IsConverted=true, Lead.ConvertedOpportunityId=006WK00000ND5j0YAD.
Logo, a chamada manual da Transformations API SEMPRE teve Opportunity de
destino (via ConvertedOpportunityId) — o gack NÃO era artefato de call
incompleta. Nota: análise paralela (ChatGPT) usou ID digitado errado
(0wkWK00000005zYAU, 17 chars) e recebeu INVALID_INPUT de tipo — nossos
testes usaram o ID correto (0wkWK0000000O5ZYAU, 18 chars).

Escala completa de comportamento da API confirmada:
- ID malformado/tipo errado → INVALID_INPUT (limpo)
- ID válido + 0 mappings    → INVALID_INPUT "specify a mapping" (limpo)
- ID válido + mapping válido → UNKNOWN_EXCEPTION (gack)
Trata toda entrada ruim com erro limpo; só explode ao EXECUTAR. Case airtight.

---

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
