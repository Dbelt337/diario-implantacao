# HU-041 — Parecer sobre el Field Mapping Preliminar para MuleSoft (28/07/2026)

Fuente: GrupoQ_Vehicle_Field_Mapping.xlsx (hoja "Field Mapping Preliminar",
verificada por el autor contra el Automotive Cloud Developer Guide v66.0).
Este parecer NO reemplaza el describe en la org: correr
DESCRIBE-hu041-mapping.apex y anexar el log antes de entregar a MuleSoft.

## Veredicto general
La planilla esta bien construida: no inventa campos, marca los huecos como
"Pendiente de definicion" y separa el precio (HU-038) del catalogo (HU-041).
Los ajustes necesarios son de ARQUITECTURA (llaves, vinculos y dimensiones),
no de nombres.

## Puntos criticos para el encaje con el flujo construido

1. VehicleDefinition.ProductId es OBLIGATORIO en la integracion (no
   opcional). Todo el flujo de ventas distingue vehiculo de accesorio por el
   semi-join `Product2Id IN (SELECT ProductId FROM VehicleDefinition)`
   (QuoteOrderService, regla un-vehiculo-por-quote, hotfix de cotizacion).
   Si Mule crea Product2 sin su VehicleDefinition vinculada, el vehiculo se
   trata como accesorio y la cotizacion sale mal. Elevar la fila "Relacion
   ficha tecnica <-> producto comercial" a requisito duro del contrato.

2. Llave de conciliacion SAP (fila CRITICA de la planilla):
   - Product2.ProductCode = MATNR es decision YA tomada del proyecto
     (combos 22/07; HU-039 devuelve el MATNR al mismo registro). No cambiar.
   - Para el UPSERT de Mule: ProductCode no es External ID ni idLookup —
     el upsert nativo no funciona por el. Opciones: (a) VehicleDefinition.
     ExternalReferenceNumber como llave del lado definicion (verificar
     EXTERNAL ID en el describe); (b) para Product2, campo custom External
     ID + Unique espejo del MATNR (campo custom en objeto standard esta
     permitido; nombre GRPQM p.ej. SapMaterialNumber, label "Material SAP")
     — practica standard de integracion; (c) Mule hace query+insert/update
     por ProductCode (mas fragil, dos llamadas). Recomendacion: (b) para
     robustez de carga masiva; decision final con Diego Braz.

3. Marca: elegir UNA via de gobierno — recomendacion: BusinessBrandId
   (entidad de marca; GrupoQ es multimarca Hyundai/Chevrolet/Honda y el
   Lead ya trae Marca) y MakeName solo si se necesita denormalizado de
   exhibicion. Nunca las dos como fuentes paralelas.

4. Sociedad (fila "Pendiente"): YA RESUELTO por la arquitectura del 28/07 —
   la sociedad NO es dimension del catalogo; es dimension de PRECIO y
   transaccion (pricebook por sociedad + Custom Metadata sociedad->
   pricebook + campo en la Opportunity estampado desde el Lead). El
   catalogo es global; la especificacion por pais va por GeoCountryId.
   Actualizar la fila con esta definicion.

5. Colores: correcto que ExteriorColor/InteriorColor son de la UNIDAD
   (Vehicle) — sirve para usados e inventario propio. Para vehiculos
   NUEVOS, la paleta disponible por modelo NO se modela en Salesforce:
   llega en la respuesta del POST /prices-and-inventory del Mule (flujo
   HU-042/HU-044, render de disponibilidad por color). Cerrar la fila
   "paleta de colores" con esa definicion — no falta objeto, sobra modelado.

6. Product2.IsActive: encaja con dos procesos ya construidos — interruptor
   de cotizable (T05, la venta guiada busca sobre codigo activo) y ciclo de
   HU-039 (solicitud nace IsActive=false, el retorno del MATNR activa).
   El sync de catalogo de Mule NO debe pisar IsActive de registros en
   estado "Solicitud de Material" (guarda anti-duplicado ya registrada).

7. ModelYear vive en Product2 (hallazgo correcto de la planilla): nuestro
   filtro de anio del flujo guiado y la busqueda del MaterialSearchService
   leen el lado Product2. Consistente.

8. VehDefSearchableField: candidato para la busqueda server-side del
   MaterialSearchService (SOQL indexada + LIMIT). Evaluar en la fase de
   industrializacion; no bloquea el contrato Mule.

9. Deprecaciones citadas (FuelType->FuelSource, TransmissionType->
   TransmissionSystem, DrivetrainType->DrivetrainSystem, DoorStyleType->
   DoorStyle): el describe imprime los DOS nombres de cada par — si ambos
   existen en la org, mapear SOLO al nuevo, como propone la planilla.

10. Precio fuera de alcance: correcto y alineado (pricebook por sociedad,
    HU-038; SAP certifica al facturar). Mantener la fila como limite.

## Proceso
- Paso 1: correr DESCRIBE-hu041-mapping.apex en DEV (admin) y guardar el log.
  [HECHO 29/07 — log apex07LWK00000Q71uw2AB, extracto en
  DESCRIBE-RESULTADO-20260729.log]
- Paso 2: ajustar la planilla con los resultados (columna de validacion) y
  las definiciones de arquitectura de arriba.
  [HECHO 29/07 — GrupoQ_Vehicle_Field_Mapping_v2_validado_org.xlsx]
- Paso 3: entregar a MuleSoft la version validada y registrar en la GUIA
  (admision HU-041) el mismo dia. [PENDIENTE — Diego]

## Resultado del describe (29/07/2026, log apex07LWK00000Q71uw2AB)

Global: 64/64 campos propuestos EXISTEN en la org — ningun FALTA. Objetos de
soporte (BusinessBrand, ProductAttribute x4, ProductMedia,
VehDefSearchableField, GeoCountry) existen y son creables. Los nombres de la
planilla v1 quedan validados sin correccion.

Hallazgos que ajustan la arquitectura:

1. NINGUN campo esta marcado como External ID — tampoco
   VehicleDefinition.ExternalReferenceNumber, contra lo que indica la guia
   v66.0 (solo idLookup: VehicleDefinition.Name y Vehicle.VIN). La opcion (a)
   del punto 2 cae; queda la (b): campo custom External ID + Unique en
   Product2 (SAPMaterialNumber__c) como llave del upsert de Mule.
   Confirmacion final: Diego Braz.
2. Picklists VACIAS en la org: FuelSource, TransmissionSystem,
   DrivetrainSystem y DoorStyle tienen 0 valores; sus predecesores a
   descontinuar si tienen (FuelType 5, TransmissionType 2, DrivetrainType 4,
   DoorStyleType 4). Antes del primer sync: poblar los value sets de los
   campos nuevos via metadata, o acordar uso transitorio de los viejos.
3. Los campos de ficha tecnica de VehicleDefinition (cilindrada, potencia,
   torque, dimensiones, pesos, rendimiento, capacidades) son TEXTO, no
   numericos: las unidades viajan dentro del valor y no hay validacion de
   plataforma — documentar unidades en el contrato Mule.
4. GeoCountrySpecification NO existe en la org (GeoCountry si). Eliminar
   cualquier referencia a ese objeto de los documentos del contrato.
5. Product2.Family es picklist con 7 valores: validar cobertura de la
   clasificacion requerida antes del sync.
6. ModelYear es numero entero y Availability/DiscontinuedDate son
   fecha/hora — sin sorpresas de tipo para el mapeo.
