# -*- coding: utf-8 -*-
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

# =============================================================== TAREFAS
H = ['ID','Tarefa','Tipo de Metadata','Componente / API Name (GRPQM)','O que fazer',
     'Depende de','Ref. HU / RN','Estado']
T=[]
def t(*r):
    assert len(r)==8, (r[0], len(r))
    T.append(list(r))
def b(n,tit): T.append([n,tit,'','','','','',''])

b('BLOCO 0','VERIFICAR AS COLUNAS QUE JA EXISTEM')
t('T01','Verificar as colunas padrao dos documentos','Verificacao','docs/scripts/check-hu064-columnas-estandar.apex',
  'Rodar e confirmar tipo, calculado e gravavel de cada coluna padrao de Quote, QuoteLineItem, Order e OrderItem, mais os valores de Quote.Status e onde mora o custo. Usar o resultado para fechar T14, T15, T20 e T35',
  '','RN4, RN6, RN10','A FAZER')
t('T02','Abrir as duas matrizes que ja existem','Verificacao','docs/scripts/check-hu064-matrices.apex',
  'Rodar e listar colunas e linhas de MatrizPisosPorRol e Discount_Rules_GrupoQ. Decidir se alguma ja e a escala da RN5 antes de criar tabela',
  '','RN4, RN5','A FAZER')

b('BLOCO 1','ESCALA POR JERARQUIA, AUTOS E MOTOS')
t('T03','Confirmar a granularidade da escala','Decision','Marca e sociedade, ou marca, modelo e sociedade',
  'Perguntar ao GrupoQ. 23 marcas por 14 sociedades da 322 linhas. 229 definicoes de modelo por 14 sociedades passa de 3000. Esse numero decide entre Custom Metadata e matriz',
  'T02','RN5','BLOQUEADO')
t('T04','Definir a tabela da escala','CalculationMatrix ou CustomMetadata','DiscountScale',
  'Chave marca, modelo e sociedade. Saida: percentual por nivel, um jogo normal e um exonerado, mais estado ativo. Reusar MatrizPisosPorRol se as colunas servirem',
  'T02, T03','RN5, RN13','A FAZER')
t('T05','Usar a marca padrao como chave','Reuso','Product2.BusinessBrandId e BusinessBrand',
  'Apontar a chave de marca para o lookup padrao do Automotive, que ja tem 23 marcas carregadas. Nao criar campo nem texto de marca',
  'T04','RN5','A FAZER')
t('T06','Usar VehicleDefinition como chave de modelo','Reuso','VehicleDefinition',
  'Apontar a chave de modelo para o objeto padrao, que ja tem 229 registros. Nao criar campo de modelo',
  'T04','RN5','A FAZER')
t('T07','Usar Sociedad_Config__mdt como chave de sociedade','Reuso','Sociedad_Config__mdt',
  'Apontar a chave de sociedade para o metadata que ja existe, com 14 registros. Nao criar uma quarta fonte de sociedade',
  'T04','RN5','A FAZER')
t('T08','Carregar os percentuais da tabela do GrupoQ','Dados','Linhas da tabela do T04',
  'Carregar o Porcentaje Descuento.xlsx por marca, modelo e sociedade, com os dois jogos de percentuais e o estado ativo ou inativo',
  'T04','RN5, RN13','A FAZER')
t('T09','Permission set de manutencao da escala','PermissionSet','DiscountScaleAdministration',
  'Dar edicao da escala so aos perfis de negocio autorizados',
  'T04','RN5','A FAZER')

b('BLOCO 2','NIVEL DO USUARIO E RANGO DO ROL')
t('T10','Definir qual role e o Gerente de Ventas','Decision','UserRole',
  'Perguntar ao GrupoQ. A org tem Gerente de Sucursal por sucursal, Gerente Ventas Online por pais, Gerente de Pais e Gerente de Usados. Nenhum se chama Gerente de Ventas',
  '','RN5','BLOQUEADO')
t('T11','Definir onde entra a Vicepresidencia','Decision','UserRole',
  'Perguntar ao GrupoQ. Nao existe role de Vicepresidencia. O mais alto e Gerente Regional Centroamerica, depois CEO GrupoQ e GrupoQ Holding',
  '','RN5','BLOQUEADO')
