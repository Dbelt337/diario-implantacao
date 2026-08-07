# Pesquisa de arquitetura — Test Drive (H1–H4) + Bug de conversão de Lead
**Modo: SOMENTE PESQUISA.** v1 · 07/08/2026 · Nenhum build iniciado. Sem Apex em nenhuma recomendação (escada: core platform → OmniStudio Standard Runtime). Org read-only: os describes marcados **[ORG-PEND]** têm o comando pronto na seção 6 — a coluna "Org" só vira **S** com o resultado colado pelo arquiteto.

---

## 0. BUG DO PRINT — "Unable to convert lead that is in use by workflow"

**Causa documentada** (KB oficial [000385353](https://help.salesforce.com/s/articleView?id=000385353&language=en_US&type=1), erro `RECORD_IN_USE_BY_WORKFLOW`): a conversão é bloqueada quando o Lead tem **ação pendente na fila de automação temporal** — qualquer uma destas:
1. Time-based workflow action pendente (workflow clássico);
2. Ação agendada de Process Builder pendente;
3. Lead **dentro de Approval Process** (lock de aprovação);
4. **Flow record-triggered com SCHEDULED PATH pendente no Lead** — o caso moderno: cada scheduled path agendado cria uma interview na mesma fila temporal e produz o mesmo lock.

**Verificações na org (read-only, nesta ordem):**
- Setup > **Time-Based Workflow** → buscar o Lead do erro na fila (workflow/PB clássicos).
- Setup > **Paused and Failed Flow Interviews** → interviews agendadas apontando pro Lead. Via SOQL (seção 6, Q1).
- Aprovação: `SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = '<leadId>' AND Status = 'Pending'`.
- Setup > Flows → filtrar record-triggered em **Lead** e abrir cada um: existe scheduled path? (Suspeitos naturais: automações de lead da org — verificar; LeadDedup/LeadUpsert são Integration Procedures, IP não cria lock temporal — o lock é de Flow/workflow/aprovação.)

**Correção sem Apex**: (a) pontual — remover a ação pendente da fila (Time-Based Workflow permite delete; interview pausada permite delete) e converter; (b) estrutural — **regra de desenho registrada abaixo em H1**: nunca ancorar scheduled path em Lead que pode ser convertido antes do disparo; ancorar no objeto que sobrevive à conversão (ServiceAppointment, Task) ou garantir entry conditions que esvaziam a fila antes da conversão (quando o registro deixa de atender as entry conditions, a interview agendada é **cancelada automaticamente** — comportamento documentado, ver H1).

**Ligação direta com o escopo**: H1 propõe lembretes por scheduled path. Se o lembrete fosse ancorado no **Lead** (test drive de prospect), toda conversão durante a janela do lembrete reproduziria ESTE bug. O desenho do H1 ancora no **ServiceAppointment** — que é exatamente o `ParentRecordId` polimórfico apontando pro Lead/Opportunity sem travar nenhum dos dois.

---

## 1. MATRIZ DE VERIFICAÇÃO
Org: **S** = confirmado por evidência já colada nesta implantação; **P** = pendente (comando na seção 6).

| Objeto | Campo | Tipo (doc) | CRUD (doc) | Fonte doc | Org |
|---|---|---|---|---|---|
| ServiceAppointment | Status / StatusCategory | picklist / restricted picklist | CRU | [SA no AC Dev Guide](https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_serviceappointment.htm) (API 58+ no contexto Automotive Scheduler) | **P** (valores exatos da org — Q2) |
| ServiceAppointment | SchedEndTime / SchedStartTime | datetime | CRU | idem | **P** |
| ServiceAppointment | ParentRecordId | reference polimórfico | CR (set na criação) | idem + [Manage Test Drive Appointments](https://help.salesforce.com/s/articleView?language=en_US&id=ind.auto_scheduler_parent_test_drive.htm&type=5) — no fluxo guest o parent vem via **Lead**; dashboard usa Lead/Opportunity | **P** (lista de objetos aceitos — Q3 describe) |
| ServiceAppointment | WorkTypeId → WorkType/WorkTypeGroup | reference | CRU | Scheduler data model ([help](https://help.salesforce.com/s/articleView?id=sf.auto_scheduler_data_model.htm&language=en_US&type=5)) | **P** |
| Vehicle | LastOdometerReading | double | CRU (Create/Filter/Nillable/Sort/Update) | **Object Reference colado na sessão 06/08** (página Vehicle) | **S** |
| Vehicle | OdometerReadingDate | date | CRU | idem | **S** |
| Vehicle | OdometerReadingUomId | reference → UnitOfMeasure | CRU | idem | **S** |
| Vehicle | OdometerState | picklist (não-restricted) — doc: "use este; **OdometerStatus será deprecado**" | CRU | idem | **S** |
| Vehicle | OdometerStatus | restricted picklist (deprecação anunciada) | CRU | idem | **S** |
| Vehicle/Asset/FleetAsset | **campo standard de km MÁXIMA** | **NÃO EXISTE** | — | Object Reference Vehicle (colado, sem campo de teto) + Asset AC fields; parâmetro de teto na org vive no CMDT `DemoCapacityConfig__mdt.MaxDemoMileage__c` (HU-046/D6) | **S** (Vehicle) / **P** (FleetAsset — Q4) |
| RecordAlert | objeto completo | API **54.0+**, Industries Common Resources | CRUD via Flow/API | [RecordAlert Dev Guide](https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/sforce_api_objects_recordalert.htm) + [Create Record Alerts from Salesforce Objects](https://help.salesforce.com/s/articleView?id=sf.record_alerts_create_from_salesforce.htm&language=en_US&type=5) | **P** (habilitado na org? Q5) |
| BranchUnit | BranchManagerId; relação com ServiceTerritory | reference (doc Industries) | — | Industries Common Resources (BranchUnit* family) — **não cruzado em 2ª fonte ainda** | **P** (Q6 — existência + população) |
| DocumentTemplate | objeto de template DocGen | standard runtime | CRUD (designer) | [OmniStudio Document Generation overview](https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5) | **P** (Q7) |

## 2. DESENHO POR HISTÓRIA (mecanismo nativo + porquê)

### H1 — Lembrete de test drive vencido
**Mecanismo**: Flow record-triggered em **ServiceAppointment** (Create+Update) com **Scheduled Path**, Time Source = `SchedEndTime` + offset (ex. +2h), entry conditions = WorkType da categoria Test Drive **e** StatusCategory ∉ {Completed, Canceled} → ação: **Custom Notification** (Notifications Builder) pro asesor (Technician/owner) ± Task de follow-up.
**Comportamentos documentados que sustentam o desenho** ([release notes scheduled paths](https://help.salesforce.com/s/articleView?id=release-notes.rn_forcecom_flow_fbuilder_scheduled_paths.htm&language=en_US&release=230&type=5), [dev blog](https://developer.salesforce.com/blogs/2021/03/schedule-your-path-in-salesforce-flow)):
- **Cancelamento automático**: se o registro deixa de atender as entry conditions antes do horário (SA completado/cancelado), a interview agendada é cancelada — o lembrete morre sozinho, sem lógica extra.
- **Re-ancoragem**: mudou o `SchedEndTime` (reagendamento), o path re-executa no novo horário — reagendamento coberto de graça.
- **Limite**: 250.000 interviews de scheduled path/24h (ou licenças×200, o maior). Volume de test drives do GrupoQ está ordens de magnitude abaixo.
- Custom Notification chega como **push no Salesforce Mobile** (desktop bell + mobile push, nativo do Notifications Builder).
**Porquê não em Lead**: seção 0 — scheduled path pendente em Lead reproduz o bug da conversão. O SA carrega o contexto (ParentRecordId → Lead/Opp) sem travar a conversão.
**Escopo compartilhado com Field Service**: entry condition SEMPRE filtrando WorkType categoria Test Drive (regra inegociável do contexto).

### H2 — Agenda do veículo demo
**Mecanismo em camadas, tudo declarativo**:
1. **Related list "Test Drive Appointments" no Vehicle** — nativa do Automotive Scheduler: o doc "How Assets and Vehicles Are Related" (colado na sessão 06/08) afirma: *"If you have enabled Automotive Scheduler in your org, you can also view the list of test drive appointments for a Vehicle record where the **Asset is used as service resource**"*. Ou seja, a sustentação é a cadeia Vehicle→Asset→ServiceResource(ResourceType técnico p/ Asset)→AssignedResource→SA. Colunas configuráveis no page layout da related list. **[ORG-PEND Q8]**: confirmar o nome exato da related list no Lightning App Builder do Vehicle.
2. **Calendário de objeto** sobre ServiceAppointment (calendário criado de objeto, campo de data = SchedStartTime, filtro WorkType Test Drive): limite documentado de calendários de objeto — **até 150 itens por vista**; calendários criados de objeto **não são compartilháveis** entre usuários (cada um cria o seu) — limitação a comunicar. [Fonte: help "Calendar Considerations" — colar página se a letra exata for exigida no QA.]
3. **FLS/Dynamic Forms sobre ParentRecordId**: ParentRecordId é campo de sistema do SA — visibilidade por página via Dynamic Forms é possível (esconder/mostrar por perfil no App Builder); FLS clássica em campo standard polimórfico é limitada — **[ORG-PEND Q9]** validar no Object Manager quais permissões o campo expõe.

### H3 — Alerta de quilometragem
**Mecanismo**: Flow record-triggered em **Vehicle** (Update, entry: `LastOdometerReading` changed) → compara com o teto (**CMDT `DemoCapacityConfig__mdt.MaxDemoMileage__c`** — decisão D6 da HU-046; **não existe campo standard de km máxima** em Vehicle, confirmado no Object Reference colado) → excedeu: **Create Records em `RecordAlert`** (objeto Industries, API 54+, criação via Flow é o caminho documentado) + Custom Notification ao gerente.
**Exibição**: componente padrão de Record Alerts na record page do Vehicle (o FlexCard `ServiceExcellenceGenericAlertCard` citado no brief é o mecanismo de exibição do pacote Industries — **[ORG-PEND Q5b]** confirmar presença/nome exato na org; alternativa 100% core: o componente Record Alerts do App Builder).
**Pré-requisito de processo**: habilitar Record Alerts em Setup (Industries) — Q5.
**Dependência de dados**: `LastOdometerReading` precisa ser alimentado (RN2 da HU-045 — capturado em SF; não vem do SAP). BranchUnit.BranchManagerId como destinatário: **não recomendo** até a Q6 provar que BranchUnit está populado — fallback declarativo: o Encargado/gerente da sucursal via grupo `GRP_Sucursal_*` (padrão HU-046).

### H4 — Documento de saída (hoja de salida)
**Mecanismo**: **OmniStudio Document Generation (standard runtime / Foundation)** — [overview oficial](https://help.salesforce.com/s/articleView?language=en_US&id=ind.doc_gen_foundation_document_generation_overview_389381.htm&type=5), [DocGen com OmniScript](https://help.salesforce.com/s/articleView?id=ind.sf_contracts_document_generation_with_omniscript.htm&language=en_US&type=5):
- **DocumentTemplate** (.docx/.pptx com tokens de JSON — dados de qualquer objeto via IP/Data Mapper);
- **LWC `osGenerateAndPreviewDocument`** dentro do OmniScript: gera, pré-visualiza e **anexa ao registro** (DOCX→PDF);
- **Permission sets documentados**: *DocGen Designer* (+OmniStudio Admin) cria templates; *DocGen User* (+OmniStudio User) gera/visualiza sem editar template;
- **Invocação**: Quick Action no ServiceAppointment → OmniScript (mesmo padrão do consentimento de test drive já desenhado no Fit&Gap) → IP monta o JSON (SA + Vehicle + asesor + cliente) → template → PDF anexado ao SA.
- **Foundation vs DocGenPlus**: Foundation = client-side, incluso no runtime standard das Industries (o caso da org); DocGenPlus = add-on com geração server-side/batch e recursos avançados — **não requerido** para hoja de salida individual no showroom. **[ORG-PEND Q7]** confirmar quais permission sets DocGen existem na org (indicador do que está licenciado).
- **Mobile**: geração client-side no browser/mobile app — comportamento em Salesforce Mobile deve ser validado em teste físico (registrar como risco de UX até o teste; alternativa: gerar no desktop da recepção).

## 3. LIMITES / GOVERNOR / KNOWN ISSUES
- Scheduled paths: 250k interviews/24h (ou licenças×200); 1 interview por path executado. Fila visível em Paused Flow Interviews.
- Calendário de objeto: 150 itens/vista; não compartilhável.
- RecordAlert: exige habilitação Industries (Setup) e permissão de leitura no objeto pros perfis que verão o alerta.
- DocGen Foundation: client-side (tamanho/complexidade de template moderados); DocGenPlus para volume/batch.
- **Known Issues**: busca pontual não retornou KI aberto sobre scheduled paths×lead conversion (o comportamento é BY DESIGN, KB 000385353). Recomendo re-checar [Known Issues](https://issues.salesforce.com) por "ServiceAppointment scheduled path" e "RecordAlert" na release corrente da org (v67) — **[ORG-PEND Q10]**, o site é navegável do teu lado.
- Regra transversal: TODA automação em SA escopada por WorkType categoria Test Drive (SA compartilhado com Field Service).

## 4. DIVERGÊNCIAS DOC × ORG
Nenhuma encontrada até aqui **nas partes já confirmáveis** (campos de odômetro do Vehicle batem com o reference colado). Coluna Org da matriz fecha com os describes — qualquer divergência entra aqui com a org vencendo.

## 5. REFERÊNCIAS
1. KB 000385353 — Error 'Unable to convert lead that is in use by workflow' (help.salesforce.com)
2. Release Notes — Run Part of a Record-Triggered Flow After the Triggering Event (scheduled paths) + Dev Blog "Schedule Your Path in Salesforce Flow"
3. Automotive Cloud Dev Guide — ServiceAppointment (API 58+); help: Set Up Appointment Scheduling / Manage Test Drive Appointments / How Automotive Scheduler Records Work Together
4. Object Reference — página Vehicle (colada integralmente na sessão de 06/08: campos de odômetro, nota de deprecação do OdometerStatus)
5. Industries Common Resources — RecordAlert (API 54+); help: Create Record Alerts from Salesforce Objects
6. OmniStudio Document Generation — overview Foundation + Document Generation with OmniScript (osGenerateAndPreviewDocument, permission sets DocGen)
7. Trailhead — Appointment Scheduling in Automotive Cloud

## 6. COMANDOS READ-ONLY PARA FECHAR A COLUNA "ORG" (rodar e colar)
```bash
# Q1 — interviews agendadas travando o lead do bug
sf data query -q "SELECT Id, InterviewLabel, CurrentElement, PauseLabel, CreatedDate FROM FlowInterview WHERE InterviewStatus='Paused'" -o devsales
# Q2 — valores reais de Status do SA
sf data query -q "SELECT MasterLabel, ApiName, IsDefault FROM ServiceAppointmentStatus ORDER BY SortOrder" -o devsales
# Q3 — describe do SA (ParentRecordId: referenceTo)
sf sobject describe -s ServiceAppointment -o devsales > sa_describe.json
# Q4 — FleetAsset existe? campos?
sf sobject describe -s FleetAsset -o devsales
# Q5 — RecordAlert habilitado
sf sobject describe -s RecordAlert -o devsales
# Q6 — BranchUnit e BranchManagerId
sf sobject describe -s BranchUnit -o devsales
# Q7 — DocumentTemplate e permission sets DocGen
sf sobject describe -s DocumentTemplate -o devsales
sf data query -q "SELECT Name FROM PermissionSet WHERE Name LIKE '%DocGen%' OR Label LIKE '%Doc%Gen%'" -o devsales
# Q8/Q9 — App Builder do Vehicle (related list Test Drive Appointments) e Object Manager do SA (ParentRecordId) — verificação visual, print
# Q10 — issues.salesforce.com: buscar "scheduled path", "RecordAlert", "ServiceAppointment" na v67
```
**O dossiê volta pra revisão do arquiteto antes de qualquer construção.**
