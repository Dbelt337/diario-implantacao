// 43 - Responsavel (agf__Assignee__c) das 7 works em sprint corrente que estavam sem responsavel (revisao de 17/09, item 4):
// 133 a 137 (Sprint 1 - Brasil TecPar) e 140, 141 (Sprint 1 - SysMap) -> Davi Israel de Abreu, decisao do Diego em 17/09.
// PO (agf__Product_Owner__c) e a Priscila De Lima: ja estava nas 7; o script so preenche se estiver vazia. Nao mexe em mais nada.
// So altera se o campo estiver vazio (nao sobrescreve responsavel ja definido). DUAS FASES: EXECUTAR = false so lista. Filtre por RSP43|.
Boolean EXECUTAR = false;
Set<String> works = new Set<String>{ 'W-000133', 'W-000134', 'W-000135', 'W-000136', 'W-000137', 'W-000140', 'W-000141' };
User davi = [SELECT Id, Name, IsActive FROM User WHERE Name = 'Davi Israel de Abreu' LIMIT 1];
User po   = [SELECT Id, Name, IsActive FROM User WHERE Name = 'Priscila De Lima' LIMIT 1];
if (!davi.IsActive || !po.IsActive) { System.debug('RSP43| usuario inativo: ' + davi.Name + '=' + davi.IsActive + ', ' + po.Name + '=' + po.IsActive + ' - nada alterado'); return; }
List<agf__ADM_Work__c> upd = new List<agf__ADM_Work__c>();
for (agf__ADM_Work__c w : [SELECT Id, Name, agf__Subject__c, agf__Sprint__r.Name, agf__Assignee__c, agf__Assignee__r.Name, agf__Product_Owner__c, agf__Product_Owner__r.Name
                           FROM agf__ADM_Work__c WHERE Name IN :works ORDER BY Name]) {
    List<String> mud = new List<String>();
    if (w.agf__Assignee__c == null) { mud.add('responsavel (vazio) -> ' + davi.Name); w.agf__Assignee__c = davi.Id; }
    else if (w.agf__Assignee__c != davi.Id) System.debug('RSP43| ' + w.Name + ' | ja tem responsavel ' + w.agf__Assignee__r.Name + ' - nao sobrescreve');
    if (w.agf__Product_Owner__c == null) { mud.add('PO (vazio) -> ' + po.Name); w.agf__Product_Owner__c = po.Id; }
    System.debug('RSP43| ' + w.Name + ' | ' + w.agf__Sprint__r.Name + ' | PO=' + w.agf__Product_Owner__r.Name + ' | ' + w.agf__Subject__c.left(50)
        + (mud.isEmpty() ? ' | sem mudanca' : ' | MUDA: ' + String.join(mud, '; ')));
    if (!mud.isEmpty()) upd.add(w);
}
System.debug('RSP43| a alterar: ' + upd.size() + ' work(s)');
if (!EXECUTAR) { System.debug('RSP43| FASE 1 concluida: nada alterado. Confira e rode com EXECUTAR = true.'); return; }
update upd;
for (agf__ADM_Work__c w : [SELECT Name, agf__Assignee__r.Name, agf__Product_Owner__r.Name, agf__Sprint__r.Name FROM agf__ADM_Work__c WHERE Name IN :works ORDER BY Name])
    System.debug('RSP43| DEPOIS ' + w.Name + ' | responsavel=' + w.agf__Assignee__r.Name + ' | PO=' + w.agf__Product_Owner__r.Name + ' | ' + w.agf__Sprint__r.Name);
System.debug('RSP43| concluido: ' + upd.size() + ' work(s) alterada(s).');
