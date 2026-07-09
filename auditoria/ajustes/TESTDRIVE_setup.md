# Test drive — o que a IP padrão precisa (para "criar certo")

> **BLOQUEIO ATUAL DIAGNOSTICADO (debug da IP GetTimeSlots):** os dados já existem
> (ServiceTerritoryId/ServiceResourceId/WorkTypeGroupId vieram preenchidos). O que falha é o
> callout `callout:AUTOSCHEDULER/services/data/v56.0/scheduling/getAppointmentSlots` (HTTP 400):
> *"the named credential AUTOSCHEDULER might not exist"*. É **configuração**, não dado/Apex.
>
> ## Correção — Named Credential `AUTOSCHEDULER` (self-callout à própria org)
> 1. Setup → **External Credential** (modelo novo): Auth Protocol OAuth 2.0 (Auth Provider apontando
>    para a própria org) ou o fluxo permitido pela segurança (JWT/Client Credentials); Principal = Named Principal.
> 2. Setup → **Named Credential** com **Developer Name = AUTOSCHEDULER** (tem que casar com `callout:AUTOSCHEDULER`);
>    **URL = a própria My Domain** `https://grupoq--devsales.sandbox.my.salesforce.com`; vincular ao External Credential;
>    Generate Authorization Header = ativo.
> 3. **Permissão**: permission set com **External Credential Principal Access** para esse External Credential,
>    atribuído ao usuário que roda o fluxo; usuário com licença/perm de **Salesforce Scheduler** (getAppointmentSlots).
> 4. Confirmar **Automotive/Salesforce Scheduler habilitado** na org.
> 5. Re-executar a IP `GetTimeSlots` — o callout deve retornar slots.

As IPs OOTB `AutomotiveScheduler/ScheduleTestDrive` e `GetTimeSlots` chamam a API padrão do
**Salesforce Scheduler `getAppointmentSlots`** (passo `FindAppointmentTimeSlots` / Http Action).
Essa API só retorna horários se estes objetos existirem e estiverem ligados. Faltando um, o
fluxo devolve "sem horários".

## Grafo de pré-requisitos (o que precisa existir)
1. **ServiceTerritory** = a **sucursal/loja** (IsActive=true). É o que o cliente escolhe.
   - **OperatingHoursId** → horário de operação da loja (com **TimeSlot** por dia).
   - Pode ter hierarquia via ParentTerritoryId (país→loja).
2. **WorkType** = "Test Drive" (com duração estimada). Criado uma vez, reaproveitado.
3. **WorkTypeGroup** + **WorkTypeGroupMember** = agrupa o WorkType "Test Drive" (o fluxo usa o grupo).
4. **ServiceTerritoryWorkType** = associa o WorkType "Test Drive" a cada ServiceTerritory
   (**crítico**: sem isso a loja não "oferece" test drive e não retorna slots).
5. **ServiceResource** = o recurso agendável (vendedor e/ou veículo), IsActive=true.
6. **ServiceTerritoryMember** = liga o ServiceResource à ServiceTerritory (com vigência/horário).
   Sem pelo menos 1 resource ativo na loja, não há slots.
7. (Se o WorkType exigir skill) **Skill** + **ServiceResourceSkill** + **SkillRequirement**.
8. **Scheduling Policy** (parametriza janela/regras) — referenciada pela IP.

## Como amarra ao que já temos
- A **sucursal** vira **ServiceTerritory**. O dealer se liga a ela por
  **`BusinessProfile.ServiceTerritoryId`** e/ou **`BranchUnit.ServiceTerritoryId`** (ambos existem).
- Ordem de carga sugerida (idempotente, dry-run):
  1) OperatingHours (+TimeSlots) → 2) ServiceTerritory por sucursal → 3) WorkType "Test Drive"
  + WorkTypeGroup(+Member) → 4) ServiceTerritoryWorkType (Test Drive × cada território) →
  5) ServiceResource + ServiceTerritoryMember → 6) vincular BusinessProfile/BranchUnit.ServiceTerritoryId.

## Filtragem por marca (planilha Marca→URL/TestDrive)
Cada site de marca (ex.: hyundaicr.com/test-drive) abre o OmniScript do test drive. O dropdown de
sucursal = ServiceTerritories. Para o site mostrar só as lojas que vendem aquela marca, o OmniScript
precisa filtrar os territórios pela marca — o que exige o dado **marca↔sociedade/dealer** (o campo
`Marcas__c` que discutimos). Sem isso, o site lista todas as lojas do GrupoQ (sem filtro de marca).

## A confirmar antes de carregar
Rodar `describe_scheduler.apex` (read-only) p/ os campos/obrigatorios de ServiceTerritory, WorkType,
WorkTypeGroup(+Member), ServiceTerritoryWorkType, ServiceResource, ServiceTerritoryMember, OperatingHours.

## Fontes
- Set Up Appointment Scheduling in Automotive Cloud — help.salesforce.com/s/articleView?id=ind.auto_configure_scheduler_parent.htm
- Complete Guide to Setting Up Appointment Scheduling (Trailhead) — trailhead.salesforce.com/content/learn/modules/appointment-scheduling-in-automotive-cloud/set-up-appointment-scheduling
- Explore the OmniStudio Components for Appointment Scheduling — help.salesforce.com/s/articleView?id=ind.auto_configure_schedulerexplore_the_omnistudio_components...htm
- Manage Test Drive Appointments — help.salesforce.com/s/articleView?id=ind.auto_scheduler_parent_test_drive.htm
- ServiceTerritory (Object Reference) — developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_serviceterritory.htm
