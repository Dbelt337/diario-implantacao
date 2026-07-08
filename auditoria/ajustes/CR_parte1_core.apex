List<String> D=new List<String>{'C101|GrupoQ La Uruca|C011-1200','C101|GrupoQ Liberia|C011-1209','C101|GrupoQ San Carlos|C011-1211','C101|GrupoQ Lindora|C011-1210','C101|GrupoQ Ayarco|C011-1223','C101|GrupoQ Uruca Usados|C817-NOALM','C101|GrupoQ Uruca Flotas|C011-1200','C101|GrupoQ Guapiles|C011-1273','C101|GrupoQ Perez Zeledon|C011-1272','C105|GrupoQ Active Motors Sucursal Central|C311-1200','C105|GrupoQ Forland Liberia|C211-1201','C105|GrupoQ Forland Perez Zeledon|C211-1202','C105|GrupoQ Forland San Carlos|C211-1203','C105|GrupoQ Forland Guapiles|C211-1204','C105|GrupoQ Forland La Uruca Sucursal Central|C311-1200','C105|GrupoQ Active Motors SABANA|C211-1212','C105|GrupoQ Vehiculos La Uruca|C311-1220','C105|GrupoQ Active Motors Paseo Las Flores|C211-1524','C105|GrupoQ Terrazas Lindora|C311-1222','C105|GrupoQ Ventas Guapiles|C311-1237'};
Map<String,Id> aN=new Map<String,Id>();
for(Account a:[SELECT Id,Name FROM Account])aN.put(a.Name,a.Id);
Id s1=aN.get('GrupoQ Costa Rica C101'),s5=aN.get('GrupoQ Costa Rica C105');
if(s1==null||s5==null)throw new IllegalArgumentException('ABORT: sociedade C101/C105 nao encontrada');
Set<Id> bA=new Set<Id>();Set<String> bE=new Set<String>();
for(BusinessProfile b:[SELECT AccountId,ExternalReferenceNumber FROM BusinessProfile]){if(b.AccountId!=null)bA.add(b.AccountId);if(b.ExternalReferenceNumber!=null)bE.add(b.ExternalReferenceNumber);}
List<Account> aC=new List<Account>();Set<String> tt=new Set<String>();
for(String x:D){List<String> p=x.split('\\|');if(tt.contains(p[1]))continue;tt.add(p[1]);if(!aN.containsKey(p[1]))aC.add(new Account(Name=p[1],ParentId=(p[0]=='C101'?s1:s5)));}
System.debug('1.Accounts:'+aC.size());if(!aC.isEmpty())insert aC;
for(Account a:aC)aN.put(a.Name,a.Id);
List<BusinessProfile> bC=new List<BusinessProfile>();Set<String> bn=new Set<String>();Set<String> cf=new Set<String>();
for(String x:D){List<String> p=x.split('\\|');String nm=p[1];String c=p[2];if(bn.contains(nm))continue;bn.add(nm);Id ai=aN.get(nm);if(ai==null||bA.contains(ai))continue;if(bE.contains(c)){System.debug('BPskip-existe '+c+' '+nm);continue;}if(cf.contains(c)){System.debug('BPskip-BranchUnit '+c+' '+nm);continue;}cf.add(c);bC.add(new BusinessProfile(AccountId=ai,Name='BP-'+nm,ExternalReferenceNumber=c,BusinessPartnerType='Sales Dealer'));}
System.debug('3.BP:'+bC.size());
for(BusinessProfile b:bC)System.debug('  +'+b.Name+' '+b.ExternalReferenceNumber);
if(!bC.isEmpty())insert bC;
Map<String,Schema.SObjectField> iF=InternalOrganizationUnit.SObjectType.getDescribe().fields.getMap();
String pf=null;for(Schema.SObjectField f:iF.values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.getType()==Schema.DisplayType.REFERENCE)for(Schema.SObjectType t:d.getReferenceTo())if(t.getDescribe().getName()=='InternalOrganizationUnit'&&pf==null)pf=d.getName();}
Map<String,SObject> iC=new Map<String,SObject>();
for(SObject i:Database.query('SELECT Id,OrganizationCode,AccountId'+(pf!=null?(', '+pf):'')+' FROM InternalOrganizationUnit')){Object oc=i.get('OrganizationCode');if(oc!=null)iC.put((String)oc,i);}
List<SObject> iU=new List<SObject>();
Map<String,String> mA=new Map<String,String>{'GQ_HOLDING'=>'GrupoQ Holding','GQ_CR'=>'GrupoQ Costa Rica','C101'=>'GrupoQ Costa Rica C101','C105'=>'GrupoQ Costa Rica C105'};
for(String c:mA.keySet())if(iC.containsKey(c)){SObject i=iC.get(c);Id ai=aN.get(mA.get(c));if(ai!=null&&(Id)i.get('AccountId')!=ai){i.put('AccountId',ai);if(!iU.contains(i))iU.add(i);}}
Map<String,String> mP=new Map<String,String>{'GQ_CR'=>'GQ_HOLDING','C101'=>'GQ_CR','C105'=>'GQ_CR'};
if(pf!=null)for(String c:mP.keySet())if(iC.containsKey(c)&&iC.containsKey(mP.get(c))){SObject i=iC.get(c);Id pi=(Id)iC.get(mP.get(c)).get('Id');if((Id)i.get(pf)!=pi){i.put(pf,pi);if(!iU.contains(i))iU.add(i);}}
System.debug('5.IOU upd:'+iU.size());if(!iU.isEmpty())update iU;
System.debug('=== FIM (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
