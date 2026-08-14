# Carga de dados Field Service na QA — destravar composite WorkOrder

**Sandbox:** `qabrasiltecpar--qa` (`diegomoraes.t@brasiltecpar.com.br.qa`)
**Data:** 13/08/2026
**Origem:** falha da integração order-papi → btp-salesforce-sapi-qas

---

## O erro

```json
{
  "code": "400",
  "reason": "COMPOSITE_REQUEST_FAILED",
  "message": "[WorkOrder | PROCESSING_HALTED] Invalid reference specified. No value for
              WorkType.records[0].Id found in WorkType."
}
```

A composite encadeia duas subrequisições: uma consulta `WorkType` (referenceId
`WorkType`), a seguinte cria o `WorkOrder` referenciando `@{WorkType.records[0].Id}`.
A consulta **retornou zero registros**, então a referência não resolveu.

A segunda metade da mensagem — *"must start with a letter or a number"* — é ruído.
Quando a referência não resolve, o Salesforce trata a string inteira como um
`referenceId` literal e reclama do ponto e do colchete. **O payload está correto.**

Com `allOrNone: true`, nada foi gravado.

### Confirmação

| Org | `SELECT Id, Name FROM WorkType` |
|---|---|
| QA (`...brasiltecpar.com.br.qa`) | **0 registros** |
| Produção | **49 registros** |

Não é permissão: se o Field Service estivesse desabilitado ou o objeto inacessível,
a query retornaria `INVALID_TYPE` em vez de vazio. O Run As é System Administrator.

---

## Por que a QA está vazia — e voltará a ficar

`WorkType` é **dado**, não metadado. Sandboxes **Developer** e **Developer Pro**
copiam apenas metadados. Todo refresh zera esses registros.

A solução precisa ser um **script reexecutável**, não um insert manual.
Confirmar o tipo em `Setup → Sandboxes`; se for **Partial Copy**, incluir esses
objetos num sandbox template resolve na origem.

---

## ⚠️ Dois problemas nos dados de produção

### 1. Nome duplicado

"Preventiva - Banda Larga - Média" existe duas vezes:

- `08qV2000000RVkdIAG`
- `08qV2000000TgqHIAS`

Se a composite filtra por `Name` e usa `records[0]`, a escolha entre os dois é
**não determinística**. É bug latente em produção, não apenas na QA.

```sql
SELECT Name, COUNT(Id) FROM WorkType GROUP BY Name HAVING COUNT(Id) > 1
```

### 2. Convenção de nome inconsistente

| Padrão A | Padrão B |
|---|---|
| `Reparo - Banda Larga - Crítica` | `Reparo Corporativo -BandaLarga - Critica` |
| espaços em volta do traço, com acento | sem espaço após o traço, sem acento, sem espaço interno |

Para lookup por nome exato, acento e espaçamento são significativos. **Confirmar
com o time de integração se o filtro da composite é por `Name`** — se for, os
nomes precisam bater caractere a caractere entre prod e QA.

---

## Mapa de dependências

```
metadados (deploy)          dados (carga)
─────────────────           ─────────────
Skill ─────────────────┐    OperatingHours ──> ServiceTerritory
RecordType             │                            │
picklists              │         WorkType   ← o que falta
                       │            │
                       └──> SkillRequirement ───────┤
                            ProductRequired ────────┤ (precisa Product2)
                            WorkTypeGroupMember ────┤ (precisa WorkTypeGroup)
                            ServiceTerritoryWorkType┘ (precisa ServiceTerritory)
```

`OperatingHours` é pré-requisito de `ServiceTerritory`, **não** de `WorkType`.
As dependências diretas de `WorkType` devem ser confirmadas pelo describe —
ver a regra na seção seguinte.

Para o `WorkOrder` criado pela composite, conforme o payload:
`Account`, `Contact`, `Asset`/`Case`, `ServiceTerritory`, `Pricebook2`,
RecordType e valores de picklist de `Status` / `Priority`.

**Atenção:** se algum WorkType tiver `ShouldAutoCreateSvcAppt = true`, criar o
WorkOrder dispara criação automática de `ServiceAppointment`, que exige
`ServiceTerritory` configurado. Isso amplia a carga mínima.

---

## Regra: descrever o objeto antes de escrever a query

Nunca escrever nome de campo de memória — gera `INVALID_FIELD`. A documentação
oficial também não basta: ela não conhece os campos customizados do org nem a
versão de API em uso. **A fonte autoritativa é o describe do próprio org.**

```sql
-- marcar "Tooling API" no Inspector
SELECT QualifiedApiName, Label, DataType, IsNillable, ReferenceTo
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'WorkType'
ORDER BY QualifiedApiName
```

Retorna nome de API, tipo, obrigatoriedade e destino dos lookups. Trocar
`'WorkType'` para qualquer outro objeto.

As linhas com `DataType` = `Lookup` ou `Master-Detail` definem as dependências
de carga: o `ReferenceTo` diz quais objetos precisam existir antes.

