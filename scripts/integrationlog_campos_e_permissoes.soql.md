# IntegrationLog__c — Diagnóstico de campos e permissões de escrita

Consultas para investigar o erro de gravação do log de integração (POST composite
com `Name: null` e campos de contexto vazios). Rode com o `sf` CLI:

```bash
sf data query -o <alias-da-org> --query "<SOQL abaixo>"
```

> As consultas 1 e 2 usam objetos de metadados (EntityParticle/FieldDefinition) —
> se o seu usuário não os enxergar, use o script Apex `check_integrationlog_fields.apex`,
> que traz a mesma informação via Schema Describe.

---

## 1. Campos do objeto: tipo, obrigatoriedade e se aceitam escrita via API

```sql
SELECT QualifiedApiName, Label, DataType, Length,
       IsNillable, IsCreatable, IsUpdatable
FROM EntityParticle
WHERE EntityDefinition.QualifiedApiName = 'IntegrationLog__c'
ORDER BY QualifiedApiName
```

Como ler o resultado:
- `IsNillable = false` **e** `IsCreatable = true` → campo obrigatório no insert.
  Se `Name` aparecer assim, o POST com `"Name": null` falha com `REQUIRED_FIELD_MISSING`.
- Se `Name` tiver `IsCreatable = false`, ele é Auto Number (Salesforce gera o valor)
  e o `null` do payload é ignorado — não é a causa do erro.

## 2. Confirmação do tipo do campo Name (Text vs Auto Number)

```sql
SELECT QualifiedApiName, DataType, IsAutoNumber, IsNameField
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'IntegrationLog__c'
  AND IsNameField = true
```

## 3. Perfis e permission sets com escrita no objeto

```sql
SELECT Parent.Profile.Name, Parent.Label, Parent.IsOwnedByProfile,
       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions
WHERE SobjectType = 'IntegrationLog__c'
  AND (PermissionsCreate = true OR PermissionsEdit = true)
ORDER BY Parent.IsOwnedByProfile DESC, Parent.Profile.Name
```

Como ler o resultado:
- `Parent.IsOwnedByProfile = true` → a linha é a permissão de um **perfil**
  (`Parent.Profile.Name` traz o nome do perfil).
- `Parent.IsOwnedByProfile = false` → é um **permission set** (`Parent.Label`).
- O usuário de integração (o que o Mule usa) precisa aparecer aqui com
  `PermissionsCreate = true`; para o `referenceId "UpdateAccount"` valer,
  também precisa de `PermissionsEdit` em `Account`.

## 4. FLS — quais campos do objeto cada perfil/permission set pode editar

```sql
SELECT Field, Parent.Profile.Name, Parent.Label, Parent.IsOwnedByProfile,
       PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE SobjectType = 'IntegrationLog__c'
ORDER BY Field, Parent.Profile.Name
```

Atenção: campos universalmente obrigatórios (como `Name` quando é Text) **não
aparecem** em `FieldPermissions` — eles são sempre graváveis quando há acesso ao
objeto. Se um campo custom do payload (ex.: `TargetSystem__c`) não tiver linha
com `PermissionsEdit = true` para o perfil do usuário de integração, o valor é
silenciosamente descartado no insert — outra causa possível de log "vazio".

## 5. Quem efetivamente tem esse acesso (usuários por trás dos perfis/PS)

```sql
SELECT Assignee.Name, Assignee.Username, Assignee.Profile.Name,
       PermissionSet.Label
FROM PermissionSetAssignment
WHERE PermissionSetId IN (
    SELECT ParentId
    FROM ObjectPermissions
    WHERE SobjectType = 'IntegrationLog__c'
      AND PermissionsCreate = true
)
ORDER BY Assignee.Name
```

Inclui tanto permission sets quanto perfis (todo perfil tem um permission set
interno espelho). Procure aqui o usuário de integração do Mule.

## 6. Verificar o acesso do próprio usuário logado (rápido)

```bash
sf data query -o <alias-da-org> --query \
  "SELECT PermissionsCreate, PermissionsEdit FROM ObjectPermissions
   WHERE SobjectType = 'IntegrationLog__c'
     AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment
                      WHERE AssigneeId = '<Id do usuário de integração>')"
```
