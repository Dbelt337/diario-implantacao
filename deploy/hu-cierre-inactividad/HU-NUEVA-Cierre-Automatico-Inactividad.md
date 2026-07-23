# HU-0XX (nueva) — All_Cierre automático de oportunidades por inactividad

BORRADOR para validación (proceso de admisión de la GUIA) — 23/07/2026.
Origen: punto 6 "Fechamento automático" del Excel del cliente, detectado por
Marianne en la revisión de la HU-024 (GQAUT-110). NO es un escenario faltante
de la HU-024 (cierre manual): es una capacidad nueva de gobernanza del
pipeline. Numerar en el Story Map al admitirla.

## Épica / Fase
Auto: E10 — Gestión de Oportunidades y Pipeline · Gobernanza de inactividad.

## Cloud / Producto
Sales Cloud (Opportunity, Flow programado, Custom Notification, Reportes).
Sin objetos custom.

## Dependencias
- HU-024 (cierre con motivo): el cierre automático REGISTRA el motivo por el
  mismo mecanismo — se agrega el valor "Cierre automático por inactividad".
- HUs de asignación/routing de leads: la reactivación del cliente pasa por el
  proceso de asignación ya definido.

## Historia de usuario
Como Gerente de Ventas
Quiero que el sistema detecte oportunidades sin seguimiento, alerte al asesor
antes de cerrarlas y las cierre automáticamente al cumplirse el plazo
Para mantener el pipeline sano, con motivos de cierre trazables y visibilidad
de los asesores que no registran su seguimiento.

## Reglas de negocio
1. Inactividad = días transcurridos desde la última actividad de la
   oportunidad, usando el campo estándar LastActivityDate (considera
   actividades completadas Y eventos programados — cumple "tomar en cuenta
   las actividades de acompañamiento programadas").
2. Plazo de inactividad: 30 días (parámetro a confirmar con el cliente).
3. Alerta previa: a los N días (propuesta: 23) el asesor recibe notificación
   (Custom Notification + tarea) de que la oportunidad será cerrada.
4. Cierre automático: al llegar a 30 días, la oportunidad se cierra Perdida
   con motivo "Cierre automático por inactividad" (lista de motivos de la
   HU-024). El Owner y el gerente quedan notificados.
5. Reactivación: si el cliente vuelve a escribir, la nueva solicitud pasa por
   el proceso de asignación definido en las historias anteriores (no se
   reabre la oportunidad cerrada; trazabilidad por el 360).
6. Visibilidad gerencial: reporte/dashboard nativo de oportunidades por días
   sin actividad y por asesor (apoyo para detectar falta de seguimiento).
7. "Bloqueo del usuario": PENDIENTE DE DEFINICION con el cliente — la
   interpretación propuesta es bloquear/cerrar la OPORTUNIDAD y señalizar al
   gerente (no bloquear el login del usuario). Confirmar en refinamiento.

## Escenarios
Escenario 1 — Alerta previa por inactividad
Dado una oportunidad abierta cuyo LastActivityDate supera N días
Cuando corre la evaluación diaria
Entonces el asesor recibe una notificación y una tarea indicando la fecha en
que la oportunidad será cerrada si no registra seguimiento.

Escenario 2 — Cierre automático con motivo
Dado una oportunidad abierta con 30 días sin actividad (incluidas las
programadas)
Cuando corre la evaluación diaria
Entonces el sistema cierra la oportunidad como Perdida con motivo "Cierre
automático por inactividad" y notifica al Owner y a su gerente.

Escenario 3 — La actividad programada evita el cierre
Dado una oportunidad con un evento de seguimiento programado
Cuando corre la evaluación diaria
Entonces la oportunidad NO se cierra (el plazo cuenta desde la última
actividad programada/registrada).

Escenario 4 — Reactivación del cliente
Dado un cliente cuya oportunidad fue cerrada por inactividad
Cuando el cliente vuelve a contactar por cualquier canal
Entonces la solicitud pasa por el proceso de asignación definido en las
historias anteriores y el historial anterior queda visible en el 360.

Escenario 5 — Visibilidad gerencial
Dado oportunidades con distintos niveles de inactividad
Cuando el gerente consulta el reporte/dashboard de seguimiento
Entonces ve las oportunidades por días sin actividad y por asesor.

## Criterios de aceptación
1. La inactividad se mide con LastActivityDate (estándar), incluyendo
   actividades programadas.
2. Alerta previa configurable antes del cierre (notificación + tarea).
3. Cierre automático al plazo definido, como Perdida, con motivo "Cierre
   automático por inactividad" registrado por el mecanismo de la HU-024.
4. La reactivación del cliente pasa por el proceso de asignación vigente.
5. Reporte/dashboard nativo de inactividad por asesor.
6. Parámetros (plazos, destinatarios) definidos por el negocio en
   refinamiento; el diseño los deja ajustables sin cambio de estructura.

## Fuera de alcance
- Bloqueo de login de usuarios (pendiente redefinición del requisito).
- Reapertura automática de oportunidades cerradas.

## Preguntas para el refinamiento
1. ¿Qué significa exactamente "bloquear al usuario"? (propuesta: cerrar la
   oportunidad + señal al gerente)
2. ¿Plazos definitivos de alerta y cierre? (propuesta: 23 y 30 días)
3. ¿Quién recibe las alertas además del Owner? (¿gerente de sucursal?)
4. ¿El cierre automático aplica a todas las etapas del pipeline o excluye
   etapas avanzadas (ej. Cotización Confirmada)?
