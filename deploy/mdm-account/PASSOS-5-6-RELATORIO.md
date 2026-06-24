# MDM Account — Passos 5 e 6 (relatório, não-construído)

Status: Passos 3-4 **deployados com sucesso** no `grupoq--devsales` em 2026-06-24.
Componentes: `CreditScenario__c`, `ApprovalInProgress__c`, Workflow (2 field updates +
Task), Approval Process `MDM_Conta_Sensivel`, Flow `Account_MDM_DadosSensiveis`,
PS_Data_Steward (Account+Contact Delete), filas `Creditos_y_Cobros`/`CrediQ_Aprobacion`.

---

## Passo 5 — Sharing Rule para o aprovador do cenário 3 (CrediQ) enxergar a Account

### Primeiro, o ponto que muita gente erra: pode nem precisar de sharing rule
Quando um registro é submetido a um Approval Process, o **aprovador designado recebe
acesso de leitura (e edição, conforme o lock) ao registro automaticamente**, enquanto a
aprovação está pendente — é o "approval sharing" nativo. Ou seja, **só para aprovar, o
aprovador já vê o registro** mesmo com OWD Private, sem sharing rule nenhuma.

A sharing rule só é necessária se você quiser visibilidade **mais ampla** que o ato de
aprovar, por exemplo:
- o time CrediQ ver os Accounts de cenário 3 **antes/depois** da aprovação (consulta,
  preparação, auditoria), não só durante o pending;
- o time estar num **ramo de papel diferente** do dono da conta (cross-boundary) e
  precisar de visão contínua.

### Pré-requisito: depende do OWD de Account
- Se **Account OWD = Public Read/Write** (ou Read Only e leitura basta) → **não precisa**
  de sharing rule; todo mundo já lê.
- Se **Account OWD = Private** → aí sim a sharing rule abaixo faz sentido para dar visão
  contínua ao time CrediQ.

> Confirmar o OWD atual:
> `SELECT SobjectType, DefaultAccountAccess FROM Organization` (ou Setup → Sharing Settings).

### Desenho recomendado (criteria-based sharing rule)
- **Objeto:** Account
- **Tipo:** Baseada em critérios (criteria-based)
- **Critério:** `CreditScenario__c EQUALS CrediQ`
- **Compartilhar com:** um **Grupo Público** `CrediQ_Aprobacion` **ou a própria fila**
  `CrediQ_Aprobacion` (filas são Groups e **podem** ser usadas em sharing rules — diferente
  do Approval Process, onde fila não pode ser aprovadora). Reaproveita os membros que você
  já gerencia na fila.
- **Nível de acesso:** **Read Only** (o edit durante a aprovação vem do lock do Approval).

### Por que NÃO entreguei isso construído
1. Depende do **OWD de Account** (se for Public, a regra é inócua/desnecessária).
2. A escolha **grupo vs fila** e a **membresia** são específicas do ambiente.
3. Para os 6 países, há decisão de design: uma regra `CreditScenario__c = CrediQ` pega
   **todos** os países; se cada país tiver um time CrediQ distinto, é preciso **adicionar
   um critério de país** (ex.: um campo `Country__c`/derivado da Sociedade) e **uma regra +
   um grupo por país**. Isso é decisão sua, igual fizemos no roteamento de Lead.

### Esqueleto de metadata (quando você decidir)
```xml
<!-- sharingRules/Account.sharingRules -->
<SharingCriteriaRule>
    <fullName>MDM_CrediQ_Visibilidade</fullName>
    <accessLevel>Read</accessLevel>
    <label>MDM CrediQ Visibilidade</label>
    <sharedTo>
        <group>CrediQ_Aprobacion</group>   <!-- fila/grupo, por DeveloperName -->
    </sharedTo>
    <criteriaItems>
        <field>CreditScenario__c</field>
        <operation>equals</operation>
        <value>CrediQ</value>
    </criteriaItems>
</SharingCriteriaRule>
```

---

## Passo 6 — Ids que mudam por ambiente + checagem de membros chumbados

