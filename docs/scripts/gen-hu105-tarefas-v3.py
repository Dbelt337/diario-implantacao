# -*- coding: utf-8 -*-
import sys
sys.path.insert(0, '/tmp')
from genxlsx import build

TIT = ('HU-105 - Tarefas Tecnicas v3 (18/08/2026, apos os describes na org) - Determinacion, Visualizacion y '
       'Aplicacion de Impuestos. Frente Sales: catalogo e venta guiada. Principio: nativo e existente ANTES de criar')

H = ['ID','Tarefa','Tipo de Metadata','Componente / API Name (GRPQM)','Detalle',
     'Depende de','Ref. HU / RN','Doc oficial','Falta / Nota','Estado (18/08)']

D_BRE  = 'developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/business_rules_engine.htm'
D_PP   = 'trailhead.salesforce.com/content/learn/modules/price-management-with-revenue-cloud/create-a-pricing-procedure-with-the-list-price-element'
D_CTX  = 'applikontech.com/context-definition-for-pricing-procedure/'
D_QLD  = 'developer.salesforce.com/docs/atlas.en-us.revenue_lifecycle_management_dev_guide.meta/revenue_lifecycle_management_dev_guide/sforce_api_objects_quotelinedetail.htm'
D_AUTO = 'Automotive Cloud Standard Objects (lista oficial)'
D_VEH  = 'developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehicle.htm'
D_AAR  = 'developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_accountaccountrelation.htm'
D_BP   = 'Automotive Cloud Standard Objects: BusinessProfile'
D_TAX  = 'trailhead.salesforce.com/content/learn/modules/billing-management-with-revenue-cloud/configure-taxes'
CONV   = 'Convencao de nomenclatura GRPQM'
LOG    = 'Log do describe de 18/08'

T = []
def t(*row):
    assert len(row) == 10, (row[0], len(row))
    T.append(list(row))

# ------------------------------------------------------------- bloco 0
T.append(['BLOCO 0','O QUE OS DESCRIBES DE 18/08 JA RESOLVERAM','','','','','','','',''])
t('T01','Describe fiscal na org','Verificacao','docs/scripts/check-hu105-impuestos.apex',
  'Rodado. Nenhum objeto fiscal nativo utilizavel, BRE completo, nenhum campo fiscal em Vehicle, VehicleDefinition, Product2 e Asset, e zero campo custom em QuoteLineItem, OrderItem e OpportunityLineItem',
  '','Todas',LOG,'Fecha V3 a V7','FEITO 18/08')
t('T02','Describe do modelo fiscal nativo e do multi pais','Verificacao','docs/scripts/check-hu105-nativo-y-multipais.apex',
  'Rodado. TaxPolicy, TaxRate, ProductTaxPolicy e TaxEngineProvider NAO existem. TaxTreatment existe e nao e criavel. LegalEntity existe, e criavel e tem zero registro. 14 sociedades em Sociedad_Config__mdt. CRC e USD ativas, faltam GTQ, HNL, NIO e PAB. Zero campo com pais no API name',
  '','RN-02, RN-15',LOG,'Fecha V1, V2, V8, V9 e V10','FEITO 18/08')
t('T03','Describe do motor de precos e do catalogo','Verificacao','docs/scripts/check-hu105-pricing-y-catalogo.apex',
  'NOVO e o mais importante. O log mostrou as lookup tables padrao do Salesforce Pricing ja na org: Price Book Entries V2, Volume Discount Entries, Tiered Adjustment Entries, Attribute Discount Entries, Bundle Based Adjustment Entries, Derived Pricing Entries, Contract Pricing Entries e Index Rate. Se o motor esta ligado, o imposto e um elemento do pricing procedure e nao uma classe Apex',
  '','RN-03, RN-19',D_PP,'Fecha V15 a V20. NADA se empacota antes disto','PENDENTE, rodar agora')
t('T04','Abrir a MatrizImpuestosReferencia antes de desenhar tabela de tasas','Verificacao','CalculationMatrix MatrizImpuestosReferencia',
  'Ja existe uma matriz com esse nome na org, vista no log de 18/08. Pode ja ser a tabela da RN-02, pode ser rascunho de outra equipe. Desenhar uma segunda antes de olhar esta e repetir o defeito da moeda de 14/08',
  'T03','RN-02',LOG,'Bloco 3 do script T03 lista as colunas','PENDENTE T03')

# ------------------------------------------------------------- bloco 1
T.append(['BLOCO 1','TABELA DE TASAS','','','','','','','',''])
t('T05','Tabela de tasas em Decision Matrix, decidido pelo describe','Decision','CalculationMatrix, reusando a da HU-038',
  'A alternativa nativa caiu: TaxPolicy e TaxRate nao existem nesta org. Elas pertencem ao Revenue Cloud Billing, e o billing e do SAP, entao nunca serao compradas por causa desta HU. Fica a Decision Matrix, que e o que a HU-038 ja desenhou e o que o BRE completo da org suporta',
  'T02, T04','RN-02, RN-22',D_TAX,'DECISAO FECHADA pelo log, nao reabrir','FECHADA 18/08')
t('T06','Reusar a matriz da HU-038, nunca criar uma segunda','Reuso','CalculationMatrix da HU-038, ou a MatrizImpuestosReferencia se servir',
  'Sociedade mais Caracteristica mais Condicion del cliente devolve a tasa. A HU-038 carrega do Impuestos_SAP.xlsx com KSCHL, ALAND, TAXK1 e MWSK1. A HU-105 consome. A org ja tem 15 matrizes, criar a decima sexta sem olhar as existentes e divida',
  'T04, T05','RN-02, RN-04','docs/hu038-precios-modelagem.md','A HU-038 tem que subir antes','PENDENTE HU-038')
t('T07','Carregar as tasas dos seis paises com versionado','Dados','CalculationMatrixVersion',
  'CR 13, GT 12, SV 13, HN 15, NI 15, PA 7. O versionado e nativo do objeto e cobre a RN-22, vigencia de mudanca de tasa, sem construir historico proprio',
  'T06','RN-02, RN-06','help.salesforce.com/s/articleView?id=ind.create_a_decision_table.htm','BLOQUEIO: premissa do GrupoQ, chega incompleta, GT e PA vazios','BLOQUEADO')
