// Marca x Sociedade em objeto NATIVO AccountBrand (SEM custom object). DRY RUN no fim.
// 1 AccountBrand por (Account de sociedade x marca). Name = marca. Idempotente por Account+Name.
Schema.SObjectType abt=Schema.getGlobalDescribe().get('AccountBrand');
if(abt==null){System.debug('ABORT: AccountBrand ausente (precisa Digital Experiences/licenca community).');}
else{
Map<String,Schema.SObjectField> abf=abt.getDescribe().fields.getMap();
for(Schema.SObjectField f:abf.values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate()&&d.getName()!='Name')System.debug('REQ AccountBrand: '+d.getName()+' ('+d.getType()+')');}
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
Map<String,Set<String>> have=new Map<String,Set<String>>();
for(SObject a:Database.query('SELECT AccountId,Name FROM AccountBrand')){Object ac=a.get('AccountId');if(ac==null)continue;String k=''+ac;if(!have.containsKey(k))have.put(k,new Set<String>());Object nm=a.get('Name');if(nm!=null)have.get(k).add(((String)nm).toUpperCase());}
List<SObject> novo=new List<SObject>();
for(String row:M){List<String> pr=row.split(':');String code=pr[0];Id acc=socAcc.get(code);
 if(acc==null){System.debug('sociedade sem Account (pula): '+code);continue;}
 Set<String> hv=have.containsKey(''+acc)?have.get(''+acc):new Set<String>();
 for(String bn:pr[1].split(';')){if(hv.contains(bn))continue;SObject o=abt.newSObject();o.put('AccountId',acc);o.put('Name',bn);novo.add(o);System.debug('+ '+code+'|'+bn);}}
System.debug('AccountBrand a criar:'+novo.size());
if(!novo.isEmpty())insert novo;
}
System.debug('=== FIM (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
