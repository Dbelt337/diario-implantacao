Map<String,Schema.SObjectType> g=Schema.getGlobalDescribe();
Set<String> canon=new Set<String>{'C101','C105','C106-PROV','H101','H105','H106-PROV','S101','S105','S106-PROV','S206','N101','N105','N106-PROV','G101','G105','P103','P105'};
Set<String> cmt=new Set<String>();
try{for(SObject s:Database.query('SELECT DeveloperName FROM Sociedad_Config__mdt'))cmt.add((String)s.get('DeveloperName'));}catch(Exception e){System.debug('AUDIT> CMT ERRO/AUSENTE '+e.getMessage());}
Set<String> gv=new Set<String>();
Map<String,Schema.SObjectField> um=g.get('User').getDescribe().fields.getMap();
if(um.containsKey('sociedad__c'))for(Schema.PicklistEntry pe:um.get('sociedad__c').getDescribe().getPicklistValues())if(pe.isActive())gv.add(pe.getValue());
Set<String> acc=new Set<String>();
for(Account ac:[SELECT Name FROM Account WHERE Parent.ParentId!=null AND Parent.Parent.ParentId=null])acc.add(ac.Name);
for(String v:canon)System.debug('AUDIT> RECON '+v+' gvsUser='+(gv.contains(v)?'X':'-')+' cmt='+(cmt.contains(v)?'X':'-')+' acc='+(acc.contains(v)?'X':'-'));
for(String v:cmt)if(!canon.contains(v))System.debug('AUDIT> RECON EXTRA cmt '+v);
for(String v:gv)if(!canon.contains(v))System.debug('AUDIT> RECON EXTRA gvsUser '+v);
for(String v:acc)if(!canon.contains(v))System.debug('AUDIT> RECON EXTRA acc '+v);
if(g.get('Account').getDescribe().fields.getMap().containsKey('brandname__c')){
 System.debug('AUDIT> Dealers BrandName preench: '+Database.countQuery('SELECT COUNT() FROM Account WHERE Parent.Parent.ParentId!=null AND Parent.Parent.Parent.ParentId=null AND BrandName__c!=null'));
 System.debug('AUDIT> Dealers BrandName nulo: '+Database.countQuery('SELECT COUNT() FROM Account WHERE Parent.Parent.ParentId!=null AND Parent.Parent.Parent.ParentId=null AND BrandName__c=null'));
}else System.debug('AUDIT> Account.BrandName__c AUSENTE');
if(um.containsKey('sociedad__c'))for(AggregateResult r:(List<AggregateResult>)Database.query('SELECT Sociedad__c s,COUNT(Id) c FROM User WHERE IsActive=true GROUP BY Sociedad__c'))System.debug('AUDIT> UserSoc '+r.get('s')+'='+r.get('c'));
if(um.containsKey('sucursalbp__c'))System.debug('AUDIT> User ativos sem SucursalBP: '+Database.countQuery('SELECT COUNT() FROM User WHERE IsActive=true AND SucursalBP__c=null'));
try{for(SObject f:Database.query('SELECT ApiName,ProcessType,TriggerType FROM FlowDefinitionView WHERE IsActive=true'))System.debug('AUDIT> FLOW '+f.get('ApiName')+' '+f.get('ProcessType')+' '+f.get('TriggerType'));}catch(Exception e){System.debug('AUDIT> FLOW ERRO '+e.getMessage());}
