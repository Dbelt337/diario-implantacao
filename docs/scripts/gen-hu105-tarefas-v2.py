# -*- coding: utf-8 -*-
import sys, os
sys.path.insert(0, '/tmp')
from genxlsx import build

TIT = ('HU-105 - Tarefas Tecnicas v2 (18/08/2026) - Determinacion, Visualizacion y Aplicacion de Impuestos. '
       'Principio: nativo e existente ANTES de criar, e o desenho tem que aguentar os seis paises')

H = ['ID','Tarefa','Tipo de Metadata','Componente / API Name (GRPQM)','Detalle',
     'Depende de','Ref. HU / RN','Doc oficial','Falta / Nota','Estado (18/08)']

DOC_OBJ  = 'developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_taxrate.htm'
DOC_TAXP = 'developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_taxpolicy.htm'
DOC_LE   = 'developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_legalentity.htm'
DOC_B2B  = 'developer.salesforce.com/docs/commerce/salesforce-commerce/guide/b2b-b2c-comm-data-model-tax.html'
DOC_BRE  = 'developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/business_rules_engine.htm'
DOC_AUTO = 'Automotive Cloud Standard Objects (lista oficial, colada no chat em 18/08)'
DOC_VEH  = 'developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehicle.htm'
DOC_AAR  = 'developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_accountaccountrelation.htm'
DOC_OITL = 'developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_orderitemtaxlineitem.htm'
CONV     = 'Convencao de nomenclatura GRPQM'

T = []
def t(*row): T.append(list(row))

# ---------------------------------------------------------------- bloco 0
T.append(['BLOCO 0','VERIFICAR O QUE JA EXISTE, ANTES DE PROPOR QUALQUER COMPONENTE','','','','','','','',''])
t('T01','Rodar o describe fiscal na org','Verificacao','docs/scripts/check-hu105-impuestos.apex',
  'Responde se existem objetos fiscais nativos, se o BRE esta habilitado, onde mora hoje o percentual da unidade e a condicao fiscal do cliente, e o que ja ha de campo custom em QuoteLineItem e OrderItem',
  'Regra dura do projeto','Todas',DOC_AUTO,'6,1 KB, roda sozinho no Execute Anonymous','PENDENTE, roda primeiro')
t('T02','Rodar o describe do modelo fiscal nativo e do multi pais','Verificacao','docs/scripts/check-hu105-nativo-y-multipais.apex',
  'A pesquisa de 18/08 achou modelo fiscal nativo fora do Automotive: LegalEntity, TaxPolicy, TaxTreatment e TaxRate, do Commerce e do Revenue. TaxRate e por codigo de imposto E PAIS, e a TaxTreatment aponta para a LegalEntity. Isso e literalmente a RN-02 e a RN-15. O script diz se estao disponiveis e criaveis nesta org',
  'T01','RN-02, RN-15',DOC_B2B,'Script separado porque os dois juntos passam do limite de URL do Execute Anonymous','PENDENTE, roda segundo')
t('T03','Cruzar item por item o que se quer criar contra o que ja existe','Decision','Planilha aba Nativo Avaliado',
  'Vinte e uma necessidades da HU contra os candidatos nativos e contra o que ja esta na org. So o que sobrar do cruzamento entra em pacote. E a regra dura que nasceu do pacote de 18 campos da HU-039',
  'T01, T02','Governanca 14/08','docs/hu039-cobertura-tecnica-2026-08-13.md','Nenhum pacote antes desta linha','PENDENTE')
t('T04','Confirmar que a licenca cobre o modelo fiscal nativo','Verificacao','check-licencias-objetos.apex, reexecucao',
  'Em 13/08 Commerce e Product Catalog Management apareceram contratados com folga. Se TaxPolicy e TaxRate vierem criaveis, a tabela de tasas pode ser nativa e por sociedade em vez de matriz construida',
  'T02','RN-02','docs/scripts/check-licencias-objetos.apex','Licenca nunca foi o obstaculo nesta org, mas toggle de Setup ja foi, caso do AssetTitle','PENDENTE')

# ---------------------------------------------------------------- bloco 1
T.append(['BLOCO 1','TABELA DE TASAS, A BASE DE TUDO','','','','','','','',''])
t('T05','Decidir onde vive a tabela de tasas','Decision','Opcao A: TaxRate mais TaxTreatment nativos. Opcao B: CalculationMatrix TasaImpuesto da HU-038',
  'A e nativa, ja e por pais e por LegalEntity, versionavel e mantida por negocio sem deploy. B ja esta desenhada na HU-038 e expressa regra que a nativa nao expressa. O provavel e hibrido: tabela nativa para a tasa, matriz so para gravame parcial e retencao',
  'T02, T04','RN-02, RN-22',DOC_OBJ,'DECISAO DE ARQUITETURA, nao abrir pacote antes','PENDENTE T02')
t('T06','Reusar a matriz da HU-038, nunca criar uma segunda','Reuso','CalculationMatrix TasaImpuesto',
  'Pais mais Caracteristica mais Condicion del cliente devolve a tasa. A HU-038 ja carrega do Impuestos_SAP.xlsx com KSCHL, ALAND, TAXK1 e MWSK1. A HU-105 consome. Duas tabelas de tasa e o mesmo defeito da moeda em 14/08',
  'T05','RN-02, RN-04','docs/hu038-precios-modelagem.md','A HU-038 tem que subir antes','PENDENTE HU-038')
