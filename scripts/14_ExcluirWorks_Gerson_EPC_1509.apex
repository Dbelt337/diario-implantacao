// 14 - Exclusao das duas works de EPC criadas pelo Gerson em 15/09 10:27 (W-000138 e W-000139), autorizada por ele no chat
// ("pode excluir ... desde que fique na sprint e alocada a Squad certa, fique a vontade para complementar/consolidar").
// DUAS FASES. Fase 1 (EXCLUIR = false): so SELECT + System.debug: despeja Details, criterios, tasks, comentarios, sprint e
// temas das duas works, para consolidar o conteudo nas works 51/52/55 ANTES de apagar. Fase 2 (EXCLUIR = true): apaga.
// Travas: so apaga se Name E inicio do Subject baterem com o esperado; a exclusao vai para a Lixeira (15 dias para restaurar).
// Filtre o log por DEL14|.
Boolean EXCLUIR = false;

Map<String, String> alvo = new Map<String, String>{
    'W-000138' => 'EPC - Ajustar US 51/52/55 em US filhas por fam',
    'W-000139' => 'EPC - Consolidar estrutura de conectividade e template de produto'
};

List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Status__c, agf__Epic__r.Name,
                                    agf__Scrum_Team__r.Name, agf__Sprint__r.Name, agf__Assignee__r.Name, agf__Product_Tag__r.Name,
                                    CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate
                             FROM agf__ADM_Work__c WHERE Name IN :alvo.keySet() ORDER BY Name];
List<agf__ADM_Work__c> paraExcluir = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : ws) {
    Boolean bate = w.agf__Subject__c != null && w.agf__Subject__c.startsWith(alvo.get(w.Name));
    System.debug('DEL14| ' + w.Name + ' | ' + (bate ? 'SUBJECT CONFERE' : 'SUBJECT DIFERENTE - NAO EXCLUIR') + ' | ' + w.agf__Subject__c);
    System.debug('DEL14| ' + w.Name + ' | status=' + w.agf__Status__c + ' | epic=' + w.agf__Epic__r.Name + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | tag=' + w.agf__Product_Tag__r.Name
        + ' | criada por ' + w.CreatedBy.Name + ' em ' + w.CreatedDate.format('dd/MM HH:mm')
        + ' | alterada por ' + w.LastModifiedBy.Name + ' em ' + w.LastModifiedDate.format('dd/MM HH:mm'));
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    System.debug('DEL14| ' + w.Name + ' | details=' + det.length() + ' chars');
    for (Integer i = 0; i < det.length(); i += 250) {
        System.debug('DUMP14| ' + w.Name + ' | ' + det.substring(i, Math.min(i + 250, det.length())));
    }
    for (agf__ADM_Acceptance_Criterion__c c : [SELECT Name, agf__Status__c, agf__Description__c FROM agf__ADM_Acceptance_Criterion__c WHERE agf__Work__c = :w.Id]) {
        System.debug('DEL14| ' + w.Name + ' | criterio | ' + c.Name + ' | ' + c.agf__Status__c + ' | ' + c.agf__Description__c);
    }
    for (agf__ADM_Task__c t : [SELECT Subject__c, agf__Status__c, agf__Assigned_To__r.Name FROM agf__ADM_Task__c WHERE agf__Work__c = :w.Id]) {
        System.debug('DEL14| ' + w.Name + ' | task | ' + t.Subject__c + ' | ' + t.agf__Status__c + ' | ' + t.agf__Assigned_To__r.Name);
    }
    for (agf__ADM_Comment__c c : [SELECT CreatedBy.Name, CreatedDate, agf__Comment__c FROM agf__ADM_Comment__c WHERE agf__Work__c = :w.Id ORDER BY CreatedDate]) {
        System.debug('DEL14| ' + w.Name + ' | comentario | ' + c.CreatedBy.Name + ' ' + c.CreatedDate.format('dd/MM HH:mm') + ' | '
            + (c.agf__Comment__c == null ? '' : c.agf__Comment__c.left(300)));
    }
    for (agf__ADM_Theme_Assignment__c ta : [SELECT agf__Theme__r.Name FROM agf__ADM_Theme_Assignment__c WHERE agf__Work__c = :w.Id]) {
        System.debug('DEL14| ' + w.Name + ' | tema | ' + ta.agf__Theme__r.Name);
    }
    if (bate) paraExcluir.add(w);
}
for (String n : alvo.keySet()) {
    Boolean achou = false;
    for (agf__ADM_Work__c w : ws) if (w.Name == n) achou = true;
    if (!achou) System.debug('DEL14| ' + n + ' | NAO ENCONTRADA (ja excluida?)');
}

if (!EXCLUIR) {
    System.debug('DEL14| FASE 1 concluida: nada excluido. ' + paraExcluir.size() + ' work(s) elegivel(is). Consolide o conteudo e rode com EXCLUIR = true.');
} else {
    // filhos (criterios, tasks, comentarios, temas) sao master-detail/lookup do pacote: conferir no log da fase 1 se ha algo a preservar
    delete paraExcluir;   // vai para a Lixeira; restaurar com undelete se necessario
    System.debug('DEL14| FASE 2: ' + paraExcluir.size() + ' work(s) excluida(s) e enviada(s) a Lixeira.');
    for (agf__ADM_Work__c w : paraExcluir) System.debug('DEL14| EXCLUIDA | ' + w.Name + ' | ' + w.agf__Subject__c);
    System.debug('DEL14| restantes com esses nomes: ' + [SELECT COUNT() FROM agf__ADM_Work__c WHERE Name IN :alvo.keySet()]);
}
