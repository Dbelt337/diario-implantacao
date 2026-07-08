/* NAO EXECUTA MUDANCA - somente leitura. Execute Anonymous.
   Confirma os API names dos campos do BusinessProfile p/ montar a carga A-01. Filtre por 'BPF>'. */
for(Schema.SObjectField f:BusinessProfile.SObjectType.getDescribe().fields.getMap().values()){
 Schema.DescribeFieldResult d=f.getDescribe();
 System.debug('BPF> '+d.getName()+' | '+d.getLabel()+' | '+d.getType()+' | ref='+d.getReferenceTo());
}
