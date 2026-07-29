# HU-009 x Scheduler (test drive) - Scripts de analise

Objetivo: levantar TODOS os fatos pendentes antes do build do "Event Before
Handler" (BranchCode no evento de test drive) e da restauracao da validation
rule original da HU-009.

Contexto (29/07/2026): a regra HU009_Visita_Requiere_Sucursal barra o booking
do Scheduler porque o Event nasce vinculado a Opportunity (WhatId 006) sem
BranchCode__c. O processo entregue (Parte B/C) nao le Subject: a chave e
BranchCode__c preenchido -> VisitStatus__c = Pendiente. Solucao desenhada:
derivar BranchCode do Service Territory do appointment via flow before-save.

Como usar: cada bloco indica ONDE rodar (Execute Anonymous ou Query Editor do
Developer Console). Rode na ordem e cole os resultados no chat para analise.

---

## SCRIPT 1 - Raio-X completo (Execute Anonymous)

Developer Console > Debug > Open Execute Anonymous Window. Colar tudo, marcar
Open Log, executar, e no log filtrar por USER_DEBUG (botao Debug Only).

```apex
// ============================================================
// 1A. ServiceTerritory: existe campo custom de sucursal?
// ============================================================
System.debug('===== 1A ServiceTerritory: campos custom =====');
Map<String, Schema.SObjectField> stFields =
    Schema.SObjectType.ServiceTerritory.fields.getMap();
Integer customCount = 0;
for (String f : stFields.keySet()) {
    Schema.DescribeFieldResult d = stFields.get(f).getDescribe();
    if (d.isCustom()) {
        customCount++;
        System.debug('CUSTOM: ' + d.getName() + ' | tipo=' + d.getType()
            + ' | label=' + d.getLabel());
    }
}
System.debug('Total de campos custom no ServiceTerritory: ' + customCount);

// ============================================================
// 1B. Event.BranchCode__c: valores de API do picklist
//     (o codigo forma o nome do grupo GRP_Sucursal_[code])
// ============================================================
System.debug('===== 1B Event.BranchCode__c: API value | label =====');
for (Schema.PicklistEntry pe :
        Event.BranchCode__c.getDescribe().getPicklistValues()) {
    System.debug(pe.getValue() + ' | ' + pe.getLabel()
        + ' | active=' + pe.isActive());
}

// ============================================================
// 1C. ServiceResource.ResourceType: tipo Asset disponivel?
//     (confirma Asset Scheduling licenciado/habilitado)
// ============================================================
System.debug('===== 1C ServiceResource.ResourceType =====');
for (Schema.PicklistEntry pe :
        ServiceResource.ResourceType.getDescribe().getPicklistValues()) {
    System.debug(pe.getValue() + ' | ' + pe.getLabel()
        + ' | active=' + pe.isActive());
}

// ============================================================
// 1D. ServiceAppointments recentes: QUEM e o Parent Record?
//     (define o filtro de correlacao do flow)
// ============================================================
System.debug('===== 1D ServiceAppointments (10 mais recentes) =====');
for (ServiceAppointment sa : [
    SELECT Id, AppointmentNumber, ParentRecordId, ParentRecordType,
           ServiceTerritoryId, ServiceTerritory.Name,
           SchedStartTime, SchedEndTime, Status,
           WorkTypeId, WorkType.Name, CreatedDate, CreatedBy.Name
    FROM ServiceAppointment
    ORDER BY CreatedDate DESC
    LIMIT 10
]) {
    System.debug(sa.AppointmentNumber
        + ' | Parent=' + sa.ParentRecordType + ':' + sa.ParentRecordId
        + ' | Territorio=' + sa.ServiceTerritory?.Name
        + ' | Inicio=' + sa.SchedStartTime
        + ' | Status=' + sa.Status
        + ' | WorkType=' + sa.WorkType?.Name);
}

// ============================================================
// 1E. Recursos atribuidos: o veiculo (Asset) aparece?
// ============================================================
System.debug('===== 1E AssignedResources (20 mais recentes) =====');
for (AssignedResource ar : [
    SELECT Id, ServiceAppointment.AppointmentNumber,
           ServiceResource.Name, ServiceResource.ResourceType,
           IsRequiredResource
    FROM AssignedResource
    ORDER BY CreatedDate DESC
    LIMIT 20
]) {
    System.debug(ar.ServiceAppointment.AppointmentNumber
        + ' | ' + ar.ServiceResource.Name
        + ' | tipo=' + ar.ServiceResource.ResourceType
        + ' | required=' + ar.IsRequiredResource);
}

// ============================================================
// 1F. Events recentes: o que o Scheduler gravou?
//     (Subject real, WhatId, BranchCode, VisitStatus)
// ============================================================
System.debug('===== 1F Events dos ultimos 7 dias (20) =====');
for (Event e : [
    SELECT Id, Subject, WhatId, What.Name, OwnerId, Owner.Name,
           StartDateTime, BranchCode__c, VisitStatus__c,
           CreatedDate, CreatedBy.Name
    FROM Event
    WHERE CreatedDate = LAST_N_DAYS:7
    ORDER BY CreatedDate DESC
    LIMIT 20
]) {
    String prefix = e.WhatId == null
        ? 'null' : String.valueOf(e.WhatId).left(3);
    System.debug('Subject=' + e.Subject
        + ' | WhatId(' + prefix + ')=' + e.What?.Name
        + ' | Owner=' + e.Owner?.Name
        + ' | Inicio=' + e.StartDateTime
        + ' | Branch=' + e.BranchCode__c
        + ' | VisitStatus=' + e.VisitStatus__c
        + ' | CriadoPor=' + e.CreatedBy.Name);
}

// ============================================================
// 1G. PROVA DA CORRELACAO: para o SA mais recente, existe
//     Event com StartDateTime = SchedStartTime?
//     (e o filtro que o flow before-save vai usar)
// ============================================================
System.debug('===== 1G Correlacao SA <-> Event =====');
List<ServiceAppointment> saList = [
    SELECT Id, AppointmentNumber, ParentRecordId, ParentRecordType,
           SchedStartTime, ServiceTerritoryId, ServiceTerritory.Name
    FROM ServiceAppointment
    WHERE SchedStartTime != null
    ORDER BY CreatedDate DESC
    LIMIT 3
];
for (ServiceAppointment sa : saList) {
    System.debug('SA ' + sa.AppointmentNumber
        + ' | Parent=' + sa.ParentRecordType
        + ' | Inicio=' + sa.SchedStartTime
        + ' | Territorio=' + sa.ServiceTerritory?.Name);
    for (Event e : [
        SELECT Id, Subject, WhatId, OwnerId, StartDateTime
        FROM Event
        WHERE StartDateTime = :sa.SchedStartTime
    ]) {
        System.debug('   -> Event correlacionado: Subject=' + e.Subject
            + ' | WhatId=' + e.WhatId + ' | Owner=' + e.OwnerId);
    }
}

// ============================================================
// 1H. Territorios cadastrados (dados)
// ============================================================
System.debug('===== 1H ServiceTerritories =====');
for (ServiceTerritory st : [
    SELECT Id, Name, IsActive, OperatingHours.Name, ParentTerritoryId
    FROM ServiceTerritory
    ORDER BY Name
]) {
    System.debug(st.Name + ' | ativo=' + st.IsActive
        + ' | horario=' + st.OperatingHours?.Name);
}
// Se o 1A encontrou campo custom de sucursal, repita esta query
// adicionando o campo no SELECT para ver o preenchimento.

// ============================================================
// 1I. Grupos publicos de sucursal (Parte B depende deles)
// ============================================================
System.debug('===== 1I Grupos GRP_Sucursal_* =====');
for (Group g : [
    SELECT Id, Name, DeveloperName
    FROM Group
    WHERE DeveloperName LIKE 'GRP_Sucursal%'
    ORDER BY DeveloperName
]) {
    System.debug(g.DeveloperName + ' | ' + g.Name);
}

// ============================================================
// 1J. Work Types / Work Type Groups (setup do Scheduler)
// ============================================================
System.debug('===== 1J WorkTypeGroups e WorkTypes =====');
for (WorkTypeGroup wtg : [SELECT Id, Name, IsActive FROM WorkTypeGroup]) {
    System.debug('WTG: ' + wtg.Name + ' | ativo=' + wtg.IsActive);
}
for (WorkType wt : [
    SELECT Id, Name, EstimatedDuration, DurationType FROM WorkType
]) {
    System.debug('WT: ' + wt.Name + ' | duracao=' + wt.EstimatedDuration
        + ' ' + wt.DurationType);
}
```

