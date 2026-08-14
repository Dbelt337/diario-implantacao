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

## Describe de `WorkType` em produção

Campos obrigatórios e graváveis (`IsNillable = false`):
`Name`, `DurationType`, `EstimatedDuration`, `ShouldAutoCreateSvcAppt`,
`OwnerId`, `FSL__Exact_Appointments__c`.

Lookups: apenas `OwnerId` → `User`,`Group` (obrigatório) e
`ServiceReportTemplateId` → `ServiceReportLayout` (opcional, vazio nos 49
registros). **`WorkType` não tem lookup para `OperatingHours`.**

### ⚠️ A chave da integração é `ServiceTypeKey__c`, não `Name`

Campo customizado **`ServiceTypeKey__c`** — rótulo "Chave do Tipo de
Atendimento", tipo **Formula (Text)**. Valores normalizados, sem acento e sem
espaço:

```
ReparoBandaLargaCritica
ManutencaoCorporativoDadosAlta
ReparoCorporativoBandaLargaSemSinalCritica
ServicoBandaLargaAlta
```

É o formato que uma integração envia. Fórmula deduzida dos dados:

```
ServiceTypeKey__c = MacroCategory__c + Product__c + SubCategory__c + Criticality__c
SkillType__c      = MacroCategory__c + Product__c + Criticality__c
```

Conferência: `ReparoCorporativo` + `BandaLarga` + `SemSinal` + `Critica`
→ `ReparoCorporativoBandaLargaSemSinalCritica`.

**Consequência para a carga:** campos fórmula são somente leitura e **não podem
ser carregados**. Carregar apenas `Name`, `DurationType` e `EstimatedDuration`
faz os registros entrarem na QA com a chave vazia — e a integração continua
falhando. É obrigatório carregar as picklists de origem:

| Campo | Rótulo |
|---|---|
| `MacroCategory__c` | Macro Categoria |
| `Product__c` | Produto |
| `SubCategory__c` | Sub Categoria |
| `Criticality__c` | Críticidade |

Com as quatro corretas, a chave se monta sozinha.

`SkillType__c` repete entre registros por construção (não inclui
`SubCategory__c`) — serve para match de habilidade, não como chave única.

### ⚠️ Duplicidade na chave de integração

```
08qV2000000RVkdIAG  Preventiva - Banda Larga - Média  criado 31/03/2026        2 Hours / 120 min
08qV2000000TgqHIAS  Preventiva - Banda Larga - Média  criado 13/08/2026 13:32  1 Hour  /  60 min
```

Ambos com **`ServiceTypeKey__c = PreventivaBandaLargaMedia`**. Não é só o `Name`
duplicado: a própria chave de integração está ambígua. Com `records[0]`, a
escolha é não determinística e as durações divergem — 120 contra 60 minutos.

O segundo foi criado **no mesmo dia deste diagnóstico**, pelo usuário
`005V200000KsviXIAR`, que também criou "Preventiva - Banda Larga - Alta" às
13:43. Há alteração ativa nos WorkTypes de produção; alinhar antes de replicar a
ambiguidade na QA.

```sql
-- duplicidade por chave de integração
SELECT ServiceTypeKey__c, COUNT(Id)
FROM WorkType GROUP BY ServiceTypeKey__c HAVING COUNT(Id) > 1
```

### Convenção de nome inconsistente

| Padrão A | Padrão B |
|---|---|
| `Reparo - Banda Larga - Crítica` | `Reparo Corporativo -BandaLarga - Critica` |
| espaços em volta do traço, com acento | sem espaço após o traço, sem acento |

Relevante apenas se o lookup for por `Name`. Como `ServiceTypeKey__c` é
normalizado, ele é o candidato mais provável — **confirmar no payload da
composite**.

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

> `FieldDefinition` **não aceita `IN` com vários objetos** — um `IN` de sete
> entidades devolve `UNEXPECTED EXCEPTION: Forbidden: The requested operation is
> not yet supported by this sObject storage type`. Consultar um objeto por vez.

As linhas com `DataType` = `Lookup` ou `Master-Detail` definem as dependências
de carga: o `ReferenceTo` diz quais objetos precisam existir antes.

Para saber o que é **carregável**, `FieldDefinition` não basta — use
`EntityParticle`:

