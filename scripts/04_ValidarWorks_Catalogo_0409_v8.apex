// 04 v8 - VALIDACAO dos scripts 01, 02, 03, 05, 07, 08, 09 e 11 (executar por ultimo).
// v4: inclui as 11 works das lacunas (script 07). Esperado: 72 OK.
// v7: inclui as notas de 08/09 dos scripts 08 e 09 e a work CAT-ACC-01. Esperado: 79 OK.
// v8: inclui as 2 notas de correcao do script 11 (08/09). Esperado: 81 OK.
// Somente SELECT + System.debug: NAO grava nada, pode rodar quantas vezes quiser.
//
// Como usar:
// 1. Execute Anonymous com "Open Log" marcado.
// 2. No log, filtre por USER_DEBUG (ou busque por "VAL|").
// 3. Me mande as linhas VAL| e a linha RESULTADO.
// 4. Se quiser o conteudo COMPLETO das works (extracao total), mude DUMP_COMPLETO
//    para true e rode de novo: o log traz linhas DUMP| com o Details inteiro em
//    blocos de 250 caracteres por work.

Boolean DUMP_COMPLETO = false;

// ---------------------------------------------------------------- 1. o que cada work deve conter
String MARCA_ASIS = 'REAPROVEITAMENTO AS-IS';

// marcadores do script 01 = cabecalho exato de cada nota (v2: corrigidos)
Map<String, List<String>> esperado = new Map<String, List<String>>{
    'W-000082' => new List<String>{ '--- DECISAO 04/09 - CONTRATO NA COTACAO, SERVER-SIDE ---' },
    'W-000089' => new List<String>{ '--- DECISAO 04/09 - GERACAO ASSINCRONA, DISPARO POR EVENTO ---' },
    'W-000086' => new List<String>{ '--- PADRAO DE RESPONSIVIDADE DA JORNADA (04/09) ---' },
    'W-000087' => new List<String>{ '--- CANAL DE EVENTOS DE CONTRATO (04/09) ---' },
    'W-000088' => new List<String>{ '--- CAMPOS FISCAIS PARAMETRIZADOS NA ORDEM (04/09, ata de 03/09) ---' },
    'W-000056' => new List<String>{ '--- NAVEGACAO POR FAMILIA (04/09, ata de 03/09) ---' },
    'W-000069' => new List<String>{ '--- NAVEGACAO POR FAMILIA (04/09, ata de 03/09) ---' },
    'W-000085' => new List<String>{ '--- COMBOS COM VARIACAO DRASTICA DE PRECO (04/09, ata de 03/09) ---' }
};

// carimbo do script 03 (reaproveitamento AS-IS) nas 27 works numeradas
for (String n : new List<String>{
        'W-000056','W-000057','W-000058','W-000059','W-000060','W-000061','W-000063',
        'W-000065','W-000066','W-000067','W-000068','W-000069','W-000072','W-000073',
        'W-000074','W-000076','W-000077','W-000081','W-000082','W-000083','W-000084',
        'W-000087','W-000088','W-000090','W-000092','W-000093','W-000094' }) {
    if (!esperado.containsKey(n)) esperado.put(n, new List<String>());
    esperado.get(n).add(MARCA_ASIS);
}


