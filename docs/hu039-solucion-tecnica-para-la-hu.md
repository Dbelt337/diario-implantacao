# HU-039 — Solución Técnica

Sección lista para incorporar al documento de la historia. Cierra el diseño: cada regla de negocio y cada criterio de aceptación tiene un lugar definido, y las definiciones que todavía dependen de terceros no cambian el diseño, solo cambian un parámetro.

---

## 1. La arquitectura en una frase

**La solicitud y el material son el mismo registro Product2.** Nace inactivo con Record Type de solicitud durante la atención, y se convierte en material definitivo cuando SAP confirma la carga del código en el Maestro de Materiales. No se crea ningún objeto custom (RN-05, RN-09).

---

## 2. Dónde vive cada cosa

| Elemento | Dónde vive | Mecanismo |
|---|---|---|
| La solicitud | `Product2` con Record Type de solicitud, `IsActive = false` | Estándar |
| El material definitivo | El **mismo** `Product2`, con Record Type Material, `IsActive = true` | Estándar |
| Los dos tipos de solicitud | Record Types `MaterialRequestOriginalPart` y `MaterialRequestWildcardCode` | Estándar |
| El disparador del Tiempo 1 | Componente LWC dentro del flujo de venta guiada | Búsqueda sin resultado |
| La gestión del Tiempo 2 | Página del registro Product2, con List Views filtradas por Record Type | Estándar |
| Estado de la solicitud | `RequestStatus__c`, picklist restringida | Pending, InReview, MaterialCreated, Rejected |
| Clave anti duplicado y de correlación con SAP | `RequestKey__c`, texto único y External ID | Base de datos |
| Sociedad | Lookup a `InternalOrganizationUnit` | 19 registros ya cargados |
| Centro y sucursal | Lookups a `Location` | 20 registros ya cargados |
| Marca | **`BusinessBrandId`, campo estándar de Automotive** | 23 registros ya cargados. No se crea ningún campo |
| Código solicitado | **`ProductCode`, campo estándar** | Queda libre porque el código definitivo del SAP vive en `SapMaterialCode__c`. Como la solicitud y el material son el mismo registro, lo lleva desde el inicio |
| Partida arancelaria | **`HarmonizedTariffSchedCode`, campo estándar** | La RFC rechaza la creación cuando falta. El campo ya existe |
| Código SAP definitivo | `SapMaterialCode__c` | Ya existe en la org |
| Adjuntos | Salesforce Files | Estándar (RN-57) |
| Trazabilidad de cambios | Field History Tracking sobre Product2 | Estándar (RN-58) |
| Aviso a los seguidores | Chatter Follow más Feed Tracking del campo de estado | Estándar (RN-56) |
| Aviso al asesor solicitante | Custom Notification al usuario de `CreatedById` | Estándar, siempre viene lleno |
| Aprobaciones de PA | Approval Process sobre Product2, o Flow Orchestration si Product2 no lo admite | Estándar |
| Errores e incidencias | `SapLastAttempt__c` en el registro, detalle del error en el log | Nebula Logger ya está instalado en la org |
| Llamadas a SAP | Named Credential más la fachada de integración ya existente | MuleSoft |

---

## 3. El recorrido, paso a paso

### Tiempo 1, durante la atención

1. El asesor busca el material. La búsqueda local filtra por producto activo, de modo que **una solicitud pendiente nunca aparece** y por lo tanto no puede entrar en la cotización (RN-07, CA-04).
2. Si no hay resultado, el sistema pregunta al asesor si desea generar el código (RN-18). Si no confirma, el flujo sigue sin generar nada (Escenario 2).
3. Si confirma, se consulta SAP de forma síncrona, Maestro de Materiales y Maestro de Fábrica (RN-19).
4. Si el material existe para la sociedad y el centro, se actualiza el catálogo y la venta sigue con el ítem (RN-20, Escenario 1).
5. Si existe pero no está creado para el centro, se intenta la extensión automática. Si funciona, la venta sigue con el ítem y no se genera solicitud (RN-21).
6. Si no existe, o la extensión falla, o SAP no responde dentro del tiempo máximo, se informa al asesor y **se crea la solicitud prellenada** con sociedad, centro y sucursal, y la venta sigue sin ese ítem (RN-23, Escenario 3).
7. En ningún caso la venta espera. El resto de la cotización continúa (RN-02, RN-03, CA-03).

**Regla técnica que ordena estos pasos:** todas las llamadas a SAP ocurren **antes** de cualquier escritura en la base. La plataforma prohíbe llamar a un sistema externo después de haber escrito en la misma transacción, de modo que el orden consultar, extender y recién después grabar no es una preferencia de diseño sino un requisito de la plataforma. La espera máxima al SAP se configura corta y explícita, y su vencimiento se trata como fallo, cayendo al paso 6.

