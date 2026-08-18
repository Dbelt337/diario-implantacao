# -*- coding: utf-8 -*-
import sys
sys.path.insert(0,'/tmp')
import zipfile, html

def col(n):
    s=''
    while n>0:
        n,r=divmod(n-1,26); s=chr(65+r)+s
    return s

def sheet_xml(rows, widths):
    out=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
         '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">','<cols>']
    for i,w in enumerate(widths,1):
        out.append(f'<col min="{i}" max="{i}" width="{w}"/>')
    out.append('</cols><sheetData>')
    for ri,row in enumerate(rows,1):
        cells=[]
        for ci,v in enumerate(row,1):
            if v is None or v=='': continue
            t=html.escape(str(v), quote=False)
            cells.append(f'<c r="{col(ci)}{ri}" t="inlineStr"><is><t xml:space="preserve">{t}</t></is></c>')
        out.append(f'<row r="{ri}">' + ''.join(cells) + '</row>')
    out.append('</sheetData></worksheet>')
    return ''.join(out)

def build(path, sheets):
    ct=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
        '<Default Extension="xml" ContentType="application/xml"/>',
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>']
    for i in range(1,len(sheets)+1):
        ct.append(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>')
    ct.append('</Types>')
    rels=('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>')
    wb=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>']
    wbr=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
         '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">']
    for i,(name,_,_) in enumerate(sheets,1):
        wb.append(f'<sheet name="{html.escape(name)}" sheetId="{i}" r:id="rId{i}"/>')
        wbr.append(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>')
    wb.append('</sheets></workbook>'); wbr.append('</Relationships>')
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ''.join(ct))
        z.writestr('_rels/.rels', rels)
        z.writestr('xl/workbook.xml', ''.join(wb))
        z.writestr('xl/_rels/workbook.xml.rels', ''.join(wbr))
        for i,(_,rows,w) in enumerate(sheets,1):
            z.writestr(f'xl/worksheets/sheet{i}.xml', sheet_xml(rows,w))

H = ['ID','Tarefa','Dono','Tipo de Metadata','Componente / API Name (GRPQM)','O que fazer',
     'Depende de','Ref. RN / Escenario','Estado']
T=[]
def t(*r):
    assert len(r)==9, (r[0], len(r))
    T.append(list(r))
def b(n,tit): T.append([n,tit,'','','','','','',''])

b('BLOCO 0','VERIFICAR O QUE O COTIZADOR JA ENTREGA')
t('T01','Rodar o describe da integracao','OSF Salesforce','Verificacao','docs/scripts/check-hu119-integracao.apex',
  'Rodar e usar para fechar T05, T10, T12 e T30. Responde se SapStatus__c e picklist ou texto, se ha campo de correlation id, se os External Id existem, se o SapOrderResponse__e e high volume, quais objetos tem CDC ligado e se o mockMode do SapMuleClient esta desligado',
  '','Todas','A FAZER')
t('T02','Confirmar a licenca de Change Data Capture','OSF Salesforce','Verificacao','Setup, Change Data Capture',
  'CDC sem add on permite selecionar so 5 entidades. Esta HU precisa de Account, Quote, QuoteLineItem, Order, OrderItem, Vehicle, Product2 e PricebookEntry, que sao oito. Contar quantas entidades ja estao selecionadas e decidir entre comprar o add on ou usar Platform Event proprio',
  '','RN-02','BLOQUEADO')
t('T03','Medir o consumo de eventos contra a cota','OSF Salesforce','Verificacao','Platform Event allocations',
  'Cota diaria de 50 mil entregas, e entrega conta POR ASSINANTE. Estimar mudancas relevantes por dia vezes numero de assinantes antes de escolher CDC ou evento proprio',
  'T02','RN-02','A FAZER')

b('BLOCO 1','SAIDA, SALESFORCE PARA SAP')
t('T04','Decidir CDC ou Platform Event proprio','OSF Salesforce','Decision','Change Data Capture ou evento custom',
  'CDC nao exige codigo mas tem teto de entidades e publica toda mudanca. Evento proprio publicado por Flow filtra na origem e nao consome selecao de entidade, mas exige um flow por objeto. Decidir com T02 e T03',
  'T02, T03','RN-02, Escenario 1','A FAZER')
