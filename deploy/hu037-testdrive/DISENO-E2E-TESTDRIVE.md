# Gestion integral de Test Drive (HU-037)
## Diseno de solucion end to end - DevSales, 29/07/2026

Alcance de este documento: el ciclo completo de la prueba de manejo desde la
Oportunidad hasta el cierre y la liberacion del vehiculo, con los componentes
reales que ya existen en la org y los que faltan por construir. Sirve de base
para el refinamiento con Melisa y para el plan de trabajo del equipo.

## 1. Vision general

```
 OPORTUNIDAD                    AGENDAMIENTO                       DIA DE LA PRUEBA
 -----------                    ------------                       ----------------
 Asesor (digital o        OmniScript GQAutoCloudScheduler          Recepcion imprime la
 presencial) abre    ->   1. Valida licencia de conducir      ->   autorizacion (PDF) desde
 la accion de              (DriverLicenseValidation /              el Appointment, cliente
 Test Drive                IdentityDocument)                       firma en fisico
                           2. Sucursal (Service Territory)
                           3. Slot + recursos:                     Cliente llega: Recibir
                              asesor (Technician) y                Cliente (HU-009) si hubo
                              vehiculo demo (Asset)                hand-off digital->presencial
                           4. ScheduleServiceAppointmentCall
                              crea el SERVICE APPOINTMENT          Vuelta terminada: cierre
                              (reserva oficial, bloquea VIN)       con kilometraje, estado
                                                                   del vehiculo y resultado
                                                                   comercial; el VIN queda
                                                                   libre para otra prueba
```

El Service Appointment es la fuente de verdad de la prueba. La Oportunidad
sigue siendo el proceso comercial. El Event solo existe cuando hay hand-off
entre asesor digital y presencial, lo crea un Flow a partir del SA y nunca
se crea a mano (seccion 5 de la HU; esto ademas devuelve la validation rule
de HU-009 a su formula original, sin excepciones).

## 2. Etapas y componentes

Agendamiento
- Quick action en la Opportunity abre el OmniScript GQAutoCloudScheduler/
  TestDriveAppointment (v3, multi-language). Pasos internos: validacion de
  licencia (embebido GQAutoCloudScheduler/DriverLicenseValidation, lee
  IdentityDocument via GetEligibleDrivers), seleccion de sucursal
  (ServiceAppointmentLocationSearch), slot y recursos
  (ServiceAppointmentTimeSlotSelection, GetAssetTypeServiceResources).
- La reserva la ejecuta la IP ScheduleServiceAppointmentCall. El vehiculo
  demo participa como Service Resource de tipo Asset, con lo cual el motor
  de agenda bloquea el VIN en el horario y no permite superposicion.
  Probado en org con SA-0107 (TD Asset - RPA Toyota Hilux + asesor).

Datos de exhibicion en el SA (deployado hoy)
- Tres campos alimentados por automatizacion, nunca por el usuario:
  AdvisorName__c, VehicleDescription__c y DriverLicenseNumber__c (PII, FLS
  restringida a venta y recepcion).
- Quien los llena: el flow AssignedResourceAfterHandler estampa asesor y
  vehiculo cada vez que un recurso entra o cambia en el SA. Eso cubre el
  booking, el cambio de vehiculo por el Modify estandar y cualquier canal
  futuro (API central). La licencia la estampa el propio OmniScript en el
  post que ya hace sobre el SA (agregar el campo al DR de
  UpsertCommentInServiceAppointmentRecord).
- Motivo de fondo: el Service Report Template y las list views no alcanzan
  datos a dos saltos (recurso -> asset -> vehiculo). Sin estampas no hay
  documento ni agenda de demos correctos. Y si la recepcion cambia el
  carro, el documento debe salir con el carro nuevo, no con el del booking.

Documento de autorizacion (RN 9)
- Datos: Data Mapper GQAutoGetAuthorizationData (extract de un solo paso
  sobre el SA, probado con Preview: NumeroCita, fechas, Sucursal, Cliente,
  y las tres estampas). Contrato de tokens congelado.
- Render: Service Report Template para el R1 (boton Create Service Report
  ya existe en el SA; plantilla iniciada por Tiago). Queda una sola
  pregunta al negocio: el formato visual estandar del Service Report
  alcanza, o exigen layout propio. Si exigen layout, el plan B es una
  pagina Visualforce renderAs PDF con los mismos campos; no se rehace nada
  del resto.
