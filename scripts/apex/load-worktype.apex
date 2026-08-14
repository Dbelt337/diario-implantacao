/*
 * Carga dos WorkTypes de produção numa sandbox.
 * Execute Anonymous — Developer Console ou Salesforce Inspector.
 *
 * GERADO a partir de data/worktype/WorkType.csv (49 registros, produção 13/08/2026).
 * Não editar à mão: regenerar a partir do CSV.
 *
 * Deixe DRY_RUN = true na primeira execução. Ele valida os valores de picklist
 * contra o describe da org sem gravar nada — que é justamente onde a carga
 * costuma falhar em silêncio: picklist ausente faz ServiceTypeKey__c sair
 * diferente e a integração continua quebrada mesmo com os 49 registros lá.
 *
 * Campos fora da carga de propósito:
 *   ServiceTypeKey__c, SkillType__c  fórmulas, calculadas sozinhas
 *   DurationInMinutes                derivado pela plataforma
 *   OwnerId                          ids de produção não existem na sandbox
 */

Boolean DRY_RUN = true;   // <<< mude para false para gravar
Boolean FORCE   = false;  // ignora a trava de registros já existentes

// ---------------------------------------------------------------- trava de org
Organization org = [SELECT Name, IsSandbox, InstanceName FROM Organization LIMIT 1];
System.debug('Org: ' + org.Name + ' | instância ' + org.InstanceName + ' | IsSandbox=' + org.IsSandbox);
System.assert(org.IsSandbox, 'ABORTADO: "' + org.Name + '" nao e sandbox. Recusando a carga.');

