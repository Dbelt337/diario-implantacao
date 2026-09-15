// 18e - Complementa a work W-000137 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000137';
String PREFIXO = 'ARQUITETURA - Finalizar decomposição';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work tecnica de Brasil TecPar (epico Arquitetura da Solucao e Ambientes). Complementada em 15/09. E a pendencia P5 da\n'
    + 'Modelagem v3 (camada tecnica CFS/RFS/Recurso e decomposicao, SysMap com OM), referenciada na consolidacao das W-000051/52/55.\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Fechar a camada tecnica do catalogo e as regras de decomposicao para a familia Conectividade (v0), para que a arvore comercial\n'
    + '(EPC-04, W-000052 e filha Conectividade) tenha o seu par tecnico e o Order Management consiga decompor e orquestrar o pedido.\n'
    + '\n'
    + 'PREMISSAS JA DECIDIDAS\n'
    + '- A arvore comercial e so a Especificacao de Oferta; Especificacao de Produto, Servico (CFS e RFS) e Recurso vivem no catalogo\n'
    + '  compartilhado e sao ligadas por relacoes de decomposicao (W-000041 RN-07; W-000044 Offer x Specification, Orderable so na\n'
    + '  oferta; W-000088 TEC-B2C-05 decomposicao e plano de orquestracao; W-000112 CAT-CHD-01 filhos).\n'
    + '- Integracao SAP de materiais acontece na decomposicao/fulfillment, nao na venda (W-000070 decisao P-16); o de-para de material\n'
    + '  SAP dos 16 filhos e a pendencia P6 (Rodrigo/fiscal).\n'
    + '- Sem uso de recurso Beta (Offer Specification Realization) em producao (W-000044).\n'
    + '- Order Management sem licenca ativa em producao (W-000134): a modelagem pode ser feita e testada em sandbox apos o ajuste.\n'
    + '\n'
    + 'ESCOPO\n'
    + '1. Para cada uma das 11 ofertas e 16 filhos da v3: product spec > CFS > RFS > recurso (CPE, porta, servico de rede, servico no\n'
    + '   fornecedor), com cardinalidades e atributos que descem para o OM.\n'
    + '2. Decomposition rules (mapeamento de atributos comerciais para tecnicos) e cenarios de orquestracao: venda nova, upgrade logico\n'
    + '   sem visita, troca de CPE com Field Service (W-000049 cenario 3), cancelamento.\n'
    + '3. Ponto de chamada SAP e Customer Core em cada cenario, alinhado com a W-000136.\n'
    + '4. Documento de modelagem tecnica (planilha + diagrama) revisado com SysMap e engenharia (Joel), e ADR.\n'
    + '\n'
    + 'DEPENDENCIAS: P6 (materiais SAP, Rodrigo); W-000136; W-000134 para teste em sandbox; grade do Joel para as outras familias.\n'
    + 'RESPONSAVEL SUGERIDO: arquiteto SysMap (OM) com Diego (governanca). Estimativa: 2 sprints (v0 Conectividade).';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Camada tecnica da Conectividade modelada',
        'que as 11 ofertas e 16 filhos da Modelagem v3 estao aprovados',
        'o documento de modelagem tecnica for concluido',
        'cada oferta tem a cadeia product spec, CFS, RFS e recurso com cardinalidades e atributos, sem uso de recurso Beta, e o documento esta anexado a esta work'},
    new List<String>{'Regras de decomposicao definidas',
        'que a camada tecnica esta modelada',
        'as decomposition rules forem listadas',
        'cada atributo comercial que o OM precisa tem mapeamento para o atributo tecnico, e nenhuma oferta fica sem regra'},
    new List<String>{'Cenarios de orquestracao',
        'que as regras estao definidas',
        'os cenarios venda nova, upgrade logico, troca de CPE e cancelamento forem descritos',
        'cada cenario indica as tarefas, o ponto de chamada SAP e Customer Core e quando abre tarefa de Field Service, alinhado ao fluxo da W-000136'},
    new List<String>{'Validacao em sandbox',
        'que preprod tem licenca de OM (W-000134) e o catalogo v0 carregado',
        'um pedido de Smart Internet Corporativa for submetido',
        'o pedido decompoe na cadeia modelada e o plano de orquestracao e gerado sem erro, com evidencia anexada'}
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
