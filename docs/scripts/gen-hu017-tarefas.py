# -*- coding: utf-8 -*-
import sys
sys.path.insert(0,'/tmp')
from hu064 import build   # reaproveita o writer

H = ['ID','Tarefa','Tipo de Metadata','Componente / API Name (GRPQM)','O que fazer',
     'Depende de','Ref. HU / RN','Estado']
T=[]
def t(*r):
    assert len(r)==8, (r[0], len(r))
    T.append(list(r))
def b(n,tit): T.append([n,tit,'','','','','',''])

b('BLOCO 0','VERIFICAR O QUE JA EXISTE')
t('T01','Rodar o describe do cliente maestro','Verificacao','docs/scripts/check-hu017-cliente-maestro.apex',
  'Rodar e usar o resultado para fechar T03, T05, T07, T12, T13, T27 e T30. Responde Record Types de Account, se AccountContactRelation esta ligado, os campos do IdentityDocument, quais objetos de ContactPoint e consentimento existem, se Account tem campo unico e quais Duplicate Rules estao ativas',
  '','Todas','A FAZER')
t('T02','Levantar o que as duas aprovacoes ativas ja cobrem','Verificacao','MDM_Conta_Sensivel e AprobacionDatosSensiblesCuenta',
  'Abrir os dois processos de aprovacao ativos em Account e listar quais campos disparam. A RN-23 pode ja estar entregue',
  '','RN-23, CA-14','A FAZER')

b('BLOCO 1','MODELO DO CLIENTE MAESTRO')
t('T03','Record Types de tipo de cliente','RecordType','Account: PersonaFisica, PersonaJuridica, Extranjero',
  'Criar os que faltarem. Persona Fisica sobre Person Account, Juridica sobre Business Account, Extranjero como terceiro tipo. Confirmar no T01 o que ja existe antes de criar',
  'T01','RN-03, CA-02','A FAZER')
t('T04','Campo unico de identidade do cliente','CustomField','Account.MasterCustomerKey (Text, Unico, External Id)',
  'Criar o campo com documento normalizado mais pais emissor. E o unico mecanismo determinista da CA-01: Duplicate Rule com EnforceSharingRules deixa passar quando o usuario nao enxerga o registro existente, que e exatamente o cenario da RN-25',
  'T01','RN-02, CA-01','A FAZER')
t('T05','Onde mora o documento de identidade','Decision','IdentityDocument nativo, ou campos em Account',
  'Decidir com o T01. O IdentityDocument tem IdDocumentType, IssuingAuthority, IssueDate, ExpirationDate e verificacao, mas so tem lookup para PartyProfile e LegalEntity. Se nao alcancar Account, o documento vira campo',
  'T01','RN-02, Escenario 5','A FAZER')
t('T06','Preencher a chave unica por regra','Flow','Account, before save',
  'Montar a chave a partir do tipo de documento, numero e pais, normalizando antes de gravar. Roda em criacao manual, conversao de lead, carga e integracao',
  'T04','RN-02, RN-15, CA-12','A FAZER')
t('T07','Ligar a relacao cliente x contato','Object Manager','AccountContactRelation',
  'Habilitar contatos em varias contas se o T01 mostrar desligado, e definir os valores de papel do contato',
  'T01','RN-04, CA-03','A FAZER')
t('T08','Campos locais da extensao por sociedade','CustomField','AccountAccountRelation: area de ventas, canal de pago, canal de facturacion, estado',
  'Criar os campos que guardam o dado local de cada sociedade. O objeto ja existe e esta vazio, entra sem migracao',
  'T01','RN-05, CA-04','A FAZER')
t('T09','Tela de extensao a outra sociedade','Screen Flow','ExtendCustomerToSociety',
  'Pedir apenas os dados locais faltantes e criar o registro de relacao, sem gerar novo identificador maestro. Componentes reativos, GA no Winter 24, e sem LWC. A lista de sociedades onde o cliente ainda NAO esta estendido sai de um Collection Choice Set calculado antes da tela, porque Choice Option nao e reativa',
  'T08','RN-05, Escenario 2','A FAZER')
