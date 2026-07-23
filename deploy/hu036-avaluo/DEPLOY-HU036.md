# HU-036 — Paquete de deploy y runbook de configuración

Separación estándar: **METADATOS** suben por paquete (SFDX/changeset, package.xml);
**DATOS de configuración** se crean en cada ambiente siguiendo el runbook (DEV ->
INT -> UAT -> PROD), ejecutado por el admin del ambiente. Los registros de
configuración no viajan en deploys — es el comportamiento normal de la plataforma.

## 1. METADATOS (van en el paquete — completar durante la construcción)

| Componente | Tipo de metadato | Estado |
|---|---|---|
| Campos custom en Appraisal: Multas_Esquelas__c, Gravamenes__c, Procesos_Judiciales__c, Motivo_Rechazo__c | CustomField | Pendiente de crear |
| Field History Tracking (Appraisal: Status, InitialValue, indicadores) | CustomField (trackHistory) | Pendiente |
| Lightning Record Page del Appraisal | FlexiPage | Pendiente |
| Acción "Request an Appraisal" en Opportunity (layout) | QuickAction + Layout | Pendiente |
| Flow: notificación al proveedor externo | Flow | Pendiente |
| Flow: búsqueda del PRU -> ProviderVal + InitialValue | Flow | Pendiente |
| Flow: cierre del avalúo (Aceptado -> Opportunity) + ramo de rechazo | Flow | Pendiente |
| Decision Matrix PRU_ValorReferencia (definición) | DecisionMatrixDefinition (+ Version) | Pendiente |
| Permission Set de acceso a la familia Appraisal (objetos/campos) | PermissionSet | Pendiente |

Nota sobre picklists de campos ESTÁNDAR (PurposeType, Status, Adjustment.Type,
ProviderName, ConditionType, MakeName...): los valores agregados a picklists
estándar no siempre son desplegables como metadato (StandardValueSet tiene
cobertura parcial). Tratarlos como **configuración por ambiente** en el runbook
(sección 2.4) salvo que la retrieve confirme soporte. Es práctica estándar.

## 2. RUNBOOK de configuración por ambiente (datos — no van en el paquete)

Cada paso indica la vía oficial (pantalla). Los Ids citados son del DevSales;
en cada ambiente se crean nuevos.

### 2.1 Features y moneda (una vez por ambiente)
- [x] DEV: Automotive + Automotive Scheduler activos (Setup > Automotive Settings).
- [x] DEV: familia Appraisal habilitada (objetos createable — verificado 23/07).
- [x] DEV: moneda USD activada (Setup > Company Information > Manage Currencies;
      tasa de sandbox aprox. 0.00196; en PROD la tasa la gobierna el sync del SAP).

### 2.2 Unidad de medida
- [x] DEV: registro UnitOfMeasure Name="Kilómetros", UnitCode="km"
      (Id DEV: 0hEWK0000003s0f2AA). Vía: pestaña Unit of Measure (App Launcher)
      o carga de datos del admin.

### 2.3 Scheduler (por sucursal)
- [x] DEV: Work Type "Avalúo" (45 min) — Id DEV: 08qWK0000013eJhYAI.
- [x] DEV: reuso del Service Territory de la sucursal (0HhWK000000Poxh0AC,
      "GQ TD Sucursal Central"); pendiente rename a "GQ Sucursal Central"
      (coordinar con el dueño del Test Drive).
- [x] DEV: Work Type Avalúo vinculado al territory (ServiceTerritoryWorkType
      Id DEV: 0VEWK00000019R34AI).
- [ ] Service Resources de los valuadores reales + ServiceTerritoryMember
      (+ Operating Hours propias si difieren de la sucursal). INSUMO Grupo Q.
- [x] DEV: recurso de prueba = Service Resource existente del Test Drive
      ("Diego Beltrao", 0HnWK000000MMGP0A4, ya miembro del territory
      0HuWK000000ItUH0A0 — reutilizado, nada creado). Sustituir por los
      valuadores reales al llegar el insumo; no desplegar el recurso de prueba.

### 2.4 Valores de picklist (por ambiente, vía Object Manager)
- [ ] Appraisal.PurposeType: Trade-In
- [ ] Appraisal.Status: Agendado | Realizado | Aceptado | Rechazado
- [ ] AppraisalAdjustment.Type: Deducción | Excepción
- [ ] AppraisalItemProviderVal.ProviderName: PRU
- [ ] AppraisalItem.ConditionType / MakeName / ModelName / ModelYear / Trim /
      ExteriorColor: valores del INSUMO Grupo Q (alinear con los picklists de
      Vehicle — una sola taxonomía).

### 2.5 Datos de la matriz PRU
- [ ] Carga del CSV en la Decision Matrix (nueva versión por actualización).
      La DEFINICIÓN de la matriz va como metadato (sección 1); las FILAS/versiones
      se cargan por CSV en cada ambiente (o solo en PROD, según gobernanza del dato).

### 2.6 Permisos
- [ ] Asignar el Permission Set de Appraisal a los perfiles (asesor, valuador,
      gerente de usados).
- [ ] Permission set de Scheduler Resource a los valuadores.

## 3. Orden de despliegue
1. Runbook 2.1 (features/moneda) -> 2. Paquete de metadatos -> 3. Runbook 2.2-2.6.

## 4. Trazabilidad
Todo componente de este paquete pertenece a la HU-036 (regla del proyecto:
componente creado = registrado el mismo día con su HU de origen). El control de
componentes por frente debe listar estos ítems como "Ventas / HU-036".
