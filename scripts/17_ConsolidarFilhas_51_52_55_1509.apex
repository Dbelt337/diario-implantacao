// 17 - Consolida nas works-mae de catalogo (W-000051 EPC-01, W-000052 EPC-04, W-000055 EPC-03) o conteudo das duas works
// que o Gerson abriu em 15/09 (W-000138 "Ajustar US 51/52/55 em US filhas por familia" e W-000139 "Consolidar estrutura de
// conectividade e template de produto; pendencias Joel/Rodrigo/OM"), que estavam com Details vazio (log do script 15).
// Condicao do Gerson para a exclusao: ficar na sprint e na squad certa -> as tres works vao para a sprint das works dele.
// Idempotente: so anexa a nota se o marcador ainda nao existir; so troca a sprint se estiver diferente. Filtre o log por CON17|.
// Rodar ANTES do script 14 com EXCLUIR = true.
String SPRINT = 'Sprint 1 - SysMap (15-26/09)';
String MARCA = '--- CONSOLIDACAO 15/09: FILHAS POR FAMILIA (Modelagem v3; absorve W-000138 e W-000139) ---';

String comum =
      '\n\n' + MARCA + '\n'
    + 'Origem: e-mail do Davi (SysMap) de 14/09 14:58 e resposta de governanca de 14/09 18:01; works W-000138 e W-000139 abertas '
    + 'pelo Gerson em 15/09 e consolidadas aqui com autorizacao dele (chat de 15/09), mantendo sprint e squad.\n'
    + 'Regra: esta work e a MAE. Nao se abre work nova para ela: ela recebe works FILHAS por FAMILIA (Conectividade, Adicional, '
    + 'Equipamento Gerenciado), nunca por oferta. A primeira filha e a de Conectividade (v0 = ofertas de conectividade da grade do '
    + 'Joel, Modelagem_Conectividade_v3_BTP_1409.xlsx). Voz, TV, Wi-Fi e Dispositivos e SVA seguem o mesmo padrao quando chegarem '
    + 'as grades do Joel e a frente Rodrigo/Varejo.\n'
    + 'Ajustes de governanca sobre a v3 (14/09): (1) um produto tem um unico Object Type: 9 produtos Conectividade, um por oferta, '
    + 'sem override por bundle; (2) arvore em dois niveis: de 17 tipos para 3 familias; (3) tipos de oferta sem atributo saem e viram '
    + 'Catalogo/Categoria e Familia do Product2; o tipo base de oferta carrega Prazo de Contrato, Modalidade de Pagamento, Tipo de '
    + 'Negociacao e Marca; (4) "Nenhum"/"Desativado" viram cardinalidade minima zero e saem das picklists; (5) preco por atributo '
    + 'com matriz (Fibra Ponto a Ponto, blocos IPv4, Banda, nivel de NOC), sem regra de preco zerando valor.\n'
    + 'Pendencias que travam a filha de Conectividade (dono): P1 Prazo de Contrato na oferta ou no componente (Joel); P2 valores dos '
    + 'adicionais por oferta ou lista unica (Joel); P3 cardinalidade da Locacao de Roteador (Joel); P4 precos das outras 10 ofertas '
    + '(Joel); P5 camada tecnica CFS/RFS/Recurso e decomposicao (SysMap com OM, tratada na W-000137); P6 codigo SAP, descricao e '
    + 'documento fiscal dos 16 filhos (Rodrigo/fiscal); P7 anomalia NOC sem cabecalho no Servico VPN (Joel); P8 valores de Marca, '
    + 'Tipo de Negociacao e ofertas com Taxa Unica (Comercial). A filha tramita quando P1 e P2 forem respondidas.\n'
    + 'Achado na v3: ATR_PRAZO_CONTRATO (aba Atribuicao por Produto) x ATR_PRAZO_DE_CONTRATO (aba Picklists); corrigir antes do '
    + 'template de carga (W-000102 CAT-TPL-01).\n';

