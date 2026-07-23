# HU-036 — Paquete de deploy y runbook de configuración

Separación estándar: **METADATOS** suben por paquete (SFDX/changeset, package.xml);
**DATOS de configuración** se crean en cada ambiente siguiendo el runbook (DEV ->
INT -> UAT -> PROD), ejecutado por el admin del ambiente. Los registros de
configuración no viajan en deploys — es el comportamiento normal de la plataforma.

## 1. METADATOS (van en el paquete — completar durante la construcción)

| Componente | Tipo de metadato | Estado |
|---|---|---|
| Campos custom en Appraisal: TrafficFines__c, Liens__c, LegalProceedings__c, RejectionReason__c (labels en español; API en inglés por la GRPQM Naming Convention) | CustomField | **DESPLEGADO en DEV 23/07** (paquete v4; los 4 nombres antiguos en español eliminados en el mismo deploy) |
| Field History Tracking de los campos custom | CustomField (trackHistory=true) | **DESPLEGADO en DEV 23/07** (embebido; el org aceptó trackHistory — history del objeto ya habilitado) |
| Field History Tracking de campos estándar (Appraisal.Status; AppraisalItem.InitialValue) | Configuración por ambiente | Runbook 2.4b (Set History Tracking en Object Manager) |
| Permission Set AppraisalManagement "Gestión de Avalúos" (Read Opportunity + familia Appraisal + 4 campos) | PermissionSet | **DESPLEGADO en DEV 23/07** (Id DEV: 0PSWK000001Bfs54AC; GQ_Avaluo_Appraisal eliminado) |
| Lightning Record Page del Appraisal | FlexiPage | Pendiente |
| Acción "Request an Appraisal" en Opportunity (layout) | QuickAction + Layout | Pendiente |
| Flow: notificación al proveedor externo | Flow | Pendiente |
| Flow: Appraisal Item After Handler (búsqueda del PRU -> ProviderVal + InitialValue) | Flow | **DESPLEGADO en DEV 23/07** como Draft (Id DEV: 301WK00002Tt7brYAB; actionType runDecisionMatrix, action PRU_Valor_Referencia). ACTIVADO y PROBADO end-to-end 23/07 (item Toyota/Corolla/2020 -> ProviderVal PRU + InitialValue 14.500 + FinalValue calculado) |
| Flow: cierre del avalúo (Aceptado -> Opportunity) + ramo de rechazo | Flow | Pendiente |
| Decision Matrix PRU_ValorReferencia (definición) | DecisionMatrixDefinition (+ Version) | Pendiente |
### 1.1 Cómo desplegar el paquete (Workbench — cualquier ambiente)
1. https://workbench.developerforce.com > Environment: Sandbox > API 63.0 > login
   con el usuario admin del ambiente.
2. Menú migration > Deploy > Choose File: `HU036_paquete_v4.zip` (incluye destructiveChangesPost.xml — en Workbench el zip lo aplica automaticamente).
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
- [x] DEV 23/07: moneda USD activada (Manage Currencies > New > USD, tasa
      0.001960, 2 decimales). NO cambiar Corporate (queda CRC); ACM (tasas datadas) no se
      habilita. En PROD la tasa la gobierna el proceso financiero/SAP.

### 2.1b Hallazgos de campos obligatorios (verificado en la UI, 23/07)
- Appraisal.UsageType obligatorio (valor: Automotive) — ya documentado.
- AppraisalItem.Usage (kilometraje) OBLIGATORIO en la creacion + su
  UsageUnitOfMeasureId (registro "Kilómetros"). Considerar en layouts y cargas.
- AppraisalItem.ConditionType OBLIGATORIO en la creacion — la escala de
  condicion del INSUMO Grupo Q es imprescindible (el campo bloquea el alta).
  DEV 23/07: escala PROVISORIA sembrada: Bueno | Promedio | Malo (reemplazar
  con la escala real del insumo).
- Appraisal.PurposeType obligatorio y el picklist vino vacio (sembrar Trade-In).

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
- [x] DEV 23/07: Appraisal.PurposeType: Trade-In (OJO: en este org el picklist vino VACIO — sembrar el valor en cada ambiente, la doc lo describia como restricto de fabrica)
- [x] DEV 23/07: Appraisal.Status: Agendado | Realizado | Aceptado | Rechazado
- [ ] AppraisalAdjustment.Type: Deducción | Excepción
- [ ] AppraisalItemProviderVal.ProviderName: PRU
- [ ] AppraisalItem.ConditionType / MakeName / ModelName / ModelYear / Trim /
      ExteriorColor: valores del INSUMO Grupo Q (alinear con los picklists de
      Vehicle — una sola taxonomía). Verificado 23/07: ConditionType ACEPTA
      valores propios (0 valores, seccion New habilitada) — sin mapeo forzado
      a Best/Better/Good.
- [ ] RejectionReason__c: agregar los valores reales del INSUMO Grupo Q
      (el paquete lo entrega solo con "Otro").

### 2.4b Field History de campos estándar (por ambiente)
- [ ] Object Manager > Appraisal > Set History Tracking: Status.
- [ ] Object Manager > Appraisal Item > Set History Tracking: Initial Value
      (si la opción existe para el objeto).
      (Los 4 campos custom ya llevan trackHistory en el paquete.)

### 2.5 Datos de la matriz PRU
- [x] DEV 23/07: matriz "PRU Valor Referencia" creada (Lookup Tables / BRE),
      columnas Pais/Marca/Modelo/Anio (Input, Text) + ValorReferencia (Output,
      Currency); 12 filas de prueba cargadas por CSV
      (PRU_Valor_Referencia_carga_DEV.csv). Version V1 ACTIVADA 23/07 (accion runDecisionMatrix/PRU_Valor_Referencia publicada).
      Nota: los valores se leen en CRC (moneda default) — confirmar con Grupo Q
      si el PRU real viene en colones o USD (pregunta del insumo).
- [ ] Carga del CSV REAL en la Decision Matrix (nueva versión por actualización).
      La DEFINICIÓN de la matriz va como metadato (sección 1); las FILAS/versiones
      se cargan por CSV en cada ambiente (o solo en PROD, según gobernanza del dato).

### 2.6 Permisos
- [ ] Asignar el Permission Set de Appraisal a los perfiles (asesor, valuador,
      gerente de usados).
- [ ] Permission set de Scheduler Resource a los valuadores.

## 3. Orden de despliegue
1. Runbook 2.1 (features/moneda) -> 2. Paquete de metadatos -> 3. Runbook 2.2-2.6.

## 3.1 Naming (GRPQM Naming Conventions — Diego Braz, 23/07)
Todo metadato de este paquete sigue la convencion oficial: API names en INGLES,
PascalCase sin underscores, labels en espanol, Description obligatoria con
paises + proposito de negocio. Los 4 campos originales en espanol
(Multas_Esquelas__c, Gravamenes__c, Procesos_Judiciales__c, Motivo_Rechazo__c)
y el PS GQ_Avaluo_Appraisal se eliminan en el mismo deploy (destructive post).

## 4. Trazabilidad
Todo componente de este paquete pertenece a la HU-036 (regla del proyecto:
componente creado = registrado el mismo día con su HU de origen). El control de
componentes por frente debe listar estos ítems como "Ventas / HU-036".