t('T12','Mapear role para nivel da escala','CustomMetadata','DiscountLevelByRole',
  'Mapear cada UserRole para um dos quatro niveis. Nao ler a hierarquia de Roles direto, que ja serve ao compartilhamento, e colapsar a dimensao sucursal, que a escala nao tem',
  'T10, T11','RN4, RN5','A FAZER')
t('T13','Calcular os pisos por nivel','ExpressionSet','Passo no pricing procedure',
  'Aplicar cada percentual da escala sobre PricebookEntry.PrecioMinimoAsesor__c, ou sobre PrecioExoneradoMinimo__c se o negocio for exonerado. Todos os niveis sobre a mesma base, nunca em cascata',
  'T04, T12','RN5, Escenario 5','A FAZER')

b('BLOCO 3','DESCONTO NO DOCUMENTO')
t('T14','Usar o Discount padrao da linha de cotizacion','Reuso','QuoteLineItem.Discount',
  'Guardar o desconto manual por linha no campo padrao percentual. Nao criar campo de desconto na linha',
  'T01','RN6, Escenario 16','A FAZER')
t('T15','Usar os campos de preco padrao da linha','Reuso','QuoteLineItem: ListPrice, UnitPrice, Subtotal, TotalPrice',
  'ListPrice vem da PricebookEntry e Subtotal e TotalPrice sao calculados. Nao criar campos de preco de lista, subtotal nem total',
  'T01','RN6','A FAZER')
t('T16','Resolver o desconto de cabecalho de Autos','Decision','Discount Distribution Service, ou campo em Quote',
  'Quote.Discount e derivado das linhas e nao recebe escrita. Avaliar o Discount Distribution Service, que aplica desconto no cabecalho e distribui pelas linhas, antes de criar campo proprio',
  'T01','RN6, GQ-CA-01-064','A FAZER')
t('T17','Desconto na linha do pedido','CustomField','OrderItem, campo de percentual de desconto',
  'OrderItem nao tem Discount padrao. Criar so depois que o T01 confirmar, e com o mesmo nome e tipo do padrao da cotizacion',
  'T01','Escenario 17','A FAZER')
t('T18','Usar o elemento Manual Discount do procedure','ExpressionSet','Passo Manual Discount no pricing procedure',
  'Aplicar o desconto digitado na linha pelo elemento nativo do motor de precos, em vez de calcular em Apex',
  'T14','RN4','A FAZER')

b('BLOCO 4','CASHBACK')
t('T19','Usar os campos de cashback da entrada de preco','Reuso','PricebookEntry: AplicaCashback__c, MontoCashback__c, VigenciaDesde__c',
  'Ler o montante, a bandeira e a vigencia dos campos que ja existem. Nao criar nada na lista de precos',
  '','RN11','A FAZER')
t('T20','Campo de cashback no documento','CustomField','Quote, campo de montante de cashback',
  'Guardar o montante que o assessor destinou a cashback. Nao ha coluna padrao para isto',
  'T19','RN11','A FAZER')
t('T21','Consolidar desconto mais cashback','ExpressionSet','Passo de consolidacao no procedure',
  'Somar desconto e cashback e avaliar a soma contra o piso do nivel, nunca cada um separado. Registrar os dois valores separados',
  'T13, T20','RN11, Escenario 8','A FAZER')

b('BLOCO 5','VALIDACAO E ALERTA')
t('T22','Avaliar Quote.Status antes de criar campo de autorizacao','Decision','Quote.Status',
  'Ver no T01 se ja ha valor que sirva para requiere autorizacion. Se a picklist for restrita, acrescentar valor proprio faz a funcionalidade padrao ver algo que nao conhece',
  'T01','Escenario 2','A FAZER')
t('T23','Passo de validacao contra o piso','ExpressionSet','Passo final do pricing procedure',
  'Comparar desconto mais cashback contra o piso do nivel do usuario e marcar a condicao quando exceder',
  'T13, T21','RN4, Escenario 2','A FAZER')
