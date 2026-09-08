// 15 - W-000070 (EPC-10): move o texto "Decisoes do cliente P-01 a P-19" escondido na Acceptance
// Criteria "3" para uma nota no Details, e registra os pontos de conflito com QUAL-01 e decisoes
// de 03/09 como PENDENCIAS (sem decidir). Idempotente: se a nota ja existir, pula.
// Esperado na 1a execucao: 1 AC ajustada, 2 notas gravadas.
String CAB1 = '--- DECISOES DO CLIENTE P-01 A P-19 (ONDA 0, registro de 26/08; movido da AC 3 em 08/09) ---';
String CAB2 = '--- PENDENCIAS DE ALINHAMENTO COM QUAL-01 E DECISOES DE 03/09 (08/09) ---';
String MARCA = 'Decisões do cliente';

agf__ADM_Work__c w = [SELECT Id, Name, agf__Details__c,
                             (SELECT Id, Name, agf__Description__c FROM agf__Acceptance_Criteria__r)
                      FROM agf__ADM_Work__c WHERE Name = 'W-000070' LIMIT 1];
String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
if (det.contains(CAB1)) { System.debug('PULOU W-000070 | nota ja existe'); return; }

String decisoes = null;
agf__ADM_Acceptance_Criterion__c acAlvo = null;
for (agf__ADM_Acceptance_Criterion__c ac : w.agf__Acceptance_Criteria__r) {
    String d = ac.agf__Description__c == null ? '' : ac.agf__Description__c;
    Integer p = d.indexOf(MARCA);
    if (p > -1) { decisoes = d.substring(p).trim(); ac.agf__Description__c = d.substring(0, p).trim(); acAlvo = ac; }
}
if (decisoes == null) { System.debug('ERRO W-000070 | texto de decisoes nao encontrado em nenhuma AC'); return; }

String pend = 'Registro de revisao (extracao completa de 08/09). Esta work nao recebeu nenhuma nota desde 26/08 e conflita com decisoes posteriores; itens a decidir com SysMap e Joel antes da parametrizacao:\n'
  + '(1) ESTRUTURA DE CATALOGO: esta work define catalogos POR FAMILIA (CAT_INTERNET, CAT_SEGURANCA, CAT_WIFI, CAT_VOZ, CAT_STREAMING, CAT_SVA, CAT_TV) e pede a atualizacao da QUAL-01; a QUAL-01 (W-000056) define catalogos POR MERCADO (CAT_B2C_EVO, CAT_B2S_EVO, CAT_B2B_EVO, CAT_B2G_EVO, CAT_WHOLESALE_EVO) com familia como categoria e "proibido catalogo por familia" (manual v2.2 §9.1/§28.3). A ata de 03/09 decidiu NAVEGACAO por familia (nota de 04/09 na W-000056 e W-000069), mas deixou em aberto se familia e catalogo ou categoria. Definir um modelo unico e ajustar a outra work.\n'
  + '(2) LISTA DE FAMILIAS: aqui Internet, Seguranca, Wi-Fi, Voz, Streaming, Servicos Digitais e TV (reservado); em 03/09 (W-000069, W-000094, W-000111) Internet, Streaming, Camera e Movel na Onda 1. Faltam CAT_MOVEL e CAT_CAMERA; CAT_TV conflita com "sem IPTV/TV Box" (W-000094, nota de 03/09).\n'
  + '(3) NOMES COM MARCA: a tabela cita Playhub, Aya Bancah, Aya Books e marcas de Wi-Fi; a decisao de rebranding (W-000102 item 1, W-000106 RN-05, W-000110 RN-01) exige nomes GENERICOS e identificador de fornecedor em atributo tecnico nao visivel.\n'
  + '(4) NUMERACAO DAS PENDENCIAS: a nota P-01..P-19 movida da AC usa P-17 = Group Promotion ID e P-18 = dominios de qualificacao; QUAL-01, B2C-13 e CAT-ZON-01 usam P-17 = solucao IBGE e P-19 = dominios do Joel. A nota diz "nao ha itens abertos", mas W-000056, W-000069 e W-000114 ainda tratam P-19 como pendente. Unificar a numeracao e o status.\n'
  + '(5) AC 3 desta work continha o texto de decisoes por engano; ajustado em 08/09 (script 15). Os criterios 1 a 3 permanecem.';

w.agf__Details__c = det + '\n\n' + CAB1 + '\n' + decisoes + '\n\n' + CAB2 + '\n' + pend;
update acAlvo;
update w;
System.debug('AC ajustada: ' + acAlvo.Name + ' | novo tamanho ' + acAlvo.agf__Description__c.length() + ' chars');
System.debug('NOTAS gravadas em W-000070: 2 | decisoes movidas: ' + decisoes.length() + ' chars | Details agora ' + w.agf__Details__c.length() + ' chars');
System.debug('SCRIPT 15 - ok (esperado na 1a execucao: 1 AC ajustada, 2 notas)');
