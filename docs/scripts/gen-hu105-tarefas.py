# -*- coding: utf-8 -*-
import sys
sys.path.insert(0, '/tmp')
import zipfile, html

def col(n):
    s=''
    while n>0:
        n,r=divmod(n-1,26); s=chr(65+r)+s
    return s

def sheet_xml(rows):
    out=['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
         '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
         '<cols>',
         '<col min="1" max="1" width="8"/><col min="2" max="2" width="50"/>',
         '<col min="3" max="3" width="20"/><col min="4" max="4" width="52"/>',
         '<col min="5" max="5" width="86"/><col min="6" max="6" width="14"/>',
         '<col min="7" max="7" width="26"/><col min="8" max="8" width="16"/>',
         '</cols><sheetData>']
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
    for i,(name,_) in enumerate(sheets,1):
        wb.append(f'<sheet name="{html.escape(name)}" sheetId="{i}" r:id="rId{i}"/>')
        wbr.append(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>')
    wb.append('</sheets></workbook>'); wbr.append('</Relationships>')
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', ''.join(ct))
        z.writestr('_rels/.rels', rels)
        z.writestr('xl/workbook.xml', ''.join(wb))
        z.writestr('xl/_rels/workbook.xml.rels', ''.join(wbr))
        for i,(_,rows) in enumerate(sheets,1):
            z.writestr(f'xl/worksheets/sheet{i}.xml', sheet_xml(rows))

H = ['ID','Tarefa','Tipo de Metadata','Componente / API Name (GRPQM)','O que fazer',
     'Depende de','Ref. HU / RN','Estado']

T = []
def t(*row):
    assert len(row) == 8, (row[0], len(row))
    T.append(list(row))
def b(n, titulo):
    T.append([n, titulo,'','','','','',''])

# ---------------------------------------------------------------- tabela de tasas
b('BLOCO 1','TABELA DE TASAS')
t('T01','Abrir a matriz de impostos existente','CalculationMatrix','MatrizImpuestosReferencia',
  'Abrir a matriz, listar colunas e linhas, e decidir se ela vira a tabela da RN-02 ou se e descartada',
  '','RN-02','A FAZER')
t('T02','Definir a tabela de tasas','CalculationMatrix','TasaImpuesto, da HU-038',
  'Chave: sociedade mais caracteristica da unidade mais condicion del cliente. Saida: tasa. Reusar a matriz da HU-038, nao criar uma segunda',
  'T01','RN-02, RN-04','A FAZER')
t('T03','Carregar as tasas dos seis paises','Dados','CalculationMatrixVersion',
  'Carregar CR 13, GT 12, SV 13, HN 15, NI 15 e PA 7 como versao com vigencia. Usar o versionado nativo para a RN-22, sem construir historico',
  'T02','RN-02, RN-06, RN-22','BLOQUEADO')
t('T04','Permission set de manutencao da tabela','PermissionSet','TaxRateAdministration',
  'Dar edicao da matriz so aos perfis de negocio autorizados. Definir com o GrupoQ quais sao',
  'T02','RN-22','A FAZER')

# ---------------------------------------------------------------- unidade
b('BLOCO 2','CONDICAO FISCAL DA UNIDADE')
t('T05','Campo do percentual de imposto da unidade','CustomField','Vehicle.TaxRatePercent (Percent, 5,2)',
  'Criar o campo com Description no padrao GRPQM. Recebe o percentual do maestro de inventario do SAP',
  '','RN-03','A FAZER')
t('T06','Campo de exoneracao por modelo e versao','CustomField','Product2.IsTaxExempt (Checkbox)',
  'Criar o campo. Decidir antes com o negocio se a exoneracao por modelo se administra em Product2 ou em VehicleDefinition',
  '','RN-10','A FAZER')
t('T07','Campo de exoneracao por unidade','CustomField','Vehicle.IsTaxExempt (Checkbox)',
  'Criar o campo. Escopo Guatemala, exoneracao por antiguidade da unidade de dois anos',
  'T05','RN-11','PAIS 2')
t('T08','Trazer o percentual fiscal da unidade do SAP','Integracao','MuleSoft, replica de inventario',
  'Pedir ao time de Mule o campo do percentual fiscal na replica de inventario e mapear para Vehicle.TaxRatePercent',
  'T05','RN-03','A FAZER')

# ---------------------------------------------------------------- cliente
b('BLOCO 3','CONDICAO FISCAL DO CLIENTE')
t('T09','Escolher a fonte unica de sociedade','Decision','Sociedad_Config__mdt, Account.Sociedad__c ou LegalEntity',
  'Escolher uma das tres, fazer backfill, repontar o que usa as outras e aposenta las. Nao sincronizar por Flow',
  '','RN-15','A FAZER')
t('T10','Escolher a fonte unica do identificador fiscal','Decision','BusinessProfile.BusinessTaxIdentifier ou Account.TaxID__c',
  'Escolher uma das duas, fazer backfill, repontar e aposentar a outra',
  '','RN-15','A FAZER')
t('T11','Campos de classificacao fiscal na relacao cliente x sociedade','CustomField','AccountAccountRelation: TaxClassification, WithholdingRate, PerceptionRate',
  'Criar os tres campos. Retencao e percepcao como percentual e nao como valor',
  'T09','RN-05, RN-06, RN-15','A FAZER')
t('T12','Campos da exoneracao do cliente','CustomField','AccountAccountRelation: ExemptionType, ExemptionDocumentNumber, ExemptionValidUntil',
  'Criar os tres campos. O arquivo do documento vai por Files, sem campo proprio',
  'T09','RN-07, RN-08, RN-09','A FAZER')
t('T13','Historico de campo na relacao fiscal','Object Manager','AccountAccountRelation, Field History Tracking',
  'Habilitar o historico nos campos fiscais criados em T11 e T12',
  'T11, T12','GQ-MK-03-108','A FAZER')
t('T14','Restringir edicao do dado fiscal do cliente','PermissionSet mais FLS','FiscalDataMaintenance',
  'Dar escrita so a Cuentas por Cobrar e Finanzas. Assessor com leitura',
  'T11','RN-15','A FAZER')

# ---------------------------------------------------------------- motor
b('BLOCO 4','DETERMINACAO')
t('T15','Verificar o motor de precos e o catalogo','Verificacao','docs/scripts/check-hu105-pricing-y-catalogo.apex',
  'Rodar o script em Execute Anonymous e usar o resultado para fechar T16, T17 e T21',
  '','RN-03, RN-19','A FAZER')
t('T16','Declarar os campos fiscais na Context Definition','ContextDefinition','Extensao da context definition de pricing',
  'Estender a context definition e declarar TaxRatePercent, IsTaxExempt, TaxClassification, WithholdingRate e PerceptionRate',
  'T05, T06, T11, T15','RN-03','A FAZER')
t('T17','Passo de determinacao fiscal no pricing procedure','ExpressionSet','Passo de imposto no pricing procedure',
  'Acrescentar o passo que le a matriz do T02 e devolve a tasa aplicavel, cruzando condicao da unidade com condicao do cliente',
  'T02, T16','RN-03, RN-04','A FAZER')
t('T18','Passo de retencao, depois do imposto','ExpressionSet','Passo de retencao no pricing procedure',
  'Acrescentar o passo de retencao apos o de imposto, calculando sobre o resultado do imposto',
  'T17','RN-05','A FAZER')
t('T19','Passo do gravame parcial','ExpressionSet','Passo de gravame no pricing procedure',
  'Aplicar a proporcao do gravame sobre a tasa da unidade. Confirmar antes com o fiscal do GrupoQ se a base e a tasa da unidade ou a do pais',
  'T17','RN-04','BLOQUEADO')
t('T20','Entrada da determinacao pela sociedade','ExpressionSet','Chave de entrada do passo fiscal',
  'Passar a sociedade do documento como entrada, e nao o pais. O pais se deriva da sociedade',
  'T09, T17','RN-15','A FAZER')

# ---------------------------------------------------------------- desglose
b('BLOCO 5','DESGLOSE E CONGELAMENTO')
t('T21','Definir onde o desglose e persistido','Decision','QuoteLineDetail nativo ou campos em QuoteLineItem',
  'Decidir com o resultado do T15. Se QuoteLineDetail estiver na org, usar o nativo e nao criar os campos do T22',
  'T15','RN-19','A FAZER')
t('T22','Campos de desglose na linha da cotizacion','CustomField','QuoteLineItem: PublicPrice, DiscountAmount, Subtotal, TaxRate, TaxAmount, WithholdingAmount, FinalPrice',
  'Criar os sete campos com Description no padrao GRPQM. So se o T21 concluir que nao ha nativo',
  'T21','RN-19','A FAZER')
t('T23','Desglose na linha do pedido','CustomField','OrderItem, os mesmos sete campos',
  'Replicar os campos do T22 em OrderItem, para o desglose viajar da cotizacion ao pedido',
  'T22','RN-19','A FAZER')
t('T24','Separar imposto do veiculo e dos acessorios','CustomField','QuoteLineItem.AccessoryTaxAmount',
  'Criar o campo e mostrar os dois valores separados no resumo, quando a unidade for exonerada ou tiver tasa reduzida',
  'T22','RN-12, GQ-CA-01-064','A FAZER')
t('T25','Congelar a determinacao na conversao','ApexClass','QuoteOrderService',
  'Estender a classe para copiar o desglose determinado da cotizacion para a reserva e para o pedido, sem recalcular',
  'T23','RN-19','A FAZER')
t('T26','Aplicar o redondeo por sociedade e moeda','Reuso','ReglaRedondeo__mdt',
  'Chamar a regra ja desenhada na HU-038. Formatar a duas decimais, calcular o IVA por posicao e arredondar por linha',
  'T25','RN-20','A FAZER')

# ---------------------------------------------------------------- documento
b('BLOCO 6','INDICADOR NO DOCUMENTO E APROVACAO')
t('T27','Indicador fiscal no documento','CustomField mais PermissionSet','Quote.TaxConditionIndicator',
  'Criar o campo e um Permission Set por sociedade que libere a edicao. Por padrao o campo se preenche da condicao do cliente',
  'T11','RN-16, FA-04','A FAZER')
t('T28','Exoneracao declarada no documento','CustomField','Quote.IsVehicleTaxExempt',
  'Criar o campo para indicar exoneracao na reserva sem alterar o dado mestre do catalogo',
  'T27','RN-10, GQ-CA-01-070','A FAZER')
t('T29','Processo de aprovacao da exoneracao','ApprovalProcess','Submit Tax Exemption Request',
  'Criar o processo seguindo o padrao do Discount Approval da Opportunity. Dispara quando o documento pede exoneracao que o cliente nao tem no dado mestre',
  'T28','RN-14, FA-01','A FAZER')
t('T30','Fila da area de Impuestos','Queue','GRP_Impuestos',
  'Criar a fila e apontar o processo de aprovacao para ela',
  'T29','RN-14','A FAZER')
t('T31','Validation rule de aprovacao pendente','ValidationRule','Quote, Tax Exemption Requires Approval',
  'Bloquear o avanco do documento enquanto a solicitacao de exoneracao nao for aprovada. Description ate 255 caracteres',
  'T29','RN-14','A FAZER')
t('T32','Validation rule de vigencia do documento','ValidationRule','AccountAccountRelation, Exemption Document Must Be Valid',
  'Impedir a aplicacao da exoneracao com documento vencido e informar o motivo ao usuario',
  'T12','RN-09','A FAZER')

# ---------------------------------------------------------------- repuestos
b('BLOCO 7','REPUESTOS E PA')
t('T33','Enviar indicador fiscal e condicao do cliente ao SAP','ApexClass','SapMuleClient',
  'Acrescentar o indicador fiscal e a condicao do cliente como parametros da chamada de preco. Salesforce nao calcula imposto em Repuestos',
  'T27','RN-16','BLOQUEADO')
t('T34','Persistir a resposta fiscal do SAP na linha','ApexClass','QuoteLineItem, campos do T22',
  'Gravar aliquota e valor de MWST e J1RI por material nos mesmos campos do T22, sem recalcular',
  'T33','RN-16','A FAZER')
t('T35','Reconsulta ao trocar o indicador fiscal','ApexClass','RepuestosLineService',
  'Disparar reconsulta de todas as linhas ao SAP quando o indicador mudar em Repuestos. Em Autos, disparar recalculo local',
  'T33','FA-04','A FAZER')
t('T36','Cobros adicionais sujeitos ou isentos','Modelagem','OrderAdjustmentGroup',
  'Definir se flete e sobrecusto de pedido emergente entram como linha de pedido ou como ajuste, e marcar por conceito se paga imposto',
  'T34','RN-17, GQ-PV-02-025','A FAZER')

# ---------------------------------------------------------------- fechamento
b('BLOCO 8','FECHAMENTO')
t('T37','Ativar as moedas dos paises pendentes','Setup','CurrencyType',
  'Ativar GTQ, HNL, NIO e PAB antes de existir documento em cada pais. CRC e USD ja estao ativas',
  '','Multi pais','PAIS 2')
t('T38','Traduzir os rotulos para espanhol','Translation','Translation Workbench',
  'Traduzir todos os campos, valores de picklist e mensagens de erro criados nesta HU',
  'T22','Convencao GRPQM','A FAZER')
t('T39','Trigger Order nos flows criados','Object Manager','Trigger Order de cada flow novo',
  'Definir a Trigger Order em cada flow que esta HU criar em Quote, Order e AccountAccountRelation',
  '','Governanca','A FAZER')
t('T40','Testes dos quinze escenarios','ApexClass','Testes do procedure e da conversao',
  'Cobrir os escenarios 1 a 15, com um caso por sociedade. Enfase no 2, no 3 e no 8',
  'T18, T25','Todos','A FAZER')

TIT = 'HU-105 - Tarefas Tecnicas - Determinacion, Visualizacion y Aplicacion de Impuestos'
build('/home/user/diario-implantacao/docs/hu105/HU105_Tarefas_Tecnicas.xlsx',
      [('Tarefas', [[TIT],[''],H] + T)])
print('tarefas:', len([r for r in T if r[0].startswith('T')]), '| linhas:', len(T))
