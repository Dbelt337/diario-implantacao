// PARTE A test drive: cria WorkType "Test Drive" + WorkTypeGroup + Member. DRY RUN. Idempotente por Name.
for(String o:new List<String>{'WorkType','WorkTypeGroup','WorkTypeGroupMember'}){Schema.SObjectType t=Schema.getGlobalDescribe().get(o);for(Schema.SObjectField f:t.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate()&&d.getName()!='Name')System.debug('REQ '+o+': '+d.getName()+' ('+d.getType()+')');}}
Schema.SObjectType wtT=Schema.getGlobalDescribe().get('WorkType');
Schema.SObjectType wtgT=Schema.getGlobalDescribe().get('WorkTypeGroup');
Schema.SObjectType wtgmT=Schema.getGlobalDescribe().get('WorkTypeGroupMember');
Id wtId;
for(SObject s:Database.query('SELECT Id FROM WorkType WHERE Name=\'Test Drive\' LIMIT 1'))wtId=(Id)s.get('Id');
if(wtId==null){SObject w=wtT.newSObject();w.put('Name','Test Drive');w.put('EstimatedDuration',60);w.put('DurationType','Minutes');insert w;wtId=(Id)w.get('Id');System.debug('WorkType criado');}
System.debug('WT Test Drive = '+wtId);
Id wtgId;
for(SObject s:Database.query('SELECT Id FROM WorkTypeGroup WHERE Name=\'Test Drive\' LIMIT 1'))wtgId=(Id)s.get('Id');
if(wtgId==null){SObject g=wtgT.newSObject();g.put('Name','Test Drive');g.put('IsActive',true);insert g;wtgId=(Id)g.get('Id');System.debug('WorkTypeGroup criado');}
System.debug('WTG Test Drive = '+wtgId);
Boolean has=false;
for(SObject s:Database.query('SELECT Id FROM WorkTypeGroupMember WHERE WorkTypeGroupId=:wtgId AND WorkTypeId=:wtId LIMIT 1'))has=true;
if(!has){SObject m=wtgmT.newSObject();m.put('WorkTypeGroupId',wtgId);m.put('WorkTypeId',wtId);insert m;System.debug('WorkTypeGroupMember criado');}
System.debug('=== FIM PARTE A (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
