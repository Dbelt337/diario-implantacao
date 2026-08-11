// Seed idempotente Field Service QA — reexecutável sem duplicar (base do runbook H)
List<OperatingHours> ohs=[SELECT Id FROM OperatingHours WHERE Name='Horário Comercial BTP' LIMIT 1];
OperatingHours oh = ohs.isEmpty()? new OperatingHours(Name='Horário Comercial BTP',TimeZone='America/Sao_Paulo'):ohs[0];
if(ohs.isEmpty()){insert oh; List<TimeSlot> sl=new List<TimeSlot>();
for(String d:new List<String>{'Monday','Tuesday','Wednesday','Thursday','Friday'})
 sl.add(new TimeSlot(OperatingHoursId=oh.Id,DayOfWeek=d,StartTime=Time.newInstance(8,0,0,0),EndTime=Time.newInstance(18,0,0,0)));
insert sl;}
if([SELECT COUNT() FROM WorkType WHERE Name='Instalação']==0)
 insert new WorkType(Name='Instalação',EstimatedDuration=120,DurationType='Minutes',ShouldAutoCreateSvcAppt=true,Product__c='BandaLarga');
if([SELECT COUNT() FROM WorkType WHERE Name='Reparo Técnico']==0)
 insert new WorkType(Name='Reparo Técnico',EstimatedDuration=90,DurationType='Minutes',ShouldAutoCreateSvcAppt=true,Product__c='BandaLarga');
Integer base=10000; List<ServiceTerritory> novos=new List<ServiceTerritory>();
for(String s:new List<String>{'CBA','JIA','PVT','IUZ','ROI','PDG','RVG'}){
 if([SELECT COUNT() FROM ServiceTerritory WHERE Name=:s]==0){
  ServiceTerritory st=new ServiceTerritory(Name=s,OperatingHoursId=oh.Id,IsActive=true);
  st.put('InicialZIPCode__c',String.valueOf(base)+'-000'); st.put('FinalZIPCode__c',String.valueOf(base+9999)+'-999');
  novos.add(st);} base+=10000;}
if(!novos.isEmpty()) insert novos;
if([SELECT COUNT() FROM Account WHERE DocumentNumber__c='11.222.333/0001-81']==0)
 insert new Account(Name='CONTA TESTE INTEGRACAO FIELD',DocumentNumber__c='11.222.333/0001-81');
System.debug('Seed verificado/completo');
