// Item A — Teste do composite encadeado por chave de negócio (Reparo Técnico + JIA + ticket 67890)
// Se "Unauthorized endpoint": criar Remote Site Setting com a URL do My Domain e repetir.
String q1=EncodingUtil.urlEncode('SELECT Id FROM Account WHERE DocumentNumber__c = \'11.222.333/0001-81\' LIMIT 1','UTF-8');
String q2=EncodingUtil.urlEncode('SELECT Id FROM WorkType WHERE Name = \'Reparo Técnico\' LIMIT 1','UTF-8');
String q3=EncodingUtil.urlEncode('SELECT Id FROM ServiceTerritory WHERE Name = \'JIA\' LIMIT 1','UTF-8');
List<Object> reqs=new List<Object>{
 new Map<String,Object>{'method'=>'GET','url'=>'/services/data/v63.0/query?q='+q1,'referenceId'=>'acc'},
 new Map<String,Object>{'method'=>'GET','url'=>'/services/data/v63.0/query?q='+q2,'referenceId'=>'wt'},
 new Map<String,Object>{'method'=>'GET','url'=>'/services/data/v63.0/query?q='+q3,'referenceId'=>'st'},
 new Map<String,Object>{'method'=>'POST','url'=>'/services/data/v63.0/sobjects/WorkOrder','referenceId'=>'wo',
  'body'=>new Map<String,Object>{'Subject'=>'Ticket 67890 - Teste composite encadeado',
   'Description'=>'Padrão ref-tickets-send-to-salesforce, dados variados',
   'AccountId'=>'@{acc.records[0].Id}','WorkTypeId'=>'@{wt.records[0].Id}','ServiceTerritoryId'=>'@{st.records[0].Id}'}}};
HttpRequest r=new HttpRequest();
r.setEndpoint(URL.getOrgDomainUrl().toExternalForm()+'/services/data/v63.0/composite');
r.setMethod('POST'); r.setHeader('Authorization','Bearer '+UserInfo.getSessionId());
r.setHeader('Content-Type','application/json');
r.setBody(JSON.serialize(new Map<String,Object>{'allOrNone'=>true,'compositeRequest'=>reqs}));
HttpResponse res=new Http().send(r);
System.debug('STATUS GERAL: '+res.getStatusCode());
System.debug(res.getBody());