t('T05','Campos relevantes por objeto','GrupoQ','CustomMetadata','RelevantFieldByObject',
  'Carregar a lista de campos que disparam envio, por objeto e linha de negocio. A propria HU diz que sem essa lista nao e implementavel',
  'T04','RN-02','BLOQUEADO')
t('T06','Flow de publicacao por objeto','OSF Salesforce','Flow','Record triggered, after save, um por objeto',
  'Publicar o evento so quando o registro ja foi transmitido ao SAP e um campo relevante mudou. Usar ISCHANGED no criterio de entrada, que e avaliado antes do flow rodar e e barato',
  'T04, T05','RN-02, Escenario 2','A FAZER')
t('T07','Supressao de eco','OSF Salesforce','Flow','Criterio de entrada dos flows de publicacao',
  'NAO republicar quando a alteracao veio do proprio SAP. Sem isso a sincronizacao bidirecional entra em laco infinito e queima a cota de eventos. Filtrar por usuario de integracao no criterio de entrada, ou por campo de origem da ultima alteracao',
  'T06','RN-12','CRITICO, nao esta na HU')
t('T08','Publicar depois do commit','OSF Salesforce','Platform Event','Behavior do evento',
  'Configurar Publish After Commit, para o evento sair somente se a transacao gravou. Publish Immediately dispara evento de mudanca que pode nao ter sido salva',
  'T04','RN-11','A FAZER')
t('T09','Callout de saida sem Apex','OSF Salesforce','External Services','HTTP Callout mais MuleGateway',
  'Gerar a acao invocavel a partir do OpenAPI do Mule, reusando o Named Credential MuleGateway que ja existe. Usar apenas no caminho ASSINCRONO do flow, porque a plataforma bloqueia callout enquanto o registro salva',
  'T06','RN-04, RN-06','A FAZER')
t('T10','Exigir OpenAPI 2.0 ou 3.0 do Mule','OSF Mule','Contrato','Spec de cada servico',
  'External Services so funciona com REST descrito em OpenAPI 2.0 ou 3.0. Se o Mule expuser SOAP ou nao publicar spec, cai em Apex. Fixar como requisito de contrato',
  '','RN-19','A FAZER')
t('T11','Fila, ordem e reintento','OSF Mule','Integracao','Camada MuleSoft',
  'Fila por registro, ordem cronologica, politica de reintento e backoff ficam no Mule. Platform Event nao garante ordenacao entre publicacoes diferentes',
  '','RN-08, RN-09, RN-12','A FAZER')
t('T12','Correlation id no registro','OSF Salesforce','CustomField','Campo de correlation id nos objetos sincronizados',
  'Guardar o identificador de correlacao devolvido pelo Mule, para o reprocesso reusar o mesmo e o SAP nao duplicar documento. O Salesforce carrega o id, nao a garantia',
  'T09','RN-11, Escenario 7','A FAZER')

b('BLOCO 2','ENTRADA, SAP PARA SALESFORCE')
t('T13','Assinatura por Pub/Sub API','OSF Mule','Integracao','Pub/Sub API',
  'Assinar CDC e Platform Event por Pub/Sub API, que e gRPC e e onde a Salesforce investe. CometD segue suportado para o que ja existe e nao e o caminho novo',
  'T04','RN-02','A FAZER')
t('T14','External Id unico por objeto sincronizado','OSF Salesforce','CustomField','Vehicle, Account, Order, Product2, PricebookEntry',
  'Um campo unico e External Id por objeto, com a chave do SAP. Product2.SapMaterialCode__c e Order.SapOrderNumber__c ja existem. Sem External Id nao ha upsert idempotente e a consulta nao e seletiva',
  'T01','RN-11, Escenario 14','A FAZER')
t('T15','Entrada em lote por Bulk API 2.0','OSF Mule','Integracao','Upsert por External Id',
  'Inventario, catalogo, precos e promocoes entram por Bulk API 2.0 com upsert no External Id. Nao consome cota de Platform Event e e idempotente por construcao',
  'T14','RN-04, Escenario 14','A FAZER')
t('T16','Entrada unitaria por evento','OSF Salesforce','Flow','Assinante de SapOrderResponse__e',
  'Estado do pedido, faturacao, nota de credito e liberacao de credito entram pelo Platform Event que ja existe, consumido por Flow. Nao criar novo canal',
  '','RN-04, Escenario 18','JA EXISTE, estender')