t('T07','Carregar as tasas dos seis paises com versionado','Dados','CalculationMatrixVersion ou TaxRate por pais',
  'CR 13, GT 12, SV 13, HN 15, NI 15, PA 7. O versionado e nativo nos dois candidatos e cobre a RN-22, vigencia de mudanca de tasa, sem construir historico proprio',
  'T05','RN-02, RN-06','help.salesforce.com/s/articleView?id=ind.create_a_decision_table.htm','BLOQUEIO: a tabela e premissa do GrupoQ e chega incompleta, GT e PA com celulas vazias','BLOQUEADO')
t('T08','Manutencao por negocio, sem deploy','PermissionSet','TaxRateAdministration',
  'A tasa muda por lei e nao pode depender de release. E o argumento de industria para tabela em dado, e nao regra em codigo: mudanca regulatoria vira linha, nao deploy',
  'T05','RN-22',DOC_BRE,'Definir quais perfis de negocio editam','PENDENTE')
t('T09','Regra: pais e dimensao de dado, nunca nome de metadado','Padrao','Revisao de nomenclatura de tudo que a HU criar',
  'Nada de campo, matriz ou classe com Costa Rica, Guatemala ou qualquer pais no API name. A propria convencao GRPQM proibe referencia a pais no nome. O bloco 4 do script T02 procura violacoes ja existentes',
  'T02','Convencao GRPQM',CONV,'Vale para todos os componentes desta HU','PENDENTE')

# ---------------------------------------------------------------- bloco 2
T.append(['BLOCO 2','CONDICAO FISCAL DA UNIDADE','','','','','','','',''])
t('T10','Campo do percentual de imposto da unidade','CustomField','Vehicle.TaxRatePercent (Percent)',
  'A RN-03 diz que o percentual vem do maestro de inventario do SAP e representa cem por cento do imposto daquela unidade. E por unidade fisica, nao por modelo, entao nao cabe em Product2 nem em VehicleDefinition. Criar so se o T01 mostrar que Vehicle nao tem campo fiscal',
  'T01','RN-03',DOC_VEH,'Description obrigatoria com paises, proposito e dependencias','PENDENTE T01')
t('T11','Exoneracao por modelo e versao','CustomField ou Nativo','Product2.TaxPolicyId nativo, ou Product2.IsTaxExempt se nao existir',
  'No modelo nativo o produto carrega a TaxPolicy e a policy agrupa as TaxTreatment, que e exatamente marcar marca, modelo e versao como exonerado. Se Product2.TaxPolicyId existir na org, nao se cria campo custom nenhum aqui',
  'T02','RN-10',DOC_TAXP,'O T02 responde. Decidir tambem Product2 contra VehicleDefinition','PENDENTE T02')
t('T12','Exoneracao por unidade','CustomField','Vehicle.IsTaxExempt (Checkbox)',
  'Guatemala exonera por antiguidade da unidade, dois anos. E por unidade e nao por modelo, entao e outro campo e o nativo por produto nao alcanca. Escopo GT, entra depois de Costa Rica, mas o desenho ja nasce com ele previsto',
  'T10','RN-11',DOC_VEH,'Nao construir agora, so nao fechar o desenho sem ele','PENDENTE, pais 2')
t('T13','Trazer o percentual fiscal da unidade do SAP','Integracao','MuleSoft, replica de inventario',
  'O percentual da unidade e a fonte da RN-03. Sem ele a determinacao nao roda em nenhum pais. Pedir ao time de Mule o campo na replica, do mesmo jeito que se pediu a ZHYB para Repuestos',
  'T10','RN-03, Premissa 1','Inventario de integracoes','Pedido ainda nao feito ao time de Mule','PENDENTE')

# ---------------------------------------------------------------- bloco 3
T.append(['BLOCO 3','CONDICAO FISCAL DO CLIENTE, POR SOCIEDADE','','','','','','','',''])
t('T14','Decidir onde vive a relacao fiscal cliente x sociedade','Decision','Opcao A: LegalEntity nativa mais AccountAccountRelation. Opcao B: objeto custom',
  'A RN-15 exige cliente x SOCIEDAD e nao cliente x pais, entao campo em Account nao serve: uma conta opera com mais de uma sociedade. AccountAccountRelation e nativa do Automotive, personalizavel, com History e Share. LegalEntity e a sociedade no modelo fiscal nativo. Objeto custom e o ultimo recurso',
  'T02','RN-15',DOC_AAR,'DECISAO DE ARQUITETURA','PENDENTE T02')
t('T15','Escolher UMA fonte de sociedade antes de amarrar imposto nela','Decision','Sociedad_Config__mdt contra LegalEntity contra texto livre',
  'Sete Custom Metadata ja carregam pais ou sociedade e o codigo se repete como texto livre sem integridade referencial. Amarrar imposto a uma oitava fonte repete o defeito. Escolher uma, backfill, repontar e aposentar as outras, nunca sincronizar por Flow',
  'T14','Governanca 14/08','docs/scripts/inventario-automacoes-e-campos.apex','Bloco 3 do script T02 lista as fontes','PENDENTE T02')
t('T16','Campos de classificacao fiscal na relacao','CustomField','TaxClassification, WithholdingRate, PerceptionRate',
  'Indicador de imposto de venda, retencao e percepcao. Sao dado fixo do cliente e nao decisao do assessor. Percentual e nao valor, porque a base muda por documento',
  'T14','RN-05, RN-06, RN-15',DOC_AAR,'El Salvador retem 1 ou 13 por cento, entao o campo e por sociedade','PENDENTE T14')
