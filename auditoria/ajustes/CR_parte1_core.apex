// Cria hierarquia CR do zero (ambiente novo): Holding->Pais->Sociedade->Dealer + BP + IOU.
// Idempotente (check-then-create). DRY RUN no fim.
List<String> D=new List<String>{'C101|GrupoQ La Uruca|C011-1200','C101|GrupoQ Liberia|C011-1209','C101|GrupoQ San Carlos|C011-1211','C101|GrupoQ Lindora|C011-1210','C101|GrupoQ Ayarco|C011-1223','C101|GrupoQ Uruca Usados|C817-NOALM','C101|GrupoQ Uruca Flotas|C011-1200','C101|GrupoQ Guapiles|C011-1273','C101|GrupoQ Perez Zeledon|C011-1272','C105|GrupoQ Active Motors Sucursal Central|C311-1200','C105|GrupoQ Forland Liberia|C211-1201','C105|GrupoQ Forland Perez Zeledon|C211-1202','C105|GrupoQ Forland San Carlos|C211-1203','C105|GrupoQ Forland Guapiles|C211-1204','C105|GrupoQ Forland La Uruca Sucursal Central|C311-1200','C105|GrupoQ Active Motors SABANA|C211-1212','C105|GrupoQ Vehiculos La Uruca|C311-1220','C105|GrupoQ Active Motors Paseo Las Flores|C211-1524','C105|GrupoQ Terrazas Lindora|C311-1222','C105|GrupoQ Ventas Guapiles|C311-1237'};
Schema.DescribeSObjectResult ad=Schema.getGlobalDescribe().get('Account').getDescribe();
Map<String,Schema.SObjectField> af=ad.fields.getMap();
for(Schema.SObjectField f:af.values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate()&&d.getName()!='Name')System.debug('REQ Account: '+d.getName()+' ('+d.getType()+')');}
String cc=null;
for(Schema.PicklistEntry pe:af.get('Country__c').getDescribe().getPicklistValues()){if(pe.isActive()){String v=pe.getValue();if(v.equalsIgnoreCase('Costa Rica')||v.equalsIgnoreCase('CR')||v.containsIgnoreCase('Costa')){cc=v;break;}}}
if(cc==null){for(Schema.PicklistEntry pe:af.get('Country__c').getDescribe().getPicklistValues())System.debug('Country__c val:'+pe.getValue());throw new IllegalArgumentException('ABORT: valor de Country__c p/ Costa Rica nao encontrado - veja os valores no log.');}
System.debug('0.Country__c=' + cc);
Map<String,Id> aN=new Map<String,Id>();
for(Account a:[SELECT Id,Name FROM Account])aN.put(a.Name,a.Id);
List<Account> t1=new List<Account>();
if(!aN.containsKey('GrupoQ Holding'))t1.add(new Account(Name='GrupoQ Holding',Country__c=cc));
if(!t1.isEmpty()){insert t1;for(Account a:t1)aN.put(a.Name,a.Id);}
Id hId=aN.get('GrupoQ Holding');
List<Account> t2=new List<Account>();
if(!aN.containsKey('GrupoQ Costa Rica'))t2.add(new Account(Name='GrupoQ Costa Rica',ParentId=hId,Country__c=cc));
if(!t2.isEmpty()){insert t2;for(Account a:t2)aN.put(a.Name,a.Id);}
Id crId=aN.get('GrupoQ Costa Rica');
List<Account> t3=new List<Account>();
if(!aN.containsKey('GrupoQ Costa Rica C101'))t3.add(new Account(Name='GrupoQ Costa Rica C101',ParentId=crId,Country__c=cc));
if(!aN.containsKey('GrupoQ Costa Rica C105'))t3.add(new Account(Name='GrupoQ Costa Rica C105',ParentId=crId,Country__c=cc));
if(!t3.isEmpty()){insert t3;for(Account a:t3)aN.put(a.Name,a.Id);}
Id s1=aN.get('GrupoQ Costa Rica C101'),s5=aN.get('GrupoQ Costa Rica C105');
System.debug('0.Hierarquia: Holding='+hId+' CR='+crId+' C101='+s1+' C105='+s5);
Set<Id> bA=new Set<Id>();Set<String> bE=new Set<String>();
for(BusinessProfile b:[SELECT AccountId,ExternalReferenceNumber FROM BusinessProfile]){if(b.AccountId!=null)bA.add(b.AccountId);if(b.ExternalReferenceNumber!=null)bE.add(b.ExternalReferenceNumber);}
List<Account> aC=new List<Account>();Set<String> tt=new Set<String>();
for(String x:D){List<String> p=x.split('\\|');if(tt.contains(p[1]))continue;tt.add(p[1]);if(!aN.containsKey(p[1]))aC.add(new Account(Name=p[1],ParentId=(p[0]=='C101'?s1:s5),Country__c=cc));}
System.debug('1.Dealers a criar:'+aC.size());if(!aC.isEmpty())insert aC;
for(Account a:aC)aN.put(a.Name,a.Id);
List<BusinessProfile> bC=new List<BusinessProfile>();Set<String> bn=new Set<String>();Set<String> cf=new Set<String>();
for(String x:D){List<String> p=x.split('\\|');String nm=p[1];String c=p[2];if(bn.contains(nm))continue;bn.add(nm);Id ai=aN.get(nm);if(ai==null||bA.contains(ai))continue;if(bE.contains(c)){System.debug('BPskip-existe '+c+' '+nm);continue;}if(cf.contains(c)){System.debug('BPskip-BranchUnit '+c+' '+nm);continue;}cf.add(c);bC.add(new BusinessProfile(AccountId=ai,ExternalReferenceNumber=c,BusinessPartnerType='Sales Dealer'));}
System.debug('3.BP a criar:'+bC.size());
for(BusinessProfile b:bC)System.debug('  +'+b.ExternalReferenceNumber);
if(!bC.isEmpty())insert bC;
System.debug('=== FIM parte1 (DRY RUN) - IOU em CR_parte1b_iou.apex ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
