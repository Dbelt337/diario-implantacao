/**
 * Como estan asignadas las habilidades de marca para el ruteo de leads.
 *
 * Responde tres cosas que se confunden entre si:
 *   a) por donde estan asignadas las habilidades, Service Resource o usuario;
 *   b) que usuario tiene mas de una marca, o ninguna;
 *   c) si existe el mapeo que conecta el campo del lead con la habilidad,
 *      que es la mitad que suele faltar.
 *
 * Ejecutar en Developer Console, Debug, Open Execute Anonymous Window,
 * con Open Log marcado y Debug Only activado.
 *
 * Correr en la MISMA org de la pantalla. Verificar la primera linea del log.
 */

Organization org = [SELECT Id, Name, InstanceName, IsSandbox FROM Organization LIMIT 1];
System.debug('ORG: ' + org.Name + ' | ' + org.Id
    + ' | instancia=' + org.InstanceName + ' | sandbox=' + org.IsSandbox);

System.debug('===================================================');
System.debug('HABILIDADES DE MARCA Y RUTEO DE LEADS');
System.debug('===================================================');

System.debug('----- 1. HABILIDADES DEFINIDAS EN LA ORG -----');
Map<Id, String> nombrePorSkill = new Map<Id, String>();
try {
    for (Skill s : [SELECT Id, MasterLabel, DeveloperName FROM Skill ORDER BY MasterLabel]) {
        nombrePorSkill.put(s.Id, s.MasterLabel);
        System.debug('   ' + s.MasterLabel + '   (' + s.DeveloperName + ')');
    }
    System.debug('   Total: ' + nombrePorSkill.size());
} catch (Exception e) {
    System.debug('   ERROR leyendo Skill: ' + e.getMessage());
}

System.debug('----- 2. ASIGNACION DIRECTA AL USUARIO (SkillUser) -----');
System.debug('   Es la via que se usa cuando Field Service NO esta activo.');
System.debug('   Si aqui sale cero, la asignacion vive en Service Resource.');
Integer directos = 0;
try {
    for (AggregateResult ar : [SELECT SkillId sk, COUNT(Id) qtd
                               FROM SkillUser GROUP BY SkillId]) {
        directos += (Integer) ar.get('qtd');
        System.debug('   ' + nombrePorSkill.get((Id) ar.get('sk'))
            + ' | usuarios=' + ar.get('qtd'));
    }
    System.debug('   Total asignaciones directas: ' + directos);
} catch (Exception e) {
    System.debug('   SkillUser no consultable aqui => ' + e.getMessage());
}

System.debug('----- 3. SERVICE RESOURCES Y SUS HABILIDADES -----');
System.debug('   Ojo con ResourceType. Para ruteo Omni-Channel el recurso');
System.debug('   representa a un agente, no a un tecnico de campo. Si aqui');
System.debug('   sale Technician para gente de ventas, confirmarlo en Setup.');
Map<Id, ServiceResource> recursos = new Map<Id, ServiceResource>();
try {
    recursos = new Map<Id, ServiceResource>([
        SELECT Id, Name, RelatedRecordId, RelatedRecord.Name, RelatedRecord.IsActive,
               ResourceType, IsActive
        FROM ServiceResource
        ORDER BY Name
        LIMIT 500
    ]);
    System.debug('   Service Resources: ' + recursos.size());
} catch (Exception e) {
    System.debug('   ERROR leyendo ServiceResource: ' + e.getMessage());
}

Map<Id, List<String>> marcasPorRecurso = new Map<Id, List<String>>();
Map<Id, List<String>> otrasPorRecurso = new Map<Id, List<String>>();
try {
    for (ServiceResourceSkill srs : [
            SELECT ServiceResourceId, SkillId, Skill.MasterLabel,
                   SkillLevel, EffectiveStartDate, EffectiveEndDate
            FROM ServiceResourceSkill
            ORDER BY ServiceResourceId, Skill.MasterLabel
            LIMIT 5000]) {
        Boolean vencida = srs.EffectiveEndDate != null
            && srs.EffectiveEndDate < System.now();
        String etiqueta = srs.Skill.MasterLabel + (vencida ? '  [VENCIDA]' : '');
        Map<Id, List<String>> destino =
            srs.Skill.MasterLabel != null
            && srs.Skill.MasterLabel.toLowerCase().startsWith('marca')
            ? marcasPorRecurso : otrasPorRecurso;
        if (!destino.containsKey(srs.ServiceResourceId)) {
            destino.put(srs.ServiceResourceId, new List<String>());
        }
        destino.get(srs.ServiceResourceId).add(etiqueta);
    }
} catch (Exception e) {
    System.debug('   ERROR leyendo ServiceResourceSkill: ' + e.getMessage());
}

