# HU-045 (Vehículo usado / consignación) — resumen del estado + las 6 definiciones

**Fecha:** 13/08/2026 · Para Santiago. Basado en: planillas de tareas técnicas v3.1 → v5, diagrama de flujo funcional, mapeo a Automotive Cloud y verificaciones en la org.

---

## 0. Antes de las definiciones: qué sigue y qué espera

La HU-045 y la HU-046 quedaron **bloqueadas ayer (12/08)** a la espera de los prototipos de UX (Gastón) — el cliente lo pidió tras la presentación. Eso **no para todo**: hay que separar dos frentes, para que no trabajes en algo que después se rehace.

| Sigue AHORA (independiente del prototipo) | ESPERA el prototipo aprobado |
|---|---|
| Modelo de datos (ya hecho en su mayoría) · T12 avalúo · T13 consignación · T15 baja al vender · T24 AssetMilestone · T23 configuración de Inventory Search · T16 completar permisos | **Las pantallas del T10** (es un Screen Flow: su layout, orden de pasos y validaciones visibles salen del prototipo) |

Sugerencia concreta: construir T10 como **lógica + subflows** (VIN check, crear/actualizar Asset+Vehicle, publicar evento) y dejar la capa de pantallas para el final. Así el 80% del T10 avanza y solo la piel se ajusta al prototipo.

## 1. Lectura del estado

Lo realizado está sólido y coherente con el modelo Automotive: la unidad se ancla en **Asset (master) → Vehicle**, el almacén en `Asset.LocationId`, la consignación en **Contract** con Record Type propio, la trazabilidad en Field History y el aviso de alta en Platform Event. Nada de eso hay que rehacerlo.

El camino crítico es **T10**, y depende de las definiciones 1 y 2 — por eso las respondo primero y con detalle.

---

## 2. Las 6 definiciones

### Def. 1 — Marca/modelo/año reales: ¿campos custom o VehicleDefinition real por unidad?

**Confirmo tu Op.2 (campos custom), con una mejora: hacerla híbrida.**

El hallazgo de que `Vehicle.MakeName/ModelName/ModelYear/TrimLevel` son de solo lectura (derivados del VehicleDefinition) es correcto y tumba el plan original — bien visto.

Ahora, **Op.1 pura (find-or-create de un VehicleDefinition por unidad) no**: crearía un modelo de catálogo por cada usado que entra, ensuciando el catálogo que alimenta la búsqueda de la venta guiada, los informes y la administración de precios. Es exactamente el problema que estamos evitando en la HU de Financial (misma decisión, ADR-004).

Pero Op.2 pura tiene un costo que hay que ver: si el usado queda colgado de un VehicleDefinition **genérico**, la búsqueda nativa por marca/modelo no lo encuentra por sus campos derivados.

**Propuesta — Op.2 híbrida (find-or-REUSE, no find-or-create):**
1. Si el modelo del usado **ya existe en el catálogo** (es una marca que GrupoQ vende — el caso más común en trade-in): **reutilizar ese VehicleDefinition real**. No se crea nada, y la unidad queda buscable de forma nativa.
2. Si el modelo **no existe** (marca fuera de catálogo): VehicleDefinition **genérico** + los campos `ActualMake__c / ActualModel__c / ActualTrimLevel__c / ActualModelYear__c` que ya creaste.
3. Los campos `Actual*` se llenan **siempre**, en los dos casos — así hay una fuente única para informes, impuestos (el año numérico limpio, insumo de la HU-105) y para la búsqueda.

**Verificación obligatoria antes de cerrar:** confirmar que los campos `Actual*` pueden incluirse como criterio en la configuración del **Inventory Search** (`VehicleSearchableField`). Si se pueden, la Op.2 híbrida queda perfecta. Si no se pueden, el punto 1 (reutilizar la definición real cuando existe) pasa de recomendable a **obligatorio** para que el usado sea buscable.

### Def. 2 — VehicleDefinition + Product2 genéricos «Used Vehicle»

