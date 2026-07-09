// DRY RUN. Valida a logica do "filho" do OmniScript GrupoQ/CriarCotacao SEM Vlocity/CPQ:
// identifica o registro de contexto (Account=001 ou Opportunity=006) e cria um Quote NATIVO.
// Rode em dry run, confira o log, comente o ultimo throw e rode de novo p/ gravar.
// Este e o mesmo passo que a Integration Procedure filha (ou um DataRaptor Post) vai fazer.

String RECID = '';                    // <-- cole o Id de contexto (Opportunity 006... ou Account 001...)
Boolean CREATE_OPP_IF_MISSING = true; // contexto Account sem Opp aberta -> cria uma Opp minima

if(String.isBlank(RECID)) throw new DmlException('Preencha RECID com o Id de contexto (Account ou Opportunity).');
Schema.SObjectType st = Id.valueOf(RECID).getSObjectType();
String obj = st.getDescribe().getName();
System.debug('CTX> tipo='+obj+' id='+RECID);

Id oppId, accId, pbId;
if(obj=='Opportunity'){
  Opportunity o=[SELECT Id,AccountId,Pricebook2Id,Name FROM Opportunity WHERE Id=:RECID];
  oppId=o.Id; accId=o.AccountId; pbId=o.Pricebook2Id;
} else if(obj=='Account'){
  accId=Id.valueOf(RECID);
  List<Opportunity> ops=[SELECT Id,Pricebook2Id FROM Opportunity
                         WHERE AccountId=:accId AND IsClosed=false ORDER BY CreatedDate DESC LIMIT 1];
  if(!ops.isEmpty()){ oppId=ops[0].Id; pbId=ops[0].Pricebook2Id; System.debug('CTX> usando Opp aberta '+oppId); }
  else if(CREATE_OPP_IF_MISSING){
    Opportunity no=new Opportunity(Name='Cotacao '+Date.today().format(),
        AccountId=accId, StageName='Prospecting', CloseDate=Date.today().addDays(30));
    insert no; oppId=no.Id; System.debug('CTX> Opp minima criada '+oppId);
  } else throw new DmlException('Account sem Opportunity aberta e CREATE_OPP_IF_MISSING=false.');
} else throw new DmlException('Contexto nao suportado: '+obj+' (esperado Account ou Opportunity).');

if(pbId==null){ // Quote com linhas exige Pricebook2Id; usa o Standard ativo se a Opp nao tiver
  List<Pricebook2> sp=[SELECT Id FROM Pricebook2 WHERE IsStandard=true AND IsActive=true LIMIT 1];
  if(!sp.isEmpty()) pbId=sp[0].Id;
}

Quote q=new Quote(Name='Cotacao '+Date.today().format(), OpportunityId=oppId,
                  Status='Draft', ExpirationDate=Date.today().addDays(30));
if(pbId!=null) q.Pricebook2Id=pbId;   // AccountId do Quote e derivado da Opportunity automaticamente
insert q;
System.debug('OK> Quote criada Id='+q.Id+' | Opp='+oppId+' | Account='+accId);

System.debug('=== FIM (DRY RUN) ===');
throw new DmlException('DRY RUN - comente esta linha p/ gravar.');
