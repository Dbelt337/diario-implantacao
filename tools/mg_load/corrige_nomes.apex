// ============================================================
// Corrige nomes corrompidos (mojibake) das contas MG.
// Le o CSV dos Files (UTF-8 correto) e regrava Account.Name casando
// pelo DocumentNumber__c mascarado. Apex e Unicode: nao corrompe.
// DRY_RUN por padrao (so conta e lista). Nao usa Inspector/Excel.
// ============================================================

Boolean DRY_RUN   = true;                 // false = grava
String  FILE_TITLE= 'contas_MG_415';      // trecho do nome do arquivo nos Files

String like = '%' + FILE_TITLE + '%';
List<ContentVersion> cvs = [SELECT VersionData FROM ContentVersion
    WHERE IsLatest = true AND (Title LIKE :like OR PathOnClient LIKE :like)
    ORDER BY CreatedDate DESC LIMIT 1];
if (cvs.isEmpty()){ System.debug('ARQUIVO NAO ENCONTRADO para "'+FILE_TITLE+'"'); return; }

// Parse quote-aware -> map(DocumentNumber mascarado -> Name correto)
Map<String,String> nameByDoc = new Map<String,String>();
for (String ln : cvs[0].VersionData.toString().split('\n')){
    if (String.isBlank(ln.trim())) continue;
    List<String> f = new List<String>(); String cur=''; Boolean q=false;
    for (Integer i=0;i<ln.length();i++){
        String ch = ln.substring(i,i+1);
        if (ch=='"') q=!q;
        else if (ch==',' && !q){ f.add(cur); cur=''; }
        else cur+=ch;
    }
    f.add(cur);
    if (f.size() < 3) continue;
    String norm = f[0].replaceAll('[^0-9A-Za-z]','').toUpperCase();     // CNPJ_NORMALIZADO
    if (norm.isNumeric() && norm.length()>=12 && norm.length()<14) norm = norm.leftPad(14,'0');
    if (norm.length()!=14) continue;                                    // pula header e invalidos
    String mask = norm.substring(0,2)+'.'+norm.substring(2,5)+'.'+norm.substring(5,8)
                 +'/'+norm.substring(8,12)+'-'+norm.substring(12,14);
    nameByDoc.put(mask, f[2].trim());                                   // RAZAO_SOCIAL
}

// Compara com o org e corrige so o que difere
List<Account> upd = new List<Account>();
for (Account a : [SELECT Id, DocumentNumber__c, Name FROM Account
                  WHERE DocumentNumber__c IN :nameByDoc.keySet()]){
    String correto = nameByDoc.get(a.DocumentNumber__c);
    if (correto != null && a.Name != correto) upd.add(new Account(Id=a.Id, Name=correto));
}

System.debug('=== DRY_RUN='+DRY_RUN+' | nomes a corrigir: '+upd.size()+' ===');
for (Account a : upd) System.debug('  '+a.Id+' -> '+a.Name);

if (!DRY_RUN && !upd.isEmpty()){
    update upd;
    System.debug('=== '+upd.size()+' nomes corrigidos ===');
}
