/* =====================================================================
 * Auditoria Modelo Organizacional - GrupoQ DevSales | SOMENTE LEITURA
 * Execute Anonymous (Developer Console > Debug > Open Execute Anonymous,
 * ou: sf apex run -o grupoq--devsales -f auditoria_readonly.apex).
 * NENHUM DML / deploy / alteracao. So SOQL, describe e leitura de picklist.
 * O relatorio sai no debug log: filtre pelas linhas que comecam com 'AUDIT>'.
 * ===================================================================== */

// Classe auxiliar (instancia) para contagens/grupos dinamicos tolerantes a erro.
public class Aud {
    public List<String> out;
    public Aud(List<String> o) { this.out = o; }
    public void cnt(String label, String soql) {
        try { out.add(label + ': ' + Database.countQuery(soql)); }
        catch (Exception e) { out.add(label + ': ERRO ' + e.getTypeName() + ' - ' + e.getMessage()); }
    }
    public void grp(String label, String soql) {
        try {
            List<AggregateResult> rs = Database.query(soql);
            if (rs.isEmpty()) { out.add(label + ': (vazio)'); return; }
            for (AggregateResult ar : rs) out.add(label + ' | ' + JSON.serialize(ar));
        } catch (Exception e) { out.add(label + ': ERRO ' + e.getMessage()); }
    }
}

List<String> out = new List<String>();
Aud a = new Aud(out);
Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

// Lista canonica das 17 sociedades (baseline Modelo B).
Set<String> canon = new Set<String>{
    'C101','C105','C106-PROV','H101','H105','H106-PROV','S101','S105','S106-PROV',
    'S206','N101','N105','N106-PROV','G101','G105','P103','P105'
};

out.add('===================================================');
out.add('AUDITORIA MODELO ORGANIZACIONAL - GrupoQ DevSales');
out.add('Execucao: ' + System.now().format('yyyy-MM-dd HH:mm:ss'));
out.add('===================================================');

/* ---------- FASE 1: SCHEMA E DESCOBERTAS ---------- */
out.add('---- FASE 1: SCHEMA ----');
for (String o : new List<String>{'Account','BusinessProfile','InternalOrganizationUnit',
        'BranchUnit','ServiceTerritory','BusinessBrand','User'}) {
    out.add('objeto ' + o + ': ' + (gd.containsKey(o) ? 'PRESENTE' : 'AUSENTE/SEM ACESSO (ACHADO)'));
}

// Record Types de Account (candidato a discriminador de nivel).
try {
    for (RecordType rt : [SELECT DeveloperName, Name, IsActive FROM RecordType
                          WHERE SobjectType = 'Account' ORDER BY DeveloperName]) {
        out.add('Account RT: ' + rt.DeveloperName + ' (' + rt.Name + ') active=' + rt.IsActive);
    }
} catch (Exception e) { out.add('Account RT: ERRO ' + e.getMessage()); }

// Campos relevantes em Account (custom + sociedad/brand/code/sap).
if (gd.containsKey('Account')) {
    Map<String, Schema.SObjectField> fm = gd.get('Account').getDescribe().fields.getMap();
    Pattern p = Pattern.compile('(?i).*(sociedad|brand|marca|sap|codigo|code).*');
    for (String fn : fm.keySet()) {
        Schema.DescribeFieldResult d = fm.get(fn).getDescribe();
        if (d.isCustom() || p.matcher(d.getName()).matches()) {
            out.add('Account.field ' + d.getName() + ' | type=' + d.getType()
                    + ' | ref=' + d.getReferenceTo());
        }
    }
}

// Campos alvo em User.
if (gd.containsKey('User')) {
    Map<String, Schema.SObjectField> fm = gd.get('User').getDescribe().fields.getMap();
    for (String fn : new List<String>{'sociedad__c','sucursalbp__c','tipoautoquevende__c','canal__c'}) {
        out.add('User.' + fn + ': ' + (fm.containsKey(fn) ? 'PRESENTE' : 'AUSENTE (achado)'));
    }
}