t('T17','Campos e arquivo da exoneracao','CustomField mais Files','ExemptionType, ExemptionDocumentNumber, ExemptionValidUntil',
  'Total ou parcial, numero do documento e vigencia. O arquivo vai por Files, que ja e nativo. Antes de criar, o T01 checa se IdentityDocument ou TaxIdentification ja resolvem, porque sao nativos e desenhados para documento fiscal',
  'T14','RN-07, RN-08, RN-09',DOC_AUTO,'O Escenario 6 depende da vigencia','PENDENTE T01')
t('T18','Ligar historico de campo na relacao fiscal','Object Manager','AccountAccountRelationHistory',
  'A RN-108 pede auditoria das mudancas fiscais. O objeto de historico ja existe, e so habilitar por campo. Zero componente criado',
  'T16','GQ-MK-03-108',DOC_AAR,'Vinte campos por objeto e o teto do historico','PENDENTE')
t('T19','Restringir quem edita o dado fiscal do cliente','PermissionSet mais FLS','FiscalDataMaintenance',
  'So Cuentas por Cobrar e Finanzas editam, e os dados se completam automaticamente na criacao do cliente. Assessor le e nao escreve',
  'T16','RN-15','Resposta do GrupoQ na propria HU','PENDENTE','PENDENTE')

# ---------------------------------------------------------------- bloco 4
T.append(['BLOCO 4','DETERMINACAO','','','','','','','',''])
t('T20','Expression Set da determinacao fiscal','ExpressionSet','TaxDetermination',
  'Cruza condicao fiscal da unidade contra condicao do cliente e devolve a tasa aplicavel, consultando a tabela do T05. A ferramenta e nomeada pela propria HU. O que a tabela nativa nao expressa fica aqui, nao em Apex',
  'T05, T10, T16','RN-03, RN-04',DOC_BRE,'Nao duplicar em Apex o que o Expression Set ja faz','PENDENTE')
t('T21','Servico Apex que invoca a determinacao','ApexClass','TaxDeterminationService',
  'Chamado pelo fluxo de venda guiada. Reusar o padrao do PricingService, que ja existe, sem duplicar logica de preco dentro do imposto',
  'T20','RN-03','Codigo em DEV','Integrar com GuidedSellingController','PENDENTE')
t('T22','Ordem: imposto primeiro, retencao sobre o resultado','ApexClass','TaxDeterminationService',
  'Calcula o imposto de venda e sobre o resultado a retencao. A ordem esta explicita na RN-05 e e facil de inverter por engano. Mesmo tipo de armadilha do callout antes do DML na HU-039',
  'T21','RN-05','RN-05 literal','Teste unitario dedicado','PENDENTE')
t('T23','Gravame parcial sobre a tasa DA UNIDADE','ExpressionSet','TaxDetermination, ramo do gravame',
  'Gravado a vinte por cento sobre unidade de 13 da 2,6. Sobre unidade eletrica de 4 da 0,8. A proporcao e sobre a tasa da unidade e nao sobre a geral do pais',
  'T20','RN-04, Escenario 3','RN-04 e Escenario 3','AMBIGUIDADE: a RN-04 exemplifica com a tasa do pais e se contradiz. Confirmar com o fiscal deles','BLOQUEADO')
t('T24','Determinacao roda por sociedade, nao por pais','ApexClass mais ExpressionSet','TaxDeterminationService, parametro de entrada',
  'A entrada da determinacao e a sociedade do documento, e a sociedade traz o pais. Se a entrada for o pais, o dia em que duas sociedades do mesmo pais tributarem diferente o desenho quebra e ja nasce dividido',
  'T15, T20','RN-15','Doze sociedades em seis paises',CONV,'PENDENTE')

# ---------------------------------------------------------------- bloco 5
T.append(['BLOCO 5','DESGLOSE E CONGELAMENTO','','','','','','','',''])
t('T25','Decidir onde o desglose e persistido','Decision','OrderItemTaxLineItem nativo contra campos custom na linha',
  'O nativo existe para exatamente isto, imposto por linha de pedido, e ja tem o Summary para o total. Se estiver disponivel e criavel, sao sete campos custom que nao se cria em OrderItem. O que ele nao cobre e o Quote, que nao tem equivalente nativo',
  'T01','RN-19',DOC_OITL,'DECISAO DE ARQUITETURA','PENDENTE T01')
t('T26','Campos de desglose na linha da cotizacion','CustomField','QuoteLineItem: PublicPrice, DiscountAmount, Subtotal, TaxRate, TaxAmount, WithholdingAmount, FinalPrice',
  'A RN-19 exige persistir na linha porque e o que congela o preco e alimenta o PDF e os relatorios. Aqui nao ha nativo: o modelo fiscal da plataforma para em Order, entao a cotizacion e construida',
  'T25','RN-19, Escenario 11',DOC_OITL,'Sete campos, todos com Description pela convencao','PENDENTE T25')
t('T27','Desglose na linha do pedido','CustomField ou Nativo','OrderItemTaxLineItem, ou os mesmos campos em OrderItem',
  'O desglose viaja da cotizacion ao pedido sem recalcular. Se o T25 der nativo, aqui nao se cria nada',
  'T26','RN-19, Escenario 14',DOC_OITL,'PENDENTE T25','PENDENTE')
