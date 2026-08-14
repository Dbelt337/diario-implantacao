/**
 * Flows record-triggered de um objeto, para aplicar o ADR-005.
 *
 * Executar em Developer Console, Debug, Open Execute Anonymous Window,
 * com Open Log marcado e Debug Only ativado.
 *
 * Trocar OBJETO abaixo para rodar em Opportunity ou Account.
 *
 * A Trigger Order nao e exposta de forma confiavel por SOQL, entao a
 * conferencia final e no Setup, Flow Trigger Explorer, que mostra os flows
 * do objeto na ordem real de execucao. Este script serve para montar a lista
 * e nao esquecer nenhum.
 */

String OBJETO = 'Lead';

System.debug('===================================================');
System.debug('FLOWS RECORD-TRIGGERED DE ' + OBJETO);
System.debug('===================================================');

List<FlowDefinitionView> flows = [
    SELECT ApiName, Label, ProcessType, TriggerType, TriggerObjectOrEventLabel
    FROM FlowDefinitionView
    WHERE IsActive = true AND TriggerObjectOrEventLabel = :OBJETO
    ORDER BY TriggerType, Label
    LIMIT 200
];

System.debug('Total: ' + flows.size());
System.debug('   ');

Map<String, Integer> porGatilho = new Map<String, Integer>();
for (FlowDefinitionView f : flows) {
    String g = String.isBlank(f.TriggerType) ? 'sem gatilho' : f.TriggerType;
    porGatilho.put(g, (porGatilho.containsKey(g) ? porGatilho.get(g) : 0) + 1);
    System.debug(g + ' | ' + f.Label);
    System.debug('        apiName=' + f.ApiName);
}

System.debug('   ');
System.debug('----- POR TIPO DE GATILHO -----');
for (String g : porGatilho.keySet()) {
    System.debug('   ' + g + ': ' + porGatilho.get(g));
}
System.debug('   A ordem so importa entre flows do MESMO tipo de gatilho.');
System.debug('   RecordBeforeSave e RecordAfterSave sao filas separadas.');

System.debug('   ');
System.debug('----- RECORD TYPES DO OBJETO, PARA O CRITERIO DE ENTRADA -----');
Schema.SObjectType t = Schema.getGlobalDescribe().get(OBJETO.toLowerCase());
for (Schema.RecordTypeInfo rt : t.getDescribe().getRecordTypeInfos()) {
    if (rt.isMaster()) { continue; }
    System.debug('   ' + rt.getName() + ' | developerName=' + rt.getDeveloperName()
        + ' | disponivel=' + rt.isAvailable());
}
System.debug('   Usar o developerName no criterio de entrada, nunca o Id, '
    + 'porque o Id muda de org para org.');

System.debug('===================================================');
System.debug('FIM');
System.debug('===================================================');