Atalho equivalente na UI: botão **"WorkType Field Info"** do Salesforce Inspector.

Quando o objetivo é ler os dados sem se comprometer com nomes de campo:

```sql
SELECT FIELDS(ALL) FROM WorkType LIMIT 200
```

`FIELDS(ALL)` nunca produz `INVALID_FIELD`.

> **Erro registrado:** a primeira versão deste documento usava
> `WorkType.OperatingHoursId`, campo que **não existe** nesse objeto — o
> relacionamento com `OperatingHours` está em `ServiceTerritory`, não em
> `WorkType`. O nome foi assumido de memória em vez de descrito. Daí a regra
> acima.

---

## Inventário — rodar em PRODUÇÃO

```sql
-- todos os campos dos 49 WorkTypes
SELECT FIELDS(ALL) FROM WorkType LIMIT 200
```

```sql
SELECT Id, WorkTypeId, WorkType.Name, WorkTypeGroupId, WorkTypeGroup.Name
FROM WorkTypeGroupMember
```

```sql
-- RelatedRecordId é polimórfico; 08q é o prefixo de WorkType
SELECT Id, RelatedRecordId, SkillId, Skill.MasterLabel, SkillLevel
FROM SkillRequirement WHERE RelatedRecordId LIKE '08q%'
```

```sql
SELECT Id, ParentRecordId, Product2Id, Product2.Name, QuantityRequired
FROM ProductRequired WHERE ParentRecordId LIKE '08q%'
```

```sql
SELECT Id, ServiceTerritoryId, ServiceTerritory.Name, WorkTypeId
FROM ServiceTerritoryWorkType
```

```sql
SELECT Id, Name, OperatingHoursId, OperatingHours.Name, ParentTerritoryId, IsActive
FROM ServiceTerritory
```

```sql
SELECT Id, Name, TimeZone FROM OperatingHours
```

Rodar as mesmas na QA para o diff do que falta.

---

## Ordem de carga

### Mínimo para destravar a composite

1. Rodar o `FieldDefinition` acima e conferir os lookups obrigatórios de
   `WorkType` (`IsNillable = false` + `DataType` de referência); carregar antes
   o que aparecer
2. **`WorkType`** — os 49 registros

Isso já faz a subrequisição de lookup retornar registro e a composite passar.

### Completo, para o fluxo funcionar de ponta a ponta

3. `Skill` — **metadado**, vai por deploy, não por carga
4. `ServiceTerritory` (depende de `OperatingHours`)
5. `WorkTypeGroup`
6. `Product2` (+ `PricebookEntry`) — se houver `ProductRequired`
7. Junções: `WorkTypeGroupMember`, `SkillRequirement`, `ProductRequired`,
   `ServiceTerritoryWorkType`
8. Dados do `WorkOrder`: `Account`, `Contact`, `Asset` / `Case` conforme o payload

---

## Execução

Ids não são portáveis entre orgs (os `08qV2...` de produção não existem na QA).
`sf data export tree` gera um plano que resolve as referências:

```bash
sf data export tree \
  -q "SELECT Name, DurationType, EstimatedDuration, Description, ShouldAutoCreateSvcAppt FROM WorkType" \
  -o prod -d ./data/worktype -p

sf data import tree -p ./data/worktype/*-plan.json -o qa
```

Versionar o diretório `./data` para que a carga seja reexecutável após cada
refresh de sandbox.

---

## Pendências

- [ ] Obter o **payload completo da composite** com o time de integração — o filtro
      da query de `WorkType` diz qual registro é esperado e se o match é por `Name`
- [ ] Confirmar o **tipo da sandbox** QA (`Setup → Sandboxes`)
- [ ] Decidir o que fazer com a **duplicidade** "Preventiva - Banda Larga - Média"
      em produção
- [ ] Verificar se algum WorkType tem `ShouldAutoCreateSvcAppt = true`

## Melhorias do lado da integração

- Tratar retorno vazio do lookup e devolver erro de negócio legível
  ("WorkType X não encontrado") em vez de `PROCESSING_HALTED`
- Corrigir o error handler DataWeave (linha 11: seletor `.details` sobre payload
  `Binary`), que quebra quando o destino responde com corpo vazio e mascara o
  erro real como `Expression 500`
- Configurar `responseTimeout` na chamada order-papi → sapi (hoje usa o default
  de 30s do Mule)

---

## Fontes

- [WorkType — Field Service Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.field_service_dev.meta/field_service_dev/sforce_api_objects_worktype.htm)
- [WorkTypeGroup — Field Service Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.field_service_dev.meta/field_service_dev/sforce_api_objects_worktypegroup.htm)
- [Field Service Core Data Model](https://developer.salesforce.com/docs/platform/data-models/guide/field-service-core-data-model.html)
- [Work Type Fields for Field Service](https://help.salesforce.com/s/articleView?id=service.fs_work_type_fields.htm&language=en_US&type=5)
- [Guidelines for Creating Work Types](https://help.salesforce.com/s/articleView?id=sf.fs_work_type_guidelines.htm&language=en_US&type=5)
