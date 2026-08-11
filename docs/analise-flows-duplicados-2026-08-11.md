# Análise dos flows "em dobro" — 11/08/2026

Base: `metadata_67.zip` (idêntico ao retrieve salvo em `historico/2026-08-10-metadata_67/`).
O campo `<status>` de cada flow resolve a dúvida: **nenhum par executa em dobro** —
em todos os pares ES/EN, só uma versão está ativa. Mas a análise revelou coisas
mais sérias: **flows que deveriam estar rodando e não estão**.

Legenda de status (Metadata API): `Active` = tem versão ativa e roda;
`Draft` = nunca ativado; `Obsolete` = foi desativado (não roda).

## 1. Pares ES/EN — resolvidos, sem execução dupla

| Versão ATIVA (a que vale) | Versão inativa (status) |
|---------------------------|--------------------------|
| `Lead_BeforeSave_DefaultPreferredContactMethod` | `Lead_BS_DefaultMetodoPreferido` (Obsolete) |
| `Lead_BeforeSave_EnforceMotoRequiredFields` | `Lead_BS_ObligatoriedadMotos` (Obsolete) |
| `Lead_BeforeSave_EnforceStatusTransitions` | `Lead_BS_TransicionEstado` (Obsolete) |
| `Lead_Scheduled_CloseMaxedAttemptLeads` | `Lead_Sched_CierreIntentos` (Obsolete) |
| `Lead_Scheduled_ContactReminder` | `Lead_Sched_RecordatorioContacto` (Obsolete) |
| `Lead_Scheduled_ReassignInactive` | `Lead_Sched_Inactividad` (Obsolete) |
| `Lead_SLA_Escalation` | `Lead_SLA_Task_Escalation` (Draft) |
| `Account_AutolaunchedFlow_ApplyApprovedSensitiveChanges` | `Account_ApplySensitiveChanges`, `Account_SensitiveDataChange` (Obsolete) |
| `Account_AutolaunchedFlow_SubmitSensitiveData_System` | `Account_SensitiveData_Submit` (Obsolete) |
| `OpportunityBeforeHandler` + `Lead_AS_EstampaRTOpp` | `Opp_BS_EstampaRT` (Obsolete) |
| `Opp_RT_Discount_Approval` (usa approval step padrão, que já notifica) | `Opp_AS_NotifyDiscountApprover` (Obsolete) |

Conclusão: o padrão foi renomear os flows de ES para EN (`_BS_` → `_BeforeSave_`,
`_Sched_` → `_Scheduled_`) desativando os antigos. Nada executa duas vezes.

## 2. 🔴 Red flags — flows INATIVOS sem substituto ativo

Estes são o risco real para a demo de quinta (13/08):

| # | Problema | Evidência | Impacto na demo |
|---|----------|-----------|-----------------|
| 1 | **Roteamento Omni-Channel quebrado?** | `Lead_TriggerOmniRouting` está **Active** e chama o subflow `LeadRouting_OmniFlow` — que está **Obsolete** (inativo). Flow ativo chamando subflow inativo = erro em tempo de execução | O passo "roteamento por fila e skill" pode falhar ao vivo. **Testar hoje** |
| 2 | **Governança de duplicados desligada** | `Lead_Dup_Governance` (Obsolete) e `Lead_RecordTriggered_DupGovernance` (Draft) — os dois inativos. Restam só `Lead_AS_CrossFieldDuplicateAlert` e `GQ_Lead_Repuestos_PreMerge` | Somado ao achado das duplicate rules (todas `Allow`, e a GQ rule exclui o usuário de integração): **lead duplicado vindo do portal entra sem alerta nem bloqueio** |
| 3 | **Lead Score desligado** | `Lead_Score_Temperatura` (Obsolete), sem substituto no pacote | Lead Score está no roteiro da demo — ou reativar, ou tirar do roteiro |
| 4 | **Primeira atenção** | `Lead_AT_PrimerContacto` (Obsolete). Existe `Lead_Contact_Attempt_Notify` ativo, mas é outra coisa (platform event `LeadContactAttempt__e` → notificação) | Verificar quem estampa a primeira atenção para o SLA (o `Lead_BS_SetSLADeadline` e `Lead_SLA_Escalation` estão ativos) |
| 5 | **Defaults de Conta nunca ativados** | `Account_RecordTriggeredFlow_Universal_Account_Defaults_CompanyCodeCurrencyCountr` (Draft) | Company code, moeda e país não são preenchidos ao criar conta — aparece na conversão do lead |

## 3. "Aqui tem todos os fluxos, certo?"

**Não dá para garantir.** O `package.xml` desse retrieve lista 54 flows **por
nome** — se algum flow da org não estava na lista, ele não veio. Para ter
certeza, rodar um retrieve com curinga:

```xml
<types>
    <members>*</members>
    <name>Flow</name>
</types>
```

Isso traz todos os flows da org (a versão ativa de cada um, ou a última se não
houver ativa). Em especial, se o Lead Score ou a governança de duplicados foram
**reconstruídos com outro nome**, um retrieve `*` mostraria.

## 4. Limpeza recomendada (pós-demo)

As 15 versões Obsolete/Draft podem ser excluídas da org para o Setup ficar
legível — o histórico fica preservado neste repositório. Prioridade baixa;
não fazer antes de quinta.