### Tiempo 2, Repuestos

1. La solicitud aparece en la List View del Equipo de Gestión de Inventarios, filtrada por Record Type.
2. El área revisa, completa los datos y carga el código en el Maestro de Materiales de SAP, fuera de Salesforce, porque no tiene usuario Salesforce (RN-38).
3. **No hay ninguna aprobación en Salesforce** (RN-36, CA-11).
4. SAP comunica la carga y devuelve el MATNR y los datos maestros (RN-41).
5. Salesforce graba el MATNR en el mismo registro, completa los datos maestros, cambia el Record Type a Material, activa el registro y lo lleva a Material Creado (RN-42, RN-43, CA-13).
6. Se notifica al asesor solicitante y a los seguidores (RN-55, CA-14).

### Tiempo 2, PA

1. La solicitud se dirige al Gerente de Categoría (RN-26).
2. El Gerente de Categoría valida traer el producto y cotiza con fábrica el material y el envío.
3. Con la cotización cargada, **somete a aprobación**: primero Director de PA, después Vicepresidente de PA (RN-44, RN-45, CA-12).
4. Obtenido el visto bueno, solicita a Gestión de Inventarios la creación del código, de forma manual y fuera de Salesforce (RN-46).
5. Desde ahí el recorrido es idéntico a los pasos 4 a 6 de Repuestos.

**Detalle operativo de la aprobación:** durante el proceso de aprobación el registro queda bloqueado para edición. Por eso el Gerente de Categoría carga la cotización **antes** de someter, no después.

---

## 3bis. Cuándo se consulta a SAP y cuándo no

Como el catálogo de materiales se replica a Salesforce, conviene dejar explícito qué preguntas se responden localmente y cuáles obligan a llamar a SAP. Son cuatro preguntas distintas y tienen respuestas distintas.

| Pregunta | ¿Necesita API? | Por qué |
|---|---|---|
| ¿El material existe? | **No** | Se responde contra el catálogo replicado |
| ¿Está creado para mi sociedad y centro? | **No, si la réplica trae los segmentos de centro y organización de ventas.** Ver más abajo | Es la pregunta que decide todo el volumen de llamadas |
| ¿Cuánto hay disponible? | **Sí, siempre** | El saldo cambia por minuto y ya se definió que viene de SAP en vivo (HU-043 RN4). Replicar saldo es una batalla perdida |
| ¿Cuál es el precio? | Según lo que defina la administración de precios | Fuera del alcance de esta historia |

**El diagrama de la historia ya dice esto y vale señalarlo:** la caja "Sistema valida el material esté creado" está pintada como Salesforce, no como SAP. La consulta al Maestro de Materiales y al Maestro de Fábrica aparece recién después de que el asesor confirma que quiere generar el código. Es decir, la validación de existencia es local por diseño, y la llamada a SAP es el camino de excepción.

### Por qué la API sigue siendo necesaria aunque el catálogo esté replicado

Tres motivos, y ninguno desaparece por replicar mejor:

1. **Latencia de la réplica.** Un material creado en SAP hace diez minutos puede no estar todavía en Salesforce. Es exactamente el caso que la RN-20 llama "catálogo desactualizado", y por eso esa regla existe: la consulta lo detecta y actualiza el catálogo en el momento.
2. **Materiales que no están en el Maestro de Materiales.** La nota del diagrama describe una tabla Z con los códigos de todos los fabricantes, que se consulta justamente cuando el material no está en el catálogo de materiales. Eso, por definición, **nunca puede llegar por la réplica**, porque no está en el maestro. Es el corazón de esta historia.
3. **Extensión a un centro nuevo.** Si el material existe pero no está creado para el centro del asesor, la extensión se ejecuta en SAP. Leer no alcanza, hay que escribir.

### La pregunta concreta que hay que hacerle al equipo SAP

El IDoc estándar de materiales tiene segmentos separados por nivel de dato: `E1MARAM` para el dato general, `E1MARCM` para el dato de centro, `E1MVKEM` para organización de ventas y canal de distribución, y `E1MARDM` para almacén.

**¿La réplica actual incluye `E1MARCM` y `E1MVKEM`, o solo `E1MARAM`?**

De la respuesta depende el diseño entero:

