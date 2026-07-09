// SOMENTE LEITURA. Descobre o schema dos objetos de Branch Management antes de criar dados.
// Filtre o log por 'BM>'. Marca campos OBRIGATORIOS e lookups (-> alvo).
for(String o:new List<String>{'BranchUnit','BranchUnitBusinessMember','BranchUnitRelatedRecord'}){
 Schema.SObjectType t=Schema.getGlobalDescribe().get(o);
 if(t==null){System.debug('BM> '+o+': AUSENTE');continue;}
 System.debug('BM> ===== '+o+' =====');
 for(Schema.SObjectField f:t.getDescribe().fields.getMap().values()){
  Schema.DescribeFieldResult d=f.getDescribe();
  Boolean req=d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate();
  System.debug('BM> '+d.getName()+' | '+d.getType()+(d.getReferenceTo().isEmpty()?'':(' -> '+d.getReferenceTo()))+(req?' | OBRIGATORIO':'')+(d.isCreateable()?'':' | RO'));
 }
}
