// 18f - Complementa a work W-000140 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000140';
String PREFIXO = 'B2B - Habilitar integração B2B';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work tecnica SysMap (epico B2B - Jornadas de Venda e Gestao do Ciclo de Vida do Cliente). Complementada em 15/09. Urgente:\n'
    + 'sem as integracoes habilitadas em sandbox, os testes das historias B2B nao saem do mock.\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Deixar a sandbox de desenvolvimento (radardev) e a preprod com as integracoes que a jornada B2B consome apontando para os\n'
    + 'ambientes de homologacao do barramento MuleSoft, com credenciais, usuarios de teste e evidencia de conectividade, para que a\n'
    + 'SysMap execute os testes das works B2B (W-000096 a W-000101, W-000119 a W-000125, W-000142 a W-000145).\n'
    + '\n'
    + 'ESCOPO\n'
    + '1. Named Credentials e External Credentials (padrao da W-000087 TEC-B2C-04) para os endpoints de homologacao usados pelo B2B:\n'
    + '   Customer Core (cliente, contrato, vigencia, ativacao), GIS/Radar (viabilidade), Econodata (enriquecimento), SAP (consulta\n'
    + '   de credito/debito, quando via barramento), Zendesk (tickets), gerador de etiqueta RGC. Lista fechada na W-000135/W-000136.\n'
    + '2. Permission set de integracao e usuario de integracao por org; permissoes de Named Credential para os perfis de teste.\n'
    + '3. Integration Procedures / Apex callouts existentes reapontados por ambiente (sem endpoint fixo no codigo).\n'
    + '4. Teste de conectividade por endpoint (chamada de leitura com retorno 200 e payload valido) com evidencia registrada.\n'
    + '5. Para endpoint sem homologacao disponivel: mock documentado (DataRaptor/IP de simulacao) com data prevista do endpoint real.\n'
    + '\n'
    + 'DEPENDENCIAS: ambientes de homologacao do MuleSoft e credenciais (W-000135); lista de APIs (W-000136); refresh de sandbox\n'
    + 'combinado (W-000134) para nao perder a configuracao.\n'
    + 'RESPONSAVEL SUGERIDO: dev lead SysMap com Thiago Campos Almeida (BTP, acessos). Estimativa: 1 sprint.';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Credenciais configuradas por ambiente',
        'que a lista de endpoints de homologacao do B2B foi fechada',
        'as Named Credentials e External Credentials forem criadas em radardev e preprod',
        'cada endpoint da lista tem credencial propria por org, sem URL ou segredo fixo em codigo, e o usuario de integracao esta ativo'},
    new List<String>{'Conectividade comprovada',
        'que as credenciais estao configuradas',
        'o teste de conectividade de cada endpoint for executado',
        'cada endpoint responde 200 com payload valido, e a evidencia (data, org, endpoint, resultado) fica registrada nesta work'},
    new List<String>{'Mocks documentados',
        'que algum endpoint de homologacao ainda nao existe',
        'a lista de conectividade for revisada',
        'cada endpoint sem homologacao tem mock documentado, dono e data prevista, e nenhuma work B2B fica bloqueada sem esse registro'},
    new List<String>{'Testes B2B executaveis',
        'que as integracoes estao habilitadas em preprod',
        'a SysMap executar o cenario de viabilidade expressa da W-000097 e o de contrato da W-000122',
        'os dois cenarios completam usando as integracoes de homologacao, sem mock, com evidencia anexada'}
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
