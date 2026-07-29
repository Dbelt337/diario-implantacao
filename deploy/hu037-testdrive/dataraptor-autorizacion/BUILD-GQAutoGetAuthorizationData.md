# Data Mapper (DataRaptor) GQAutoGetAuthorizationData - hoja de construccion
## Para Tiago - autorizacion de test drive (HU-037 item 9), 29/07/2026

Por que hoja y no XML: el ODT hecho a mano fuera del designer tiene alta
chance de fallar el deploy (globalKeys/estructura). Montar en el designer
son ~15 min con esta hoja; despues se versiona con el retrieve manifest
incluido (OmniStudio Metadata ya esta habilitado en la org).

## Identidad

- Tipo: Extract | Nombre: GQAutoGetAuthorizationData
- Input/Output: JSON / JSON
- Input esperado: { "ContextId": "<ServiceAppointmentId>" }
- Description: All countries. Extracts the 5 data blocks of the test drive
  authorization document (customer+license, vehicle, advisor, branch,
  schedule) from a ServiceAppointment. Consumed by the authorization
  renderer (Service Report / VF) and the reprint flow. HU-037 RN 9.2.

## Extract steps (en este orden - cada paso enlaza con el anterior)

| # | Objeto | Filtro | Alias |
|---|---|---|---|
| 1 | ServiceAppointment | Id = ContextId | SA |
| 2 | AssignedResource | ServiceAppointmentId = SA.Id AND ServiceResource.ResourceType = 'S' | RVehiculo |
| 3 | AssignedResource | ServiceAppointmentId = SA.Id AND ServiceResource.ResourceType = 'T' | RAsesor |
| 4 | Vehicle | AssetId = RVehiculo.ServiceResource.AssetId | Veh |
| 5 | Opportunity | Id = SA.ParentRecordId | Opp |
| 6 | IdentityDocument | (filtro del titular igual al que usa GetEligibleDrivers*) + tipo licencia + vigente | Lic |

(*) El IP GetEligibleDrivers del DriverLicenseValidation YA localiza la
licencia del cliente - copiar el mismo filtro/DR de ahi para no inventar
dos criterios distintos del mismo dato.

## Output mappings (contrato de tokens - NO renombrar sin avisar)

| Origen | Token de salida |
|---|---|
| SA.AppointmentNumber | NumeroCita |
| SA.SchedStartTime | FechaHoraInicio |
| SA.SchedEndTime | FechaHoraFin |
| SA.ServiceTerritory.Name | Sucursal |
| SA.Street + SA.City | DireccionDomicilio (solo pruebas a domicilio) |
| Opp.Account.Name | Cliente |
| Lic.DocumentNumber (API real de la org) | LicenciaNumero |
| Lic.ExpirationDate (API real) | LicenciaVence |
| Veh.MakeName | VehiculoMarca |
| Veh.ModelName | VehiculoModelo |
| Veh.VehicleRegistrationNumber | VehiculoPlaca |
| Veh.VehicleIdentificationNumber | VehiculoVin |
| RAsesor.ServiceResource.Name | Asesor |

## Campos de exhibicion en el SA (paquete mdapi INCLUIDO, ya deployable)

Motivo: el Service Report Template selecciona campos del SA y relacionados
DIRECTOS - datos a dos saltos (Asset del recurso, nombre del asesor) no
aparecen en el selector. Solucion: estampar al confirmar el booking (en el
IP ScheduleServiceAppointmentCall o en un after-save) estos 3 campos:

- ServiceAppointment.AdvisorName__c (Text 120, "Asesor del test drive")
- ServiceAppointment.VehicleDescription__c (Text 255, "Vehiculo (marca
  modelo placa VIN)")
- ServiceAppointment.DriverLicenseNumber__c (Text 40, "Licencia de
  conducir" - PII: FLS restringida, solo perfiles de venta/recepcion)

Deploy: carpeta paquete-sa-fields de este mismo directorio. Post-deploy:
FLS + agregar al layout del SA (y al Service Report Template).
Sirven para las DOS rutas (Service Report los lee directo; VF los muestra
sin queries extra) y de paso dejan la agenda de demos (RN 13) sin nombre
de cliente pero con vehiculo/asesor legibles.

## Versionado post-build

Retrieve del Data Mapper una vez montado (Workbench/sf con el manifest
package-retrieve-odt.xml de esta carpeta) y commit en el repo, como el
resto de los componentes.