t('T24','Definir se a advertencia bloqueia','Decision','',
  'Perguntar ao GrupoQ. O Escenario 3 diz que impede continuar ate a aprovacao. O Flujo 7 diz que nao bloqueia e que so o envio e a impressao ficam bloqueados. Sao comportamentos opostos no mesmo gatilho',
  '','Escenario 3, Flujo 7','BLOQUEADO')
t('T25','Alerta sem expor o montante limite','LWC ou Flow','Aviso na tela de cotizacion',
  'Informar apenas que o desconto excede o permitido para o rol. Em Autos e Motos nunca mostrar o montante limite',
  'T23','RN4','A FAZER')
t('T26','Alerta de configuracao ausente ou inativa','Flow','',
  'Se nao houver registro ativo para a combinacao de marca, modelo e sociedade, informar a condicao e impedir desconto abaixo do Precio Minimo de Asesor, sem assumir valor por defeito',
  'T04','Escenarios 9 e 10','A FAZER')
t('T27','Alerta de cliente sem grupo ou canal','Flow','',
  'Informar a ausencia do dado. O motor detecta ausencia, nao valida se a atribuicao esta correta',
  '','Escenario 21','A FAZER')
t('T28','Alerta de regra vencida','Flow','',
  'Informar ao vendedor que a regra de desconto ou de preco esta vencida e seguir para a proxima regra vigente',
  '','Escenario 20','A FAZER')

b('BLOCO 6','REPUESTOS E PA')
t('T29','Exibir o preco construido pelo SAP sem recalcular','ApexClass','SapMuleClient e tela de linhas',
  'Mostrar o preco com as condicoes do esquema ZGQREF ja incorporadas. Salesforce nao recalcula nem persiste os codigos de condicao',
  '','RN3, Escenario 13','A FAZER')
t('T30','Resolver como o Salesforce sabe de ZRMA e ZREC','Decision','Contrato da resposta do MuleSoft',
  'Pedir ao time de Mule uma bandeira na resposta. A RN3 diz que o Salesforce nao ramifica por codigo do SAP, mas a RN7 e a RN14 exigem comportamento diferente para ZRMA, que retira todos os descontos, e para ZREC, que soma',
  '','RN3, RN7, RN14','BLOQUEADO')
t('T31','Avaliar so o desconto manual, linha a linha','ExpressionSet','Passo de validacao',
  'Avaliar cada linha de forma independente contra o rango do rol e marcar a condicao so na linha que excede',
  'T23','Escenario 16','A FAZER')
t('T32','Precedencia entre automatico e manual','ExpressionSet','Passo de precedencia',
  'Selecionar uma so regra, a de maior percentual, e descartar a outra. Nunca somar descontos',
  'T31','RN7, Escenarios 15 e 24','A FAZER')
t('T33','Desconto de lealdade apenas informado','ApexClass','Tela de linhas',
  'Informar a condicao, nao expor o desconto no documento comercial e nao avaliar contra o rango do rol nem enviar a aprovacao',
  'T29','RN14, Escenario 25','A FAZER')
t('T34','Reconsulta ao trocar o indicador fiscal','ApexClass','RepuestosLineService',
  'Disparar reconsulta de todas as linhas ao SAP quando o indicador mudar em Repuestos. Em Autos disparar recalculo local',
  'T29','FA-04, Escenario 15','A FAZER')
t('T35','Rodar o motor tambem sobre o pedido','ExpressionSet','Mesmo pricing procedure em Order',
  'Resolver o desconto direto no pedido, com a mesma configuracao, quando nao existir cotizacion previa',
  'T18','Escenario 17','A FAZER')
t('T36','Nao recalcular por condicao de pagamento, retencao ou moeda','ExpressionSet','Passo de determinacao',
  'Conservar o desconto ja calculado quando mudarem esses tres. Nao sao criterios de determinacao',
  'T31','Escenario 18','A FAZER')

b('BLOCO 7','MARGEM E RASTREABILIDADE')
t('T37','Definir onde mora o custo estimado','Decision','PricebookEntry ou Product2',
  'Nao ha campo de custo em Product2, PricebookEntry, Vehicle nem Asset. Definir onde mora e de onde vem antes de criar. Em Autos exonerados o custo e o do veiculo exonerado',
  'T01','RN10','A FAZER')