t('T09a','Subir os flows para API 59.0 ou superior','Setup','Versao de API dos flows da HU',
  'A preferencia de opt in da beta de componentes reativos expira. Sem API 59.0 a reatividade da tela nao vale',
  'T09','RN-05','A FAZER')
t('T10','Aposentar Account.Sociedad__c','Divida','Account.Sociedad__c (TEXTAREA)',
  'Campo de sociedade em texto livre na conta, que contradiz a RN-05 e nao tem integridade. Fazer backfill para AccountAccountRelation, repontar o que usa e desativar. Nao sincronizar os dois por Flow',
  'T08','RN-05, Governanca','ACHADO 18/08')
t('T11','Cliente sem vendedor proprietario','Setup','Account, dono padrao',
  'Definir dono padrao da conta como usuario ou fila de dados maestros, nunca o assessor. O assessor se associa ao documento comercial',
  '','RN-06, CA-05','A FAZER')
t('T12','Cliente originador e terceiro faturado','CustomField','Account ou Quote, relacao entre as partes',
  'Registrar quem negocia e quem fatura quando forem diferentes, conservando o usuario final do veiculo. Verificar antes se AccountAccountRelation ja serve',
  'T08','RN-07','A FAZER')
t('T13','Baixa logica do cliente','CustomField mais Flow','Account: estado e vigencia',
  'Inativar por estado ou data, tirar das list views operativas e conservar o historico. Sem exclusao fisica. Checar antes se ha campo de estado em Account',
  'T01','RN-10, CA-17, Escenario 9','A FAZER')

b('BLOCO 2','QUALIDADE DO DADO')
t('T14','Tabela de regras de documento por pais','CustomMetadata','DocumentRuleByCountry',
  'Tipos de documento admitidos e formato por pais, editavel em Setup sem desenvolvimento. Uma linha por pais e tipo',
  '','RN-12, RN-21, CA-07','A FAZER')
t('T15','Tabela de regras de telefone por pais','CustomMetadata','PhoneRuleByCountry',
  'Prefixo, comprimento e digito inicial de movel por pais',
  '','RN-14, CA-09','A FAZER')
t('T16','Validacao de documento e telefone','ValidationRule ou Flow','Account',
  'Aplicar as duas tabelas na gravacao e informar o formato esperado quando falhar. Description ate 255 caracteres',
  'T14, T15','RN-12, RN-14, Escenario 3','A FAZER')
t('T17','Correio de faturacao separado do comercial','Decision mais CustomField','ContactPointEmail nativo, ou campo em Account',
  'Decidir com o T01. Se ContactPointEmail existir, usar o tipo de uso para separar faturacao de comercial em vez de criar campo',
  'T01','RN-13, CA-08','A FAZER')
t('T18','Exigir o correio de faturacao so onde aplica','Dynamic Forms','Pagina de Account',
  'Marcar o campo como obrigatorio por regra de visibilidade quando o pais exigir faturacao eletronica, e esconder onde nao aplica. Condicionar campo a campo, nunca a secao, porque regra de secao so e avaliada depois de salvar',
  'T17','RN-13, Escenario 4','A FAZER')
t('T19','Obrigatoriedade configuravel por pais, sociedade e tipo','Dynamic Forms','Pagina de Account por Record Type',
  'Montar as regras de obrigatoriedade em Dynamic Forms, que desde Winter 23 suporta Person Account. Sem desenvolvimento e sem codigo',
  'T03','RN-11, CA-06','A FAZER')
t('T20','Normalizacao antes de gravar','Flow','Account, before save',
  'Normalizar nome, documento, telefone, correio e endereco antes de gravar, para as regras de coincidencia operarem sobre valores comparaveis',
  '','RN-15, CA-10','A FAZER')
