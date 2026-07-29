# Inventario de vehiculos SAP -> Salesforce (Automotive Cloud)
## Mapeo campo a campo + definiciones de upsert (borrador para validacion, 29/07/2026)

Principios aplicados (arquitectura cerrada):
- SAP es la fuente de la verdad del inventario; Salesforce consulta y exhibe.
- Cero objetos custom (restriccion cliente 22/07). Campos custom en objetos
  standard estan permitidos y se usan solo cuando NO hay campo nativo.
- Dato DERIVABLE no se sincroniza (se calcula en SF con formula).
- Naming: API en ingles PascalCase, labels en espanol, Description con paises.
- Los API names nativos marcados [confirmar] se traban con el script
  DESCRIBE-INVENTARIO.apex (la verdad es la org, no la doc).

## 1. Veredicto campo a campo (RFC de inventario)

Leyenda: NATIVO = campo standard destino | CUSTOM = crear campo custom |
NO ENVIAR = no sincronizar (derivado o sin caso de uso) | PENDIENTE SAP =
falta definicion del lado SAP antes de decidir.

| Campo RFC | Veredicto | Destino / Regla |
|---|---|---|
| BUKRS | CUSTOM | `Vehicle.CompanyCode__c` (picklist). Reusar el Global Value Set de sociedad si ya existe (C101/C105/N101/N105, mismo dominio que Opportunity.Sociedad). Clave para busqueda por sociedad. |
| EMPRESATXT | NO ENVIAR | Descripcion de la sociedad = label del picklist de BUKRS. Mandar el texto duplicaria el maestro. |
| SERIE | PENDIENTE SAP | Si SERIE = chasis/VIN, va al campo nativo de VIN del Vehicle y NO se crea nada. Si es otra numeracion (serie comercial), `Vehicle.SapSeries__c` (Text). Bloquea la definicion del upsert - prioridad alta con SAP. |
| MARCA_VEHICULO | NATIVO (nivel modelo) | La marca es atributo del MODELO, no de la unidad: VehicleDefinition (campo de make [confirmar API name en describe]) via el Product2/MATNR. El CODIGO SAP de marca se traduce en MuleSoft (tabla codigo->nombre); SF recibe el nombre. No crear campo de marca en Vehicle. |
| FLOOR_PLAN | PENDIENTE SAP | Financiamiento de inventario (floor plan) es dato financiero interno. Default: NO ENVIAR salvo que negocio confirme que el vendedor lo necesita (ej. priorizar venta de unidades en floor plan -> seria `Vehicle.IsFloorPlanFinanced__c` checkbox). |
| RESERVA | NATIVO (via status) | No es campo aparte: alimenta la matriz de `Vehicle.Status` (seccion 3). Reserva viva en SAP -> Status = Reservado. |
| ALIST_COMPLETO | CUSTOM | `Vehicle.IsPrepComplete__c` (checkbox). Ademas alimenta la matriz de Status (sin alistamiento no esta Disponible). Se guarda el flag crudo para trazabilidad + reglas de entrega. |
| NAC_REALIZADA | CUSTOM | `Vehicle.IsNationalized__c` (checkbox). Igual que el anterior: flag crudo + insumo de la matriz de Status. Critico en CA (no se entrega sin nacionalizar). |
| F_INGRESO | CUSTOM | `Vehicle.InventoryEntryDate__c` (Date). Base del aging. |
| D_ANTI | NO ENVIAR | Derivado: formula en SF `TODAY() - InventoryEntryDate__c`. Sincronizar dias envejece en horas; la formula siempre esta al dia. |
| CTG_ANTI | NO ENVIAR (default) | Derivado de D_ANTI: formula con los rangos. EXCEPCION: si los rangos son regla de negocio mantenida en SAP y cambian, entonces SI enviar (`Vehicle.AgingCategory__c` picklist) para no duplicar la regla. Decidir con negocio: quien es dueno de los rangos? |
| T_VEHICULO | NATIVO | `VehicleDefinition.VehicleType` (picklist [confirmar valores]). Mapa codigo SAP -> valor SF en MuleSoft. |
| NRO_POLIZA | PENDIENTE SAP (probable CUSTOM) | Confirmar significado: poliza ADUANERA (importacion, par con NAC_REALIZADA) o SEGURO. Aduanera -> `Vehicle.ImportPolicyNumber__c` (Text 40). Seguro de inventario -> probable NO ENVIAR (dato interno de finanzas). |
| FPOLIZA | PENDIENTE SAP | Sigue la decision de NRO_POLIZA (`Vehicle.ImportPolicyDate__c` Date si aplica). |
| Centro (WERKS) | CUSTOM | `Vehicle.PlantCode__c` (picklist). ATENCION: el centro SAP se correlaciona con la sucursal - alinear los valores con la clave canonica de sucursal (BranchCode CR_URUCA... y ServiceTerritory.BranchCode__c) cuando el centro sea 1:1 con sucursal. Es lo que hace la busqueda "vehiculos en mi sucursal" funcionar sin tabla de-para nueva. |
| Deposito (LGORT) | CUSTOM | `Vehicle.StorageLocationCode__c` (Text/picklist corto). Granularidad interna del centro (transito, showroom, bodega). |
| Pais de origen | CUSTOM | `Vehicle.CountryOfOrigin__c` (picklist ISO). A nivel UNIDAD (no VehicleDefinition): el mismo modelo puede venir de plantas distintas. Insumo de nacionalizacion/aranceles. |
| DATOS_ACCESORIOS | PENDIENTE SAP | Sin detalle de estructura no se disena. Direccion probable: accesorios instalados de fabrica de la unidad. SIN objeto custom disponible, las opciones son (a) no sincronizar y resolver accesorios en la cotizacion (pricebook, como hoy), o (b) texto largo JSON de exhibicion en el Vehicle. Decidir cuando SAP detalle. |

