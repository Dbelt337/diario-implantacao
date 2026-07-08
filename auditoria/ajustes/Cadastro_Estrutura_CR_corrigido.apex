// Grupo Q - Cadastro/Ajuste estrutura CR (corrigido) - check-then-create, idempotente, DRY RUN.
// Correcoes vs original (ver REVISAO_script_cadastro_CR.md):
//  C-1: ExternalReferenceNumber deixa de ser o Centro (colide 8x). Usa Centro-Almacen e faz
//       PRE-FLIGHT de duplicidade (no batch e vs BPs existentes) + checa isUnique do campo.
//  A-1: bloco IOU acessa campos por describe/dinamico (nao quebra compilacao se o nome mudar).
//  A-2: aborta se as Accounts de sociedade nao existirem (evita dealer orfao).
//  M-1/M-2: guarda AssociatedLocation/Location.
// Rode idealmente via: sf apex run -o <alias> -f Cadastro_Estrutura_CR_corrigido.apex

// ===== CONFIG =====
Boolean USA_CENTRO_ALMACEN = true; // true: ExternalReferenceNumber = Centro-Almacen (ex.: C011-1200)
                                   // false: = Centro (ex.: C011) -> so se o campo NAO for unique

List<String> dados = new List<String>();
dados.add('C101|GrupoQ La Uruca|C011|C011-1200');
dados.add('C101|GrupoQ Liberia|C011|C011-1209');
dados.add('C101|GrupoQ San Carlos|C011|C011-1211');
dados.add('C101|GrupoQ Lindora|C011|C011-1210');
dados.add('C101|GrupoQ Ayarco|C011|C011-1223');
dados.add('C101|GrupoQ Uruca Usados|C817|C817-NOALM');
dados.add('C101|GrupoQ Uruca Flotas|C011|C011-1200');
dados.add('C101|GrupoQ Guapiles|C011|C011-1273');
dados.add('C101|GrupoQ Perez Zeledon|C011|C011-1272');
dados.add('C105|GrupoQ Active Motors Sucursal Central|C311|C311-1200');
dados.add('C105|GrupoQ Forland Liberia|C211|C211-1201');
dados.add('C105|GrupoQ Forland Perez Zeledon|C211|C211-1202,C311-1202');
dados.add('C105|GrupoQ Forland San Carlos|C211|C211-1203');
dados.add('C105|GrupoQ Forland Guapiles|C211|C211-1204');
dados.add('C105|GrupoQ Forland La Uruca Sucursal Central|C311|C311-1200');
dados.add('C105|GrupoQ Active Motors SABANA|C211|C211-1212');
dados.add('C105|GrupoQ Vehiculos La Uruca|C311|C311-1220');
dados.add('C105|GrupoQ Active Motors Paseo Las Flores|C211|C211-1524');
dados.add('C105|GrupoQ Terrazas Lindora|C311|C311-1222');
dados.add('C105|GrupoQ Ventas Guapiles|C311|C311-1237');

// helper: codigo SAP escolhido por dealer
// (primeiro almacen quando ha varios: 'C211-1202,C311-1202' -> 'C211-1202')

// ===== INDICES =====
Map<String,Id> accPorNome = new Map<String,Id>();
for (Account a : [SELECT Id, Name FROM Account]) accPorNome.put(a.Name, a.Id);
Id socC101 = accPorNome.get('GrupoQ Costa Rica C101');
Id socC105 = accPorNome.get('GrupoQ Costa Rica C105');
// A-2: aborta cedo se as sociedades nao existem (senao dealers nasceriam orfaos)
if (socC101 == null || socC105 == null) {
    throw new IllegalArgumentException('ABORT: Account de sociedade nao encontrada. C101='+socC101+' C105='+socC105+
        '. Confirme os nomes "GrupoQ Costa Rica C101/C105" antes de rodar.');
}

Map<String,Id> locPorNome = new Map<String,Id>();
for (SObject l : Database.query('SELECT Id, Name FROM Location')) { String nm=(String)l.get('Name'); if(nm!=null) locPorNome.put(nm,(Id)l.get('Id')); }
Set<Id> bpPorAcc = new Set<Id>();
Map<String,Id> bpExtExistente = new Map<String,Id>();
for (BusinessProfile bp : [SELECT AccountId, ExternalReferenceNumber FROM BusinessProfile]) {
    if (bp.AccountId!=null) bpPorAcc.add(bp.AccountId);
    if (bp.ExternalReferenceNumber!=null) bpExtExistente.put(bp.ExternalReferenceNumber, bp.AccountId);
}

