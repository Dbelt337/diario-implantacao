/**
 * Cuantos leads y cuantos convertidos hay, para Einstein Lead Scoring.
 *
 * Los umbrales documentados por Salesforce, por segmento, incluido el segmento
 * All Leads por defecto:
 *   - al menos 1.000 leads creados en los ultimos 200 dias;
 *   - de esos, al menos 120 convertidos a cuenta y contacto;
 *   - opcional, 120 convertidos en los ultimos 180 dias con oportunidad creada
 *     en el momento de la conversion.
 *
 * Este script cuenta exactamente eso y dice cuanto falta.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado, EN LA ORG DE QA.
 */

Organization laOrg = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | instancia=' + laOrg.InstanceName + ' | sandbox=' + laOrg.IsSandbox);
if (laOrg.IsSandbox) {
    System.debug('   ATENCION: es sandbox. Ver la nota del final.');
}

Datetime hace200 = System.now().addDays(-200);
Datetime hace180 = System.now().addDays(-180);

System.debug('===================================================');
System.debug('1. LOS TRES NUMEROS QUE EINSTEIN MIRA');
System.debug('===================================================');

Integer total       = [SELECT COUNT() FROM Lead];
Integer creados200  = [SELECT COUNT() FROM Lead WHERE CreatedDate >= :hace200];
Integer convert200  = [SELECT COUNT() FROM Lead
                       WHERE CreatedDate >= :hace200 AND IsConverted = true];
Integer convert180  = [SELECT COUNT() FROM Lead
                       WHERE CreatedDate >= :hace180 AND IsConverted = true];
Integer conOpp180   = [SELECT COUNT() FROM Lead
                       WHERE CreatedDate >= :hace180 AND IsConverted = true
                         AND ConvertedOpportunityId != null];

System.debug('   Leads en total, sin filtro de fecha : ' + total);
System.debug('   Creados en los ultimos 200 dias     : ' + creados200
    + '   (minimo 1000)  ' + (creados200 >= 1000 ? 'OK' : 'FALTAN ' + (1000 - creados200)));
System.debug('   Convertidos de esos                 : ' + convert200
    + '   (minimo 120)   ' + (convert200 >= 120 ? 'OK' : 'FALTAN ' + (120 - convert200)));
System.debug('   Convertidos en los ultimos 180 dias : ' + convert180);
System.debug('   De esos, con oportunidad creada     : ' + conOpp180
    + '   (opcional 120) ' + (conOpp180 >= 120 ? 'OK' : 'FALTAN ' + (120 - conOpp180)));

Decimal tasa = creados200 == 0 ? 0
    : ((Decimal) convert200 / creados200 * 100).setScale(2);
System.debug('   Tasa de conversion en 200 dias      : ' + tasa + ' por ciento');
System.debug('   Una tasa muy alta o muy baja tambien hace el modelo no salir.');

System.debug('===================================================');
System.debug('2. CONVERTIDOS POR TIPO DE REGISTRO');
System.debug('===================================================');
System.debug('   Si se crean segmentos por linea de negocio, CADA segmento');
System.debug('   necesita los mismos 1000 y 120. Es el error mas comun.');
for (AggregateResult ar : [SELECT RecordType.DeveloperName rt, COUNT(Id) q
                           FROM Lead WHERE CreatedDate >= :hace200
                           GROUP BY RecordType.DeveloperName]) {
    String rt = String.valueOf(ar.get('rt'));
    Integer creados = (Integer) ar.get('q');
    Integer convert = Database.countQuery(
        'SELECT COUNT() FROM Lead WHERE CreatedDate >= :hace200 '
        + 'AND IsConverted = true AND RecordType.DeveloperName = \'' + rt + '\'');
    System.debug('   ' + rt + ' | creados=' + creados + ' | convertidos=' + convert
        + (creados >= 1000 && convert >= 120 ? '  OK' : '  INSUFICIENTE'));
}

System.debug('===================================================');
System.debug('3. CONVERTIDOS POR MES, PARA VER SE HAY HISTORIA');
System.debug('===================================================');
for (AggregateResult ar : [SELECT CALENDAR_YEAR(CreatedDate) anio,
                                  CALENDAR_MONTH(CreatedDate) mes, COUNT(Id) q
                           FROM Lead WHERE IsConverted = true
                           GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
                           ORDER BY CALENDAR_YEAR(CreatedDate) DESC,
                                    CALENDAR_MONTH(CreatedDate) DESC
                           LIMIT 12]) {
    System.debug('   ' + ar.get('anio') + '-' + ar.get('mes') + ' | ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('4. ESTADO DE LOS LEADS, PARA ENTENDER EL EMBUDO');
System.debug('===================================================');
for (AggregateResult ar : [SELECT Status s, IsConverted c, COUNT(Id) q
                           FROM Lead GROUP BY Status, IsConverted
                           ORDER BY Status]) {
    System.debug('   ' + ar.get('s') + ' | convertido=' + ar.get('c')
        + ' | ' + ar.get('q'));
}

System.debug('===================================================');
System.debug('5. LO QUE PROBABLEMENTE ESTA PASANDO');
System.debug('===================================================');
System.debug('   Einstein Lead Scoring se habilita y se entrena en PRODUCCION.');
System.debug('   En sandbox no arma modelo, por mas que los numeros den. Si el');
System.debug('   objetivo es solo ver la funcionalidad en QA, el camino no es');
System.debug('   este: es mostrarla en produccion o con datos de demostracion.');
System.debug('   ');
System.debug('   Y si los numeros de arriba no llegan a 1000 y 120, tampoco');
System.debug('   armaria modelo propio en produccion. En ese caso Einstein usa');
System.debug('   un modelo global, con datos anonimos de otros clientes, que');
System.debug('   funciona pero no aprende del negocio del GrupoQ.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
