# Evolucion GQAutoCloudScheduler: documento de autorizacion (HU-037 item 9)

Base analizada (retrieve 29/07, metadata_55): OmniScript
GQAutoCloudScheduler/TestDriveAppointment v3 (multi-language, evolucion del
standard de Automotive Cloud) + GQAutoCloudScheduler/DriverLicenseValidation
v2 embebido (RN 1.5 CUBIERTA: GetEligibleDrivers / RevalidateEligibleDrivers /
FinalDriverRequired / LWC DriverLicenseControl).

Estado org relevante: Document Generation Settings singleton ACTIVO
(server-side + PDF, libreria DocgenDocumentTemplateLibrary); General Settings
con Design Document Templates in Salesforce y Templates Export habilitados;
SA sin action type "Generate Document" (confirmado 29/07) -> la generacion
vive DENTRO del OmniScript, sin ancla de objeto.

## Diseno

```
ScheduleServiceAppointmentCall (IP, existente)
        | exito (rama AppointmentBookingConfirmed)
        v
DRExtractAuthorizationData        (DataRaptor Extract, NUEVO)
        v
GenerateAuthorizationDocument     (Remote Action -> DocumentGenerationUtil, NUEVO)
        v
AppointmentBookingConfirmed (step existente)
  + boton/enlace "Descargar autorizacion (PDF)" (ContentDocumentId del paso anterior)
```

Reimpresion (recepcion, sin reagendar): OmniScript hermano
GenerateTestDriveAuthorization (Type/SubType: GQAutoCloudScheduler/
GenerateAuthorization) con SOLO los 2 elementos nuevos + pantalla de
descarga; expuesto como quick action LWC en el Service Appointment
(action type Lightning Web Component, disponible en el picklist del SA).

## Elementos nuevos (crear en el designer, no editar el XML a mano)

### 1. DataRaptor Extract: GQAutoGetAuthorizationData
Input: ServiceAppointmentId (salida del ScheduleServiceAppointmentCall; en
la reimpresion, recordId del SA).
Extraccion (5 bloques del 9.2):
- ServiceAppointment: AppointmentNumber, SchedStartTime, SchedEndTime,
  Street/City (domicilio), ServiceTerritory.Name, ParentRecordId
- Cuenta/contacto: via ParentRecord (Opportunity) -> Account.Name, doc
  de identidad; licencia: IdentityDocument vigente del cliente (numero,
  vencimiento) - mismo dato que valido DriverLicenseValidation
- Vehiculo: AssignedResource con ServiceResource.ResourceType = Asset ->
  Asset/Vehicle (marca, modelo, placa, VIN)
- Asesor: AssignedResource tipo Technician -> User.Name
- Sucursal: ServiceTerritory (nombre + direccion)
Output JSON plano con los tokens EXACTOS del template (contrato de nombres
entre DataRaptor y DOCX: fijarlo en este doc cuando Tiago publique el
template).

### 2. Remote Action: GenerateAuthorizationDocument
Clase: DocumentGenerationUtil (Callable, en el paquete tradein/hu037).
Parametros (remoteOptions):
- actionName: nombre del invocable standard de generacion tal como aparece
  en el Flow Builder (TESTE 2 pendiente - parametrizado a proposito: lo que
  aparezca en la busqueda "generate document" se configura aqui SIN cambiar
  codigo)
- templateApiName: TestDriveAuthorization (developer name del Document
  Template de Tiago)
- recordId: ServiceAppointmentId
- tokenDataJson: salida del DataRaptor
- convertToPdf: true (9.3)
Salida: ContentDocumentId del PDF anexado al SA -> variable del OmniScript
para el enlace de descarga.

### 3. Ajustes en el step de confirmacion
- AppointmentBookingConfirmed: agregar bloque "Autorizacion generada" con
  enlace de descarga (URL /sfc/servlet.shepherd/document/download/
  {ContentDocumentId}).
- Falla de generacion NO bloquea la reserva (el SA ya existe): rama de
  error solo muestra aviso "genere desde el appointment" (la quick action
  de reimpresion es el fallback).

## Gates y pruebas

1. TESTE 2 (nombre real de la action de generacion en Flow Builder) -
   configura actionName. Si NO existe invocable de generacion en la org,
   DocumentGenerationUtil cambia de estrategia (llamada REST al endpoint de
   docgen con Named Credential propio) - solo en ese caso.
2. Template TestDriveAuthorization publicado (Tiago) con los tokens del
   contrato de nombres.
3. Aceite de runtime: usuario SIN DocGen Designer genera el PDF (define la
   pregunta de licencia runtime de una vez).
4. E2E: agendar test drive con licencia validada -> PDF en Files del SA con
   cliente/vehiculo/asesor/sucursal/horario -> reimpresion por quick action.
5. Post-deploy por ambiente (DLG): singleton de Document Generation
   Settings + autorizacion server-side se rehacen a mano en UAT/PROD.

## Registro GUIA (mismo dia)

- RN 1.5 cubierta por DriverLicenseValidation embebido (evidencia retrieve).
- Item 9: generacion dentro del OmniScript (sin ancla de objeto en SA,
  limitacion verificada en org); Service Report (Field Service) descartado
  por no replicar la plantilla del negocio (analisis Tiago).
- Reimpresion via quick action LWC en el SA.
