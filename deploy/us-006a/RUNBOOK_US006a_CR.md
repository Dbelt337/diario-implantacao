# US-006a — Runbook CR (teste, carga de dados, desenho, deploy)
> Data: 2026-07-06 · Escopo: Costa Rica (C101/C105)

## 1. COMO TESTAR (T10 ponta a ponta)

**Pré-requisitos (uma vez):**
- Flow `Account_SensitiveDataChange` **ativo** (V6).
- Grupo `MDG_Default` **com pelo menos 1 usuário** (garante fallback). Idealmente também o grupo do cenário (`MDG_GCCC`, `MDG_G019`...).
- Usuário que **solicita**: `User.Department` preenchido (ver §2). Se vazio/divergente → cai no Default (ainda funciona).
- Conta de teste: `Sociedad__c` = `C101`; `CreditScenario__c` = `SinCredito`/`ContaCorriente`/`CrediQ` (se vazio → Default).

**Fluxo:**
1. Abre a conta → botão **Modificar Datos Sensibles**.
2. Preenche **Nuevo Tipo de Documento** (dropdown lista os tipos), número, nome, e-mail → **Motivo** → **Enviar Solicitud**.
3. **Verifica (staging):** `SensitiveChangeStatus__c = Pending`; `Proposed*` preenchidos; **`Aprobador de Cambios` (SensitiveChangeApprover__c) = um membro do grupo resolvido**.
4. Esse **aprovador** entra → **Approvals / Para Aprobar** → **Aprova**.
5. **Verifica (final):** campos **reais** atualizados (Name/DocType/DocNumber/Email); `status = Completed`; staging limpo; **sem erro**.

**Testes extras:**
- **Rejeição:** aprovador rejeita → `status = Rejected`; campos reais **não** mudam.
- **Cenário crédito:** conta com `CreditScenario__c = ContaCorriente` → roteia pra `MDG_GCCC` **independente do depto**; `CrediQ` → `MDG_CREDIQ`.
- **Fallback:** user sem Department / conta sem Sociedad → roteia pra `MDG_Default`.

## 2. COMO CARREGAR OS DADOS NO OBJETO USER

O roteamento lê **`User.Department`** (Text 80). Ele precisa ter **exatamente** um dos valores da matriz (case-sensitive):

`Autopits`, `CRM`, `Call Center`, `Distribuidor`, `Online`, `PA`, `Pintura`, `Repuestos`, `Taller`, `Trámites`, `Usados`, `Vehículos`, `WEB`, `APP`, `FORMULARIO`

**Como carregar (bulk):**
1. **Salesforce Inspector / Data Loader** — método recomendado:
   - Query: `SELECT Id, Name, Department FROM User WHERE IsActive = true`
   - Preenche a coluna `Department` com o valor do depto de cada usuário.
   - **Update** (upsert por Id).
2. Manual (poucos users): Setup → Users → editar → campo **Department**.

> ⚠️ O valor tem que bater **byte a byte** com a coluna `Departamento__c` da matriz (com acento em `Trámites`). Divergência → cai no `MDG_Default`.

**Grupos (membership) — dado por ambiente:**
- Setup → **Public Groups** → cada `MDG_*` → adiciona **Usuários** (nunca grupo aninhado — o aprovador tem que ser User).

## 3. RESUMO DO DESENHO DA SOLUÇÃO

**Circuito 100% declarativo. Campo sensível só muda depois de aprovado.**

```
Quick Action → screen flow:
  grava PROPOSTA em campos staging (status=Pending)
  → resolve APROVADOR: (User.Department + Account.Sociedad__c + CreditScenario__c)
       → matriz CMT → GRUPO → 1 membro do grupo → SensitiveChangeApprover__c
  → Submit ao Approval Process (Classic) → trava a conta, notifica o aprovador
Aprovador aprova
  → Final Approval seta status=Approved
  → before-save aplica staging → campos REAIS (mesma transação), status=Completed
  → CDC de Account emite SÓ o valor aprovado → MuleSoft → SAP
  → flow legado de crédito é suprimido pela guarda (esCierreGovernanca) no apply
```