t('T38','Campo de custo e campo de margem','CustomField','Campo de custo no T37 e margem na linha',
  'Criar o campo de custo definido no T37 e o campo de margem calculado sobre ele',
  'T37','RN10','A FAZER')
t('T39','Esconder custo e margem do assessor','PermissionSet mais FLS','',
  'Deixar custo e margem invisiveis ao assessor. A exibicao ao aprovador e da HU-065',
  'T38','RN10','A FAZER')
t('T40','Campos de rastreabilidade do desconto','CustomField','QuoteLineItem: origem do desconto e regra aplicada',
  'Registrar a origem, automatico ou manual, e a regra ou escalao que determinou o valor. Desconto e cashback registrados separados',
  'T14','RN13','A FAZER')
t('T41','Registrar as regras descartadas','Reuso','Nebula Logger',
  'Registrar qual regra aplicou e quais foram descartadas no Nebula Logger, que ja esta instalado. Nao criar campo de log',
  'T32','Escenarios 15 e 24','A FAZER')

b('BLOCO 8','FECHAMENTO')
t('T42','Reusar o processo de aprovacao ja ativo','Reuso','DiscountApproval em Quote',
  'Partir do processo que ja esta ativo. Antes de redesenhar, levantar por que GQ_Discount_Approval e GQ_Discount_Approval_Chain em Opportunity ficaram obsoletos',
  '','RN4, HU-065','A FAZER')
t('T43','Reusar Aprobador_Config__mdt','Reuso','Aprobador_Config__mdt',
  'Usar o metadata de aprovador que ja existe antes de criar outro',
  'T42','HU-065','A FAZER')
t('T44','Trigger Order nos flows criados','Object Manager','Trigger Order de cada flow novo',
  'Definir a Trigger Order em cada flow que esta HU criar em Quote e Order',
  '','Governanca','A FAZER')
t('T45','Traduzir os rotulos para espanhol','Translation','Translation Workbench',
  'Traduzir campos, valores de picklist e mensagens de alerta criados nesta HU',
  'T25','Convencao GRPQM','A FAZER')
t('T46','Testes dos vinte e seis escenarios','ApexClass','Testes do procedure',
  'Cobrir os escenarios 1 a 26, com um caso por nivel da escala e um por sociedade',
  'T23, T32','Todos','A FAZER')

# =============================================================== COLUNAS
HC = ['Objeto','Coluna padrao','Tipo','Para que serve na HU','Reuso ou criacao','Nota']
C=[]
def c(*r):
    assert len(r)==6, (r[0], len(r))
    C.append(list(r))