// marcadores do script 05 (consistencia tecnica/B2B/B2C) = cabecalho exato de cada nota
Map<String, List<String>> e05 = new Map<String, List<String>>{
    'W-000060' => new List<String>{ '--- MODELO DE ENDERECO (decisao 01/09, registro 04/09) ---' },
    'W-000085' => new List<String>{ '--- PRECO POR ZONA E PRAZO DE CONTRATO (decisao 03/09) ---' },
    'W-000069' => new List<String>{ '--- ZONA DE PRECO NO FUNIL (decisao 03/09) ---' },
    'W-000084' => new List<String>{ '--- CONTEXTO DE PRECO NO CREATE CART (decisao 03/09) ---' },
    'W-000081' => new List<String>{ '--- PRAZO DE CONTRATO E CAMPOS FISCAIS (decisoes 03/09 e 04/09) ---' },
    'W-000075' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---' },
    'W-000080' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---' },
    'W-000095' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---' },
    'W-000096' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---' },
    'W-000098' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---', '--- GERACAO DE PROPOSTA NA COTACAO, ASSINCRONA (decisao 04/09) ---' },
    'W-000099' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---' },
    'W-000100' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---', '--- MACD SEM TECNICO E IDENTIDADE DO ATIVO (04/09) ---' },
    'W-000101' => new List<String>{ '--- DIRETRIZ DE INTEGRACAO 04/09 (endpoint proprietario x TMF) ---', '--- CAMPOS FISCAIS NO HANDOFF (decisao 04/09) ---' },
    'W-000065' => new List<String>{ '--- ASSINATURA INTEGRADA AO CANAL DE CONTRATO (04/09) ---' },
    'W-000066' => new List<String>{ '--- GATILHO DA REGUA POR EVENTO (04/09) ---' },
    'W-000093' => new List<String>{ '--- SERVICE TAG E IDENTIDADE DO ATIVO (04/09) ---' },
    'W-000094' => new List<String>{ '--- ESCOPO DE PRODUTOS NA INSTALACAO (decisao 03/09) ---' },
    'W-000058' => new List<String>{ '--- OFERTA MOVEL DA TRILHA ALTERNATIVA (decisao 03/09) ---' }
};
// marcadores dos scripts 08 e 09 (08/09) e do script 11 (correcao apos auditoria das contas, 08/09)
Map<String, List<String>> e08 = new Map<String, List<String>>{
    'W-000082' => new List<String>{ '--- ESCLARECIMENTO 08/09 - QUEM GERA O CONTRATO ---' },
    'W-000089' => new List<String>{ '--- SAIDA DO DOCGEN E VERSAO ASSINADA (08/09) ---' },
    'W-000065' => new List<String>{ '--- CONTRATO ASSINADO NO SALESFORCE (08/09) ---' },
    'W-000105' => new List<String>{ '--- RETORNO DO CONTRATO ASSINADO PARA O SALESFORCE (08/09) ---' },
    'W-000117' => new List<String>{ '--- CENARIO REAL DA ORG DE PRODUCAO (08/09) ---',
                                    '--- CORRECAO APOS AUDITORIA DAS CONTAS BILLING (08/09) ---' },
    'W-000103' => new List<String>{ '--- CONTAS ANTES DOS ATIVOS - DADOS DA ORG (08/09) ---',
                                    '--- CORRECAO DO PASSO 2 DA CARGA (08/09) ---' }
};
for (String n : e08.keySet()) {
    if (!e05.containsKey(n)) e05.put(n, new List<String>());
    e05.get(n).addAll(e08.get(n));
}
for (String n : e05.keySet()) {
    if (!esperado.containsKey(n)) esperado.put(n, new List<String>());
    esperado.get(n).addAll(e05.get(n));
}

// works novas do script 02 (localizadas por prefixo do Subject; o numero W- foi gerado na criacao)
// TEC-INT-01 tambem deve ter recebido a nota AS-IS do script 03
Map<String, Boolean> novas = new Map<String, Boolean>{
    'US CAT-TPL-01%' => false,
    'US CAT-MIG-01%' => false,
    'US CAT-TAG-01%' => false,
    'US TEC-INT-01%' => true,
    'US CAT-ZON-01%' => false,
    'US CPQ-BRE-01%' => false,
    'US CAT-PRC-01%' => false,
    'US B2C-30%' => false,
    'US B2C-31%' => false,
    'US B2C-32%' => false,
    'US TEC-INT-02%' => false,
    'US CAT-FAM-01%' => false,
    'US CAT-CHD-01%' => false,
    'US CAT-API-01%' => false,
    'US B2C-33%' => false,
    'US CAT-ACC-01%' => false
};