t('T17','Atualizar somente campos do payload','OSF Salesforce','Flow','Assinantes de entrada',
  'Atualizar apenas os campos que vieram no lote, preservando o resto do registro. E o Escenario 15, sincronizacao incremental',
  'T16','Escenario 15','A FAZER')
t('T18','Reconciliacao para queda longa','OSF Mule','Integracao','Job de reconciliacao',
  'Evento fica no bus por 72 HORAS. Passado isso o replay por ReplayId nao recupera nada. Escenario 16 fala de varias horas, mas queda maior que 72h exige resync completo por chave. Desenhar o job, nao supor',
  'T15','Escenario 16','CRITICO, nao esta na HU')
t('T19','Frequencia dos programados parametrizavel','GrupoQ e OSF Mule','Integracao','Scheduler do Mule',
  'Definir a frequencia por interface. Hoje ha tres valores na mesma fonte, dez minutos, dez a quinze por sociedade e quinze. O parametro vive no Mule e tem que mudar sem deploy',
  '','RN-05','BLOQUEADO')
t('T20','Uma interface por pais','OSF Mule','Integracao','Segregacao por pais e sociedade',
  'A unidade reatribuida entre paises deixa de viajar pela interface de origem e passa pela do destino, sem duplicar',
  '','RN-17, Escenario 20','A FAZER')

b('BLOCO 3','ESTADO, REFRESCO E REPROCESSO')
t('T21','Separar estado de integracao de estado do documento','OSF Salesforce','CustomField','Campo de estado de integracao, picklist',
  'Sao duas coisas diferentes e a HU pede as duas. O SapStatus__c de hoje e o estado do documento no SAP. Falta o estado da integracao com os sete valores: pendente, enviado, confirmado, erro tecnico, erro funcional, reintentando e requer intervencao manual. Picklist, nao texto, para ser filtravel e reportavel',
  'T01','RN-07','A FAZER')
t('T22','Etapa operativa e ultima sincronizacao','OSF Salesforce','CustomField','Etapa operativa e data e hora da ultima sincronizacao com sucesso',
  'Cola de creditos, cola de alistamento, despachado e faturado, mais o timestamp. Sem o timestamp o usuario nao sabe se o dado e de agora ou de ontem',
  'T21','RN-07','A FAZER')
t('T23','Exibir o estado na ficha','OSF Salesforce','Dynamic Forms','Highlights Panel e pagina do registro',
  'Mostrar estado de integracao, estado no SAP, etapa e ultima sincronizacao. Sem componente proprio',
  'T22','RN-07','A FAZER')
t('T24','Acao de refresco a demanda','OSF Salesforce','Quick Action mais Flow','No documento comercial e na unidade de inventario',
  'Forcar a releitura do SAP em qualquer etapa, sem esperar o ciclo programado. Registrar usuario, data, hora e resultado. Sem LWC',
  'T09','RN-06, Escenario 8','A FAZER')
t('T25','Acao de reprocesso manual','OSF Salesforce','Quick Action mais Custom Permission','Visivel so para usuario autorizado',
  'Pedir ao Mule o reenvio COM O CORRELATION ID ORIGINAL. O Salesforce nao remonta payload, so pede reenvio, para a idempotencia continuar onde pode ser garantida',
  'T12','RN-09, Escenario 7','A FAZER')
t('T26','Mensagem de erro em linguagem compreensivel','OSF Mule','Contrato','Resposta de erro do servico',
  'O Mule devolve mensagem tratada, sem codigo tecnico nem traco de middleware. O Salesforce exibe o que recebe e nao traduz',
  'T10','RN-08, Escenario 5','A FAZER')
t('T27','Notificar o dono do documento','OSF Salesforce','Custom Notification','SapOrderAlert',
  'Notificar o responsavel quando a transacao falhar por erro funcional. O tipo de notificacao ja existe no Cotizador. Definir com o GrupoQ quem mais recebe por processo',
  'T21','RN-16','JA EXISTE, estender')
t('T28','Relatorio de documentos travados','OSF Salesforce','Report','Por estado de integracao',
  'Lista e dashboard filtrando por estado de integracao, para o seguimento de documento atascado',
  'T21','RN-07','A FAZER')

