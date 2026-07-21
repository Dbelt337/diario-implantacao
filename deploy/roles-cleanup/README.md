# Roles cleanup — remoção via destructiveChanges

Remove os roles fora do desenho (Matriz v14): 7× `GQ_Sup_PDV_CR_*` + `GQ_Valuador_CR`.

## Pré-checagem (toda org, antes de deployar)
```sql
SELECT Id, Name, UserRole.DeveloperName FROM User
WHERE UserRole.DeveloperName LIKE 'GQ_Sup_PDV_CR_%' OR UserRole.DeveloperName = 'GQ_Valuador_CR'
```
- **0 usuários** (caso da QA) → pode deployar direto.
- **Com usuários** (checar Prod) → reatribuir ao role correto + preencher
  `User.ManagerId` ANTES (ver `../sharing-lead-opp/RUNBOOK-LIMPEZA-ROLES.md`).
  O deploy destrutivo NÃO reatribui usuários — falha se o role tiver usuários.

## Deploy (Workbench)
1. Zipar `package.xml` + `destructiveChanges.xml` na raiz do zip.
2. Workbench → Migration → **Deploy** → escolher o zip → marcar **Single Package**
   e **Rollback On Error** → (opcional **Check Only** primeiro) → Deploy.

## Deploy (sf CLI)
```
sf project deploy start --manifest package.xml --post-destructive-changes destructiveChanges.xml -o <org>
```

## Cenário real: drift promovido DEV → INT → UAT
Os roles errados estão no **source** e foram promovidos por vários ambientes.
Ordem obrigatória:

### PASSO 1 (crítico) — consertar o SOURCE
Remover os `.role` (`GQ_Sup_PDV_CR_*`, `GQ_Valuador_CR`) do **repositório/branch
que alimenta as promoções**. Se não, a próxima promoção **recria** os roles.
(É o repo do pipeline de deploy, NÃO este diário.)

### PASSO 2 — limpar cada ambiente (destructiveChanges)
Rodar o mesmo `destructiveChanges.xml` em **cada env que já recebeu** — DEV, INT,
UAT (e QA/Prod se aplicável). Em CADA um, antes:
```sql
SELECT Id, Name, UserRole.DeveloperName FROM User
WHERE UserRole.DeveloperName LIKE 'GQ_Sup_PDV_CR_%' OR UserRole.DeveloperName = 'GQ_Valuador_CR'
```
- 0 usuários → deploy direto.
- >0 usuários (⚠️ provável em **UAT** — gente testando) → reatribuir + `User.ManagerId`
  ANTES (o deploy destrutivo falha se o role tiver usuário).

### Ordem sugerida
SOURCE → DEV → INT → UAT → (QA/Prod). Fazer em todos pra não sobrar divergência.

## Notas
- Roles são folha (sem filhos) → deletáveis.
- Não mexe em sharing rules (não são necessárias — hierarquia resolve).
