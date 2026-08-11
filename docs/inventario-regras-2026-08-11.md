# Inventário de Regras — retrieve de 11/08/2026 (`retrieve_09SWK00000RrePZ2AZ.zip`)

Resultado do manifest `retrieve/package-reglas-lead-account-opp.xml`, salvo em
`historico/2026-08-11-rules/`.

## ⚠️ Achado principal: NÃO existem validation rules na org

O retrieve pediu `ValidationRule: *` e **nada voltou** — a org não tem nenhuma
validation rule declarativa (em nenhum objeto). Todas as validações estão
implementadas como **flows before-save**:

- Transição de estados: `Lead_BS_TransicionEstado` / `Lead_BeforeSave_EnforceStatusTransitions`
- Obrigatoriedade Motos: `Lead_BS_ObligatoriedadMotos` / `Lead_BeforeSave_EnforceMotoRequiredFields`

Ponto para a demo: se perguntarem "onde estão as validation rules?", a resposta
é que a estratégia adotada foi validação via flow (mensagem de erro customizada,
lógica condicional por record type). Vale confirmar se isso é decisão de
arquitetura consciente e registrá-la.

## Duplicate rules (10)

Todas com `actionOnInsert = Allow` e `actionOnUpdate = Allow` — ou seja,
**alertam mas não bloqueiam**. O bloqueio/governança efetiva de duplicados no
Lead é feita pelos flows (`Lead_Dup_Governance` / `Lead_RecordTriggered_DupGovernance`,
`Lead_AS_CrossFieldDuplicateAlert`, `GQ_Lead_Repuestos_PreMerge`).

### Lead

| Regra | Ativa | Matching rule | Observação |
|-------|:-----:|---------------|------------|
| `Standard_Lead_Duplicate_Rule` | ✅ | `Lead_Matching_Rule` (Autos/Motos) | Alerta em ES: "Ya existe un registro con información similar…" |
| `GQ_Lead_Repuestos_Duplicate_Rule` | ✅ | `LeadMatchingRuleRepuestoPA` | Filtrada por `Industry = Repuestos, PA`; **exclui usuários com "integration" no username** (a integração não dispara o alerta) |
| `Standard_Lead_to_Contact_Duplicate_Rule` | ❌ | `Standard_Contact_Match_Rule_v1_1` | Standard, desativada |

### Account / Person Account

| Regra | Ativa | Matching rule | Observação |
|-------|:-----:|---------------|------------|
| `Duplicate_Rule_Account` | ✅ | `AccountMatchbyDocumentNumber` | Alerta em ES por número de documento |
| `Standard_Account_Duplicate_Rule` | ✅ | `Standard_Account_Match_Rule_v1_0` | Standard, alerta em EN — ⚠️ avaliar se deve ficar ativa junto com a custom (dois alertas na demo) |
| `Duplicate_PersonAccount_DocumentNumber` | ✅ | `PersonAccountMatchbyDocumentNumber` | Alerta em ES (documento ou e-mail) |
| `Duplicate_Rule_Person_Account` | ❌ | `PersonAccountMatchbyDocumentNumber` | Versão em EN, desativada |
| `Standard_Person_Account_Duplicate_Rule` | ❌ | `Standard_PersonAccount_Match_Rule_v1_0` | Standard, desativada |

### Contact

| Regra | Ativa | Matching rule | Observação |
|-------|:-----:|---------------|------------|
| `Standard_Contact_Duplicate_Rule` | ✅ | `Standard_Contact_Match_Rule_v1_1` | Standard, alerta em EN |
| `Standard_Contact_to_Lead_Duplicate_Rule` | ❌ | `Standard_Lead_Match_Rule_v1_0` | Standard, desativada |

### Opportunity

**Nenhuma** duplicate rule e **nenhuma** matching rule — coerente com o desenho
(a duplicidade é tratada na porta de entrada, no Lead).

## Matching rules customizadas

### Lead (3, todas ativas)

- **`Lead_Matching_Rule`** (Autos/Motos): (Email OU Phone OU MobilePhone OU SecondaryPhone OU SecondaryEmail) E Brand E CompanyCode E Industry — duplicado só dentro da mesma marca/sociedade/linha.
- **`LeadMatchingRuleRepuestoPA`**: contatos (emails/telefones) OU (FirstName E LastName) OU VIN OU Placa, sempre E Industry.
- **`GQ_Lead_Repuestos_Match`** (US-005): Email OU MobilePhone OU VIN OU Placa. Criada para a `GQ_Lead_Repuestos_Duplicate_Rule`, mas a duplicate rule atual referencia `LeadMatchingRuleRepuestoPA` — ⚠️ matching rule ativa e órfã; decidir qual das duas é a oficial.

### Account (1, ativa)

- **`AccountMatchbyDocumentNumber`**: (DocumentNumber E DocumentType E Country) OU Email OU Phone.

## Pendências deste retrieve

1. As matching rules de **PersonAccount** e **Contact** não vieram (o manifest só pedia Account/Lead/Opportunity). Se precisar delas, adicionar `PersonAccount` e `Contact` em `MatchingRules` no próximo retrieve.
2. Alertas standard em inglês (Account e Contact standard rules ativas) destoam das telas em espanhol — ajustar ou desativar antes da demo.
3. Dado que rules são `Allow` (só alertam), leads duplicados vindos da **integração** entram sem bloqueio — confirmar que a governança via flow cobre esse caminho (o filtro da GQ rule exclui explicitamente o usuário de integração).