b('BLOCO 4','DESEMPENHO E RESILIENCIA')
t('T29','Flows a prova de volume','OSF Salesforce','Flow','Todos os flows de integracao',
  'Sem Get Records dentro de loop, sem callout no caminho sincrono, e criterio de entrada estreito. Flow acionado por registro roda em lote e um flow mal feito multiplica por 200',
  'T06','RN-04','A FAZER')
t('T30','Trigger Order em cada flow','OSF Salesforce','Object Manager','Trigger Order por objeto e gatilho',
  'Ordem entre flows do mesmo objeto e gatilho so e previsivel com Trigger Order definida. A org ja tem 39 automacoes',
  'T06','Governanca','A FAZER')
t('T31','Diferir recalculo de compartilhamento na carga','OSF Salesforce','Setup','Defer Sharing Calculations',
  'Ligar antes da carga inicial de inventario e catalogo e recalcular depois. E o remedio que a documentacao recomenda para atualizacao em larga escala',
  'T15','RN-18','A FAZER')
t('T32','Indice nos campos de chave','OSF Salesforce','CustomField','External Id dos objetos sincronizados',
  'Campo External Id ja e indexado, o que torna o upsert seletivo. Se algum objeto passar de centenas de milhares de registros, pedir indice custom ao Suporte',
  'T14','RN-04','A FAZER')
t('T33','Nao replicar o que so se le','OSF Salesforce','Salesforce Connect','External Object por OData',
  'Saldo, credito e informacao contabil se consultam no ERP em tempo real e nao se replicam, conforme a RN-20. External Object evita armazenamento e evita sincronizacao. Avaliar se o Mule expoe OData',
  'T10','RN-20, RN-26 da HU-017','A FAZER')
t('T34','Medir a cota antes de ligar tudo','OSF Salesforce','Verificacao','Platform Event usage',
  'Entrega conta por assinante. Ligar CDC em oito objetos com tres assinantes multiplica por tres. Medir em DEV e projetar antes de subir para producao',
  'T03','RN-04','A FAZER')

b('BLOCO 5','AJUSTES NO COTIZADOR')
t('T35','Desligar o mockMode do SapMuleClient','OSF Salesforce','ApexClass','SapMuleClient',
  'Confirmar como o mockMode se desliga e garantir que esta desligado nos ambientes que falam com o Mule de verdade. E o risco de silenciosamente nao integrar nada',
  'T01','RN-04','PENDENTE ANTIGO')
t('T36','Padronizar o estado de integracao nos objetos do Cotizador','OSF Salesforce','CustomField','Order, Quote, QuoteLineItem',
  'Aplicar o campo do T21 nos objetos que o Cotizador ja sincroniza, para o padrao ser um so em toda a org',
  'T21','RN-07','A FAZER')
t('T37','Acrescentar supressao de eco ao handler existente','OSF Salesforce','Flow','SAP_Order_Response_Handler',
  'O handler atualiza a Order com o que o SAP devolve. Quando os flows de publicacao do T06 entrarem, essa atualizacao vai republicar. Fechar o laco antes de ligar a saida',
  'T07','RN-12','CRITICO')
t('T38','Verificar o comportamento do SapOrderResponse__e','OSF Salesforce','Platform Event','SapOrderResponse__e',
  'Confirmar se e high volume, o que e o padrao desde Spring 23, e se o publish e after commit',
  'T01','RN-11','A FAZER')
t('T39','Reusar o padrao do Cotizador nos outros dominios','OSF Salesforce','Padrao','Generalizar em vez de reconstruir',
  'A ida e a volta do pedido ja rodam. Inventario, catalogo, precos e devolucoes seguem o mesmo desenho, sem inventar canal novo',
  'T16','RN-03','A FAZER')
t('T40','Novo callout entra por External Services','OSF Salesforce','Padrao','Regra de construcao',
  'Nao reescrever o SapMuleClient, que funciona. Mas todo servico novo entra por HTTP Callout e External Services, sem Apex',
  'T09','RN-19','A FAZER')

