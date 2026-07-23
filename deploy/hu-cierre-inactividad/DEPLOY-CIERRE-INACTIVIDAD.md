# Cierre automático por inactividad — estado del deploy (DEV)

HU: borrador en admisión (HU-NUEVA-Cierre-Automatico-Inactividad.md).
Regla de gobernanza: el Flow queda en DRAFT y SIN ACTIVAR hasta que la HU sea
admitida y numerada; al numerarla, registrar los componentes en el control de
componentes ("Ventas / HU-0XX") el mismo día.

## Desplegado en DEV 23/07/2026 (CierreInactividad_v2.zip, success 9/9)
| Componente | Tipo | Id DEV |
|---|---|---|
| InactivityPolicy__mdt "Política de Inactividad" (+5 campos) | CustomObject (CMDT) | 01IWK000001r4bB2AQ |
| InactivityPolicy.Default (23 / 30 / Closed Lost / textos) | CustomMetadata (registro) | m0GWK000009iekX2AQ |
| Flow "Close Inactive Opportunities" (Scheduled, diario 06:00 UTC) | Flow (DRAFT) | 301WK00002TtSwTYAV |

## Diseño (cero hardcode)
- Todos los parámetros viven en el CMDT: Setup > Custom Metadata Types >
  Política de Inactividad > Manage Records > Default > Edit.
- Inactividad medida con LastActivityDate (estándar; incluye actividades
  programadas), con fallback a CreatedDate si nunca hubo actividad.
- Alerta única (deduplicada por Subject) con vencimiento en la fecha prevista
  del cierre; cierre como perdida en la etapa configurada + tarea informativa.
- Sin registro de política, el flow no hace nada (a prueba de org sin config).

## Pendientes antes de ACTIVAR
- [ ] HU admitida y numerada (Melisa/Marianne) — actualizar Mapa de HUs.
- [ ] LostStageName__c: reemplazar "Closed Lost" por el API name real de la
      etapa perdida del funil (editar el registro Default).
- [ ] Vincular el motivo: agregar en el elemento "Close Opportunity As Lost"
      el campo de motivo de cierre de la HU-024 (API name a confirmar) con el
      valor CloseReasonValue__c del CMDT; sembrar "Cierre automático por
      inactividad" en la picklist de motivos.
- [ ] Prueba en DEV: bajar temporalmente los días (0/1) en el registro
      Default, Debug del flow sobre una Opportunity de prueba, verificar tarea
      y cierre, restaurar 23/30.
- [ ] Definiciones de refinamiento: significado de "bloquear usuario", plazos
      definitivos, destinatarios de alertas, etapas excluidas.
