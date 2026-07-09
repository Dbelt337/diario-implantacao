// PARTE B test drive: ServiceTerritory por sucursal (dealer CR) + ServiceTerritoryWorkType +
// ServiceTerritoryMember + vinculo BusinessProfile.ServiceTerritoryId. DRY RUN. Rodar APOS Parte A.
for(String o:new List<String>{'ServiceTerritory','ServiceTerritoryWorkType','ServiceTerritoryMember'}){Schema.SObjectType t=Schema.getGlobalDescribe().get(o);for(Schema.SObjectField f:t.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate()&&d.getName()!='Name')System.debug('REQ '+o+': '+d.getName()+' ('+d.getType()+')');}}
Id wtId; for(SObject s:Database.query('SELECT Id FROM WorkType WHERE Name=\'Test Drive\' LIMIT 1'))wtId=(Id)s.get('Id');
Id ohId; for(SObject s:Database.query('SELECT OperatingHoursId FROM TimeSlot WHERE OperatingHoursId!=null LIMIT 1'))ohId=(Id)s.get('OperatingHoursId');
Id resId; for(SObject s:Database.query('SELECT Id FROM ServiceResource WHERE IsActive=true LIMIT 1'))resId=(Id)s.get('Id');
System.debug('prereq: WT='+wtId+' OH='+ohId+' RES='+resId);
if(wtId==null){System.debug('ABORT: rode a Parte A (WorkType Test Drive) primeiro.');}
else if(ohId==null){System.debug('ABORT: nenhum OperatingHours com TimeSlot.');}
else{
Schema.SObjectType stT=Schema.getGlobalDescribe().get('ServiceTerritory');
Schema.SObjectType stwtT=Schema.getGlobalDescribe().get('ServiceTerritoryWorkType');
Schema.SObjectType stmT=Schema.getGlobalDescribe().get('ServiceTerritoryMember');
Map<Id,String> deal=new Map<Id,String>();
for(Account a:[SELECT Id,Name FROM Account WHERE Parent.Parent.ParentId!=null AND Parent.Parent.Parent.ParentId=null ORDER BY Name])deal.put(a.Id,a.Name);
Map<String,Id> stByName=new Map<String,Id>();
for(SObject s:Database.query('SELECT Id,Name FROM ServiceTerritory'))stByName.put((String)s.get('Name'),(Id)s.get('Id'));
List<SObject> stNew=new List<SObject>();
for(String nm:deal.values())if(!stByName.containsKey(nm)){SObject t=stT.newSObject();t.put('Name',nm);t.put('OperatingHoursId',ohId);t.put('IsActive',true);stNew.add(t);}
System.debug('1.ServiceTerritory a criar:'+stNew.size());
if(!stNew.isEmpty())insert stNew;
for(SObject t:stNew)stByName.put((String)t.get('Name'),(Id)t.get('Id'));
Set<Id> stwtEx=new Set<Id>();
for(SObject s:Database.query('SELECT ServiceTerritoryId FROM ServiceTerritoryWorkType WHERE WorkTypeId=:wtId'))stwtEx.add((Id)s.get('ServiceTerritoryId'));
List<SObject> stwtNew=new List<SObject>();
for(String nm:deal.values()){Id stid=stByName.get(nm);if(stid!=null&&!stwtEx.contains(stid)){SObject w=stwtT.newSObject();w.put('ServiceTerritoryId',stid);w.put('WorkTypeId',wtId);stwtNew.add(w);stwtEx.add(stid);}}
System.debug('2.ServiceTerritoryWorkType a criar:'+stwtNew.size());
if(!stwtNew.isEmpty())insert stwtNew;
Set<Id> stmEx=new Set<Id>();
if(resId!=null)for(SObject s:Database.query('SELECT ServiceTerritoryId FROM ServiceTerritoryMember WHERE ServiceResourceId=:resId'))stmEx.add((Id)s.get('ServiceTerritoryId'));
List<SObject> stmNew=new List<SObject>();
if(resId!=null)for(String nm:deal.values()){Id stid=stByName.get(nm);if(stid!=null&&!stmEx.contains(stid)){SObject m=stmT.newSObject();m.put('ServiceTerritoryId',stid);m.put('ServiceResourceId',resId);m.put('EffectiveStartDate',Date.today());m.put('TerritoryType','P');stmNew.add(m);stmEx.add(stid);}}
System.debug('3.ServiceTerritoryMember a criar:'+stmNew.size());
if(!stmNew.isEmpty())insert stmNew;
Boolean bpHasST=Schema.getGlobalDescribe().get('BusinessProfile').getDescribe().fields.getMap().containsKey('serviceterritoryid');
if(bpHasST){List<SObject> bpUpd=new List<SObject>();
 for(SObject bp:Database.query('SELECT Id,AccountId,ServiceTerritoryId FROM BusinessProfile WHERE AccountId IN :deal.keySet()')){
  Id acc=(Id)bp.get('AccountId');Id stid=stByName.get(deal.get(acc));
  if(stid!=null&&(Id)bp.get('ServiceTerritoryId')!=stid){bp.put('ServiceTerritoryId',stid);bpUpd.add(bp);}}
 System.debug('4.BusinessProfile a vincular ServiceTerritory:'+bpUpd.size());
 if(!bpUpd.isEmpty())update bpUpd;
}else System.debug('4.BusinessProfile sem campo ServiceTerritoryId (pulado)');
}
System.debug('=== FIM PARTE B (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
