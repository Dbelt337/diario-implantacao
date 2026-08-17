// HU-024 parte 1: etapas y campo de motivo, en Repuestos y PA. Solo lectura.
// Version corta: el Developer Console manda el codigo en la URL y un script
// largo devuelve HTTP 414 URI Too Long. Correr esta y despues la parte 2.

Id rt = null;
for (Schema.RecordTypeInfo ri : Opportunity.SObjectType.getDescribe().getRecordTypeInfos()) {
    if (ri.isMaster()) { continue; }
    System.debug('RT ' + ri.getDeveloperName() + ' | act=' + ri.isActive()
        + ' | disp=' + ri.isAvailable());
    if (ri.getDeveloperName() == 'GQOpportunitiesRepuestosPA') { rt = ri.getRecordTypeId(); }
}
if (rt == null) { System.debug('SIN RT GQOpportunitiesRepuestosPA'); return; }

System.debug('--- ETAPAS DE LA ORG ---');
Set<String> perdidas = new Set<String>();
for (OpportunityStage s : [SELECT MasterLabel, IsActive, IsClosed, IsWon,
                                  DefaultProbability, ForecastCategoryName
                           FROM OpportunityStage ORDER BY SortOrder NULLS LAST]) {
    System.debug(s.MasterLabel + ' | act=' + s.IsActive + ' | cerr=' + s.IsClosed
        + ' | gan=' + s.IsWon + ' | prob=' + s.DefaultProbability
        + ' | fc=' + s.ForecastCategoryName);
    if (s.IsClosed && !s.IsWon) { perdidas.add(s.MasterLabel); }
}
System.debug('ETAPAS DE PERDIDA: ' + perdidas);

System.debug('--- CAMPO DE MOTIVO ---');
List<String> cs = new List<String>();
for (Schema.SObjectField f : Opportunity.SObjectType.getDescribe().fields.getMap().values()) {
    Schema.DescribeFieldResult d = f.getDescribe();
    String t = (d.getName() + ' ' + d.getLabel()).toLowerCase();
    if (!(t.contains('loss') || t.contains('lost') || t.contains('perdid')
          || t.contains('motiv') || t.contains('reason') || t.contains('cierre'))) { continue; }
    cs.add(d.getName());
    System.debug(d.getName() + ' | ' + d.getLabel() + ' | tipo=' + d.getType()
        + ' | custom=' + d.isCustom() + ' | restr=' + d.isRestrictedPicklist()
        + ' | dep=' + d.isDependentPicklist() + ' | oblig=' + !d.isNillable());
    if (d.isDependentPicklist() && d.getController() != null) {
        System.debug('   CONTROLADA POR ' + d.getController().getDescribe().getName());
    }
    for (Schema.PicklistEntry pe : d.getPicklistValues()) {
        System.debug('   ' + (pe.isActive() ? 'ACT ' : 'INACT ') + pe.getValue()
            + ' | lbl=' + pe.getLabel());
    }
}
if (cs.isEmpty()) { System.debug('NINGUN campo de motivo en Opportunity'); }

System.debug('--- USO REAL EN REPUESTOS ---');
System.debug('total=' + [SELECT COUNT() FROM Opportunity WHERE RecordTypeId = :rt]);
for (AggregateResult a : [SELECT StageName s, COUNT(Id) q FROM Opportunity
                          WHERE RecordTypeId = :rt GROUP BY StageName
                          ORDER BY COUNT(Id) DESC]) {
    System.debug(a.get('s') + ' | ' + a.get('q'));
}

if (!perdidas.isEmpty()) {
    List<String> lp = new List<String>(perdidas);
    Integer tp = Database.countQuery('SELECT COUNT() FROM Opportunity WHERE RecordTypeId = \''
        + rt + '\' AND StageName IN (\'' + String.join(lp, '\',\'') + '\')');
    System.debug('--- CERRADAS PERDIDAS: ' + tp + ' ---');
    for (String c : cs) {
        try {
            Integer sin = Database.countQuery('SELECT COUNT() FROM Opportunity WHERE RecordTypeId = \''
                + rt + '\' AND StageName IN (\'' + String.join(lp, '\',\'') + '\') AND ' + c + ' = null');
            System.debug(c + ' VACIO en ' + sin + ' de ' + tp);
            for (AggregateResult a : Database.query('SELECT ' + c + ' v, COUNT(Id) q FROM Opportunity'
                    + ' WHERE RecordTypeId = \'' + rt + '\' AND StageName IN (\''
                    + String.join(lp, '\',\'') + '\') GROUP BY ' + c + ' ORDER BY COUNT(Id) DESC')) {
                System.debug('   EN USO ' + a.get('v') + ' | ' + a.get('q'));
            }
        } catch (Exception e) { System.debug(c + ' no agrupa: ' + e.getMessage()); }
    }
}
System.debug('FIN PARTE 1');
