# Diagnóstico READ-ONLY — campos do Lead para reúso na HU-010
> Rodar no Salesforce Inspector (Data Export) ou Workbench. Nenhum DML. Só leitura.

## Query 1 — TODOS os campos custom do Lead (nome, label, tipo)
> Marque "Use Tooling API" no Inspector se necessário.
```sql
SELECT QualifiedApiName, Label, DataType
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Lead'
  AND QualifiedApiName LIKE '%__c'
ORDER BY QualifiedApiName
```

## Query 2 — foco HU-010 (SLA / contacto / gestión / temperatura / prioridad / intentos)
```sql
SELECT QualifiedApiName, Label, DataType
FROM FieldDefinition
WHERE EntityDefinition.QualifiedApiName = 'Lead'
  AND ( QualifiedApiName LIKE '%SLA%'      OR QualifiedApiName LIKE '%Deadline%'
     OR QualifiedApiName LIKE '%Contacto%' OR QualifiedApiName LIKE '%Contact%'
     OR QualifiedApiName LIKE '%Gestion%'  OR QualifiedApiName LIKE '%Reassign%'
     OR QualifiedApiName LIKE '%Transfer%' OR QualifiedApiName LIKE '%Attempt%'
     OR QualifiedApiName LIKE '%Temperatura%' OR QualifiedApiName LIKE '%Prioridad%'
     OR QualifiedApiName LIKE '%Cumpli%'   OR QualifiedApiName LIKE '%Score%'
     OR QualifiedApiName LIKE '%Rating%'   OR QualifiedApiName LIKE '%Discard%' )
ORDER BY QualifiedApiName
```

## Query 3 (opcional, só para VALORES de picklist) — Apex ANÁLISE, sem DML
> Use apenas se quiser os valores das picklists (Status/Rating/Industry/Temperatura se existir).
> É só describe (leitura), não grava nada.
```apex
Schema.DescribeSObjectResult d = Lead.SObjectType.getDescribe();
for (Schema.SObjectField f : d.fields.getMap().values()) {
    Schema.DescribeFieldResult r = f.getDescribe();
    Boolean pick = (r.getType() == Schema.DisplayType.Picklist || r.getType() == Schema.DisplayType.MultiPicklist);
    if (!r.isCustom() && !pick) continue;
    String vals = '';
    if (pick) {
        for (Schema.PicklistEntry pe : r.getPicklistValues()) {
            vals += pe.getValue() + (pe.isActive() ? '' : '(inativo)') + ' | ';
        }
    }
    System.debug(r.getName() + '  [' + r.getType() + ']  "' + r.getLabel() + '"' + (vals != '' ? '  => ' + vals : ''));
}
```

## Query 4 — ScoreIntelligence (Einstein) para a Temperatura
```sql
SELECT Id, Score, BaseId FROM ScoreIntelligence LIMIT 5
```
> Se der erro de coluna, rode primeiro o describe do objeto (nome real de Score/categoria pode divergir — R5).
