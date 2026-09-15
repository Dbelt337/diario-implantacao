// 22 - Exclusao das works antigas de catalogo e B2C da SysMap: W-000029 a W-000040 (historias B2C de 27/07, Bruno) e
// W-000041 a W-000050 (works de catalogo de 29-30/07, Diego e Priscila; 041 = revisao 10/09 da EPC-04, superada pela v3),
// decisao do Diego em 15/09. DUAS FASES, igual ao 14. Fase 1 (EXCLUIR = false): so lista o que seria apagado, com criterios,
// tasks e temas filhos. Fase 2 (EXCLUIR = true): apaga (Lixeira, 15 dias). Travas: numero na faixa, time SysMap, status New e
// nenhuma work fora da lista esperada; se qualquer trava falhar em uma work, ela fica de fora e o log avisa. Filtre por DEL22|.
Boolean EXCLUIR = true;   // fase 2 autorizada pelo Diego em 15/09 (inclusive as 141 tasks de W-000041 a 050)
Set<String> esperadas = new Set<String>();
for (Integer i = 29; i <= 50; i++) esperadas.add('W-0000' + i);

List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Status__c, agf__Scrum_Team__r.Name, agf__Epic__r.Name, agf__Sprint__r.Name,
                                    agf__Assignee__r.Name, CreatedBy.Name, CreatedDate, agf__Details__c
                             FROM agf__ADM_Work__c WHERE Name IN :esperadas ORDER BY Name];
List<agf__ADM_Work__c> paraExcluir = new List<agf__ADM_Work__c>();
Set<String> achadas = new Set<String>();
for (agf__ADM_Work__c w : ws) {
    achadas.add(w.Name);
    Boolean timeOk = w.agf__Scrum_Team__r.Name == 'SysMap';
    Boolean statusOk = w.agf__Status__c == 'New';
    Integer nCrit = [SELECT COUNT() FROM agf__ADM_Acceptance_Criterion__c WHERE agf__Work__c = :w.Id];
    Integer nTask = 0, nTema = 0;
    try { nTask = [SELECT COUNT() FROM agf__ADM_Task__c WHERE agf__Work__c = :w.Id]; } catch (Exception e) { nTask = -1; }
    try { nTema = [SELECT COUNT() FROM agf__ADM_Theme_Assignment__c WHERE agf__Work__c = :w.Id]; } catch (Exception e) { nTema = -1; }
    Boolean elegivel = timeOk && statusOk;
    System.debug('DEL22| ' + w.Name + ' | ' + (elegivel ? 'ELEGIVEL' : 'TRAVA (time=' + w.agf__Scrum_Team__r.Name + ', status=' + w.agf__Status__c + ') - NAO EXCLUIR')
        + ' | epic=' + w.agf__Epic__r.Name + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name
        + ' | criada ' + w.CreatedDate.format('dd/MM/yy') + ' por ' + w.CreatedBy.Name
        + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()) + ' | criterios=' + nCrit + ' | tasks=' + nTask + ' | temas=' + nTema
        + ' | ' + w.agf__Subject__c);
    if (elegivel) paraExcluir.add(w);
}
for (String n : esperadas) if (!achadas.contains(n)) System.debug('DEL22| ' + n + ' | NAO ENCONTRADA (ja excluida ou nunca existiu)');

if (!EXCLUIR) {
    System.debug('DEL22| FASE 1 concluida: nada excluido. ' + paraExcluir.size() + ' de ' + ws.size() + ' work(s) elegivel(is). Confira a lista e rode com EXCLUIR = true.');
} else {
    // tasks das works elegiveis: apagadas explicitamente antes (o relacionamento pode ser lookup, o que travaria a exclusao da work)
    List<agf__ADM_Task__c> tasks = [SELECT Id FROM agf__ADM_Task__c WHERE agf__Work__c IN :paraExcluir];
    if (!tasks.isEmpty()) delete tasks;
    System.debug('DEL22| FASE 2: ' + tasks.size() + ' task(s) excluida(s).');
    delete paraExcluir;   // criterios de aceite (master-detail) vao junto; tudo para a Lixeira, restauravel por 15 dias
    System.debug('DEL22| FASE 2: ' + paraExcluir.size() + ' work(s) excluida(s) e enviada(s) a Lixeira.');
    for (agf__ADM_Work__c w : paraExcluir) System.debug('DEL22| EXCLUIDA | ' + w.Name + ' | ' + w.agf__Subject__c);
    System.debug('DEL22| restantes na faixa W-000029 a W-000050: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE Name IN :esperadas]
        + ' | total de works na org: ' + [SELECT COUNT() FROM agf__ADM_Work__c]);
}