**Peças:**
- **Staging fields** + **status** (Account) — recebem a proposta; campos reais intocados até aprovar.
- **screen flow `Account_SensitiveDataChange`** — UI + resolução do aprovador.
- **CMT `Aprobador_Datos_Sensibles__mdt`** — matriz (Sociedad+Depto+Escenario → Grupo) + Default.
- **Public Groups `MDG_*`** — aprovadores por área (R4-clean; membership por ambiente).
- **Approval Process Classic `Aprobacion_Datos_Sensibles_Cuenta`** — aprova via related user field.
- **before-save `Account_ApplySensitiveChanges`** — aplica staging→real na mesma transação do Final Approval (protege o CDC).
- **Workflow field updates** `SDS_Set_Aprobado/Rechazado` — mudam o status na decisão do AP.
- **Guarda Fase 4** no flow legado de crédito — evita colisão de aprovações.

## 4. TUDO QUE VAI NO DEPLOY (promoção p/ outro ambiente)

### 4.1 Metadata (deploy por zip — Flow/CMT-tipo separados do resto)
| Componente |
|---|
| `Account.object`: `SensitiveChangeStatus__c`, `ProposedName__c`, `ProposedDocumentType__c` (não-restrito), `ProposedDocumentNumber__c`, `ProposedElectronicBillingEmail__c`, `SensitiveChangeRequestedBy__c`, `SensitiveChangeReason__c`, `SensitiveChangeRequestedDate__c`, `SensitiveChangeApprover__c` |
| CMT tipo `Aprobador_Datos_Sensibles__mdt` (+ campos Sociedad/Departamento/Escenario_Credito/Grupo_Aprobador/Es_Default) |
| `Group`: `MDG_GCCC`, `MDG_GCCP`, `MDG_CREDIQ`, `MDG_G003`, `MDG_G006`, `MDG_G019`, `MDG_G022`, `MDG_GCL6`, `MDG_GCL7`, `MDG_Default` |
| `customPermissions/CanEditSensitiveAccountFields` |
| `quickActions/Account.Modificar_Datos_Sensibles` |
| `flows/Account_SensitiveDataChange` (ativar após deploy) |
| `flows/Account_ApplySensitiveChanges` (ativar após deploy) |
| `workflows/Account` (SDS_Set_Aprobado, SDS_Set_Rechazado) |
| `approvalProcesses/Account.Aprobacion_Datos_Sensibles_Cuenta` |
| **Layout**: botão `Modificar Datos Sensibles` na página da Account |
> Guarda Fase 4 no `Account_MDM_DadosSensiveis` = pertence à demanda de crédito (R3); promover junto só sob GO.

### 4.2 Dado de config — via **Apex** (CMT-zip dá UNKNOWN_EXCEPTION nesta org)
- `Carga_CMT_Matriz_CR.apex` (75 regras + Default). Rodar por ambiente.

### 4.3 Por ambiente (manual / dado)
- **GroupMember** de cada `MDG_*` (quem aprova).
- **User.Department** (§2).
- **FLS**: campos reais **read-only** p/ asesores; staging **editável**. *(pendente — necessário p/ "bloquear" edição direta)*
- **CDC** habilitado em Account (Setup → Change Data Capture).
- **Quick Action no layout** da Account.
- **"Deploy processes and flows as active" = OFF** nesta org → **ativar os flows manualmente** após cada deploy.
- **Map Lead → Account**: campo Sociedad (p/ `Sociedad__c` nascer preenchido na conversão).

## 5. PENDÊNCIAS (não bloqueiam CR, mas ficam no radar)
- 🔴 **Person Account**: apply grava `Name` (não gravável em conta pessoa) → precisa ramo `IsPersonAccount` (First/Last).
- **FLS** dos campos reais (bloquear edição direta — exigência da spec).
- Limpar staging na rejeição (refinamento).
- Matriz dos outros países (GT/SV/HN/NI) — só somar linhas na CMT.
