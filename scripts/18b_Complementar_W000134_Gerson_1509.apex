// 18b - Complementa a work W-000134 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000134';
String PREFIXO = 'INTEGRAÇÕES - Ambientes';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work tecnica de Brasil TecPar (epico Integracao, Barramento (MuleSoft) e CI/CD). Complementada em 15/09 com as evidencias\n'
    + 'levantadas em producao (prod-brasiltecpar) e o encaminhamento combinado com o Gerson (e-mail ao Bismarck, Gerson em copia).\n'
    + '\n'
    + 'SITUACAO ENCONTRADA EM 15/09 (producao)\n'
    + '- Setup > Company Information > Usage-Based Entitlements: "Maximum B2C orders submitted via Industries Order Management" com\n'
    + '  Allowance 0, vigencia encerrada em 16/06/2026, 252 ordens usadas, ultimo uso em 29/05/2026. Nao ha linha de ordens B2B.\n'
    + '- Nenhum Permission Set License de Order Management na org; Communications Cloud Plus com 2100 licencas (1950 em uso), ativa\n'
    + '  ate 17/06/2028; Document Generation com 624 usuarios; PSLs de PCM/Unified Catalog atribuidas a 5 administradores, sem uso.\n'
    + '- Installed Packages: Vlocity CMT 900.650.3 (EPC, CPQ, CLM e OM no mesmo pacote); a licenca do pacote (1/1) esta com um usuario\n'
    + '  de Field Service, nao com o time do projeto.\n'
    + '- Historico: a licenca de OM era cortesia de 12 meses (vencida em 16/06/2026); o novo aditivo comercial inclui OM, mas ainda\n'
    + '  nao foi provisionado pela Salesforce (case aberto; Gerson).\n'
    + '- Consequencia: nenhuma jornada que submete pedido ao Industries Order Management (B2C-27, TEC-B2C-05, B2B-05, MACD, EPC-10 com\n'
    + '  decomposicao) pode ir a producao ate a provisao; preprod e radardev herdam a mesma situacao no proximo refresh.\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Formalizar junto a Salesforce (AE/Bismarck) a provisao das licencas de Order Management do aditivo e os ajustes de licenca\n'
    + 'das sandboxes, com evidencias, e acompanhar ate as tres orgs (producao, preprod, radardev) terem OM utilizavel para testes e\n'
    + 'go-live.\n'
    + '\n'
    + 'ENTREGAS\n'
    + '1. E-mail de evidencias ao Bismarck (prints de Usage-Based Entitlements, Installed Packages, consulta de PermissionSetLicense e\n'
    + '   do package license), com Gerson em copia, pedindo data de provisao e confirmacao das quantidades de ordens B2C e B2B.\n'
    + '2. Registro do numero do case e do retorno do AE nesta work (comentarios), com a data prevista.\n'
    + '3. Apos a provisao em producao: Match Production Licenses (ou refresh) em preprod e radardev; verificacao das entitlements e das\n'
    + '   PSLs nas tres orgs; licenca do pacote Vlocity CMT realocada para o usuario de integracao/administrador do projeto.\n'
    + '4. Teste de fumaca: submissao de um pedido de teste em preprod pelo XOM sem erro de entitlement, com evidencia anexada.\n'
    + '\n'
    + 'DEPENDENCIAS: retorno do AE (Bismarck); janela de refresh das sandboxes combinada com SysMap (perda de dados de teste).\n'
    + 'RESPONSAVEL SUGERIDO: Gerson Da Silva Pereira (relacionamento com AE) com Diego (evidencias e verificacao tecnica).';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Evidencias formalizadas',
        'que as evidencias de producao (entitlements, pacotes, PSLs, package license) foram coletadas em 15/09',
        'o e-mail ao Bismarck for enviado com o Gerson em copia',
        'o e-mail e o numero do case ficam registrados nesta work, com a lista do que foi pedido: provisao de OM (B2C e B2B) e ajuste das sandboxes'},
    new List<String>{'Provisao confirmada em producao',
        'que a Salesforce informou a provisao do aditivo',
        'a tela de Usage-Based Entitlements de producao for consultada',
        'existe entitlement de ordens via Industries Order Management com Allowance maior que zero e vigencia futura, para B2C e para B2B, e a data fica registrada na work'},
    new List<String>{'Sandboxes alinhadas',
        'que producao esta provisionada',
        'preprod e radardev passarem por Match Production Licenses ou refresh',
        'as duas sandboxes exibem as mesmas entitlements e PSLs de producao, e a data do refresh fica registrada na work'},
    new List<String>{'Pedido de teste no OM',
        'que preprod esta alinhada',
        'um pedido de teste for submetido ao XOM',
        'o pedido e decomposto e orquestrado sem erro de licenca ou entitlement, com print anexado como evidencia'}
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
