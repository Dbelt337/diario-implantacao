// SOMENTE LEITURA. Confirma se Quote esta habilitado e quais campos sao obrigatorios
// para inserir Quote/QuoteLineItem (necessario para o OmniScript "Criar Cotacao", sem CPQ).
// Filtre o log por 'Q>'. Marca OBRIGATORIOs e lookups (-> alvo). Roda antes de criar dados.
for(String o:new List<String>{'Quote','QuoteLineItem','Opportunity','OpportunityLineItem'}){
 Schema.SObjectType t=Schema.getGlobalDescribe().get(o);
 if(t==null){System.debug('Q> '+o+': AUSENTE (feature nao habilitada?)');continue;}
 Schema.DescribeSObjectResult r=t.getDescribe();
 System.debug('Q> ===== '+o+' | createable='+r.isCreateable()+' =====');
 for(Schema.SObjectField f:r.fields.getMap().values()){
  Schema.DescribeFieldResult d=f.getDescribe();
  Boolean req=d.isCreateable()&&!d.isNillable()&&!d.isDefaultedOnCreate();
  // loga so os relevantes: obrigatorios, lookups e alguns campos-chave de Quote
  Boolean key=new Set<String>{'Name','Status','OpportunityId','Pricebook2Id','AccountId','ExpirationDate','ContactId'}.contains(d.getName());
  if(req||!d.getReferenceTo().isEmpty()||key)
   System.debug('Q> '+d.getName()+' | '+d.getType()+(d.getReferenceTo().isEmpty()?'':(' -> '+d.getReferenceTo()))+(req?' | OBRIGATORIO':'')+(d.isCreateable()?'':' | RO'));
 }
}
// Quotes precisam estar habilitados em Setup > Quotes Settings. Se 'Quote' vier AUSENTE, habilite antes.
System.debug('Q> === FIM describe (read-only) ===');