// ===== C-1 PRE-FLIGHT: chave SAP =====
Schema.DescribeFieldResult erd = BusinessProfile.ExternalReferenceNumber.getDescribe();
Boolean extUnique = erd.isUnique() || erd.isIdLookup();
System.debug('0. ExternalReferenceNumber isUnique='+erd.isUnique()+' isIdLookup='+erd.isIdLookup());
Map<String,List<String>> codePorDealers = new Map<String,List<String>>();
Set<String> nomesVistos = new Set<String>();
for (String linha : dados) {
    List<String> p = linha.split('\\|');
    String nome=p[1];
    if (nomesVistos.contains(nome)) continue;
    nomesVistos.add(nome);
    String code = USA_CENTRO_ALMACEN ? p[3].split(',')[0] : p[2];
    if (!codePorDealers.containsKey(code)) codePorDealers.put(code, new List<String>());
    codePorDealers.get(code).add(nome);
}
Boolean temColisao = false;
for (String code : codePorDealers.keySet()) {
    List<String> ds = codePorDealers.get(code);
    if (ds.size() > 1) { temColisao = true; System.debug('   COLISAO no batch: '+code+' -> '+ds); }
    if (bpExtExistente.containsKey(code)) { temColisao = true; System.debug('   COLISAO vs BP existente: '+code); }
}
if (temColisao && extUnique) {
    throw new IllegalArgumentException('ABORT: ExternalReferenceNumber e unique/idLookup e ha codigos repetidos '+
        '(ver COLISAO acima). Resolva antes: mescle os dealers, escolha outro almacen, ou reveja o campo.');
}
if (temColisao) System.debug('   (colisoes existem mas o campo NAO e unique - insert prossegue; roteamento nao distingue dealer pelo codigo)');

// ===== 1. ACCOUNTS =====
List<Account> accCriar = new List<Account>();
Set<String> tratados = new Set<String>();
for (String linha : dados) {
    List<String> p = linha.split('\\|');
    String soc=p[0], nome=p[1];
    if (tratados.contains(nome)) continue;
    tratados.add(nome);
    if (!accPorNome.containsKey(nome)) accCriar.add(new Account(Name=nome, ParentId=(soc=='C101'?socC101:socC105)));
}
System.debug('1. Accounts a criar: ' + accCriar.size());
for (Account a : accCriar) System.debug('   + ' + a.Name);
if (!accCriar.isEmpty()) insert accCriar;
for (Account a : accCriar) accPorNome.put(a.Name, a.Id);

// ===== 2. LOCATIONS =====
Set<String> locKeys = new Set<String>();
for (String linha : dados) { List<String> p=linha.split('\\|'); for (String k : p[3].split(',')) locKeys.add(k); }
List<SObject> locCriar = new List<SObject>();
Schema.SObjectType locT = Schema.getGlobalDescribe().get('Location');
if (locT==null) throw new IllegalArgumentException('ABORT: objeto Location indisponivel.');
for (String k : locKeys) if (!locPorNome.containsKey(k)) { SObject l=locT.newSObject(); l.put('Name',k); locCriar.add(l); }
System.debug('2. Locations a criar: ' + locCriar.size());
if (!locCriar.isEmpty()) insert locCriar;
for (SObject l : Database.query('SELECT Id, Name FROM Location')) { String nm=(String)l.get('Name'); if(nm!=null) locPorNome.put(nm,(Id)l.get('Id')); }

// ===== 3. BUSINESSPROFILE (1 por dealer) =====
List<BusinessProfile> bpCriar = new List<BusinessProfile>();
Set<String> bpNomeFeito = new Set<String>();
for (String linha : dados) {
    List<String> p = linha.split('\\|');
    String nome=p[1];
    String code = USA_CENTRO_ALMACEN ? p[3].split(',')[0] : p[2]; // C-1: codigo unico por dealer
    if (bpNomeFeito.contains(nome)) continue;
    bpNomeFeito.add(nome);
    Id accId = accPorNome.get(nome);
    if (accId!=null && !bpPorAcc.contains(accId)) {
        bpCriar.add(new BusinessProfile(AccountId=accId, Name='BP-'+nome, ExternalReferenceNumber=code, BusinessPartnerType='Sales Dealer'));
    }
}
System.debug('3. BusinessProfiles a criar: ' + bpCriar.size());
for (BusinessProfile bp : bpCriar) System.debug('   + '+bp.Name+' extref='+bp.ExternalReferenceNumber);
if (!bpCriar.isEmpty()) insert bpCriar;