t('T28','Separar imposto do veiculo e imposto dos acessorios','CustomField','AccessoryTaxAmount',
  'Quando a unidade e exonerada ou tem tasa reduzida, os acessorios mantem a tasa geral. O resumo mostra os dois separados. No modelo nativo isso e uma TaxTreatment por produto e sai de graca',
  'T26','RN-12, GQ-CA-01-064',DOC_TAXP,'Depende do T11','PENDENTE')
t('T29','Congelar a determinacao na conversao','ApexClass','QuoteOrderService, extensao',
  'Cotizacion vira reserva e depois pedido conservando o imposto determinado, sem recalcular. A classe ja existe em DEV, isto e extensao e nao construcao',
  'T27','RN-19, Escenario 14','Codigo em DEV','Reaproveitamento direto','PENDENTE')
t('T30','Redondeo por sociedade e moeda','Reuso','ReglaRedondeo__mdt da HU-038',
  'Resposta do GrupoQ: cada operacao formata a duas decimais, o IVA calcula por posicao e arredonda por linha. Ja desenhado na HU-038, a HU-105 so chama',
  'T29','RN-20','docs/hu038-precios-modelagem.md','Nao criar regra de arredondamento propria','PENDENTE HU-038')

# ---------------------------------------------------------------- bloco 6
T.append(['BLOCO 6','INDICADOR NO DOCUMENTO E APROVACAO','','','','','','','',''])
t('T31','Indicador fiscal no documento, editavel por perfil','CustomField mais PermissionSet','Quote.TaxConditionIndicator',
  'Atributo do documento comercial, mesmo criterio ja usado para a moeda. A resposta do GrupoQ na HU e Permission Set por sociedade',
  'T16','RN-16, FA-04','Resposta do GrupoQ na propria HU','Definir os perfis por sociedade','PENDENTE')
t('T32','Exoneracao declarada no proprio documento','CustomField','Quote.IsVehicleTaxExempt',
  'Indicar na reserva que o veiculo e exonerado mesmo sem estar marcado no catalogo. Nao altera o dado mestre',
  'T31','RN-10 segunda parte','GQ-CA-01-070','Nao altera o dado mestre do catalogo','PENDENTE')
t('T33','Aprovacao da exoneracao nao registrada','ApprovalProcess','Submit Tax Exemption Request',
  'Se o documento pede exoneracao que o cliente nao tem no dado mestre, bloqueia o avanco e gera solicitacao. O padrao ja existe na org no Opportunity Record Type Discount Approval, entao e copia de padrao e nao invencao',
  'T31','RN-14, FA-01, Escenario 5','Processo ja existente em DEV','Reaproveitar o padrao aprovado','PENDENTE')
t('T34','Fila de Impuestos e validation rules','Group ou Queue mais ValidationRule','GRP_Impuestos, Tax Exemption Requires Approval, Exemption Document Must Be Valid',
  'Destino da solicitacao, bloqueio do avanco enquanto nao aprovada, e bloqueio de documento de exoneracao vencido informando o motivo. Description de validation rule tem teto de 255 caracteres, ja batemos nele',
  'T33','RN-09, RN-14, Escenario 6','Limite de 255 medido em 14/08','Duas VR e uma fila','PENDENTE')

# ---------------------------------------------------------------- bloco 7
T.append(['BLOCO 7','REPUESTOS E PA, ONDE O SALESFORCE NAO CALCULA','','','','','','','',''])
t('T35','Enviar indicador fiscal e condicao do cliente ao servico de precos','ApexClass','SapMuleClient',
  'Repuestos e PA nao calculam imposto no Salesforce. O indicador e a condicao viajam como parametro e o SAP devolve o valor. E a pratica de industria quando o ERP e o sistema de registro fiscal, e aqui o SAP e inteiro do GrupoQ',
  'T31','RN-16, Escenario 12','Inventario de integracoes','BLOQUEIO: ZHYB_DBM_PRECIO_VTA_NO_MAESTRO ainda nao existe no SapMuleClient','BLOQUEADO')
t('T36','Persistir aliquota e valor de MWST e J1RI por material','CustomField','QuoteLineItem: TaxRate e TaxAmount reusados, mais WithholdingAmount',
  'Salesforce exibe e persiste o que o SAP devolve, sem recalcular. Mesmo padrao ja usado no AvailabilityStatus da HU-043. Os campos sao os mesmos do T26, nao se cria um segundo conjunto so para Repuestos',
  'T35','RN-16','docs/hu043','Reuso de campo, nao criacao','PENDENTE')
t('T37','Reconsulta ao trocar o indicador fiscal','ApexClass','RepuestosLineService',
  'Em Repuestos a troca do indicador dispara reconsulta de todas as linhas ao SAP. Em Autos dispara recalculo local. Sao dois comportamentos e a HU trata como um so',
  'T35','FA-04, Escenario 15','FA-04','A HU trata os dois como um so, separar','PENDENTE')
t('T38','Cobros adicionais sujeitos ou isentos','Modelagem','Definir se e linha de pedido ou objeto de ajuste',
  'Flete, sobrecusto de pedido emergente e similares. No modelo nativo isso e OrderAdjustmentGroup, que ja existe para ajuste de pedido. Avaliar antes de criar objeto',
  'T36','RN-17, GQ-PV-02-025, Escenario 13',DOC_OITL,'Modelagem pendente, avaliar o nativo primeiro','PENDENTE')