t('T08','Manutencao por negocio, sem deploy','PermissionSet','TaxRateAdministration',
  'A tasa muda por lei e nao pode depender de release. A propria documentacao do BRE usa este argumento: regra em dado responde a mudanca regulatoria sem deploy. E o que sustenta o multi pais',
  'T06','RN-22',D_BRE,'Definir quais perfis de negocio editam','PENDENTE')
t('T09','Pais e dimensao de dado, nunca nome de metadado','Padrao','Revisao de nomenclatura de tudo que a HU criar',
  'O describe de 18/08 mostrou zero campo com pais no API name em Account, Product2, Quote e PricebookEntry. A org esta limpa nisso hoje e a HU-105 nao pode ser a primeira a sujar',
  'T02','Convencao GRPQM',CONV,'Vale para todos os componentes desta HU','VERIFICADO 18/08')

# ------------------------------------------------------------- bloco 2
T.append(['BLOCO 2','CONDICAO FISCAL DA UNIDADE','','','','','','','',''])
t('T10','Campo do percentual de imposto da unidade','CustomField','Vehicle.TaxRatePercent (Percent)',
  'CONFIRMADO pelo describe: Vehicle, VehicleDefinition, Product2 e Asset nao tem NENHUM campo fiscal. Nao ha o que reusar. O percentual vem do maestro de inventario do SAP e representa cem por cento do imposto daquela unidade, por unidade fisica e nao por modelo',
  'T01','RN-03',D_VEH,'Description obrigatoria com paises, proposito e dependencias','CONFIRMADO, construir')
t('T11','Exoneracao por modelo e versao','CustomField','Product2.IsTaxExempt (Checkbox)',
  'A alternativa nativa caiu: Product2.TaxPolicyId nao existe e ProductTaxPolicy nao existe nesta org. Campo custom e o caminho. Decidir ainda se o negocio administra em Product2, que e o catalogo, ou em VehicleDefinition, que e a especificacao',
  'T02','RN-10',D_AUTO,'Product2 contra VehicleDefinition segue aberto','CONFIRMADO, construir')
t('T12','Exoneracao por unidade','CustomField','Vehicle.IsTaxExempt (Checkbox)',
  'Guatemala exonera por antiguidade da unidade, dois anos. E por unidade e nao por modelo. Nao construir agora, so nao fechar o desenho sem ele, porque e o campo que prova que o modelo aguenta o pais 2',
  'T10','RN-11',D_VEH,'GTQ nem sequer esta ativa como moeda','PENDENTE, pais 2')
t('T13','Trazer o percentual fiscal da unidade do SAP','Integracao','MuleSoft, replica de inventario',
  'O percentual da unidade e a fonte da RN-03 e nao existe em lugar nenhum da org hoje. Sem ele a determinacao nao roda em nenhum pais. Pedir ao time de Mule o campo na replica',
  'T10','RN-03, Premissa 1','Inventario de integracoes','Pedido ainda nao feito ao time de Mule','PENDENTE')
t('T14','Declarar os campos fiscais na Context Definition','ContextDefinition','Extensao da context definition do pricing',
  'TAREFA QUE NAO ESTAVA EM NENHUMA LISTA. Campo custom so chega ao motor de precos se estiver declarado no contexto. Sem isto o TaxRatePercent existe no Vehicle e o calculo nao enxerga. Se o T03 confirmar o motor ligado, esta tarefa e obrigatoria e vem antes do calculo',
  'T03, T10','RN-03',D_CTX,'Depende do resultado do T03','PENDENTE T03')

# ------------------------------------------------------------- bloco 3
T.append(['BLOCO 3','CONDICAO FISCAL DO CLIENTE, POR SOCIEDADE','','','','','','','',''])
t('T15','Resolver a duplicidade do identificador fiscal do cliente','Divida','Account.TaxID__c contra BusinessProfile.BusinessTaxIdentifier',
  'O describe achou os dois. BusinessTaxIdentifier e campo PADRAO do BusinessProfile, do Automotive. TaxID__c e custom em Account. Sao duas fontes para o mesmo dado, o mesmo defeito da moeda de 14/08. Escolher uma, backfill, repontar e aposentar a outra, nunca sincronizar por Flow',
  'T01','RN-15, Governanca 14/08',D_BP,'Decidir ANTES de amarrar imposto em qualquer uma','ACHADO 18/08')
t('T16','Escolher UMA fonte de sociedade','Decision','Sociedad_Config__mdt contra Account.Sociedad__c contra LegalEntity',
  'O describe achou tres. Sociedad_Config__mdt tem 14 registros com rotulo inconsistente, G105 e P103 ao lado de Sociedad C101. Account.Sociedad__c e TEXTAREA, texto livre sem integridade. LegalEntity e nativa, criavel e esta vazia. Amarrar imposto a uma quarta fonte, ou a um textarea, e retrabalho garantido',
  'T02','RN-15, Governanca 14/08',LOG,'DECISAO DE ARQUITETURA. 14 sociedades no metadata contra 12 no escopo','ACHADO 18/08')
t('T17','Relacao fiscal cliente x sociedade','CustomField','AccountAccountRelation, campos fiscais',
  'A RN-15 exige cliente x SOCIEDAD e nao cliente x pais: uma conta opera com mais de uma sociedade e so Costa Rica ja tem duas, C101 Autos e C105 Motos. O describe confirmou AccountAccountRelation com 26 campos, nenhum fiscal, e zero registro. E nativa do Automotive, personalizavel, com History e Share',
  'T16','RN-15',D_AAR,'Objeto existe e esta vazio, entao entra sem migracao','CONFIRMADO, construir')
t('T18','Campos de classificacao fiscal na relacao','CustomField','TaxClassification, WithholdingRate, PerceptionRate',
  'Indicador de imposto de venda, retencao e percepcao. Sao dado fixo do cliente e nao decisao do assessor. Percentual e nao valor, porque a base muda por documento. El Salvador retem 1 ou 13 por cento, entao o campo e por sociedade e nao por conta',
  'T17','RN-05, RN-06, RN-15',D_AAR,'','PENDENTE T17')
