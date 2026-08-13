# HU-045, vehículo usado y consignación. Resumen del estado y respuesta a las 6 definiciones

Fecha: 13/08/2026. Para Santiago. Base: planillas de tareas técnicas v3.1 a v5, diagrama funcional, Automotive Cloud Developer Guide (objetos estándar y guías de campo) y verificación pendiente en la org con el script GAPCHECK6.

## 1. Qué avanza ahora y qué espera el prototipo

La HU-045 y la HU-046 quedaron bloqueadas el 12/08 esperando los prototipos de UX de Gastón. Eso no detiene el frente técnico, conviene separar dos carriles para no construir algo que después se rehaga.

Avanza ahora, sin depender del prototipo: modelo de datos, T12 avalúo, T13 consignación, T15 baja al vender, T24 AssetMilestone, T23 configuración de búsqueda de inventario, T16 permisos.

Espera el prototipo aprobado: solamente las pantallas del T10, porque es un Screen Flow y su layout, el orden de pasos y las validaciones visibles salen del diseño.

Recomendación concreta: construir el T10 como lógica más subflows (chequeo de VIN, crear o actualizar Asset y Vehicle, publicar el evento) y dejar la capa de pantallas para el final. Así avanza la mayor parte del T10 y solo se ajusta la piel cuando llegue el prototipo.

## 2. Lectura del estado

Lo realizado está sólido y es coherente con el modelo Automotive: la unidad anclada en Asset como master y Vehicle como detalle, el almacén en `Asset.LocationId`, la consignación en Contract con Record Type propio, la trazabilidad en Field History y el aviso de alta por Platform Event. Nada de eso hay que rehacer.

El camino crítico es el T10 y depende de las definiciones 1 y 2, por eso van primero y con más detalle.

## 3. Las 6 definiciones

### Definición 1. Marca, modelo y año reales del usado

Confirmo tu Op.2 (campos custom), con una mejora, hacerla híbrida, y con un hallazgo que conviene incorporar.

Tu diagnóstico de que `MakeName`, `ModelName`, `ModelYear` y `TrimLevel` en Vehicle son de solo lectura y derivan del VehicleDefinition es correcto, y tumba el plan original.

Op.1 pura, un find or create de VehicleDefinition por cada unidad, no. Crearía un modelo de catálogo por cada usado que entra y ensuciaría el catálogo que alimenta la búsqueda de la venta guiada, los informes y la administración de precios. Es exactamente lo que estamos evitando en el frente de Financial, ADR-004.

Op.2 pura tampoco es gratis: si el usado cuelga de un VehicleDefinition genérico, la búsqueda nativa por marca y modelo no lo encuentra por los campos derivados.

Propuesta, Op.2 híbrida, find or REUSE, no find or create:

1. Si el modelo del usado ya existe en el catálogo, que es el caso más común en trade in porque es una marca que GrupoQ vende, se reutiliza ese VehicleDefinition real. No se crea nada y la unidad queda buscable de forma nativa.
2. Si el modelo no existe, marca fuera de catálogo, se usa el VehicleDefinition genérico más los campos `ActualMake__c`, `ActualModel__c`, `ActualTrimLevel__c` y `ActualModelYear__c` que ya creaste.
3. Los campos `Actual*` se llenan siempre, en los dos casos, para tener fuente única para informes, para impuestos (el año numérico limpio, insumo de la HU-105) y para la búsqueda.

Hallazgo de la documentación que conviene aprovechar: en `AppraisalItem`, los campos estándar `MakeName`, `ModelName` y `ModelYear` existen y son picklists restringidas. Es decir, la plataforma ya modela la marca y el modelo del ítem avaluado de forma independiente del VehicleDefinition. Consecuencia práctica: del lado del avalúo probablemente no necesites campos custom, alcanza con extender esas picklists, que son metadata desplegable por ambiente. Los campos `Actual*` siguen siendo necesarios, pero del lado de la unidad, no del avalúo.

Verificación obligatoria antes de cerrar, está en el script GAPCHECK6: confirmar que los campos `Actual*` se pueden usar como criterio en la configuración de búsqueda de inventario. La documentación dice que además de armar el dataset con `VehicleSearchableField` se puede crear una configuración de búsqueda directamente sobre el objeto Vehicle, y ese es el camino que haría viables los `Actual*` como criterio. Si no se pudiera, el punto 1, reutilizar el VehicleDefinition real cuando el modelo existe, pasa de recomendable a obligatorio.