# ---------------------------------------------------------------- bloco 8
T.append(['BLOCO 8','MULTI PAIS, O QUE NAO PODE FICAR PARA DEPOIS','','','','','','','',''])
t('T39','Moeda: verificar as ativas antes de prometer pais','Verificacao','CurrencyType',
  'Costa Rica opera com CRC e USD e as duas estao ativas. GTQ, HNL e NIO nao estao. Isso nao bloqueia o escopo atual e bloqueia as sociedades desses paises quando entrarem. O bloco 4 do script T02 lista',
  'T02','Multi pais','docs/ambiente','Ativar moeda depois de ter dado exige taxa de cambio retroativa','PENDENTE')
t('T40','Tasa por sociedade e nao por pais, no dado','Padrao','Tabela do T05, chave',
  'A chave da tabela e sociedade, e a sociedade traz o pais. Duas sociedades do mesmo pais podem tributar diferente por atividade, e Autos e Motos em Costa Rica ja sao duas. Chave por pais e retrabalho garantido no pais 2',
  'T05, T24','RN-15','C101 Autos e C105 Motos','Chave por pais e retrabalho garantido','PENDENTE')
t('T41','Traducao pela Translation Workbench, nao por campo por idioma','Translation','Translation Workbench',
  'Metadado nasce em ingles e a exibicao vai em espanhol, pela convencao GRPQM. Campo por idioma multiplica por seis e nao escala',
  'T26','Convencao GRPQM',CONV,'Traduzir tudo que a HU criar','PENDENTE')
t('T42','Nenhuma regra fiscal em codigo de pais','Padrao','Revisao do TaxDeterminationService',
  'Ley 9518 de Costa Rica, os dois anos da Guatemala e a retencao de El Salvador entram como linha de tabela e nao como ramo de if. O argumento e o mesmo da documentacao do BRE: mudanca regulatoria sem deploy',
  'T20','Multi pais',DOC_BRE,'Criterio de revisao de codigo desta HU','PENDENTE')

# ---------------------------------------------------------------- bloco 9
T.append(['BLOCO 9','REUSO CONFIRMADO E FECHAMENTO','','','','','','','',''])
t('T43','Reusar PrecioExonerado e PrecioExoneradoMinimo','Reuso','PricebookEntry.PrecioExonerado__c, PrecioExoneradoMinimo__c',
  'Ja existem na org, verificados no retrieve de 14/08. Exoneracao total cotiza com eles em vez do Precio de Lista. Zero componente novo',
  '','RN-07, Escenario 4','Retrieve de 14/08','Nao criar nada aqui','FEITO')
t('T44','Reusar o percentual de 1a matricula da HU-038','Reuso','PricebookEntry, campo de 1a matricula',
  'Administrado como percentual na entrada de lista, irmao do Gastos__c. Sua alteracao nao dispara aprovacao de precos. Ja desenhado na HU-038',
  '','RN-13, Escenarios 9 e 10','docs/hu038-precios-modelagem.md','PENDENTE HU-038','PENDENTE HU-038')
t('T45','Reusar o Nebula Logger para erro de determinacao','Reuso','Nebula Logger, ja instalado',
  'Nao criar SapLastError nem contador de retentativa em objeto nenhum. Foi exatamente o erro apontado no pacote da HU-039',
  'T21','Governanca 14/08','docs/hu039-cobertura-tecnica-2026-08-13.md','Zero campo custom de log','PENDENTE')
t('T46','Trigger Order em qualquer flow que a HU criar','Object Manager','Trigger Order de cada flow novo',
  'A org tem 39 automacoes concentradas em Lead, Account e Opportunity. Ordem entre flows do mesmo objeto e gatilho so e previsivel com Trigger Order definida em cada um',
  '','Governanca 14/08','docs/scripts/inventario-automacoes-e-campos.apex','Vale tambem para Quote e Order','PENDENTE')
t('T47','Testes dos quinze escenarios','ApexClass','TaxDeterminationServiceTest',
  'Cobrir os escenarios 1 a 15 com enfase no 2, no 3 e no 8, que sao os que a RN-04 e a RN-05 tornam faceis de errar. Um caso por pais para provar que nao ha regra cravada em codigo',
  'T22, T42','Todos','Escenarios da propria HU','Um caso por pais','PENDENTE')

TAREFAS = [[TIT],[''],H] + T

# ---------------------------------------------------------------- aba nativo
HN = ['#','Necessidade (RN)','Candidato nativo ou ja existente','De onde vem','Ja esta na org?','Veredito','Fundamento']
N = []
def n(*r): N.append(list(r))
n('N01','Tabela de tasas por pais (RN-02)','TaxRate','Commerce e Revenue, API 55+','T02 responde','AVALIAR ANTES DE CRIAR',
  'TaxRate e definida por codigo de imposto e PAIS, e se liga a LegalEntity. E a forma da RN-02 e da RN-15 juntas')
n('N02','Tasa por sociedade (RN-15)','LegalEntity mais TaxTreatment','Commerce e Revenue','T02 responde','AVALIAR ANTES DE CRIAR',
  'A TaxTreatment aponta para a LegalEntity e a regra aplica quando as duas coincidem. Sem legal entity o Billing nao calcula imposto, o que confirma que a sociedade e a chave certa')
