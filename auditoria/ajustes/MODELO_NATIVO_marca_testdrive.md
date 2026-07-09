# Modelo nativo — marca × dealer e test drive (sem objeto custom)

Cliente não pode criar objeto custom. Toda a modelagem usa **objetos nativos do Automotive Cloud**.
Esta nota substitui a abordagem de junção custom (`Marca_Sociedad__c` fica **descontinuada**).

## 1. Marca × dealer/sociedade → objeto nativo `AccountBrand`
> **CORREÇÃO (validado na org):** `AccountBrand` tem **AccountId UNIQUE** — só 1 marca por
> conta (erro `DUPLICATE_VALUE` ao inserir a 2ª). Portanto **NÃO serve** para dealer multi-marca.
> O caminho nativo multi-marca é **BranchUnit** (Branch Management). Rode `describe_branch.apex`
> para confirmar o lookup BranchUnit→BusinessBrand. Alternativa: multipicklist `Marcas__c` na sociedade.

`AccountBrand` é o objeto padrão que representa "os detalhes de marca de um Partner Account" e é o
mecanismo nativo para registrar **quais marcas um dealer vende/representa** (Salesforce docs). Um
Account com várias marcas = **vários registros AccountBrand**.
- Confirmado na org: `AccountBrand` PRESENTE, `AccountId -> Account` (a licença Digital Experiences
  está ligada).
- **Grão**: criamos 1 AccountBrand por (Account de **sociedade** × marca), pois a planilha
  `Sociedades_Marcas_Sucursales` é grão de sociedade. Toda sucursal herda as marcas da sociedade.
- **Script**: `CR_marcas_accountbrand.apex` (nativo, idempotente por Account+Name, DRY RUN).
  Carrega a matriz inteira; cria só para as sociedades que já têm Account (hoje CR C101/C105).
- Limitação nativa: `AccountBrand` não tem FK para `BusinessBrand` — o vínculo ao catálogo é por
  **nome** (Name = marca). Os 23 BusinessBrands continuam como catálogo/hierarquia por OEM.

### Envio ao SAP
Os dados ficam consultáveis para a integração: `AccountBrand.Name` (marca) + `AccountBrand.Account`
→ a sociedade, cujo código (C101/C105) está no `InternalOrganizationUnit.OrganizationCode` e/ou no
`BusinessProfile.ExternalReferenceNumber` (código SAP por franquia). Query de export:
`SELECT Account.Name, Name FROM AccountBrand`. O de-para nome-da-marca → código-SAP-da-marca é
mapeamento da camada de integração.

## 2. Test drive na concessionária → Automotive Scheduler (nativo)
Fluxo "cliente vai à loja" usa o **Automotive Scheduler**:
- **ServiceTerritory** = a **sucursal/loja** onde ocorre o test drive (o cliente escolhe no site).
- **BusinessProfile.ServiceTerritoryId** liga o dealer ao seu ServiceTerritory (passo do guia
  "Create Business Profiles" — obrigatório se usar Scheduler).
- **WorkType / WorkTypeGroup** = "Test Drive" (o tipo de serviço/cita).
- **ServiceAppointment** = a cita agendada; **ServiceResource** = vendedor/veículo.
- Objetos de apoio: ServiceTerritoryMember, TimeSlot, Skill, WorkTypeGroupMember.

Para habilitar o test-drive das sucursales de CR: criar **ServiceTerritory** por sucursal e
vincular via `BusinessProfile.ServiceTerritoryId`. É o próximo script (mesmo padrão, dry-run).
> Nota: a disponibilidade de marca por sucursal (ex.: Cadillac só em 3 lojas) é mais fina que a
> planilha (grão sociedade). Se o test-drive precisar filtrar marca por loja, essa matriz
> marca×sucursal é um dado adicional (vem dos sites de marca), modelável com AccountBrand no
> Account do **dealer** (não só da sociedade).

## 3. Resumo do modelo (tudo nativo)
| Necessidade | Objeto nativo |
|---|---|
| Grupo/país/sociedade/dealer | Account (hierarquia) + InternalOrganizationUnit |
| Código SAP por franquia | BusinessProfile.ExternalReferenceNumber |
| Catálogo de marcas | BusinessBrand (23, hierarquia por OEM via ParentId) |
| Marca que o dealer/sociedade vende | **AccountBrand** (1 por Account×marca) |
| Almacenes | Location + AssociatedLocation |
| Test drive / cita na loja | ServiceTerritory + WorkType + ServiceAppointment (Automotive Scheduler) |

## Fontes
- Create Business Brands in Automotive Cloud — help.salesforce.com/s/articleView?id=ind.auto_business_brands.htm
- AccountBrand (Object Reference) — developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_accountbrand.htm
- Automotive Cloud Standard Objects — developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm
- Manage Test Drive Appointments in Automotive Cloud — help.salesforce.com/s/articleView?id=ind.auto_scheduler_parent_test_drive.htm
- How Automotive Scheduler Records Work Together — help.salesforce.com/s/articleView?id=sf.auto_scheduler_data_model.htm
- Schedule Test Drives and Vehicle Services (Trailhead) — trailhead.salesforce.com/content/learn/modules/appointment-scheduling-in-automotive-cloud/schedule-test-drives-and-vehicle-services

> Páginas salesforce.com não puderam ser baixadas nesta sessão (403 no egresso); síntese a partir
> das referências de objeto e resultados de busca acima. API names de Scheduler a confirmar via describe.

## 4. BranchUnit — describe confirmado (org)
Campos: `Name`(obrig), `AccountId`->Account, `BranchCode`(ex.: C011), `Type`(picklist),
`IsActive`, `ParentBranchUnitId`->BranchUnit, `ServiceTerritoryId`->ServiceTerritory,
`LocationId`->Location, `OperatingHoursId`->OperatingHours, `OperationalState`, `BranchManagerId`->Banker.
`BranchUnitBusinessMember`: BranchUnitId + BusinessUnitMemberId(Banker,User). `BranchUnitRelatedRecord`:
RelatedRecordId polimórfico (Account/Case/Contact/Lead/…), **sem BusinessBrand**.

**Conclusão (validado):** nenhum objeto nativo do AC liga dealer↔BusinessBrand em N:N
(AccountBrand é 1:1; BranchUnit e RelatedRecord não têm campo de marca).

### Decisão de marca (dado o cenário)
- **Marca** = campo **multipicklist `Marcas__c`** (valores = as 23 BusinessBrands) na **sociedade**
  (Account ou IOU). É um CAMPO (não objeto), multi-marca, e exportável para SAP
  (`SELECT ..., Marcas__c FROM ...`). Grão = sociedade (bate com a planilha).
- **BranchUnit** = unidade operacional do dealer por centro/línea (BranchCode=centro SAP). Ótimo
  encaixe nativo para: vínculo Account (dealer), Location (almacén) e **ServiceTerritory (test drive)**.
  Reaproveita o "La Uruca / C011" já criado. Idempotente por BranchCode.
- **Pendência de decisão do arquiteto:** é possível criar CAMPO custom (não objeto)? Se sim,
  `Marcas__c` fecha a marca. Se não, a marca fica como dado de referência fora do SF / integração SAP.