t('T19','Campos e arquivo da exoneracao','CustomField mais Files','ExemptionType, ExemptionDocumentNumber, ExemptionValidUntil',
  'TaxIdentification NAO existe nesta org e IdentityDocument tem 20 campos e nenhum fiscal, entao nao ha nativo que cubra. Total ou parcial, numero do documento e vigencia. O arquivo vai por Files, que e nativo',
  'T17','RN-07, RN-08, RN-09',LOG,'O Escenario 6 depende da vigencia','CONFIRMADO, construir')
t('T20','Ligar historico de campo na relacao fiscal','Object Manager','AccountAccountRelationHistory',
  'A RN-108 pede auditoria das mudancas fiscais. O objeto de historico ja existe, e so habilitar por campo. Zero componente criado',
  'T18','GQ-MK-03-108',D_AAR,'Vinte campos por objeto e o teto do historico','PENDENTE')
t('T21','Restringir quem edita o dado fiscal do cliente','PermissionSet mais FLS','FiscalDataMaintenance',
  'So Cuentas por Cobrar e Finanzas editam, e os dados se completam automaticamente na criacao do cliente. Assessor le e nao escreve',
  'T18','RN-15','Resposta do GrupoQ na propria HU','','PENDENTE')

# ------------------------------------------------------------- bloco 4
T.append(['BLOCO 4','DETERMINACAO, DENTRO DO MOTOR DE PRECOS','','','','','','','',''])
t('T22','Decidir onde a determinacao roda','Decision','Elemento no pricing procedure contra Expression Set chamado por Apex',
  'A documentacao e explicita: um pricing procedure E um Expression Set, e cada elemento e um passo que referencia uma lookup table, do mesmo jeito que Attribute Discount Entries referencia Attribute Based Adjustment. Se o motor esta ligado, o imposto e mais um passo e nao uma classe. Isso apaga a TaxDeterminationService da lista',
  'T03','RN-03, RN-04',D_PP,'DECISAO DE ARQUITETURA, decidida pelo T03','PENDENTE T03')
t('T23','Elemento fiscal no pricing procedure','ExpressionSet','Passo de imposto no pricing procedure existente',
  'Cruza condicao fiscal da unidade contra condicao do cliente e devolve a tasa aplicavel, consultando a tabela do T06. Roda junto com o preco, no mesmo motor, sem segundo ponto de invocacao para manter',
  'T14, T22','RN-03, RN-04',D_PP,'','PENDENTE T22')
t('T24','Ordem: imposto primeiro, retencao sobre o resultado','ExpressionSet','Dois passos ordenados no procedure',
  'Calcula o imposto de venda e sobre o resultado a retencao. A ordem esta explicita na RN-05 e e facil de inverter. Em pricing procedure a ordem e o proprio desenho do stack, o que torna o erro visivel em vez de escondido em codigo',
  'T23','RN-05','RN-05 literal','Teste dedicado','PENDENTE')
t('T25','Gravame parcial sobre a tasa DA UNIDADE','ExpressionSet','Passo do gravame',
  'Gravado a vinte por cento sobre unidade de 13 da 2,6. Sobre unidade eletrica de 4 da 0,8. A proporcao e sobre a tasa da unidade e nao sobre a geral do pais',
  'T23','RN-04, Escenario 3','RN-04 e Escenario 3','AMBIGUIDADE: a RN-04 exemplifica com a tasa do pais e se contradiz. Confirmar com o fiscal deles','BLOQUEADO')
t('T26','Entrada da determinacao e a sociedade, nao o pais','Padrao','Context definition e chave da matriz',
  'A sociedade traz o pais. Se a entrada for o pais, o dia em que duas sociedades do mesmo pais tributarem diferente o desenho quebra, e Costa Rica ja tem duas. E o teste do multi pais nesta HU',
  'T16, T23','RN-15','C101 Autos e C105 Motos','','PENDENTE')

# ------------------------------------------------------------- bloco 5
T.append(['BLOCO 5','DESGLOSE E CONGELAMENTO','','','','','','','',''])
t('T27','Decidir onde o desglose e persistido','Decision','QuoteLineDetail nativo contra campos custom em QuoteLineItem',
  'QuoteLineDetail existe no modelo de Revenue Management para representar a quebra de uma linha, incluindo a matematica do preco. Se estiver nesta org, sete campos custom deixam de ser criados. O describe ja provou que QuoteLineItem tem ZERO campo custom hoje, entao a folha esta limpa nos dois caminhos',
  'T03','RN-19',D_QLD,'DECISAO DE ARQUITETURA, decidida pelo T03','PENDENTE T03')
t('T28','Campos de desglose na linha da cotizacion','CustomField','QuoteLineItem: PublicPrice, DiscountAmount, Subtotal, TaxRate, TaxAmount, WithholdingAmount, FinalPrice',
  'So se o T27 disser que nao ha nativo. A RN-19 exige persistir na linha porque e o que congela o preco e alimenta o PDF e os relatorios',
  'T27','RN-19, Escenario 11',D_QLD,'Sete campos, todos com Description pela convencao','PENDENTE T27')
t('T29','Desglose na linha do pedido','CustomField ou Nativo','OrderItemTaxLineItem, ou os mesmos campos em OrderItem',
  'OrderItemTaxLineItem existe nesta org, e criavel e esta vazio. O que nao existe e motor que o alimente, porque TaxPolicy e TaxTreatment criavel nao estao la. Avaliar se vale usar so como estrutura de dado',
  'T28','RN-19, Escenario 14',LOG,'Sem engine nativa, alguem tem que escrever nele','PENDENTE T27')
t('T30','Separar imposto do veiculo e imposto dos acessorios','CustomField','AccessoryTaxAmount',
  'Quando a unidade e exonerada ou tem tasa reduzida, os acessorios mantem a tasa geral. O resumo mostra os dois separados',
  'T28','RN-12, GQ-CA-01-064','GQ-CA-01-064','Depende do T11','PENDENTE')
