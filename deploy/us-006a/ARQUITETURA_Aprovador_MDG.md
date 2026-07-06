# US-006a — Arquitetura do Circuito de Dados Sensíveis + Roteamento de Aprovador (MDG)

> Produção-ready, R4-compliant (zero username no metadata), escalável.
> Data: 2026-07-06.

## 1. Princípio de desenho (por que assim)

- **Account NÃO suporta Queue** → aprovador tem que ser **User** (related user field). O AP já usa `SensitiveChangeApprover__c`.
- **R4:** nenhum username/Id viaja no metadata. Logo o CMT aponta pra **Public Group** (API name = igual em todo ambiente); a **membership** é dado de cada org.
- **Separação metadata × dado:**
  - *Metadata (deploya, igual dev/UAT/prod):* estrutura CMT + a **matriz** (Sociedad+Departamento+Escenario → Grupo) + os **Public Groups** (cascas).
  - *Dado por ambiente (não deploya):* **quem está** em cada grupo (GroupMember).

## 2. Fluxo END-TO-END (Business Account, caminho de solicitação)

```
Asesor → Quick Action "Modificar Datos Sensibles"
  │
  ▼  screen flow Account_SensitiveDataChange
  1. Get_Account (valores reais)
  2. ¿solicitud pendiente? ¿bypass? → decisões
  3. Pantalla_Solicitud: preenche novos valores
     (dropdown Tipo Doc lê DocumentType__c real → grava o CÓDIGO 05/06…)
  4. ¿Hay cambios reales? (compara Proposed vs real)
  5. Update_Staging: Proposed* + SensitiveChangeStatus__c = Pending
                     + RequestedBy/Date/Reason
  6. ► RESOLVER APROBADOR (novo, R4-clean):
       a. Get User do solicitante → Department
       b. Get_Account.CreditScenario__c → Escenario (Sin/ContaCorriente/CrediQ)
       c. Get_Regla (CMT): match (Sociedad + Departamento + Escenario)
             → Grupo_Aprobador__c   [fallback: regra Default]
       d. Get_GroupMember: um membro ATIVO do grupo → User
       e. Set SensitiveChangeApprover__c = esse User
  7. Submit_Approval (processDefinitionNameOrId = Aprobacion_Datos_Sensibles_Cuenta)
       → trava a conta + roteia pro aprovador
  8. Pantalla_Confirmacion
  │
  ▼  APROVADOR (email nativo + "Para Aprobar")
  9. Aprova
     └─ AP Final Approval → field update SDS_Set_Aprobado: status = Approved
        └─ before-save Account_ApplySensitiveChanges (MESMA transação):
              status=Approved → aplica Proposed* → campos REAIS
              (Name/DocType/DocNumber/Email), limpa staging, status = Completed
           └─ CDC de Account emite SÓ o valor aprovado → MuleSoft → SAP
           └─ after-save legado Account_MDM_DadosSensiveis:
                guarda esCierreGovernanca (status→Completed) SUPRIME a 2ª
                aprovação de crédito → sem colisão
```

**Caminho de rejeição:** AP Final Rejection → `SDS_Set_Rechazado`: status=Rejected. O apply não roda (entry=Approved). *(Refinamento opcional: limpar staging na rejeição.)*

**Caminho de edição direta** (usuários com `CanEditSensitiveAccountFields` — hoje não atribuída a ninguém): `Update_Directo` grava real + status=Approved → apply → Completed.

**Person Account (GAP a tratar):** `Name` não é gravável em conta pessoa. O apply precisa de um ramo `IsPersonAccount` → gravar `FirstName`/`LastName` em vez de `Name`. **Pendente.**

## 3. Roteamento do aprovador (a matriz)

Entradas → saída:
`(Sociedad, Departamento do solicitante, Escenario de crédito)` → **Grupo aprobador**

- **Escenario 1** (Sin cuenta corriente / sin CrediQ) → grupo da **área origen** (depende do depto)
- **Escenario 2** (Cuenta Corriente) → grupo **Créditos y Cobros** do país (GCCG/GCCS/GCCC…)
- **Escenario 3** (CrediQ) → grupo **CREDIQ**

Fonte do Escenario = `CreditScenario__c` (calculado pelo flow legado de crédito). Acoplamento intencional.

## 4. Manifesto de DEPLOY

### 4.1 Já deployado (base US-006a) ✅
| Componente | Estado |
|---|---|
| `Account.object`: SensitiveChangeStatus__c (picklist EN), ProposedName/DocumentType(não-restrito)/DocumentNumber/ElectronicBillingEmail, SensitiveChangeRequestedBy/Date/Reason, SensitiveChangeApprover__c | ✅ |
| `CanEditSensitiveAccountFields.customPermission` | ✅ |
| `Modificar_Datos_Sensibles.quickAction` | ✅ |
| `Account_ApplySensitiveChanges.flow` (before-save, EN) | ✅ |
| `Account_SensitiveDataChange.flow` (tela + lookup) | ✅ (v atual) |
| `Account.workflow` (SDS_Set_Aprobado/Rechazado, EN) | ✅ |
| `Aprobacion_Datos_Sensibles_Cuenta.approvalProcess` (relatedUserField) | ✅ |
| `Aprobador_Datos_Sensibles__mdt` (tipo CMT) | ✅ |

### 4.2 Novo — Fase B (roteamento por grupo)
| Componente | Tipo | Observação |
|---|---|---|
| `Aprobador_Datos_Sensibles__mdt.Grupo_Aprobador__c` | CustomField (Text) | substitui a lógica de username; guarda o **DeveloperName do Public Group** |
| Public Groups (1 por área): `MDG_GCCC`, `MDG_CREDIQ`, `MDG_G120`, … | Group | **cascas** — membership por ambiente |
| Registros CMT da matriz (gerados do Excel) | CustomMetadata | 1 regra por Sociedad+Depto+Escenario + regra `Default` |
| `Account_SensitiveDataChange.flow` (rework do passo 6) | Flow | keyed lookup → grupo → membro → set aprovador (fallback Default) |
| `Account_ApplySensitiveChanges.flow` (ramo Person Account) | Flow | tratar `Name` em conta pessoa |

### 4.3 Dado por ambiente (NÃO no pacote)
- **GroupMember** de cada `MDG_*` (quem aprova em cada org). Setado em dev/UAT/prod separadamente.

## 5. Ordem de deploy (contorna os erros já vividos)
1. CMT field `Grupo_Aprobador__c` (só o objeto) — deploy isolado.
2. Public Groups.
3. Registros CMT da matriz + regra Default (metadata; **deploy separado do flow** — CMT+flow juntos = UNKNOWN_EXCEPTION).
4. Flow reworked (sozinho; elementos contíguos por tipo).
5. Por ambiente: popular GroupMember dos grupos usados.

## 6. Pendências fora deste bloco (não bloqueiam)
- 🔴 **Person Account** no apply (Name → First/Last).
- **FLS**: campos reais read-only p/ asesores (spec exige "bloquear" edição direta).
- Limpar staging na rejeição (refinamento).

## 7. Confirmações necessárias p/ finalizar a matriz (R5)
1. **Sociedad na conta**: campo `Sociedad__c` guarda o código (`G101`/`S101`/`CRC`)? Ou outro campo?
2. **Departamento do solicitante**: `User.Department` casa com a coluna "Departamento" da tabela? Ou há mapeamento?
> Com Default como fallback, o circuito já funciona mesmo antes do match fino — a matriz completa só refina o roteamento.