```sql
-- Tooling API
SELECT QualifiedApiName, DataType, IsCreatable, IsUpdatable, IsCalculated, IsNillable
FROM EntityParticle
WHERE EntityDefinition.QualifiedApiName = 'WorkType'
ORDER BY QualifiedApiName
```

`IsCreatable = true` **e** `IsCalculated = false` é a lista exata da carga.

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

Lista confirmada por `EntityParticle` (`IsCreatable = true` e
`IsCalculated = false`):

```sql
SELECT Name, DurationType, EstimatedDuration, ShouldAutoCreateSvcAppt,
       FSL__Exact_Appointments__c,
       MacroCategory__c, Product__c, SubCategory__c, Criticality__c,
       RootCase__c, Skill__c
FROM WorkType
```

**`OwnerId` fica fora de propósito.** É obrigatório, mas os Ids de usuário de
produção não existem na QA; sem ele no arquivo o Salesforce atribui ao usuário
que executa a carga. Incluir os Ids de prod quebra o import.

**Nunca carregar** — a plataforma rejeita:

| Campo | Motivo |
|---|---|
| `ServiceTypeKey__c` | `IsCalculated = true` |
| `SkillType__c` | `IsCalculated = true` |
| `DurationInMinutes` | `IsCreatable = false`, `IsUpdatable = false` — derivado de `DurationType` × `EstimatedDuration` (2 Hours → 120; 1 Hour → 60) |

Omitidos por estarem vazios nos 49 registros: `Description`, `MinimumCrewSize`,
`RecommendedCrewSize`, `WoDocumentTemplate`, `WoliDocumentTemplate`,
`SaDocumentTemplate`, `FSL__Due_Date_Offset__c`, `ServiceReportTemplateId`,
`CostCenterId`, `JobExpenseTypeId`.

> `CostCenterId` e `JobExpenseTypeId` aparecem em `EntityParticle` mas **não** em
> `FieldDefinition` nem em `FIELDS(ALL)`. Para planejar carga, a autoridade é
> `EntityParticle`.

#### A carga não tem dependência de outros objetos

Confirmado nos 49 registros exportados:

- **`ShouldAutoCreateSvcAppt = false` em todos** — nenhum `ServiceAppointment` é
  criado automaticamente, logo `ServiceTerritory` **não** é pré-requisito
- **Nenhum lookup preenchido** entre os 11 campos — não há Id a resolver entre orgs

O único pré-requisito são os valores de picklist.

#### ⚠️ A QA está atrasada em metadados

Verificado em 14/08/2026 via `Schema.SObjectType.WorkType.fields.getMap()`:

| Campo | QA |
|---|---|
| `MacroCategory__c`, `Product__c`, `SubCategory__c`, `Criticality__c` | ok |
| `RootCase__c`, `ServiceTypeKey__c`, `SkillType__c` | ok |
| **`Skill__c`** | **ausente** |

`Skill__c` não compõe `ServiceTypeKey__c`, então a carga funciona sem ele —
basta removê-lo do construtor. Perde-se a informação de habilidade em 2 dos 49
registros.

Mas o sintoma é maior que o campo: só oito campos foram testados, e a QA está
defasada em relação à produção. `Skill__c` é recente — só aparece preenchido nos
registros criados em 11 e 12/08/2026, depois do último refresh. **Um deploy de
metadados prod→QA fica pendente no backlog**, senão o próximo teste esbarra em
outro campo.

Script de verificação:

```apex
Map<String, Schema.SObjectField> m = Schema.SObjectType.WorkType.fields.getMap();
for (String f : new List<String>{'MacroCategory__c','Product__c','SubCategory__c',
     'Criticality__c','RootCase__c','Skill__c','ServiceTypeKey__c','SkillType__c'}) {
  System.debug(f + ' -> ' + (m.containsKey(f.toLowerCase()) ? 'ok' : '*** FALTA ***'));
}
```

#### Execute Anonymous pelo Inspector estoura o cabeçalho

O Salesforce Inspector executa Apex anônimo via **GET** na Tooling API, com o
código na query string. O script completo dá **17 KB codificados** contra um
limite de ~8 KB — os 80 caracteres acentuados dos nomes pesam sozinhos, já que
cada `ç` ou `ã` vira 6 a 9 caracteres.

