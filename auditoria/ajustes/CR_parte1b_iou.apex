// Rodar DEPOIS da parte1 gravada (holding/pais/sociedades ja existem).
// Cria/atualiza IOUs GQ_HOLDING->GQ_CR->C101/C105 e vincula AccountId. DRY RUN no fim.
Map<String,Id> aN=new Map<String,Id>();
for(Account a:[SELECT Id,Name FROM Account WHERE Name LIKE 'GrupoQ%' OR Name LIKE 'Grupo Q%'])aN.put(a.Name,a.Id);
Id hId=aN.get('GrupoQ Holding');Id crId=aN.get('GrupoQ Costa Rica');
Id s1=aN.get('GrupoQ Costa Rica C101'),s5=aN.get('GrupoQ Costa Rica C105');
System.debug('acc: H='+hId+' CR='+crId+' C101='+s1+' C105='+s5);
Schema.SObjectType iT=Schema.getGlobalDescribe().get('InternalOrganizationUnit');
Map<String,Schema.SObjectField> iomap=iT.getDescribe().fields.getMap();
String pf=null;for(Schema.SObjectField f:iomap.values()){Schema.DescribeFieldResult d=f.getDescribe();if(d.getType()==Schema.DisplayType.REFERENCE)for(Schema.SObjectType t:d.getReferenceTo())if(t.getDescribe().getName()=='InternalOrganizationUnit'&&pf==null)pf=d.getName();}
Map<String,SObject> iC=new Map<String,SObject>();
for(SObject i:Database.query('SELECT Id,OrganizationCode,AccountId'+(pf!=null?(', '+pf):'')+' FROM InternalOrganizationUnit')){Object oc=i.get('OrganizationCode');if(oc!=null)iC.put((String)oc,i);}
List<String> ord=new List<String>{'GQ_HOLDING','GQ_CR','C101','C105'};
Map<String,String> nmm=new Map<String,String>{'GQ_HOLDING'=>'GrupoQ Holding','GQ_CR'=>'GrupoQ Costa Rica','C101'=>'Sociedade C101 Costa Rica','C105'=>'Sociedade C105 Costa Rica'};
Map<String,Id> iac=new Map<String,Id>{'GQ_HOLDING'=>hId,'GQ_CR'=>crId,'C101'=>s1,'C105'=>s5};
Map<String,String> ipar=new Map<String,String>{'GQ_CR'=>'GQ_HOLDING','C101'=>'GQ_CR','C105'=>'GQ_CR'};
List<SObject> novo=new List<SObject>();List<String> novoC=new List<String>();
for(String c:ord)if(!iC.containsKey(c)){SObject o=iT.newSObject();o.put('OrganizationCode',c);o.put('OrganizationName',nmm.get(c));if(iac.get(c)!=null)o.put('AccountId',iac.get(c));novo.add(o);novoC.add(c);}
System.debug('IOU a criar:'+novo.size());
if(!novo.isEmpty()){insert novo;for(Integer j=0;j<novo.size();j++)iC.put(novoC[j],novo[j]);}
List<SObject> iU=new List<SObject>();
for(String c:ord)if(iC.containsKey(c)){SObject i=iC.get(c);Boolean ch=false;
 if(iac.get(c)!=null&&(Id)i.get('AccountId')!=iac.get(c)){i.put('AccountId',iac.get(c));ch=true;}
 if(pf!=null&&ipar.containsKey(c)&&iC.containsKey(ipar.get(c))){Id pi=(Id)iC.get(ipar.get(c)).get('Id');if((Id)i.get(pf)!=pi){i.put(pf,pi);ch=true;}}
 if(ch)iU.add(i);}
System.debug('IOU a atualizar:'+iU.size());if(!iU.isEmpty())update iU;
System.debug('=== FIM parte1b (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