c('QuoteLineItem','Discount','Percent','Desconto manual por linha, RN6 e Escenario 16','REUSAR','Gravavel. E o campo natural do desconto manual')
c('QuoteLineItem','ListPrice','Currency','Precio de Lista da linha','REUSAR','Somente leitura, vem da PricebookEntry')
c('QuoteLineItem','UnitPrice','Currency','Precio negociado da linha','REUSAR','Gravavel. E onde o preco final por unidade fica')
c('QuoteLineItem','Subtotal','Currency','Subtotal antes do desconto','REUSAR','Calculado, UnitPrice vezes Quantity')
c('QuoteLineItem','TotalPrice','Currency','Total da linha com desconto','REUSAR','Calculado')
c('QuoteLineItem','Quantity','Double','Quantidade, base do desconto por volume','REUSAR','')
c('QuoteLineItem','Description','TextArea','Justificativa do desconto na linha','AVALIAR','Ver se o negocio precisa de campo proprio ou se este serve')
c('Quote','Discount','Percent','Desconto do documento em Autos, RN6','NAO SERVE','Derivado das linhas e somente leitura. Nao recebe desconto de cabecalho')
c('Quote','Subtotal','Currency','Subtotal do documento','REUSAR','Calculado')
c('Quote','TotalPrice','Currency','Total do documento','REUSAR','Calculado')
c('Quote','GrandTotal','Currency','Total com impostos e frete','REUSAR','Calculado')
c('Quote','Status','Picklist','Condicao requiere autorizacion, Escenario 2','AVALIAR PRIMEIRO','Ver no T01 se ja ha valor que sirva antes de criar campo')
c('Quote','ExpirationDate','Date','Vigencia do documento','REUSAR','')
c('Quote','Pricebook2Id','Lookup','Lista de precos vigente, premissa da HU-038','REUSAR','')
c('OrderItem','UnitPrice','Currency','Preco da linha do pedido','REUSAR','')
c('OrderItem','ListPrice','Currency','Precio de Lista da linha do pedido','REUSAR','Somente leitura')
c('OrderItem','TotalPrice','Currency','Total da linha do pedido','REUSAR','')
c('OrderItem','Discount','','Percentual de desconto no pedido, Escenario 17','NAO EXISTE, CRIAR','Confirmar no T01. E a unica coluna de desconto que falta de verdade')
c('Order','TotalAmount','Currency','Total do pedido','REUSAR','Calculado')
c('Order','Status','Picklist','Estado do pedido','REUSAR','')
c('PricebookEntry','PrecioMinimoAsesor__c','Currency','Base de calculo da escala, RN5','REUSAR','Ja existe na org')
c('PricebookEntry','PrecioExoneradoMinimo__c','Currency','Base de calculo exonerada, RN5','REUSAR','Ja existe na org')
c('PricebookEntry','PrecioExonerado__c','Currency','Preco exonerado','REUSAR','Ja existe na org')
c('PricebookEntry','Gastos__c','Currency','Gastos da entrada de preco','REUSAR','Ja existe na org')
c('PricebookEntry','AplicaCashback__c','Checkbox','Bandeira de cashback, RN11','REUSAR','Ja existe na org')
c('PricebookEntry','MontoCashback__c','Currency','Montante de cashback, RN11','REUSAR','Ja existe na org')
c('PricebookEntry','VigenciaDesde__c','Date','Vigencia do cashback, RN11','REUSAR','Ja existe na org')
c('PricebookEntry','UnitPrice','Currency','Precio de Lista','REUSAR','')
c('Product2','BusinessBrandId','Lookup','Marca, chave da escala da RN5','REUSAR','Padrao do Automotive. BusinessBrand tem 23 registros')
c('Product2','Family','Picklist','Familia, criterio de Repuestos','REUSAR','')
c('Product2','ProductCode','Text','SKU, criterio de Repuestos','REUSAR','')
c('VehicleDefinition','(objeto)','','Modelo, chave da escala da RN5','REUSAR','229 registros na org')
c('BusinessBrand','(objeto)','','Marca, chave da escala da RN5','REUSAR','23 registros na org')
c('UserRole','(objeto)','','Nivel do usuario, RN4 e RN5','REUSAR PARCIAL','Tem Gerente de Marca e Director. Falta Gerente de Ventas e Vicepresidencia')
c('Sociedad_Config__mdt','(metadata)','','Sociedade, chave da escala','REUSAR','14 registros na org')
c('Quote','(campo de cashback)','','Montante destinado a cashback, RN11','NAO EXISTE, CRIAR','Sem coluna padrao equivalente')
c('QuoteLineItem','(origem do desconto)','','Automatico ou manual, RN13','NAO EXISTE, CRIAR','Sem coluna padrao equivalente')
c('QuoteLineItem','(regra aplicada)','','Regra ou escalao que determinou, RN13','NAO EXISTE, CRIAR','Sem coluna padrao equivalente')
c('Product2 ou PricebookEntry','(custo estimado)','','Base da margem, RN10','NAO EXISTE, CRIAR','Nenhum campo de custo em Product2, PricebookEntry, Vehicle nem Asset')
c('QuoteLineItem','(margem)','','Margem resultante, RN10','NAO EXISTE, CRIAR','Precisa de FLS para esconder do assessor')

TIT = 'HU-064 - Tarefas Tecnicas - Motor de Descuentos Multicriterio Omnicanal'
TC  = 'HU-064 - Colunas padrao avaliadas antes de criar campo'
build('/home/user/diario-implantacao/docs/hu064/HU064_Tarefas_Tecnicas.xlsx',
      [('Tarefas', [[TIT],[''],H]+T, [8,50,26,52,86,14,26,14]),
       ('Colunas Padrao', [[TC],[''],HC]+C, [24,30,12,50,22,58])])
print('tarefas:', len([r for r in T if r[0].startswith('T')]), '| colunas avaliadas:', len(C))
