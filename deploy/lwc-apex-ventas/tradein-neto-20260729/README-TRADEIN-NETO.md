# Retoma en la venta guiada - paquete tradein-neto (29/07/2026)

## Principio de diseno (por que SF y SAP siempre coinciden)

La retoma NO es descuento de precio: es COMPOSICION DE PAGO. El precio del
vehiculo sigue siendo el del SAP (RN intacta: SF no calcula precios); el
avaluo aceptado reduce el NETO A PAGAR, igual que el anticipo.

El "mismo calculo en los dos lados" se garantiza por construccion, no por
sincronizacion: Salesforce manda a SAP los OPERANDOS (precio por linea +
valor de retoma congelado + referencia del avaluo), nunca un neto calculado.
Ambos sistemas hacen la misma aritmetica trivial sobre los mismos operandos:
neto = precio + accesorios + impuestos - retoma - anticipo. SAP hace el
neteo financiero real en la facturacion (compra del usado + venta del nuevo).

Base verificada (describe 23/07, registrado en MODELAGEM-AVALUO.md y en la
description del campo de la opp): NO existe columna nativa de trade-in en
Opportunity ni en Quote en esta org - por eso los campos custom. En el
Appraisal el valor final es FORMULA nativa (FinalAppraisalValue =
TotalItemFinalValue + TotalAdjustmentValue, updateable=false): el valuador
no digita, y lo que la quote congela es el resultado de esa formula ya
aceptado (Status = Aceptado, picklist sembrado por HU-036).

## Cadena ya entregada que este paquete consume

1. HU-036: Appraisal After Handler estampa FinalAppraisalValue en
   Opportunity.TradeInValue__c cuando el avaluo pasa a aceptado.
2. Este paquete: la cotizacion CONGELA ese valor en Quote.TradeInValue__c
   (revision posterior del avaluo nunca cambia lo negociado; re-aplicar es
   accion explicita del vendedor).
3. El pedido lleva el bloque tradeIn a SAP (gate de contrato abajo).

## Contenido

| Componente | Cambio |
|---|---|
| Quote.TradeInValue__c (nuevo) | Monto de retoma congelado al crear la quote |
| Quote.NetAmount__c (nuevo) | Formula: GrandTotal - TradeInValue (solo display) |
| QuoteOrderService | Query trae Opportunity.TradeInValue__c y lo estampa en la PRIMERA quote de vehiculo (regla de reparto multi-vehiculo pendiente de negocio - estampar en todas duplicaria la retoma) |
| PricingService | Overload con opportunityId: PricingResult.tradeInValue (operando para la pantalla de precio, implementado) |
| SapOrderService | DTO OrderPayload con bloque tradeIn opcional (appraisalId + value + currency) y TODO del gate de contrato |
| lwc/resumenFinanciero (nuevo) | Componente compartido: renderiza operandos y neto; no consulta ni calcula precios. Uso: `<c-resumen-financiero precio-vehiculo={...} retoma={...} ...>` dentro de ventaVehiculo / ventaUsados |

## Gates ABIERTOS (no desplegar el tramo SAP sin cerrarlos)

1. CONTRATO MULESOFT: el bloque tradeIn NO existe en el contrato de pedido
   (Annex). Alta formal igual que HU-039 antes de activar el envio.
2. REPARTO MULTI-VEHICULO: con mas de un vehiculo en la opp, a que quote va
   la retoma? Hoy: primera quote (documentado en codigo). Definir con negocio.
3. VIGENCIA DEL AVALUO: el campo NATIVO Appraisal.ValidityEndDate ya existe
   (describe 23/07, MODELAGEM-AVALUO). El gate del paso "aplicar retoma" es
   ValidityEndDate &gt;= TODAY, sin campo custom. Falta solo que GrupoQ defina
   el plazo estandar que el valuador estampa.
4. AVALUO QUE DEJA DE ESTAR ACEPTADO tras congelarse en una quote: alertar a
   la opp (flow en VehicleAppraisal), nunca deshacer solo. Evolucion aparte.

## v2 (29/07 tarde) - retoma DENTRO del calculo de la venta guiada

Con el describe de la org (log 29/07): PricebookEntry ya tenia la mitad
local del precio (Gastos__c, PrecioMinimoAsesor__c, PrecioExonerado__c,
PrecioExoneradoMinimo__c, AplicaCashback__c, MontoCashback__c). Novedades:

- PricingService IMPLEMENTADO (ya no stub): columnas de referencia del PBE
  (con swap exonerado cuando Opportunity.VentaExonerada__c), cashback,
  operando de retoma con GATE DE VIGENCIA (solo avaluo Aceptado con
  ValidityEndDate >= TODAY cuenta; vencido -> isTradeInExpired=true para
  la pantalla avisar y bloquear). El impuesto de referencia sigue TODO BRE.
- GuidedSellingController.getPricePageData IMPLEMENTADO: nuevo parametro
  opportunityId; resuelve el PricebookEntry por el pricebook de la Opp
  (pricebook = sociedad) + ProductCode, delega al servicio y devuelve el
  PricingResult serializado. Sin PBE (usados) igual devuelve la retoma.

Cableado del modal (paso 'precio', para Davi):
1. Llamar getPricePageData(materialCode, sociedad, null, null, 1, recordId).
2. Desglose: listPrice / expenses / (referencia BRE cuando llegue) y la fila
   "Retoma (avaluo aceptado)" en negativo cuando tradeInValue > 0.
3. Pie: <c-resumen-financiero precio-vehiculo={listPrice} accesorios={...}
   impuestos={...} retoma={tradeInValue} anticipo={0} currency-code={...}>.
   Anticipo queda en 0 hasta confirmar el API name del campo de la Opp
   (describe pendiente - los campos de pago tienen API en ingles).
4. isTradeInExpired=true -> banner de aviso y NO restar la retoma.
5. minimumPrice alimenta el paso 'descuento' (guard del approval).

Hallazgo del describe a resolver aparte: QuoteLineItem.Vehicle__c NO esta
en la org aunque el DLG lo marca desplegado (v17) - re-verificar el deploy
del esqueleto antes del mapeo accesorio->vehiculo.

## Deploy (DevSales)

```
sf project deploy start --metadata-dir deploy/lwc-apex-ventas/tradein-neto-20260729 -o DevSales
```

Orden interno: objects -> classes -> lwc (el package.xml ya lo resuelve).
Post-deploy: FLS de los 2 campos de Quote a los perfiles/PS de ventas +
agregar al page layout de Quote (patron TRIO del DLG). Registrar en el DLG
de componentes y en la GUIA el mismo dia.

## Pruebas minimas

1. Opp con avaluo aceptado (TradeInValue estampado por HU-036) -> crear
   cotizacion por venta guiada -> Quote.TradeInValue__c congelado y
   NetAmount = GrandTotal - retoma.
2. Revisar el avaluo despues (cambiar FinalAppraisalValue) -> la quote NO
   cambia; la opp si (comportamiento esperado, documentado).
3. Opp sin avaluo -> quote sin retoma, NetAmount = GrandTotal.
4. Dos vehiculos en la opp -> retoma solo en la primera quote (hasta la
   regla de reparto).