1. **Si trae los segmentos de centro y de ventas**, la pregunta "está creado para mi sociedad y centro" se responde localmente, la API queda como camino de excepción, y el volumen de llamadas es bajo. Además el destino natural del segmento de centro es el objeto estándar que relaciona producto y ubicación, de modo que la persistencia de la extensión por centro deja de ser una optimización que inventamos y pasa a ser simplemente dónde aterriza un dato que la réplica ya trae.
2. **Si solo trae el dato general**, entonces cada búsqueda necesita preguntarle a SAP si el material está creado para ese centro, la consulta síncrona deja de ser excepción y pasa a ser la norma, y hay que revisar la experiencia del mostrador antes de comprometer tiempos.

Es una sola pregunta, y es la que más impacto tiene sobre el rendimiento y sobre el esfuerzo de integración.

---

## 3ter. La RFC de creación de material, y cómo simplifica el diseño

Con el diccionario de datos de `ZQEV_DBM_CREACION_MATERIALES` a la vista, el diseño se simplifica de forma importante. Corrige además una afirmación anterior nuestra, que decía que faltaban tres piernas de integración: **dos de las tres ya existen y son esta misma función.**

### Qué hace y qué no hace la función

| Parámetro | Tipo | Obligatorio | Observación |
|---|---|---|---|
| `MATERIAL` | MATNR, 18 | **Sí** | **Es entrada, no salida** |
| `SOCIEDAD` | BUKRS, 4 | Sí | |
| `CANAL` | VTWEG, 2 | Sí | Canal de distribución |
| `SERIE` | ZSERIE_APLIC | Sí | Obligatoria para materiales ZREP |
| `VER_DEFAULT` | CHAR1 | No | Con X ejecuta lógica adicional y confirma la transacción |
| `MENSAJE` | CHAR255 | Salida | **Es la única salida** |

Tres consecuencias de diseño salen directo de esta tabla.

**Primera, y es la que más simplifica: SAP no asigna el código, el código se envía.** `MATERIAL` es entrada obligatoria. Entonces todo el circuito de "SAP crea, asigna un MATNR y lo devuelve para que Salesforce actualice el registro" **no aplica a esta función**. El código es el número de parte que el asesor ya tiene. Como la llamada es síncrona, el resultado se conoce en el momento.

**Segunda, la misma función hace la creación y la extensión.** Las variantes documentadas incluyen crear para distinta sociedad, distinto canal y distinta serie. Eso es exactamente la extensión de la RN-21, de modo que no hace falta un servicio aparte.

**Tercera, la función no devuelve datos maestros.** La única salida es un mensaje de 255 caracteres. Entonces la RN-48 y la RN-49, que piden que el retorno traiga descripción, disponibilidad, precio, rotación y cadena de sucesión, **no se satisfacen con esta función**. Esos datos llegan por la consulta de materiales o por la réplica del catálogo, en un segundo paso.

### El recorrido queda así, mucho más corto

1. Búsqueda local. Si aparece, la venta sigue.
2. Si no aparece, se pregunta al asesor si desea generar el código (RN-18).
3. Si confirma, se llama a `ZQEV_DBM_CREACION_MATERIALES` de forma síncrona.
4. Si el mensaje es de éxito, el material **ya existe en SAP**. Se consulta para traer los datos maestros, se crea o actualiza el producto en Salesforce, se activa, y la venta sigue con el ítem.
5. Si el mensaje es de error, se informa al asesor, se crea la solicitud prellenada inactiva y la venta sigue sin ese ítem (RN-23).

El Tiempo 2 no desaparece, **pasa a ser el camino de excepción en lugar de ser la regla.** Es donde caen los casos que la RFC rechaza.

### Cuándo la RFC rechaza, que es exactamente el alcance del Tiempo 2

La documentación declara dos validaciones que producen rechazo:

1. **Serie obligatoria.** Los materiales ZREP deben tener serie; si no la tienen, el material se elimina del procesamiento.
2. **Partida arancelaria obligatoria.** Si no existe, el material se rechaza durante la carga.

Ambas son datos que el asesor no puede inventar en el mostrador. Por eso la solicitud al área responsable sigue teniendo sentido: es quien completa esos datos. Y como la función admite ser llamada de nuevo, **la solicitud completada se reenvía por la misma RFC**, sin necesidad de un servicio nuevo ni de una notificación de vuelta.

### Alcance real de la función

Las reglas internas fijan Tipo de Material ZREP, Unidad ZUN y Condición de Precio ZQRP. Es decir, **la función es de repuestos**. Esto es consistente con la RN-27, que dice que en PA la creación nunca se resuelve automáticamente y siempre pasa por solicitud, cotización y aprobación. PA no usa esta función.

### Lo que esto obliga a resolver, y es lo más urgente del diseño

`CANAL` y `SERIE` son entradas obligatorias, y **hoy el flujo de venta guiada no las tiene**. No son datos que el asesor tenga a mano ni que estén en la pantalla. Hay tres opciones y hay que elegir una:

1. Derivarlas del contexto, canal por sociedad y serie por la línea o el vehículo asociado;
2. Pedirlas al asesor en el momento de confirmar la creación;
3. Parametrizarlas por sociedad y centro en configuración.

**Sin resolver esto, el camino automático no se puede construir**, por más que la RFC exista. Es la definición más urgente de toda la historia, por encima incluso de la lista de campos de la RN-49.

---

## 3quater. Cómo se entera quien tiene que crear el material

Pregunta abierta y conviene ser explícito: **hoy no está definido**, y la propia historia lo declara así en la RN-54, donde dice que el aviso inicial al área responsable se hace por fuera del sistema, por llamada, mensaje o correo, a criterio del vendedor, y que queda pendiente confirmar si ese aviso puede salir por correo desde Salesforce.

Hay una restricción de fondo que conviene nombrar, porque explica el problema y también explica otro punto de la historia: **no se puede notificar dentro de un sistema a quien no tiene usuario en ese sistema.** La RN-38 y la RN-62 dicen que Gestión de Inventarios no tiene usuario Salesforce en esta fase.

Y es exactamente la misma restricción que deja sin dueño el estado En revisión. La RN-15 dice que el área responsable actualiza los estados, pero sin usuario no puede hacerlo. **La pregunta de la notificación y la pregunta del estado son la misma pregunta.**

### Tres opciones, con su costo real

| Opción | Cómo funciona | Costo | Consecuencia |
|---|---|---|---|
| **1. Correo desde Salesforce a un buzón compartido** | Alerta automática al crear la solicitud, dirigida a una casilla o grupo de Gestión de Inventarios | Cero desarrollo. No requiere usuario Salesforce | Resuelve el aviso, **no resuelve la trazabilidad**: nadie puede marcar En revisión, así que no se sabe si alguien la tomó |
| **2. Aviso dentro de SAP** | SAP genera una tarea o entrada de trabajo para el analista | **Desarrollo SAP nuevo.** Cuando la RFC rechaza no se creó nada en SAP, así que no hay de dónde disparar un aviso: habría que enviar la solicitud a SAP como registro pendiente. No figura en ningún inventario de integraciones | Resuelve el aviso en la herramienta donde esa persona trabaja, al costo de una integración y un desarrollo que hoy no existen |
| **3. Dar usuario Salesforce a Gestión de Inventarios** | Trabajan la solicitud desde su List View, como ya lo hace el Catman en PA | Licencias y perfiles. La org tiene 2554 licencias Salesforce con 48 en uso, así que **la licencia no es la restricción** | Resuelve aviso y trazabilidad de una sola vez, con lo nativo: vista de lista, estado, seguimiento del registro e historial |

### La opción 2 sí es viable: SAP tiene APIs para esto

Revisamos la documentación de SAP y **existen módulos de función habilitados para RFC**, es decir invocables desde MuleSoft, que sirven exactamente para avisar dentro de SAP. Son tres caminos con alcances distintos.

| Camino | Módulo de función | Qué produce | Nivel |
|---|---|---|---|
| **Work item de workflow** | `SAP_WAPI_START_WORKFLOW`, o `SAP_WAPI_CREATE_EVENT` si se prefiere disparar por evento | Un **ítem de trabajo** en la bandeja del analista, con estado, responsable y fecha de cierre. Devuelve el ID del work item | Tarea real |
| **Mensaje en la bandeja de SAP** | `SO_NEW_DOCUMENT_SEND_API1` o `SO_DOCUMENT_SEND_API1`, con tipo de destinatario `B` | Un mensaje en el Business Workplace. Se lee, pero no se gestiona | Aviso |
| **Correo** | Los mismos, con tipo de destinatario `U` | Un correo | Aviso |

**El caso de la tabla que hay que descartar es el tercero**, y por una razón de arquitectura: si la respuesta es un correo, pasar por SAP y MuleSoft no agrega nada, Salesforce lo envía de forma nativa. Ir por SAP solo se justifica si el aviso tiene que **vivir dentro de SAP como trabajo**.

**Una advertencia operativa sobre el segundo camino:** los mensajes enviados a la bandeja de SAP **no generan aviso por correo por sí solos**. Para que el analista se entere sin abrir el Business Workplace hay que ejecutar el programa estándar `RSWUWFML2`, que es el que reenvía por correo los ítems de la bandeja. Si esto no se contempla, el aviso llega a un buzón que nadie mira.

Descartamos también `BAPI_ALM_NOTIF_CREATE`: crea una notificación de mantenimiento o de calidad, que es un objeto de negocio con otra semántica y no corresponde a la creación de un material.

