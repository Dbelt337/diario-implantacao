// SOMENTE LEITURA. BusinessBrand + AccountBrand + candidatos a juncao marca<->dealer. Filtre 'BB>'.
System.debug('BB> BusinessBrand total:'+[SELECT COUNT() FROM BusinessBrand]);
for(SObject b:Database.query('SELECT Name FROM BusinessBrand ORDER BY Name LIMIT 60'))System.debug('BB> brand: '+b.get('Name'));
Schema.SObjectType bt=Schema.getGlobalDescribe().get('BusinessBrand');
for(Schema.SObjectField f:bt.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();if(!d.getReferenceTo().isEmpty())System.debug('BB.ref BusinessBrand.'+d.getName()+' -> '+d.getReferenceTo());}
// AccountBrand: existe? (precisa de Digital Experiences + licenca community)
Schema.SObjectType ab=Schema.getGlobalDescribe().get('AccountBrand');
if(ab==null)System.debug('BB> AccountBrand: AUSENTE (Digital Experiences/community license off)');
else{System.debug('BB> AccountBrand: PRESENTE');for(Schema.SObjectField f:ab.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();if(!d.getReferenceTo().isEmpty())System.debug('BB.ref AccountBrand.'+d.getName()+' -> '+d.getReferenceTo());}}
// candidatos a juncao marca<->dealer
for(String o:new List<String>{'BusinessBrandAssociation','BrandAssociation','ProductBrand','AccountBrand','DealerBrand','BusinessBrandShare'}){if(Schema.getGlobalDescribe().get(o)!=null)System.debug('BB> objeto presente: '+o);}
