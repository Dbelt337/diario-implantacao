# Runbook — Deploy Workbench: Campos de Precios + Solicitud Cambio Precios (DevSales)

**Pacote:** `deploy_precios_catalogo.zip` · API 63.0 · Metadata API tradicional (package.xml na raiz)

## Paso 0 — Anti-colisão (substitui a Fase 1 da spec; rodar ANTES de qualquer deploy)
Este ambiente não alcança a org (rede bloqueia Salesforce), então os describes viram estas 3 queries no Inspector. Se QUALQUER item abaixo já existir, **NÃO deploye** — me manda o resultado e eu regenero o pacote sem os itens em colisão.

```sql
-- 0.1 Campos custom já existentes na PricebookEntry (conferir contra os 8 do pacote)
SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'PricebookEntry'
```
```sql
-- 0.2 Product2: Make__c / Version__c já existem? (conferir na lista)
SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Product2'
```
```sql
-- 0.3 O objeto Solicitud_Cambio_Precios__c já existe?
SELECT QualifiedApiName, Label FROM EntityDefinition WHERE QualifiedApiName = 'Solicitud_Cambio_Precios__c'
```
Regras de decisão: 0.1 com algum dos 8 → tirar do pacote (alertar se tipo/label divergirem). 0.2 com Make__c/Version__c → remover `Product2.object` e os 2 members do package.xml. 0.3 retornando linha → remover o objeto do pacote e manter só o lookup `Solicitud__c` na PBE.

## Paso 1 — Validação (substitui o dry-run da 3.2)
Workbench → **migration → Deploy**:
- File: `deploy_precios_catalogo.zip`
- ✅ **Check Only** (é o dry-run — NADA é gravado)
- ✅ Single Package · ✅ Rollback on Error
- Conferir ANTES no utilities → sessionInfo que o org Id é `00DWK000005VFeD` (DevSales) — cicatriz de 10/07.
Esperado: 16 componentes success (ou 13/14 se o Paso 0 mandou remover Product2/objeto). Falhou algo → me manda o JSON do resultado.

## Paso 2 — Deploy real
Mesmo zip, mesmas opções, **Check Only DESMARCADO**. Critério de sucesso NÃO é o relatório do deploy: é o Paso 3.

## Paso 3 — Verificação por dados (sempre)
```sql
SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'PricebookEntry' AND QualifiedApiName IN ('PrecioMinimoAsesor__c','PrecioExonerado__c','PrecioExoneradoMinimo__c','Gastos__c','MontoCashback__c','AplicaCashback__c','VigenciaDesde__c','Solicitud__c')
```
```sql
SELECT Id, DeveloperName FROM CustomObject... -- ou simplesmente: SELECT COUNT() FROM Solicitud_Cambio_Precios__c (objeto acessível = criado)
```

## Paso 4 — Pós-deploy manual
1. **Atribuir `PS_Precios_Catalogo`** a quem gerencia precios (o FLS dos 13 campos vem TODO pelo PS — lembrete: campo criado por metadado não dá FLS a ninguém, nem admin).
2. Admin quer ver os campos? Atribuir o PS ao admin também (não tocamos profiles — decisão da spec 2.4).
3. Page layouts: os campos novos NÃO entram em layout sozinhos — adicionar `Solicitud__c` + precios no layout da PricebookEntry e montar o layout do objeto novo (Estado, Tipo, Marca, Sociedad, Comentario).
4. Tab do objeto (se quiser navegação): Setup → Tabs → New (a spec não incluiu CustomTab de propósito).

## Avisos
- `Estado__c` e `Tipo__c` foram gerados como picklists **restritas** (não estava na spec — remover `<restricted>` se quiserem valores livres).
- Currency "16,2" da spec foi mapeado para `precision 18 / scale 2` = **Currency(16,2) na UI** (precision do metadado = dígitos totais). Literal 16/2 criaria Currency(14,2).
- O nome correto do objeto standard é `PricebookEntry` (a spec grafou "PriceBookEntry" — corrigido, não é invenção de nome).
