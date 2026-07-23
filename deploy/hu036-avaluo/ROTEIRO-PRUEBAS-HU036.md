# HU-036 — Guion de pruebas (avalúo de vehículo usado / trade-in)

Ambiente objetivo: el que reciba el paquete (INT/UAT). Ejecutar DESPUÉS del
checklist de deploy (ver DEPLOY-HU036.md). Datos de prueba mínimos: una
Opportunity activa, la matriz PRU cargada y activa, el Flow "Appraisal Item
After Handler" activo, y el usuario con los permission sets "Gestión de
Avalúos" + OmniStudio User.

Convención: cada prueba indica el criterio de aceptación (CA) que cubre.
Resultado esperado en negrita. Anotar OK/FALLO + evidencia (print o Id).

## P1 — Agendamiento del avalúo (CA-1, CA-2; Esc. 2/3)
1. En la Opportunity, agendar cita con Work Type "Avalúo" (Scheduler), en la
   sucursal (Service Territory) y horario disponible.
2. **Esperado**: Service Appointment creado con Parent Record = Opportunity,
   Work Type Avalúo, Status Scheduled; el Owner de la Opportunity NO cambia;
   la disponibilidad ofrecida sale de Operating Hours (sin SAP).

## P2 — Creación del avalúo desde el card nativo (CA-6)
1. En la Opportunity, botón/card "Request an Appraisal" (FlexCard estándar).
2. Purpose Type = Trade-In, Validity End Date futura, Appraised By = valuador.
3. **Esperado**: Appraisal creado, Reference Record = la Opportunity,
   UsageType = Automotive, Status editable con los 4 estados sembrados.

## P3 — Item con match en el PRU (CA-7, CA-8; Esc. 6)
1. En el Appraisal > Appraisal Items > New: Make/Model/Year existentes en la
   matriz PRU + Usage (km) + unidad Kilómetros + Condition Type.
2. Esperar unos segundos y refrescar.
3. **Esperado**: (a) Appraisal Item Provider Valuation creado automaticamente
   con Provider Name = PRU, fecha/hora y valor de la matriz; (b) Initial Value
   del item = valor de la matriz; (c) Final Value del item = Initial Value;
   (d) Final Appraisal Value del Appraisal = suma de los items.

## P4 — Item SIN match en el PRU (ramo negativo del Flow)
1. Crear un segundo item con una marca/modelo/año que NO exista en la matriz.
2. **Esperado**: NO se crea ProviderVal y el Initial Value queda vacío (el
   valuador lo informará manualmente). Sin error de Flow (ramo default).

## P5 — Deducción del valuador (CA-9; Esc. 6)
1. En el Appraisal > Appraisal Adjustments > New: Type = Deducción, Adjustment
   Value negativo (ej. -500), Description con el motivo, Status = Approved,
   vinculado al item de P3.
2. **Esperado**: Final Value del item y Final Appraisal Value recalculados
   (restan la deducción); CreatedBy/fecha como traza nativa de quién ajustó.

## P6 — Ajuste sin Status no computa (regla de plataforma; hallazgo 23/07)
1. Crear un ajuste SIN llenar Status (o con InReview).
2. **Esperado**: los totales NO cambian hasta poner Status = Approved.
   PROCEDIMIENTO PERMANENTE (decisión 23/07, sin flows adicionales): el usuario
   SIEMPRE selecciona Status = Approved al crear el ajuste. Documentar en la
   capacitación y en el help text del layout.

## P7 — Indicadores legales y notas (CA-10; Esc. 6)
1. En el Appraisal, llenar Multas (esquelas) / Gravámenes / Procesos judiciales
   (default: Pendiente de verificación -> cambiar a No) y una nota en Comment.
2. **Esperado**: valores guardados; Field History registra los cambios de los
   4 campos custom (y de Status si el tracking del runbook 2.4b se aplicó).

## P8 — Excepción del gerente hacia arriba (regla de negocio 7)
1. Crear ajuste Type = Excepción con valor POSITIVO (ej. +300), Approved.
2. **Esperado**: los totales SUBEN; traza de quién ajustó.

## P9 — Visibilidad 360 (CA-15; Esc. 11)
1. Abrir la Opportunity y la Account del cliente.
2. **Esperado**: el Appraisal y su resultado visibles/navegables desde el 360
   (related list / página). Formalización completa llega con la Lightning
   Record Page del paquete v5.

## P10 — Multi-sucursal (CA-12; Esc. 5) — cuando exista segundo territory
1. Agendar el avalúo en un Service Territory distinto al de la venta.
2. **Esperado**: SA en el territory correcto; Owner de la Opportunity sin
   cambio; valuador agregado al Opportunity Team.

## Pruebas de proceso NATIVO (decisión 23/07: sin flows adicionales)
- P11 Cierre Aceptado (CA-11, CA-13; Esc. 7/8): el valuador pone
  Status = Aceptado; el ASESOR aplica el trade-in en la cotización
  (procedimiento manual; el valor sale del Final Appraisal Value).
  **Esperado**: cotización refleja el trade-in; trazabilidad en el Appraisal.
- P12 Rechazo (CA-14; Esc. 10): Status = Rechazado + Motivo de rechazo
  llenado por el asesor; la Opportunity sigue con o sin usado.
  **Esperado**: motivo registrado (Field History audita el cambio).
- P13 Notificación al proveedor externo (CA-5; Esc. 4): el asesor envía el
  aviso por correo desde la Opportunity (actividad registrada).
  **Esperado**: actividad/email en la línea de tiempo de la Opportunity.
NOTA: CA-5 y CA-11 mencionan "Flow" en el texto de la HU — alinear la
redacción V3 con Melisa (decisión: proceso nativo/manual en lugar de Flow).

## Fuera de esta HU (coordinar con otras frentes)
- Solicitud online genera Lead (CA-3 — frente digital / Web-to-Lead).
- Envío de la propuesta por correo O365 / WhatsApp (CA-13 — integraciones).
