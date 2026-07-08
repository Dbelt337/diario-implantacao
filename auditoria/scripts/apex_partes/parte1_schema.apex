Map<String,Schema.SObjectType> g=Schema.getGlobalDescribe();
for(String o:new List<String>{'Account','BusinessProfile','InternalOrganizationUnit','BranchUnit','ServiceTerritory','BusinessBrand','User'})
 System.debug('AUDIT> obj '+o+': '+(g.containsKey(o)?'PRESENTE':'AUSENTE'));
for(RecordType r:[SELECT DeveloperName,IsActive FROM RecordType WHERE SobjectType='Account'])
 System.debug('AUDIT> AccRT '+r.DeveloperName+' active='+r.IsActive);
if(g.containsKey('Account')){Map<String,Schema.SObjectField> m=g.get('Account').getDescribe().fields.getMap();
 for(String f:m.keySet()){Schema.DescribeFieldResult d=m.get(f).getDescribe();String n=d.getName().toLowerCase();
  if(d.isCustom()||n.contains('sociedad')||n.contains('brand')||n.contains('marca')||n.contains('code')||n.contains('sap'))
   System.debug('AUDIT> Acc.f '+d.getName()+' '+d.getType()+' ref='+d.getReferenceTo());}}
if(g.containsKey('User')){Map<String,Schema.SObjectField> m=g.get('User').getDescribe().fields.getMap();
 for(String f:new List<String>{'sociedad__c','sucursalbp__c','tipoautoquevende__c','canal__c'})
  System.debug('AUDIT> User.'+f+': '+(m.containsKey(f)?'PRESENTE':'AUSENTE'));}
if(g.containsKey('BusinessProfile')){Map<String,Schema.SObjectField> m=g.get('BusinessProfile').getDescribe().fields.getMap();
 for(String f:m.keySet()){Schema.DescribeFieldResult d=m.get(f).getDescribe();
  if(d.getType()==Schema.DisplayType.REFERENCE)for(Schema.SObjectType t:d.getReferenceTo())
   if(t.getDescribe().getName()=='Account')System.debug('AUDIT> BP->Account lookup: '+d.getName());}}
