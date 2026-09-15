// 18a - Complementa a work W-000133 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000133';
String PREFIXO = 'INTEGRAÇÕES - CI/CD';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work tecnica de Brasil TecPar (epico Integracao, Barramento (MuleSoft) e CI/CD). Complementada em 15/09 na validacao das works\n'
    + 'tecnicas; sucede a W-000025 "Esteira CI/CD" (Thiago, em andamento) e passa a ser a referencia da esteira do projeto SysMap.\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Ter o metadata do projeto Salesforce versionado em repositorio GitLab de Brasil TecPar e uma esteira basica de CI/CD que valide\n'
    + 'toda alteracao antes de chegar em preprod e producao, para que SysMap e BTP trabalhem no mesmo codigo e nenhum deploy em\n'
    + 'producao seja feito direto da org ou por change set sem rastreio.\n'
    + '\n'
    + 'ESCOPO (esteira basica)\n'
    + '1. Repositorio GitLab do projeto (grupo de Brasil TecPar), formato source (sf project), com o metadata atual de producao\n'
    + '   recuperado por manifest: objetos e campos custom, Apex, LWC, flows, permission sets, OmniStudio (OmniScripts, Integration\n'
    + '   Procedures, DataRaptors, FlexCards) e metadata Industries exportado por DataPack, alem dos scripts de catalogo (EPC).\n'
    + '2. Estrategia de branches: main = producao; develop = preprod; feature/W-000xxx = uma branch por work do Agile Accelerator.\n'
    + '   Merge Request obrigatorio para develop e main, com pelo menos um aprovador de BTP (governanca) para main.\n'
    + '3. Pipeline (GitLab CI, runner com sf CLI): (a) em todo MR para develop: validacao (deploy check-only) contra preprod com\n'
    + '   execucao dos testes Apex (RunLocalTests) e cobertura minima de 75%; (b) no merge em develop: deploy em preprod;\n'
    + '   (c) no merge em main: deploy em producao somente por job manual, aprovado por BTP, em janela combinada.\n'
    + '4. Autenticacao dos jobs por JWT (connected app + certificado) com usuario de integracao dedicado por org; segredos em variaveis\n'
    + '   protegidas do GitLab, nunca no repositorio.\n'
    + '5. README com o fluxo, o mapa de orgs (radardev = desenvolvimento, preprod = homologacao, producao) e o procedimento para abrir MR.\n'
    + '\n'
    + 'FORA DE ESCOPO NESTA WORK\n'
    + 'Testes automatizados de UI, qualidade estatica (PMD/scanner) como gate bloqueante, migracao de dados e deploy de DataPacks\n'
    + 'Industries automatizado (entram como evolucao apos a esteira basica rodar por uma sprint).\n'
    + '\n'
    + 'DEPENDENCIAS E RISCOS\n'
    + 'Acesso ao GitLab de BTP para SysMap (usuarios nomeados); usuario de integracao e certificado em cada org; preprod atualizada\n'
    + '(refresh) antes da primeira validacao. Risco: metadata Industries (EPC, OmniStudio) so parcialmente coberto por sf deploy;\n'
    + 'DataPacks continuam com processo manual documentado ate a evolucao.\n'
    + '\n'
    + 'RESPONSAVEL SUGERIDO: Thiago Campos Almeida (BTP), com apoio do dev lead SysMap. Estimativa: 1 sprint.';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Repositorio com o metadata de producao',
        'que o repositorio GitLab do projeto foi criado no grupo de Brasil TecPar',
        'o metadata de producao for recuperado por manifest e commitado na branch main',
        'o repositorio contem objetos, Apex, LWC, flows, permission sets e OmniStudio de producao, com README e mapa de orgs, e um deploy check-only da main contra producao termina sem diferencas'},
    new List<String>{'Validacao automatica de Merge Request',
        'que existe um MR de uma branch feature/W-000xxx para develop',
        'o pipeline rodar',
        'o job de validacao executa deploy check-only contra preprod com testes Apex, e um MR com teste falhando ou cobertura abaixo de 75% fica bloqueado para merge'},
    new List<String>{'Deploy automatico em preprod',
        'que um MR foi aprovado e mesclado em develop',
        'o pipeline de develop rodar',
        'o deploy em preprod e executado pelo job, com log e resultado visiveis no GitLab, sem intervencao manual na org'},
    new List<String>{'Deploy em producao controlado',
        'que develop foi mesclado em main',
        'o pipeline de main rodar',
        'o deploy em producao fica aguardando job manual, que so pode ser disparado por aprovador de BTP, e cada execucao fica registrada com autor, data e commit'},
    new List<String>{'Segredos fora do repositorio',
        'que os jobs autenticam por JWT com usuario de integracao por org',
        'o repositorio e o pipeline forem auditados',
        'nenhuma senha, token ou chave privada existe no codigo; as credenciais estao apenas em variaveis protegidas do GitLab'}
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
