Map<String,Schema.SObjectType> g=Schema.getGlobalDescribe();
if(g.containsKey('BusinessProfile')){
 String bpf=null;
 Map<String,Schema.SObjectField> m=g.get('BusinessProfile').getDescribe().fields.getMap();
 for(String f:m.keySet()){Schema.DescribeFieldResult d=m.get(f).getDescribe();
  if(d.getType()==Schema.DisplayType.REFERENCE)for(Schema.SObjectType t:d.getReferenceTo())
   if(t.getDescribe().getName()=='Account'&&bpf==null)bpf=d.getName();}
 System.debug('AUDIT> BP->Account field: '+bpf);
 System.debug('AUDIT> BP SalesDealer extref NULO[P0]: '+Database.countQuery('SELECT COUNT() FROM BusinessProfile WHERE BusinessPartnerType=\'Sales Dealer\' AND ExternalReferenceNumber=null'));
 for(AggregateResult r:(List<AggregateResult>)Database.query('SELECT ExternalReferenceNumber ref,COUNT(Id) c FROM BusinessProfile WHERE ExternalReferenceNumber!=null GROUP BY ExternalReferenceNumber HAVING COUNT(Id)>1'))
  System.debug('AUDIT> extref DUP '+r.get('ref')+' x'+r.get('c'));
 for(AggregateResult r:(List<AggregateResult>)Database.query('SELECT BusinessPartnerType t,COUNT(Id) c FROM BusinessProfile GROUP BY BusinessPartnerType'))
  System.debug('AUDIT> BPtype '+r.get('t')+'='+r.get('c'));
 if(bpf!=null){
  System.debug('AUDIT> BP orfaos (sem Account): '+Database.countQuery('SELECT COUNT() FROM BusinessProfile WHERE '+bpf+'=null'));
  Set<Id> deal=new Set<Id>();
  for(Account ac:[SELECT Id FROM Account WHERE Parent.Parent.ParentId!=null AND Parent.Parent.Parent.ParentId=null])deal.add(ac.Id);
  Set<Id> wbp=new Set<Id>();
  for(SObject bp:Database.query('SELECT '+bpf+' FROM BusinessProfile WHERE BusinessPartnerType=\'Sales Dealer\'')){Object v=bp.get(bpf);if(v!=null)wbp.add((Id)v);}
  Integer s=0;for(Id d:deal)if(!wbp.contains(d))s++;
  System.debug('AUDIT> DEALERS n4 SEM BP SalesDealer[P0]: '+s+' de '+deal.size());
 }
}
if(g.containsKey('InternalOrganizationUnit')){
 System.debug('AUDIT> IOU total[17]: '+Database.countQuery('SELECT COUNT() FROM InternalOrganizationUnit'));
 System.debug('AUDIT> IOU AccountId nulo: '+Database.countQuery('SELECT COUNT() FROM InternalOrganizationUnit WHERE AccountId=null'));
}
if(g.containsKey('BranchUnit'))System.debug('AUDIT> BranchUnit total: '+Database.countQuery('SELECT COUNT() FROM BranchUnit'));
if(g.containsKey('ServiceTerritory'))System.debug('AUDIT> ServiceTerritory total: '+Database.countQuery('SELECT COUNT() FROM ServiceTerritory'));
if(g.containsKey('BusinessBrand'))System.debug('AUDIT> BusinessBrand total[22]: '+Database.countQuery('SELECT COUNT() FROM BusinessBrand'));