Resultado: `HTTP ERROR 431 Request Header Fields Too Large`.

Use o **Developer Console** (`Debug → Open Execute Anonymous Window`), que envia
por SOAP POST sem esse limite, ou `sf apex run --file`. Para insistir no
Inspector, quebrar em blocos de ~25 registros mantendo cada um sob 5 KB
codificados, com skip por nome para que sejam reexecutáveis.

#### Resultado da carga (14/08/2026)

**46 dos 48 registros carregados.** Faltam `Serviço - Banda Larga - Aferição
Velocidade` e `Serviço - Câmera - Alta`.

Erro na tentativa dos dois:

```
INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, bad value for restricted
picklist field: BandaLarga: [Product__c]
```

Enganoso: `BandaLarga` **existe** na QA e foi carregado seis vezes sem problema.
O describe explica:

```
Product__c | restrita=true | dependente=true (controlador: MacroCategory__c)
```

`Product__c` é restrita **e dependente** de `MacroCategory__c`. Não falta valor —
falta a **dependência**: sob o controlador `Servico`, os produtos `BandaLarga` e
`Camera` não estão habilitados na matriz da QA. Os registros `Servico` são os
mais novos de produção (11 e 12/08/2026), posteriores ao último refresh.

Correção: `Setup → Object Manager → Work Type → Fields & Relationships →
Product__c → Field Dependencies → Edit`, incluir `BandaLarga` e `Camera` na
coluna `Servico`. Comparar com a mesma tela em produção.

Consequência enquanto não for corrigido: a integração não encontra
`ServicoBandaLargaAlta` nem `ServicoCameraAlta`. Qualquer outro tipo funciona.

> **Lição:** "o valor existe na picklist" não basta quando a picklist é
> dependente. O `INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST` aponta o campo e o
> valor, mas não diz que o problema está na combinação com o controlador.

Script de inspeção de picklists:

```apex
Map<String, Schema.SObjectField> m = Schema.SObjectType.WorkType.fields.getMap();
for (String f : new List<String>{'MacroCategory__c','Product__c','SubCategory__c',
                                 'Criticality__c','RootCase__c'}) {
  Schema.DescribeFieldResult d = m.get(f.toLowerCase()).getDescribe();
  List<String> vs = new List<String>();
  for (Schema.PicklistEntry pe : d.getPicklistValues()) if (pe.isActive()) vs.add(pe.getValue());
  System.debug(f + ' | restrita=' + d.isRestrictedPicklist()
    + ' | dependente=' + d.isDependentPicklist()
    + (d.isDependentPicklist() ? ' (controlador: ' + d.getController().getDescribe().getName() + ')' : '')
    + ' | ' + vs);
}
```

#### Pré-requisito: valores de picklist na QA

Se as picklists forem restritas, valor ausente derruba a linha. Pior: se
`SubCategory__c` entrar vazio, a fórmula `ServiceTypeKey__c` sai diferente da de
produção e a integração continua falhando **mesmo com os 49 registros
carregados**.

Valores em uso em produção:

| Campo | Valores |
|---|---|
| `MacroCategory__c` | `Instalacao`, `Reparo`, `Manutencao`, `Preventiva`, `Servico`, `ReparoCorporativo`, `ManutencaoCorporativo` |
| `Product__c` | `BandaLarga`, `TV`, `TelefoniaFixa`, `Telefonia`, `Camera`, `CFTV`, `Dados` |
| `SubCategory__c` | `SemSinal` |
| `Criticality__c` | `Critica`, `Alta`, `Media`, `Baixa` |
| `RootCase__c` | `LOS (00)`, `Atividade de Verificação (28)` |
| `Skill__c` | `Indoor` |

Conferir em `Setup → Object Manager → Work Type` ou pelo field info do Inspector.

#### Validação após a carga

```sql
SELECT ServiceTypeKey__c, Name FROM WorkType ORDER BY ServiceTypeKey__c
```

As chaves geradas devem bater uma a uma com as de produção. Divergência aqui
significa picklist de origem errada.

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

### Script pronto