### El diseño con workflow, que es el que resuelve las dos cosas a la vez

El primer camino tiene una propiedad que los otros no tienen, y es la que cierra el problema de fondo: **un work item tiene estado y devuelve un identificador**. Eso permite saber si alguien lo tomó, quién y cuándo, sin que esa persona necesite usuario Salesforce. Es exactamente la trazabilidad que la RN-15 y el CA-06 piden y que la opción del correo no da.

El enrutamiento en MuleSoft quedaría así:

1. Salesforce crea la solicitud y **publica un evento de plataforma**. No llama a MuleSoft en la misma transacción, porque la plataforma prohíbe hacer una llamada externa después de haber escrito en la base. El evento es el mecanismo previsto para esto.
2. MuleSoft se suscribe y **enruta por línea de negocio y por motivo de rechazo**. Repuestos va a workflow de SAP; PA no va a SAP, porque su circuito son las aprobaciones dentro de Salesforce. Y dentro de Repuestos, falta de serie y falta de partida arancelaria pueden ir a responsables distintos.
3. MuleSoft invoca `SAP_WAPI_START_WORKFLOW` pasando en el contenedor la clave de la solicitud, el código, la sociedad, el centro, la marca, la descripción, el solicitante y el motivo del rechazo.
4. **El ID del work item vuelve a Salesforce** y se guarda en el registro. Con eso la solicitud queda enlazada a la tarea de SAP.
5. Cuando el analista completa el work item, SAP avisa a MuleSoft y MuleSoft actualiza la solicitud por su clave, poniéndola En revisión, Material Creado o Rechazado.

Con ese ida y vuelta, **el estado deja de estar huérfano** y Gestión de Inventarios sigue trabajando solo en SAP, que es la premisa de la RN-38.

**Lo que hay que construir de cada lado.** Del lado Salesforce es poco: un evento de plataforma, un campo para el ID del work item y el endpoint de retorno, todo dentro de lo ya diseñado. Del lado SAP no es gratuito: hace falta **definir el workflow y las reglas de determinación de agente**, o sea quién recibe según sociedad y centro. Eso es desarrollo SAP con costo real, y es la parte que hay que dimensionar antes de comprometerla.

### Recomendación

**Opción 1 para el R1**, porque no bloquea nada y se implementa con una alerta de correo desde Salesforce, sin pasar por SAP ni por MuleSoft.

**Opción 2 con workflow como objetivo**, porque es la única que resuelve el aviso y la trazabilidad respetando la premisa de que Gestión de Inventarios no usa Salesforce. Las APIs existen y son invocables desde MuleSoft; lo que falta dimensionar es la definición del workflow y la determinación de agente del lado SAP.

**Opción 3 como alternativa a comparar**, porque si dar usuario Salesforce resulta más barato que definir el workflow en SAP, es la solución más simple de las tres, y la licencia no es el obstáculo.

La decisión entre la 2 y la 3 es, en el fondo, dónde queremos que viva el trabajo del analista. Conviene tomarla con los dos números sobre la mesa.

---

## 4. Cobertura de las reglas de negocio

