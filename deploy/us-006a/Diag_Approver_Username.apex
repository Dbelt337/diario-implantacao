/* US-006a — username do aprovador pretendido (READ ONLY). Filtro: AP */
for (User u : [SELECT Id, Name, Username, IsActive FROM User WHERE Id='005WK00000KOUJdYAP'])
    System.debug(LoggingLevel.ERROR, 'AP | aprovador atual -> Name='+u.Name+' | Username='+u.Username+' | ativo='+u.IsActive);
/* candidatos Gestion de Datos, caso queira outro */
for (User u : [SELECT Name, Username FROM User WHERE IsActive=true AND (Name LIKE '%Wilmar%' OR Name LIKE '%Garzon%' OR Name LIKE '%Gesti%Dato%')])
    System.debug(LoggingLevel.ERROR, 'AP | candidato -> '+u.Name+' | '+u.Username);