Se o 1E falhar por campo inexistente, remova a linha do campo apontado no
erro e rode de novo - a falha em si e diagnostico (ex.: se ServiceResource
nao tiver AssetId, o Asset Scheduling nao esta habilitado).

---

## SCRIPT 2 - Estado da validation rule (Query Editor + Tooling API)

Developer Console > Query Editor > marcar o checkbox "Use Tooling API":

```sql
SELECT Id, ValidationName, Active, ErrorMessage
FROM ValidationRule
WHERE EntityDefinition.DeveloperName = 'Event'
```

Esperado: HU009_Visita_Requiere_Sucursal com o estado atual de Active e a
formula vigente (abrir o registro para ver Metadata, ou conferir no Object
Manager). Anotar se a versao em vigor ainda e a escopada por Subject
(paliativo) ou a original.

---

## SCRIPT 3 - Estado dos flows (Query Editor, SEM Tooling API)

```sql
SELECT ApiName, Label, ProcessType, TriggerType, IsActive
FROM FlowDefinitionView
WHERE ApiName IN (
    'Event_AfterSave_ShareBranchHandOff',
    'Opportunity_Screen_ReceiveCustomer'
)
```

Esperado: ambos ativos. Se IsActive nao existir na org (varia por versao),
remover a coluna e conferir o estado em Setup > Flows.

