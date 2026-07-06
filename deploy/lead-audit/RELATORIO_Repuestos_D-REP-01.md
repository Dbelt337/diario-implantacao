# Análise Read-Only — Ecossistema Repuestos (D-REP-01)
> Org grupoq--devsales · 2026-07-06 · **READ-ONLY (R1)**: nada deployado/editado/executado.
> Insumo: retrieve `metadata_29` (2 flows ativos). Fases 1.1–1.4 (inventário via Tooling/SOQL/Settings) **não executáveis neste ambiente** — queries prontas na seção 1; rodar na org e anexar (R5).

## 1. INVENTÁRIO (1.1–1.4) — queries a rodar na org (não tenho acesso)
> Estas 4 não pude executar (sem conexão à org). Rode e cole o resultado; sigo a análise. Não inventei nomes (R5).
- **1.1 Flows:** a query `FlowDefinitionView WHERE DeveloperName LIKE '%Repuest%'...` — o retrieve trouxe **2 ativos**: `GQ_Lead_Repuestos_Reasignacion_y_Cotizacion` e `GQ_Lead_Repuestos_PreMerge`. Confirmar se há outros (SparePart/Pieza) e a **autoria** (Q12, que o .flow não traz).
- **1.2 OmniStudio:** `OmniProcess/OmniDataTransform/OmniUiCard WHERE Name LIKE '%Repuest%'` — **pendente** (é onde pode estar a criação de Quote).
- **1.3 Record Types:** `RecordType WHERE SobjectType IN ('Quote','Order','Opportunity')` + QuickAction `%Cotiz%/%Repuest%` — **pendente**.
- **1.4 QuoteSettings:** retrieve `Settings/Quote` — **pendente** (toggle "Quote sem Opportunity"). Colar o XML integral.

## 2. LEITURA PROFUNDA (Q1–Q12)

### FLOW A — `GQ_Lead_Repuestos_Reasignacion_y_Cotizacion` (ATIVO, apiVersion 60, triggerOrder 20)

- **Q1 ENTRADA:** `<start>` object=**Lead**, `recordTriggerType=Create`, `triggerType=RecordAfterSave`, **sem `<filters>` de entrada** (dispara em TODO Lead criado; a segmentação "Repuestos" vem depois na decisão `Es_Repuestos`). Sem `doesRequireRecordChangedToMeetCriteria` (é Create). **Todo o corpo roda em `<scheduledPaths><pathType>AsyncAfterCommit</pathType>` → `Get_LineItem_New`.**
- **Q2 OPPORTUNITY (pergunta central):** **NÃO.** Zero `recordCreates`/`recordUpdates` com `object=Opportunity`; zero actionCall de `LeadConvert`/`convertLead`. Evidência: os únicos `recordCreates` são `Log_Asset`/`Log_Falha`/`Log_Vehiculo`, todos `<object>Task</object>`; os `recordUpdates` são `Asignar_Cola` e `Marcar_Candidato`, ambos `<inputReference>$Record</inputReference>` (Lead). **Binário: não cria Opportunity, não converte Lead.**
- **Q3 QUOTE:** **NÃO.** Zero `recordCreates` com `object=Quote`. Nenhum RecordTypeId de Quote, nenhum AccountId/OpportunityId. O nome "Cotizacion" é **enganoso** — as Tasks `Log_Asset`/`Log_Vehiculo` só **descrevem** ("Cotizacion vinculada a Asset/Vehicle por VIN") mas **nenhum objeto Quote é criado**. → **A criação de Quote NÃO está neste flow** (candidata: OmniStudio — ver 1.2).
- **Q4 ACCOUNT:** **Não toca Account.** Lookups: `Get_Lead_Anterior` (Lead por Email/MobilePhone), `Get_Asset` (Asset por SerialNumber=VIN), `Get_Vehicle` (Vehicle por VIN), `Get_LineItem_New/Prev` (LeadLineItem), `Get_Cola_Pais` (Group/Queue). **Nenhum lookup/criação de Account.** Cliente Person/Business: N/A.
- **Q5 PRICING:** **N/A.** Sem `Pricebook2Id`, sem `QuoteLineItems`, sem mapeamento LeadLineItem→Quote (não há Quote).
- **Q6 REASIGNACIÓN:** **SIM.** `Asignar_Cola` → `$Record.OwnerId = Get_Cola_Pais.Id`. A fila é resolvida pela fórmula `queueDevName = "Queue_Vendedores_" & CASE(LEFT(TEXT($Record.CompanyCode__c),1), "C","CR","G","GT","H","HN","N","NI","P","PA","S","SV","")` → lookup `Group` por `DeveloperName` + `Type='Queue'`. **Owner → QUEUE, resolvida por SOCIEDADE/país** (1ª letra do CompanyCode__c). Não é User, não é skills, não é Id hardcoded.
- **Q7 ASSÍNCRONO:** **O flow INTEIRO é async** — o único caminho do `<start>` é `scheduledPaths` `AsyncAfterCommit`. Todos os elementos (Get_LineItem_New → Tiene_LineItem → Es_Repuestos → Sin_Brand → Get_Cola_Pais → Cola_Encontrada → Asignar_Cola → Tiene_VIN → Get_Vehicle/Get_Asset → Log_* → Get_Lead_Anterior → Tem_Anterior → Get_LineItem_Prev → Avalia_Unificacion → Marcar_Candidato) rodam em **transação separada** (pós-commit). **Consumo SÍNCRONO na inserção do Lead = 0.**
- **Q8 FAULT PATHS:** **Parcial.** `Get_LineItem_New/Prev`, `Get_Lead_Anterior`, `Marcar_Candidato` → fault vai pra `Log_Falha` (Task "…lead mantido"). **PORÉM** `Get_Asset`, `Get_Vehicle`, `Get_Cola_Pais`, `Asignar_Cola` → fault vai pro **próximo elemento sem log** (ex.: `Asignar_Cola` fault → `Tiene_VIN`). → **falha de reatribuição é engolida silenciosamente** (risco).
- **Q9 COLISÕES:** **Não colide com US-006a nem MDM.** Escreve só em `Lead.OwnerId` e `Lead.UnifiedFromLeadId__c`. **Não toca Account, nem Document*/ElectronicBillingEmail__c/CreditScenario__c.** Escopo 100% Lead.
- **Q10 BYPASS:** **NÃO existe.** Nenhuma referência a `$Permission.Bypass_Gates_Automacao` (nem `$Permission` em geral). O async roda pra **todo** Lead criado (auto-filtra depois via `Es_Repuestos`).
- **Q11 IDS HARDCODED:** **NENHUM Id literal** (00X). Fila por `DeveloperName` (formula), sem RT/Pricebook/User Id. ⚠️ Dependência cross-ambiente = **existência das filas `Queue_Vendedores_CR/GT/HN/NI/PA/SV`** e do campo `CompanyCode__c`/`Brand__c`.
- **Q12 AUTORIA:** **Não disponível no .flow** (o retrieve de Flow não traz Created/LastModified). → rodar a query 1.1 (FlowDefinitionView) na org.