// Descoberta do lookup BusinessProfile -> Account.
String bpAccField = null;
if (gd.containsKey('BusinessProfile')) {
    Map<String, Schema.SObjectField> fm = gd.get('BusinessProfile').getDescribe().fields.getMap();
    for (String fn : fm.keySet()) {
        Schema.DescribeFieldResult d = fm.get(fn).getDescribe();
        if (d.getType() == Schema.DisplayType.REFERENCE) {
            for (Schema.SObjectType rt : d.getReferenceTo()) {
                if (rt.getDescribe().getName() == 'Account') {
                    out.add('BP lookup -> Account: ' + d.getName());
                    if (bpAccField == null) bpAccField = d.getName();
                }
            }
        }
    }
    if (bpAccField == null) out.add('BP -> Account: NENHUM lookup para Account encontrado (achado)');
}

/* ---------- FASE 2: INVENTARIO / CONTAGENS ---------- */
out.add('---- FASE 2: CONTAGENS (real x alvo) ----');
a.cnt('Account nivel1 Holding [alvo 1]',   'SELECT COUNT() FROM Account WHERE ParentId = null');
a.cnt('Account nivel2 Pais [alvo 6]',      'SELECT COUNT() FROM Account WHERE ParentId != null AND Parent.ParentId = null');
a.cnt('Account nivel3 Sociedade [alvo 17]','SELECT COUNT() FROM Account WHERE Parent.ParentId != null AND Parent.Parent.ParentId = null');
a.cnt('Account nivel4 Dealer [alvo 128]',  'SELECT COUNT() FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null');
a.cnt('Account nivel5+ (achado se >0)',    'SELECT COUNT() FROM Account WHERE Parent.Parent.Parent.ParentId != null');
a.grp('Account por RecordType',            'SELECT RecordType.DeveloperName rt, COUNT(Id) c FROM Account GROUP BY RecordType.DeveloperName');
a.grp('BusinessProfile por tipo',          'SELECT BusinessPartnerType t, COUNT(Id) c FROM BusinessProfile GROUP BY BusinessPartnerType');
a.cnt('InternalOrganizationUnit [alvo 17]','SELECT COUNT() FROM InternalOrganizationUnit');
a.cnt('BranchUnit',                        'SELECT COUNT() FROM BranchUnit');
a.cnt('ServiceTerritory',                  'SELECT COUNT() FROM ServiceTerritory');
a.cnt('BusinessBrand [alvo 22]',           'SELECT COUNT() FROM BusinessBrand');

/* ---------- FASE 3: INTEGRIDADE DA HIERARQUIA ---------- */
out.add('---- FASE 3: HIERARQUIA ----');
a.cnt('Accounts com ParentId nulo (holding + orfaos)', 'SELECT COUNT() FROM Account WHERE ParentId = null');
a.cnt('Accounts profundidade > 4 (achado)', 'SELECT COUNT() FROM Account WHERE Parent.Parent.Parent.ParentId != null');
a.grp('Duplicidade nome sob mesmo pai',
      'SELECT ParentId p, Name n, COUNT(Id) c FROM Account WHERE ParentId != null GROUP BY ParentId, Name HAVING COUNT(Id) > 1');

/* ---------- FASE 4: BUSINESSPROFILE E CHAVE SAP (P0) ---------- */
out.add('---- FASE 4: BUSINESSPROFILE / CHAVE SAP (CRITICIDADE MAXIMA) ----');
a.cnt('BP Sales Dealer com ExternalReferenceNumber NULO (P0)',
      'SELECT COUNT() FROM BusinessProfile WHERE BusinessPartnerType = \'Sales Dealer\' AND ExternalReferenceNumber = null');
a.grp('BP ExternalReferenceNumber DUPLICADO (P0)',
      'SELECT ExternalReferenceNumber ref, COUNT(Id) c FROM BusinessProfile WHERE ExternalReferenceNumber != null GROUP BY ExternalReferenceNumber HAVING COUNT(Id) > 1');