b('BLOCO 6','FECHAMENTO')
t('T41','Definir a matriz de etapas que permitem alterar','GrupoQ','Decision','Matriz de estados do documento',
  'Definir em quais estados do pedido a alteracao e permitida e sincronizavel. Sem isso o Escenario 11 nao tem regra',
  '','RN-13, Escenario 11','BLOQUEADO')
t('T42','Definir a politica de reintento','OSF Arquitetura','Decision','Numero, intervalo e estrategia de espera',
  'Declarada pendente pela propria HU. Definir com o time de Mule e registrar no contrato',
  'T11','RN-08','BLOQUEADO')
t('T43','Definir onde persiste a traca e por quanto tempo','OSF Arquitetura','Decision','Salesforce, MuleSoft ou os dois',
  'Recomendacao: so no Mule, com o Salesforce guardando correlation id e ultimo resultado. Duplicar a traca nos dois lados e o caminho para divergirem',
  '','RN-15','BLOQUEADO')
t('T44','Declarar a brecha da camada compartilhada','OSF Arquitetura','Documentacao','Risco a escrever na HU',
  'A RN-16 diz que normalizacao, autenticacao, erro, cache, log e monitoramento centralizado estao documentados SO para a camada de fabricas, e que nao ha equivalente para SAP. Essa fundacao nao esta estimada em lugar nenhum',
  '','RN-16','A DECLARAR')
t('T45','Testes dos vinte e um escenarios','OSF Salesforce','Flow Test','Testes dos flows de publicacao e de consumo',
  'Cobrir os escenarios 1 a 21 com enfase no 4, no 7, no 10, no 16 e no 21, que sao os de idempotencia, ordem, recuperacao e visibilidade',
  'T25','Todos','A FAZER')

# ------------------------------------------------- aba modelagem
HM = ['#','Limite ou padrao','Numero ou regra','Por que importa aqui']
M=[]
def m(*r):
    assert len(r)==4, (r[0], len(r))
    M.append(list(r))

m('L01','Retencao de evento no bus','72 horas',
  'Passado isso o replay por ReplayId nao recupera nada. O Escenario 16 fala de queda de varias horas, mas queda maior que 72h exige resync completo por chave')
m('L02','Cota diaria de entrega de Platform Event','50 mil por dia, mais 100 mil com add on',
  'Teto real do desenho de saida. Se estourar, a mudanca nao viaja e ninguem percebe na hora')
m('L03','Entrega conta POR ASSINANTE','1000 eventos vezes 10 assinantes igual a 10 mil entregas',
  'O numero de assinantes multiplica o consumo. Cada canal a mais custa cota')
m('L04','Publicacao por hora','250 mil por hora, mais 25 mil com add on',
  'Nao e o gargalo aqui, mas define o teto de uma carga em rajada')
m('L05','Entidades em Change Data Capture','5 sem add on de licenca',
  'Esta HU precisa de oito objetos. Ou compra o add on, ou usa Platform Event proprio publicado por Flow')
m('L06','Volume do Platform Event','Todo evento custom novo e high volume desde Spring 23',
  'Nao ha escolha de standard volume, e high volume tem entrega assincrona')
m('L07','Callout em record triggered Flow','Somente no caminho assincrono, e so em after save',
  'A plataforma bloqueia callout enquanto o registro salva. Coincide com a RN-04, que quer transacao assincrona')
m('L08','External Services','Somente REST com OpenAPI 2.0 ou 3.0',
  'SOAP ou ausencia de spec joga o desenho de volta para Apex. Vira requisito de contrato do Mule')
m('L09','Timeout de callout','Ate 120 segundos, e numero limitado por transacao',
  'Serve para refresco a demanda e consulta de preco. Nao serve para propagacao em volume')
m('L10','Entrada em lote','Bulk API 2.0 com upsert em External Id',
  'Nao consome cota de Platform Event e e idempotente por construcao. E o caminho certo para inventario e catalogo')
m('L11','Ordenacao','Platform Event nao garante ordem entre publicacoes diferentes',
  'A RN-12 pede ordem cronologica. Quem ordena e a fila do Mule, nao o Salesforce')
m('L12','Comportamento de publicacao','Publish After Commit',
  'O evento sai somente se a transacao gravou. Publish Immediately pode anunciar mudanca que nao foi salva')
m('L13','Assinatura externa','Pub/Sub API, gRPC',
  'E onde a Salesforce investe. CometD segue suportado para o que ja existe e nao e o caminho novo')