**OK, con tres condiciones:**
1. El Product2 genérico se crea con **`Family = No Comercializado`** y **nunca** con PricebookEntry en una lista comercial. Es la misma regla que acordamos para los productos financiables: sin entrada de precio no es cotizable, y con la Family fuera de la allowlist no aparece en la búsqueda del flujo guiado.
2. **Orden de creación confirmado: Asset primero, Vehicle después** — `Vehicle.AssetId` es master-detail y el centro vive en `Asset.LocationId` (verificado en la org). En el Asset van sociedad, LocationId, PurchaseDate y AssetProvidedById.
3. **El ex-GQ conserva su VehicleDefinition real** — confirmado, y por la regla D2: VIN único, el re-ingreso **actualiza el mismo Vehicle**, nunca crea uno nuevo. Con la Op.2 híbrida de arriba, además, cualquier usado de marca del catálogo también conserva la definición real.

### Def. 3 — Avalúo: a qué registro se liga

**Tu recomendación es correcta y coincide con la semántica oficial de los objetos:** el `Appraisal` es *"la valuación para uno o más ítems"* y el `AppraisalItem` es *"el ítem que se valúa, como un vehículo o un asset"*. Entonces:
- **`Appraisal.ReferenceRecordId` = Account** del vendedor/consignante (el «para quién»);
- **`AppraisalItem.ReferenceRecordId` = Vehicle** (ex-GQ) o el registro de la unidad de terceros (el «qué»).

**Sobre PurposeType (solo tiene «Trade-In»):** antes de agregar valores hay que verificar si el picklist es **restringido**. Si admite valores nuevos, agregar «Compra Directa» y «Consignación» — es lo más limpio. Si es restringido y no se puede extender, la alternativa es un campo propio de propósito en el Appraisal (no tocar el estándar). Es una verificación de 2 minutos en Setup y evita un rework.

**Sobre reutilizar el avalúo de trade-in de la HU-036: sí**, con una regla que hay que fijar: **ventana de vigencia** del avalúo (p. ej. X días) — pasado ese plazo se exige uno nuevo. Sin esa regla, un avalúo viejo entra en una compra nueva.

### Def. 4 — Inventory Search nativo vs list views

**Sí, adoptar el Inventory Search nativo como base**, con las list views (T17) como fallback. Cubre lo que las list views no cubren (búsqueda filtrable multi-criterio y traslados entre sucursales) y es el mecanismo que el propio Automotive Cloud ofrece para esto.

**Tu nota es importante y la firmo:** se configura por Setup en cada org y no es 100% desplegable → **entra en el DLG como paso manual por ambiente** (DEV → QA → UAT → PROD), con checklist. Es el tipo de item que, si no queda escrito, se descubre el día del go-live.

Y el enganche con la Def. 1: la configuración de búsqueda tiene que incluir los campos donde vive la marca/modelo real.

### Def. 5 — AssetMilestone «Resale» en R1

**Sí, en R1.** Tres razones:
1. El objeto existe **exactamente para esto** — `AssetMilestone` representa *"los eventos clave del ciclo de vida de un vehículo, como fabricación, registro o **reventa**"*;
2. El costo es 1 elemento «Create Records» dentro de un flow que ya se va a construir (T10) — minutos;
3. **No es retroactivo**: si entra después, se pierde el historial de todo el período de R1 y no se puede reconstruir. Barato ahora, imposible luego.

### Def. 6 — Locations de consignación (dato del cliente)

`Asset.LocationId` es el modelo nativo (verificado). Falta el **dato**: la lista de Locations por sociedad. Es la misma pendiente del T09 y del thread de la HU-046.

**Acción:** cobrarla como entregable con dueño y fecha en la próxima sesión — sin ella, T09 no cierra y el almacén de consignación queda sin ancla. Mientras tanto, el flujo se construye con el lookup y se carga el dato cuando llegue (no bloquea el desarrollo).

---

## 3. Resumen de acciones

| # | Acción | Responsable |
|---|---|---|
| 1 | Verificar si los campos `Actual*` sirven como criterio en `VehicleSearchableField` | Santiago (Setup) |
| 2 | Verificar si `Appraisal.PurposeType` admite valores nuevos (¿picklist restringido?) | Santiago (Setup) |
| 3 | Aplicar Op.2 híbrida en T10 (reutilizar VehicleDefinition real cuando el modelo existe) | Santiago |
| 4 | Definir ventana de vigencia del avalúo reutilizado de HU-036 | Negocio |
| 5 | Registrar Inventory Search como paso manual por ambiente en el DLG | Santiago |
| 6 | Cobrar la lista de Locations por sociedad | Diego / cliente |
| 7 | Separar T10 en lógica (avanza) y pantallas (espera prototipo de Gastón) | Santiago |