if (bpAccField != null) {
    a.cnt('BP orfaos (sem Account no lookup ' + bpAccField + ')',
          'SELECT COUNT() FROM BusinessProfile WHERE ' + bpAccField + ' = null');
}

// Anti-join em memoria: dealers (nivel 4) sem BP 'Sales Dealer'.
if (bpAccField != null) {
    try {
        Set<Id> dealerIds = new Set<Id>();
        for (Account ac : [SELECT Id FROM Account
                           WHERE Parent.Parent.ParentId != null
                             AND Parent.Parent.Parent.ParentId = null]) {
            dealerIds.add(ac.Id);
        }
        Set<Id> comBp = new Set<Id>();
        for (SObject bp : Database.query('SELECT ' + bpAccField
                + ' FROM BusinessProfile WHERE BusinessPartnerType = \'Sales Dealer\'')) {
            Object v = bp.get(bpAccField);
            if (v != null) comBp.add((Id) v);
        }
        Integer semBp = 0;
        List<Id> exemplos = new List<Id>();
        for (Id d : dealerIds) {
            if (!comBp.contains(d)) { semBp++; if (exemplos.size() < 20) exemplos.add(d); }
        }
        out.add('DEALERS nivel4 SEM BP Sales Dealer (P0): ' + semBp + ' de ' + dealerIds.size());
        if (!exemplos.isEmpty()) out.add('  exemplos AccountId: ' + exemplos);
    } catch (Exception e) { out.add('Anti-join dealer/BP: ERRO ' + e.getMessage()); }
}

/* ---------- FASE 5: INTERNALORGANIZATIONUNIT ---------- */
out.add('---- FASE 5: IOU ----');
a.cnt('IOU com AccountId nulo (achado)', 'SELECT COUNT() FROM InternalOrganizationUnit WHERE AccountId = null');
try {
    Integer n = 0;
    for (InternalOrganizationUnit i : [SELECT Name, Account.Name FROM InternalOrganizationUnit ORDER BY Name]) {
        if (n < 30) out.add('IOU: ' + i.Name + ' -> Account=' + (i.Account != null ? i.Account.Name : 'NULO'));
        n++;
    }
    out.add('IOU total listado: ' + n);
} catch (Exception e) { out.add('IOU lista: ERRO ' + e.getMessage()); }

/* ---------- FASE 6: BRANCHUNIT / SERVICETERRITORY ---------- */
out.add('---- FASE 6: BRANCHUNIT / SERVICETERRITORY ----');
a.cnt('BranchUnit sem AccountId', 'SELECT COUNT() FROM BranchUnit WHERE AccountId = null');
a.cnt('BranchUnit raiz (sem ParentBranchUnitId)', 'SELECT COUNT() FROM BranchUnit WHERE ParentBranchUnitId = null');
a.cnt('ServiceTerritory raiz (sem ParentTerritoryId)', 'SELECT COUNT() FROM ServiceTerritory WHERE ParentTerritoryId = null');

/* ---------- FASE 7: CONFIGURACAO DE SUPORTE ---------- */
out.add('---- FASE 7: CONFIG DE SUPORTE ----');

// CMT Sociedad_Config__mdt.
Set<String> cmt = new Set<String>();
try {
    for (SObject s : Database.query('SELECT DeveloperName FROM Sociedad_Config__mdt')) {
        cmt.add((String) s.get('DeveloperName'));
    }
    out.add('CMT Sociedad_Config__mdt registros: ' + cmt.size());
} catch (Exception e) { out.add('CMT Sociedad_Config__mdt: ERRO/AUSENTE ' + e.getMessage()); }

// Valores ativos de User.Sociedad__c (reflete GVS_Sociedad se vinculado).
Set<String> gvsLike = new Set<String>();
if (gd.containsKey('User')) {
    Map<String, Schema.SObjectField> fm = gd.get('User').getDescribe().fields.getMap();
    if (fm.containsKey('sociedad__c')) {
        for (Schema.PicklistEntry pe : fm.get('sociedad__c').getDescribe().getPicklistValues()) {
            if (pe.isActive()) gvsLike.add(pe.getValue());
        }
        out.add('User.Sociedad__c valores ativos: ' + gvsLike.size());
    }
}

