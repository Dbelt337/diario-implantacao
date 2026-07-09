// Junção Marca x Sociedade. Rodar APOS deploy do objeto Marca_Sociedad__c. DRY RUN no fim.
// Cria juncoes para as sociedades que ja tem Account (CR: C101/C105). Idempotente por Codigo__c.
Schema.SObjectType jt=Schema.getGlobalDescribe().get('Marca_Sociedad__c');
if(jt==null){System.debug('ABORT: deploy o objeto Marca_Sociedad__c primeiro (ver metadata/objects/Marca_Sociedad__c).');}
else{
List<String> M=new List<String>{
 'H101:CHERY;CHEVROLET;CHRYSLER;FIAT;MAZDA;NISSAN','H105:FORLAND',
 'N101:CHERY;CHEVROLET;NISSAN','N105:FORLAND;TVS;VENTO',
 'S101:CHERY;CHRYSLER;FIAT;HONDA;HYUNDAI;ISUZU;NISSAN;PORSCHE','S105:FORLAND;GWM',
 'S206:FORD;MAZDA','G101:CHERY;CHRYSLER;FIAT;HYUNDAI;MAZDA;PEUGEOT;ROWOR',
 'P103:CHERY;CHEVROLET;PEUGEOT','P105:GWM','C101:CHEVROLET;HYUNDAI;ISUZU','C105:ARCFOX;FORLAND'};
Map<String,Id> socAcc=new Map<String,Id>();
for(String code:new List<String>{'H101','H105','N101','N105','S101','S105','S206','G101','P103','P105','C101','C105'}){
 String pat='%'+code+'%';
 for(Account a:[SELECT Id,Name FROM Account WHERE Name LIKE :pat]){if(!socAcc.containsKey(code))socAcc.put(code,a.Id);}
}
Map<String,Id> brand=new Map<String,Id>();
for(BusinessBrand b:[SELECT Id,Name FROM BusinessBrand])brand.put(b.Name.toUpperCase(),b.Id);
Set<String> exist=new Set<String>();
for(SObject o:Database.query('SELECT Codigo__c FROM Marca_Sociedad__c'))if(o.get('Codigo__c')!=null)exist.add((String)o.get('Codigo__c'));
List<SObject> novo=new List<SObject>();
for(String row:M){List<String> pr=row.split(':');String code=pr[0];Id acc=socAcc.get(code);
 if(acc==null){System.debug('sociedade sem Account (pula): '+code);continue;}
 for(String bn:pr[1].split(';')){Id bid=brand.get(bn);
  if(bid==null){System.debug('marca sem BusinessBrand: '+bn);continue;}
  String key=code+'|'+bn;if(exist.contains(key))continue;
  SObject o=jt.newSObject();o.put('Sociedad__c',acc);o.put('Marca__c',bid);o.put('Codigo__c',key);novo.add(o);System.debug('+ '+key);}}
System.debug('Juncoes a criar:'+novo.size());
if(!novo.isEmpty())insert novo;
}
System.debug('=== FIM (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
