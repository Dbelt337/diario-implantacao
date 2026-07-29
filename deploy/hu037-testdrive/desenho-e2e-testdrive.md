# Test Drive - desenho end to end (papel de pao)

```mermaid
flowchart TD
    A[Oportunidad<br>asesor abre Test Drive] --> B{Licencia de conducir<br>valida?}
    B -- no --> B2[No avanza:<br>capturar licencia<br>IdentityDocument]
    B2 --> B
    B -- si --> C[Elegir sucursal, horario,<br>carro demo y asesor<br>OmniScript GQAutoCloudScheduler]
    C --> D[SERVICE APPOINTMENT<br>reserva oficial<br>bloquea el VIN del demo]
    D --> E[Flow estampa en el SA:<br>asesor + vehiculo<br>+ licencia via OmniScript]
    E --> F[PDF de autorizacion<br>Service Report<br>cliente firma en fisico]

    D -.solo si hand-off digital->presencial.-> G[Flow crea Event<br>con sucursal]
    G --> H[Recepcion: Recibir Cliente<br>HU-009: Opp pasa al<br>asesor presencial]

    D -. cambio de carro u horario .-> I[Modify sobre el SA<br>re-estampa solo]
    I --> E

    F --> J[Prueba realizada]
    J --> K[Cierre en el SA:<br>km inicial/final, condicion]
    K --> L[Actualiza odometro del Vehicle<br>+ tarea en la Opp<br>+ VIN libre para otra prueba]
```

Leyenda rapida:
- El Service Appointment es la fuente de verdad; la Oportunidad sigue siendo la venta.
- Linea punteada = camino opcional (hand-off / reprogramacion).
- El Event solo existe con hand-off; nunca se crea a mano.
