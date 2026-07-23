# HU-036 V2 — Cobertura de los criterios de aceptación (corte 23/07/2026, DEV)

Estados: PROBADO (funciona en DEV, evidencia registrada) · LISTO PARA PROBAR
(construido/configurado, falta la prueba) · EN CONSTRUCCION (paquete v5) ·
INSUMO (bloqueado por dato del Grupo Q) · OTRA FRENTE (dependencia externa).

| # | Criterio de aceptación | Estado | Evidencia / pendiente |
|---|---|---|---|
| 1 | Agendamiento con Scheduler (SA, Work Type Avalúo, SR, ST, OH), patrón Test Drive | LISTO PARA PROBAR | Work Type 08qWK..., territory reusado, STWT, recurso de prueba. Falta crear un Service Appointment de prueba desde la Opportunity |
| 2 | Disponibilidad en Scheduler; SAP no participa | PROBADO (por diseño) | No existe integración de agenda; se confirma en la prueba del criterio 1 |
| 3 | Sin Experience Cloud; asesor agenda; solicitud online genera Lead | PARCIAL / OTRA FRENTE | Agendamiento por asesor: criterio 1. Web-to-Lead (GQ-CA-01-179) pertenece a la frente digital/leads — coordinar |
| 4 | Valuadores internos = User + Service Resource, sin SAP | PROBADO (con recurso de prueba) | Recurso real por sucursal = INSUMO (nombres + horarios) |
| 5 | Proveedor externo = Cuenta/Contacto + notificación automática vía Flow | EN CONSTRUCCION (v5, Flow 2) | Flow con placeholder; empresa/contacto/texto del aviso = INSUMO |
| 6 | Resultado en familia nativa Appraisal relacionada a la Opportunity | PROBADO 23/07 | APL-000000002 con ReferenceRecord = Opportunity |
| 7 | FinalAppraisalValue calculado nativamente (no se digita) | PROBADO 23/07 | Final Value CRC 14.500 calculado por formula (updateable=false) |
| 8 | PRU registrado en AppraisalItemProviderVal, tabla maestra por país | PROBADO 23/07 (estructura) | AIP-000000001 creado por el Flow; matriz con columna Pais. Carga REAL = INSUMO (archivo PRU + moneda + unico/por condicion) |
| 9 | Deducciones/excepciones = AppraisalAdjustment con traza, sin aprobación | LISTO PARA PROBAR | Objeto nativo activo; sembrar Adjustment.Type (Deducción/Excepción) y probar un ajuste negativo (recalculo del FinalValue) |
| 10 | Indicadores legales como campos custom + notas en Appraisal.Comment | LISTO PARA PROBAR | 4 campos desplegados (paquete v4, naming GRPQM). Exponer en la Lightning Page (v5) y probar |
| 11 | Al finalizar, Flow actualiza automáticamente la Opportunity | EN CONSTRUCCION (v5, Flow 3) | Decisión de modelado pendiente: campo destino del trade-in en Opportunity/Quote |
| 12 | Otra sucursal: ST correspondiente, Owner no cambia, Opportunity Team | LISTO PARA PROBAR (diseño) | Owner inmutable es comportamiento estándar; prueba completa requiere un segundo territory (o el de otra sucursal real) |
| 13 | Valor aceptado se consume como trade-in en la cotización y recalcula neto; envío por correo/WhatsApp | PARCIAL | Consumo en cotización: Flow 3 (v5). Envío O365/WhatsApp (GQ-CA-01-050) = OTRA FRENTE (integraciones) |
| 14 | Rechazo: renegociar o continuar sin usado, registrando motivo | EN CONSTRUCCION (v5, Flow 3 ramo rechazo) | RejectionReason__c desplegado; valores reales = INSUMO |
| 15 | Avalúo y resultado visibles en el 360 del prospecto | PARCIAL | Related lists nativas ya visibles; formalizar Lightning Record Page (v5) |

## Lectura rápida
- PROBADOS hoy: 6, 7, 8 (estructura), 2 (por diseño) — el corazón nativo de la HU.
- LISTOS PARA PROBAR (config de minutos): 1, 4, 9, 10, 12.
- EN CONSTRUCCION (paquete v5): 5, 11, 13 (lado SF), 14, 15 (página).
- INSUMO Grupo Q: PRU real (archivo/moneda/condicion), escala de condición
  (obligatoria — bloquea el alta del item), motivos de rechazo, valuadores,
  proveedor externo.
- OTRA FRENTE: Web-to-Lead digital (criterio 3), envío O365/WhatsApp (criterio 13).

## Escenarios de la HU vs pruebas
- Esc. 6 (registro nativo + PRU): PROBADO end-to-end 23/07.
- Esc. 2/3 (agendamiento interno): prueba pendiente del criterio 1.
- Esc. 4 (externo): Flow 2 (v5). Esc. 5 (otra sucursal): criterio 12.
- Esc. 7/8/10 (finalización, aceptación, rechazo): Flow 3 (v5).
- Esc. 9 (envío propuesta): otra frente. Esc. 1 (canal digital): otra frente.
- Esc. 11 (360): criterio 15.
