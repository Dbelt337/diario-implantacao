# US-006a — Checklist de Go-Live (Costa Rica) + Resumo da Solução
> Data: 2026-07-06 · Escopo: CR (C101/C105)

## RESUMO — como funciona (em 6 passos)
1. Usuário abre a Account → botão **Modificar Datos Sensibles**.
2. O **screen flow** grava a proposta em **campos staging** e põe `status = Pending` (os campos **reais não mudam**).
3. O flow **resolve o aprovador**: lê `User.Department` (solicitante) + `Sociedad__c` + `CreditScenario__c` (conta) → busca na **matriz (CMT)** → acha o **Public Group** → pega **um membro** → grava em `SensitiveChangeApprover__c`.
4. **Submete ao Approval Process (Classic)** → trava a conta e **notifica o aprovador** (email nativo).
5. Aprovador **aprova** → o Approval seta `status = Approved` → o **before-save `Apply`** copia staging → **campos reais** na **mesma transação**, e põe `status = Completed`.
6. O **CDC** da Account emite **só o valor aprovado** → MuleSoft → SAP. A **guarda da Fase 4** impede o flow legado de crédito de colidir.
> Rejeição → `status = Rejected`, reais intocados. Governança total: sem aprovação, o dado sensível **não muda**.

---

## A) SUBIR (metadata — deploy por zip)
> Flow e CMT-tipo em deploys **separados** do resto (senão UNKNOWN_EXCEPTION).

- [ ] **Campos Account** (staging + status): `SensitiveChangeStatus__c`, `ProposedName__c`, `ProposedDocumentType__c` (não-restrito), `ProposedDocumentNumber__c`, `ProposedElectronicBillingEmail__c`, `SensitiveChangeRequestedBy__c`, `SensitiveChangeReason__c`, `SensitiveChangeRequestedDate__c`, `SensitiveChangeApprover__c`
- [ ] **CMT tipo** `Aprobador_Datos_Sensibles__mdt` (+ campos Sociedad/Departamento/Escenario_Credito/Grupo_Aprobador/Es_Default)
- [ ] **Public Groups** (10): `MDG_GCCC`, `MDG_GCCP`, `MDG_CREDIQ`, `MDG_G003`, `MDG_G006`, `MDG_G019`, `MDG_G022`, `MDG_GCL6`, `MDG_GCL7`, `MDG_Default`
- [ ] **Custom Permission** `CanEditSensitiveAccountFields`
- [ ] **Quick Action** `Account.Modificar_Datos_Sensibles`
- [ ] **Flow** `Account_SensitiveDataChange`
- [ ] **Flow** `Account_ApplySensitiveChanges`
- [ ] **Workflow** `Account` → field updates `SDS_Set_Aprobado`, `SDS_Set_Rechazado`
- [ ] **Approval Process** `Aprobacion_Datos_Sensibles_Cuenta`
- [ ] **Permission Set** `MDG_Datos_Sensibles_Acceso` (FLS leitura CreditScenario/Sociedad)
> Dependências pré-existentes (não são nossas, mas têm que existir): `DocumentType__c`, `DocumentNumber__c`, `ElectronicBillingEmail__c`, `Sociedad__c`, `CreditScenario__c`, `ApprovalInProgress__c`.
> Guarda **Fase 4** no flow legado `Account_MDM_DadosSensiveis` = demanda de crédito (R3) → promover só sob GO explícito.

## B) CARREGAR DADO (via Apex — CMT-zip dá UNKNOWN_EXCEPTION nesta org)
- [ ] Rodar `Carga_CMT_Matriz_CR.apex` → cria **75 regras + Default** na matriz. (repetir por ambiente)

## C) HABILITAR / CONFIGURAR (por ambiente)
- [ ] **Ativar os 2 flows** manualmente (setting "Deploy flows as active" = OFF nesta org)
- [ ] **Atribuir** a Permission Set `MDG_Datos_Sensibles_Acceso` aos **usuários do flow**
- [ ] **Membros dos Public Groups**: adicionar **usuários** (nunca grupo aninhado) em cada `MDG_*` que for usar — no mínimo `MDG_Default`
- [ ] **`User.Department`**: preencher com os valores da matriz (`Autopits`, `CRM`, `Call Center`, `Distribuidor`, `Online`, `PA`, `Pintura`, `Repuestos`, `Taller`, `Trámites`, `Usados`, `Vehículos`, `WEB`, `APP`, `FORMULARIO`) — via Data Loader/Inspector
- [ ] **CDC** habilitado em Account (Setup → Change Data Capture → Account)
- [ ] **Quick Action no layout** da Account (arrastar o botão pro Highlights Panel / Mobile & Lightning Actions)
- [ ] **Map Lead → Account** do campo Sociedad (pra `Sociedad__c` nascer preenchido na conversão)
- [ ] **FLS**: campos **reais** (`Name`/`DocumentType__c`/`DocumentNumber__c`/`ElectronicBillingEmail__c`) **read-only** pros asesores; **staging editável**. *(bloqueia edição direta — exigência da spec)*

## D) TESTE (T10)
- [ ] Submeter (staging + Pending + aprovador resolvido)
- [ ] Aprovar (reais aplicados + Completed + staging limpo)
- [ ] Rejeitar (Rejected + reais intocados)
- [ ] Cenário crédito (ContaCorriente→GCCC, CrediQ→CREDIQ, independe do depto)
- [ ] Fallback (sem depto/sociedad → MDG_Default)

## E) PENDÊNCIAS (não bloqueiam CR)
- [ ] 🔴 **Person Account**: apply grava `Name` (não gravável em conta pessoa) → ramo `IsPersonAccount` (First/Last)
- [ ] **FLS** dos reais read-only (item C, exigência da spec)
- [ ] Limpar staging na rejeição (refinamento)
- [ ] Matriz outros países (GT/SV/HN/NI) — somar linhas na CMT