### Varredura do que construímos (Passos 2-4)

| Referência | Tipo | Estável entre ambientes? |
|---|---|---|
| `Account.CreditScenario__c`, `ApprovalInProgress__c` | API name de campo | ✅ Sim |
| Picklist values `SinCredito`/`ContaCorriente`/`CrediQ` | valor de picklist | ✅ Sim |
| `Manager` (cenário 1) | userHierarchyField padrão | ✅ Sim |
| `MDM_Set_ApprovalInProgress_True/False`, `MDM_Reverter_Dados_Sensiveis` | API name (workflow) | ✅ Sim |
| Filas `Creditos_y_Cobros`/`CrediQ_Aprobacion` | DeveloperName | ✅ Sim |
| `FinancialAccountParty.AccountId/IsRoleActive`, `FinancialAccount.Id` | API name | ✅ Sim |
| **`diego.beltrao@grupoq.com.devsales`** (aprovador cenários 2 e 3) | **username** | ❌ **NÃO** |
| Valores `Status='Active'`, `Type='CrediQ'/'ContaCorriente'` no Flow | **dado da FSC (placeholder)** | ⚠️ a confirmar |

### Conclusão
- **Nenhum Id de registro chumbado** (15/18 chars) em lugar nenhum. O Flow usa `$Record`,
  lookups por DeveloperName e valores de picklist — tudo estável.
- **As filas foram criadas vazias** (sem membro chumbado no metadata). Membresia é
  gerenciada no Setup.
- **O único item específico de ambiente é o username do aprovador** nos steps 2 e 3 do
  Approval Process (`diego.beltrao@grupoq.com.devsales`). É um **placeholder de teste** e
  **precisa ser trocado** ao promover para QA/Prod (lá não tem o sufixo `.devsales` e os
  aprovadores reais serão o time de crédito). Isso é inerente a "quem aprova" — não há como
  ser genérico num Approval Process (aprovador só pode ser User/Queue, e Account não aceita
  Queue).
  - **Mitigação opcional** (à prova de ambiente): trocar o approver por um **campo User-lookup**
    `CreditApprover__c` na Account preenchido pelo Flow (related user field). O metadata do
    Approval passa a referenciar só o campo; "quem" vira dado. Avise se quiser que eu monte.

### 2 placeholders de DADO a confirmar com a FSC (não são Ids)
No Flow `Account_MDM_DadosSensiveis`, decisão **Avalia_FA**:
- CrediQ ativo = `FinancialAccount.Status = 'Active'` **E** `Type = 'CrediQ'`
- Conta corrente = `FinancialAccount.Type = 'ContaCorriente'`

Trocar pelos **valores reais** das picklists de `FinancialAccount` quando a FSC definir.

---

## Como testar agora (importante)

1. **(Opcional) FLS:** dê acesso de leitura aos 2 campos novos no seu perfil/PS para ver
   `CreditScenario__c` na tela.
2. **Cenário 1 (SinCredito → Gerente):** como **ainda não há dado de FinancialAccount no
   org**, **toda** conta classifica como SinCredito → vai pro **gerente do submitter**.
   ⚠️ Se o usuário dono **não tiver Manager** preenchido no User, a submissão **falha**
   ("no approver"). Garanta um Manager no User de teste, ou teste cenário 2/3.
3. **Cenário 2/3 (você como aprovador):** crie um `FinancialAccount` + um
   `FinancialAccountParty` (AccountId = conta de teste, IsRoleActive = true) com
   `Type='CrediQ'`/`Status='Active'` (ou `Type='ContaCorriente'`). Depois edite um campo
   sensível na conta (B2B: Phone/Billing*; B2C: PersonEmail/PersonMobilePhone/etc.) e salve.
   → Flow classifica → submete → **cai pra você aprovar**. Registro fica travado até
   aprovar/rejeitar.
4. **Rejeição:** ao rejeitar, o registro destrava, a flag limpa e é criada a **Task de
   reversão manual** pro dono.
