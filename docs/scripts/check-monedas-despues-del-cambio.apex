/**
 * Verificacion despues de cambiar la moneda corporativa a USD.
 *
 * Cambiar la moneda corporativa re-basa las tasas de conversion, pero NO
 * cambia la moneda de los registros que ya existen ni la de las entradas de
 * precio. Este script muestra que quedo en cada moneda, que es lo que falta
 * convertir de verdad.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

System.debug('===================================================');
System.debug('ESTADO DE MONEDAS DESPUES DEL CAMBIO');
System.debug('===================================================');

System.debug('----- 1. MONEDAS Y TASAS, YA RE-BASADAS -----');
try {
    for (CurrencyType c : [SELECT IsoCode, ConversionRate, IsCorporate, IsActive, DecimalPlaces
                           FROM CurrencyType ORDER BY IsCorporate DESC, IsoCode]) {
        System.debug('   ' + c.IsoCode
            + (c.IsCorporate ? '  <<< CORPORATIVA' : '')
            + ' | activa=' + c.IsActive
            + ' | tasa=' + c.ConversionRate
            + ' | decimales=' + c.DecimalPlaces);
    }
    System.debug('   Revisar que las tasas quedaron correctas: ahora se expresan');
    System.debug('   contra USD, no contra la moneda corporativa anterior.');
} catch (Exception e) {
    System.debug('   ERROR leyendo CurrencyType: ' + e.getMessage());
}

System.debug('----- 2. ENTRADAS DE PRECIO POR LISTA Y MONEDA -----');
System.debug('   Esto es lo que el proceso comercial realmente lee.');
try {
    for (AggregateResult ar : [SELECT Pricebook2.Name lista, CurrencyIsoCode moneda,
                                      COUNT(Id) qtd, MIN(UnitPrice) minimo, MAX(UnitPrice) maximo
                               FROM PricebookEntry
                               GROUP BY Pricebook2.Name, CurrencyIsoCode
                               ORDER BY Pricebook2.Name]) {
        System.debug('   ' + ar.get('lista') + ' | ' + ar.get('moneda')
            + ' | entradas=' + ar.get('qtd')
            + ' | rango=' + ar.get('minimo') + ' a ' + ar.get('maximo'));
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('----- 3. REGISTROS COMERCIALES POR MONEDA -----');
System.debug('   Cambiar la moneda corporativa NO los toco. Siguen como estaban.');
for (String obj : new List<String>{ 'Opportunity', 'Quote', 'Order' }) {
    try {
        for (AggregateResult ar : Database.query(
                'SELECT CurrencyIsoCode moneda, COUNT(Id) qtd FROM ' + obj
                + ' GROUP BY CurrencyIsoCode ORDER BY CurrencyIsoCode')) {
            System.debug('   ' + obj + ' | ' + ar.get('moneda') + ' | ' + ar.get('qtd'));
        }
    } catch (Exception e) {
        System.debug('   ' + obj + ' => ' + e.getMessage());
    }
}

System.debug('----- 4. LO QUE SUELE SORPRENDER -----');
System.debug('   La moneda de una PricebookEntry se define al crearla y no se');
System.debug('   edita despues: hay una entrada por producto, lista y moneda.');
System.debug('   Para publicar en USD lo que hoy esta en CRC hay que CREAR las');
System.debug('   entradas en USD, no convertir las existentes.');
System.debug('   Y una Opportunity solo puede pasar a USD si la lista que usa');
System.debug('   ya tiene entradas en USD para sus productos.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
