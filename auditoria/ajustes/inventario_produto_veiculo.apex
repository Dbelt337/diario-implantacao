// SOMENTE LEITURA. Catalogo de produto/veiculo para o test drive. Filtre 'PRD>'.
for(String o:new List<String>{'Product2','VehicleDefinition','ProductBrand','ProductCategory','AssetModel','WorkTypeGroup'}){
 try{System.debug('PRD> COUNT '+o+': '+Database.countQuery('SELECT COUNT() FROM '+o));}catch(Exception e){System.debug('PRD> '+o+': ERRO/AUSENTE '+e.getMessage());}
}
try{for(SObject s:Database.query('SELECT Name FROM Product2 ORDER BY Name LIMIT 30'))System.debug('PRD> P2 '+s.get('Name'));}catch(Exception e){System.debug('PRD> P2 ERRO '+e.getMessage());}
try{for(SObject s:Database.query('SELECT Name FROM VehicleDefinition ORDER BY Name LIMIT 30'))System.debug('PRD> VD '+s.get('Name'));}catch(Exception e){System.debug('PRD> VD ERRO/AUSENTE '+e.getMessage());}