// Accounts de sociedade (nivel 3) - heuristica: codigo aparece no Name.
Set<String> accSoc = new Set<String>();
try {
    for (Account ac : [SELECT Name FROM Account
                       WHERE Parent.ParentId != null AND Parent.Parent.ParentId = null]) {
        accSoc.add(ac.Name);
    }
} catch (Exception e) { out.add('Accounts nivel3: ERRO ' + e.getMessage()); }

// Matriz de reconciliacao canonica x GVS(User) x CMT x Accounts.
out.add('-- RECONCILIACAO (canonica x gvsUser x cmt x acc) --');
for (String v : canon) {
    out.add('RECON ' + v
            + ' | canon=X'
            + ' gvsUser=' + (gvsLike.contains(v) ? 'X' : '-')
            + ' cmt='     + (cmt.contains(v)     ? 'X' : '-')
            + ' acc='     + (accSoc.contains(v)  ? 'X' : '-'));
}
for (String v : cmt)     if (!canon.contains(v)) out.add('RECON EXTRA cmt (fora da canonica): ' + v);
for (String v : gvsLike) if (!canon.contains(v)) out.add('RECON EXTRA gvsUser (fora da canonica): ' + v);
for (String v : accSoc)  if (!canon.contains(v)) out.add('RECON EXTRA acc (fora da canonica): ' + v);

// Account.BrandName__c: existencia e preenchimento no escopo dealer.
Boolean hasBrand = gd.containsKey('Account')
        && gd.get('Account').getDescribe().fields.getMap().containsKey('brandname__c');
if (hasBrand) {
    a.cnt('Dealers com BrandName__c preenchido',
          'SELECT COUNT() FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null AND BrandName__c != null');
    a.cnt('Dealers com BrandName__c NULO',
          'SELECT COUNT() FROM Account WHERE Parent.Parent.ParentId != null AND Parent.Parent.Parent.ParentId = null AND BrandName__c = null');
} else {
    out.add('Account.BrandName__c: AUSENTE (achado)');
}

// User.Sociedad__c / SucursalBP__c: preenchimento nos ativos.
if (gd.containsKey('User')) {
    Map<String, Schema.SObjectField> fm = gd.get('User').getDescribe().fields.getMap();
    if (fm.containsKey('sociedad__c')) {
        a.grp('User.Sociedad__c preenchimento (ativos)',
              'SELECT Sociedad__c s, COUNT(Id) c FROM User WHERE IsActive = true GROUP BY Sociedad__c');
    }
    if (fm.containsKey('sucursalbp__c')) {
        a.cnt('Usuarios ativos SEM SucursalBP__c',
              'SELECT COUNT() FROM User WHERE IsActive = true AND SucursalBP__c = null');
    }
}

/* ---------- FASE 8: AUTOMACOES ---------- */
out.add('---- FASE 8: FLOWS ATIVOS ----');
try {
    for (SObject f : Database.query('SELECT ApiName, Label, ProcessType, TriggerType FROM FlowDefinitionView WHERE IsActive = true ORDER BY ProcessType, ApiName')) {
        out.add('FLOW ' + f.get('ApiName') + ' | ' + f.get('ProcessType') + ' | trigger=' + f.get('TriggerType'));
    }
} catch (Exception e) { out.add('FlowDefinitionView: ERRO ' + e.getMessage()); }

/* ---------- SAIDA ---------- */
out.add('===================================================');
out.add('FIM DA COLETA - ' + out.size() + ' linhas | limites: SOQL '
        + Limits.getQueries() + '/' + Limits.getLimitQueries()
        + ' | linhas ' + Limits.getQueryRows() + '/' + Limits.getLimitQueryRows());
for (String line : out) System.debug('AUDIT> ' + line);