t('T31','Congelar a determinacao na conversao','ApexClass','QuoteOrderService, extensao',
  'Cotizacion vira reserva e depois pedido conservando o imposto determinado, sem recalcular. A classe ja existe em DEV, isto e extensao e nao construcao',
  'T29','RN-19, Escenario 14','Codigo em DEV','Reaproveitamento direto','PENDENTE')
t('T32','Redondeo por sociedade e moeda','Reuso','ReglaRedondeo__mdt da HU-038',
  'Cada operacao formata a duas decimais, o IVA calcula por posicao e arredonda por linha, resposta do proprio GrupoQ. Ja desenhado na HU-038, a HU-105 so chama',
  'T31','RN-20','docs/hu038-precios-modelagem.md','Nao criar regra de arredondamento propria','PENDENTE HU-038')

# ------------------------------------------------------------- bloco 6
T.append(['BLOCO 6','INDICADOR NO DOCUMENTO E APROVACAO','','','','','','','',''])
t('T33','Indicador fiscal no documento, editavel por perfil','CustomField mais PermissionSet','Quote.TaxConditionIndicator',
  'Atributo do documento comercial, mesmo criterio ja usado para a moeda. A resposta do GrupoQ na HU e Permission Set por sociedade',
  'T18','RN-16, FA-04','Resposta do GrupoQ na propria HU','Definir os perfis por sociedade','PENDENTE')
t('T34','Exoneracao declarada no proprio documento','CustomField','Quote.IsVehicleTaxExempt',
  'Indicar na reserva que o veiculo e exonerado mesmo sem estar marcado no catalogo. Nao altera o dado mestre',
  'T33','RN-10 segunda parte','GQ-CA-01-070','','PENDENTE')
t('T35','Aprovacao da exoneracao nao registrada','ApprovalProcess','Submit Tax Exemption Request',
  'Se o documento pede exoneracao que o cliente nao tem no dado mestre, bloqueia o avanco e gera solicitacao. O padrao ja existe na org no Discount Approval da Opportunity, entao e copia de padrao aprovado e nao invencao',
  'T33','RN-14, FA-01, Escenario 5','Processo ja existente em DEV','','PENDENTE')
t('T36','Fila de Impuestos e validation rules','Group ou Queue mais ValidationRule','GRP_Impuestos, Tax Exemption Requires Approval, Exemption Document Must Be Valid',
  'Destino da solicitacao, bloqueio do avanco enquanto nao aprovada, e bloqueio de documento vencido informando o motivo',
  'T35','RN-09, RN-14, Escenario 6','Limite de 255 caracteres na Description, ja batemos nele','Duas VR e uma fila','PENDENTE')

# ------------------------------------------------------------- bloco 7
T.append(['BLOCO 7','REPUESTOS E PA, ONDE O SALESFORCE NAO CALCULA','','','','','','','',''])
t('T37','Enviar indicador fiscal e condicao do cliente ao servico de precos','ApexClass','SapMuleClient',
  'Repuestos e PA nao calculam imposto no Salesforce. O indicador e a condicao viajam como parametro e o SAP devolve o valor. E a pratica de industria quando o ERP e o sistema de registro fiscal, e aqui o SAP e inteiro do GrupoQ',
  'T33','RN-16, Escenario 12','Inventario de integracoes','BLOQUEIO: ZHYB_DBM_PRECIO_VTA_NO_MAESTRO nao existe no SapMuleClient','BLOQUEADO')
t('T38','Persistir aliquota e valor de MWST e J1RI por material','CustomField','Os mesmos campos do T28, reusados',
  'Salesforce exibe e persiste o que o SAP devolve, sem recalcular. Mesmo padrao do AvailabilityStatus da HU-043. Nao se cria um segundo conjunto de campos so para Repuestos',
  'T37','RN-16','docs/hu043','Reuso de campo, nao criacao','PENDENTE')
t('T39','Reconsulta ao trocar o indicador fiscal','ApexClass','RepuestosLineService',
  'Em Repuestos a troca do indicador dispara reconsulta de todas as linhas ao SAP. Em Autos dispara recalculo local. Sao dois comportamentos e a HU trata como um so',
  'T37','FA-04, Escenario 15','FA-04','A HU trata os dois como um so, separar','PENDENTE')
t('T40','Cobros adicionais sujeitos ou isentos','Modelagem','OrderAdjustmentGroup, avaliar antes de criar objeto',
  'Flete, sobrecusto de pedido emergente e similares. O describe confirmou OrderAdjustmentGroup na org, com 22 campos. Avaliar antes de modelar objeto proprio',
  'T38','RN-17, GQ-PV-02-025',LOG,'Objeto existe, falta ver se serve','PENDENTE')

# ------------------------------------------------------------- bloco 8
T.append(['BLOCO 8','MULTI PAIS','','','','','','','',''])
t('T41','Ativar as moedas antes de ter dado no pais','Setup','CurrencyType',
  'O describe confirmou CRC e USD ativas, USD corporativa. GTQ, HNL, NIO e PAB nao estao. Nao bloqueia Costa Rica e bloqueia cada pais na entrada. Ativar depois de ja ter documento exige taxa de cambio retroativa, que e caro e sujo',
  'T02','Multi pais',LOG,'Levantar com a Melisa na entrada de cada pais','ACHADO 18/08')
t('T42','Tasa por sociedade e nao por pais, no dado','Padrao','Chave da matriz do T06',
  'A chave e sociedade e a sociedade traz o pais. Duas sociedades do mesmo pais podem tributar diferente por atividade, e Autos e Motos em Costa Rica ja sao duas. Chave por pais e retrabalho garantido no pais 2',
  'T06, T26','RN-15','C101 Autos e C105 Motos','','PENDENTE')
t('T43','Nenhuma regra fiscal em codigo de pais','Padrao','Revisao dos passos do pricing procedure',
  'Ley 9518 de Costa Rica, os dois anos da Guatemala e a retencao de El Salvador entram como linha de tabela e nao como ramo de if. E o argumento da propria documentacao do BRE: mudanca regulatoria sem deploy',
  'T23','Multi pais',D_BRE,'Criterio de revisao de codigo desta HU','PENDENTE')
