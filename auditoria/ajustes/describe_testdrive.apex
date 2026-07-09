// SOMENTE LEITURA. Como o test drive identifica a sucursal (ServiceTerritory) e liga ao dealer.
// Filtre por 'TD>'. Mostra os lookups dos objetos do Automotive Scheduler.
for(String o:new List<String>{'ServiceTerritory','ServiceAppointment','WorkType','WorkTypeGroup','ServiceResource','ServiceTerritoryMember'}){
 Schema.SObjectType t=Schema.getGlobalDescribe().get(o);
 System.debug('TD> '+o+': '+(t==null?'AUSENTE':'PRESENTE'));
 if(t==null)continue;
 for(Schema.SObjectField f:t.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();if(!d.getReferenceTo().isEmpty())System.debug('TD> '+o+'.'+d.getName()+' -> '+d.getReferenceTo());}
}
Schema.SObjectType bp=Schema.getGlobalDescribe().get('BusinessProfile');
if(bp!=null)for(Schema.SObjectField f:bp.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();for(Schema.SObjectType r:d.getReferenceTo())if(r.getDescribe().getName()=='ServiceTerritory')System.debug('TD> BusinessProfile.'+d.getName()+' -> ServiceTerritory');}
