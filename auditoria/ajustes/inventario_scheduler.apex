// SOMENTE LEITURA. Inventario do que existe de Scheduler na org. Filtre 'SCH>'.
for(String o:new List<String>{'ServiceTerritory','OperatingHours','TimeSlot','WorkType','WorkTypeGroup','WorkTypeGroupMember','ServiceResource','ServiceTerritoryMember','ServiceTerritoryWorkType'}){
 try{System.debug('SCH> COUNT '+o+': '+Database.countQuery('SELECT COUNT() FROM '+o));}catch(Exception e){System.debug('SCH> '+o+': ERRO '+e.getMessage());}
}
try{for(SObject s:Database.query('SELECT Id,Name,IsActive,OperatingHoursId FROM ServiceTerritory ORDER BY Name LIMIT 40'))System.debug('SCH> ST '+s.get('Id')+' | '+s.get('Name')+' active='+s.get('IsActive')+' OH='+s.get('OperatingHoursId'));}catch(Exception e){System.debug('SCH> ST list ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Id,Name FROM WorkType ORDER BY Name LIMIT 30'))System.debug('SCH> WT '+s.get('Id')+' | '+s.get('Name'));}catch(Exception e){System.debug('SCH> WT list ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Id,Name FROM WorkTypeGroup ORDER BY Name LIMIT 30'))System.debug('SCH> WTG '+s.get('Id')+' | '+s.get('Name'));}catch(Exception e){System.debug('SCH> WTG list ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Id,Name,IsActive,ResourceType FROM ServiceResource ORDER BY Name LIMIT 30'))System.debug('SCH> SR '+s.get('Id')+' | '+s.get('Name')+' active='+s.get('IsActive')+' type='+s.get('ResourceType'));}catch(Exception e){System.debug('SCH> SR list ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Id,Name,TimeZone FROM OperatingHours ORDER BY Name LIMIT 20'))System.debug('SCH> OH '+s.get('Id')+' | '+s.get('Name')+' tz='+s.get('TimeZone'));}catch(Exception e){System.debug('SCH> OH list ERRO '+e.getMessage());}