// ---------------------------------------------------------------- 2. validar works numeradas
Integer ok = 0, falta = 0, dup = 0;
Map<String, agf__ADM_Work__c> porNome = new Map<String, agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Status__c, agf__Details__c,
                                  agf__Epic__r.Name, agf__Scrum_Team__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN :esperado.keySet()]) {
    porNome.put(w.Name, w);
}

for (String nome : esperado.keySet()) {
    agf__ADM_Work__c w = porNome.get(nome);
    if (w == null) {
        System.debug('VAL| ' + nome + ' | WORK NAO ENCONTRADA');
        falta += esperado.get(nome).size();
        continue;
    }
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    for (String m : esperado.get(nome)) {
        Integer q = det.countMatches(m);
        String r = (q == 1) ? 'OK' : (q == 0 ? 'FALTA' : 'DUPLICADO x' + q);
        if (q == 1) ok++; else if (q == 0) falta++; else dup++;
        System.debug('VAL| ' + nome + ' | ' + r + ' | ' + m);
    }
}

// ---------------------------------------------------------------- 3. validar works novas
for (String prefixo : novas.keySet()) {
    List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Status__c, agf__Details__c,
                                        agf__Epic__r.Name, agf__Scrum_Team__r.Name, agf__Assignee__r.Name
                                 FROM agf__ADM_Work__c WHERE agf__Subject__c LIKE :prefixo];
    if (ws.isEmpty()) {
        System.debug('VAL| ' + prefixo + ' | FALTA | work nova nao foi criada');
        falta++;
        continue;
    }
    if (ws.size() > 1) {
        System.debug('VAL| ' + prefixo + ' | DUPLICADO x' + ws.size() + ' | criada mais de uma vez');
        dup++;
    }
    agf__ADM_Work__c w = ws[0];
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    Boolean camposOk = w.agf__Epic__c != null && w.agf__Scrum_Team__c != null && det.length() > 500;
    System.debug('VAL| ' + prefixo + ' | ' + (camposOk ? 'OK' : 'INCOMPLETA') + ' | criada como ' + w.Name
        + ' | epic=' + w.agf__Epic__r.Name + ' | time=' + w.agf__Scrum_Team__r.Name
        + ' | status=' + w.agf__Status__c + ' | details=' + det.length() + ' chars');
    if (camposOk) ok++; else falta++;
    porNome.put(w.Name, w);
    if (novas.get(prefixo)) { // TEC-INT-01: nota AS-IS do script 03
        Integer q = det.countMatches(MARCA_ASIS);
        String r = (q == 1) ? 'OK' : (q == 0 ? 'FALTA' : 'DUPLICADO x' + q);
        if (q == 1) ok++; else if (q == 0) falta++; else dup++;
        System.debug('VAL| ' + w.Name + ' | ' + r + ' | ' + MARCA_ASIS + ' (nota na work nova)');
    }
}

// ---------------------------------------------------------------- 4. panorama geral do backlog
for (agf__ADM_Work__c w : [SELECT Name, agf__Subject__c, agf__Status__c, agf__Details__c
                           FROM agf__ADM_Work__c
                           WHERE Name >= 'W-000051' AND Name <= 'W-000117'
                           ORDER BY Name]) {
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    Integer notas = det.countMatches('--- ');
    System.debug('VAL| PANORAMA | ' + w.Name + ' | ' + w.agf__Status__c + ' | '
        + det.length() + ' chars | ' + notas + ' nota(s) | ' + w.agf__Subject__c);
}

System.debug('VAL| RESULTADO: ' + ok + ' OK, ' + falta + ' FALTANDO, ' + dup + ' DUPLICADOS');

// ---------------------------------------------------------------- 5. extracao completa (opcional)
if (DUMP_COMPLETO) {
    for (String nome : porNome.keySet()) {
        agf__ADM_Work__c w = porNome.get(nome);
        String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
        System.debug('DUMP| ===== ' + w.Name + ' | ' + w.agf__Subject__c + ' =====');
        for (Integer i = 0; i < det.length(); i += 250) {
            System.debug('DUMP| ' + w.Name + ' | ' + det.substring(i, Math.min(i + 250, det.length())));
        }
    }
}