### Definición 2. VehicleDefinition y Product2 genéricos «Used Vehicle»

De acuerdo, con tres condiciones y una adición importante que salió de la revisión del modelo estándar.

1. El Product2 genérico se crea con `Family = No Comercializado` y nunca con PricebookEntry en una lista comercial. Es la misma regla que acordamos para los productos financiables: sin entrada de precio no es cotizable, y con la Family fuera de la allowlist no aparece en la búsqueda del flujo guiado.
2. Orden de creación confirmado, Asset primero y Vehicle después, porque `Vehicle.AssetId` es master detail y el centro vive en `Asset.LocationId`. En el Asset van sociedad, LocationId, PurchaseDate y AssetProvidedById.
3. El ex GQ conserva su VehicleDefinition real, y por VIN único el reingreso actualiza el mismo Vehicle, nunca crea otro. Con la Op.2 híbrida, además, cualquier usado de una marca del catálogo también conserva la definición real.

Adición: para la consignación el modelo estándar tiene un objeto que hoy no está en el diseño y que resuelve justo el punto delicado, que la unidad está en nuestro predio pero no es nuestra.

`AssetAccountParticipant`, API 56 y superior, es la junction entre Asset y Account, «the association between a participating account and an asset», con su equivalente `AssetContactParticipant` para personas. Es el lugar nativo del consignante como participante de la unidad, y está confirmado disponible en la org, verificado el 13/08 con `check-licencias-objetos.apex`.

Esto no reemplaza al Contract, lo complementa. El Contract queda para las condiciones comerciales de la consignación, plazo, comisión, precio mínimo, y la relación con el dueño queda en el objeto que la plataforma tiene para eso. La ventaja concreta es que la relación dueño y unidad sobrevive al Contract, sirve para la baja al vender (T15) y evita campos custom de dueño en el Asset.

Sobre la titularidad legal, el estándar tiene además `AssetTitle`, «information that establishes the legal ownership of an asset or a vehicle», con `AssetTitleParty`. Sería el lugar ideal para el título del vehículo consignado, pero la verificación del 13/08 muestra que **esos dos objetos no existen hoy en la org**, aunque sí están contratadas y asignadas las licencias de Vehicle and Asset Finance Foundation y Vehicle and Asset Lending for Agents. O sea que no parece un tema de licencia sino de habilitación en Setup, en Enable Features for Automotive Cloud. Mientras no aparezcan, el diseño no depende de ellos: `AssetAccountParticipant` más Contract cubre la consignación. Vale revisar el toggle porque si se habilita sin costo, es el lugar correcto del título.

### Definición 3. Avalúo, a qué registro se liga

Tu recomendación es correcta y coincide con la semántica oficial: `Appraisal` es «the appraisal for one or more items» y `AppraisalItem` es «an item that is appraised, such as a vehicle or an asset». Entonces `Appraisal.ReferenceRecordId` apunta a la Account del vendedor o consignante, el para quién, y `AppraisalItem.ReferenceRecordId` apunta a la unidad, el qué.

Tres precisiones que salieron de la documentación:

1. `AppraisalItem.ReferenceRecordId` es polimórfico, la doc dice explícitamente «such as an Asset or Vehicle record with a serial number or a vehicle identification number». Regla para nosotros: si la unidad tiene VIN y por lo tanto tiene registro Vehicle, se apunta al Vehicle; si es una unidad sin Vehicle, por ejemplo una parte o un accesorio, se apunta al Asset. Conviene dejarlo escrito para que el flow no decida caso por caso.
2. `PurposeType` tiene documentados los valores Sale y Trade In, o sea que ni «Compra Directa» ni «Consignación» existen de fábrica. Antes de agregarlos hay que confirmar si la picklist es restringida, está en el script. Si admite valores nuevos se agregan y listo, es metadata desplegable. Si es restringida y no se puede extender, la alternativa es un campo propio de propósito en el Appraisal sin tocar el estándar. Son dos minutos de verificación y evitan un rework del T12.
3. El avalúo no son dos objetos, son cinco, y tres de ellos nos ahorran campos custom. `AppraisalAdjustment` es «an adjustment for the appraisal or an appraisal item» y tiene `TotalAdjustmentValue`, ahí van los descuentos por estado, golpes, kilometraje, en vez de campos sueltos. `AppraisalItemProviderVal` es «a valuation of the item that is appraised», sirve para guardar más de una valuación sobre la misma unidad, por ejemplo el peritaje interno y un valor de referencia externo, con trazabilidad de cuál se usó. `AppraisalItemAddOn` es «an add on product, such as an accessory, that enhances or complements the appraised item», ahí van los accesorios que suman valor. Vale la pena revisar el T12 contra estos tres antes de crear campos.

