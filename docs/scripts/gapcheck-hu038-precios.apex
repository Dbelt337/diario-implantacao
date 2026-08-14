/**
 * GAPCHECK HU-038, precios de vehiculos.
 *
 * Confirma en la org las tres cosas de las que depende el diseno y que no
 * conviene dar por sabidas: si PricebookEntry sostiene historico, si
 * Pricebook2 admite comparticion, y si el motor de reglas esta disponible
 * para impuestos y factores.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 */

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

System.debug('===================================================');
System.debug('GAPCHECK HU-038');
System.debug('===================================================');

System.debug('----- 1. HISTORICO Y COMPARTICION -----');
for (String nombre : new List<String>{
        'PricebookEntryHistory',   // historico de campo de la entrada de precio
        'PricebookEntryChangeEvent',
        'Pricebook2History',
        'Pricebook2Share',         // si existe, hay comparticion por lista, base del acceso por marca
        'Product2History' }) {
    System.debug('   ' + (gd.containsKey(nombre.toLowerCase()) ? 'SI  ' : 'NO  ') + nombre);
}

System.debug('----- 2. MOTOR DE REGLAS PARA IMPUESTOS Y FACTORES -----');
for (String nombre : new List<String>{
        'CalculationMatrix', 'CalculationMatrixVersion', 'CalculationMatrixRow',
        'ExpressionSet', 'ExpressionSetVersion', 'DecisionMatrixDefinition' }) {
    System.debug('   ' + (gd.containsKey(nombre.toLowerCase()) ? 'SI  ' : 'NO  ') + nombre);
}

System.debug('----- 3. PRICEBOOKENTRY, CAMPOS ACTUALES -----');
List<String> requeridos = new List<String>{
    'PrecioMinimoAsesor__c', 'MontoCashback__c', 'AplicaCashback__c',
    'PrecioExonerado__c', 'PrecioExoneradoMinimo__c', 'Gastos__c', 'VigenciaDesde__c',
    'ImpuestoPrimeraMatricula__c', 'PrecioFlotas__c',
    'CostoEstimado__c', 'CostoEstimadoExonerado__c', 'CashbackVigenciaHasta__c',
    'MinimoGerenteVentas__c', 'MinimoGerenteMarca__c', 'MinimoDirector__c'
};
Map<String, Schema.SObjectField> pbe = PricebookEntry.SObjectType.getDescribe().fields.getMap();
Integer faltan = 0;
for (String c : requeridos) {
    Boolean existe = pbe.containsKey(c.toLowerCase());
    if (!existe) { faltan++; }
    System.debug('   ' + (existe ? 'YA EXISTE : ' : 'FALTA     : ') + c);
}
System.debug('   Faltan ' + faltan + ' de ' + requeridos.size());

System.debug('----- 4. CUANTOS CAMPOS PUEDEN LLEVAR HISTORICO -----');
System.debug('   Limite de la plataforma: 20 campos rastreados por objeto.');
Integer customs = 0;
for (Schema.SObjectField f : pbe.values()) {
    if (f.getDescribe().isCustom()) { customs++; }
}
System.debug('   PricebookEntry tiene hoy ' + customs + ' campos custom.');
System.debug('   Con los 11 comerciales mas los calculados, el margen contra el limite es estrecho.');

System.debug('----- 5. MULTIMONEDA Y REDONDEO -----');
try {
    for (CurrencyType c : [SELECT IsoCode, ConversionRate, IsCorporate, IsActive, DecimalPlaces
                           FROM CurrencyType ORDER BY IsoCode]) {
        System.debug('   ' + c.IsoCode + ' | corporativa=' + c.IsCorporate
            + ' | activa=' + c.IsActive + ' | decimales=' + c.DecimalPlaces
            + ' | tasa=' + c.ConversionRate);
    }
} catch (Exception e) {
    System.debug('   La org no es multimoneda o no se pudo leer: ' + e.getMessage());
}
System.debug('   RN6 exige que el redondeo coincida con SAP, que calcula con cuatro');
System.debug('   decimales y monta las posiciones con dos. Los decimales de arriba');
System.debug('   son los que Salesforce aplica al exhibir.');

System.debug('----- 6. LISTAS DE PRECIO ACTUALES -----');
for (Pricebook2 pb : [SELECT Name, IsStandard, IsActive FROM Pricebook2 ORDER BY Name]) {
    System.debug('   ' + pb.Name + ' | standard=' + pb.IsStandard + ' | activa=' + pb.IsActive);
}
System.debug('   La HU nombra 12 sociedades: C101, C105, S101, S206, S105, G101,');
System.debug('   H101, H105, N101, N105, P103, P105. Y exige lista de accesorios aparte.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