t('T21','Definir as chaves de coincidencia','Documentacao','Entrega para a HU-006',
  'Exata sobre documento mais pais, difusa sobre nome, correio, telefone e razao social. Esta HU define, a HU-006 configura',
  'T04','RN-16, CA-11','A FAZER')
t('T22','Fechar o furo de compartilhamento na Duplicate Rule','Setup','DuplicateRule de Account, securityOption',
  'Com EnforceSharingRules o insert passa em silencio quando o usuario nao enxerga o duplicado. Decidir entre BypassSharingRules, que revela existencia, e depender do campo unico do T04',
  'T04','RN-17, CA-01, CA-12','A FAZER')
t('T23','Registro incompleto nao persiste','Flow','Account, depuracao',
  'Depurar os registros cuja criacao nao se completou ou ficaram em erro de integracao',
  '','RN-19, CA-19','A FAZER')

b('BLOCO 3','GOVERNANCA DO DADO')
t('T24','Reusar as aprovacoes de dado sensivel','Reuso','MDM_Conta_Sensivel e AprobacionDatosSensiblesCuenta',
  'Partir dos dois processos que ja estao ativos em Account. Ajustar apenas os campos que disparam, conforme a RN-23: nome, documento, endereco fiscal, correio de faturacao e telefone principal',
  'T02','RN-23, CA-14','JA EXISTE, ajustar')
t('T25','Reusar Aprobador_Config__mdt','Reuso','Aprobador_Config__mdt e SensitiveDataApprover__mdt',
  'Usar o metadata de aprovador que ja existe para determinar o avaliador por tipo de dado, sociedade e papel',
  'T24','RN-23','JA EXISTE')
t('T26','Historico de campo nos campos priorizados','Object Manager','Account, Field History Tracking',
  'Selecionar ate 20 campos, comecando pelos sensiveis da RN-23. Field Audit Trail nao esta licenciado e a propria HU reconhece',
  'T24','RN-24, CA-13','A FAZER')
t('T27','OWD de Account privada','Setup','Organization Wide Defaults',
  'Deixar Account como Private. Sharing rule concede acesso e nunca restringe, entao sem OWD privada a RN-25 nao se sustenta',
  '','RN-25, CA-15','A FAZER')
t('T27a','Verificar o operador do criterio de sharing rule','Verificacao','Setup, Sharing Settings',
  'Abrir uma criteria-based sharing rule de Account e ver se o operador contains esta disponivel para campo texto. Decide entre um campo texto com 14 regras ou 14 checkbox com 14 regras',
  '','RN-25','A FAZER')
t('T27b','Marca das sociedades habilitadas na conta','CustomField','Account, um checkbox por sociedade, ou um texto com a lista',
  'Criar a marca que a sharing rule vai ler. Nao e a chave maestra, e derivado da AccountAccountRelation, entao nao conflita com a unicidade da RN-05. Confirmar essa leitura com a Melisa antes de empacotar',
  'T27a','RN-05, RN-25','A FAZER')
t('T27c','Flow que estampa a marca de sociedade','Flow','AccountAccountRelation, apos criar, atualizar e excluir',
  'Manter a marca da T27b sincronizada com os registros de relacao. E o contorno que a propria documentacao de sharing rule indica: automacao mantem o campo, a regra le o campo',
  'T27b','RN-05, RN-25','A FAZER')
t('T27d','Public group por sociedade','Group','Um public group por sociedade',
  'Criar os grupos ANTES das regras. O Share With de uma sharing rule nao pode ser editado depois de salvar, so apagando e recriando a regra',
  '','RN-25','A FAZER')
t('T27e','Criteria-based sharing rules por sociedade','SharingRules','Account, uma regra por sociedade',
  'Uma regra por sociedade lendo a marca da T27b e concedendo ao grupo da T27d. Teto de 50 regras por criterio por objeto, e 14 sociedades cabem. Decidir ANTES de salvar a opcao Include records owned by users who cannot have an assigned role, que vem marcada e nao pode ser editada depois',
  'T27b, T27c, T27d','RN-25, Escenario 7','A FAZER')
