# US-006a CR — MANIFESTO FINAL (o que compõe a solução)
> 2026-07-06 · **Este doc supera todos os zips intermediários.** É o estado final no DevSales.
> Para promover (QA/UAT/prod): **retrieve do DevSales** (package.xml abaixo) → deploy → Apex → config.

## 1. METADATA (deploy) — versões FINAIS
| # | Componente | Tipo | Nota |
|---|---|---|---|
| 1 | `Account.SensitiveChangeStatus__c` | CustomField | picklist, valores API **EN** (Pending/Approved/Rejected/Completed) |
| 2 | `Account.ProposedName__c` | CustomField | staging |
| 3 | `Account.ProposedDocumentType__c` | CustomField | staging, **NÃO-restrito** |
| 4 | `Account.ProposedDocumentNumber__c` | CustomField | staging |
| 5 | `Account.ProposedElectronicBillingEmail__c` | CustomField | staging |
| 6 | `Account.SensitiveChangeReason__c` | CustomField | |
| 7 | `Account.SensitiveChangeRequestedBy__c` | CustomField | |
| 8 | `Account.SensitiveChangeRequestedDate__c` | CustomField | |
| 9 | `Account.SensitiveChangeApprover__c` | CustomField | related user (o AP roteia por ele) |
| 10 | `Aprobador_Datos_Sensibles__mdt` (+ campos Sociedad/Departamento/Escenario_Credito/Grupo_Aprobador/Es_Default) | CustomObject (CMT) | estrutura da matriz |
| 11 | **Public Groups (10):** MDG_GCCC, MDG_GCCP, MDG_CREDIQ, MDG_G003, MDG_G006, MDG_G019, MDG_G022, MDG_GCL6, MDG_GCL7, MDG_Default | Group | membros = dado por env |
| 12 | `Account_SensitiveDataChange` | Flow | screen (chama o subflow) |
| 13 | `Account_SensitiveData_Submit` | Flow | **subflow SYSTEM CONTEXT** (grava + submete) |
| 14 | `Account_ApplySensitiveChanges` | Flow | before-save (aplica; ramo Person Account) |
| 15 | `Aprobacion_Datos_Sensibles_Cuenta` | ApprovalProcess | Classic |
| 16 | `Account` (SDS_Set_Aprobado, SDS_Set_Rechazado) | Workflow | field updates |
| 17 | `CanEditSensitiveAccountFields` | CustomPermission | bypass — **não atribuir** |
| 18 | `Account.Modificar_Datos_Sensibles` | QuickAction | botão |
| 19 | `MDG_Datos_Sensibles_Acceso` | PermissionSet | **vendedor = READ** |
| 20 | `MDG_Aprobador_Lectura` | PermissionSet | **aprovador = READ** |
| 21 | Layout da Account | Layout | botão + related list Approval History |

## 2. DADO (via Apex — CMT-zip dá UNKNOWN_EXCEPTION nesta org)
- `Carga_CMT_Matriz_CR.apex` → **75 regras + Default** na CMT. Rodar por ambiente.

## 3. ORDEM DE DEPLOY (num env novo)
1. Campos Account (1–9) + CMT tipo (10) + Groups (11) + Custom Permission (17) + Quick Action (18) + Workflow (16) + Approval Process (15) + Permission Sets (19,20) — **pode ir junto**.
2. **Apex** da matriz (`Carga_CMT_Matriz_CR.apex`).
3. **Subflow** `Account_SensitiveData_Submit` (13) — deploy + **ativar**.
4. **Flows** `Account_SensitiveDataChange` (12) + `Account_ApplySensitiveChanges` (14) — deploy + **ativar** (o screen flow só ativa com o subflow já ativo).
5. Layout (21).

## 4. CONFIG POR AMBIENTE (não vai no metadata)
- [ ] **Ativar os 3 flows** (subflow → screen → apply). Setting "deploy as active" = OFF.
- [ ] **Atribuir PS**: `MDG_Datos_Sensibles_Acceso` aos vendedores · `MDG_Aprobador_Lectura` aos aprovadores.
- [ ] **Membros dos Public Groups** MDG_* (usuários) — mín. `MDG_Default`.
- [ ] **`User.Department`** com os valores da matriz (Autopits, CRM, Call Center, Repuestos...).
- [ ] **Record Types de Account**: atribuir o valor **`Completed`** de `SensitiveChangeStatus__c` a cada RT (Business + Person).
- [ ] **CDC** ligado em Account.
- [ ] **Quick Action + Approval History** no layout.
- [ ] **Map Lead→Account** (Sociedad → `Sociedad__c`).

## 5. DEPENDÊNCIAS PRÉ-EXISTENTES (têm que existir no destino)
`Name`/`FirstName`/`LastName`/`IsPersonAccount` · `DocumentType__c` · `DocumentNumber__c` · `ElectronicBillingEmail__c` · `Sociedad__c` · `CreditScenario__c` · `ApprovalInProgress__c`

## 6. FORA DO US-006a (não subir sem GO)
- Guarda **Fase 4** no `Account_MDM_DadosSensiveis` = demanda de **crédito** (R3).

## 7. ZIPS INTERMEDIÁRIOS = OBSOLETOS
Todos os `Deploy_CR_*`, `Deploy_US006a_*`, `PicklistFix`, `ScreenFix`, `DocTypeFix`, `StagingUnrestrict`, PS v1–v4 → **superados**. Use o **retrieve do estado final** (não os zips soltos).