t('T44','Traducao pela Translation Workbench','Translation','Translation Workbench',
  'Metadado nasce em ingles e a exibicao vai em espanhol, pela convencao GRPQM. Campo por idioma multiplica por seis e nao escala',
  'T28','Convencao GRPQM',CONV,'Traduzir tudo que a HU criar','PENDENTE')

# ------------------------------------------------------------- bloco 9
T.append(['BLOCO 9','REUSO CONFIRMADO E FECHAMENTO','','','','','','','',''])
t('T45','Reusar PrecioExonerado e PrecioExoneradoMinimo','Reuso','PricebookEntry.PrecioExonerado__c, PrecioExoneradoMinimo__c',
  'CONFIRMADO no describe de 18/08, junto com Gastos__c e PrecioMinimoAsesor__c. Exoneracao total cotiza com eles em vez do Precio de Lista. Zero componente novo',
  '','RN-07, Escenario 4',LOG,'Nao criar nada aqui','FEITO')
t('T46','Reusar o percentual de 1a matricula da HU-038','Reuso','PricebookEntry, campo de 1a matricula',
  'Administrado como percentual na entrada de lista, irmao do Gastos__c. Sua alteracao nao dispara aprovacao de precos',
  '','RN-13, Escenarios 9 e 10','docs/hu038-precios-modelagem.md','','PENDENTE HU-038')
t('T47','Reusar o Nebula Logger para erro de determinacao','Reuso','Nebula Logger, ja instalado',
  'Nao criar campo de ultimo erro nem contador de retentativa em objeto nenhum. Foi o erro apontado no pacote da HU-039',
  'T23','Governanca 14/08','docs/hu039-cobertura-tecnica-2026-08-13.md','Zero campo custom de log','PENDENTE')
t('T48','Trigger Order em qualquer flow que a HU criar','Object Manager','Trigger Order de cada flow novo',
  'A org tem 39 automacoes concentradas em Lead, Account e Opportunity. Ordem entre flows do mesmo objeto e gatilho so e previsivel com Trigger Order definida em cada um',
  '','Governanca 14/08','docs/scripts/inventario-automacoes-e-campos.apex','Vale tambem para Quote e Order','PENDENTE')
t('T49','Testes dos quinze escenarios','ApexClass','Testes do procedure e da conversao',
  'Cobrir os escenarios 1 a 15 com enfase no 2, no 3 e no 8, que sao os que a RN-04 e a RN-05 tornam faceis de errar. Um caso por sociedade para provar que nao ha regra cravada em codigo',
  'T24, T43','Todos','Escenarios da propria HU','Um caso por sociedade','PENDENTE')

TAREFAS = [[TIT],[''],H] + T

# ------------------------------------------------------------- aba nativo
HN = ['#','Necessidade (RN)','Candidato nativo ou ja existente','De onde vem','Resposta da org (18/08)','Veredito','Fundamento']
N = []
def n(*r):
    assert len(r) == 7, (r[0], len(r))
    N.append(list(r))

n('N01','Tabela de tasas por pais (RN-02)','TaxRate','Revenue Cloud Billing','NAO EXISTE na org','DESCARTADO',
  'Pertence ao Revenue Cloud Billing e o billing e do SAP. Nunca sera comprado por causa desta HU. Fica a Decision Matrix')
n('N02','Tasa por sociedade (RN-15)','TaxPolicy mais TaxTreatment','Revenue Cloud Billing','TaxPolicy NAO existe. TaxTreatment existe e NAO e criavel','DESCARTADO',
  'Sem TaxPolicy criavel nao ha como cadastrar nada. TaxTreatment sozinho e objeto de sistema, so leitura')
n('N03','Exoneracao por modelo (RN-10)','Product2.TaxPolicyId e ProductTaxPolicy','Revenue Cloud Billing','Nenhum dos dois existe','DESCARTADO',
  'Vira campo custom em Product2. Verificado campo a campo, Product2 nao tem nenhum campo fiscal')
n('N04','Sociedade como entidade (RN-15)','LegalEntity','Plataforma','Existe, criavel, 26 campos, ZERO registro','NAO INTRODUZIR AGORA',
  'A org ja tem Sociedad_Config__mdt com 14 registros e Account.Sociedad__c. Trazer a LegalEntity vazia seria a terceira fonte de sociedade, que e exatamente o defeito que a governanca proibe')
n('N05','Desglose por linha de pedido (RN-19)','OrderItemTaxLineItem','Order Management','Existe, criavel, vazio','ESTRUTURA SIM, MOTOR NAO',
  'O objeto esta la mas nao ha engine fiscal nativa para alimenta lo, porque TaxPolicy nao existe. Avaliar so como forma de dado')
n('N06','Desglose na cotizacion (RN-19)','QuoteLineDetail','Revenue Management','T03 responde','VERIFICAR ANTES DE CRIAR',
  'Representa a quebra de uma linha de cotizacion, incluindo a matematica do preco. Se estiver na org, apaga sete campos custom')
n('N07','Motor de determinacao (RN-03)','Pricing procedure do Salesforce Pricing','Revenue Cloud, frente Sales','As lookup tables padrao JA ESTAO na org','CAMINHO PROVAVEL',
  'A documentacao diz que um pricing procedure e ele mesmo um Expression Set, e cada elemento referencia uma lookup table. O imposto vira um passo, nao uma classe Apex')
n('N08','Campo fiscal chegar ao calculo','Context Definition','Revenue Cloud, frente Sales','T03 responde','OBRIGATORIO SE O MOTOR ESTIVER LIGADO',
  'Campo custom so entra no calculo se declarado no contexto. Nao estava em nenhuma lista e sem ele o campo existe e o motor nao ve')
n('N09','Tabela de tasas ja existente','CalculationMatrix MatrizImpuestosReferencia','Alguem ja criou nesta org','EXISTE','ABRIR ANTES DE CRIAR',
  'Ha 15 matrizes na org e uma se chama MatrizImpuestosReferencia. Desenhar outra sem olhar esta e repetir o caso do CountryCurrency__mdt')
n('N10','Gravame parcial (RN-04)','nao ha nativo','','','CONSTRUIR no BRE',
  'Proporcao sobre a tasa da unidade nao e expressavel em tabela de tasa. Vai como passo, que e configuracao e nao codigo')
