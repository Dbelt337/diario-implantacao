# US-006a CR — Resumo Final da Solução (fluxo, quem preenche, o que avaliar)
> Org grupoq--devsales · 2026-07-06 · Escopo: **Costa Rica (C101 / C105)**.
> Este doc consolida o estado final + as decisões abertas para UAT/produção.

---

## 0. Resposta sobre o mapeamento SAP→Account (doc `Integration_data_mapping_Account_SAP_GrupoQ_v2_1`)
| Chave de roteamento | Está no doc SAP? | Origem |
|---|---|---|
| `Sociedad__c` | ✅ **SIM** (R6) | *company code* do SAP → MuleSoft. TextArea 255. Vem na carga inicial + delta. |
| `CreditScenario__c` | ❌ **NÃO** | Integração SAP **não traz**. É o gap principal. |

Campos sensíveis do circuito também vêm do SAP: `DocumentType__c` (R7), `DocumentNumber__c` (R8), `ElectronicBillingEmail__c` (R9), `Name`/Razón Social (R19), `LastName` (R15 Person).

---

## 1. Como ficou a solução (fluxo end-to-end)
1. **Vendedor** abre a conta e clica na Quick Action **"Modificar Datos Sensibles"** (não edita os campos direto — bloqueado por FLS + Validation Rule).
2. **Screen flow** (`Account_SensitiveDataChange`, contexto do usuário) coleta os valores propostos + motivo.
3. Chama o **subflow em contexto de sistema** (`Account_SensitiveData_Submit`, `SystemModeWithoutSharing`) que:
   - grava os `Proposed*` + `SensitiveChangeStatus__c = Pending` + auditoria (`RequestedBy/Date/Reason`);
   - **resolve o aprovador** pela matriz CMT `(Sociedad × Departamento × Escenario)` → Public Group → 1º membro → `SensitiveChangeApprover__c`;
   - **submete a aprovação** como o **Owner da conta** (`skipEntryCriteria=true`).
4. **Approval Process Classic** (`Aprobacion_Datos_Sensibles_Cuenta`) roteia pro `SensitiveChangeApprover__c`.
5. **Aprovado** → workflow seta `Approved` → before-save **`Account_ApplySensitiveChanges`** copia `Proposed*` → campos reais (`Name`/Person, `DocumentType__c`, `DocumentNumber__c`, `ElectronicBillingEmail__c`) e marca `Completed`.
6. **CDC** emite só o valor aprovado → MuleSoft → SAP.
7. **Rejeitado** → workflow seta `Rejected` + task de reversão manual.

**Governança de edição direta:** FLS read-only nos campos custom (PS vendedor) + **Validation Rule `Bloquear_Edicion_Datos_Sensibles`** para o `Name` (standard, sem FLS). A VR **exime** `CanEditSensitiveAccountFields`, `Bypass_Gates_Automacao` e o próprio apply (status→Completed).

---

## 2. Quem preenche cada campo

### A) Criados pelo US-006a — preenchidos pelo PRÓPRIO circuito
| Campo | Quem grava |
|---|---|
| `SensitiveChangeStatus__c` | subflow (Pending) / workflow (Approved/Rejected) / apply (Completed) |
| `ProposedName/DocumentType/DocumentNumber/ElectronicBillingEmail__c` | screen flow → subflow |
| `SensitiveChangeReason__c` / `RequestedBy__c` / `RequestedDate__c` | subflow (auditoria) |
| `SensitiveChangeApprover__c` | subflow (resolvido pela matriz) |

### B) Pré-existentes vindos do SAP (integração MuleSoft) — **preenchidos na carga/delta**
| Campo | Origem SAP | Status |
|---|---|---|
| `Sociedad__c` | company code | ✅ no mapeamento (R6) |
| `DocumentType__c` / `DocumentNumber__c` | tax type / tax number | ✅ (R7/R8) |
| `ElectronicBillingEmail__c` | e-mail facturación | ✅ (R9) |
| `Name` (Business) / `LastName` (Person) | razón social / apellido | ✅ (R19/R15) |
| `Country__c`, `SAPCustomerCode__c`, endereço, moeda | — | ✅ |

