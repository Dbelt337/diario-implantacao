/*
 * IntrospectModel.apex  —  Execute Anonymous (Developer Console: Debug > Open Execute Anonymous Window)
 * Objetivo: mapear a modelagem do org GrupoQ para o fluxo de Lead/Dealer.
 * Saida: tudo via System.debug, com marcadores ">>>" para facilitar copiar o log de volta.
 *
 * Como rodar:
 *  - Developer Console > Debug > Execute Anonymous (marque "Open Log").
 *  - OU: sf apex run --file deploy/modelagem/IntrospectModel.apex
 *  - Depois copie as linhas que comecam com ">>>" (filtre por "DEBUG|>>>" no log).
 *
 * Seguro: SO LE (describes + SELECTs). Nao grava nada.
 */

// ---------- helpers de "saida limpa" ----------
List<String> out = new List<String>();
out.add('>>> ====== INTROSPECCAO MODELAGEM GRUPOQ ======');

Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

// ---------- 1) TODOS os objetos custom (__c) e MDT (__mdt) ----------
out.add('>>> ');
out.add('>>> ===== 1. OBJETOS CUSTOM (__c) =====');
List<String> customObjs = new List<String>();
List<String> mdtObjs = new List<String>();
for (String key : gd.keySet()) {
    Schema.DescribeSObjectResult d = gd.get(key).getDescribe();
    String nm = d.getName();
    if (nm.endsWithIgnoreCase('__mdt')) {
        mdtObjs.add(nm);
        continue;
    }
    if (d.isCustom() && nm.endsWithIgnoreCase('__c')) {
        customObjs.add(nm);
    }
}
customObjs.sort();
mdtObjs.sort();
for (String nm : customObjs) {
    out.add('>>> CUSTOMOBJ | ' + nm + ' | label=' + gd.get(nm.toLowerCase()).getDescribe().getLabel());
}
out.add('>>> ');
out.add('>>> ===== 2. CUSTOM METADATA TYPES (__mdt) =====');
for (String nm : mdtObjs) {
    out.add('>>> MDT | ' + nm + ' | label=' + gd.get(nm.toLowerCase()).getDescribe().getLabel());
}

// ---------- alvos a detalhar: Account, BusinessProfile + custom do dominio ----------
Set<String> targets = new Set<String>{'Account','BusinessProfile','LeadPreferredSeller'};
for (String nm : customObjs) {
    String low = nm.toLowerCase();
    if (low.contains('marca') || low.contains('socied') || low.contains('sucursal')
        || low.contains('dealer') || low.contains('brand') || low.contains('outlet')
        || low.contains('unidad') || low.contains('organiz') || low.contains('vendedor')
        || low.contains('seller') || low.contains('pais') || low.contains('country')
        || low.contains('almac') || low.contains('centro') || low.contains('concesion')) {
        targets.add(nm);
    }
}

// ---------- 3) Record Types do Account ----------
out.add('>>> ');
out.add('>>> ===== 3. ACCOUNT RECORD TYPES =====');
for (Schema.RecordTypeInfo rt : gd.get('account').getDescribe().getRecordTypeInfos()) {
    if (rt.isAvailable()) {
        out.add('>>> ACCOUNT_RT | ' + rt.getName() + ' | devName=' + rt.getDeveloperName() + ' | default=' + rt.isDefaultRecordTypeMapping());
    }
}

// ---------- 4) Campos dos alvos (custom + chaves) ----------
out.add('>>> ');
out.add('>>> ===== 4. CAMPOS DOS OBJETOS-CHAVE =====');
for (String objApi : targets) {
    Schema.SObjectType st = gd.get(objApi.toLowerCase());
    if (st == null) { out.add('>>> (objeto nao encontrado: ' + objApi + ')'); continue; }
    Schema.DescribeSObjectResult d = st.getDescribe();
    out.add('>>> --- OBJ ' + d.getName() + ' (label=' + d.getLabel() + ') ---');
    Map<String, Schema.SObjectField> fmap = d.fields.getMap();
    for (String fk : fmap.keySet()) {
        Schema.DescribeFieldResult fd = fmap.get(fk).getDescribe();
        String fn = fd.getName();
        // so campos custom OU campos-chave standard relevantes
        Boolean keyStd = (new Set<String>{'Id','Name','ParentId','AccountId','RecordTypeId',
            'BusinessPartnerCode','ExternalReferenceNumber','BusinessPartnerType',
            'BusinessOperatingName','BusinessPartnerRegisteredName','Type','Industry'}).contains(fn);
        if (fd.isCustom() || keyStd) {
            String ref = '';
            if (fd.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> refs = fd.getReferenceTo();
                if (!refs.isEmpty()) ref = ' -> ' + refs[0].getDescribe().getName();
            }
            out.add('>>> FIELD | ' + d.getName() + ' | ' + fn + ' | ' + fd.getType() + ref + ' | ' + fd.getLabel());
        }
    }
}

