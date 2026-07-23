# HU-036 — Guía de configuración completa, paso a paso (sin paquete)

Todo lo necesario para que el avalúo de vehículo usado (trade-in) funcione en
un ambiente, en orden de dependencia, hecho 100% por pantalla (Setup). Es la
reproducción exacta de lo construido y probado en DevSales el 23/07/2026.

---

## PASO 0 — Prerrequisitos del org (verificar antes de empezar)
1. Setup > buscar **Automotive Settings**: Automotive y **Automotive Scheduler**
   activados; la seccion de **Appraisal Management** habilitada.
2. El paquete **OmniStudio** de Automotive instalado (viene con la nube; se
   verifica en el Paso 10 cuando el card aparezca en App Builder).
3. Licencias visibles en Company Information: Automotive Foundation, OmniStudio
   (Admin/User/Runtime), BRE Designer/Runtime (para la Decision Matrix).

## PASO 1 — Moneda USD (Setup > Company Information > Manage Currencies)
1. En Active Currencies > **New** > Currency Type: **USD - U.S. Dollar**.
2. Conversion Rate: cuantos USD vale 1 CRC (ej. `0.00196`). Decimal Places: 2.
3. Save. NO usar "Change Corporate" (la corporativa sigue CRC). NO habilitar
   Advanced Currency Management.

## PASO 2 — Unidad de medida Kilómetros
1. App Launcher (9 puntos) > buscar **Unit of Measure** (pestana del objeto).
2. New: Name `Kilómetros`, Unit Code `km`. Save.
   (Si la pestana no aparece, crear el registro por carga de datos del admin.)

## PASO 3 — Valores de picklist (Setup > Object Manager)
Mecanica igual en todos: objeto > Fields & Relationships > campo > seccion de
valores (Picklist Values) > **New** > un valor por linea > Save.

| Objeto | Campo | Valores |
|---|---|---|
| Appraisal | Purpose Type | `Trade-In` (el org lo entrega VACIO y es obligatorio) |
| Appraisal | Status | `Agendado` `Realizado` `Aceptado` `Rechazado` |
| Appraisal Item Provider Valuation | Provider Name | `PRU` |
| Appraisal Item | Condition Type | escala del INSUMO Grupo Q (provisoria: `Bueno` `Promedio` `Malo`) — OBLIGATORIO al crear item |
| Appraisal Item | Make Name / Model Name / Model Year | taxonomia del PRU (insumo); para pruebas: `Toyota` / `Corolla` / `2020` |
| Appraisal Adjustment | Type | `Deducción` `Excepción` |

NO tocar: Appraisal Adjustment.Status (restricto de plataforma:
Approved/InReview/Rejected, sin seccion de valores).

## PASO 4 — Campos custom en el Appraisal (Object Manager > Appraisal > Fields & Relationships > New)
Naming GRPQM: API en ingles PascalCase sin underscores; label en espanol;
Description obligatoria (paises + proposito). Crear los 4:

| Field Label | API Name | Tipo | Valores / Default |
|---|---|---|---|
| Multas (esquelas) | `TrafficFines` | Picklist (restricta) | Sí / No / Pendiente de verificación (default: Pendiente de verificación) |
| Gravámenes | `Liens` | Picklist (restricta) | idem |
| Procesos judiciales | `LegalProceedings` | Picklist (restricta) | idem |
| Motivo de rechazo | `RejectionReason` | Picklist (abierta) | `Otro` (los valores reales llegan del insumo) |