// ------------------------------------------------------------------- registros
// Name|DurationType|EstimatedDuration|MacroCategory|Product|SubCategory|Criticality|RootCase|Skill
List<String> rows = new List<String>{
        'Instalação|Hours|2|Instalacao|||||',
        'Reparo - Banda Larga - Crítica|Hours|2|Reparo|BandaLarga||Critica||',
        'Reparo - Banda Larga - Alta|Hours|2|Reparo|BandaLarga||Alta||',
        'Manutenção - Banda Larga - Baixa|Hours|2|Manutencao|BandaLarga||Baixa||',
        'Manutenção - Banda Larga - Média|Hours|2|Manutencao|BandaLarga||Media||',
        'Preventiva - Banda Larga - Média|Hours|2|Preventiva|BandaLarga||Media||',
        'Visita Técnica|Hours|1|Preventiva|BandaLarga||Baixa||',
        'Reparo - TV - Alta|Hours|2|Reparo|TV||Alta||',
        'Reparo - TV - Média|Hours|2|Reparo|TV||Media||',
        'Reparo - Telefone Fixa - Crítica|Hours|3|Reparo|TelefoniaFixa||Critica||',
        'Reparo - Telefone Fixa - Alta|Hours|2|Reparo|TelefoniaFixa||Alta||',
        'Reparo - Câmera - Alta|Hours|2|Reparo|Camera||Alta||',
        'Reparo - Câmera - Média|Hours|2|Reparo|Camera||Media||',
        'Reparo - CFTV - Alta|Hours|2|Reparo|CFTV||Alta||',
        'Reparo Corporativo - Dados - Crítica|Hours|2|ReparoCorporativo|Dados||Critica||',
        'Reparo Corporativo - Dados - Alta|Hours|2|ReparoCorporativo|Dados||Alta||',
        'Manutenção Corporativo - Dados - Alta|Hours|2|ManutencaoCorporativo|Dados||Alta||',
        'Manutenção Corporativo - Dados - Crítica|Hours|2|ManutencaoCorporativo|Dados||Critica||',
        'Reparo Corporativo -BandaLarga - Critica|Hours|2|ReparoCorporativo|BandaLarga|SemSinal|Critica|LOS (00)|',
        'Reparo Corporativo -BandaLarga - Alta|Hours|2|ReparoCorporativo|BandaLarga|SemSinal|Alta|LOS (00)|',
        'Manutenção Corporativo -BandaLarga - Critica|Hours|2|ManutencaoCorporativo|BandaLarga|SemSinal|Critica|LOS (00)|',
        'Manutenção Corporativo -BandaLarga - Alta|Hours|2|ManutencaoCorporativo|BandaLarga|SemSinal|Alta|LOS (00)|',
        'Reparo Corporativo -TV - Critica|Hours|2|ReparoCorporativo|TV|SemSinal|Critica|LOS (00)|',
        'Reparo Corporativo -TV - Alta|Hours|2|ReparoCorporativo|TV|SemSinal|Alta|LOS (00)|',
        'Manutenção Corporativo -TV - Critica|Hours|2|ManutencaoCorporativo|TV|SemSinal|Critica|LOS (00)|',
        'Manutenção Corporativo -TV - Alta|Hours|2|ManutencaoCorporativo|TV|SemSinal|Alta|LOS (00)|',
        'Reparo Corporativo -TelefoniaFixa - Critica|Hours|2|ReparoCorporativo|TelefoniaFixa|SemSinal|Critica|LOS (00)|',
        'Reparo Corporativo -TelefoniaFixa - Alta|Hours|2|ReparoCorporativo|TelefoniaFixa|SemSinal|Alta|LOS (00)|',
        'Manutenção Corporativo -TelefoniaFixa - Critica|Hours|2|ManutencaoCorporativo|TelefoniaFixa|SemSinal|Critica|LOS (00)|',
        'Manutenção Corporativo -TelefoniaFixa - Alta|Hours|2|ManutencaoCorporativo|TelefoniaFixa|SemSinal|Alta|LOS (00)|',
        'Reparo Corporativo -Camera - Critica|Hours|2|ReparoCorporativo|Camera|SemSinal|Critica|LOS (00)|',
        'Reparo Corporativo -Camera - Alta|Hours|2|ReparoCorporativo|Camera|SemSinal|Alta|LOS (00)|',
        'Manutenção Corporativo -Camera - Critica|Hours|2|ManutencaoCorporativo|Camera|SemSinal|Critica|LOS (00)|',
        'Manutenção Corporativo -Camera - Alta|Hours|2|ManutencaoCorporativo|Camera|SemSinal|Alta|LOS (00)|',
        'Reparo Corporativo -CFTV - Critica|Hours|2|ReparoCorporativo|CFTV|SemSinal|Critica|LOS (00)|',
        'Reparo Corporativo -CFTV - Alta|Hours|2|ReparoCorporativo|CFTV|SemSinal|Alta|LOS (00)|',
        'Manutenção Corporativo -CFTV - Critica|Hours|2|ManutencaoCorporativo|CFTV|SemSinal|Critica|LOS (00)|',
        'Manutenção Corporativo -CFTV - Alta|Hours|2|ManutencaoCorporativo|CFTV|SemSinal|Alta|LOS (00)|',
        'Atendimento N3|Hours|2|Instalacao||SemSinal|Critica|LOS (00)|',
        'Reparo - TV - Alta - 1 Hora|Hours|1|Reparo|TV|SemSinal|Alta|LOS (00)|',
        'Reparo - TV - Média - 1 Hora|Hours|1|Reparo|TV|SemSinal|Media|LOS (00)|',
        'Reparo - Telefone Fixa - Crítica - 1 Hora|Hours|1|Reparo|TelefoniaFixa|SemSinal|Critica|LOS (00)|',
        'Reparo - Câmera - Média - 1 Hora|Hours|1|Reparo|Camera|SemSinal|Media|LOS (00)|',
        'Reparo - CFTV - Alta - 1 Hora|Hours|1|Reparo|CFTV|SemSinal|Alta|LOS (00)|',
        'Reparo - Telefonia - Alta - 2 Horas|Hours|2|Reparo|Telefonia||Alta||',
        'Serviço - Banda Larga - Aferição Velocidade|Hours|1|Servico|BandaLarga||Alta|Atividade de Verificação (28)|Indoor',
        'Serviço - Câmera - Alta|Hours|1|Servico|Camera||Alta|LOS (00)|Indoor',
        'Preventiva - Banda Larga - Média|Hours|1|Preventiva|BandaLarga||Media||',
        'Preventiva - Banda Larga - Alta|Hours|1|Preventiva|BandaLarga||Alta||'
};

// -------------------------------------------------- valores de picklist da org
Map<String, Set<String>> valid = new Map<String, Set<String>>();
Map<String, Schema.SObjectField> pick = new Map<String, Schema.SObjectField>{
    'MacroCategory__c' => WorkType.MacroCategory__c,
    'Product__c'       => WorkType.Product__c,
    'SubCategory__c'   => WorkType.SubCategory__c,
    'Criticality__c'   => WorkType.Criticality__c,
    'RootCase__c'      => WorkType.RootCase__c,
    'Skill__c'         => WorkType.Skill__c
};
for (String fld : pick.keySet()) {
    Set<String> vals = new Set<String>();
    for (Schema.PicklistEntry pe : pick.get(fld).getDescribe().getPicklistValues()) {
        if (pe.isActive()) vals.add(pe.getValue());
    }
    valid.put(fld, vals);
}