System.debug(String.join(out, '\n'));

// ---------- 5) Amostras de dados (queries separadas para nao estourar log) ----------
List<String> out2 = new List<String>();
out2.add('>>> ');
out2.add('>>> ===== 5. AMOSTRAS DE DADOS =====');

// Account: hierarquia + campos custom
try {
    out2.add('>>> -- ACCOUNT (amostra) --');
    for (Account a : Database.query(
        'SELECT Id, Name, RecordType.DeveloperName, ParentId, Parent.Name FROM Account ORDER BY Name LIMIT 25')) {
        out2.add('>>> ACC | ' + a.Id + ' | ' + a.Name + ' | RT=' + (a.RecordType!=null?a.RecordType.DeveloperName:'') + ' | parent=' + (a.Parent!=null?a.Parent.Name:''));
    }
} catch (Exception e) { out2.add('>>> ERRO Account: ' + e.getMessage()); }

// BusinessProfile: amostra ampla
try {
    out2.add('>>> -- BUSINESSPROFILE (amostra) --');
    for (SObject bp : Database.query(
        'SELECT Id, Name, AccountId, Account.Name, Account.Parent.Name, BusinessPartnerCode, ExternalReferenceNumber, BusinessPartnerType FROM BusinessProfile ORDER BY Name LIMIT 40')) {
        out2.add('>>> BP | ' + bp.get('Name') + ' | acct=' + bp.get('AccountId')
            + ' | code=' + bp.get('BusinessPartnerCode') + ' | extRef=' + bp.get('ExternalReferenceNumber')
            + ' | type=' + bp.get('BusinessPartnerType'));
    }
} catch (Exception e) { out2.add('>>> ERRO BusinessProfile: ' + e.getMessage()); }

System.debug(String.join(out2, '\n'));

// ---------- 6) Amostra dos objetos custom do dominio + MDT ----------
List<String> out3 = new List<String>();
out3.add('>>> ');
out3.add('>>> ===== 6. AMOSTRA OBJETOS DOMINIO + MDT =====');

Set<String> sampleObjs = new Set<String>(targets);
sampleObjs.remove('Account');
sampleObjs.remove('BusinessProfile');
// adiciona MDT do dominio
for (String m : mdtObjs) {
    String low = m.toLowerCase();
    if (low.contains('marca') || low.contains('socied') || low.contains('brand')
        || low.contains('dealer') || low.contains('sucursal') || low.contains('map')
        || low.contains('country') || low.contains('pais')) {
        sampleObjs.add(m);
    }
}

Integer queryBudget = 80;
for (String objApi : sampleObjs) {
    if (queryBudget <= 0) break;
    Schema.SObjectType st = gd.get(objApi.toLowerCase());
    if (st == null) continue;
    Schema.DescribeSObjectResult d = st.getDescribe();
    // monta lista de campos queryaveis (custom + Name + Id), pula compound
    List<String> qf = new List<String>{'Id'};
    Map<String, Schema.SObjectField> fmap = d.fields.getMap();
    if (fmap.containsKey('name')) qf.add('Name');
    for (String fk : fmap.keySet()) {
        Schema.DescribeFieldResult fd = fmap.get(fk).getDescribe();
        if (!fd.isCustom()) continue;
        Schema.DisplayType t = fd.getType();
        if (t == Schema.DisplayType.ADDRESS || t == Schema.DisplayType.LOCATION) continue;
        if (fd.getName().equalsIgnoreCase('Name')) continue;
        qf.add(fd.getName());
    }
    try {
        Integer total = Database.countQuery('SELECT count() FROM ' + d.getName());
        out3.add('>>> ');
        out3.add('>>> -- ' + d.getName() + ' (total=' + total + ') campos: ' + String.join(qf, ','));
        queryBudget -= 2;
        for (SObject r : Database.query('SELECT ' + String.join(qf, ',') + ' FROM ' + d.getName() + ' LIMIT 15')) {
            List<String> vals = new List<String>();
            for (String f : qf) {
                Object v = r.get(f);
                vals.add(f + '=' + (v==null?'':String.valueOf(v)));
            }
            out3.add('>>> ROW | ' + d.getName() + ' | ' + String.join(vals, ' | '));
        }
    } catch (Exception e) {
        out3.add('>>> ERRO ' + d.getName() + ': ' + e.getMessage());
    }
}

System.debug(String.join(out3, '\n'));
System.debug('>>> ====== FIM INTROSPECCAO ======');
