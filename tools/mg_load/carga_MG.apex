// ============================================================
// Carga de Contas MG (cluster SEMPRE) - Apex ANONIMO
// DRY_RUN por padrao. Sobe o CSV como arquivo (ContentVersion) e roda.
// Fatie por WIN_START/WIN_END se estourar limite de CPU (cada execucao = 1 transacao).
// ============================================================

// ---- Config ----
Boolean DRY_RUN   = true;                    // false = grava (DML)
String  FILE_TITLE= 'contas_MG_415';         // trecho do Title/nome do arquivo enviado (busca por LIKE)
Integer WIN_START = 0;                       // janela [start,end) sobre linhas de dados
Integer WIN_END   = 150;                     // rode 0-150, 150-300, 300-415
Id      RT_LEGAL  = '012V2000002CjppIAC';    // RecordType LegalEntity_B2B
Set<String> RETER = new Set<String>{         // 6 excecoes ja determinadas (retidas)
    '00075209462668','59896558000167','60239950000122',
    '99999999992103','38486817000194','18715391000196'};

// ---- Parser CSV aware de aspas ----
List<List<String>> rows = new List<List<String>>();
String titleLike = '%' + FILE_TITLE + '%';
List<ContentVersion> cvs = [SELECT VersionData FROM ContentVersion
    WHERE IsLatest = true AND (Title LIKE :titleLike OR PathOnClient LIKE :titleLike)
    ORDER BY CreatedDate DESC LIMIT 1];
if (cvs.isEmpty()){
    System.debug('ARQUIVO NAO ENCONTRADO para "'+FILE_TITLE+'". Liste os titulos com: '
        +'SELECT Title, PathOnClient FROM ContentVersion WHERE IsLatest=true ORDER BY CreatedDate DESC');
    return;
}
ContentVersion cv = cvs[0];
for (String ln : cv.VersionData.toString().split('\n')) {
    if (String.isBlank(ln.trim())) continue;
    List<String> f = new List<String>(); String cur=''; Boolean q=false;
    for (Integer i=0;i<ln.length();i++){
        String ch = ln.substring(i,i+1);
        if (ch=='"') q=!q;
        else if (ch==',' && !q){ f.add(cur); cur=''; }
        else cur+=ch;
    }
    f.add(cur);
    rows.add(f);
}

// ---- Coleta linhas da janela + chaves para as queries ----
List<Map<String,String>> regs = new List<Map<String,String>>();
Set<String> emails = new Set<String>();
Set<String> docVars = new Set<String>();
Integer last = Math.min(WIN_END, rows.size()-1);      // rows[0] = header
for (Integer i = Math.max(1, WIN_START+1); i <= last; i++){
    List<String> c = rows[i];
    if (c.size() < 5) continue;
    String norm = c[0].replaceAll('[^0-9A-Za-z]','').toUpperCase();
    if (norm.isNumeric() && norm.length()>=12 && norm.length()<14) norm = norm.leftPad(14,'0');
    String email = c[4].trim().toLowerCase();
    Map<String,String> r = new Map<String,String>{
        'norm'=>norm, 'name'=>c[2].trim(), 'email'=>email };
    regs.add(r);
    emails.add(email);
    String mask = norm.length()==14 ?
        norm.substring(0,2)+'.'+norm.substring(2,5)+'.'+norm.substring(5,8)+'/'
        +norm.substring(8,12)+'-'+norm.substring(12,14) : norm;
    r.put('mask', mask);
    docVars.add(norm); docVars.add(mask);
}

// ---- Resolve owner por email (ativo). Sem match/inativo -> retido ----
Map<String,Id> ownerByEmail = new Map<String,Id>();
for (User u : [SELECT Id, Email FROM User WHERE Email IN :emails AND IsActive = true])
    ownerByEmail.put(u.Email.toLowerCase(), u.Id);

// ---- Crossmatch: contas existentes nos DOIS formatos ----
Map<String,Account> byNorm = new Map<String,Account>();
for (Account a : [SELECT Id, DocumentNumber__c, Regional__c, Management__c, ClusterManual__c
                  FROM Account WHERE DocumentNumber__c IN :docVars]){
    String k = a.DocumentNumber__c.replaceAll('[^0-9A-Za-z]','').toUpperCase();
    if (k.isNumeric() && k.length()>=12 && k.length()<14) k = k.leftPad(14,'0');
    byNorm.put(k, a);
}

// ---- Classifica e monta DML ----
List<Account> updates = new List<Account>();
List<Account> inserts = new List<Account>();
List<String>  retidos = new List<String>();
for (Map<String,String> r : regs){
    String norm = r.get('norm');
    if (RETER.contains(norm) || norm.length()!=14){ retidos.add(norm+' | '+r.get('name')+' | doc invalido/excecao'); continue; }
    Id owner = ownerByEmail.get(r.get('email'));
    if (owner == null){ retidos.add(norm+' | '+r.get('name')+' | owner nao resolvido: '+r.get('email')); continue; }
    Account ex = byNorm.get(norm);
    if (ex != null){
        Account u = new Account(Id=ex.Id, OwnerId=owner, ClusterManual__c='SEMPRE');
        if (String.isBlank(ex.Regional__c))   u.Regional__c   = 'MG';
        if (String.isBlank(ex.Management__c)) u.Management__c = 'MG';
        updates.add(u);                       // NAO toca Name nem DocumentNumber__c
    } else {
        inserts.add(new Account(
            DocumentNumber__c=r.get('mask'), Name=r.get('name'), OwnerId=owner,
            RecordTypeId=RT_LEGAL, Regional__c='MG', Management__c='MG', ClusterManual__c='SEMPRE'));
    }
}

// ---- Relatorio ----
System.debug('=== DRY_RUN='+DRY_RUN+' janela '+WIN_START+'-'+WIN_END+' ===');
System.debug('Atualizar (update): '+updates.size());
System.debug('Criar (upsert)    : '+inserts.size());
System.debug('Retidos           : '+retidos.size());
for (String s : retidos) System.debug('  RETIDO: '+s);

// ---- DML (so quando DRY_RUN=false) ----
if (!DRY_RUN){
    if (!updates.isEmpty()){
        for (Database.SaveResult sr : Database.update(updates, false))
            if (!sr.isSuccess()) System.debug('ERRO UPDATE '+sr.getErrors());
    }
    if (!inserts.isEmpty()){
        for (Database.UpsertResult ur : Database.upsert(inserts, Account.DocumentNumber__c, false))
            if (!ur.isSuccess()) System.debug('ERRO UPSERT '+ur.getErrors());
    }
    System.debug('=== DML aplicado ===');
}