| Bloque | Reglas | Cómo queda cubierto |
|---|---|---|
| 1. Modelo en dos tiempos | RN-01 a RN-04 | El Tiempo 1 vive en el flujo de venta guiada y el Tiempo 2 en el registro. El flujo crea la solicitud y no espera respuesta, por eso ningún paso del Tiempo 2 puede bloquear la venta |
| 2. Modelación | RN-05 a RN-09 | Product2 con tres Record Types. El mismo registro cambia de Record Type al activarse, de modo que no existe migración ni segundo producto |
| 3. Estados | RN-10 a RN-16 | `RequestStatus__c` restringida con los cuatro estados. Pending e InReview cuentan como solicitud abierta a efectos de duplicados, porque son los estados en que `RequestKey__c` está poblado |
| 4. Tiempo 1 Repuestos | RN-17 a RN-23 | Recorrido de la sección 3. La creación automática se limita a Repuesto Original por Record Type, el Código Comodín siempre genera solicitud |
| 5. Tiempo 1 PA | RN-24 a RN-27 | En PA la extensión automática aplica solo entre centros de la misma sociedad. Fuera de eso siempre se genera solicitud al Gerente de Categoría |
| 6. Sociedad, centro y sucursal | RN-28, RN-29 | Tres lookups obligatorios por layout. La disponibilidad se evalúa siempre por sociedad y centro, nunca global, porque son parte de la clave |
| 7. Tipos y datos requeridos | RN-30 a RN-32 | Obligatoriedad diferenciada por Record Type mediante los layouts. Los dos procesos no se mezclan porque son Record Types distintos con List Views distintas |
| 8. Duplicados | RN-33 a RN-35 | Ver sección 5.1. El Flow informa, la base de datos garantiza |
| 9. Tiempo 2 Repuestos | RN-36 a RN-43 | Sin aprobaciones. El estado llega por integración porque el área no tiene usuario Salesforce. El retorno actualiza el mismo registro por External ID |
| 10. Tiempo 2 PA | RN-44 a RN-47 | Aprobación de dos niveles sobre el registro. El Gerente de canal accede por perfil de solo lectura |
| 11. Datos maestros | RN-48 a RN-50 | Los atributos devueltos se graban en el mismo registro. Rotación en `TurnoverClass__c` y cadena de sucesión en `SupersededByProduct__c`, autorrelación a Product2 |
| 12. Errores y respuesta de SAP | RN-51 a RN-53 | Reintento con contador y tope explícito, incidencia registrada en el propio registro, y el registro nunca se activa ante error |
| 13. Notificaciones | RN-54 a RN-56 | Custom Notification al solicitante y Feed Tracking para los seguidores. Sin notificaciones custom entre áreas y **sin Case** |
| 14. Adjuntos y trazabilidad | RN-57 a RN-60 | Salesforce Files, Field History y Chatter, todo centralizado en el registro de la solicitud |
| 15. Roles y permisos | RN-61 a RN-63 | Control por perfil, asignación de Record Type por perfil y List Views por Record Type. Ver la limitación documentada en la sección 7 |

### Criterios de aceptación

| Criterio | Dónde queda cubierto |
|---|---|
| CA-01, CA-02, CA-03 | Recorrido del Tiempo 1, sección 3 |
| CA-04 | Doble barrera: la búsqueda filtra por activo, y la plataforma no admite entrada de precio activa para producto inactivo, de modo que un material inactivo no puede llegar a una cotización aunque alguien lo intente |
| CA-05, CA-09 | Tres Record Types sobre Product2, sin objeto custom |
| CA-06 | `RequestStatus__c` visible en el layout y en las List Views |
| CA-07 | Obligatoriedad por layout de cada Record Type |
| CA-08 | Sección 5.1 |
| CA-10 | Files y Field History |
| CA-11, CA-12 | Sin aprobación en Repuestos, aprobación de dos niveles en PA |
| CA-13 | Upsert por External ID, que actualiza el mismo registro por construcción |
| CA-14 | Dos mecanismos distintos, uno para el solicitante y otro para los seguidores |
| CA-15 | El material activo es cotizable por los mecanismos estándar, sin distinción entre cliente B2B y no B2B |
| CA-16 | Sección 5.4 |
| CA-17 | Perfiles de solo lectura para Jefe, Encargado, Gerente de Repuestos y Gerente de canal |

---

## 5. Las cuatro decisiones técnicas que sostienen la solución

### 5.1 Duplicados: el Flow informa, la base de datos garantiza

La RN-34 pide resolver los duplicados con Flow y descarta las Duplicate Rules. Se cumple. Pero un Flow por sí solo no resuelve el caso de dos asesores que consultan en el mismo instante: los dos no encuentran nada y los dos crean.

Por eso `RequestKey__c`, la combinación de código de material, sociedad y centro, es un campo **único**. La base de datos rechaza el segundo registro sin importar cuántos usuarios simultáneos haya. El Flow sigue siendo quien consulta antes y muestra el mensaje al asesor, ofreciéndole seguir la solicitud existente.

Y hay un detalle que hace funcionar la RN-14 sin ningún artificio: **un campo único ignora los valores nulos**. Al marcar la solicitud como Rechazada se limpia `RequestKey__c`, y una nueva solicitud sobre la misma combinación pasa a ser admisible, exactamente como pide la regla.

### 5.2 Correlación con SAP: el mismo campo sirve para las dos alternativas

`RequestKey__c` es además External ID, de modo que MuleSoft escribe el retorno de SAP directamente sobre el registro correcto, en una sola llamada y de forma idempotente. Esto garantiza la RN-43 por construcción de la base de datos y no por convención: **es imposible que el retorno cree un segundo Product2.**

Esta decisión es deliberadamente indiferente a la definición pendiente sobre la integración de salida:

1. Si SAP puede transportar y devolver un identificador nuestro, transporta este mismo valor;
2. Si no puede, el valor se reconstruye desde el código, la sociedad y el centro, que son datos que SAP conoce.

En los dos casos el campo es el mismo y el diseño no cambia. Cambia solo quién arma el valor.

### 5.3 El riesgo de la réplica de catálogo, y cómo queda contenido