### FLOW B — `GQ_Lead_Repuestos_PreMerge` (ATIVO, **Screen Flow**, `runInMode=SystemModeWithSharing`)

- **Q1:** Screen flow (`processType=Flow`), input `recordId` (Lead). Sem trigger (é invocado por ação/tela).
- **Q2 OPPORTUNITY:** **NÃO.** Nenhuma Opportunity/Quote/LeadConvert. Só `recordUpdates` em **Lead** (`Update_Master`, `Update_Dup`).
- **Q3 QUOTE:** **NÃO.**
- **Q4 ACCOUNT:** **Não toca.** Só Lead (`Get_Master`, `Get_Dup_Check` por Email/MobilePhone/Phone).
- **Q6 REASIGNACIÓN:** Não muda Owner. **Prepara merge:** marca `UnifiedFromLeadId__c` + `WasUnified__c=true` no master e `DuplicateReason__c` no duplicado; depois o usuário roda o **merge nativo** (tela `Tela_Fim`).
- **Q7 ASYNC:** N/A (screen flow, síncrono na interação).
- **Q8 FAULT:** **Bom** — todos os elementos com faultConnector → `Tela_Erro` (mostra `$Flow.FaultMessage`).
- **Q9 COLISÕES:** Só Lead (`UnifiedFromLeadId__c`, `WasUnified__c`, `DuplicateReason__c`). Sem Account/sensível.
- **Q10 BYPASS:** Não tem.
- **Q11 IDS:** Nenhum hardcoded. `limit=50` no `dynamicChoiceSets`.
- **Q12:** não disponível no .flow.

## 3. MATEMÁTICA DE TRANSAÇÃO (estática — lote 200 leads, 1 save)

- **Flow A é 100% AsyncAfterCommit** → **na transação síncrona do insert de 200 leads, consumo = 0 SOQL / 0 DML.**
- **Async (por lead):** SOQL até ~6 (`Get_LineItem_New`, `Get_Lead_Anterior`, e condicionais `Get_LineItem_Prev`, `Get_Cola_Pais`, `Get_Vehicle`, `Get_Asset`); DML até ~3 (`Asignar_Cola` upd, `Marcar_Candidato` upd, 1 `Log_*` Task). Pior caso ~6 SOQL / ~3 DML por lead.
- **Anti-padrão de loop:** **NÃO existe** — o flow **não tem `<loops>`**; nenhum Get/Update dentro de iteração. Em bulk, cada elemento roda 1x por interview; sem risco de "Too many SOQL 101".
- **Flow B** (screen): síncrono na sessão do usuário, ~2 SOQL / 2 DML por execução; irrelevante pra lote.

## 4. VEREDITO
> **A premissa do D-REP-01 está PARCIALMENTE CONFIRMADA:** a parte "**NÃO cria Opportunity**" está **CONFIRMADA** (Q2 — zero recordCreates/updates de Opportunity, zero LeadConvert); mas a parte "**cria cotización (Quote)**" está **REFUTADA para este flow** (Q3 — nenhum `object=Quote`; o flow só **reatribui owner por fila/sociedad + marca unificação + cria Tasks de log**). A criação de Quote, se existir, está **fora deste flow** (provável OmniStudio — validar com 1.2/1.4).

## 5. RISCOS ENCONTRADOS (Q8–Q11) — só nomeados, sem correção (R1)
1. **Falha silenciosa de reatribuição (Q8):** fault de `Asignar_Cola`/`Get_Cola_Pais` não gera log — lead fica sem fila e ninguém sabe.
2. **Dependência de filas por nome (Q11):** `Queue_Vendedores_<país>` precisam existir; ausência → sem reatribuição, silenciosa (`Cola_Encontrada` default).
3. **Sem gate de bypass (Q10):** async dispara pra **todo** Lead criado (custo/observabilidade), auto-filtrando só depois em `Es_Repuestos`.
4. **Nome enganoso:** "Cotizacion" sem criar Quote — risco de leitura errada do escopo (a própria premissa do D-REP-01).
5. **Autoria não verificada (Q12):** pendente rodar 1.1.
```