## 2. Definiciones de upsert (cadena Product2 -> VehicleDefinition -> Vehicle)

Regla general: MuleSoft hace UPSERT por External Id custom (los campos
standard no son marcables como External Id). Cadena de 3 niveles:

1. `Product2` - External Id: `SapMaterialCode__c` (Text 18, Unique,
   External Id) = MATNR. Se mantiene ProductCode = MATNR para exhibicion
   (patron ya cerrado en el guard de combos). Un material = un modelo/version
   vendible.
2. `VehicleDefinition` - External Id: `SapMaterialCode__c` (Text 18, Unique,
   External Id) = MATNR (1:1 con Product2; el upsert de Mule primero resuelve
   Product2, despues VehicleDefinition con ProductId).
3. `Vehicle` - External Id: `Vin__c` (Text 17, Unique, External Id) = VIN/
   chasis. ADEMAS se llena el campo nativo de VIN [confirmar API name en
   describe] para que la UI nativa (fichas, appraisal re-vinculo HU-045,
   busqueda CBSF) funcione. El custom es solo la llave tecnica del upsert.
   GATE: si SAP confirma que SERIE = chasis, la llave es esa; si el VIN
   puede faltar en transito, definir con SAP la llave provisoria (material +
   serie?) - upsert sin llave estable no va.

## 3. Vehicle.Status - valores y matriz SAP -> SF

Propuesta de valores (picklist Status del Vehicle [confirmar si restricted
en describe]; si restricted y no editable, mapear a los nativos existentes):

- `EnTransito` (label: En transito)
- `EnAlistamiento` (label: En alistamiento)
- `Disponible` (label: Disponible)
- `Reservado` (label: Reservado)
- `Vendido` (label: Vendido)
- `Baja` (label: Baja / no vendible)

Matriz de derivacion (Mule calcula el status con los flags del RFC; SF solo
recibe el resultado + los flags crudos):

