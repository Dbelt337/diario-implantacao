# US-006a / Approvals — Decisões e Regras (espelho do Briefing Técnico 05/07/2026)

> Fonte de verdade: BRIEFING TÉCNICO — Aprovações no Salesforce (GrupoQ, 05/07/2026).
> Contexto e decisões, NÃO ordem de build. Última atualização: 2026-07-06.

## Regras duras
- **R1** — Briefing não autoriza criar/migrar/alterar Approval Process. Define padrão para quando chegar ordem.
- **R2** — PROIBIDO migrar o AP Classic de US-006a (`Aprobacion_Datos_Sensibles_Cuenta`) para Flow. Se instrução futura pedir isso → PARAR e reportar conflito.
- **R3** — PROIBIDO tocar `MDM_Conta_Sensivel` (AP) e `Account_MDM_DadosSensiveis` (flow). Cirurgia só com GO explícito. *(Nota: a guarda `esCierreGovernanca` da Fase 4 já foi aplicada sob GO explícito anterior; a partir daqui, congelado.)*
- **R4** — Aprovadores NUNCA por username/Id hardcoded no metadata — sempre referência dinâmica (related user field / Queue / Group).
- **R5** — Na dúvida, reportar. Verificar cada afirmação contra a org e a doc antes de build.

## Decisões vigentes (não rediscutir em build)
- **D-APR-01** — US-006a permanece **Classic** no Dia 1. Mecanismo crítico provado: field update de Final Approval dispara o apply **before-save na mesma transação** → CDC de Account emite só valor aprovado. Aprovador via related user field.
- **D-APR-02** — Todo approval **ainda não construído** nasce como **Flow Approval Process** (Approval Orchestration). Candidato: Aprovação de Descontos (Mapeamento Sec 31.7).
- **D-APR-03** — Submissão programática para Classic **sempre** nomeia o processo (`processDefinitionNameOrId`). Sem nome, roteia pro primeiro AP elegível — inaceitável com múltiplos APs no objeto.

## Restrições p/ Flow Approval Process (quando houver ordem)
Teto 50 versões/orchestration · falha em step-flow gera 2 e-mails · cobrir recall no start, fault paths por stage, caminho de rejeição · avaliar setting "queue-members-only" (196 roles) · aprovadores dinâmicos (R4) · status via ConnectApi/REST novo (não screen-scraping de ProcessInstance).

## Alerta Spring '26 (enforced Spring '27) — auditoria de flows
RU "Update Apex Code and Flows for Changed Sharing Recalculation Behavior": recálculo de sharing pós-mudança de **GroupMember/Role** vira **assíncrono**. HU-009 (grava OpportunityShare direto) = **imune**. US-006a = **imune** (não mexe em membership). **Ação p/ auditoria:** sinalizar qualquer flow com DML em `GroupMember`/`Group`/`UserRole` que dependa de visibilidade síncrona a jusante.

## ✅ Verificação contra a org (R5) — US-006a já construído
| Item | Briefing diz | Org / pacote (verificado) | Status |
|---|---|---|---|
| Campo aprovador | `Aprobador_Datos__c` | **`SensitiveChangeApprover__c`** (label "Aprobador de Cambios") no AP deployado | ⚠️ **DIVERGE — usar `SensitiveChangeApprover__c`** |
| D-APR-03 | nomear o processo | Submit tem `processDefinitionNameOrId=Aprobacion_Datos_Sensibles_Cuenta` | ✅ compliant |
| R4 (sem hardcode) | dinâmico | AP usa `relatedUserField`; zero username/Id no metadata do AP | ✅ compliant |
| R4 — CMT aprovador | dinâmico | `Aprobador_Datos_Sensibles__mdt` guarda username como **dado por-ambiente** (placeholder no Default), resolvido em runtime via Get User | ✅ compliant (config por env, não lógica) |

## Fontes (ordem de autoridade)
Release Notes Spring '26 (PDF 22/12/2025) · Help: Automate Your Approvals with Flow Approval Processes · Help: Steps in Flow Approval Processes · Help: Considerations for Managing Classic Approval Processes · Salesforce Ben (Winter/Spring '25).