// ===== 4. ASSOCIATEDLOCATION (N:N dealer<->almacen) =====
Schema.SObjectType alT = Schema.getGlobalDescribe().get('AssociatedLocation');
if (alT!=null) {
    Map<String,Schema.SObjectField> alF = alT.getDescribe().fields.getMap();
    String cAcc, cLoc;
    for (Schema.SObjectField f : alF.values()) {
        Schema.DescribeFieldResult dd=f.getDescribe();
        if (dd.getType()==Schema.DisplayType.REFERENCE) for (Schema.SObjectType ref : dd.getReferenceTo()) {
            String rn=ref.getDescribe().getName();
            if (rn=='Account'&&cAcc==null) cAcc=dd.getName();
            if (rn=='Location'&&cLoc==null) cLoc=dd.getName();
        }
    }
    System.debug('4. AssociatedLocation campos: Account='+cAcc+' Location='+cLoc);
    if (cAcc!=null && cLoc!=null) {
        Set<String> alExist = new Set<String>();
        for (SObject al : Database.query('SELECT '+cAcc+','+cLoc+' FROM AssociatedLocation')) alExist.add(''+al.get(cAcc)+'|'+al.get(cLoc));
        List<SObject> alCriar = new List<SObject>();
        for (String linha : dados) {
            List<String> p=linha.split('\\|');
            Id accId=accPorNome.get(p[1]);
            for (String k : p[3].split(',')) {
                Id locId=locPorNome.get(k);
                if (accId==null||locId==null) continue;
                String ch=''+accId+'|'+locId;
                if (alExist.contains(ch)) continue;
                alExist.add(ch);
                SObject al=alT.newSObject(); al.put(cAcc,accId); al.put(cLoc,locId); alCriar.add(al);
            }
        }
        System.debug('4. AssociatedLocation a criar: ' + alCriar.size());
        if (!alCriar.isEmpty()) insert alCriar;
    } else {
        System.debug('4. PULADO: nao achei os lookups Account/Location em AssociatedLocation. Confirme via describe.');
    }
} else {
    System.debug('4. PULADO: objeto AssociatedLocation indisponivel.');
}

// ===== 5. IOUs CR: arvore societaria + vinculo Account (acesso dinamico - A-1) =====
Map<String,Schema.SObjectField> iouF = InternalOrganizationUnit.SObjectType.getDescribe().fields.getMap();
Boolean hasCode = iouF.containsKey('organizationcode');
Boolean hasParent = iouF.containsKey('parentorganizationid');
Boolean hasAcc = iouF.containsKey('accountid');
if (!hasCode) {
    System.debug('5. PULADO: InternalOrganizationUnit sem campo OrganizationCode. Rode o describe de IOU e ajuste os nomes.');
} else {
    Map<String,SObject> iouPorCod = new Map<String,SObject>();
    for (SObject i : Database.query('SELECT Id, OrganizationCode'+(hasAcc?', AccountId':'')+(hasParent?', ParentOrganizationId':'')+' FROM InternalOrganizationUnit')) {
        Object oc=i.get('OrganizationCode'); if(oc!=null) iouPorCod.put((String)oc, i);
    }
    List<SObject> iouUpd = new List<SObject>();
    Map<String,String> iouAcc = new Map<String,String>{
        'GQ_HOLDING'=>'GrupoQ Holding','GQ_CR'=>'GrupoQ Costa Rica',
        'C101'=>'GrupoQ Costa Rica C101','C105'=>'GrupoQ Costa Rica C105'};
    if (hasAcc) for (String cod : iouAcc.keySet()) {
        if (iouPorCod.containsKey(cod)) {
            SObject i = iouPorCod.get(cod);
            Id accId = accPorNome.get(iouAcc.get(cod));
            if (accId!=null && (Id)i.get('AccountId')!=accId) { i.put('AccountId',accId); if(!iouUpd.contains(i)) iouUpd.add(i); }
            else if (accId==null) System.debug('   aviso: Account "'+iouAcc.get(cod)+'" nao encontrada (IOU '+cod+' sem vinculo).');
        }
    }
    Map<String,String> iouParent = new Map<String,String>{'GQ_CR'=>'GQ_HOLDING','C101'=>'GQ_CR','C105'=>'GQ_CR'};
    if (hasParent) for (String cod : iouParent.keySet()) {
        if (iouPorCod.containsKey(cod) && iouPorCod.containsKey(iouParent.get(cod))) {
            SObject i = iouPorCod.get(cod);
            Id parentId = (Id)iouPorCod.get(iouParent.get(cod)).get('Id');
            if ((Id)i.get('ParentOrganizationId')!=parentId) { i.put('ParentOrganizationId',parentId); if(!iouUpd.contains(i)) iouUpd.add(i); }
        }
    }
    System.debug('5. IOUs CR a ajustar (Account+Parent): ' + iouUpd.size());
    if (!iouUpd.isEmpty()) update iouUpd;
    System.debug('   (IOUs orfas de outros paises: intocadas, conforme decidido)');
}

System.debug('=== Concluido (ou simulado se DRY RUN) ===');
throw new DmlException('DRY RUN - nada gravado. Confira o log, comente este throw e rode novamente.');