En cada uno: quitar el underscore que Salesforce inserta en el API name,
llenar Description (ej.: "All countries. Legal verification indicator for the
used-vehicle trade-in appraisal..."), y dar visibilidad a los perfiles que
corresponda (o via permission set del Paso 11).

## PASO 5 — Field History Tracking
1. Object Manager > Appraisal > Fields & Relationships > **Set History
   Tracking** > marcar: Status + los 4 campos del Paso 4. Save.
2. (Si la opcion existe en Appraisal Item: marcar Initial Value.)

## PASO 6 — Scheduler del avalúo (patron Test Drive)
1. **Work Type**: App Launcher > Work Types > New: Name `Avalúo`, Estimated
   Duration 45 min. (En DEV: 08qWK0000013eJhYAI.)
2. **Service Territory**: reusar el de la sucursal (el mismo del Test Drive).
   Un territory = una sucursal (lugar, no proceso).
3. **Vinculo**: en el territory > related Service Territory Work Types > New >
   Work Type Avalúo.
4. **Service Resource** por valuador: ResourceType Technician, RelatedRecord =
   el User del valuador, Active. (Insumo: valuadores reales + horarios.)
5. **Service Territory Member**: agregar el resource al territory (Territory
   Type Primary, fecha de inicio hoy; Operating Hours propias si difieren).

## PASO 7 — Decision Matrix del PRU (BRE)
1. App Launcher > **Lookup Tables** (app Business Rules Engine) > **New** >
   tipo **Decision Matrix** > Name `PRU Valor Referencia` > Standard. Save.
2. Abrir la version V1 > en la grilla, definir las columnas (boton del menu
   desplegable junto a Delete Rows > **Edit Columns**, o Add Column):
   - Input, Text: `Pais`, `Marca`, `Modelo`, `Anio`
   - Output, Currency: `ValorReferencia`
   (Header Type es el selector clave: Input vs Output.)
3. **Save** en la grilla (persiste la definicion de columnas).
4. **Upload CSV File** con las filas (cabecera exacta:
   `Pais,Marca,Modelo,Anio,ValorReferencia`). Para pruebas usar
   PRU_Valor_Referencia_carga_DEV.csv del repositorio; la carga real es una
   NUEVA VERSION con el archivo del insumo.
5. Verificar las filas en la grilla > **Save**.
6. **ACTIVAR la version** (Edit > checkbox Active > Save). Sin version activa
   la accion del Flow no existe (error "We can't find the ... action").
   Moneda: la columna Currency lee la moneda default del org (CRC) —
   confirmar con Grupo Q si el PRU real viene en colones o USD.

## PASO 8 — Flow "Appraisal Item After Handler" (Flow Builder)
Setup > Flows > New Flow > **Record-Triggered Flow**:
1. Object **Appraisal Item**; trigger **A record is created**; Optimize for
   **Actions and Related Records**. Entry conditions (All): MakeName Is Null
   `False`; ModelName Is Null `False`; ModelYear Is Null `False`.
2. **+ Action** > filtro por tipo **Decision Matrices** > `PRU Valor
   Referencia`. Inputs: Pais = `CR` (fijo por ahora), Marca =
   `{!$Record.MakeName}`, Modelo = `{!$Record.ModelName}`, Anio =
   `{!$Record.ModelYear}`.
3. **+ Decision** "Reference Value Found?": outcome cuando el output
   ValorReferencia de la accion **Is Null = False**. (Ramo default: nada —
   sin match, el valuador digita el valor en la inspeccion.)
4. Ramo positivo > **Create Records** (Appraisal Item Provider Valuation):
   AppraisalItemId = `{!$Record.Id}`; ProviderName = `PRU`;
   ValuationDateTime = `{!$Flow.CurrentDateTime}`;
   AverageConditionValue = output ValorReferencia.
5. **+ Update Triggering Record**: InitialValue = output ValorReferencia.
6. Save como `Appraisal Item After Handler` (naming GRPQM) con Description >
   **Activate**.

## PASO 9 — Card "Request an Appraisal" en la pagina de la Opportunity
1. Abrir una Opportunity > engranaje > **Edit Page** (Lightning App Builder,
   pagina "GQ Opportunity - Retail").
2. En Components, buscar **Flexcard** > arrastrarlo a la columna deseada.
3. En las propiedades, **Flexcard Name** =
   `AppraisalManagementCreateAppraisalCard` (card ESTANDAR del paquete
   OmniStudio de Automotive — no clonar ni customizar; upgrades automaticos).
4. **Save** > **Activation** (asignar como org default o por app segun el
   estandar de paginas del proyecto).
Gobernanza: NO deshabilitar el setting "Managed Package Runtime" (es la llave
que abre la customizacion de los componentes de fabrica).

## PASO 10 — Lightning Record Page del Appraisal (visibilidad 360)
1. Abrir un Appraisal > Edit Page > acomodar: highlights (Status, Final
   Appraisal Value), Details con los 4 campos legales + Comment, related
   lists (Appraisal Items, Appraisal Adjustments, Provider Valuations en el
   item). Activation como default.
2. En la pagina de la Opportunity, verificar la related list de Appraisals.

## PASO 11 — Permisos
1. **Permission Set "Gestión de Avalúos"** (Setup > Permission Sets > New):
   - Object Settings: Appraisal, Appraisal Item, Appraisal Item Addon,
     Appraisal Item Provider Valuation, Appraisal Adjustment — Read/Create/
     Edit (sin Delete). Opportunity — Read (dependencia de plataforma).
   - Field Permissions: los 4 campos del Paso 4 (Read + Edit).
2. Asignar ese PS + **OmniStudio User** (el card lo requiere) + el permission
   set de Scheduler Resource a: asesores, valuadores, gerente de usados.

## PASO 12 — Procedimientos de usuario (decision 23/07: SIN flows adicionales)
1. **Ajustes**: al crear una Deducción/Excepción, SIEMPRE seleccionar
   **Status = Approved** — un ajuste sin Approved NO computa en los totales
   (regla de plataforma probada). Agregar help text al campo y capacitar.
2. **Cierre**: el valuador pone Status = `Aceptado` o `Rechazado`. Si
   Rechazado, llena **Motivo de rechazo**. Si Aceptado, el ASESOR aplica el
   valor (Final Appraisal Value) como trade-in en la cotizacion.
3. **Proveedor externo**: el asesor envia la notificacion por correo desde la
   Opportunity (actividad registrada en la linea de tiempo).

## PASO 13 — Prueba de humo
Ejecutar el guion ROTEIRO-PRUEBAS-HU036.md (P1 a P10). La prueba minima:
item Toyota/Corolla/2020 -> Provider Valuation PRU automatico + Initial Value
con el valor de la matriz + Final Appraisal Value calculado; deduccion -500
Approved -> total recalculado.

---
Trazabilidad: todos los componentes pertenecen a la HU-036 (registrar en el
control de componentes como "Ventas / HU-036" el mismo dia de su creacion).
