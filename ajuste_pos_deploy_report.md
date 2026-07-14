# Ajuste Pós-Deploy — Precios/Catálogo DevSales (fase 2) · 14/07

**Gate (regra 1):** sem sf CLI/rede Salesforce neste ambiente (403 de política — provado hoje) → describes e escrita de dados viraram passos Inspector para o arquiteto; pacotes saíram como zip (dry-run = Check Only do Workbench). Nada foi deployado daqui (regra 2 respeitada por construção).

## 0. MUDANÇA DE ORDEM SUPERIOR: "não podemos criar objeto novo"
O deploy 20/20 criou `Solicitud_Cambio_Precios__c`, mas a decisão pós-deploy é REMOVÊ-LO. O delete via UI falhou ("other objects have relationships") porque `PricebookEntry.Solicitud__c` aponta para ele.
**Solução: `deploy/precios_ajuste/remove_solicitud/Remove_Solicitud.zip`** — destructive dos DOIS (lookup + objeto) numa tacada. Workbench: Single Package ✅ · Check Only ☐ · Rollback ✅ (ambos existem, sem warnings esperados). O `PS_Precios_Catalogo` NÃO bloqueia e se auto-limpa das referências; ele continua valendo pelo FLS dos 7 campos restantes.
Prova pós-delete: `SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName='PricebookEntry'` → sem `Solicitud__c`; Object Manager sem o objeto.
**Consequência de desenho:** a auditoria de cambios de precio fica SEM cabeçalho → o history tracking da PBE (Fase 3) deixa de ser opcional e vira o mecanismo governante. Se a plataforma recusar history em PBE, decisão a escalar: viver só com auditoria implícita (SetupAuditTrail não cobre dados) ou usar um objeto EXISTENTE como cabeçalho (Case, p.ex.) — anotado como TODO-PRECIOS-01.

## 1. Auditoria do que caiu (1.1–1.4) — VERSÃO PÓS-DELETE
Estado esperado após o delete de 14/07: **7 campos** na PBE (Solicitud__c fora), objeto inexistente.

**A1 — PBE com exatamente os 7 (e sem cadáver):**
```sql
SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'PricebookEntry'
```
Esperado: PrecioMinimoAsesor/PrecioExonerado/PrecioExoneradoMinimo/Gastos/MontoCashback (Currency 16,2), AplicaCashback (Checkbox), VigenciaDesde (Date). NÃO deve aparecer `Solicitud__c` nem `Solicitud_del__c` (se `_del` aparecer, o Erase não foi feito).

**A2 — objeto fora:** `SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName = 'Solicitud_Cambio_Precios__c'` → vazio.

**A3 — Product2:** `SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Product2'` → contém Make__c e Version__c (Text 80).

**A4 — PS íntegro pós-delete (a exclusão limpa as entradas do objeto sozinha):**
```sql
SELECT SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name = 'PS_Precios_Catalogo')
```
Esperado: 7 linhas PricebookEntry r/w; zero linhas de Solicitud_Cambio_Precios__c.

Divergências conhecidas (D2/D3 no `package_report.md`): picklists restritas, Currency 18/2.

## 2. Pós-deploy operacional — passos Inspector (dados, idempotentes)
2.1 **Atribuir PS**: Setup → Permission Sets → PS Precios Catalogo → Manage Assignments → seu usuário (skip se já).
2.2 **Pricebook C101** (query-first): `SELECT Id, Name, IsActive FROM Pricebook2` → se não houver `C101%`, importar `carga_catalogo/1_pricebook2_C101.csv` (Inspector → Data Import → Insert Pricebook2). Confirmar Standard ativo (IsStandard=true, IsActive=true; update se preciso).
2.3 **Carga da amostra** (fallback 6 filas embutido — a Amostra_Catalogo_HyundaiCR.xlsx não está na sessão). Ordem OBRIGATÓRIA, tudo query-first pela chave lógica ProductCode:
    a) `2_product2.csv` → Insert Product2. Depois `SELECT Id, ProductCode FROM Product2 WHERE Make__c='Hyundai'` e copiar os Ids.
    b) `3_vehicledefinition.csv` → preencher `<ID_PRODUCT2>` pela referência de ProductCode e Insert VehicleDefinition. Se o describe do VehicleDefinition exigir campos que não temos (Q3b pendente!), pular a onda b e registrar — não inventar.
    c) `4_pbe_standard.csv` → preencher `<ID_PRODUCT2>` e `<ID_STANDARD_PB>` (`SELECT Id FROM Pricebook2 WHERE IsStandard=true`) → Insert PricebookEntry. **SÓ DEPOIS** `5_pbe_c101.csv` (preencher `<ID_PB_C101>`) — ordem invertida = STANDARD_PRICE_NOT_DEFINED. Coluna `__ProductCode_referencia` é guia: REMOVER antes do import. Multicurrency confirmado na org → CurrencyIsoCode=USD mantido; se a Standard PB não tiver USD ativa, o insert acusa — ativar a moeda ou trocar para a moeda corporativa.
    ExonMin/MontoCashback vazios de propósito (completam na carga real).