System.debug('----- 4. CUANTAS MARCAS TIENE CADA UNO -----');
System.debug('   Esto es lo que se queria validar.');
List<String> sinMarca = new List<String>();
for (ServiceResource sr : recursos.values()) {
    List<String> marcas = marcasPorRecurso.get(sr.Id);
    Integer n = marcas == null ? 0 : marcas.size();
    if (n == 0) {
        sinMarca.add(sr.Name);
        continue;
    }
    System.debug('   ' + sr.Name
        + ' | usuario=' + sr.RelatedRecord.Name
        + ' | tipo=' + sr.ResourceType
        + ' | activo=' + sr.IsActive
        + ' | marcas=' + n);
    if (n > 1) {
        System.debug('        ' + marcas + '   <- mas de una marca');
    } else {
        System.debug('        ' + marcas);
    }
    List<String> otras = otrasPorRecurso.get(sr.Id);
    if (otras != null) { System.debug('        otras habilidades: ' + otras); }
}
if (!sinMarca.isEmpty()) {
    System.debug('   SIN NINGUNA MARCA, no los alcanza el ruteo por habilidad:');
    System.debug('   ' + sinMarca);
}

System.debug('----- 5. USUARIOS ACTIVOS SIN SERVICE RESOURCE -----');
System.debug('   Un vendedor sin recurso no participa del ruteo por habilidad,');
System.debug('   aunque este en la cola.');
Set<Id> conRecurso = new Set<Id>();
for (ServiceResource sr : recursos.values()) { conRecurso.add(sr.RelatedRecordId); }
try {
    Integer sinRecurso = 0;
    for (User u : [SELECT Id, Name, Profile.Name FROM User
                   WHERE IsActive = true AND UserType = 'Standard'
                   ORDER BY Name LIMIT 500]) {
        if (!conRecurso.contains(u.Id)) {
            sinRecurso++;
            if (sinRecurso <= 40) {
                System.debug('   ' + u.Name + ' | ' + u.Profile.Name);
            }
        }
    }
    System.debug('   Total sin Service Resource: ' + sinRecurso);
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('----- 6. LA MITAD QUE SUELE FALTAR: EL MAPEO -----');
System.debug('   Asignar la habilidad al recurso no rutea nada por si solo.');
System.debug('   Hace falta que el trabajo entrante PIDA la habilidad, sea por');
System.debug('   Skill Mapping en Setup, Omni-Channel, o por codigo que arme');
System.debug('   los SkillRequirement al enrutar.');
for (String obj : new List<String>{ 'SkillRequirement', 'PendingServiceRouting' }) {
    try {
        Integer n = Database.countQuery('SELECT COUNT() FROM ' + obj);
        System.debug('   ' + obj + ' => ' + n + ' registros');
    } catch (Exception e) {
        System.debug('   ' + obj + ' => ' + e.getMessage());
    }
}
try {
    for (AggregateResult ar : [SELECT ServiceChannel.MasterLabel canal, COUNT(Id) qtd
                               FROM QueueRoutingConfig___x LIMIT 1]) {
        System.debug('   ' + ar);
    }
} catch (Exception e) {
    System.debug('   Routing configs: revisar en Setup, Omni-Channel, Routing Configurations.');
}

System.debug('----- 7. TERRITORIOS, POR SI EL RUTEO TAMBIEN LOS USA -----');
try {
    for (AggregateResult ar : [SELECT ServiceTerritory.Name terr, COUNT(Id) qtd
                               FROM ServiceTerritoryMember
                               GROUP BY ServiceTerritory.Name
                               ORDER BY ServiceTerritory.Name]) {
        System.debug('   ' + ar.get('terr') + ' | miembros=' + ar.get('qtd'));
    }
} catch (Exception e) {
    System.debug('   ERROR: ' + e.getMessage());
}

System.debug('===================================================');
System.debug('FIN');
System.debug('===================================================');
