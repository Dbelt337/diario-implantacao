# A-07 — Branch Management e Record Type de dealer (proposta Wilmar) — NÃO EXECUTADO

Proposta (Wilmar Garzon): (1) usar **Branch Unit** + **Branch Unit Member** para gerir vendas
de veículos E de peças numa única conta de concessionária (2 Branch Units, 1 concessionária);
(2) ter um **Record Type** próprio para contas do tipo concessionária. Ambos são suportados e
documentados no Automotive Cloud.

## 1. Branch Management (suporta a ideia dos 2 Branch Units por dealer)
Documentação oficial: "Configure Branch Management for Automotive Cloud"
(help.salesforce.com, id=sf.auto_configure_branch_mngmnt_dealer). Da busca oficial:
"With Branch Management, you can track user performance and productivity at specific branches.
And with Record Association Builder, you can automatically link leads, cases, accounts, and
contacts to different branch units."

Objetos (confirmar API names via describe — ver snippet abaixo):
- **BranchUnit** — a unidade/filial de negócio. Já existe na org (auditoria: 1 registro). Um
  Account de concessionária pode ter **múltiplos BranchUnit** (ex.: um "Ventas Vehículos" e um
  "Repuestos"), atendendo ao ponto do Wilmar (2 Branch Units, 1 concessionária).
- **BranchUnitBusinessMember** — associa usuários (membros) a um BranchUnit; é a base da
  **visibilidade** por filial (o "Branch units members" citado).
- **BranchUnitRelatedRecord** — associa registros (Leads, Cases, Accounts, Contacts) a um
  BranchUnit; populado automaticamente pelo **Record Association Builder**.

Como isso resolve o A-07 (BranchUnit vs ServiceTerritory): **não é ou/ou**.
- **BranchUnit** = modelo organizacional/visibilidade das linhas de negócio dentro do dealer
  (veículos vs repuestos) e handover (Mapeamento Sec 48). É o canônico para esse fim.
- **ServiceTerritory** = local de operação para **Automotive Scheduler** (test drives / citas de
  servicio). Permanece, mas só para agendamento; também aparece como campo no BusinessProfile.
Ou seja, adotar Branch Management **não descarta** ServiceTerritory — muda o papel de cada um.

## 2. Record Type de concessionária (ponto 2)
Documentação: "Stakeholder Management in Automotive Cloud" (Trailhead) e "Automotive Cloud Data
Model". Da busca oficial: "To model individual people... use person accounts. For organizations,
such as dealerships and banks, use business accounts... an account can represent a subsidiary,
dealer, customer, supplier, or service provider."

Observação da auditoria: a org só tem os Record Types `BusinessAccount` e `PersonAccount`
(padrão AC) — **não há RT de dealer**. Um RT próprio "Concesionaria" (ou por nível) é
customização do cliente (não vem pronto no AC), e é recomendável porque:
- dá um **discriminador de nível explícito** para contas de dealer (hoje o nível só existe por
  profundidade de ParentId — ver achado do discriminador na Sec 2.2 do relatório);
- permite page layout, validações, sharing e automações específicas de concessionária.

## Recomendação para o plano
- **A-07 revisado:** adotar **Branch Management (BranchUnit + BranchUnitBusinessMember +
  Record Association Builder)** como modelo organizacional/visibilidade; manter **ServiceTerritory**
  apenas para agendamento (Automotive Scheduler).
- **Novo item (ligado ao discriminador):** criar **Record Type de Account "Concesionaria"** e
  aplicá-lo às contas de dealer; usar como discriminador de nível.

## Snippet de confirmação (somente leitura) — API names dos objetos de Branch Management
```apex
for(String o:new List<String>{'BranchUnit','BranchUnitBusinessMember','BranchUnitRelatedRecord'}){
 Schema.SObjectType t=Schema.getGlobalDescribe().get(o);
 System.debug('BM> '+o+': '+(t!=null?'PRESENTE':'AUSENTE'));
 if(t!=null) for(Schema.SObjectField f:t.getDescribe().fields.getMap().values()){
  Schema.DescribeFieldResult d=f.getDescribe();
  if(d.getType()==Schema.DisplayType.REFERENCE) System.debug('   '+d.getName()+' -> '+d.getReferenceTo());
 }
}
```

## Fontes
- Configure Branch Management for Automotive Cloud — help.salesforce.com/s/articleView?id=sf.auto_configure_branch_mngmnt_dealer.htm
- Stakeholder Management in Automotive Cloud (Trailhead) — trailhead.salesforce.com/content/learn/modules/stakeholder-modeling-in-automotive-cloud
- Automotive Cloud Data Model — help.salesforce.com/s/articleView?id=ind.auto_data_model.htm
- Automotive Cloud Standard Objects (Developer Guide) — developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm
- Create Business Profiles in Automotive Cloud — help.salesforce.com/s/articleView?id=sf.auto_create_businness_profiles.htm

> Corpo das páginas não pôde ser baixado nesta sessão (egresso bloqueia *.salesforce.com, HTTP 403);
> os API names dos objetos de Branch Management devem ser confirmados via o snippet acima.
