// 18d - Complementa a work W-000136 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000136';
String PREFIXO = 'ARQUITETURA - Mapear fluxo';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work tecnica de Brasil TecPar (epico Arquitetura da Solucao e Ambientes). Complementada em 15/09.\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Realizar a sessao de arquitetura com Victor, David, Zildo, Priscila e Fernanda e sair dela com o fluxo ponta a ponta da jornada\n'
    + 'B2B e o mapa das APIs que ela consome e publica, para que as works B2B (W-000096 a W-000101, W-000107, W-000119 a W-000125,\n'
    + 'W-000142 a W-000145) tenham a mesma referencia de integracao e a SysMap nao desenhe integracao por work.\n'
    + '\n'
    + 'ESCOPO DA SESSAO\n'
    + '1. Fluxo B2B: lead (Econodata, inatividade) > enderecamento e viabilidade expressa (GIS/Radar) > cotacao multi-site, alcadas e\n'
    + '   trading (CPQ, BRE) > contrato e signatario legal (CLM, DocGen) > auditoria BKO e credito > pedido e orquestracao (OM) >\n'
    + '   ativacao no Customer Core e faturamento (SAP) > pos-venda (Zendesk, Visao 360, MACD, refidelizacao, cancelamento).\n'
    + '2. Para cada passo: sistema de origem e destino, API (nome, padrao TMF quando houver, proprietario quando nao), direcao,\n'
    + '   sincrono ou evento, dono no barramento, work do Agile que consome.\n'
    + '3. Pontos abertos a fechar na sessao: endpoint do Customer Core para vigencia e ativacao (decisao de 04/09), momento da chamada\n'
    + '   SAP (decomposicao no OM, P-16), etiqueta RGC por ponto (W-000050/W-000104), padrao de eventos de contrato (W-000105).\n'
    + '\n'
    + 'ENTREGAS\n'
    + '- Diagrama de fluxo B2B (sequencia por etapa) e diagrama de contexto de integracoes, versionados no repositorio de documentacao\n'
    + '  do projeto.\n'
    + '- Tabela de APIs (entrada da W-000135) e lista de decisoes de arquitetura (ADR) com data e participantes.\n'
    + '- Ata da sessao com pendencias, dono e prazo.\n'
    + '\n'
    + 'DEPENDENCIAS: agenda dos participantes; inventario da W-000135; licenca de OM (W-000134) para validar a etapa de pedido.\n'
    + 'RESPONSAVEL SUGERIDO: Diego Beltrao de Moraes (governanca) com o arquiteto SysMap. Estimativa: 1 sessao + 3 dias de consolidacao.';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Sessao realizada e registrada',
        'que a sessao foi agendada com Victor, David, Zildo, Priscila e Fernanda',
        'a sessao ocorrer',
        'existe ata com participantes, decisoes, pendencias com dono e prazo, anexada a esta work'},
    new List<String>{'Fluxo B2B ponta a ponta',
        'que a ata foi publicada',
        'o diagrama de fluxo B2B for consolidado',
        'todas as etapas de lead a pos-venda aparecem com sistema de origem e destino, e cada etapa referencia a work B2B que a implementa'},
    new List<String>{'Mapa de APIs',
        'que o fluxo esta consolidado',
        'a tabela de APIs for publicada',
        'cada integracao tem nome, padrao, direcao, sincrono ou evento, dono e work consumidora, e a tabela e a mesma usada no inventario da W-000135'},
    new List<String>{'Decisoes de arquitetura',
        'que houve decisao sobre Customer Core, SAP no OM, RGC e eventos de contrato',
        'as ADRs forem registradas',
        'cada decisao tem contexto, opcao escolhida, alternativas e consequencias, e as works afetadas recebem nota apontando a ADR'}
};

if (String.isBlank(w.agf__Details__c)) { w.agf__Details__c = det; update w; System.debug('CMP18| Details gravado (' + det.length() + ' chars)'); }
else System.debug('CMP18| Details ja preenchido (' + w.agf__Details__c.length() + ' chars) - NAO sobrescrito; compare com o texto deste script');
Integer existentes = [SELECT COUNT() FROM agf__ADM_Acceptance_Criterion__c WHERE agf__Work__c = :w.Id];
if (existentes == 0) {
    List<agf__ADM_Acceptance_Criterion__c> novos = new List<agf__ADM_Acceptance_Criterion__c>();
    Integer i = 0;
    for (List<String> c : crits) {
        i++;
        novos.add(new agf__ADM_Acceptance_Criterion__c(agf__Work__c = w.Id, Name = 'Critério ' + i + ' - ' + c[0], agf__Status__c = 'New',
            agf__Description__c = 'Dado ' + c[1] + '\nQuando ' + c[2] + '\nEntão ' + c[3]));
    }
    insert novos;
    System.debug('CMP18| ' + novos.size() + ' criterios criados');
} else System.debug('CMP18| ja existem ' + existentes + ' criterios - nenhum criado');
System.debug('CMP18| concluido ' + w.Name);
