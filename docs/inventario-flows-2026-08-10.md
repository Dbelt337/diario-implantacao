# Inventário de Flows — retrieve de 10/08/2026 (`metadata_67.zip`)

54 flows recuperados da org (API 65.0), salvos em `historico/2026-08-10-metadata_67/`.
Organizado pela jornada demonstrável, conforme alinhado para a demo de 13/08.

## 1. Lead — criação (portais via integration procedure + UI) e defaults

| Flow | Papel |
|------|-------|
| `Lead_BS_DefaultMetodoPreferido` / `Lead_BeforeSave_DefaultPreferredContactMethod` | Default do método de contato preferido ⚠️ possível par ES/EN duplicado |
| `Lead_BS_DeriveSociedad` | Deriva a sociedade |
| `Lead_BS_EstampaAsignado` | Estampa o vendedor asignado/preferido |
| `Lead_BS_ObligatoriedadMotos` / `Lead_BeforeSave_EnforceMotoRequiredFields` | Campos obrigatórios para Motos ⚠️ possível par ES/EN duplicado |
| `Lead_BS_SetSLADeadline` | Calcula o prazo de SLA de primeira atenção |

## 2. Roteamento por fila e skill (Omni-Channel)

| Flow | Papel |
|------|-------|
| `Lead_TriggerOmniRouting` | Dispara o roteamento |
| `LeadRouting_OmniFlow` | Omni-Channel Flow (fila + skill) |

## 3. SLA, primeira atenção, recordatórios e escalada

| Flow | Papel |
|------|-------|
| `Lead_AT_PrimerContacto` | Registra a primeira atenção |
| `Lead_SLA_Escalation` / `Lead_SLA_Task_Escalation` | Escalada de SLA |
| `Lead_Sched_RecordatorioContacto` / `Lead_Scheduled_ContactReminder` | Recordatório de contato ⚠️ possível par ES/EN duplicado |
| `Lead_Contact_Attempt_Notify` | Notificação de tentativa de contato |
| `Lead_Sched_CierreIntentos` / `Lead_Scheduled_CloseMaxedAttemptLeads` | Fecha leads com tentativas esgotadas ⚠️ possível par ES/EN duplicado |
| `Lead_Sched_Inactividad` / `Lead_Scheduled_ReassignInactive` | Reatribuição por inatividade ⚠️ possível par ES/EN duplicado |

## 4. Máquina de estados e validações do Lead

| Flow | Papel |
|------|-------|
| `Lead_BS_TransicionEstado` / `Lead_BeforeSave_EnforceStatusTransitions` | Transições de estado permitidas (com motivo de descarte) ⚠️ possível par ES/EN duplicado |

## 5. Duplicidade

| Flow | Papel |
|------|-------|
| `Lead_Dup_Governance` / `Lead_RecordTriggered_DupGovernance` | Governança de duplicados ⚠️ possível par duplicado |
| `Lead_AS_CrossFieldDuplicateAlert` | Alerta de duplicidade cross-field |
| `GQ_Lead_Repuestos_PreMerge` | Pré-merge de leads de Repuestos |

## 6. Lead Score — descontinuado

| Flow | Papel |
|------|-------|
| `Lead_Score_Temperatura` | Score / temperatura do lead — **descontinuado por decisão do time (Obsolete); não faz parte do escopo atual nem da demo** |

## 7. Conversão em Conta + Oportunidade

| Flow | Papel |
|------|-------|
| `Lead_AS_EstampaRTOpp` | Estampa o record type da oportunidade na conversão |
| `Lead_SetStatusOnConversion` | Estado do lead na conversão |
| `GQ_Lead_Repuestos_Reasignacion_y_Cotizacion` | Reasignación e cotización para Repuestos |

## 8. Oportunidade — record type e sales process

| Flow | Papel |
|------|-------|
| `Opp_BS_EstampaRT` | Estampa record type por linha de negócio |
| `OpportunityBeforeHandler` | Handler before-save da oportunidade |

## 9. Avalúo de usados

| Flow | Papel |
|------|-------|
| `AppraisalAfterHandler` | Pós-processamento do avalúo (notificação ao proveedor) |
| `AppraisalItemAfterHandler` | Pós-processamento dos itens do avalúo |

## 10. Test drive e veículos demo

| Flow | Papel |
|------|-------|
| `Generate_Test_Drive_Authorization` | Autorização de test drive em PDF |
| `ExecuteDemoRequest` | Execução de solicitação de demo |
| `ManageDemoVehicle` | Gestão de veículos demo (console) |
| `LogDemoActivity` | Log de atividade de demo |

## 11. Aprovação de desconto

| Flow | Papel |
|------|-------|
| `Opp_AS_EvaluarDescuento` | Avalia o desconto (matriz de decisão) |
| `Opp_RT_Discount_Approval` | Processo de aprovação |
| `Opp_AL_SetDiscountStatus` | Atualiza status do desconto |
| `Opp_AS_NotifyDiscountApprover` | Notifica o aprovador |

## 12. Visitas e hand-off entre sucursais

| Flow | Papel |
|------|-------|
| `Event_AfterSave_ShareBranchHandOff` | Compartilhamento no hand-off entre sucursais |
| `Opportunity_Screen_ReceiveCustomer` | Recepção do cliente na sucursal destino |

## 13. Housekeeping de oportunidades e cotizaciones

| Flow | Papel |
|------|-------|
| `CloseInactiveOpportunities` | Fecha oportunidades inativas |
| `Flag_Expired_Quotes` | Marca cotizaciones vencidas |

## 14. Conta — dados sensíveis (MDM)

| Flow | Papel |
|------|-------|
| `Account_ScreenFlow_ModificationSensitiveData` | Screen flow de solicitação de alteração |
| `Account_SensitiveData_Submit` / `Account_AutolaunchedFlow_SubmitSensitiveData_System` | Submissão da solicitação |
| `Account_SensitiveDataChange` / `Account_ApplySensitiveChanges` / `Account_AutolaunchedFlow_ApplyApprovedSensitiveChanges` | Aplicação das mudanças aprovadas ⚠️ verificar sobreposição |
| `Account_MDM_DadosSensiveis` | Orquestração MDM de dados sensíveis |

## 15. Conta — defaults e contratos

| Flow | Papel |
|------|-------|
| `Account_RecordTriggeredFlow_Universal_Account_Defaults_CompanyCodeCurrencyCountr` | Defaults universais (company code, moeda, país) |
| `Contract_BS_ConsignmentDefaultEndDate` | Data fim default de consignação |
| `Contract_Sched_ConsignmentExpiryAlert` | Alerta de vencimento de consignação |

## Observações

1. **⚠️ Pares ES/EN**: há vários flows que parecem ser a mesma lógica em duas versões (ex.: `Lead_Sched_RecordatorioContacto` × `Lead_Scheduled_ContactReminder`). Se ambos estiverem **ativos**, a lógica pode executar em dobro — vale conferir o status de ativação antes da demo de quinta.
2. **Cliente ocasional**: não há flow de criação de cliente ocasional neste retrieve. Se já existir na org, entrou por outro mecanismo (LWC/Apex/quick action) ou ficou fora do package — incluir no próximo retrieve.
3. **Validation/duplicate rules**: não vêm em retrieve de Flow. Usar `retrieve/package-reglas-lead-account-opp.xml`.
