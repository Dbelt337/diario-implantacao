# Revisão — Cadastro_Estrutura_CR_Completo_2_2.apex (NÃO EXECUTADO)

Revisão do script de cadastro da estrutura de Costa Rica contra a planilha-fonte
`Sucursales_QRM_3.xlsx` e os achados da auditoria. O script cria Accounts (dealers),
Locations (almacenes), BusinessProfiles (1/dealer), AssociatedLocations (N:N) e ajusta
as IOUs de CR. Termina com DRY RUN (throw), o que faz rollback de todo o DML — bom.

## CRÍTICO

### C-1 — `BusinessProfile.ExternalReferenceNumber = Centro SAP` (p[2]) colide (linha 77)
O script grava a chave SAP com o **Centro** (p[2] = `C011`, `C211`, `C311`, `C817`), não com
um código único por dealer. No conjunto `dados` isso gera duplicidade massiva:
`C011` ×8 (La Uruca, Liberia, San Carlos, Lindora, Ayarco, Uruca Flotas, Guapiles, Perez
Zeledon), `C311` ×5, `C211` ×6, `C817` ×1.

Impacto conforme a definição do campo (Sec 4.2: `ExternalReferenceNumber` é idLookup, **único
na org**, e é a chave do dealerCode lookup da cascata de Leads):
- Se o campo estiver marcado **unique**: o `insert bpCriar` falha com `DUPLICATE_VALUE`.
- Se não estiver: o roteamento não consegue distinguir dealers pelo código (só a sociedade,
  por acaso, continua coerente porque todos os C011 são C101).

Na planilha, o identificador único por ponto é **Centro+Almacén** (`C011-1200`, `C011-1209`…),
que o script já calcula e usa para Location (p[3]) — mas **não** para a chave do BP.

**Decisão necessária (bloqueante):** qual é o código SAP do dealer para o roteamento?
1. **Centro (compartilhado)** — então `ExternalReferenceNumber` NÃO pode ser unique, e a cascata
   mapeia Centro→Sociedad. Confirmar que o campo não é unique (describe: `isUnique`).
2. **Centro-Almacén (único)** — trocar linha 77 para usar `p[3]` (o código único). Problema:
   dealers com múltiplos almacenes (ex.: `C211-1202,C311-1202`) precisam de regra de qual
   almacén é o principal para a chave.

> Verificar antes de rodar: `BusinessProfile.ExternalReferenceNumber` é unique/idLookup na org?
> (rodar o describe já entregue `describe_businessprofile.apex` e checar o flag).

## ALTO

### A-1 — API names de InternalOrganizationUnit não confirmados (linhas 117, 134-139)
O bloco 5 usa `OrganizationCode` e `ParentOrganizationId`. A auditoria confirmou que IOU tem
`AccountId` (a query de contagem funcionou), mas **não** confirmou esses dois. Se algum nome
estiver errado, o bloco anônimo **nem compila** e nada roda. Confirmar via describe antes:
```apex
for(Schema.SObjectField f:InternalOrganizationUnit.SObjectType.getDescribe().fields.getMap().values()){Schema.DescribeFieldResult d=f.getDescribe();System.debug('IOUF> '+d.getName()+' | '+d.getType()+' | ref='+d.getReferenceTo());}
```

### A-2 — Dependência de nomes exatos de Account (linhas 30-31, 122-124)
`socC101`/`socC105` dependem de `GrupoQ Costa Rica C101`/`C105` (batem com a evidência da
auditoria). Já `GQ_HOLDING`→`GrupoQ Holding` e `GQ_CR`→`GrupoQ Costa Rica` (linhas 123-124)
**não foram confirmados** que existem com esse nome. Se não existirem, `accId=null` e o vínculo
da IOU é silenciosamente pulado (guardado por `accId!=null`) — bloco 5 vira no-op parcial.
Sem null-guard em socC101/socC105 na linha 49: se algum for null, o dealer é criado **órfão**
(ParentId=null), reintroduzindo o achado A-03. Recomendo abortar se socC101/socC105 forem null.

## MÉDIO

### M-1 — `AssociatedLocation`: seleção dinâmica do campo de Account pode pegar o campo errado (linhas 84-97)
A descoberta pega o **primeiro** campo REFERENCE que aponta para Account. Se `AssociatedLocation`
tiver mais de um lookup para Account, pode escolher o errado. O vínculo esperado costuma ser
`ParentRecordId` (Account) + `LocationId` (Location). Confirmar via describe e, de preferência,
fixar os API names em vez de inferir. Verificar também se há campo obrigatório (ex.: `Type`).

### M-2 — `Location` criada só com Name (linha 62)
Alguns orgs exigem `LocationType` (ou outros) para inserir Location. Se o insert falhar, todo o
bloco falha. Confirmar campos obrigatórios de Location via describe.

### M-3 — Cobertura parcial e convenção de nomes divergente da planilha
O `dados` tem 20 linhas curadas; a planilha tem ~110 pontos para CR (o restante são
moto-repuestos/Gollo/Curacao/Tropigas — provavelmente almacenes, não dealers). Os nomes no
script levam prefixo `GrupoQ ` que não existe na planilha. Isso é uma decisão de modelagem
válida, mas registre qual é o critério (o que vira Account+BP vs. o que vira só Location).
`Uruca Usados` usa a chave inventada `C817-NOALM` (almacén vazio na planilha) — ok como placeholder.

## BAIXO
- B-1: `Region` não é setado no BP (o guia oficial pede; não obrigatório, mas relevante p/ picklist).
- B-2: `accPorNome` é chaveado por Name global (last-wins em nomes repetidos). Ok para o subconjunto
  CR, arriscado se estender a países com nomes genéricos repetidos ("Santa Ana", "Online"…).

## Pontos bons (manter)
- Idempotência por check-then-create (Accounts por nome, BP por AccountId, Location por nome, AL por par).
- DRY RUN via throw no fim → rollback de todo o DML.
- Descoberta dinâmica dos campos de AssociatedLocation (evita hardcode frágil) — só precisa de guarda.
- Vincula dealer→sociedade via ParentId (corrige A-03) e cria BP Sales Dealer (corrige A-01) para CR.

## Antes de comentar o throw e rodar de verdade
1. Resolver C-1 (chave SAP: Centro vs Centro-Almacén; confirmar unique).
2. Confirmar API names de IOU (A-1) e AssociatedLocation/Location (M-1, M-2) via describe.
3. Garantir socC101/socC105 não nulos (A-2).
4. Rodar 1x em DRY RUN e conferir os contadores no log antes de remover o throw.
