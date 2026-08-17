// Agenda do veiculo demo, parte 2: a unidade demo e Asset ou so Vehicle?
//
// O padrao do Automotive e: Asset vira ServiceResource no ServiceTerritory da
// sucursal, e assim o veiculo fica agendavel. Nossos flows mexem em Vehicle.
// Se as unidades demo existem so como Vehicle, a nativa nao se aplica sem antes
// criar os Asset. Solo lectura.

Map<String, Schema.SObjectType> g = Schema.getGlobalDescribe();

System.debug('=== 1. Asset existe e liga com Vehicle ===');
if (!g.containsKey('asset')) {
    System.debug('   Asset NAO existe. A nativa nao se aplica.');
} else {
    Map<String, Schema.SObjectField> af = Asset.SObjectType.getDescribe().fields.getMap();
    System.debug('   Asset.VehicleId: ' + (af.containsKey('vehicleid') ? 'existe' : 'NAO existe'));
    System.debug('   assets: ' + [SELECT COUNT() FROM Asset]);
    try {
        for (AggregateResult a : Database.query(
                'SELECT RecordType.DeveloperName rt, COUNT(Id) q FROM Asset GROUP BY RecordType.DeveloperName')) {
            System.debug('   Asset RT ' + a.get('rt') + ' | ' + a.get('q'));
        }
        System.debug('   A documentacao pede dois RT: Vehicles e Parts & Accessories.');
    } catch (Exception e) { System.debug('   ' + e.getMessage()); }
    try {
        Integer comVeh = Database.countQuery('SELECT COUNT() FROM Asset WHERE VehicleId != null');
        System.debug('   assets ligados a um Vehicle: ' + comVeh);
    } catch (Exception e) { System.debug('   VehicleId: ' + e.getMessage()); }
}

System.debug('=== 2. O veiculo ja e recurso agendavel ===');
try {
    for (AggregateResult a : Database.query(
            'SELECT ResourceType t, COUNT(Id) q FROM ServiceResource GROUP BY ResourceType')) {
        System.debug('   ServiceResource tipo ' + a.get('t') + ' | ' + a.get('q'));
    }
    for (SObject r : Database.query(
            'SELECT Name, ResourceType, IsActive FROM ServiceResource'
            + ' WHERE ResourceType = \'A\' OR ResourceType = \'Asset\' LIMIT 10')) {
        System.debug('   recurso de ativo: ' + r.get('Name') + ' | ativo=' + r.get('IsActive'));
    }
    System.debug('   Sem recurso do tipo Asset, nenhum veiculo e agendavel.');
} catch (Exception e) { System.debug('   ServiceResource: ' + e.getMessage()); }

System.debug('=== 3. O work type group de test drive ===');
try {
    for (SObject w : Database.query('SELECT Name FROM WorkTypeGroup LIMIT 20')) {
        System.debug('   WorkTypeGroup: ' + w.get('Name'));
    }
    for (SObject w : Database.query('SELECT Name, DurationInMinutes FROM WorkType LIMIT 20')) {
        System.debug('   WorkType: ' + w.get('Name') + ' | ' + w.get('DurationInMinutes') + ' min');
    }
} catch (Exception e) { System.debug('   ' + e.getMessage()); }

System.debug('=== 4. Os territorios, que sao as sucursais ===');
try {
    for (SObject t : Database.query(
            'SELECT Name, IsActive, ParentTerritoryId FROM ServiceTerritory ORDER BY Name LIMIT 30')) {
        System.debug('   ' + t.get('Name') + ' | ativo=' + t.get('IsActive')
            + (t.get('ParentTerritoryId') == null ? ' | RAIZ' : ''));
    }
} catch (Exception e) { System.debug('   ServiceTerritory: ' + e.getMessage()); }

System.debug('=== 5. O QUE DECIDE O TAMANHO DA HISTORIA ===');
System.debug('   Se ja ha Asset com RT de veiculo E ServiceResource do tipo Asset,');
System.debug('   a agenda e configuracao: calendario de objeto sobre');
System.debug('   ServiceAppointment mais um campo formula como rotulo.');
System.debug('   Se as unidades demo so existem como Vehicle, antes disso ha uma');
System.debug('   carga de Asset e a amarracao como recurso, e a historia cresce.');