```bash
./scripts/load-worktype.sh <alias-da-org> --dry-run   # inspeciona sem carregar
./scripts/load-worktype.sh <alias-da-org>             # carrega e valida
```

Arquivo de carga: `data/worktype/WorkType.csv` — 49 registros, 11 colunas,
extraídos de produção em 13/08/2026.

O script:

1. **Recusa carregar fora de sandbox.** Consulta `Organization.IsSandbox` e
   aborta se for produção (só prossegue com `ALLOW_PRODUCTION=1` **e** `--force`)
2. Aborta se a org já tiver WorkTypes, para não duplicar (contornável com
   `--force`)
3. Avisa sobre colisões de `ServiceTypeKey__c` no CSV antes de carregar
4. Carrega via `sf data import bulk`
5. **Valida**: compara as chaves geradas na org com as calculadas a partir do
   CSV. Divergência aponta valor de picklist ausente ou diferente no destino

Requer o Salesforce CLI autenticado. Roda em Linux, macOS, WSL e Git Bash; não
depende de `jq`.

### Regeneração do CSV

Para atualizar o arquivo a partir de produção:

```sql
SELECT Name, DurationType, EstimatedDuration, ShouldAutoCreateSvcAppt,
       FSL__Exact_Appointments__c,
       MacroCategory__c, Product__c, SubCategory__c, Criticality__c,
       RootCase__c, Skill__c
FROM WorkType
```

### Alternativa via sf data export tree

Ids não são portáveis entre orgs (os `08qV2...` de produção não existem na QA).
`sf data export tree` gera um plano que resolve as referências:

```bash
sf data export tree \
  -q "SELECT Name, DurationType, EstimatedDuration, ShouldAutoCreateSvcAppt, \
             FSL__Exact_Appointments__c, MacroCategory__c, Product__c, \
             SubCategory__c, Criticality__c, RootCase__c, Skill__c \
      FROM WorkType" \
  -o prod -d ./data/worktype -p

sf data import tree -p ./data/worktype/*-plan.json -o qa
```

Versionar o diretório `./data` para que a carga seja reexecutável após cada
refresh de sandbox.

---

## Depois da carga: `ExternalIDVoalle__c`

Com os WorkTypes carregados, o teste da composite avançou — o lookup passou e o
erro mudou:

```
antes:  [WorkOrder | PROCESSING_HALTED] No value for WorkType.records[0].Id
depois: [WorkOrder | INVALID_FIELD] No such column 'ExternalIDVoalle__c'
```

### Não é defasagem de sandbox

Comparação dos campos custom de `WorkOrder` nas duas orgs:

| Org | Campos custom |
|---|---|
| Produção | 97 |
| QA | 97 |

**Listas idênticas, zero diferenças.** `ExternalIDVoalle__c` não existe em
nenhuma das duas — deploy não resolve, não há o que copiar.

Campos relacionados que existem em ambas:

```
voallecategory1__c … voallecategory5__c   categorias do Voalle
externalidzendesk__c                      external id, mas do Zendesk
vlocity_cmt__externalworkordernumber__c   numero externo da ordem
contractlineitemexternalid__c, protocolid__c, workorderuniquenumber__c
```

As categorias do Voalle foram criadas, o external id não. Ou falta criar o campo,
ou o payload deveria gravar em outro destino — `vlocity_cmt__ExternalWorkOrderNumber__c`
é o candidato mais natural. Decisão do time de integração.

Script usado (rodar nas duas orgs; identifica a org no próprio log):

```apex
Organization o = [SELECT Name, IsSandbox FROM Organization LIMIT 1];
List<String> fs = new List<String>();
for (String f : Schema.SObjectType.WorkOrder.fields.getMap().keySet())
  if (f.endsWith('__c')) fs.add(f);
fs.sort();
System.debug(o.Name + ' | IsSandbox=' + o.IsSandbox + ' | ' + fs.size()
  + ' custom: ' + String.join(fs, ', '));
```

### Escopo real da defasagem QA↔produção

Confirmado apenas em `WorkType`:

- `Skill__c` existe em produção e falta na QA
- dependência `Servico` → `BandaLarga`/`Camera` ausente na matriz da QA

`WorkOrder` está sincronizado. O deploy pendente é
`CustomObject:WorkType`, **não** `WorkOrder`.

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
