# Diagnostico — "Error al crear la cotizacion" (28/07/2026)

## Sintoma
El boton "Crear cotizacion" de la venta guiada fallaba con
"Script-thrown exception ... QuoteOrderService.createQuotesSingleVehicle:
line 43" (usuario Santiago) y luego "La oportunidad necesita un Pricebook
... line 45" (el numero de linea cambio porque Davi edito la clase entre
las dos pruebas).

## Causa raiz (leida en el codigo real, retrieve 28/07)
NO es un problema de permisos. Es un guard clause del propio codigo de
Davi (QuoteOrderService, lineas 43-46):

    if (opp.Pricebook2Id == null) {
        throw new QuoteOrderServiceException('La oportunidad necesita un Pricebook');
    }

La Opportunity de prueba 006WK00000NWE9GYAX no tiene Pricebook asignado,
asi que falla para CUALQUIER usuario. El "para mi funciona" inicial fue
una cuestion de tiempo: la prueba exitosa de Diego fue anterior a que el
guard existiera / a que se probara esa oportunidad.

Evidencia de los diagnosticos (Execute Anonymous):
- Santiago (005WK00000MzRGS): Opp visible (1), PBE 446, Prod 224,
  RT NewVehicle disponible — lectura y RT OK.
- Diego (005WK00000KECh4): Quote create true, QLI create true,
  Pricebook estandar activo 1, Pricebook custom activo:
  "C101 - Vehiculos y Motos (CR)" (01sWK000003AnvNYAS, CRC).

## Correccion (dato, no deploy)
En la Opportunity de prueba: lista relacionada Products > Choose Price
Book > "C101 - Vehiculos y Motos (CR)" y AGREGAR el producto del vehiculo
(ej. Hyundai Tucson) como linea. Ambas cosas: el codigo de Davi construye
las Quotes a partir de las OpportunityLineItems que son vehiculos
(semi-join VehicleDefinition); sin lineas de vehiculo, `quotes` queda
vacio y la siguiente falla seria "List index out of bounds" en
`quotes[0]` (linea 109).

## Hallazgos adicionales del diagnostico
1. QuoteLineItem.Vehicle__c SIN FLS para nadie (el describe de Diego,
   admin, devolvio false): los campos desplegados via Metadata API llegan
   sin FLS en ningun perfil. Hoy no rompe nada (el codigo de Davi tiene el
   mapeo comentado), pero hay que dar FLS ANTES de que Davi descomente el
   mapeo accesorio->vehiculo. Destino correcto: permission set del flujo
   (GuidedSellingAccess, pendiente de crear) — no editar perfiles.
2. Sugerencia para Davi (registrada, no impuesta): en vez de lanzar
   excepcion, el service puede resolver el pricebook de la sociedad y
   asignarlo a la Opportunity cuando venga null (un update), y construir
   las lineas desde selectedVehicles en lugar de exigir OppLineItems
   pre-cargadas — el TODO updateOppLineItemsVehiclesAndAccessories ya
   apunta ahi.
3. El nombre del pricebook "C101 - Vehiculos y Motos (CR)" lleva sociedad
   y pais: es DATO (no metadato), la convencion GRPQM no lo prohibe, pero
   conviene definir el catalogo de pricebooks por sociedad con GrupoQ.

## Captura de la org (carpeta captura-org-20260728/)
Retrieve del estado real de la org (paquete
package-retrieve-captura-org-actual.xml): las 8 LWC con nombres viejos,
las 10 clases con el codigo REAL de Davi (createQuotesSingleVehicle,
DTOs VehicleDTO/Disponibilidad, wire del createQuote en ventaGuiadaModal)
y la QuickAction vieja. Es la BASE de la reconciliacion v19
(renombre GRPQM + codigo real, sin perder nada de Davi). El v18 NO debe
desplegarse como esta: su destructiveChangesPost borraria estos aportes.
