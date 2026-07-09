// SOMENTE LEITURA. Dump do ServiceTerritory que JA funciona (Ids do debug) + relacionados,
// para clonar o setup nas outras sucursales. Filtre 'EX>'.
Id tid='0HhT10000004CBEKA2';
Id rid='0HnT10000004CGNKA2';
Id wtg='0VST10000004C9wOAE';
try{for(SObject s:Database.query('SELECT Name,OperatingHoursId,ParentTerritoryId,IsActive FROM ServiceTerritory WHERE Id=:tid'))System.debug('EX> ST '+s.get('Name')+' | OH='+s.get('OperatingHoursId')+' parent='+s.get('ParentTerritoryId')+' active='+s.get('IsActive'));}catch(Exception e){System.debug('EX> ST ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Name,TimeZone FROM OperatingHours WHERE Id IN (SELECT OperatingHoursId FROM ServiceTerritory WHERE Id=:tid)'))System.debug('EX> OH '+s.get('Name')+' tz='+s.get('TimeZone'));}catch(Exception e){System.debug('EX> OH ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT DayOfWeek,StartTime,EndTime,Type FROM TimeSlot WHERE OperatingHoursId IN (SELECT OperatingHoursId FROM ServiceTerritory WHERE Id=:tid)'))System.debug('EX> SLOT '+s.get('DayOfWeek')+' '+s.get('StartTime')+'-'+s.get('EndTime')+' '+s.get('Type'));}catch(Exception e){System.debug('EX> SLOT ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT WorkTypeId FROM ServiceTerritoryWorkType WHERE ServiceTerritoryId=:tid'))System.debug('EX> STWT wt='+s.get('WorkTypeId'));}catch(Exception e){System.debug('EX> STWT ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT ServiceResourceId,TerritoryType FROM ServiceTerritoryMember WHERE ServiceTerritoryId=:tid'))System.debug('EX> STM res='+s.get('ServiceResourceId')+' type='+s.get('TerritoryType'));}catch(Exception e){System.debug('EX> STM ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Name,IsActive,ResourceType FROM ServiceResource WHERE Id=:rid'))System.debug('EX> SR '+s.get('Name')+' active='+s.get('IsActive')+' type='+s.get('ResourceType'));}catch(Exception e){System.debug('EX> SR ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Name FROM WorkTypeGroup WHERE Id=:wtg'))System.debug('EX> WTG '+s.get('Name'));}catch(Exception e){System.debug('EX> WTG ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId=:wtg'))System.debug('EX> WTGM wt='+s.get('WorkTypeId'));}catch(Exception e){System.debug('EX> WTGM ERRO '+e.getMessage());}