- Descartados y por que: Document Generation (limitacion de ancla de
  objeto: no soporta Service Appointment; verificado en doc y en org),
  firma electronica (fuera de alcance por RN 9.4).
- OJO con la redaccion de la HU: el punto 9.1 nombra "Document Generation"
  textualmente. Hay que corregirla con Melisa antes del refinamiento, sea
  cual sea la respuesta del layout.

Hand-off y recepcion (cruce con HU-009)
- Solo cuando el asesor de origen es digital: un Flow (por construir,
  "ServiceAppointment After Handler") crea el Event operativo con la
  sucursal (BranchCode del Service Territory). Con eso dispara la Parte B
  de HU-009 tal como fue entregada: comparte la Opp con el grupo de la
  sucursal y deja la visita Pendiente. La recepcionista cierra el ciclo
  con Recibir Cliente. Sin hand-off no se crea Event.

Cierre de la prueba (RN 11, por construir)
- Campos de cierre en el SA (salida, devolucion, km inicial y final,
  condicion, observaciones), validacion de km final >= inicial, y un flow
  al completar que actualiza el odometro del Vehicle y deja la actividad
  de seguimiento en la Opportunity. La liberacion del VIN al completar o
  cancelar es nativa del motor de agenda.

Agenda de demos y control de kilometraje (RN 13 y 14, por construir)
- Agenda: list view de appointments por sucursal usando las estampas
  (vehiculo y asesor visibles, sin nombre de cliente).
- Kilometraje: maximo configurado por vehiculo demo, alerta al gerente al
  cruzar el umbral. Se alimenta del odometro que actualiza el cierre.

Canales digitales (RN 15, fase de integracion)
- Los sitios consumen el mismo motor via API central en MuleSoft (envuelve
  las REST APIs del Scheduler). Alta formal en el contrato Mule, igual que
  los demas servicios. Sin Lead: valida duplicados, crea Person Account si
  no existe, crea la Opportunity de canal Online y agenda.

## 3. Decisiones registradas

1. El Event no se usa para disponibilidad ni se crea a mano; solo hand-off,
   via Flow desde el SA. Restaura la validation rule de HU-009 original.
2. La autorizacion sale del Service Report en R1, condicionado al visto
   bueno del negocio sobre el formato; VF como alternativa si lo rechazan.
3. Las estampas del SA son la fuente del documento y de la agenda de
   demos; las escribe la automatizacion y la troca de vehiculo re-estampa.
4. Document Generation queda descartado para esta HU por limitacion de
   ancla (se conserva el puente DocumentGenerationUtil en el repo por si
   la plataforma abre el soporte mas adelante).
5. La licencia de conducir tiene su maestro en IdentityDocument; el numero
   en el SA es copia de exhibicion para el impreso, con FLS restringida.

## 4. Pendientes con dueno

| Pendiente | Dueno |
|---|---|
| Visto bueno del formato del Service Report (o pedir layout propio) | Negocio / Melisa |
| Correccion de redaccion del punto 9.1 (nombra Document Generation) | Diego + Melisa |
| Plantilla del Service Report con las estampas | Tiago |
| Agregar DriverLicenseNumber__c al DR post del OmniScript | Tiago |
| Deploy del flow AssignedResourceAfterHandler + prueba con troca de vehiculo | Diego |
| Flow de hand-off (Event con BranchCode) + restaurar VR HU-009 | Equipo (siguiente build) |
| Campos y flow de cierre (RN 11), agenda de demos (RN 13), km maximo (RN 14) | Equipo (plan de cobertura) |
| Alta de la API central en el contrato MuleSoft | Diego (gestion contrato) |

## 5. Pruebas de aceptacion del tramo construido

1. Agendar test drive desde la Opp con licencia validada; el SA nace con
   asesor y vehiculo estampados.
2. Cambiar el vehiculo por el Modify estandar; las estampas se actualizan.
3. Preview del Data Mapper con el Id del SA: los diez tokens llenos.
4. Generar el Service Report desde el SA: PDF en Files con cliente,
   vehiculo, asesor, sucursal y horario. Usuario generador sin licencia
   DocGen Designer (cierra la pregunta de runtime).
5. Regresion HU-009: visita manual sin sucursal sigue bloqueada; booking
   no dispara la regla.