n('N03','Exoneracao por modelo e versao (RN-10)','Product2.TaxPolicyId e TaxPolicy','Commerce e Revenue','T02 responde','AVALIAR ANTES DE CRIAR',
  'Cada produto carrega uma tax policy e a policy agrupa tratamentos que decidem se o produto tributa. E exatamente marcar marca, modelo e versao')
n('N04','Desglose por linha de pedido (RN-19)','OrderItemTaxLineItem e o Summary','Order Management','T01 responde','AVALIAR ANTES DE CRIAR',
  'Existe para representar o imposto de uma linha de pedido e a variacao por ajuste. Cobre o pedido, NAO cobre o Quote')
n('N05','Desglose na cotizacion (RN-19)','nao ha nativo','','','CONSTRUIR',
  'O modelo fiscal da plataforma para em Order. Quote nao tem objeto de imposto por linha, entao os sete campos do T26 sao construcao legitima')
n('N06','Regra de gravame parcial (RN-04)','nao ha nativo','','','CONSTRUIR em BRE',
  'Proporcao sobre a tasa da unidade nao e expressavel em TaxRate. Vai em Expression Set, que e configuracao e nao codigo')
n('N07','Retencao e percepcao (RN-05, RN-06)','nao ha nativo','','','CONSTRUIR em BRE',
  'O modelo nativo trata imposto de venda, nao retencao na fonte sobre o resultado. E regra latino americana e fica na matriz')
n('N08','Exoneracao por unidade (RN-11)','nao ha nativo','','','CONSTRUIR, pais 2',
  'A politica fiscal nativa e por produto, nao por unidade fisica. Guatemala exonera por antiguidade da unidade')
n('N09','Percentual fiscal da unidade (RN-03)','Vehicle, campos padrao','Automotive Cloud','T01 responde','VERIFICAR ANTES',
  'Automotive Cloud nao tem objeto de imposto, confirmado na lista oficial de Standard Objects, mas Vehicle pode ja ter campo fiscal livre')
n('N10','Relacao cliente x sociedade (RN-15)','AccountAccountRelation','Automotive Cloud','Existe, zero campo custom e zero registro','AVALIAR CONTRA LegalEntity',
  'Nativa, personalizavel, com History e Share. A duvida e se a sociedade e uma Account ou uma LegalEntity, e o T15 resolve')
n('N11','Auditoria da mudanca fiscal (RN-108)','AccountAccountRelationHistory','Plataforma','Existe','REUSAR',
  'Historico de campo e nativo, basta habilitar. Nao se constroi objeto de auditoria')
n('N12','Documento de exoneracao (RN-08)','IdentityDocument e TaxIdentification','Plataforma e Industries','T01 responde','VERIFICAR ANTES',
  'Sao objetos desenhados para documento fiscal e de identidade. Se cobrirem, nao se cria campo de numero de documento')
n('N13','Arquivo da exoneracao (RN-08)','Files','Plataforma','Existe','REUSAR','Anexo e nativo, nao se modela armazenamento')
n('N14','Preco exonerado (RN-07)','PricebookEntry.PrecioExonerado__c','Ja construido no projeto','SIM, retrieve de 14/08','REUSAR',
  'Ja existe e ja e usado. Cotizar exoneracao total com ele')
n('N15','Percentual de 1a matricula (RN-13)','PricebookEntry, campo da HU-038','Projeto, HU-038','Desenhado','REUSAR','Irmao do Gastos__c, a HU-105 so consome')
n('N16','Redondeo (RN-20)','ReglaRedondeo__mdt','Projeto, HU-038','Desenhado','REUSAR','Por sociedade e moeda, ja resolvido')
n('N17','Log de erro da determinacao','Nebula Logger','Ja instalado na org','SIM','REUSAR',
  'Nao criar campo de ultimo erro nem contador de retentativa. Licao do pacote de 18 campos da HU-039')
n('N18','Aprovacao da exoneracao (RN-14)','ApprovalProcess, padrao do Discount Approval','Ja existe em DEV','SIM','REUSAR O PADRAO',
  'Copiar o padrao aprovado em vez de desenhar um novo fluxo de aprovacao')
n('N19','Vigencia de mudanca de tasa (RN-22)','Versionado de TaxRate ou CalculationMatrixVersion','Nativo nos dois candidatos','T02 responde','REUSAR',
  'Nao construir historico de tasa. O versionado e nativo e e o que a RN-22 pede')
n('N20','Cobros adicionais (RN-17)','OrderAdjustmentGroup','Order Management','T01 responde','AVALIAR ANTES DE CRIAR',
  'Ajuste de pedido ja e modelado. Avaliar antes de criar objeto de cobro')
n('N21','Cumprimento fiscal e livro legal (RN-21)','SAP','ERP do GrupoQ','Fora do Salesforce','NAO CONSTRUIR',
  'Salesforce nao gera arquivo de obrigacao legal. E fronteira de responsabilidade, o SAP e inteiro deles')

NATIVO = [['HU-105 - Nativo Avaliado. Vinte e uma necessidades cruzadas contra o que a plataforma ja modela e contra o que a org ja tem. Nada entra em pacote sem passar por aqui'],[''],HN] + N