t('T27f','Diferir o recalculo na carga inicial','Setup','Defer Sharing Calculations',
  'Ligar o Defer Sharing Calculations antes da carga em massa de clientes e recalcular depois. E o remedio que a propria documentacao recomenda para atualizacao em larga escala',
  'T27e','RN-25','A FAZER')
t('T27g','Declarar o acesso implicito pela conta pai','Documentacao','Risco a escrever na HU',
  'Quem tem acesso a uma Opportunity, Case ou Contact ganha visibilidade da conta pai. Entao o Escenario 7 nao e hermetico: o assessor ve o cliente pelo negocio que e dele, independente da sociedade. Escrever na HU antes de UAT. Se o negocio quiser hermetismo, a restricao sobe para Opportunity, Quote e Order, e isso e outra historia',
  'T27e','RN-25, Escenario 7','A DECLARAR')
t('T28','Modelo de permissoes e FLS','PermissionSet mais FLS','MasterDataAdmin, MasterDataRead',
  'Separar quem administra o maestro de quem so cria e atualiza dentro do perfil, com FLS nos campos sensiveis',
  'T27','RN-22, RN-25, CA-15','A FAZER')
t('T29','Marca de nao sincronizado com SAP','CustomField','Account: estado de sincronizacao e ultimo erro',
  'Marcar o cliente como nao sincronizado quando a replicacao falhar. Registrar o erro no Nebula Logger pela acao invocavel de Flow, sem escrever Apex e sem criar campo de log',
  '','RN-26, RN-27, CA-18, Escenario 8','A FAZER')
t('T30','Atributos fiscais derivados por regra','Flow ou ExpressionSet','Account, derivacao automatica',
  'Derivar tipo de imposto, condicao de pagamento, classificacao B2C ou B2B, grupo de contas e lista de precos a partir do tipo de documento e de cliente. Nao se mostram na captura e sao sensiveis para a replicacao',
  'T14','RN-32','A FAZER')

b('BLOCO 4','PROTECAO DO DADO')
t('T31','Documento de respaldo com principal','CustomField mais Files','Account, marcacao de documento principal',
  'Guardar identificacao, registro tributario e poderes como Files, com um campo que marque o principal. O expediente comercial e da HU-078',
  '','RN-31, CA-16','A FAZER')
t('T32','Ligar Data Protection and Privacy','Setup','Objetos de consentimento',
  'Os objetos de consentimento so existem com a preferencia habilitada. Ligar antes de a HU-034 precisar',
  'T01','RN-33','A FAZER')
t('T33','Consentimento como dado do cliente','Reuso','Individual, ContactPointTypeConsent',
  'Guardar consentimento e canal de preferencia nos objetos nativos. ContactPointTypeConsent tem BusinessBrandId, entao consentimento por marca sai nativo, o que importa num grupo multimarca',
  'T32','RN-33','A FAZER')
t('T34','Declarar o que depende de licenca nao contratada','Documentacao','Riscos da HU',
  'Cifrado at rest exige Shield e retencao com anonimizacao exige Privacy Center, nenhum dos dois licenciado. FLS e masking cobrem visibilidade e nao substituem cifra. Registrar como premissa, nao como tarefa',
  '','RN-29, RN-30','BLOQUEADO')
t('T35','Nao usar Dynamic Forms como seguranca','Padrao','Revisao das paginas',
  'Campo escondido por regra de visibilidade continua acessivel em relatorio, list view e API. Proteger dado sensivel so por FLS',
  'T19','RN-29','A FAZER')

b('BLOCO 5','MULTI PAIS E FECHAMENTO')
t('T36','Pais e dimensao de dado, nunca nome de metadado','Padrao','Revisao de nomenclatura',
  'As regras por pais vivem nas tabelas do T14 e T15. Nenhum campo, flow ou classe com pais no API name',
  'T14','Convencao GRPQM','A FAZER')
