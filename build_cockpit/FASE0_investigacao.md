# Cockpit GQ_VentaVehiculo — FASE 0: investigação obrigatória (regra 4)

## RESULTADOS (14/07 — parciais)
- **Q1 ✅** RTs Opportunity (todos ativos): `GQOpportunitiesAutos`, `GQOpportunitiesMotos`, `GQOpportunitiesFlotas` (cockpit) · `GQOpportunitiesMayorista`, `GQOpportunitiesRepuestosPA` (fora). Nenhum RT de Quote/Order apareceu (confirmar se a lista acabava ali).
- **Q2 ✅** DUAS etapas ganhas ativas: `Cerrada ganada` (sort 5) e `Ganado` (sort 15). Funil GQ: Nuevo Interés(7) Sospechoso(8) Prospectando(9) Análisis(10) Negociación(11) Cotización Confirmada(12) Cierre(13) Reserva Confirmada(14) Ganado(15) Perdido(16). Decisão: motor 4.1 dispara por `IsWon` false→true (cobre ambas); Cierre 2.3 grava a etapa do sales process do RT (ver Q11).
- **Q3 ❌** `VehicleStatus` NÃO existe no Vehicle desta org (spec desatualizada — org vence). Rodar Q3b abaixo.
- **Q4 ❌** `TriggerObjectOrEventApiName`/`RecordTriggerType` não existem no FlowDefinitionView desta API — usar Q4b.
- **ProcessDefinition ✅** Únicos approvals ativos: `MDM_Conta_Sensivel` e `AprobacionDatosSensiblesCuenta` (conta sensível). **NÃO existe approval de desconto** → o "approval do H6" da spec 2.2 = D-APR-02 (orquestração que o Santiago está construindo). Alinhar contrato de submissão com ele.
- Operacional Inspector: UMA query por execução (duas no mesmo box = MALFORMED_QUERY).

## Queries corrigidas / novas
```sql
-- Q3b: describe do Vehicle (descobrir o campo real de status)
SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Vehicle'
-- Q4b: flows ativos (colunas compatíveis)
SELECT ApiName, Label, ProcessType, TriggerType, IsActive FROM FlowDefinitionView WHERE IsActive = true ORDER BY ProcessType, ApiName
-- Q11: RT -> sales process (qual etapa "ganada" vale para cada RT)
SELECT SobjectType, DeveloperName, BusinessProcessId FROM RecordType WHERE SobjectType = 'Opportunity'
SELECT Id, Name, IsActive FROM BusinessProcess WHERE TableEnumOrId = 'Opportunity'
```
Pendentes da lista original: Q5, Q6, Q7, Q8, Q10.

**Status do gate (13/07):** ambiente remoto SEM sf CLI (npm 403 — política de rede) e sem alias DevSales autenticado → build ABORTADO pela regra dura 1. O build só começa com os resultados abaixo (rodar no Salesforce Inspector / Workbench da DevSales, org Id `00DWK000005VFeD` — conferir SEMPRE antes, cicatriz de 10/07).

Cada query alimenta uma decisão da spec. Colar os resultados de volta na conversa.

## Q1 — Record Types reais (decide filtros do Opp_AS_GenerarPedido 4.1 e visibility 5.1)
```sql
SELECT SobjectType, DeveloperName, Name, IsActive
FROM RecordType
WHERE SobjectType IN ('Opportunity','Quote','Order')
ORDER BY SobjectType, DeveloperName
```

## Q2 — Etapas da Opportunity (decide o gatilho "Ganado" 4.1 e gates do Cierre 2.3)
```sql
SELECT ApiName, MasterLabel, IsActive, IsWon, IsClosed, SortOrder
FROM OpportunityStage
ORDER BY SortOrder
```

