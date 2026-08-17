/**
 * Dos anomalias que aparecieron en UAT (00DWK000005VF7x2AG) el 17/08.
 *
 * 1. UN LEAD CON Status = 'Convertido' Y IsConverted = false.
 *    IsConverted es de solo lectura y lo pone la plataforma al convertir. El
 *    Status es una picklist que cualquiera, o cualquier Flow, puede escribir.
 *    Un lead parado en el estado de convertido SIN haber sido convertido no
 *    tiene cuenta, ni contacto, ni oportunidad, y aun asi sale del embudo en
 *    todo reporte que filtre por Status. Es un lead perdido en silencio.
 *
 * 2. VEINTIDOS LEADS SIN RECORD TYPE, sobre 179. Doce por ciento.
 *    Sin Record Type no hay layout, ni reglas por linea de negocio, ni
 *    segmento posible.
 *
 * El script tambien compara la lista de valores de Status con la de QA, porque
 * los dos sandboxes mostraron valores distintos: en QA aparece 'New' y en UAT
 * aparece 'No contactado'. Eso es deriva de configuracion entre ambientes.
 *
 * Solo lectura.
 */

Organization laOrg = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + laOrg.Name + ' | ' + laOrg.Id
    + ' | instancia=' + laOrg.InstanceName + ' | sandbox=' + laOrg.IsSandbox);

System.debug('===================================================');
System.debug('1. QUE VALOR DE Status ES EL DE CONVERTIDO');
System.debug('===================================================');
System.debug('   LeadStatus.IsConverted marca cual de los valores significa');
System.debug('   convertido para la plataforma. Puede haber mas de uno.');
for (LeadStatus ls : [SELECT MasterLabel, ApiName, IsConverted, IsDefault, SortOrder
                      FROM LeadStatus ORDER BY SortOrder]) {
    System.debug('   ' + ls.MasterLabel + '  (' + ls.ApiName + ')'
        + ' | esDeConversion=' + ls.IsConverted
        + ' | pordefecto=' + ls.IsDefault);
}

System.debug('===================================================');
System.debug('2. LOS VALORES ACTIVOS DE LA PICKLIST, PARA COMPARAR ORGS');
System.debug('===================================================');
for (Schema.PicklistEntry pe :
        Lead.Status.getDescribe().getPicklistValues()) {
    if (!pe.isActive()) { continue; }
    System.debug('   ' + pe.getValue() + '  (label: ' + pe.getLabel() + ')');
}
System.debug('   Comparar esta lista con la de la otra org. Si difieren, hay');
System.debug('   deriva de configuracion y los reportes no son comparables.');

System.debug('===================================================');
System.debug('3. LEADS EN ESTADO DE CONVERSION SIN ESTAR CONVERTIDOS');
System.debug('===================================================');
Set<String> estadosDeConversion = new Set<String>();
for (LeadStatus ls : [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true]) {
    estadosDeConversion.add(ls.MasterLabel);
}
System.debug('   Estados que cuentan como conversion: ' + estadosDeConversion);

if (estadosDeConversion.isEmpty()) {
    System.debug('   Ninguno marcado. Entonces "Convertido" es un valor comun y');
    System.debug('   la plataforma no lo reconoce: hay dos nociones de convertido,');
    System.debug('   la real y la que el equipo escribe a mano. Eso hay que unificar.');
} else {
    List<Lead> huerfanos = [SELECT Id, Name, Company, Status, IsConverted,
                                   RecordType.DeveloperName, Owner.Name,
                                   CreatedDate, LastModifiedDate, LastModifiedBy.Name
                            FROM Lead
                            WHERE Status IN :estadosDeConversion AND IsConverted = false
                            ORDER BY LastModifiedDate DESC
                            LIMIT 200];
    System.debug('   Encontrados: ' + huerfanos.size());
    for (Lead l : huerfanos) {
        System.debug('   ' + l.Id + ' | ' + l.Name + ' | ' + l.Company
            + ' | estado=' + l.Status
            + ' | rt=' + (l.RecordType == null ? 'SIN RECORD TYPE' : l.RecordType.DeveloperName)
            + ' | dueno=' + l.Owner.Name);
        System.debug('        creado=' + l.CreatedDate
            + ' | ultima modificacion=' + l.LastModifiedDate
            + ' por ' + l.LastModifiedBy.Name);
    }
    System.debug('   Quien aparece en "ultima modificacion" dice si fue una');
    System.debug('   persona o una automatizacion la que escribio el estado.');
}

System.debug('===================================================');
System.debug('4. LEADS SIN RECORD TYPE');
System.debug('===================================================');
Integer sinRt = [SELECT COUNT() FROM Lead WHERE RecordTypeId = null];
Integer todos = [SELECT COUNT() FROM Lead];
System.debug('   ' + sinRt + ' de ' + todos + ' leads sin Record Type');
for (AggregateResult ar : [SELECT CreatedBy.Name n, COUNT(Id) q
                           FROM Lead WHERE RecordTypeId = null
                           GROUP BY CreatedBy.Name ORDER BY COUNT(Id) DESC LIMIT 10]) {
    System.debug('   creados por ' + ar.get('n') + ' : ' + ar.get('q'));
}
System.debug('   Si se concentran en un usuario de integracion, el que crea el');
System.debug('   lead no esta enviando Record Type y toma el del perfil por');
System.debug('   defecto, que puede no existir. Ahi se arregla, no a mano.');

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