---

## SCRIPT 4 - Checagens manuais (sem script)

1. Setup > Salesforce Scheduler Settings: anotar o estado dos toggles
   Event Management, Aggregate Resource Use e Multi-Resource Scheduling.
   (Event Management precisa estar ON - e ele que cria o Event que estamos
   integrando ao hand-off.)
2. Object Manager > Service Territory > Fields: cruzar com o resultado 1A.
3. Setup > Process Automation Settings: nada a mudar, so referencia.

---

## Mapa resultado -> decisao

| Resultado | Decide |
|---|---|
| 1A | Se ja existe campo de sucursal no territorio, reusamos; senao criamos BranchCode__c (picklist com os MESMOS API values do 1B) |
| 1B | Valores exatos que o campo do territorio deve carregar (grupo GRP_Sucursal_[code]) |
| 1C | Tipo Asset presente = Asset Scheduling confirmado em describe |
| 1D | ParentRecordType do SA = filtro do Get Records do flow (Opp direto ou via Account) |
| 1F | Subject real que o Scheduler grava (documentar; NAO sera usado como chave) |
| 1G | Prova empirica do filtro de correlacao StartDateTime = SchedStartTime (e se ha risco de colisao com mais de um Event no mesmo horario) |
| 1H | Quais territorios precisam receber o codigo antes do go |
| 1I | Grupos de sucursal existentes x codigos do 1B (gap = Task de log da Parte B) |
| 2 | Estado/formula da regra antes da restauracao |
| 3 | Parte B e C ativas antes do teste E2E |

Proximo passo apos colar os resultados: spec final do flow
"Event Before Handler" (filtros exatos conforme 1D/1G) + restauracao da
regra original + matriz de testes E2E.
