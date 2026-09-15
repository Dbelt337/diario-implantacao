// 18g - Complementa a work W-000141 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000141';
String PREFIXO = 'B2B - Escrever histórias';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work SysMap (epico B2B - Jornadas de Venda e Gestao do Ciclo de Vida do Cliente). Complementada em 15/09.\n'
    + '\n'
    + 'SITUACAO EM 15/09\n'
    + '- As 29 historias do documento "Especificacao Funcional e Tecnica B2B" estao cobertas: 1 a 25 pelas works W-000096 a W-000101,\n'
    + '  W-000107, W-000115, W-000119 a W-000125 e W-000128 (notas de refinamento de 10/09); 26 a 29 pelas works criadas em 15/09\n'
    + '  W-000142 (B2B-13 refidelizacao simples), W-000143 (B2B-14 aviso previo de cancelamento), W-000144 (B2B-15 condicoes de\n'
    + '  faturamento) e W-000145 (B2B-16 cadencia de notificacoes), com 32 criterios de aceite e docs no padrao do export.\n'
    + '- Os 68 comentarios de negocio de 14/09 (Priscila, Fernanda) estao registrados no documento e nas works.\n'
    + '- Documentacao: 82 docs do export de 11/09 + 4 docs das works novas + 10 docs das works de catalogo sem doc (15/09).\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Fazer o onboarding dos 3 novos profissionais SysMap no B2B e, com eles, escrever as historias TECNICAS B2B (TEC-B2B) que ainda\n'
    + 'nao existem, no padrao das TEC-B2C (W-000084 a W-000092): uma work tecnica por fundacao compartilhada, nao por historia de negocio.\n'
    + '\n'
    + 'ESCOPO\n'
    + '1. Onboarding (dia 1): acesso ao Agile Accelerator (time SysMap), ao GitLab (W-000133) e as sandboxes; leitura guiada do pacote\n'
    + '   de docs, da planilha de cobertura historias x works e das decisoes de 10/09 e 14/09; walkthrough das works B2B-01 a B2B-16.\n'
    + '2. Historias tecnicas B2B a abrir (proposta, validar com o dev lead): TEC-B2B-01 botao e OmniScript de cotacao multi-site e\n'
    + '   trading (B2B-03/12); TEC-B2B-02 BRE de precificacao e alcadas (CPQ-BRE-01, W-000107); TEC-B2B-03 CLM: contract types,\n'
    + '   state model, Amend Frame Agreement e templates DocGen (B2B-09, B2B-13); TEC-B2B-04 Scheduled Paths e reguas (B2B-14, B2B-16,\n'
    + '   validade 30 dias); TEC-B2B-05 integracoes B2B (Customer Core, GIS, Econodata, Zendesk) sobre a W-000140; TEC-B2B-06 seguranca\n'
    + '   e perfis B2B (GR, SDR, BKO, Arquitetura); TEC-B2B-07 Visao 360 do grupo economico (B2B-10).\n'
    + '3. Cada work tecnica com: fundamentacao no Salesforce Help, dependencias, criterios de aceite no formato Dado/Quando/Entao,\n'
    + '   criada por script (padrao dos scripts 11/12: valida antes, cria se faltar, uma work por script).\n'
    + '\n'
    + 'DEPENDENCIAS: nomes e datas de entrada dos 3 profissionais; acessos (BTP); W-000140 para os testes.\n'
    + 'RESPONSAVEL SUGERIDO: dev lead SysMap com Davi Israel de Abreu (funcional). Estimativa: onboarding 2 dias + 1 sprint de escrita.';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Onboarding concluido',
        'que os 3 profissionais SysMap entraram no projeto',
        'o onboarding for realizado',
        'cada um tem acesso ao Agile Accelerator, GitLab e sandboxes, recebeu o pacote de docs e a planilha de cobertura, e o registro do onboarding esta nesta work'},
    new List<String>{'Lista de historias tecnicas validada',
        'que a proposta TEC-B2B-01 a 07 foi apresentada ao dev lead',
        'a lista for revisada',
        'a lista final tem codigo, titulo, historias de negocio cobertas e responsavel, sem historia tecnica duplicando fundacao ja existente nas TEC-B2C'},
    new List<String>{'Works tecnicas criadas por script',
        'que a lista foi validada',
        'os scripts de criacao forem executados',
        'cada work TEC-B2B existe no Agile Accelerator (time SysMap, epico B2B) com Details, fundamentacao, dependencias e criterios de aceite, e os numeros W ficam registrados nesta work'}
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