n('N11','Retencao e percepcao (RN-05, RN-06)','nao ha nativo','','','CONSTRUIR no BRE',
  'Retencao na fonte sobre o resultado e regra latino americana. Nem o modelo nativo de imposto trata, quando existe')
n('N12','Percentual fiscal da unidade (RN-03)','Vehicle, campos padrao','Automotive Cloud','NENHUM campo fiscal em Vehicle, VehicleDefinition, Product2 e Asset','CONSTRUIR',
  'Verificado campo a campo por rotulo e por API name. Automotive Cloud nao tem objeto nem campo de imposto')
n('N13','Relacao cliente x sociedade (RN-15)','AccountAccountRelation','Automotive Cloud','Existe, 26 campos, nenhum fiscal, zero registro','REUSAR O OBJETO, ACRESCENTAR CAMPO',
  'Nativa, personalizavel, com History e Share. Esta vazia, entao entra sem migracao')
n('N14','Identificador fiscal do cliente','BusinessProfile.BusinessTaxIdentifier','Automotive Cloud','EXISTE, e padrao. E Account.TaxID__c custom tambem existe','DUPLICIDADE A RESOLVER',
  'Duas fontes para o mesmo dado. O padrao deveria ganhar. Escolher, backfill, repontar e aposentar, nunca sincronizar por Flow')
n('N15','Documento de exoneracao (RN-08)','TaxIdentification e IdentityDocument','Plataforma e Industries','TaxIdentification NAO existe. IdentityDocument existe com 20 campos e nenhum fiscal','CONSTRUIR',
  'Nao ha nativo que carregue tipo, numero e vigencia de exoneracao')
n('N16','Arquivo da exoneracao (RN-08)','Files','Plataforma','Existe','REUSAR','Anexo e nativo, nao se modela armazenamento')
n('N17','Auditoria da mudanca fiscal (RN-108)','AccountAccountRelationHistory','Plataforma','Objeto de historico existe','REUSAR',
  'Historico de campo e nativo, basta habilitar. Nao se constroi objeto de auditoria')
n('N18','Preco exonerado (RN-07)','PricebookEntry.PrecioExonerado__c','Projeto, ja construido','EXISTE, confirmado no describe','REUSAR',
  'Junto com PrecioExoneradoMinimo__c, Gastos__c e PrecioMinimoAsesor__c')
n('N19','Percentual de 1a matricula (RN-13)','PricebookEntry, campo da HU-038','Projeto, HU-038','Desenhado','REUSAR','Irmao do Gastos__c, a HU-105 so consome')
n('N20','Redondeo (RN-20)','ReglaRedondeo__mdt','Projeto, HU-038','Desenhado','REUSAR','Por sociedade e moeda, ja resolvido')
n('N21','Vigencia de mudanca de tasa (RN-22)','CalculationMatrixVersion','BRE','BRE completo na org','REUSAR',
  'Nao construir historico de tasa. O versionado e nativo e e o que a RN-22 pede')
n('N22','Log de erro','Nebula Logger','Ja instalado','SIM','REUSAR',
  'Nao criar campo de ultimo erro nem contador de retentativa. Licao do pacote de 18 campos da HU-039')
n('N23','Aprovacao da exoneracao (RN-14)','ApprovalProcess do Discount Approval','Ja existe em DEV','SIM','REUSAR O PADRAO',
  'Copiar o padrao aprovado em vez de desenhar um fluxo novo de aprovacao')
n('N24','Cobros adicionais (RN-17)','OrderAdjustmentGroup','Order Management','Existe, 22 campos','AVALIAR ANTES DE CRIAR',
  'Ajuste de pedido ja e modelado. Ver se serve antes de modelar objeto de cobro')
n('N25','Cumprimento fiscal e livro legal (RN-21)','SAP','ERP do GrupoQ','Fora do Salesforce','NAO CONSTRUIR',
  'Salesforce nao gera arquivo de obrigacao legal. Fronteira de responsabilidade, o SAP e inteiro deles')

NATIVO = [['HU-105 - Nativo Avaliado. 25 necessidades cruzadas contra a plataforma e contra a org. A coluna Resposta da org e o resultado dos describes de 18/08, nao suposicao'],[''],HN] + N

