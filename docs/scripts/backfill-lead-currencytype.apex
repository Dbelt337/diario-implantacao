/**
 * Backfill de CurrencyType__c nos Leads que tem pais e nao tem moeda.
 *
 * Resolve o FIELD_CUSTOM_VALIDATION_EXCEPTION
 *   "Es necesario informar la moneda (Tipo de Divisa) cuando el pais esta definido"
 * na origem, preenchendo o dado, em vez de desligar a regra.
 *
 * Executar em Developer Console, Debug, Open Execute Anonymous Window,
 * com Open Log marcado e Debug Only ativado.
 *
 * ANTES DE RODAR: confirmar o mapa abaixo. A moeda default por pais foi
 * inferida da dependencia do picklist, onde USD aparece habilitado em todos
 * os paises e a moeda local em cada um. Se o negocio quiser USD como default
 * em algum pais, ajustar aqui.
 */

Map<String, String> monedaPorPais = new Map<String, String>{
    'CR' => 'CRC',   // Costa Rica
    'GT' => 'GTQ',   // Guatemala
    'SV' => 'USD',   // El Salvador, dolarizado
    'HN' => 'HNL',   // Honduras
    'NI' => 'NIO',   // Nicaragua
    'PA' => 'USD'    // Panama
};

List<Lead> pendentes = [
    SELECT Id, Name, Country__c, CurrencyType__c
    FROM Lead
    WHERE Country__c != null
      AND Country__c != 'NA'
      AND CurrencyType__c = null
    LIMIT 10000
];

System.debug('Leads com pais e sem moeda: ' + pendentes.size());
if (pendentes.isEmpty()) {
    System.debug('Nada a corrigir. Se o erro persistir, ele vem do registro que o '
        + 'seu proprio script esta atualizando, e a correcao e informar '
        + 'CurrencyType__c junto com Country__c nesse update.');
    return;
}

List<Lead> aAtualizar = new List<Lead>();
Map<String, Integer> semMapa = new Map<String, Integer>();

for (Lead l : pendentes) {
    String moeda = monedaPorPais.get(l.Country__c);
    if (moeda == null) {
        semMapa.put(l.Country__c, (semMapa.containsKey(l.Country__c) ? semMapa.get(l.Country__c) : 0) + 1);
        continue;
    }
    l.CurrencyType__c = moeda;
    aAtualizar.add(l);
}

if (!semMapa.isEmpty()) {
    System.debug('ATENCAO, paises sem moeda no mapa, nao foram tocados: ' + semMapa);
}

Integer ok = 0;
Integer falha = 0;
List<Database.SaveResult> res = Database.update(aAtualizar, false);
for (Integer i = 0; i < res.size(); i++) {
    if (res[i].isSuccess()) {
        ok++;
    } else {
        falha++;
        if (falha <= 10) {
            System.debug('FALHA em ' + aAtualizar[i].Id + ': ' + res[i].getErrors()[0].getMessage());
        }
    }
}
System.debug('Atualizados: ' + ok + ' | Com erro: ' + falha);

System.debug('----- DISTRIBUICAO FINAL POR PAIS E MOEDA -----');
for (AggregateResult ar : [
        SELECT Country__c pais, CurrencyType__c moeda, COUNT(Id) qtd
        FROM Lead
        WHERE Country__c != null
        GROUP BY Country__c, CurrencyType__c
        ORDER BY Country__c]) {
    System.debug('   ' + ar.get('pais') + ' | ' + ar.get('moeda') + ' | ' + ar.get('qtd'));
}