# ---------------------------------------------------------------- aba decisoes
HD = ['Tema','Decisao','Por que','Fonte','Estado']
D = [
 ['Principio','Nativo e existente antes de criar','Vinte e uma necessidades foram cruzadas na aba Nativo Avaliado. Seis viram reuso direto, cinco dependem de um describe para decidir, e so o que sobrar entra em pacote','Governanca de 14/08','APLICADO'],
 ['Principio','O desenho nasce multi pais','Costa Rica e a implantacao, mas sao seis paises e doze sociedades. Tasa e chave de tabela, nunca ramo de codigo, e pais nunca aparece em API name','Convencao GRPQM e escopo do programa','APLICADO'],
 ['Escopo do motor fiscal','A HU-105 CONSOME, nao constroi o motor','A tabela de tasas, a matriz de 1a matricula e a regra de redondeo ja foram desenhadas na HU-038, e a condicao fiscal do cliente na HU-017','docs/hu038-precios-modelagem.md','FECHADA'],
 ['Objeto de imposto do Automotive','Nao existe','A lista oficial de Automotive Cloud Standard Objects nao tem nenhum objeto fiscal. Vehicle, VehicleDefinition, Appraisal, Fleet, Claim, Telemetry, nenhum de imposto','Automotive Cloud Standard Objects','FECHADA'],
 ['Modelo fiscal nativo','Existe, mas fora do Automotive','LegalEntity, TaxPolicy, TaxTreatment e TaxRate sao do Commerce e do Revenue. A org tem Commerce e Product Catalog Management contratados. Isso muda o desenho e tem que ser verificado antes de empacotar','Pesquisa de 18/08','ABERTA, T02 decide'],
 ['Tabela de tasas','Provavelmente hibrida','Tasa base na tabela, nativa ou matriz, e so a regra que ela nao expressa em Expression Set: gravame parcial e retencao. Nao duplicar a tasa em dois lugares','Pesquisa de 18/08','ABERTA, T05 decide'],
 ['Regra fiscal em codigo','Proibida','Mudanca de tasa e mudanca de lei nao pode depender de release. A documentacao do BRE usa exatamente este argumento: regra em dado responde a mudanca regulatoria sem deploy','Business Rules Engine, documentacao oficial','FECHADA'],
 ['Relacao fiscal','Cliente x sociedade, nao cliente x pais','A RN-15 e explicita. Campo em Account nao serve porque uma conta opera com mais de uma sociedade. E ha duas sociedades so em Costa Rica, C101 Autos e C105 Motos','RN-15, GQ-MK-03-040','ABERTA, T14 decide'],
 ['Fonte da sociedade','Uma so, escolhida antes de amarrar imposto','Sete Custom Metadata ja carregam pais ou sociedade como texto livre. Amarrar imposto a mais uma fonte repete o defeito da moeda de 14/08','Inventario de 14/08','ABERTA, T15 decide'],
 ['Repuestos e PA','Salesforce nao calcula imposto','O indicador viaja como parametro e a resposta do SAP e exibida e persistida sem recalculo. E a pratica de industria quando o ERP e o sistema de registro fiscal','RN-16','FECHADA'],
 ['Cumprimento fiscal','Permanece no SAP','Salesforce nao gera arquivo de obrigacao legal nem livro fiscal. Fronteira de responsabilidade','RN-21','FECHADA'],
 ['Precio de Lista','Com IVA incluido em veiculos','Mantem a pratica atual. Em Repuestos varia por pais e continua pendente','RN-18','ABERTA'],
 ['Log de erro','Nebula Logger, sem campo proprio','Ja instalado. Criar campo de ultimo erro e contador de retentativa foi apontado como divida no pacote da HU-039','Governanca de 14/08','FECHADA'],
]
DEC = [['HU-105 - Decisoes e Escopo'],[''],HD] + D

# ---------------------------------------------------------------- aba arquitetura
HA = ['Camada','Componente','Papel','Ja existe?','O que muda no pais 2']
A = [
 ['Tabela de tasas','TaxRate nativa ou CalculationMatrix TasaImpuesto','Sociedade mais Caracteristica mais Condicion del cliente devolve a tasa','A decidir no T05','Linha nova na tabela, zero deploy'],
 ['Determinacao','ExpressionSet TaxDetermination','Cruza unidade contra cliente e devolve a tasa aplicavel','Nao','Nada, se nenhuma regra estiver em codigo'],
 ['Condicao da unidade','Vehicle.TaxRatePercent','Percentual da unidade, vindo do maestro de inventario do SAP','T01 responde','Nada, o campo e por unidade'],
 ['Exoneracao por modelo','Product2.TaxPolicyId nativo, ou campo custom','Marca, modelo e versao exonerados','T02 responde','Politica nova por produto, dado e nao metadado'],
 ['Exoneracao por unidade','Vehicle.IsTaxExempt','Guatemala, por antiguidade da unidade','Nao','Este campo NASCE no pais 2, previsto desde agora'],
 ['Sociedade','LegalEntity ou Sociedad_Config__mdt','Chave fiscal do documento e da relacao com o cliente','Fonte a escolher no T15','Registro novo, zero deploy'],
 ['Condicao do cliente','AccountAccountRelation mais campos fiscais','Classificacao, retencao, percepcao e exoneracao por sociedade','Objeto existe, campos nao','Registro novo por sociedade'],
 ['Preco exonerado','PricebookEntry.PrecioExonerado__c','Base da cotizacion quando ha exoneracao total','SIM, verificado em 14/08','Nada'],
 ['Desglose e congelamento','QuoteLineItem, e OrderItemTaxLineItem ou OrderItem','Persistir Precio Publico, Descuento, Subtotal, Impuesto, Retencion e Precio Final','Nao','Nada, sao os mesmos campos'],
 ['Indicador do documento','Quote.TaxConditionIndicator','Atributo do documento, editavel por perfil autorizado','Nao','Permission Set novo por sociedade'],
 ['Aprovacao','ApprovalProcess mais Queue','Exoneracao pedida sem respaldo no dado mestre','Padrao existe no Discount Approval','Fila nova por pais, se o negocio quiser'],
 ['Repuestos','SapMuleClient','Envia indicador e condicao, exibe MWST e J1RI','Classe existe, a chamada de preco nao','Nada no Salesforce, e SAP'],
 ['Redondeo','ReglaRedondeo__mdt','Por sociedade e moeda','Desenhado na HU-038','Registro novo'],
 ['Moeda','CurrencyType','CRC e USD ativas. GTQ, HNL e NIO nao','Parcial','ATIVAR ANTES de ter dado, taxa retroativa e cara'],
 ['Idioma','Translation Workbench','Metadado em ingles, exibicao em espanhol','Convencao vigente','Traducao nova, nao campo novo'],
 ['Venta guiada','GuidedSellingController, PricingService, QuoteOrderService','Ponto de invocacao da determinacao','SIM, extensao','Nada'],
]
ARQ = [['HU-105 - Arquitetura por camada, com a coluna que prova que o desenho aguenta o pais 2'],[''],HA] + A

