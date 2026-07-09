// SOMENTE LEITURA. Verifica BusinessBrand e como se relaciona (marca x dealer/sucursal). Filtre 'BB>'.
System.debug('BB> total:'+[SELECT COUNT() FROM BusinessBrand]);
for(SObject b:Database.query('SELECT Name FROM BusinessBrand ORDER BY Name LIMIT 60'))System.debug('BB> '+b.get('Name'));
Schema.SObjectType bt=Schema.getGlobalDescribe().get('BusinessBrand');
for(Schema.SObjectField f:bt.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();if(!d.getReferenceTo().isEmpty())System.debug('BB.ref '+d.getName()+' -> '+d.getReferenceTo());}
for(String o:new List<String>{'BusinessBrandAssociation','BrandAssociation','ProductBrand','AccountBrand','DealerBrand'}){if(Schema.getGlobalDescribe().get(o)!=null)System.debug('BB> junction possivel: '+o);}