# ------------------------------------------------------------- aba decisoes
HD = ['Tema','Decisao','Por que','Fonte','Estado']
D = [
 ['Principio','Nativo e existente antes de criar','25 necessidades cruzadas na aba Nativo Avaliado, e as respostas vieram de describe rodado na org e nao de suposicao. Oito viram reuso direto, quatro foram descartadas como nativo, tres esperam o T03, e o resto e construcao com motivo escrito','Describes de 18/08','APLICADO'],
 ['Principio','O desenho nasce multi pais','Costa Rica e a implantacao, mas sao seis paises. Tasa e chave de tabela, nunca ramo de codigo, e a chave e a SOCIEDADE e nao o pais. A org hoje esta limpa: zero campo com pais no API name','Convencao GRPQM e describe de 18/08','APLICADO'],
 ['RETRATACAO','O modelo fiscal nativo NAO serve, ao contrario do que a v2 propos','A v2 apostou em LegalEntity, TaxPolicy, TaxTreatment e TaxRate depois da pesquisa. O describe mostrou que TaxPolicy, TaxRate, ProductTaxPolicy e TaxEngineProvider nao existem nesta org, e que TaxTreatment nao e criavel. Esses objetos sao do Revenue Cloud Billing, e billing e do SAP','Log de 18/08','FECHADA'],
 ['Frente','Commerce e outra frente, aqui e Sales','O modelo fiscal que a pesquisa achou vive no Commerce e no Billing. O que interessa a esta HU e o Salesforce Pricing do catalogo e da venta guiada, e ele JA esta na org: as lookup tables padrao de preco apareceram no describe','Log de 18/08','FECHADA'],
 ['Motor de determinacao','Passo no pricing procedure, nao classe Apex','A documentacao diz que um pricing procedure e ele mesmo um Expression Set, e cada elemento e um passo que le uma lookup table. Se o motor esta ligado, o imposto entra como passo. Isso apaga a TaxDeterminationService que a v1 e a v2 listavam','Documentacao do Salesforce Pricing','ABERTA, T03 confirma'],
 ['Context Definition','Campo fiscal so vale se declarado no contexto','Descoberta da pesquisa que nao estava em nenhuma lista. Sem declarar, o campo existe no Vehicle e o motor nao enxerga. Vira tarefa obrigatoria e anterior ao calculo','Documentacao do Salesforce Pricing','ABERTA, T03 confirma'],
 ['Escopo do motor fiscal','A HU-105 CONSOME, nao constroi o motor','A tabela de tasas, a matriz de 1a matricula e a regra de redondeo ja foram desenhadas na HU-038, e a condicao fiscal do cliente na HU-017','docs/hu038-precios-modelagem.md','FECHADA'],
 ['Objeto de imposto do Automotive','Nao existe, e agora esta provado','A lista oficial nao tem objeto fiscal e o describe confirmou: Vehicle, VehicleDefinition, Product2 e Asset com ZERO campo fiscal','Log de 18/08','FECHADA'],
 ['Matriz de impostos','Ja ha uma na org, abrir antes de desenhar','MatrizImpuestosReferencia apareceu entre as 15 matrizes. Desenhar outra sem olhar esta e repetir o caso do CountryCurrency__mdt de 14/08','Log de 18/08','ABERTA, T04'],
 ['Identificador fiscal do cliente','Ha duplicidade e ela e anterior a esta HU','BusinessProfile.BusinessTaxIdentifier e padrao do Automotive. Account.TaxID__c e custom. Duas fontes para o mesmo dado. Resolver antes de amarrar imposto em qualquer uma delas','Log de 18/08','ABERTA, T15'],
 ['Fonte de sociedade','Tres fontes hoje, e uma delas e texto livre','Sociedad_Config__mdt com 14 registros e rotulo inconsistente, Account.Sociedad__c como TEXTAREA sem integridade, e LegalEntity nativa e vazia. Escolher uma antes de amarrar imposto','Log de 18/08','ABERTA, T16'],
 ['Regra fiscal em codigo','Proibida','Mudanca de tasa e mudanca de lei e nao pode depender de release. A documentacao do BRE usa exatamente este argumento','Business Rules Engine, documentacao oficial','FECHADA'],
 ['Repuestos e PA','Salesforce nao calcula imposto','O indicador viaja como parametro e a resposta do SAP e exibida e persistida sem recalculo. E a pratica de industria quando o ERP e o sistema de registro fiscal','RN-16','FECHADA'],
 ['Cumprimento fiscal','Permanece no SAP','Salesforce nao gera arquivo de obrigacao legal nem livro fiscal','RN-21','FECHADA'],
 ['Precio de Lista','Com IVA incluido em veiculos','Mantem a pratica atual. Em Repuestos varia por pais e continua pendente','RN-18','ABERTA'],
]
DEC = [['HU-105 - Decisoes e Escopo v3. Inclui a retratacao do que a v2 propos'],[''],HD] + D

# ------------------------------------------------------------- aba arquitetura
HA = ['Camada','Componente','Papel','Ja existe? (describe 18/08)','O que muda no pais 2']
A = [
 ['Tabela de tasas','CalculationMatrix, da HU-038 ou a MatrizImpuestosReferencia','Sociedade mais Caracteristica mais Condicion del cliente devolve a tasa','BRE completo. Uma matriz de impostos ja existe, conteudo a verificar','Linha nova na tabela, zero deploy'],
 ['Motor','Passo fiscal no pricing procedure','Roda junto com o preco, sem segundo ponto de invocacao','Lookup tables padrao de preco JA na org','Nada, se nenhuma regra estiver em codigo'],
 ['Contexto','Context Definition estendida','Faz o campo fiscal chegar ao calculo','A verificar no T03','Nada'],
 ['Condicao da unidade','Vehicle.TaxRatePercent','Percentual da unidade, do maestro de inventario do SAP','NAO existe, Vehicle tem zero campo fiscal','Nada, o campo e por unidade'],
 ['Exoneracao por modelo','Product2.IsTaxExempt','Marca, modelo e versao exonerados','NAO existe, e nao ha politica fiscal nativa','Dado novo, nao metadado'],
 ['Exoneracao por unidade','Vehicle.IsTaxExempt','Guatemala, por antiguidade da unidade','NAO existe','Este campo NASCE no pais 2, previsto desde agora'],
 ['Sociedade','Sociedad_Config__mdt, Account.Sociedad__c ou LegalEntity','Chave fiscal do documento e da relacao com o cliente','TRES fontes, uma delas TEXTAREA. Escolher no T16','Registro novo, zero deploy'],
 ['Identificador fiscal','BusinessProfile.BusinessTaxIdentifier','Documento fiscal do cliente','EXISTE e e padrao, mas Account.TaxID__c duplica','Nada'],
 ['Condicao do cliente','AccountAccountRelation mais campos fiscais','Classificacao, retencao, percepcao e exoneracao por sociedade','Objeto existe e esta vazio. Campos nao existem','Registro novo por sociedade'],
 ['Preco exonerado','PricebookEntry.PrecioExonerado__c','Base da cotizacion quando ha exoneracao total','SIM, confirmado no describe','Nada'],
 ['Desglose e congelamento','QuoteLineDetail nativo, ou campos em QuoteLineItem','Persistir Precio Publico, Descuento, Subtotal, Impuesto, Retencion e Precio Final','QuoteLineItem com ZERO campo custom hoje. QuoteLineDetail a verificar','Nada, sao os mesmos campos'],
 ['Indicador do documento','Quote.TaxConditionIndicator','Atributo do documento, editavel por perfil autorizado','NAO existe','Permission Set novo por sociedade'],
 ['Aprovacao','ApprovalProcess mais Queue','Exoneracao pedida sem respaldo no dado mestre','Padrao existe no Discount Approval','Fila nova, se o negocio quiser'],
 ['Repuestos','SapMuleClient','Envia indicador e condicao, exibe MWST e J1RI','Classe existe, a chamada de preco nao','Nada no Salesforce, e SAP'],
 ['Redondeo','ReglaRedondeo__mdt','Por sociedade e moeda','Desenhado na HU-038','Registro novo'],
 ['Moeda','CurrencyType','CRC e USD ativas, USD corporativa','FALTAM GTQ, HNL, NIO e PAB','ATIVAR ANTES de ter documento, cambio retroativo e caro'],
 ['Idioma','Translation Workbench','Metadado em ingles, exibicao em espanhol','Convencao vigente','Traducao nova, nao campo novo'],
 ['Venta guiada','GuidedSellingController, PricingService, QuoteOrderService','Ponto de entrada da cotizacion','SIM, extensao','Nada'],
]
ARQ = [['HU-105 - Arquitetura por camada. A coluna Ja existe agora traz o resultado do describe, e a ultima e o teste do pais 2'],[''],HA] + A