t('T37','Traduzir os rotulos para espanhol','Translation','Translation Workbench',
  'Traduzir campos, valores de picklist, Record Types e mensagens de erro criados nesta HU',
  'T16','Convencao GRPQM','A FAZER')
t('T38','Trigger Order nos flows criados','Object Manager','Trigger Order de cada flow em Account',
  'Account ja e um dos objetos com mais automacao na org. Definir a ordem em cada flow novo',
  'T20','Governanca','A FAZER')
t('T39','Testes dos nove escenarios','Flow Test','Testes dos flows acionados por registro',
  'Cobrir os escenarios 1 a 9 com Flow Test, que versiona junto com o flow. Enfase no 1, no 2 e no 7, e o 7 testado com usuario de outra sociedade, nunca com administrador',
  'T27e','Todos','A FAZER')

# ---------------------------------------------------------- aba nativo
HN = ['#','Requisito (RN / CA)','Candidato nativo ou ja existente','Veredito','Nota']
N=[]
def n(*r):
    assert len(r)==5, (r[0], len(r))
    N.append(list(r))

n('N01','RN-02, CA-01 identificador unico','Duplicate Rule mais Matching Rule','NAO BASTA',
  'Com securityOption EnforceSharingRules o insert passa em silencio se o usuario nao enxerga o duplicado, que e o cenario da RN-25. Com Block a API respeita, mas o furo do compartilhamento continua')
n('N02','RN-02 identificador unico','Campo unico mais External Id em Account','CONSTRUIR',
  'Unico mecanismo determinista. Mesma solucao do RequestKey__c da HU-039')
n('N03','RN-02, Escenario 5 documento de identidade','IdentityDocument','VERIFICAR NO T01',
  'Tem tipo, autoridade emissora, emissao, vencimento e verificacao. Mas os lookups sao PartyProfile e LegalEntity, nao Account')
n('N04','RN-03, CA-02 tipos de cliente','Person Account e Record Type','REUSAR','Person Account ja habilitado na org')
n('N05','RN-04, CA-03 cliente com varios contatos','AccountContactRelation','REUSAR','Padrao, precisa estar habilitado')
n('N06','RN-05, CA-04 extensao por sociedade','AccountAccountRelation','REUSAR',
  'Existe na org, 26 campos, zero registro. Entra sem migracao')
n('N07','RN-05 sociedade na conta','Account.Sociedad__c','DIVIDA A REMOVER',
  'TEXTAREA em texto livre. Contradiz a propria RN-05 e nao tem integridade referencial')
n('N07b','RN-05, Escenario 2 tela de extensao','Screen Flow com componentes reativos','REUSAR, SEM LWC',
  'Reactive Screen Components GA no Winter 24 e Repeater no Spring 24, com pre carga no Winter 25. Componente reativo nao funciona dentro do Repeater')
n('N07c','Testes','Flow Test','REUSAR, SEM CLASSE DE TESTE',
  'Sem Apex nao ha classe de teste. Flow Test versiona junto com o flow')
n('N08','RN-11, CA-06 obrigatorios por pais e tipo','Dynamic Forms','REUSAR',
  'Suporta Person Account desde Winter 23 e permite comportamento Required condicional. Regra de secao so e avaliada depois de salvar, entao condicionar campo a campo')
n('N09','RN-12, RN-14, RN-21 regras por pais','Custom Metadata Type','CONSTRUIR',
  'Editavel em Setup sem desenvolvimento, que e o que a RN-21 exige')
n('N10','RN-13, CA-08 correio de faturacao','ContactPointEmail','VERIFICAR NO T01',
  'Se existir, o tipo de uso separa faturacao de comercial sem criar campo')
