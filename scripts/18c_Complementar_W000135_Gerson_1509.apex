// 18c - Complementa a work W-000135 (aberta pelo Gerson em 15/09 10:27 com Details vazio, log do script 15). Uma work por script.
// Idempotente: so grava Details se estiver vazio; so cria criterios se a work nao tiver nenhum; nao mexe em Subject, time, sprint
// nem responsavel. Trava: so roda se o Subject comecar com o prefixo esperado. Filtre o log por CMP18|.
String NOME = 'W-000135';
String PREFIXO = 'INTEGRAÇÕES - MuleSoft';
List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name,
                                    agf__Assignee__r.Name, agf__Epic__r.Name
                             FROM agf__ADM_Work__c WHERE Name = :NOME LIMIT 1];
if (ws.isEmpty()) { System.debug('CMP18| ' + NOME + ' NAO ENCONTRADA - nada feito'); return; }
agf__ADM_Work__c w = ws[0];
if (w.agf__Subject__c == null || !w.agf__Subject__c.startsWith(PREFIXO)) { System.debug('CMP18| ' + NOME + ' SUBJECT DIFERENTE DO ESPERADO - nada feito: ' + w.agf__Subject__c); return; }
System.debug('CMP18| ' + w.Name + ' | ' + w.agf__Subject__c + ' | time=' + w.agf__Scrum_Team__r.Name + ' | epic=' + w.agf__Epic__r.Name
    + ' | sprint=' + w.agf__Sprint__r.Name + ' | assignee=' + w.agf__Assignee__r.Name + ' | details=' + (w.agf__Details__c == null ? 0 : w.agf__Details__c.length()));

String det =
      'Work tecnica de Brasil TecPar (epico Integracao, Barramento (MuleSoft) e CI/CD). Complementada em 15/09.\n'
    + '\n'
    + 'OBJETIVO\n'
    + 'Fechar duas frentes do barramento: (1) obter da MuleSoft/parceiro o orcamento da avaliacao de arquitetura (architect assessment)\n'
    + 'solicitada, com escopo, prazo e valor; (2) inventariar as demandas de integracao que as works do projeto ja exigem do\n'
    + 'barramento, com dono, status e work de origem, para priorizar por sprint e evitar que cada squad abra integracao por conta.\n'
    + '\n'
    + 'INVENTARIO INICIAL DE DEMANDAS DO BARRAMENTO (extraido das works, 15/09)\n'
    + '1. Customer Core: endpoint proprietario via MuleSoft para cliente, contrato, vigencia e ativacao (decisao de 04/09; W-000087\n'
    + '   TEC-B2C-04 Named Credentials e mapa de capacidades; W-000080 B2C-23; W-000142 B2B-13 sincronizacao de vigencia).\n'
    + '2. Canal de eventos de contrato Salesforce -> MuleSoft (W-000105 TEC-INT-01).\n'
    + '3. SAP: materiais, centro de lucro e faturamento, acionado na decomposicao do OM e nao na venda (W-000070 decisao P-16;\n'
    + '   W-000050; W-000044).\n'
    + '4. GIS/Radar: viabilidade tecnica por CEP/coordenada e tecnologia de acesso (W-000045, W-000047, W-000097 B2B-02, W-000074).\n'
    + '5. Zendesk: tickets de debito interno, trouble tickets por etiqueta RGC (W-000067, W-000050, W-000104).\n'
    + '6. Econodata: enriquecimento de leads B2B (W-000096 B2B-01).\n'
    + '7. Fornecedores de SVA e mapeamento de IDs (W-000110 TEC-INT-02).\n'
    + '8. Gerador de etiquetas RGC do Customer Core (W-000050, W-000104 CAT-TAG-01).\n'
    + '9. Recepcao inbound de vendas digitais / Touchless Order API (W-000075 B2C-18).\n'
    + 'Marketing Cloud usa Marketing Cloud Connect e nao passa pelo barramento (W-000092).\n'
    + '\n'
    + 'ENTREGAS\n'
    + '- Orcamento da avaliacao do arquiteto recebido e registrado (anexo ou link) com decisao de contratacao do gestor.\n'
    + '- Planilha/pagina de inventario com: demanda, sistema, direcao, padrao (TMF ou proprietario), work de origem, squad, status,\n'
    + '  dependencia de ambiente (homologacao MuleSoft), prioridade por sprint.\n'
    + '- Lista do que ja existe no barramento hoje (APIs publicadas, ambientes, credenciais) x o que precisa ser construido.\n'
    + '\n'
    + 'DEPENDENCIAS: retorno comercial MuleSoft/parceiro; W-000136 (arquitetura das APIs B2B) alimenta o inventario; W-000140 depende\n'
    + 'dos endpoints de homologacao listados aqui.\n'
    + 'RESPONSAVEL SUGERIDO: Gerson Da Silva Pereira (orcamento) e Thiago Campos Almeida (inventario tecnico). Estimativa: 1 sprint.';

List<List<String>> crits = new List<List<String>>{
    new List<String>{'Orcamento registrado',
        'que a avaliacao do arquiteto MuleSoft foi solicitada',
        'o orcamento for recebido',
        'escopo, prazo, valor e condicao ficam registrados nesta work com a decisao do gestor (aprovado, negociar ou recusado) e a data'},
    new List<String>{'Inventario de demandas publicado',
        'que as works do projeto citam integracoes via barramento',
        'o inventario for consolidado',
        'cada demanda tem sistema, direcao, padrao, work de origem, squad, status e prioridade, e nenhuma integracao citada nas works fica fora da lista'},
    new List<String>{'Existente x a construir',
        'que o inventario esta publicado',
        'for confrontado com as APIs ja publicadas no barramento',
        'a lista marca o que ja existe (com ambiente e credencial) e o que precisa ser construido, com dono e sprint alvo'}
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