Sobre reutilizar el avalúo de trade in de la HU-036, sí, con una regla que hay que fijar con negocio: ventana de vigencia del avalúo, por ejemplo X días, pasado ese plazo se exige uno nuevo. Sin esa regla un avalúo viejo entra en una compra nueva.

### Definición 4. Búsqueda de inventario nativa contra list views

Sí, adoptar la búsqueda de inventario nativa como base, con las list views del T17 como fallback. Cubre lo que las list views no cubren, búsqueda filtrable multicriterio y traslado de unidades entre sucursales, y es el mecanismo que el propio Automotive Cloud ofrece para esto.

Tu nota es importante y la firmo: se configura por Setup en cada org y no es totalmente desplegable, así que entra en el DLG como paso manual por ambiente, DEV, QA, UAT y PROD, con checklist. Es el tipo de ítem que si no queda escrito se descubre el día del go live.

Cuidado con los nombres, porque hay tres objetos parecidos y solo uno es el nuestro:

1. `VehicleSearchableField`, API 58, «a common dataset including multiple fields and values from multiple objects and is used as the basis for inventory search related to vehicles». Este es el de inventario, el que nos sirve.
2. `VehDefSearchableField`, API 63, es para buscar especificaciones de modelo «in vehicle and asset lending». No es el nuestro.
3. `DealerVehDefSearchableField`, API 65, es para búsquedas de concesionarios por ubicación. Tampoco es el nuestro.

Y el enganche con la definición 1: la configuración de búsqueda tiene que incluir los campos donde vive la marca y el modelo real del usado, sea porque se reutiliza el VehicleDefinition o porque los `Actual*` entran como criterio.

### Definición 5. AssetMilestone «Resale» en R1

Sí, en R1, por tres razones.

1. El objeto existe exactamente para esto, `AssetMilestone` representa «the key events in the lifecycle of a vehicle asset, such as manufacturing, registration, or resale». La reventa está nombrada en la definición del objeto.
2. El costo es un elemento «Create Records» dentro de un flow que igual se va a construir, el T10, o sea minutos.
3. No es retroactivo. Si entra después se pierde el historial de todo el período de R1 y no se puede reconstruir. Barato ahora, imposible luego.

### Definición 6. Locations de consignación

`Asset.LocationId` es el modelo nativo y no hay que buscar alternativa. Lo que falta es el dato, la lista de Locations por sociedad, que es la misma pendiente del T09 y del hilo de la HU-046.

Acción: cobrarla como entregable con dueño y fecha en la próxima sesión. Sin ella el T09 no cierra y el almacén de consignación queda sin ancla. Mientras tanto el flujo se construye con el lookup y el dato se carga cuando llegue, no bloquea el desarrollo.

## 4. Verificaciones en la org

Están todas en un solo script, `docs/scripts/gapcheck6-hu045-usado-consignacion.apex`, para ejecutar en Developer Console, Execute Anonymous, con Open Log y Debug Only activados. Responde de una vez:

1. Si existen en la org `Appraisal`, `AppraisalItem`, `AppraisalAdjustment`, `AppraisalItemProviderVal`, `AppraisalItemAddOn`, `AssetTitle`, `AssetTitleParty`, `AssetAccountParticipant`, `AssetMilestone`, `VehicleSearchableField` y `SellerProduct`.
2. Si `Appraisal.PurposeType` es picklist restringida y qué valores tiene hoy.
3. Qué valores admite el tipo de hito en `AssetMilestone`, para saber si «Resale» ya está o hay que agregarlo.
4. Qué campos de Vehicle son calculados o no editables, que es la confirmación formal de tu hallazgo sobre `MakeName` y compañía.
5. Qué campos custom ya existen en Vehicle y en Asset, incluidos los `Actual*`, para ver qué queda por crear.
6. Si `AppraisalItem.MakeName`, `ModelName` y `ModelYear` son restringidas en la org y con qué valores.

## 4bis. Licencias, verificado en la org el 13/08

Ejecutado `docs/scripts/check-licencias-objetos.apex` en DEV Sales. Resultado, ningún bloqueo de licencia para la HU-045.