La RN-43 advierte que la sincronización posterior del catálogo podría crear un Product2 duplicado. Ese riesgo tiene nombre concreto: la réplica estándar de materiales de SAP, que ya está en el alcance del programa.

El escenario es real. Si la réplica trae el material nuevo antes de que llegue la notificación de creación, crea un producto con el código SAP mientras la solicitud sigue sin él.

**Queda contenido porque el código SAP también es un campo único.** Cuando la notificación intente grabar ese mismo código sobre la solicitud, la base de datos lo rechaza. No es un fallo de integración, es la carrera con la réplica, y el tratamiento es determinista: se marca la solicitud como Material Creado, se mantiene inactiva, se notifica normalmente al asesor y se lo dirige al producto que la réplica ya creó. El resultado funcional es idéntico y no requiere intervención manual.

**Recomendación para eliminar la carrera en el origen:** pedir que la notificación de creación sea inmediata y no dependa de la ventana de la réplica de catálogo.

### 5.4 Errores y escalamiento sin abrir casos

Ante un error de SAP el proceso reintenta, con un contador que se guarda en el propio registro y un tope explícito, porque la plataforma acota los reintentos automáticos y un evento descartado en silencio deja a todos sin enterarse.

Ante falta de respuesta, el escalamiento **no puede ser un Case**, porque la RN-56 lo prohíbe. Se resuelve con alerta por correo a un grupo de responsables y una vista de lista de solicitudes trabadas ordenada por antigüedad, alimentada por la fecha del último intento. Lo único que falta definir es el destinatario y el tiempo de respuesta esperado, que es un parámetro de configuración y no una pieza de diseño.

En los dos casos el registro no se activa, no se marca como Material Creado y la incidencia queda registrada (RN-53, CA-16).

---

## 6. Decisiones tomadas por defecto para no bloquear el desarrollo

Cada una tiene una razón, y en ninguna el diseño cambia si la definición llega distinta.

| Punto pendiente | Decisión por defecto | Qué cambia si se define distinto |
|---|---|---|
| Integración de salida de Salesforce a SAP | Se diseña la correlación sobre `RequestKey__c`, que funciona con y sin ella | Nada estructural. Solo quién arma el valor de la clave |
| Quién actualiza los estados | En Repuestos los escribe la integración, porque el área responsable no tiene usuario Salesforce. En PA los escribe el Gerente de Categoría | Solo la propiedad de solo lectura del campo en un layout |
| Si Product2 admite Approval Process | Aprobación nativa. Si no lo admite, Flow Orchestration | Nada funcional. Los dos producen los mismos estados y el mismo bloqueo del registro |
| Persistir la extensión por centro | No se persiste en este release. Se consulta a SAP en cada búsqueda, que es lo que la RN-19 pide literalmente | Es una optimización posterior, con objeto estándar disponible, y no altera el modelo |
| Rotación como lista de valores | Campo de texto hasta que SAP confirme el conjunto cerrado de valores | Conversión a lista restringida, sin pérdida de datos |

---

## 7. Fuera del alcance de esta historia

Se declara explícitamente para evitar interpretaciones posteriores.

1. **El traslado entre centros de la RN-24.** La propia historia lo marca como pendiente de validación. Salesforce tiene objeto estándar para registrar traslados de inventario entre ubicaciones, de modo que la pregunta es dónde se registra y no si es posible. La construcción pertenece a la historia de pedido, no a esta.
2. **El diseño técnico de la integración**, tal como la propia historia establece.
3. **Notificaciones customizadas entre áreas y apertura de casos**, excluidas por la RN-56.
4. **Visibilidad por registro.** El objeto Product2 no admite reglas de compartición ni compartición manual, solo el valor por defecto de toda la organización. Lo que la historia pide sí se cubre: control por perfil, vistas por Record Type y acceso de solo lectura para las jefaturas. Pero si en el futuro se requiere que una sucursal no vea las solicitudes de otra, eso no es alcanzable sobre Product2 y obligaría a revisar la RN-05. Queda documentado aquí para que la decisión sea consciente.

---

## 8. Qué queda cubierto y qué no, sin adornos

De las 63 reglas de negocio, **59 quedan completamente resueltas con el diseño de esta sección**. Las 4 restantes son, todas, definiciones que la propia historia declara abiertas, más la lista de campos maestros. Ninguna depende de decisiones nuestras.

Además hay **una definición que no es una regla de negocio pero que bloquea la construcción del camino automático**, y es la más urgente de todas: de dónde salen el canal de distribución y la serie, que la RFC exige como entradas obligatorias. Está detallada en la sección 3ter.

### 8.1 Dependientes de servicios SAP