2.4 **Smoke test** (deixar os registros — são a demo): Opp com RT `GQOpportunitiesAutos` + Quote com Pricebook C101 + QLI do Accent Sport 2025 → esperado UnitPrice=28900 e `SELECT Id, UnitPrice, PricebookEntry.PrecioMinimoAsesor__c, PricebookEntry.PrecioExonerado__c, PricebookEntry.Gastos__c, PricebookEntry.VigenciaDesde__c FROM QuoteLineItem WHERE Quote.OpportunityId='<OPP_ID>'` lendo 24900/20100/1500/2026-08-01 por travessia.

## 3. Pacote history PBE — DEPLOYADO ✅ (14/07)
**VEREDITO: a plataforma ACEITOU history na PricebookEntry** — enableHistory + trackHistory nos 7 campos no ar. O field history da PBE é oficialmente a auditoria governante dos cambios de precio (TODO-PRECIOS-01 RESOLVIDO — não precisa de cabeçalho). Consulta da trilha: `SELECT ParentId, Field, OldValue, NewValue, CreatedBy.Name, CreatedDate FROM PricebookEntryHistory ORDER BY CreatedDate DESC`.

### (histórico) Pacote gerado
`enableHistory` no PricebookEntry + `trackHistory=true` nos **7** campos (Solicitud__c fora — está sendo removido). Dry-run impossível daqui → **rodar com Check Only ✅ primeiro**: se a plataforma recusar history em PBE, o erro literal encerra a dúvida (colar aqui) e vale o TODO-PRECIOS-01; se passar, deploy real.
⚠️ Rodar o history SÓ DEPOIS do Remove_Solicitud (o .object do history não traz Solicitud__c — se o lookup ainda existir, ele sobrevive, mas a ordem limpa evita confusão de estado).

## 4. Campos do Order — DEPLOYADO ✅ (14/07, via Cockpit_Fase1_4.zip)
Campos SAP + Quote__c + motores Opp_AS_GenerarPedido (universal, adendo) e Order_AS_ActivarPorFactura no ar. Pendências manuais: FLS SAP_* no PS_Api (UI) + leitura no PS_Base_Sales_GrupoQ.

### (histórico) Nota original
`SAP_OrderNumber__c`/`SAP_FacturaRef__c`/`SAP_SyncStatus__c` (+`Quote__c`) estão no **`deploy/cockpit_fase1_4/Cockpit_Fase1_4.zip`** com os dois motores — que já incorporam o ADENDO (gate IsWon+quote, exclusão explícita só do Mayorista, sem lista de inclusão). Não gerei pacote duplicado. FLS de integração: adicionar os SAP_* ao `PS_Api` NA UI (PS por pacote é full-replace — cicatriz).

## Execução do delete (14/07 — CONCLUÍDO ✅)
Sequência real que funcionou (lição para o diário):
1. Destructive combinado (lookup+objeto na mesma transação) → **gack** (ErrorId 814372279-535264) — não repetir esse formato.
2. `Remove_Paso1_Campo.zip` → success, lookup deletado (virou `Solicitud_del__c` em Deleted Fields).
3. **Campo deletado ≠ campo morto**: o `_del` em Deleted Fields AINDA conta como relação e seguiu bloqueando o delete do objeto → **Erase manual** (Object Manager → Pricebook Entry → Deleted Fields → Erase).
4. Delete do objeto na UI → OK. Arquiteto confirmou: **objeto removido**, veto "não podemos criar objeto novo" cumprido.
`PS_Precios_Catalogo` permanece válido com o FLS dos 7 campos de precio restantes (referências ao objeto se auto-limparam).

## 5. TODOs nomeados
- ~~TODO-PRECIOS-01~~ ✅ RESOLVIDO 14/07: PBE aceitou history — auditoria governante garantida.
- TODO-PRECIOS-02: ~~prova do delete~~ ✅ (confirmado pelo arquiteto); resta colar o smoke test.
- TODO-PRECIOS-03: carga real do catálogo SAP (substitui o fallback; chave ProductCode; decidir external Id definitivo para o Mule). **Moeda (14/07): org tem só CRC ativa (corporativa, taxa 1) — a amostra entrou em CRC com valores nominais de USD (ok p/ demo). Na carga real: lista por país decide — valores reais em CRC, OU ativar USD antes se CR precifica em dólar. CSVs de carga ficaram sem coluna CurrencyIsoCode (herdam a moeda da org).**
- TODO-PRECIOS-04: onda VehicleDefinition depende do describe (Q3b) — validar campos aceitos.
