# US-005 — Deploy ÚNICO (`us005-single.zip`)

## A regra da plataforma (pesquisada, não é escolha)
Uma **Matching Rule nova NÃO pode ser deployada já ativa** — entra inativa e é ativada depois; e a **Duplicate Rule exige a Matching Rule ativa**.
Fontes: [Copado](https://docs.copado.com/articles/copado-ci-cd-publication/matching-rule-deployment-returns-error-change-the-matching-rule-status-separately-from-other-changes) · [SF KB 000383122](https://help.salesforce.com/s/articleView?id=000383122&type=1) · [forcedotcom/cli #569](https://github.com/forcedotcom/cli/issues/569).

Logo, um deploy único com a Matching Rule **ativa** é impossível. **A solução é deployar TUDO de uma vez com as regras INATIVAS e ativá-las no Setup (2 cliques — não é deploy).**

## Como fazer (1 deploy + 2 cliques)
1. **Workbench → Migration → Deploy → `us005-single.zip`** (Rollback on Error + Single Package). Sobe **tudo**: campos (LeadLineItem + Lead), CMT + registro, PS de FLS, os 2 Flows, **Matching Rule inativa** e **Duplicate Rule inativa**.
2. **Setup → Matching Rules → "GQ Lead Repuestos Match" → Activate.**
3. **Setup → Duplicate Rules → "GQ Lead Repuestos Dup" → Activate.**

Pronto. Os passos 2 e 3 são toggles instantâneos no Setup (síncronos), não deploys — então o seu processo de deploy continua sendo **um único deploy**.

## Conteúdo do pacote (1 package.xml)
`CustomField` (LicensePlate__c + 3 do Lead + 3 do CMT) · `CustomObject` (GQ_Dedup_Repuestos_Config__mdt) · `PermissionSet` (GQ_Lead_Repuestos_FLS) · `MatchingRule` (Lead.GQ_Lead_Repuestos_Match, **Inactive**) · `DuplicateRule` (Lead.GQ_Lead_Repuestos_Dup, **isActive=false**) · `CustomMetadata` (Default) · `Flow` (Reasignacion_y_Cotizacion + PreMerge).

## Se o deploy reclamar da Duplicate Rule (plano B)
Caso a org rejeite a Duplicate Rule inativa referenciando uma Matching Rule ainda inativa (raro, mas possível):
1. Remova a pasta `duplicateRules/` do zip e o bloco `DuplicateRule` do `package.xml` → re-deploye (continua **um** deploy do metadado).
2. Crie a Duplicate Rule **no Setup** (point-and-click): Setup → Duplicate Rules → New → objeto Lead → Matching Rule = GQ Lead Repuestos Match → **Alert + Allow** → Activate.

A diferença é só se a Duplicate Rule vem como metadado ou como config de tela — em ambos os casos **é um único deploy**.

## Observação
As 5 flags de confirmação (vínculo a veículo via Task, API names nativos, FLS via PS, D-005-A/B/C, timing do LeadLineItem) continuam valendo — ver `README.md`. Idealmente, confirme as D-005 com a Melisa antes, já que os Flows entram neste mesmo pacote.
