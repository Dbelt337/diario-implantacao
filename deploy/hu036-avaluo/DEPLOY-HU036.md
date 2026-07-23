# HU-036 — Paquete de deploy y runbook de configuración

Separación estándar: **METADATOS** suben por paquete (SFDX/changeset, package.xml);
**DATOS de configuración** se crean en cada ambiente siguiendo el runbook (DEV ->
INT -> UAT -> PROD), ejecutado por el admin del ambiente. Los registros de
configuración no viajan en deploys — es el comportamiento normal de la plataforma.

## 1. METADATOS (van en el paquete — completar durante la construcción)

| Componente | Tipo de metadato | Estado |
|---|---|---|
| Campos custom en Appraisal: Multas_Esquelas__c, Gravamenes__c, Procesos_Judiciales__c, Motivo_Rechazo__c | CustomField | **DESPLEGADO en DEV 23/07** (paquete v2, deploy success:true) |
| Field History Tracking de los campos custom | CustomField (trackHistory=true) | **DESPLEGADO en DEV 23/07** (embebido; el org aceptó trackHistory — history del objeto ya habilitado) |
| Field History Tracking de campos estándar (Appraisal.Status; AppraisalItem.InitialValue) | Configuración por ambiente | Runbook 2.4b (Set History Tracking en Object Manager) |
| Permission Set GQ_Avaluo_Appraisal (Read Opportunity + familia Appraisal + 4 campos) | PermissionSet | **DESPLEGADO en DEV 23/07** (Id DEV: 0PSWK000001BerB4AS) |
| Lightning Record Page del Appraisal | FlexiPage | Pendiente |
| Acción "Request an Appraisal" en Opportunity (layout) | QuickAction + Layout | Pendiente |
| Flow: notificación al proveedor externo | Flow | Pendiente |
| Flow: búsqueda del PRU -> ProviderVal + InitialValue | Flow | Pendiente |
| Flow: cierre del avalúo (Aceptado -> Opportunity) + ramo de rechazo | Flow | Pendiente |
| Decision Matrix PRU_ValorReferencia (definición) | DecisionMatrixDefinition (+ Version) | Pendiente |
### 1.1 Cómo desplegar el paquete (Workbench — cualquier ambiente)
1. https://workbench.developerforce.com > Environment: Sandbox > API 63.0 > login
   con el usuario admin del ambiente.
2. Menú migration > Deploy > Choose File: `HU036_paquete_v2.zip`.
3. Marcar **Single Package** y **Rollback On Error**. Next > Deploy.
4. Verificar en Object Manager > Appraisal que los 4 campos existen y en
   Permission Sets que "GQ Avalúo - Familia Appraisal" existe.
Nota: si el deploy reclamara por trackHistory (history no habilitado para el
objeto en el ambiente), habilitar primero Set History Tracking en
Object Manager > Appraisal y reintentar.

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
- [x] Appraisal.PurposeType: Trade-In (nativo restrito, ya venia de fabrica)
- [x] DEV 23/07: Appraisal.Status: Agendado | Realizado | Aceptado | Rechazado
- [ ] AppraisalAdjustment.Type: Deducción | Excepción
- [ ] AppraisalItemProviderVal.ProviderName: PRU
- [ ] AppraisalItem.ConditionType / MakeName / ModelName / ModelYear / Trim /
      ExteriorColor: valores del INSUMO Grupo Q (alinear con los picklists de
      Vehicle — una sola taxonomía). Verificado 23/07: ConditionType ACEPTA
      valores propios (0 valores, seccion New habilitada) — sin mapeo forzado
      a Best/Better/Good.
- [ ] Motivo_Rechazo__c: agregar los valores reales del INSUMO Grupo Q
      (el paquete lo entrega solo con "Otro").

### 2.4b Field History de campos estándar (por ambiente)
- [ ] Object Manager > Appraisal > Set History Tracking: Status.
- [ ] Object Manager > Appraisal Item > Set History Tracking: Initial Value
      (si la opción existe para el objeto).
      (Los 4 campos custom ya llevan trackHistory en el paquete.)

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