Map<String, String> especifico = new Map<String, String>{
    'W-000051' => 'Filha EPC-01 Conectividade (categorias da familia): categorias dos 25 atributos da v3 (Leia-me e aba Atribuicao '
                + 'por Produto), confrontadas com a taxonomia CAT_ de 8 categorias desta work; toda categoria nova entra por aqui.',
    'W-000052' => 'Filha EPC-04 Conectividade (hierarquia e atribuicao): aba Hierarquia OT (OT_OFFER_BASE > OT_OFFER_CONECTIVIDADE / '
                + 'OT_OFFER_EQUIP_GERENCIADO; OT_PROD_BASE > OT_PROD_CONECTIVIDADE / OT_PROD_ADICIONAL / OT_PROD_EQUIP_GERENCIADO) e '
                + 'aba Atribuicao por Produto (herdado x atribuido no produto, valores habilitados e ocultos). Conflito a registrar: a '
                + 'W-000041 (revisao 10/09) poe Codigo SAP e Descricao Fiscal como atributos do tipo base; na v3 sao campos do Product2 '
                + 'e os transversais ficam no tipo base de OFERTA.',
    'W-000055' => 'Filha EPC-03 Conectividade (dicionario de atributos): 25 atributos ATR_* com picklists PL_* da aba Picklists; 4 '
                + 'transversais no tipo base de oferta, 11 no tipo Conectividade, 1 por adicional; os de Firewall/Wi-Fi atribuidos no '
                + 'produto. Metadados de governanca (escopo, dono, versao) valem para a filha.'
};

List<agf__ADM_Sprint__c> sps = [SELECT Id, Name FROM agf__ADM_Sprint__c WHERE Name = :SPRINT LIMIT 1];
if (sps.isEmpty()) { System.debug('CON17| SPRINT NAO ENCONTRADA: ' + SPRINT + ' - nada alterado'); return; }
Id sprintId = sps[0].Id;

List<agf__ADM_Work__c> ws = [SELECT Id, Name, agf__Subject__c, agf__Details__c, agf__Sprint__c, agf__Sprint__r.Name, agf__Scrum_Team__r.Name
                             FROM agf__ADM_Work__c WHERE Name IN ('W-000051', 'W-000052', 'W-000055') ORDER BY Name];
if (ws.size() != 3) { System.debug('CON17| ESPERAVA 3 works, achou ' + ws.size() + ' - nada alterado'); return; }
List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : ws) {
    String det = w.agf__Details__c == null ? '' : w.agf__Details__c;
    Boolean mudou = false;
    if (!det.contains(MARCA)) { w.agf__Details__c = det + comum + especifico.get(w.Name); mudou = true; }
    if (w.agf__Sprint__c != sprintId) { w.agf__Sprint__c = sprintId; mudou = true; }
    System.debug('CON17| ' + w.Name + ' | time=' + w.agf__Scrum_Team__r.Name + ' | sprint antes=' + w.agf__Sprint__r.Name
        + ' | nota ' + (det.contains(MARCA) ? 'JA EXISTIA' : 'ANEXADA') + ' | details ' + det.length() + ' -> ' + w.agf__Details__c.length()
        + ' | ' + (mudou ? 'ATUALIZA' : 'SEM MUDANCA'));
    if (mudou) upd.add(w);
}
if (!upd.isEmpty()) update upd;
for (agf__ADM_Work__c w : [SELECT Name, agf__Sprint__r.Name, agf__Details__c FROM agf__ADM_Work__c WHERE Name IN ('W-000051', 'W-000052', 'W-000055') ORDER BY Name]) {
    System.debug('CON17| DEPOIS ' + w.Name + ' | sprint=' + w.agf__Sprint__r.Name + ' | nota=' + (w.agf__Details__c.contains(MARCA) ? 'OK' : 'FALTA'));
}
System.debug('CON17| concluido: ' + upd.size() + ' work(s) atualizada(s). Agora rode o script 14 com EXCLUIR = true.');