n('N11','RN-16, CA-11 chaves de coincidencia','Matching Rules','REUSAR','Esta HU define as chaves, a HU-006 configura')
n('N12','RN-18 fusao de duplicados','Merge nativo, inclusive Person Account','REUSAR','Operacao administrativa padrao')
n('N13','RN-20 carga massiva','Data Loader e Bulk API','REUSAR','Capacidade padrao. A HU so fixa a regra')
n('N14','RN-23, CA-14 aprovacao de dado sensivel','MDM_Conta_Sensivel e AprobacionDatosSensiblesCuenta','JA EXISTE E ESTA ATIVO',
  'Mais Aprobador_Config__mdt, SensitiveDataApprover__mdt e o permission set MDG Aprobador. Praticamente entregue')
n('N15','RN-24, CA-13 auditoria','Field History Tracking','REUSAR PARCIAL',
  'Teto de 20 campos por objeto. Field Audit Trail nao licenciado')
n('N16','RN-25, CA-15 visibilidade por sociedade','Restriction Rules','NAO SERVE',
  'Nao cobre Account. Disponivel so para objetos custom, external, contratos, eventos, tarefas e time sheets')
n('N17','RN-25 visibilidade por sociedade','Sharing Rule por criterio','NAO SERVE',
  'So le campo da propria conta, e a RN-05 proibe campo de sociedade na conta')
n('N18','RN-25, Escenario 7 visibilidade por sociedade','Flow que estampa a marca mais criteria-based sharing rule','CONSTRUIR DECLARATIVO',
  'E o contorno que a propria doc de sharing rule indica para campo nao suportado: automacao mantem um campo texto ou checkbox, a regra le o campo. Zero Apex')
n('N18b','RN-25 visibilidade por sociedade','Flow criando AccountShare direto','DESCARTADO',
  'De fora do Apex so se escreve share com RowCause Manual, e share manual e apagado quando o dono muda. Motivo proprio de compartilhamento exige Apex Sharing Reason')
n('N18c','RN-25 limite de regras','300 sharing rules por objeto, 50 por criterio','CABE',
  '14 sociedades cabem com folga nas duas variantes')
n('N19','RN-29 protecao de dado sensivel','FLS e masking','REUSAR',
  'Cobre visibilidade. Nao cobre cifra at rest, que exige Shield e nao esta licenciado')
n('N20','RN-30 retencao e anonimizacao','Privacy Center','NAO LICENCIADO',
  'Versao nativa da plataforma faz retencao e mascaramento, mas e add on pago')
n('N21','RN-31, CA-16 documentos','Salesforce Files e ContentDocumentLink','REUSAR','Falta so um campo que marque o principal')
n('N22','RN-33 consentimento','Individual, ContactPointTypeConsent, DataUsePurpose','REUSAR',
  'Exige a preferencia Data Protection and Privacy habilitada. Tem BusinessBrandId, entao consentimento por marca e nativo')
n('N23','RN-26, RN-27 erro de replicacao','Nebula Logger','REUSAR','Ja instalado. Nao criar campo de log nem contador de retentativa')
n('N24','RN-06, CA-05 conta sem dono vendedor','Dono padrao e fila','REUSAR','Configuracao, nao construcao')
n('N25','RN-09 pedido nao altera o maestro','Regra de processo','NAO CONSTRUIR','E criterio de desenho, nao componente')

TIT = 'HU-017 - Tarefas Tecnicas - Busqueda y Gestion del Cliente Maestro en Salesforce. Native first: zero Apex e zero LWC'
TN  = 'HU-017 - Nativo avaliado antes de criar. Verificar no T01 significa que o describe ainda nao rodou'
build('/home/user/diario-implantacao/docs/hu017/HU017_Tarefas_Tecnicas.xlsx',
      [('Tarefas', [[TIT],[''],H]+T, [8,50,26,52,88,14,28,18]),
       ('Nativo Avaliado', [[TN],[''],HN]+N, [8,40,44,26,80])])
print('tarefas:', len([r for r in T if r[0].startswith('T')]), '| nativo:', len(N))