| Condicion SAP | Status SF |
|---|---|
| Sin nacionalizar (NAC_REALIZADA = no) | EnTransito |
| Nacionalizado, ALIST_COMPLETO = no | EnAlistamiento |
| Nacionalizado + alistado + sin RESERVA + stock libre | Disponible |
| RESERVA activa | Reservado |
| Facturado/entregado (sale del stock) | Vendido |
| Bloqueado/baja en SAP | Baja |

Regla de precedencia: Vendido > Reservado > EnTransito > EnAlistamiento >
Disponible. La asetizacion de la venta SF (gatillo Facturado) NO viene de
este sync: el sync solo marca Vendido cuando SAP lo confirme (consistencia
con el ciclo Borrador -> Enviado -> Confirmado -> Facturado).

## 4. CLIENTE -> Vehicle.CurrentOwnerId

Recomendacion: FUERA del alcance del sync de inventario.
- Unidades de stock: el dueno es GrupoQ (no hay CLIENTE). No llenar
  CurrentOwnerId en el sync o apuntarlo a la cuenta interna de la sociedad
  (decidir: cuenta interna por sociedad ya existe?).
- Unidades vendidas: la propiedad del cliente la establece la ASETIZACION
  nativa del ciclo de pedido SF (gatillo = Facturado, Asset + Vehicle +
  AssetContactParticipant via Flow) - ya es parte de la arquitectura cerrada.
  Si el sync tambien escribiera el dueno, habria dos escritores para el
  mismo dato (conflicto con el guard anti-duplicado tipo HU-039).
- Si aun asi el negocio quiere reconciliar el CLIENTE de SAP: la llave es el
  campo de codigo de cliente SAP ya existente en Account ("Codigo Cliente",
  [confirmar API name]) y el sync solo ALERTA divergencias, no escribe.

## 5. Obligatorios, validaciones, tipos y tamanos

La verdad es la org: correr `DESCRIBE-INVENTARIO.apex` (junto a este doc) y
pegar el log. El script imprime, para Product2 / VehicleDefinition / Vehicle:
- campos obligatorios en create (isNillable=false y sin default),
- todos los campos con tipo y tamano (length/precision/scale),
- picklists con sus valores y si son restricted,
- lookups con el objeto destino,
- y las validation rules activas se consultan aparte (query Tooling incluida
  en el script como comentario).

Con ese log se completan las columnas "tipo/tamano/valores permitidos" y
"ejemplos" que el equipo SAP pidio, sin adivinar.

## RESULTADO DEL DESCRIBE (29/07, log de la org) - vereditos ACTUALIZADOS

El describe corrio sobre Product2 (53 campos), VehicleDefinition (49) y
Vehicle (85). Actualizaciones sobre las secciones 1-5:

### Hallazgo estructural: Vehicle.AssetId es OBLIGATORIO
Todo Vehicle requiere un Asset (ademas de VehicleDefinitionId y VIN, tambien
obligatorios). Consecuencia para el sync: la cadena real es
`Product2 -> VehicleDefinition -> ASSET -> Vehicle`. El Asset de una unidad
de STOCK necesita cuenta dueno -> la "cuenta interna por sociedad" (pendiente
6 de la seccion 6) deja de ser opcional: es PRERREQUISITO del sync. Bonus de
consistencia: en la venta ya no se crea el Asset - se TRANSFIERE (Asset.
AccountId + Vehicle.CurrentOwnerId al cliente en Facturado), alineado con la
asetizacion nativa del ciclo de pedido.

