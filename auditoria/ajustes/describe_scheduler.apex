// SOMENTE LEITURA. Campos/obrigatorios/lookups dos objetos do Scheduler (test drive). Filtre 'SC>'.
for(String o:new List<String>{'ServiceTerritory','WorkType','WorkTypeGroup','WorkTypeGroupMember','ServiceTerritoryWorkType','ServiceResource','ServiceTerritoryMember','OperatingHours'}){
 Schema.SObjectType t=Schema.getGlobalDescribe().get(o);
 System.debug('SC> ===== '+o+': '+(t==null?'AUSENTE':'PRESENTE')+' =====');
 if(t==null)continue;
 for(Schema.SObjectField f:t.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();
  Boolean req=d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate();
  if(req||!d.getReferenceTo().isEmpty())System.debug('SC> '+o+'.'+d.getName()+' | '+d.getType()+(d.getReferenceTo().isEmpty()?'':(' -> '+d.getReferenceTo()))+(req?' | REQ':''));}
}
