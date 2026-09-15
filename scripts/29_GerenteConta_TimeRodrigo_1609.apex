// 29 - Chamado da Sustentacao (Samuel Vitor, via Tatiane Pompermaier, time de planejamento): "Gerente da conta" das contas do
// time do Rodrigo Nascimento Piccolo deve ser o Rodrigo, tanto nas contas que estao com o Wesley Ramalho Goncalves quanto nas
// que estao em branco. NAO mudar o dono da conta nem o dono da oportunidade (sao o gerente de relacionamento).
// Levantamento de 15/09: 6 contas com Wesley (3 Gabriel, 3 Tatiane), 27 em branco (Luan, Lucidia, Tamires, Tatiane) e 13
// oportunidades abertas com aprovador (ManagerAccount__c) diferente do Rodrigo, 6 delas do Gabriel travadas em aprovacao.
// DUAS FASES. EXECUTAR = false: so lista o time, as contas e as oportunidades que seriam alteradas. EXECUTAR = true: atualiza
// Account.AccountManager__c e Opportunity.ManagerAccount__c (allOrNone = false: quem falhar por trava de aprovacao ou regra
// de validacao fica listado para tratar depois). Nunca toca em OwnerId. Filtre o log por HIE29|.
Boolean EXECUTAR = false;

User rodrigo = [SELECT Id, Name, UserRoleId, UserRole.Name FROM User WHERE Name = 'Rodrigo Nascimento Piccolo' AND IsActive = true LIMIT 1];
User wesley  = [SELECT Id, Name FROM User WHERE Name = 'Wesley Ramalho Goncalves' AND IsActive = true LIMIT 1];
System.debug('HIE29| gerente alvo=' + rodrigo.Name + ' (' + rodrigo.Id + ') papel=' + rodrigo.UserRole.Name + ' | gerente a substituir=' + wesley.Name + ' (' + wesley.Id + ')');

// time do Rodrigo = usuarios ativos nos papeis abaixo do papel dele (ate 3 niveis)
Set<Id> papeis = new Set<Id>{ rodrigo.UserRoleId };
Set<Id> fronteira = new Set<Id>{ rodrigo.UserRoleId };
for (Integer nivel = 0; nivel < 3 && !fronteira.isEmpty(); nivel++) {
    Set<Id> prox = new Set<Id>();
    for (UserRole r : [SELECT Id, Name FROM UserRole WHERE ParentRoleId IN :fronteira]) { prox.add(r.Id); System.debug('HIE29| papel filho (nivel ' + (nivel + 1) + '): ' + r.Name); }
    papeis.addAll(prox); fronteira = prox;
}
Map<Id, User> time = new Map<Id, User>([SELECT Id, Name, UserRole.Name FROM User WHERE IsActive = true AND UserRoleId IN :papeis AND Id != :rodrigo.Id ORDER BY Name]);
for (User u : time.values()) System.debug('HIE29| membro do time: ' + u.Name + ' | ' + u.UserRole.Name);
System.debug('HIE29| time do Rodrigo: ' + time.size() + ' usuario(s)');

// contas do time com gerente = Wesley ou em branco
List<Account> contas = [SELECT Id, Name, Owner.Name, AccountManager__c, AccountManager__r.Name FROM Account
                        WHERE OwnerId IN :time.keySet() AND (AccountManager__c = :wesley.Id OR AccountManager__c = null) ORDER BY Owner.Name, Name];
Integer nW = 0, nB = 0;
for (Account a : contas) {
    if (a.AccountManager__c == null) nB++; else nW++;
    System.debug('HIE29| CONTA | ' + a.Name.left(50) + ' | dono=' + a.Owner.Name + ' | gerente atual=' + (a.AccountManager__c == null ? '(em branco)' : a.AccountManager__r.Name) + ' -> ' + rodrigo.Name);
    a.AccountManager__c = rodrigo.Id;
}
System.debug('HIE29| contas a alterar: ' + contas.size() + ' (' + nW + ' com Wesley, ' + nB + ' em branco). Dono da conta nao muda.');

// oportunidades abertas do time com aprovador (Gerente da Conta na opp) diferente do Rodrigo
List<Opportunity> opps = [SELECT Id, Name, Owner.Name, StageName, ManagerAccount__c, ManagerAccount__r.Name, Send4Approval__c FROM Opportunity
                          WHERE IsClosed = false AND OwnerId IN :time.keySet() AND (ManagerAccount__c != :rodrigo.Id OR ManagerAccount__c = null) ORDER BY Owner.Name, Name];
for (Opportunity o : opps) {
    System.debug('HIE29| OPP | ' + o.Name.left(50) + ' | dono=' + o.Owner.Name + ' | fase=' + o.StageName + ' | em aprovacao=' + o.Send4Approval__c
        + ' | travada=' + Approval.isLocked(o.Id) + ' | gerente atual=' + (o.ManagerAccount__c == null ? '(em branco)' : o.ManagerAccount__r.Name) + ' -> ' + rodrigo.Name);
    o.ManagerAccount__c = rodrigo.Id;
}
System.debug('HIE29| oportunidades a alterar: ' + opps.size() + '. Dono da oportunidade nao muda. As travadas em aprovacao devem falhar na regra de validacao e ficam para depois.');

if (!EXECUTAR) { System.debug('HIE29| FASE 1 concluida: nada alterado. Confira o time e as listas e rode com EXECUTAR = true.'); return; }

Integer okA = 0; List<String> errA = new List<String>();
for (Database.SaveResult r : Database.update(contas, false)) { if (r.isSuccess()) okA++; else errA.add(r.getId() + ': ' + r.getErrors()[0].getMessage().left(120)); }
System.debug('HIE29| CONTAS: ' + okA + ' atualizada(s), ' + errA.size() + ' falha(s)');
for (String e : errA) System.debug('HIE29|   falha conta ' + e);
Integer okO = 0; List<String> errO = new List<String>();
Database.SaveResult[] rs = Database.update(opps, false);
for (Integer i = 0; i < rs.size(); i++) { if (rs[i].isSuccess()) okO++; else errO.add(opps[i].Name.left(40) + ' (' + opps[i].Owner.Name + '): ' + rs[i].getErrors()[0].getMessage().left(110)); }
System.debug('HIE29| OPORTUNIDADES: ' + okO + ' atualizada(s), ' + errO.size() + ' falha(s) - as que falharam por aprovacao ficam para depois da aprovacao ou reatribuicao (script 27)');
for (String e : errO) System.debug('HIE29|   falha opp ' + e);
// conferencia
System.debug('HIE29| DEPOIS | contas do time com gerente Rodrigo: ' + [SELECT COUNT() FROM Account WHERE OwnerId IN :time.keySet() AND AccountManager__c = :rodrigo.Id]
    + ' | com Wesley: ' + [SELECT COUNT() FROM Account WHERE OwnerId IN :time.keySet() AND AccountManager__c = :wesley.Id]
    + ' | em branco: ' + [SELECT COUNT() FROM Account WHERE OwnerId IN :time.keySet() AND AccountManager__c = null]);
System.debug('HIE29| DEPOIS | opps abertas do time com aprovador diferente do Rodrigo: ' + [SELECT COUNT() FROM Opportunity WHERE IsClosed = false AND OwnerId IN :time.keySet() AND (ManagerAccount__c != :rodrigo.Id OR ManagerAccount__c = null)]);