Con el diccionario de datos de `ZQEV_DBM_CREACION_MATERIALES` a la vista, esta lista se reduce mucho respecto de la evaluación inicial.

| Regla | Estado |
|---|---|
| RN-21, RN-22 | **Cubiertas.** La RFC crea y extiende, es síncrona, y sus variantes documentadas incluyen distinta sociedad, distinto canal y distinta serie |
| RN-41, RN-42 | **Ya no son necesarias en el camino automático**, porque la RFC devuelve el resultado en el momento y el código es dato de entrada. Siguen siendo necesarias solo si se decide que el camino de excepción se completa dentro de SAP en lugar de reenviarse desde Salesforce. Es una elección, no una dependencia |
| RN-48, RN-49 | **Pendientes.** La RFC devuelve únicamente un mensaje de 255 caracteres, así que los datos maestros llegan por la consulta de materiales o por la réplica. Falta la lista de campos |

Es decir, la ausencia de estos servicios en el inventario "Integraciones para cotizar y crear un pedido" era esperable y no era un vacío: ese inventario se armó para cotizar y crear pedidos, y la RFC de creación de material se documentó por separado, en el contexto de la HU-028.

Queda una trampa de nomenclatura que conviene igual señalar: en ese inventario existe un escenario llamado *"Create Material from Cloud for Customer in SAP ERP"* que apunta a un servicio de **consulta**, no de creación. La creación es la RFC de este apartado, no aquella.

### 8.2 No cubribles como están escritas, porque la propia historia las declara abiertas

| Regla | Qué dice la historia | Qué necesitamos |
|---|---|---|
| **RN-49** | El retorno debe incluir *"todos los datos disponibles en el Maestro de Materiales de SAP que hoy se visualizan en la consulta rápida"* | **Este es el punto que más puede mover la estimación.** No sabemos cuántos campos son. Pueden ser cinco o cincuenta, y cada uno es un campo a crear, mapear en MuleSoft y mantener. Sin la lista no se puede dimensionar ni prometer. Es el pedido más urgente de los cuatro |
| RN-24 | *"El sistema en el que se ejecuta y registra ese traslado requiere validación"* | Definición de Grupo Q. Salesforce tiene objeto estándar si se decide registrarlo acá |
| RN-52 | *"El mecanismo de escalamiento no está definido a la fecha y requiere validación con Grupo Q"* | Destinatario y tiempo de respuesta. El mecanismo ya está resuelto, falta el parámetro |
| RN-54 | *"Queda registrada la dependencia de confirmar si esa notificación puede enviarse por correo directamente desde Salesforce"* | Confirmación de Grupo Q |

Las cuatro ya estaban marcadas como pendientes **en el propio documento de la historia**. No son hallazgos nuevos ni objeciones nuestras: son definiciones que la historia dejó abiertas y que siguen abiertas.

### 8.3 Una salvedad sobre un criterio de aceptación

El CA-15 exige verificar la cotización *"dentro de la vigencia de la cotización"* para clientes B2B. La vigencia de la cotización no se define en esta historia. Se asume la regla de vigencia que fije la historia de cotización, y se verifica contra ella.

### 8.4 Conclusión

**Lo que sí se puede cerrar hoy es la solución en Salesforce, y queda cerrada por completo:** modelo de datos, ciclo de vida del registro, control de duplicados a prueba de concurrencia, correlación con SAP, notificaciones, aprobaciones, trazabilidad y permisos. Nada de eso espera a nadie y todo está especificado en las secciones 1 a 7.

**Lo que no se puede cerrar es el alcance de la integración**, por dos motivos concretos: faltan tres piernas en el inventario que se está cotizando, y falta la lista de campos de la RN-49 sin la cual no hay dimensionamiento posible.

Esa es la separación honesta, y conviene que quede escrita en la historia con esas palabras.

---

## 9. Dependencias externas

| Dependencia | Dueño | Bloquea |
|---|---|---|
| Confirmar si la solicitud se envía desde Salesforce a SAP | Grupo Q | No bloquea el desarrollo, solo el armado de la clave |
| Qué servicio SAP atiende la creación y extensión automática del Tiempo 1 | Equipo SAP | El paso 5 del Tiempo 1. El resto avanza |
| Que la notificación de creación sea inmediata y no dependa de la réplica de catálogo | Equipo SAP y MuleSoft | Nada. Sin esto el diseño sigue funcionando, con el tratamiento de la sección 5.3 |
| Destinatario y tiempo de respuesta del escalamiento | Grupo Q | Solo la configuración de la alerta |
| Conjunto de valores de Rotación | Equipo SAP | Nada, el campo es de texto |