## Q3 — Taxonomia VehicleStatus em uso (1.2 — documentar, NÃO criar picklist)
```sql
SELECT VehicleStatus, COUNT(Id) qtde FROM Vehicle GROUP BY VehicleStatus
```
E o grão do estoque (para o GQ_Cockpit_Unidad 3.1):
```sql
SELECT COUNT(Id) qtde FROM Vehicle
SELECT Id, Name, VehicleDefinitionId, VehicleStatus FROM Vehicle LIMIT 20
```

## Q4 — Inventário de flows ativos (colisão com before-saves + nome real do approval H6, 2.2)
```sql
SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventApiName, RecordTriggerType, IsActive
FROM FlowDefinitionView
WHERE IsActive = true
ORDER BY ProcessType, ApiName
```
Approval processes clássicos (se o H6 for approval clássico e não flow):
```sql
SELECT Id, DeveloperName, Name, Type, State FROM ProcessDefinition WHERE State = 'Active'
```

## Q5 — Decision Matrix Discount_Rules_GrupoQ (2.2 — REUSO do padrão LeadScore)
```sql
SELECT Id, Name, UniqueName FROM CalculationMatrix
SELECT Id, Name, CalculationMatrixId, VersionNumber, IsEnabled, StartDate, EndDate FROM CalculationMatrixVersion
```
E o flow de LeadScore que já usa runDecisionMatrix (para copiar o padrão do action call — me mandar o XML depois: Setup → Flows → export, ou retrieve):
```sql
SELECT ApiName, Label FROM FlowDefinitionView WHERE ApiName LIKE '%Lead%' AND IsActive = true
```

## Q6 — Campos existentes (1.1: o que já existe antes de criar; 1.3: anticipo/financiamiento)
```sql
SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Opportunity'
SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Quote'
SELECT QualifiedApiName, DataType, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'Order'
```

## Q7 — OmniStudio Standard Runtime presente e o que já existe (2.x/3.x — namespaces e colisões)
```sql
SELECT Id, Name, Type, SubType, Language, IsActive, VersionNumber, IsIntegrationProcedure
FROM OmniProcess ORDER BY Type, SubType
SELECT Id, Name, Type FROM OmniDataTransform ORDER BY Name
```
(Se `OmniProcess` não existir como objeto → runtime managed/vlocity_cmt → PARAR e reavaliar, a spec exige Standard Runtime.)

## Q8 — Amostra p/ Cotizar (2.1: herança de OLIs ao criar Quote da Opp)
```sql
SELECT Id, Name, StageName, RecordType.DeveloperName, Pricebook2Id, SyncedQuoteId,
       (SELECT Id, Product2Id, Quantity, UnitPrice FROM OpportunityLineItems)
FROM Opportunity WHERE Pricebook2Id != null LIMIT 5
```

## Q9 — Link de Pago / CrediQ (3.2/3.3: existe flow Sec 33.6? slot sp_CotizarWS?)
Já coberto pela Q4 — procurar no resultado ApiNames com `Pago`, `Payment`, `CrediQ`, `Cotizar`.

## Q10 — CMDT flag para stubs (3.1)
```sql
SELECT QualifiedApiName, Label FROM EntityDefinition WHERE QualifiedApiName LIKE '%__mdt' ORDER BY QualifiedApiName
```

---

## Decisões já respondíveis sem org (registro)
- **LWC/Apex "caso muito necessário"** (adendo do arquiteto): mantido como VÁLVULA, não como plano. Nada nas Fases 1–5 precisa: IP_LeerEstadoVenta é DR Turbo + flags; Descuento reusa runDecisionMatrix; motores 4.x são flows; Anticipo/Unidad terminam em stub declarado. O gate por artefato (100% declarativo / existe em Standard Runtime / limite de elementos) continua valendo — se um artefato falhar o gate, a decisão de apelar para LWC/Apex é tomada NAQUELE artefato, documentada no relatório, nunca por antecipação.
- **Anti-exemplo b2bSalesQuote.json**: recebido (uploads). Será lido apenas para formato DataPack, composição IP-filha e Cache Block — conforme regra 5.
