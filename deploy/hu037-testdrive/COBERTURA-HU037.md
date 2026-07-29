# HU-037 - Gestion Integral de Test Drive: plan de cobertura (29/07/2026)

Base: HU037Auto_Test_Drive_v2_3.docx (FIT, MH, R1-S3). Estado real validado
hoy en DevSales (SA-0107, Asset resource, modify flow, describe de licencias).

## A. YA CUBIERTO (validado en org hoy)

| RN | Evidencia |
|---|---|
| 1.1 agendar desde Opp via Scheduler | SA-0107 creado desde la Opp (Parent=Opportunity), WT "Prueba de manejo sucursal" 60 min |
| 1.2/1.3 demo como Asset + bloqueo VIN | ServiceResource tipo Asset (TD Asset - RPA Toyota Hilux) required en el SA; asset scheduling confirmado (tipo S activo) |
| 4.1/4.2 SA fuente de verdad, reprogramar/cancelar | Outbound Modify Appointment probado (SelectNewServiceResource + slots) |
| 10.1 domicilio | WT "Prueba de manejo domicilio" 120 min ya existe; SA tiene Address nativo |
| Territorios/horarios | GQ Sucursal La Uruca / Lindora / Perez Zeledon + GQ Test Drive Hours |
| 9 (parcial) | DocGen Designer reasignado a Tiago para plantilla; 26k runtime community |

## B. DECISIONES DE DISENO A TRABAR (bloquean el resto)

1. SECCION 5 (Event solo con hand-off, creado por Flow, nunca manual, sin
   controlar disponibilidad) REDISENA el hallazgo de hoy: los 3 Events que
   el booking crea (principal + 2 "Tiempo bloqueado", CreatedBy Automotive
   API) NO cumplen 5.1/5.6. Decision: suprimir la creacion automatica
   (apagar Event Management / configuracion del flujo automotive - verificar
   cual de los dos los genera) y crear UN Event solo en hand-off via Flow
   propio (item C3). CONSECUENCIA BUENA: la validation rule HU-009 vuelve a
   la FORMULA ORIGINAL sin excepciones (sin Events de Scheduler ligados a
   la Opp, no hay conflicto) y el Event de hand-off nace CON BranchCode
   (del territory del SA) -> dispara la Parte B nativa (share sucursal +
   Pendiente) -> Recibir Cliente cierra el ciclo. Todo el saga de la manana
   se resuelve por diseno.
   PENDIENTE: impacto en visibilidad de calendario del asesor (HU-027 O365)
   - el asesor presencial ve el Event de hand-off; el digital ve la agenda
   por el SA. Validar con negocio/Melisa.
2. RUNTIME DocGen: no existe SKU interno; hipotesis = incluido en OmniStudio
   (27.131). TEST: asignar OmniStudio PSL a usuario vendedor y generar con
   la plantilla. Si falla -> patron automation user (Platform Event +
   subscriber con running user licenciado) + pregunta formal de compliance
   (acceso indirecto) al contacto de licenciamiento.

## C. POR CONSTRUIR (workstreams)

C1. Licencia de conducir (1.5, Esc.2) - CONFIG+FLOW
    IdentityDocument (existe en la org) + DocumentChecklistItem (IDA,
    licenciado en Automotive Foundation) + screen flow gate en el
    agendamiento: sin licencia vigente no continua. PII: FLS restringida.
C2. Parametrizacion de agenda - CONFIG
    Buffer de bloqueo parametrizable (1.6) en el Work Type; Shifts para
    disponibilidad excepcional (3.1); colas por sucursal para recepcion
    (7.2/7.3) y sharing de SA con recursos asignados.
C3. Flow "ServiceAppointment After Handler" - FLOW (nucleo nuevo)
    Al crear SA desde Opp con owner = asesor digital (hand-off): crea el
    Event operativo con BranchCode del territory (alimenta HU-009 Parte B);
    en reprogramacion/cancelacion actualiza/cierra el Event (4.3, 5.5,
    12.4). Naming GRPQM.
C4. Documento de autorizacion (9) - DOCGEN
    Plantilla (Tiago, Designer); accion "Generar autorizacion" en el SA;
    PDF a Files; datos: cliente, vehiculo, asesor, sucursal, horario.
    Sin firma electronica (9.4). Gate = decision B2.
C5. Cierre del Test Drive (11) - CAMPOS+FLOW+VR
    Campos en SA: salida, devolucion, km inicial/final, condicion,
    observaciones (API ingles, labels ES). VR: km final obligatorio al
    cerrar y >= inicial (11.3/11.4). Flow al completar: actualiza
    Vehicle.LastOdometerReading + OdometerReadingDate (11.5), crea Task en
    la Opp (11.7). Liberacion del VIN (11.6) es nativa al completar/cancelar.
C6. Recordatorios (12) - FLOW
    Record-triggered en SA con scheduled path sobre SchedEndTime + offset
    (parametro en Custom Metadata): si sigue Agendado -> custom notification
    + Task al Owner de la Opp. El path se recalcula solo al reprogramar
    (12.4) y no corre si cerro/cancelo (12.5).
C7. Agenda de demos (13) - CONFIG (fase 1)
    List view / calendario de SA-recursos por sucursal SIN nombre de
    cliente (columnas restringidas). LWC dedicado solo si la list view no
    alcanza (decidir en UAT).
C8. Km maximo demo (14) - CAMPOS+FLOW
    Campos en Vehicle/Asset demo: MaxOdometer, umbral %. Flow al actualizar
    odometro (C5): al cruzar umbral -> notificacion al gerente + alerta
    visual (formula/badge en record page).
C9. API central para canales digitales (2, 15) - INTEGRACION (la mayor)
    Mule expone el motor: consultar sucursales/disponibilidad/demos/slots +
    registrar test drive (Salesforce Scheduler REST APIs por debajo).
    Flujo inbound: validar duplicados -> Person Account si no existe ->
    Opportunity canal Online SIN Lead -> SA via Scheduler. Es SERVICIO
    NUEVO en el contrato MuleSoft (misma categoria HU-039) - alta formal.
    Nota: contradice el GAP "autoagenda = fase futura" registrado en
    MODELAGEM-AVALUO - la HU-037 lo trae a alcance; alinear con Melisa.
C10. Otra sucursal (8) - FLOW menor
    Asesor sustituto como recurso -> auto-agregarlo al Opportunity Team
    (owner no cambia). Territory de la otra sucursal ya funciona nativo.

## D. ORDEN SUGERIDO (dependencias)

1. B1 + B2 (decisiones) -> destraban C3 y C4.
2. C1, C2, C5 (config + campos + gates) - sprint actual.
3. C3 + restaurar VR HU-009 original + regresion Recibir Cliente.
4. C6, C8, C10 (flows menores).
5. C4 (plantilla + runtime segun B2).
6. C7 (list view) y C9 (contrato Mule - arrancar el alta YA por lead time).

## E. PROCESO

- Decisiones B1/B2 + el cambio de alcance del C9 = GUIA el mismo dia +
  version unica con Melisa antes del refinamiento.
- Cada workstream entra al DLG al desplegar.
