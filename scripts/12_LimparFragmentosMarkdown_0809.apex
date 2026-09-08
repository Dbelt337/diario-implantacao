// 12 - LIMPEZA de fragmentos de markdown ("## n. Titulo") colados no Details de 3 works
// (revisao dos 66 docs de 08/09). Idempotente: se o fragmento nao existir, pula.
// Esperado na 1a execucao: 3 works atualizadas. Nao mexe em marcador de nota (04 v8 continua 81 OK).

Map<String, String> fragmento = new Map<String, String>{
    'W-000073' => '## 2. Risco & Viabilidade',
    'W-000075' => '## 4. Pagamento, Delivery & Field Service',
    'W-000083' => '## 1. Entrada & Qualificação de Lead'
};

Integer limpas = 0, puladas = 0;
List<agf__ADM_Work__c> paraAtualizar = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Details__c
                           FROM agf__ADM_Work__c WHERE Name IN :fragmento.keySet()]) {
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    String frag = fragmento.get(w.Name);
    String fragHtml = frag.replace('&', '&amp;');           // Details rich text pode ter & escapado
    Integer antes = det.length();
    // remove o fragmento com o espaco/quebra que o antecede, nas duas grafias
    for (String f : new List<String>{ ' ' + frag, ' ' + fragHtml, frag, fragHtml }) {
        det = det.replace(f, '');
    }
    if (det.length() == antes) {
        System.debug('PULOU ' + w.Name + ' | fragmento nao encontrado: ' + frag);
        puladas++;
        continue;
    }
    w.agf__Details__c = det;
    paraAtualizar.add(w);
    System.debug('LIMPOU ' + w.Name + ' | ' + w.agf__Subject__c + ' | -' + (antes - det.length()) + ' chars | ' + frag);
    limpas++;
}
if (!paraAtualizar.isEmpty()) update paraAtualizar;
System.debug('SCRIPT 12 - works limpas: ' + limpas + ', puladas: ' + puladas + ' (esperado na 1a execucao: 3 limpas)');