m('L14','Laco de eco','Nao ha protecao nativa',
  'Sincronizacao bidirecional sem supressao de eco entra em laco e queima a cota. Filtrar por usuario de integracao no criterio de entrada do flow')
m('L15','Recalculo de compartilhamento','Defer Sharing Calculations',
  'Carga em massa de inventario dispara recalculo. Diferir antes e recalcular depois')
m('L16','Consulta seletiva','External Id ja e indexado',
  'Upsert por External Id e seletivo. Sem chave indexada o upsert em volume degrada')
m('L17','Zero replicacao','Salesforce Connect e External Object por OData',
  'Saldo, credito e contabil se consultam e nao se replicam, o que a RN-20 exige. Depende de o Mule expor OData')

# ------------------------------------------------- aba cotizador
HC = ['#','Componente do Cotizador','O que ja cobre','O que ajustar']
C=[]
def c(*r):
    assert len(r)==4, (r[0], len(r))
    C.append(list(r))

c('C01','SapOrderResponse__e, Platform Event','Canal de entrada SAP para Salesforce','Confirmar high volume e publish after commit')
c('C02','SAP_Order_Response_Handler, Flow','Consumidor do evento, ja declarativo','Acrescentar supressao de eco antes de ligar a saida, senao entra em laco')
c('C03','Order_Facturado_Handler, Flow','Escenario 18, faturado dispara entrega e milestone','Acrescentar a notificacao a Tramites e gerencia, que a HU pede')
c('C04','Order.SapStatus__c','Estado do documento no SAP','Nao e o estado da integracao. Falta o campo dos sete estados, e como picklist')
c('C05','Order.SapOrderNumber__c','Chave do documento no SAP','Marcar como External Id unico, para o upsert ser idempotente')
c('C06','Order.SapInvoiceNumber__c e SapInvoiceDate__c','Faturacao','Nada, cobre')
c('C07','QuoteLineItem.AvailabilityStatus__c e AvailabilityDetail__c','Padrao de persistir o que o SAP devolve','Reusar o mesmo padrao nos outros dominios')
c('C08','Product2.SapMaterialCode__c','Chave do material','Confirmar se e unico e External Id')
c('C09','MuleGateway e MuleSoft_EC','Named Credential e External Credential','Reusar em External Services, sem criar outra credencial')
c('C10','PS_Mule_Integration','Permissao de integracao','Revisar o acesso do usuario de integracao contra as sharing rules da HU-017')
c('C11','SapOrderAlert, Custom Notification Type','Canal de notificacao da RN-16','Estender para os outros dominios em vez de criar tipo novo')
c('C12','Generar_Pedido_SAP e Quote_Aceptada_Genera_Pedido, Flows','Ida do pedido, automatica e por botao','Acrescentar o correlation id e o estado de integracao')
c('C13','SapMuleClient, ApexClass','Cliente HTTP do Mule','Nao reescrever, funciona. Mas confirmar como o mockMode se desliga, e todo servico novo entra por External Services')
c('C14','Nenhum campo de correlation id','','Criar. Sem ele o reprocesso do Escenario 7 duplica documento no SAP')
c('C15','Nenhum timestamp de ultima sincronizacao','','Criar. Sem ele o usuario nao sabe se o dado e de agora ou de ontem')

TIT = 'HU-119 - Tarefas Tecnicas - Integracion SAP MuleSoft, sincronizacion automatica. Coluna Dono separa Salesforce, MuleSoft e GrupoQ'
TM  = 'HU-119 - Modelagem, limites e numeros que decidem o desenho'
TC  = 'HU-119 - O que o Cotizador ja entrega e o que ajustar nele'
build('/home/user/diario-implantacao/docs/hu119/HU119_Tarefas_Tecnicas.xlsx',
      [('Tarefas', [[TIT],[''],H]+T, [8,46,18,22,46,90,14,26,20]),
       ('Modelagem e Limites', [[TM],[''],HM]+M, [8,42,44,92]),
       ('Ajustes no Cotizador', [[TC],[''],HC]+C, [8,44,44,84])])
print('tarefas:', len([r for r in T if r[0].startswith('T')]), '| limites:', len(M), '| cotizador:', len(C))