// ------------------------------------------------------- montagem e validação
List<WorkType> toLoad = new List<WorkType>();
List<String> problems = new List<String>();
Map<String, List<String>> byKey = new Map<String, List<String>>();

for (String row : rows) {
    List<String> p = row.split('\\|', -1);   // -1 preserva campos vazios no fim
    System.assert(p.size() == 9, 'Linha malformada: ' + row);

    String nm = p[0], macro = p[3], prod = p[4], sub = p[5], crit = p[6], root = p[7], skill = p[8];

    Map<String, String> vals = new Map<String, String>{
        'MacroCategory__c' => macro, 'Product__c'  => prod,  'SubCategory__c' => sub,
        'Criticality__c'   => crit,  'RootCase__c' => root,  'Skill__c'       => skill
    };
    for (String fld : vals.keySet()) {
        String v = vals.get(fld);
        if (String.isNotBlank(v) && !valid.get(fld).contains(v)) {
            problems.add(nm + ': valor "' + v + '" ausente na picklist ' + fld);
        }
    }

    String key = macro + prod + sub + crit;
    if (!byKey.containsKey(key)) byKey.put(key, new List<String>());
    byKey.get(key).add(nm);

    toLoad.add(new WorkType(
        Name                        = nm,
        DurationType                = p[1],
        EstimatedDuration           = Decimal.valueOf(p[2]),
        ShouldAutoCreateSvcAppt     = false,
        FSL__Exact_Appointments__c  = false,
        MacroCategory__c            = String.isBlank(macro) ? null : macro,
        Product__c                  = String.isBlank(prod)  ? null : prod,
        SubCategory__c              = String.isBlank(sub)   ? null : sub,
        Criticality__c              = String.isBlank(crit)  ? null : crit,
        RootCase__c                 = String.isBlank(root)  ? null : root,
        Skill__c                    = String.isBlank(skill) ? null : skill
    ));
}

for (String k : byKey.keySet()) {
    if (byKey.get(k).size() > 1) {
        System.debug(LoggingLevel.WARN,
            'COLISAO de ServiceTypeKey__c "' + k + '": ' + byKey.get(k)
            + ' -- a composite usa records[0], a escolha fica nao deterministica.');
    }
}

if (!problems.isEmpty()) {
    for (String pr : problems) System.debug(LoggingLevel.ERROR, pr);
    System.assert(false, 'ABORTADO: ' + problems.size()
        + ' valor(es) de picklist ausente(s) nesta org. Faca o deploy dos metadados antes da carga.');
}
System.debug('Picklists OK. Registros preparados: ' + toLoad.size());

// ------------------------------------------------------------------ existentes
Integer existing = [SELECT COUNT() FROM WorkType];
System.debug('WorkTypes ja existentes na org: ' + existing);
if (existing > 0 && !FORCE) {
    System.assert(false, 'ABORTADO: a org ja tem ' + existing
        + ' WorkType(s); carregar agora criaria duplicatas. Use FORCE = true se for intencional.');
}

if (DRY_RUN) {
    System.debug('DRY_RUN = true -- nada foi gravado. Mude para false para carregar.');
    return;
}

// ----------------------------------------------------------------------- carga
insert toLoad;
System.debug('Inseridos: ' + toLoad.size());

// ------------------------------------------------------------------- validação
Integer blanks = 0;
for (WorkType wt : [SELECT Name, ServiceTypeKey__c FROM WorkType]) {
    if (String.isBlank(wt.ServiceTypeKey__c)) {
        blanks++;
        System.debug(LoggingLevel.ERROR, 'ServiceTypeKey__c vazia em: ' + wt.Name);
    }
}
if (blanks > 0) {
    System.debug(LoggingLevel.ERROR, blanks
        + ' registro(s) com chave vazia -- a integracao NAO vai encontra-los.');
} else {
    System.debug('OK: todas as ' + toLoad.size() + ' chaves ServiceTypeKey__c foram geradas.');
}
