# Cadastro estrutura Costa Rica — runbook

Scripts que criam a estrutura organizacional de CR num ambiente novo (Automotive Cloud).
Todos são **idempotentes** (check-then-create) e terminam em **DRY RUN** (um `throw` no fim faz
rollback de todo o DML). Para gravar de verdade: rode em dry run, confira o log, **comente a
última linha** (o `throw`) e rode de novo.

Se der **HTTP 431** ao colar no Developer Console (script grande), rode pela CLI:
`sf apex run -o grupoq--devsales -f <arquivo>`

## Ordem de execução
1. **`CR_parte1_core.apex`** — cria a hierarquia de Account do zero:
   Holding (`GrupoQ Holding`) → País (`GrupoQ Costa Rica`) → Sociedades
   (`GrupoQ Costa Rica C101`, `... C105`) → 20 dealers curados → BusinessProfiles.
2. **`CR_parte1b_iou.apex`** — cria/atualiza as IOUs `GQ_HOLDING → GQ_CR → C101/C105`,
   vinculando `AccountId` e o parent. Rodar **após** gravar a parte1.
3. **`CR_parte2_almacenes.apex`** — cria `Location` (almacenes) e `AssociatedLocation`
   (N:N dealer↔almacén). Rodar após a parte1.

Versão única (tudo junto, ~16KB, só via CLI): `Cadastro_Estrutura_CR_corrigido.apex`.
Versão única minificada (~7.5KB): `Cadastro_Estrutura_CR_min.apex`.

## Formato dos dados (variável `D`)
`Sociedad|NomeDealer|CodigoSAP` — ex.: `C101|GrupoQ La Uruca|C011-1200`.
O `CodigoSAP` (Centro-Almacén) vira `BusinessProfile.ExternalReferenceNumber`.

## Decisões e regras do modelo (aprendidas na implantação)
- **`BusinessProfile.ExternalReferenceNumber` é Unique** (Text 255, case-insensitive).
  Por isso o script cria **1 BP por código**. Dealers que compartilham o mesmo código
  (ex.: `La Uruca` e `Uruca Flotas` = `C011-1200`; os dois "Sucursal Central" = `C311-1200`)
  aparecem como `BPskip-BranchUnit` — são candidatos a **Branch Unit** (mesma concessionária,
  linhas de negócio distintas). Ver `A-07_branch_management.md`.
- **`BusinessProfile.Name` é auto-number** (BP-00000009…): não setar no insert.
- **`Account.Country__c` é picklist obrigatória**: o script descobre o valor de Costa Rica
  dinamicamente e aplica em todos os Accounts. Ele também loga `REQ Account:` com todos os
  campos obrigatórios do Account — se aparecer outro além de Country__c, adicione ao insert.
- **IOU**: `OrganizationCode` (Text 40), `OrganizationName` (Text 80), `AccountId` (Lookup),
  `ParentOrganizationId` (Hierarchy, detectado dinamicamente). Não tem ExternalReferenceNumber.
- **Nomes de conta**: convenção `GrupoQ ...` (o script tolera `Grupo Q ...` na resolução).

## Armadilhas de Apex anônimo (já corrigidas nestes scripts)
- Nome de variável `iF`/`iF`... — Apex trata keywords como case-insensitive; `iF` = `if`. Evite.
- `InternalOrganizationUnit.SObjectType` como token não resolve nesta org — use
  `Schema.getGlobalDescribe().get('InternalOrganizationUnit')`.
- Developer Console manda o corpo na URL → scripts grandes dão 431. Minifique ou use `sf apex run -f`.

## Como estender para outra sociedade / país (depois)
1. Ajuste a lista `D` com os dealers da nova sociedade (`Sociedad|Nome|CodigoSAP`).
2. Ajuste os nomes/códigos da hierarquia (Holding/País/Sociedade) e o valor de `Country__c`
   (o script já detecta por país; troque o alvo de busca se não for Costa Rica).
3. Em `CR_parte1b_iou.apex`, ajuste os mapas `ord`/`nmm`/`iac`/`ipar` para os novos códigos IOU.
4. Rode sempre em DRY RUN primeiro.

## Pendências conhecidas (para configurar depois)
- **Branch Units** dos dealers que compartilham código (Ventas/Repuestos/Flotas por concessionária).
- **Record Type de Account "Concesionaria"** (discriminador de nível) — ver `A-07_branch_management.md`.
- **Campos `User.SucursalBP__c` e `Account.BrandName__c`** (metadados em `metadata/`).
- Reconciliação de sociedades GVS×CMT (`A-05_reconciliacao_sociedades.md`).
