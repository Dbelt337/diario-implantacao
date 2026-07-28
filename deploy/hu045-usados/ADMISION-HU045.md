# HU-045 — Auto: Registro de Vehículo Usado — mapa de admision (28/07/2026)

Consolidacion de lo decidido en las sesiones de arquitectura (proceso de
admision de la GUIA: resguardos -> flujo -> modelo -> fronteras -> tareas).

## 1. Que resuelve
Registrar el vehiculo usado en Salesforce como UNIDAD comercializable
(inventario PROPIO del GrupoQ): VIN, datos minimos, ficha e historial.
Los usados SE COMERCIALIZAN en Salesforce — el inventario y el precio son
de gestion propia, sin consulta SAP para el precio de exhibicion.

## 2. Modelagem (Automotive Cloud — validada con la documentacion oficial)
- **Vehicle** = la unidad fisica: VehicleIdentificationNumber (VIN, clave
  natural), kilometraje, datos de la ficha; VehicleDefinitionId -> modelo.
- **VehicleDefinition/Product2** = el modelo/version (catalogo); si el
  usado es de una marca/modelo fuera del catalogo GrupoQ, la ficha vive en
  campos del Vehicle (sin crear catalogo para terceros).
- **Asset** = el periodo de PROPIEDAD. Regla de oro: NUNCA transferir el
  Asset — al cambiar el dueno se CIERRA el asset anterior (UsageEndDate),
  se CREA el nuevo del comprador y se re-apunta Vehicle.AssetId. La unidad
  (Vehicle) es una sola para siempre; los Assets son la linea de tiempo.
- Asset SOLO para propiedad de cliente final gestionada por GrupoQ:
  consignacion = Contract (RT dedicado); stock propio del GrupoQ = estado/
  Location del Vehicle; historia fuera del GrupoQ = campos de ficha.

## 3. Los 3 origenes de ingreso del usado
1. **Trade-in / avaluo (HU-036)**: el avaluo aceptado ingresa la unidad;
   elo tecnico: AppraisalItem.ReferenceRecordId (polimorfico Asset/Vehicle)
   — si el VIN ya fue vendido por GrupoQ, se RE-VINCULA la unidad existente
   (historial completo de la casa). PENDIENTE: captura del VIN en el flujo
   del avaluo (ajuste HU-036).
2. **Compra directa**: registro manual de la unidad (pantalla/flujo de alta
   con datos minimos RN-2).
3. **Consignacion (RN-3)**: la unidad se registra igual (Vehicle), la
   relacion comercial vive en un Contract con RT dedicado — el GrupoQ no es
   dueno, no hay Asset del GrupoQ.

## 4. Reglas revisadas (V3 del documento)
- **RN-1 VIN**: VIN obligatorio y unico (clave natural del Vehicle;
  VehicleIdentificationNumber nativo). Anti-duplicado por VIN al registrar:
  si existe, RE-USAR la unidad (re-vinculo), jamas crear segunda.
- **RN-2 datos minimos**: ficha del usado (kilometraje, duenos anteriores,
  tipo de adquisicion, estado, ubicacion) — campos nativos del Vehicle +
  custom SOLO tras describe (disciplina T01).
- **RN-3 consignacion**: redaccion ajustada — el control de acceso por
  sociedad va por PERMISSION SET (no por RT por sociedad; nombres de
  metadato sin pais, convencion GRPQM).

## 5. Fronteras y elos
- HU-036 (avaluo) alimenta el ingreso por trade-in.
- HU-042 (seleccion): usados se cotizan POR UNIDAD (VIN) — ya construido:
  RT Quote UsedVehicle + QuoteLineItem.Vehicle__c (v17, describe corrido)
  + flujo de usados del mock (ficha, inventario propio, SOQL sin SAP).
- Assetizacion en la venta del usado: cerrar asset del dueno anterior +
  crear el del comprador (misma unidad) — gatillo Facturado, como nuevos.
- **PENDIENTE BLOQUEANTE con GrupoQ**: facturacion del usado — SAP o
  local? Define el ciclo del pedido del usado (si SAP: mismo ciclo
  Enviado->Confirmado->Facturado; si local: gatillo de assetizacion local).

## 6. Estado del build
- Ya construido (HU-042/esqueleto): flujo de venta del usado en el mock
  (v6+), RT UsedVehicle, Vehicle__c, leyendas de inventario propio.
- Falta de esta HU: pantalla/flujo de ALTA de la unidad (3 origenes),
  anti-duplicado por VIN, ficha (describe de campos del Vehicle antes de
  crear custom), list views del inventario de usados, carga inicial (si
  hay stock historico).