# ---------------------------------------------------------------- aba verificacoes
HV = ['#','O que verificar','Como','Por que decide algo','Estado']
V = [
 ['V1','Existem TaxPolicy, TaxTreatment, TaxRate, LegalEntity, e sao criaveis','check-hu105-nativo-y-multipais.apex, bloco 1','Se existirem e forem criaveis, a tabela de tasas pode ser nativa e por sociedade, e nao se constroi matriz para isso','PENDENTE'],
 ['V2','Product2.TaxPolicyId existe','check-hu105-nativo-y-multipais.apex, bloco 2','Se existir, a RN-10 nao vira campo custom nenhum','PENDENTE'],
 ['V3','OrderItemTaxLineItem existe e e criavel','check-hu105-impuestos.apex, bloco 1','Decide se o desglose do pedido e nativo ou sete campos custom','PENDENTE'],
 ['V4','O BRE esta habilitado, CalculationMatrix e ExpressionSet','check-hu105-impuestos.apex, bloco 2','Sem BRE o desenho da HU-038 e o da HU-105 caem juntos','PENDENTE'],
 ['V5','Vehicle e Product2 ja tem campo fiscal','check-hu105-impuestos.apex, bloco 3','Evita criar campo duplicado, regra dura do projeto','PENDENTE'],
 ['V6','AccountAccountRelation esta em uso ou continua vazio','check-hu105-impuestos.apex, bloco 4','Decide se a relacao fiscal usa ele, usa LegalEntity ou vira objeto proprio','PENDENTE'],
 ['V7','IdentityDocument e TaxIdentification cobrem o documento de exoneracao','check-hu105-impuestos.apex, bloco 4','Evita criar campo de numero e vigencia de documento','PENDENTE'],
 ['V8','Quantas fontes de sociedade a org ja tem','check-hu105-nativo-y-multipais.apex, bloco 3','Amarrar imposto a uma oitava fonte repete o defeito da moeda de 14/08','PENDENTE'],
 ['V9','Moedas ativas contra os seis paises','check-hu105-nativo-y-multipais.apex, bloco 4','Nao bloqueia Costa Rica, bloqueia o pais de cada moeda que faltar','PENDENTE'],
 ['V10','Campo com pais cravado no API name','check-hu105-nativo-y-multipais.apex, bloco 4','A convencao GRPQM proibe. Se ja houver, e divida a declarar','PENDENTE'],
 ['V11','A base do gravame parcial e a tasa da unidade ou a do pais','Pergunta ao fiscal do GrupoQ','A RN-04 se contradiz com o proprio exemplo. Muda todo o calculo','BLOQUEIO'],
 ['V12','A tabela de tasas completa dos seis paises','Entrega do GrupoQ','Premissa declarada e nao entregue. GT e PA estao vazios na propria HU','BLOQUEIO'],
 ['V13','Ley 9518 de Costa Rica: o 4 por cento e IVA ou 1a matricula','Pergunta ao fiscal do GrupoQ','Costa Rica e a implantacao atual, entao bloqueia primeiro','BLOQUEIO'],
 ['V14','ZHYB_DBM_PRECIO_VTA_NO_MAESTRO existe no Mule','Time de integracao','Sem ele o imposto de Repuestos nao chega','BLOQUEIO'],
]
VER = [['HU-105 - Verificacoes que decidem o desenho. As dez primeiras rodam na org, as quatro ultimas dependem do cliente'],[''],HV] + V

out = '/home/user/diario-implantacao/docs/hu105/HU105_Tarefas_Tecnicas_v2.xlsx'
build(out, [('Tarefas',TAREFAS), ('Nativo Avaliado',NATIVO), ('Decisoes e Escopo',DEC),
            ('Arquitetura',ARQ), ('Verificacoes',VER)])
print('tarefas linhas:', len(T), '| nativo:', len(N), '| decisoes:', len(D),
      '| arquitetura:', len(A), '| verificacoes:', len(V))
for r in T:
    if r[0].startswith('T'):
        assert len(r) == 10, (r[0], len(r))
print('ok, todas as linhas de tarefa com 10 colunas')
