// Rodar DEPOIS da parte1 gravada (Accounts + BP ja existem). Cria Location e AssociatedLocation.
List<String> D=new List<String>{'GrupoQ La Uruca|C011-1200','GrupoQ Liberia|C011-1209','GrupoQ San Carlos|C011-1211','GrupoQ Lindora|C011-1210','GrupoQ Ayarco|C011-1223','GrupoQ Uruca Usados|C817-NOALM','GrupoQ Uruca Flotas|C011-1200','GrupoQ Guapiles|C011-1273','GrupoQ Perez Zeledon|C011-1272','GrupoQ Active Motors Sucursal Central|C311-1200','GrupoQ Forland Liberia|C211-1201','GrupoQ Forland Perez Zeledon|C211-1202,C311-1202','GrupoQ Forland San Carlos|C211-1203','GrupoQ Forland Guapiles|C211-1204','GrupoQ Forland La Uruca Sucursal Central|C311-1200','GrupoQ Active Motors SABANA|C211-1212','GrupoQ Vehiculos La Uruca|C311-1220','GrupoQ Active Motors Paseo Las Flores|C211-1524','GrupoQ Terrazas Lindora|C311-1222','GrupoQ Ventas Guapiles|C311-1237'};
Map<String,Id> aN=new Map<String,Id>();
for(Account a:[SELECT Id,Name FROM Account])aN.put(a.Name,a.Id);
Map<String,Id> lN=new Map<String,Id>();
for(SObject l:Database.query('SELECT Id,Name FROM Location')){String n=(String)l.get('Name');if(n!=null)lN.put(n,(Id)l.get('Id'));}
Set<String> lK=new Set<String>();
for(String x:D)for(String k:x.split('\\|')[1].split(','))lK.add(k);
Schema.SObjectType lT=Schema.getGlobalDescribe().get('Location');
List<SObject> lC=new List<SObject>();
for(String k:lK)if(!lN.containsKey(k)){SObject l=lT.newSObject();l.put('Name',k);lC.add(l);}
System.debug('2.Locations:'+lC.size());if(!lC.isEmpty())insert lC;
for(SObject l:Database.query('SELECT Id,Name FROM Location')){String n=(String)l.get('Name');if(n!=null)lN.put(n,(Id)l.get('Id'));}
Schema.SObjectType aT=Schema.getGlobalDescribe().get('AssociatedLocation');
Map<String,Schema.SObjectField> aF=aT.getDescribe().fields.getMap();String cA,cL;
for(Schema.SObjectField f:aF.values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.getType()==Schema.DisplayType.REFERENCE)for(Schema.SObjectType r:d.getReferenceTo()){String rn=r.getDescribe().getName();if(rn=='Account'&&cA==null)cA=d.getName();if(rn=='Location'&&cL==null)cL=d.getName();}}
System.debug('4.AL Account='+cA+' Location='+cL);
if(cA!=null&&cL!=null){Set<String> ae=new Set<String>();for(SObject o:Database.query('SELECT '+cA+','+cL+' FROM AssociatedLocation'))ae.add(''+o.get(cA)+'|'+o.get(cL));
List<SObject> a2=new List<SObject>();
for(String x:D){List<String> p=x.split('\\|');Id ai=aN.get(p[0]);for(String k:p[1].split(',')){Id li=lN.get(k);if(ai==null||li==null)continue;String ch=''+ai+'|'+li;if(ae.contains(ch))continue;ae.add(ch);SObject o=aT.newSObject();o.put(cA,ai);o.put(cL,li);a2.add(o);}}
System.debug('4.AL:'+a2.size());if(!a2.isEmpty())insert a2;}else System.debug('4.PULADO lookups AL');
System.debug('=== FIM (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
