/* NAO EXECUTA MUDANCA - somente leitura. Execute Anonymous.
   Extrai os IDs concretos que alimentam os CSVs de carga do PLANO_REMEDIACAO.
   Filtre o log por 'WL>'. Cada bloco corresponde a um achado. */

// A-01: dealers (nivel 4) SEM BusinessProfile 'Sales Dealer'
Map<Id,Account> dmap=new Map<Id,Account>([SELECT Id,Name,ParentId,Parent.Name FROM Account WHERE Parent.Parent.ParentId!=null AND Parent.Parent.Parent.ParentId=null]);
Set<Id> wbp=new Set<Id>();
for(BusinessProfile bp:[SELECT AccountId FROM BusinessProfile WHERE BusinessPartnerType='Sales Dealer' AND AccountId!=null])wbp.add(bp.AccountId);
for(Account a:dmap.values())if(!wbp.contains(a.Id))System.debug('WL> A01_DEALER_SEM_BP,'+a.Id+','+a.Name+','+a.ParentId+','+a.Parent.Name);

// A-02: BusinessProfile com tipo nulo
for(BusinessProfile bp:[SELECT Id,AccountId,BusinessPartnerCode,ExternalReferenceNumber FROM BusinessProfile WHERE BusinessPartnerType=null])System.debug('WL> A02_BP_TIPO_NULO,'+bp.Id+','+bp.AccountId+','+bp.BusinessPartnerCode+','+bp.ExternalReferenceNumber);

// A-03: Accounts de sociedade (nivel 3) e paises (nivel 2) para montar ParentId
for(Account a:[SELECT Id,Name,ParentId FROM Account WHERE Parent.ParentId!=null AND Parent.Parent.ParentId=null])System.debug('WL> A03_SOCIEDADE,'+a.Id+','+a.Name+','+a.ParentId);
for(Account a:[SELECT Id,Name,ParentId FROM Account WHERE ParentId!=null AND Parent.ParentId=null])System.debug('WL> A03_PAIS,'+a.Id+','+a.Name+','+a.ParentId);
for(Account a:[SELECT Id,Name FROM Account WHERE Parent.Parent.Parent.ParentId!=null])System.debug('WL> A03_PROFUNDIDADE_MAIOR_4,'+a.Id+','+a.Name);

// A-04: IOUs sem Account
for(InternalOrganizationUnit i:[SELECT Id,Name FROM InternalOrganizationUnit WHERE AccountId=null])System.debug('WL> A04_IOU_SEM_ACC,'+i.Id+','+i.Name);

// A-05: registros de CMT (identificar P101 / faltantes)
for(Sociedad_Config__mdt c:[SELECT DeveloperName,MasterLabel FROM Sociedad_Config__mdt ORDER BY DeveloperName])System.debug('WL> A05_CMT,'+c.DeveloperName+','+c.MasterLabel);

// A-11: usuarios ativos sem Sociedad__c
for(User u:[SELECT Id,Username,Sociedad__c FROM User WHERE IsActive=true AND Sociedad__c=null ORDER BY Username LIMIT 200])System.debug('WL> A11_USER_SEM_SOC,'+u.Id+','+u.Username);