### C) Pré-existentes de OUTROS processos (NÃO vêm do SAP)
| Campo | Quem deveria preencher | Status |
|---|---|---|
| **`CreditScenario__c`** | circuito de crédito (`Account_MDM_DadosSensiveis`) | ❌ **não vem do SAP → GAP** |
| **`User.Department`** (do vendedor) | cadastro/admin de usuário | ⚠️ garantir = valores da matriz |

---

## 3. O que AVALIAR / deve estar preenchido antes do UAT/prod

### 🔴 Bloqueadores de roteamento
- [ ] **`CreditScenario__c`** — SAP não traz. Definir a fonte:
  - (a) circuito de crédito preenche pós-carga; ou
  - (b) valor default na carga; ou
  - (c) deixar vazio → **cai no `MDG_Default`** (rede de segurança — funciona, mas sem roteamento específico).
- [ ] **`User.Department`** de cada vendedor = exatamente os valores da matriz (`Repuestos`, `CRM`, `Autopits`, `Call Center`, `PA`, `Taller`, `Pintura`, `Distribuidor`, `Online`, `Trámites`, `Usados`, `Vehículos`, `WEB`, `APP`, `FORMULARIO`).

### 🟠 Integração x Validation Rule (crítico)
- [ ] **Usuário de integração (MuleSoft/SAP) precisa ter a Custom Permission `Bypass_Gates_Automacao`** — senão a VR `Bloquear_Edicion_Datos_Sensibles` **bloqueia o sync SAP→SF** (o SAP escreve Name/Document*/Email, exatamente os campos travados).

### 🟡 Config declarativa (por ambiente)
- [ ] **Ativar os 3 flows** (subflow → screen → apply). Setting "deploy as active" = OFF.
- [ ] **Membros dos Public Groups MDG_*** — em especial `MDG_Default` (fallback) e os de cada escenario (`MDG_GCCC`, `MDG_CREDIQ`, `MDG_G022`…) com aprovadores **reais e ativos**.
- [ ] **Record Types de Account**: valor `Completed` de `SensitiveChangeStatus__c` atribuído a cada RT (Business + Person).
- [ ] **CDC** ligado em Account.
- [ ] **Quick Action + related list Approval History** no layout.
- [ ] **`Name` como Read-Only** no page layout do vendedor (esconde o lápis; backend continua gravando).
- [ ] **Carga da matriz CMT** (`Carga_CMT_Matriz_CR.apex`) — 75 regras + Default por ambiente.

---

## 4. Correções aplicadas nesta rodada (VALIDADAS)
| Problema | Causa | Correção | Status |
|---|---|---|---|
| `"no se ha encontrado ningún proceso aplicable"` | entry criteria reavaliado antes do commit | `skipEntryCriteria=true` no submit | ✅ |
| idem | `allowedSubmitters = owner/creator` e vendedor não era dono | submeter como **`Get_Cuenta.OwnerId`** | ✅ |
| VR travava integrações | VR sem exceção | exime `Bypass_Gates_Automacao` | ✅ |
| Aprovação foi p/ Diego (não Wilmar) | conta sem `CreditScenario__c` → Default; e G022 tinha Diego no submit | comportamento correto (fallback); testar com `SinCredito` + G022=Wilmar | 🔄 re-teste |

**Confirmação E2E:** `ProcessInstance` criado, `Status = Pending`, `ProcessDefinition = Aprobacion_Datos_Sensibles_Cuenta`. ✅

---

## 5. Matriz de roteamento (Repuestos como exemplo)
| Sociedad | Departamento | Escenario | → Grupo |
|---|---|---|---|
| C101/C105 | Repuestos | ContaCorriente | MDG_GCCC |
| C101/C105 | Repuestos | CrediQ | MDG_CREDIQ |
| C101/C105 | Repuestos | SinCredito | **MDG_G022** |
| (sem regra / campos vazios) | — | — | **MDG_Default** (fallback) |
