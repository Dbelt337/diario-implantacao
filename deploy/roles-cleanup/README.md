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

## Ordem de promoção
QA (agora, sem usuários) → Prod (após reatribuir usuários, se houver) → demais orgs.

## Evitar recorrência
Se estes roles existirem como `.role` no repositório de metadata, **remover de lá**
também — senão um deploy futuro os recria (foi a origem do drift).

## Notas
- Roles são folha (sem filhos) → deletáveis.
- Não mexe em sharing rules (não são necessárias — hierarquia resolve).