# ------------------------------------------------------------- aba verificacoes
HV = ['#','O que verificar','Como','Resposta','Estado']
V = [
 ['V1','TaxPolicy, TaxTreatment, TaxRate e LegalEntity existem e sao criaveis','check-hu105-nativo-y-multipais.apex','TaxPolicy e TaxRate NAO existem. TaxTreatment existe e nao e criavel. LegalEntity existe, e criavel e esta vazia','RESPONDIDO 18/08'],
 ['V2','Product2.TaxPolicyId existe','check-hu105-nativo-y-multipais.apex','Nao existe. ProductTaxPolicy tambem nao','RESPONDIDO 18/08'],
 ['V3','OrderItemTaxLineItem existe e e criavel','check-hu105-impuestos.apex','Existe, criavel, vazio. Mas sem engine fiscal nativa para alimentar','RESPONDIDO 18/08'],
 ['V4','O BRE esta habilitado','check-hu105-impuestos.apex','Completo: CalculationMatrix, versoes, colunas, linhas, ExpressionSet e DecisionMatrixDefinition. 15 matrizes ja criadas','RESPONDIDO 18/08'],
 ['V5','Vehicle e Product2 ja tem campo fiscal','check-hu105-impuestos.apex','NENHUM, em Vehicle, VehicleDefinition, Product2 e Asset','RESPONDIDO 18/08'],
 ['V6','AccountAccountRelation esta em uso','check-hu105-impuestos.apex','26 campos, nenhum fiscal, zero registro. Entra sem migracao','RESPONDIDO 18/08'],
 ['V7','IdentityDocument ou TaxIdentification cobrem o documento de exoneracao','check-hu105-impuestos.apex','TaxIdentification nao existe. IdentityDocument tem 20 campos e nenhum fiscal. Nao cobrem','RESPONDIDO 18/08'],
 ['V8','Quantas fontes de sociedade a org tem','check-hu105-nativo-y-multipais.apex','TRES: Sociedad_Config__mdt com 14 registros e rotulo inconsistente, Account.Sociedad__c TEXTAREA, e LegalEntity vazia','RESPONDIDO 18/08'],
 ['V9','Moedas ativas contra os seis paises','check-hu105-nativo-y-multipais.apex','CRC e USD ativas, USD corporativa. Faltam GTQ, HNL, NIO e PAB','RESPONDIDO 18/08'],
 ['V10','Campo com pais cravado no API name','check-hu105-nativo-y-multipais.apex','Zero. A org esta limpa e a HU-105 nao pode ser a primeira a sujar','RESPONDIDO 18/08'],
 ['V15','O motor de precos do Sales esta ligado','check-hu105-pricing-y-catalogo.apex, bloco 1','Decide se o imposto e passo do procedure ou classe Apex. Muda a lista inteira do bloco 4','PENDENTE'],
 ['V16','QuoteLineDetail existe na org','check-hu105-pricing-y-catalogo.apex, bloco 2','Decide se o desglose e nativo ou sete campos custom em QuoteLineItem','PENDENTE'],
 ['V17','O que a MatrizImpuestosReferencia ja tem dentro','check-hu105-pricing-y-catalogo.apex, bloco 3','Pode ja ser a tabela da RN-02. Se for, nao se cria nenhuma','PENDENTE'],
 ['V18','Ha expression set com uso de Pricing','check-hu105-pricing-y-catalogo.apex, bloco 4','E o lugar onde o passo fiscal entra','PENDENTE'],
 ['V19','Existe Context Definition para estender','check-hu105-pricing-y-catalogo.apex, bloco 1','Sem declarar o campo no contexto, o motor nao enxerga o TaxRatePercent','PENDENTE'],
 ['V20','Como o catalogo esta organizado, familia e price books','check-hu105-pricing-y-catalogo.apex, bloco 5','Define onde a exoneracao por modelo e administrada','PENDENTE'],
 ['V11','A base do gravame parcial e a tasa da unidade ou a do pais','Pergunta ao fiscal do GrupoQ','A RN-04 se contradiz com o proprio exemplo. Muda todo o calculo','BLOQUEIO'],
 ['V12','A tabela de tasas completa dos seis paises','Entrega do GrupoQ','Premissa declarada e nao entregue. GT e PA estao vazios na propria HU','BLOQUEIO'],
 ['V13','Ley 9518 de Costa Rica: o 4 por cento e IVA ou 1a matricula','Pergunta ao fiscal do GrupoQ','Costa Rica e a implantacao atual, entao bloqueia primeiro','BLOQUEIO'],
 ['V14','ZHYB_DBM_PRECIO_VTA_NO_MAESTRO existe no Mule','Time de integracao','Sem ele o imposto de Repuestos nao chega','BLOQUEIO'],
]
VER = [['HU-105 - Verificacoes. V1 a V10 ja respondidas pelos describes de 18/08. V15 a V20 saem do script novo. V11 a V14 dependem do cliente'],[''],HV] + V

out = '/home/user/diario-implantacao/docs/hu105/HU105_Tarefas_Tecnicas_v3.xlsx'
build(out, [('Tarefas',TAREFAS), ('Nativo Avaliado',NATIVO), ('Decisoes e Escopo',DEC),
            ('Arquitetura',ARQ), ('Verificacoes',VER)])
print('tarefas:', len(T), '| nativo:', len(N), '| decisoes:', len(D),
      '| arquitetura:', len(A), '| verificacoes:', len(V))
