// 14 - MIGRA os criterios de aceite escritos no CORPO (Details) para a related list Acceptance
// Criteria, nas works que nao tem nenhum registro na related list. Formatos aceitos, uma linha por
// criterio, logo abaixo do titulo "CRITERIOS DE ACEITE" / "CRITÉRIOS DE ACEITE":
//   "1. Dado ..., quando ..., entao ..."   ou   "Cenário 1: Titulo. Dado ... quando ... entao ..."
// A secao termina na linha em branco seguinte ou na 1a nota ("--- "). O corpo recebe um ponteiro.
// DRY_RUN = true: so lista o que faria. Troque para false para gravar. Idempotente (so roda onde ACCount = 0).
Boolean DRY_RUN = true;
String DE = 'W-000051', ATE = 'W-000117';

List<agf__ADM_Acceptance_Criterion__c> novos = new List<agf__ADM_Acceptance_Criterion__c>();
List<agf__ADM_Work__c> works = new List<agf__ADM_Work__c>();
Integer wCount = 0;
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Details__c,
                                  (SELECT Id FROM agf__Acceptance_Criteria__r LIMIT 1)
                           FROM agf__ADM_Work__c WHERE Name >= :DE AND Name <= :ATE ORDER BY Name]) {
    if (!w.agf__Acceptance_Criteria__r.isEmpty() || w.agf__Details__c == null) continue;
    String det = w.agf__Details__c.replace('\r\n', '\n');
    Pattern p = Pattern.compile('(?im)^\\s*CRIT[EÉ]RIOS DE ACEITE\\s*:?\\s*\\n');
    Matcher m = p.matcher(det);
    if (!m.find()) continue;
    Integer ini = m.start(), corpoIni = m.end();
    Integer fim = det.length();
    Integer nota = det.indexOf('\n--- ', corpoIni); if (nota > -1) fim = nota;
    Integer branco = det.indexOf('\n\n', corpoIni); if (branco > -1 && branco < fim) fim = branco;
    String secao = det.substring(corpoIni, fim);
    List<String> linhas = new List<String>();
    for (String l : secao.split('\n')) if (l.trim().length() > 0) linhas.add(l.trim());
    if (linhas.isEmpty()) continue;
    wCount++;
    Integer i = 0;
    for (String l : linhas) {
        i++;
        String titulo = l;
        Matcher mc = Pattern.compile('^(Cen[aá]rio\\s+\\w+\\s*:\\s*[^.]{0,60})\\.').matcher(l);
        if (mc.find()) titulo = mc.group(1);
        else if (l.startsWith(String.valueOf(i) + '.')) titulo = 'Critério ' + i;
        titulo = titulo.left(80);
        novos.add(new agf__ADM_Acceptance_Criterion__c(agf__Work__c = w.Id, Name = titulo, agf__Description__c = l));
        System.debug('MIG| ' + w.Name + ' | AC ' + i + ' | ' + titulo + ' | ' + l.left(120));
    }
    String ponteiro = 'CRITERIOS DE ACEITE: migrados para a related list Acceptance Criteria em 08/09 (' + linhas.size() + ' itens).';
    w.agf__Details__c = det.substring(0, ini) + ponteiro + det.substring(fim);
    works.add(w);
    System.debug('MIG| ' + w.Name + ' | ' + linhas.size() + ' criterios | ' + w.agf__Subject__c);
}
System.debug('MIG| RESUMO: ' + wCount + ' works, ' + novos.size() + ' criterios' + (DRY_RUN ? ' (DRY RUN, nada gravado)' : ' GRAVADOS'));
if (!DRY_RUN && !novos.isEmpty()) { insert novos; update works; }
