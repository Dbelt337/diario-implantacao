// 10 - DUMP das works do modelo de contas (executar quando quiser ler o conteudo completo).
// Somente SELECT + System.debug: NAO grava nada, pode rodar quantas vezes quiser.
//
// Como usar:
// 1. Execute Anonymous com "Open Log" marcado.
// 2. No log, filtre por USER_DEBUG (ou busque por "DUMP|").
// 3. Me mande o log inteiro (ou so as linhas DUMP|).
//
// Traz o Details inteiro de cada work em blocos de 250 caracteres, na ordem,
// mais os comentarios (agf__ADM_Comment__c) se houver.

List<String> alvos = new List<String>{ 'W-000117', 'W-000103' };

for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c, agf__Status__c, agf__Details__c,
                                  agf__Epic__r.Name, agf__Scrum_Team__r.Name,
                                  (SELECT CreatedDate, CreatedBy.Name, agf__Body__c
                                   FROM agf__Comment__r ORDER BY CreatedDate)
                           FROM agf__ADM_Work__c
                           WHERE Name IN :alvos
                           ORDER BY Name]) {
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    System.debug('DUMP| ===== ' + w.Name + ' | ' + w.agf__Subject__c + ' =====');
    System.debug('DUMP| ' + w.Name + ' | epic=' + w.agf__Epic__r.Name
        + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | status=' + w.agf__Status__c
        + ' | details=' + det.length() + ' chars'
        + ' | notas=' + det.countMatches('--- ')
        + ' | comentarios=' + w.agf__Comment__r.size());
    Integer bloco = 0;
    for (Integer i = 0; i < det.length(); i += 250) {
        bloco++;
        System.debug('DUMP| ' + w.Name + ' | ' + String.valueOf(bloco).leftPad(3, '0') + ' | '
            + det.substring(i, Math.min(i + 250, det.length())));
    }
    for (agf__ADM_Comment__c c : w.agf__Comment__r) {
        String corpo = c.agf__Body__c == null ? '' : c.agf__Body__c;
        System.debug('DUMP| ' + w.Name + ' | COMENTARIO ' + c.CreatedDate.format('dd/MM HH:mm')
            + ' ' + c.CreatedBy.Name + ' | ' + corpo.left(250));
    }
}
System.debug('DUMP| FIM');