### Nativos encontrados que REEMPLAZAN customs propuestos
| Campo RFC | Veredito nuevo |
|---|---|
| MARCA_VEHICULO | NATIVO confirmado: `Product2.MakeName` (STRING 80) + denormalizado en `Vehicle.MakeName` (40). Mule traduce codigo->nombre. Cero custom. |
| SERIE | Si es chasis: NATIVO `Vehicle.ChassisNumber` (STRING 255, separado del VIN). La org tiene VIN y chasis como campos distintos - la pendiente con SAP baja de "donde guardarlo" a solo "que significa". |
| T_VEHICULO | `VehicleDefinition.VehicleType` NO existe en esta version. Destino real: `Product2.Family` (picklist NO restricto, ya sembrado: Autos / Motos / Frotas / Usados / Repuestos / PA / Accesorio) para la taxonomia comercial; `VehicleDefinition.VehicleClass` (STRING) como clasificacion tecnica si SAP distingue mas fino. |
| Deposito (LGORT) | Candidato NATIVO: `Vehicle.StockCode` (STRING 255) si el negocio acepta un solo codigo de ubicacion de stock; si Centro y Deposito deben viajar separados, se mantiene el custom `StorageLocationCode__c`. Decidir con el equipo SAP. |
| Identidad SAP | NATIVOS hechos para esto: `Vehicle.SourceSystemName` / `SourceSystemIdentifier` / `ExtlSystemVehicleIdentifier` (STRING 255). El identificador SAP de la unidad vive ahi SIN custom. |

### Lo que el describe CONFIRMA del borrador
- Ningun campo con flag External Id upsertable en los 3 objetos (el
  `Product2.ExternalId` standard existe pero NO es llave de upsert) -> los
  3 External Ids custom de la seccion 2 SIGUEN siendo necesarios. Los
  nativos de identidad (ExternalReferenceNumber en VehicleDefinition,
  ExtlSystemVehicleIdentifier en Vehicle) se llenan ADEMAS, para exhibicion.
- Obligatorios reales en create: Product2 = Name; VehicleDefinition = Name +
  ProductId; Vehicle = Name + AssetId + VehicleDefinitionId + VIN.
- `Vehicle.Status` es picklist NO restricto con los valores default del
  paquete: "En ubicacion de concesionario / En servicio / En reparacion /
  En fabricacion". Decision de la seccion 3 refinada: sembrar los valores
  GrupoQ (EnTransito/EnAlistamiento/Disponible/Reservado/Vendido/Baja) y
  desactivar los default que no se usen - una sola taxonomia, no dos.
- `Vehicle.CurrentOwnerId` referencia Account (no polimorfico) - compatible
  con la regla de la seccion 4.
- BUKRS, F_INGRESO, flags (ALIST/NAC), FLOOR_PLAN y polizas siguen SIN casa
  nativa -> customs de la seccion 1 confirmados.
- Campos de precio del Vehicle (MarketPrice, AverageMarketValue...) NO se
  usan: el precio es del SAP (guard de arquitectura).
- VehicleDefinition trae ficha tecnica rica nativa (motor, bateria, medidas,
  consumo, FuelSource/DrivetrainSystem/TransmissionSystem picklists nuevos -
  los viejos TransmissionType/FuelType estan Deprecated: NO mapear a los
  deprecated). Si el RFC algun dia manda specs, hay casa nativa.

## 6. Pendientes que bloquean (para devolver a SAP/negocio)

1. SERIE: que es exactamente? (bloquea la llave del upsert de Vehicle)
2. DATOS_ACCESORIOS: estructura y proposito.
3. NRO_POLIZA/FPOLIZA: aduanera o seguro?
4. FLOOR_PLAN: el vendedor necesita verlo? (si no: no enviar)
5. CTG_ANTI: los rangos de antiguedad son regla viva en SAP o fija? (define
   formula en SF vs campo sincronizado)
6. Negocio: cuenta interna por sociedad para el ASSET de las unidades de
   stock - PRERREQUISITO del sync (Vehicle.AssetId es obligatorio, ver
   resultado del describe). Definir la cuenta (una por sociedad BUKRS) antes
   de la primera carga.
7. Falta correr la query Tooling de validation rules de los 3 objetos
   (comentario al final del DESCRIBE-INVENTARIO.apex) para cerrar la
   seccion "reglas de validacion y excepciones".
