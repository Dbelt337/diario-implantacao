# HU-039 — Decision del objeto de la solicitud de material (28/07/2026)

## Pregunta
Existe un objeto standard (Automotive Cloud / Field Service) para "solicitar
material", que permita solo crear un registro en Salesforce en lugar del
modelo Product2 + Record Type?

## Evidencia (describe corrido en DEV el 28/07)
La familia de inventario del Field Service EXISTE y esta habilitada en la
org (licencia Inventory Search and Transfer, 2.130 asientos — evidencia
22/07): ProductRequest, ProductRequestLineItem, ProductTransfer, ProductItem.

Hallazgo decisivo: **ProductRequestLineItem.Product2Id es OBLIGATORIO**
(lookup requerido a Product2). La linea del ProductRequest exige un material
EXISTENTE — el objeto representa pedidos de stock/traslado de piezas ya
creadas, no solicitudes de creacion de dato maestro.

## Decision
Se CONFIRMA la solucion registrada: la solicitud es un **Product2 con
Record Type "Solicitud de Material"** (IsActive=false; el MATNR vuelve AL
MISMO registro y lo activa). Motivos:

1. ProductRequest no puede representar un material inexistente (describe).
2. Usarlo obligaria a crear el Product2 primero — dos registros a
   sincronizar contra uno solo en la solucion vigente.
3. La familia ProductRequest/ProductTransfer queda RESERVADA para su
   proposito real: traslados entre sucursales (RN-04 HU-042) y
   reabastecimiento de posventa. No contaminar ese proceso standard.
4. La restriccion del cliente (sin objeto custom nuevo; Case excluido)
   sigue respetada. Plan B registrado: Case con RT dedicado si GrupoQ
   exigiera colas formales.

## Bonus del describe
ProductItem (Location + Product2 + QuantityOnHand obligatorios) confirma el
inventario nativo validado en HU-025, listo para la carga cuando llegue.