Sin licencia adicional, todo disponible: `Product2`, `Pricebook2`, `PricebookEntry`, `Opportunity`, `OpportunityLineItem`, `Quote`, `QuoteLineItem`, `Order`, `OrderItem`, `Asset`, `Location`, `Contract`, `Account` y `Contact`.

Automotive Cloud, todo disponible y con licencias holgadas: `Vehicle`, `VehicleDefinition`, `AssetMilestone`, `VehicleSearchableField`, `AssetAccountParticipant`, `AssetContactParticipant`, `LeadLineItem` y `OpportunityPreferredSeller`. Las permission set licenses contratadas son Automotive Foundation User con 2130 asientos y 10 en uso, Automotive Scheduler 2130 con 8, Fleet Management 2130 con 4, Vehicle Connected Services 2130 con 3, Warranty Lifecycle Management 2130 sin uso y Einstein for Automotive 80 con 5. Todas vencen el 10/02/2031.

Avalúo, todo disponible: `Appraisal`, `AppraisalItem`, `AppraisalAdjustment`, `AppraisalItemAddOn` y `AppraisalItemProviderVal`. Las licencias del bloque de finance están contratadas y asignadas, Vehicle and Asset Finance Foundation 2130 con 2 en uso y Vehicle and Asset Lending for Agents 2130 con 2.

Única excepción: `AssetTitle` y `AssetTitleParty` no existen en la org. Como las licencias de lending sí están, lo más probable es que falte el toggle en Setup, Enable Features for Automotive Cloud. No bloquea la HU-045 porque la consignación se resuelve con `AssetAccountParticipant` más Contract.

Taxonomía de catálogo, disponible y con licencia propia: `ProductCatalog`, `ProductCategory`, `ProductCategoryProduct`, `ProductRelatedComponent`, `ProductClassification` y `BusinessBrand`. La org tiene Product Catalog Management Administrator con 4261 asientos y 4 en uso, y Product Catalog Management Viewer con 6391. Esto no afecta a la HU-045 pero confirma la propuesta del ADR-004 para parametrizar marcas y modelos sin crear objetos.

## 5. Acciones

1. Ejecutar el GAPCHECK6 y pegar el log. Responsable Santiago.
2. Según el resultado, decidir si los `Actual*` entran como criterio de búsqueda o si la reutilización del VehicleDefinition real pasa a obligatoria. Responsable Santiago y Diego.
3. Aplicar la Op.2 híbrida en el T10. Responsable Santiago.
4. Revisar el T12 contra `AppraisalAdjustment`, `AppraisalItemProviderVal` y `AppraisalItemAddOn` antes de crear campos custom. Responsable Santiago.
5. Incorporar `AssetTitle`, `AssetTitleParty` y `AssetAccountParticipant` al diseño de consignación del T13, si el script confirma que están disponibles. Responsable Santiago.
6. Definir la ventana de vigencia del avalúo reutilizado de la HU-036. Responsable negocio.
7. Registrar la configuración de búsqueda de inventario como paso manual por ambiente en el DLG. Responsable Santiago.
8. Cobrar la lista de Locations por sociedad. Responsable Diego con el cliente.
9. Separar el T10 en lógica, que avanza, y pantallas, que esperan el prototipo de Gastón. Responsable Santiago.

## 6. Fuentes

1. Automotive Cloud Standard Objects, Automotive Cloud Developer Guide, definiciones citadas de `Appraisal`, `AppraisalItem`, `AppraisalAdjustment`, `AppraisalItemProviderVal`, `AppraisalItemAddOn`, `AssetTitle`, `AssetTitleParty`, `AssetAccountParticipant`, `AssetMilestone`, `VehicleSearchableField`, `VehDefSearchableField`, `DealerVehDefSearchableField`, `Vehicle`, `VehicleDefinition`.
2. AppraisalItem, Automotive Cloud Developer Guide, `ReferenceRecordId` polimórfico hacia Asset o Vehicle, `MakeName`, `ModelName` y `ModelYear` como picklists restringidas, `RegistrationState`.
3. Appraisal, `PurposeType` con valores documentados Sale y Trade In.
4. AppraisalAdjustment, campo `TotalAdjustmentValue` acumulado por ítem.
5. Set Up Vehicle Inventory Search in Automotive Cloud, Salesforce Help, dataset con `VehicleSearchableField` y opción de configurar la búsqueda directamente sobre el objeto Vehicle.
6. How Assets and Vehicles Are Related in Automotive Cloud, Salesforce Help, todo vehículo es un Asset pero no todo Asset es un vehículo.
