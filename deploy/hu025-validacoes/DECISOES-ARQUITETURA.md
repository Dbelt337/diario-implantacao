# Log de decisões de arquitetura (Nativo / GAP / Dependência)

Rubrica: ver PRINCIPIOS-ANALISE.md. Veredito: ✅ Nativo · ⚠️ Parcial · ❌ GAP · 🔌 Dependência.

---

## HU-025 — Conversão Lead→Opp (produto + vendedor)
✅ **RESOLVIDA.** Transformação nativa (ObjectHierarchyRelationship) cria
OpportunityLineItem e OpportunityPreferredSeller na conversão. Ver
NOTAS.md e HANDOFF-PROXIMOS-AMBIENTES.md.

## HU-042 — Cenários de cotação
| # | Cenário | Veredito | Base |
|---|---|---|---|
| 1 | Múltiplas unidades da mesma marca | ✅ Nativo | Vários line items numa cotação |
| 2 | Enviar cotação por WhatsApp | ✅ Nativo | Digital Engagement (licença confirmada); link do Quote PDF ou documento no canal Messaging |
| 3 | Anexar ficha técnica + enviar junto | ✅ Nativo | Files + Quote PDF por e-mail/WhatsApp. GAP só se exigirem PDF único mesclado (doc-gen) |
| 4 | Cotação multimarca (Chevrolet + Hyundai) | ✅ Nativo | Price Book é por **país/sociedade**, contém todas as marcas → cabem na mesma cotação. Limite: não misturar produtos de **países diferentes** (books diferentes) |

## HU-044 — Criação da cotação com stock
✅ Fluxo correto. **OmniScript (Standard Runtime)** como container; Integration
Procedure → MuleSoft → SAP nos passos de disponibilidade/preço. Decidir usar o
objeto **Quote nativo** (recomendado, para enviar ao cliente). Passos de
SAP/preço (H7) 🔌 dependência — montar shell nativo agora, ligar integração
quando o contrato sair.

## HU-030 — Repuestos / PA (peças)
| # | Ponto | Veredito | Base |
|---|---|---|---|
| 1 | Integração catálogo montadora | 🔌 Dependência | MuleSoft Accelerator for SAP (Product/Availability). Sprint 3 sem integração: modelo + catálogo seed + busca sobre cache |
| 2 | Resolução VIN→peças | ❌/🔌 GAP de dado | Compatibilidade é dado OEM. VIN→VehicleDefinition nativo; VehicleDefinition→peça via tabela de compatibilidade carregada |
| 3 | Modelo de dados do veículo | ✅ Nativo (campos confirmados) | **Vehicle** (VehicleIdentificationNumber=VIN, VehicleRegistrationNumber=Placa) + **Asset** + **Asset Account Participant** (Stakeholder Role=Customer) → identifica cliente e mostra VINs. Falta **carregar** os dados |
| 4 | Visibilidade cross-sociedade x segurança | ✅ Nativo (padrão) | **Inventário NATIVO: Location + ProductItem + SerializedProduct** (não custom). ProductItem read-only com OWD amplo p/ ver disponibilidade de outras filiais; comercial segue seguro por sociedade. Sync SAP via mapeamento Vehicle Inventory (BOD) |
| 5 | Determinação do preço | ✅/🔌 | **PA → Price Book nativo**; **Repuestos → callout real-time SAP** (dinâmico). Price Book padrão só p/ PA |
| 6 | Disponibilidade informativa x transacional | ✅ Confirmado | Identificação = read-only via MuleSoft; validação transacional = real-time no fechamento (decisão Felipe) |
| 7 | Sincronização e modo degradado | 🔌 Dependência | Cache no SF: materiais/preços de referência/disponibilidade básica (diário) + real-time só no commit. SAP fora → cache com flag e bloqueia só o commit |

## HU-039 — Criação/extensão de material (master data SAP)
| # | Ponto | Veredito | Base |
|---|---|---|---|
| 1 | Automático vs solicitação | 🔌/⚠️ | Automático via integração se regra determinística; senão solicitação + aprovação. Depende da **governança de master data** do GrupoQ |
| 2 | Modelagem (Case vs objeto custom) | ✅ Nativo | **Case + Record Type "Solicitação de Material" + Entitlements/Milestones** (SLA, fila, auditoria nativos). Objeto custom só se muitos campos estruturados |
| 3 | Usuários sem licença SF (inventário/almoxarifado) | ✅ (padrão integração) | Atuam **no SAP**; SF cria a solicitação e o status volta automático via MuleSoft (**closed-loop**), fecha o Case |

## Transversais
- **Assinatura digital:** ❌ **fora do nativo.** Requer **DocuSign** ou **Adobe
  Acrobat Sign** (add-on pago) para e-signature legal; ou elemento **Signature
  do OmniScript** para aceite simples (sem valor legal/auditoria). Item separado.
- **Inventário/estoque (todas as HUs):** 🔌 MuleSoft/SAP. Padrão: cache diário
  (status básico) + validação real-time no fechamento. Reusar aceleradores Mule.
- **Preço por sociedade/país:** ✅ Price Book por sociedade (multimoeda). C101
  Costa Rica montado; futuros HN/GT/SV mesma lógica.

---

## US-015 — Gestão de contas B2B (Repuestos/PA) — H2 Vinculação de Frota

**Requisito:** ver na conta B2B do cliente os VINs da frota dele (colunas VIN,
modelo, estado, último odômetro), **sem colidir** com a conta de quem vendeu a
unidade.

**CORREÇÃO DE PREMISSA (rubrica #4 — escopo/decisão sobre campo inexistente):**
O D-B2B-01 mandava usar `Vehicle.RelatedAccountId` (citando Object Reference
l.397). **Describe no org (log 07LWK00000PdMFI2A3) provou: `Vehicle` NÃO tem
`RelatedAccountId` NEM `AccountId`.** O Vehicle liga a Account só via Asset
(`Vehicle.AssetId` → `Asset.AccountId`). Logo o D-B2B-01, como escrito, **não é
implementável**. A decisão estava marcada RESOLVIDA sobre um campo que não existe.

**COBERTURA NATIVA CORRETA — `AssetAccountParticipant`** (Automotive Cloud):
- Objeto feito para relacionar **múltiplos stakeholders** a um asset/veículo, com
  **papel** (Stakeholder Role: Customer / Sales Dealer / Customer-Preferred
  Dealer / Financier), Status e datas de vigência. Tem lookup **direto ao
  Vehicle**.
- Frota do cliente = AAP **Role=Customer** ligando a **conta B2B** ao **Vehicle**.
- Quem vendeu = AAP **Role=Sales Dealer**. Zero colisão — resolve por design o
  que o RelatedAccountId tentava.
- **Related list na conta** = "Asset Account Participants" filtrada Role=Customer;
  colunas VIN/modelo/estado/odômetro vêm do Vehicle (lookup no AAP).
- Visualização opcional: **Actionable Relationship Center** (nativo) para o grafo
  de stakeholders do veículo.

**Descartado:** `Fleet_Owner_Account__c` custom (rubrica #2) — o AAP nativo cobre
com papel + histórico, sem campo novo.

**Verdito:** ✅ Nativo (AssetAccountParticipant). Ação: corrigir D-B2B-01 e o
roteiro E2E (H5) de `Vehicle.RelatedAccountId` para `AssetAccountParticipant`.

Doc oficial: Create Asset Account Participants in Automotive Cloud —
https://help.salesforce.com/s/articleView?id=sf.auto_create_asset_account_participants.htm

**Campos do AAP confirmados no org (describe 07LWK00000PdPI22AN):**
`AccountId`→Account, `VehicleId`→Vehicle, `AssetId`→Asset, `StakeholderRole`
(picklist), `EffectiveStartDate`/`EffectiveEndDate`, `IsActive`, `UsageType`,
`CurrencyIsoCode`, `Name`. Confirma lookup DIRETO Conta↔Vehicle + papel + vigência.

**Passos de implementação (H2):**
1. Relacionar frota = criar AssetAccountParticipant: `AccountId`=conta B2B do
   cliente, `VehicleId`=veículo, `StakeholderRole`=Customer, `IsActive`=true,
   `EffectiveStartDate`. Vendedor = outro AAP com Role=Sales Dealer (sem colisão).
2. Related list na conta B2B = adicionar "Asset Account Participants" na página
   (Dynamic Forms/layout), filtrada por Role=Customer.
3. Colunas VIN/modelo/estado/odômetro = criar **formula fields no AAP** puxando
   do lookup Vehicle (ex.: Vehicle.VehicleIdentificationNumber, ConditionType,
   modelo via VehicleDefinition, odômetro) e exibir na related list.
   Zero objeto/campo custom de modelo — só fórmulas de exibição.

---

## HU-013 / US-017 — Disponibilidade e atribuição de assessores de showroom (Autos/Motos)

**Requisito:** libro de piso (bitácora), estado do assessor em tempo real
(ativo/ocupado/ausente), atribuição do walk-in a assessor disponível pela
recepção/host, com override manual. FIT (Annex fila 15).

**Stack NATIVO (native-first):**
| Requisito | Recurso nativo | Doc |
|---|---|---|
| Estado tempo real (ativo/ocupado/ausente) | **Omni-Channel Presence Statuses** (Online/Busy/Away) | Set Up Presence Statuses |
| Atribuição por presença + capacidade | **Omni-Channel Presence-Based Routing** + Presence Configuration (Capacity) | Routing Model Options |
| Ordem de turno (round-robin/carga) | **Routing Model** (Least Active / Most Available) | Routing Model Options |
| Libro de piso (walk-in roteável) | **Service Channel** sobre **Lead** ou objeto custom "Visita_Showroom" | Route Work with Omni-Channel |
| Fila quando todos ocupados | **Omni-Channel Queue** | Omni-Channel |
| Host supervisiona / reatribui | **Omni-Channel Supervisor** + reassign | Omni Supervisor |
| Tempos de espera / tráfego | timestamps de AgentWork/PendingServiceRouting + relatórios | — |
| Notificação ao assessor | Omni widget + **Custom Notification** (App/Mobile) / Email via Flow | Notification Builder |
| Cliente com CITA | **Salesforce Scheduler** (respeita assessor agendado) + Scheduler↔Omni utilization | Enable Scheduler & Omni-Channel |

**CAVEAT-CHAVE (rubrica #4) — quem seta o estado do assessor:**
Omni-Channel Presence é **auto-gerido pelo agente logado num console** (o
assessor seta Available/Busy). Em showroom, o assessor está no salão, talvez só
com mobile. Então validar com GrupoQ o MODO de operação:
- **Agente self via console** → Presence Status **nativo** (sem `Advisor_Status__c`).
- **Host gerencia um board** (assessor não fica em console) → aí um
  `Advisor_Status__c` + board custom (FlexCard/OmniScript Standard Runtime) pode
  se justificar, PORÉM o roteamento Omni-Channel ainda usa Presence — ou vira
  atribuição manual pelo host. **Definir isso decide se o campo custom entra.**

**Descartar por ora:** `Advisor_Status__c` custom como premissa fixa — só se o
modo "host-board" for confirmado. Native-first = Presence Status.

**Libro de piso:** não há objeto nativo "floor log". Decisão: rotear **Lead**
(walk-in = prospect) OU objeto custom leve **Visita_Showroom__c** se precisarem
bitácora própria (tráfego/tempos). Avaliar reuso de Lead antes de criar objeto.

**Dependência (rubrica):** Omni-Channel exige **licença Service Cloud** — o
próprio Annex flaga (caveat fila 272). Confirmar entitlement + registrar a base.

**A validar (já no doc):** capacidade por assessor, ordem de turno, comportamento
all-busy, respeito à cita, sucursal sem host. Manter como perguntas ao cliente.

**Veredito:** ✅ Nativo (Omni-Channel + Salesforce Scheduler), 🔌 dependência de
licença Service Cloud. Ponto aberto: modo de gestão do estado (agente vs host).

---

## HU-027 / US-042… — Seguimento comercial e gestão de atividades (Auto/Motos/Rep&PA)

**Estado:** FIT, native-first, **sem objeto custom**. Task/Event/Notes/Activity
Timeline sobre Opportunity.

**EAC vs Standard — DECISÃO:**
- **Standard Task/Event/Notes + Activity Timeline = SISTEMA DE REGISTRO oficial.**
  É o repositório de trazabilidade/reporting e o que permite automação e gating.
- **Einstein Activity Capture = OPCIONAL e complementar** — só auto-captura de
  eventos de calendário (e e-mails) para VISIBILIDADE. **NÃO é o repositório
  oficial** (o próprio doc crava isso).
- Motivo técnico: itens do EAC ficam em armazenamento externo (AWS), **não** como
  Task/Event → não entram nos reports padrão de Activity, sem trigger/Flow, com
  limite de retenção. Por isso o **gating de Rep&PA Online** ("só avança se tarefas
  obrigatórias completas") **exige Task standard**, não EAC.
- Recomendação: **construir em standard; EAC só como add-on passivo** se GrupoQ
  decidir (licença/validação). Não basear a HU no EAC.

**Config de atividades (planilha):**
- Llamada (Log a Call): Documentación, Cita, Financiamiento, Negociación.
- Tarea (Task): Enviar Cotización, Presupuesto, Recontacto, Confirmar visita.
- Evento (Event): Prueba de manejo, Avalúo, Visita a sucursal, Entrega de
  vehículos, Invitación BTL, Firma documentos, Visita de campo.
- Campos = os de caixa do Salesforce. Type (categoria) + Subject (subvalores).

**Respostas nativas às perguntas abertas do doc:**
- "Calendário no SF sem EAC?" → **Lightning Calendar** nativo (Events) + Activity
  Timeline (Tasks/Calls/Notes). Atividades visíveis mesmo sem EAC.
- "Relatório de atividades por sucursal?" → **Reports padrão de Activities**
  (Task/Event) agrupados por assessor/sucursal.
- "Contempla WhatsApp/Correos?" → E-mail = **EmailMessage** no timeline;
  **WhatsApp = Messaging Session** (Digital Engagement, licença já confirmada).
- **Sincronização bidirecional de Task/llamadas = 🔌 GAP** (sem nativo; Lightning
  Sync/Salesforce for Outlook descontinuados). Exigiria Graph API/integração.
  Não assumir (rubrica #4).
- Mostrador: permitir **criar Opportunity** quando o cliente não compra na hora
  (fluxo gerido) além do transacional Conta/Contato→Quote→Order. Nativo.

**Veredito:** ✅ Nativo (Sales Cloud Activities + Outlook Integration). EAC
opcional. Bidirecional Task/call = GAP a validar. Licença Outlook Integration é
free; EAC pode exigir Sales/Service Cloud Einstein — confirmar.

---

## HU Avalúos — Agendamento e gestão de avaliações (Autos, trade-in)

**Requisito:** agendar/gerir avaliações (avaliadores internos e externos),
autoatendimento, observações (multas/gravames/processos), filial diferente da Opp.

**Stack NATIVO — Salesforce/Automotive Scheduler (mesmo padrão do Test Drive):**
| Requisito | Recurso nativo | Doc |
|---|---|---|
| Avaliação (agendamento) | **Service Appointment** + **Work Type** "Avalúo" | Manage Appointments (Scheduler) |
| Avaliador interno | **Service Resource** (ligado a User) | Assign Service Territories |
| Filial | **Service Territory** | Set Up Service Territories |
| Disponibilidade | **Operating Hours** + Scheduling Policy — NATIVA, **não SAP** | Work Types & Territories |
| Autoatendimento (cliente agenda sozinho) | ❌ SEM Experience Cloud não é nativo → **agendamento assistido** (recepção/assessor agenda no Scheduler) OU site próprio via **Scheduler REST APIs** (dev/integração) | Scheduler REST |
| Observações (multas/gravames/processos) | Campos na Service Appointment + **Notes**, ligados à Opp | — |
| Avaliação em outra filial | Service Appointment em outra **Service Territory** + **Opportunity Team** (Owner mantido) | (padrão Test Drive) |

**Avaliador EXTERNO sem acesso ao SF (rubrica #4 — não assumir):**
- **Não** vira Service Resource (exigiria User/licença). Modelar como
  **Conta/Contato fornecedor**; registrar o Service Appointment (rastreabilidade)
  + **notificar por Flow (e-mail/WhatsApp via Messaging)** + histórico na Opp.
  Mesmo padrão da HU-039 (ator fora do SF).
- Só vira **Service Resource** se precisarem **gerir a agenda do externo** no SF
  (aí precisa User/licença) — decisão a validar.
- **Não há objeto nativo de "avaliador externo"** no Automotive Cloud — Scheduler
  + notificação cobre.

**GrupoQ NÃO tem Experience Cloud (confirmado):** autoatendimento do cliente
online **não é nativo**. Native path = **agendamento assistido** (recepção/
assessor agenda em nome do cliente no Scheduler — cobre o essencial). Self-service
real (cliente agenda sozinho) = site próprio + **Scheduler REST APIs** (dev/
integração) OU adquirir Experience Cloud → marcar como GAP/dependência, não nativo.

**Dependências (rubrica):** User/licença (externo como Service Resource, só se
gerir agenda dele). Disponibilidade NÃO depende de SAP. Autoatendimento online =
GAP sem Experience Cloud.

**Veredito:** ✅ Nativo (Salesforce Scheduler). Externo = registrar+notificar
(vendor Contact), não Service Resource por padrão. Observações = campos + Notes.

**Registro do RESULTADO da avaliação (valor, observações finais):**
- Resultado vive no **Service Appointment** (campos custom: valor do avalúo,
  observações finais, condição, multas/gravames). Avaliador interno preenche ao
  concluir (Status=Completed); externo → assessor interno registra.
- **Propagação para a Opportunity:** SA↔Opp NÃO é master-detail → sem roll-up
  nativo. Native path = **Flow record-triggered na Service Appointment**
  (Status=Completed) carimba valor/observações na Opportunity. É o "atualiza
  automaticamente" (declarativo, sem código).
- Bônus: se o veículo de troca for um registro **Vehicle**, o mesmo Flow pode
  atualizar `AverageMarketValue`/`MarketPrice` (campos nativos de mercado).
- Histórico: cada Service Appointment guarda seu resultado → related list de
  avaliações na Opp para rastreabilidade (re-avaliações).

**⚠️ CORREÇÃO native-first (rubrica #2) — usar a família NATIVA Appraisal:**
Melisa (GrupoQ) apontou que o Automotive Cloud tem o data model **"Vehicle and
Asset Appraisals"**: `Appraisal`, `AppraisalItem`, `AppraisalItemAddon`,
`AppraisalItemProviderVal`, `AppraisalAdjustment`. Minha recomendação anterior
(resultado em CAMPOS CUSTOM no Service Appointment) estava ERRADA por não usar o
nativo apropriado. Desenho correto:
- **Service Appointment (Scheduler)** = só o AGENDAMENTO (quando/onde/quem —
  Service Resource, Territory, Operating Hours).
- **Appraisal (+ Item + ProviderVal + Adjustment)** = a AVALIAÇÃO/RESULTADO:
  - `FinalAppraisalValue` **calculado nativamente** (não campo manual).
  - `AppraisalItemProviderVal` = valorações do provedor / **PRU de referência**
    (se PRU vem de tabela mestre GQ-CA-01-157, a provider val referencia/guarda).
  - `AppraisalAdjustment` = **cada dedução do avaliador e exceção do gerente,
    rastreada uma a uma** — é a rastreabilidade que se perderia com campos custom.
- Link: Appraisal relacionada à Opportunity/Vehicle/Asset. Flow pode carimbar o
  FinalAppraisalValue na Opp, mas a **fonte da verdade é a Appraisal nativa**.

**NÃO eliminar a família Appraisal** — é o modelo nativo de avaliação e entrega a
rastreabilidade (adjustments/provider vals/valor calculado). Corrige o registro
anterior de "campos custom no Service Appointment".

Doc oficial: Vehicle and Asset Appraisals (Data Model) —
https://developer.salesforce.com/docs/platform/data-models/guide/vehicle-and-asset-appraisals.html

---

## OmniStudio — Derivar RecordType do Lead por DeveloperName numa Integration Procedure (Davi)

**Contexto:** IP `GrupoQ_LeadUpsert` (Standard Runtime) cria o Lead a partir do
web-to-lead. A linha de negócio chega em `lead.businessLine` (Autos, Motos,
Repuestos/PA, Flotas) e a IP precisa derivar o `RecordTypeId` do Lead antes do
insert. Sintoma reportado: RecordType salvava **branco**.

**Desenho da IP (correto, mantém):**
1. `RecordFormula` (Set Values) monta `developerName` = `CONCAT("GQLeads",
   IF(OR(businessLine="Repuestos",businessLine="PA"),"RepuestosPA",businessLine))`,
   `defaultName="GQLeadsAutos"`, `sObject="Lead"`.
2. `GetLeadRecordType` (DR Extract `DRExtractRecordTypeFromName`) — busca o
   RecordType por `developerName` + `sObject`, devolve node **`id`**.
3. `GetAutosRecordType` (mesmo DR) — só roda se `ISBLANK(GetLeadRecordType:id)`
   (fallback Autos).
4. `SetRecordType` (Set Values) — `id = IF(ISBLANK(GetLeadRecordType:id),
   GetAutosRecordType:id, GetLeadRecordType:id)`.
5. `InsertLead` (DR Post `DRLeadInsertMapper`) — manda `RecordTypeId =
   SetRecordType:id`; o Data Mapper mapeia input `RecordTypeId` (raiz) → output
   `Lead.RecordTypeId`.

**Pega-ratões (checar NESTA ordem quando RecordType sai branco):**
1. **Node de saída do DR Extract tem que se chamar exatamente `id`** (minúsculo,
   raiz). A IP lê `%GetLeadRecordType:id%`. Se o Extract devolve `Id`/`RecordTypeId`
   ou aninhado, a referência sai vazia → SetRecordType branco.
2. **DeveloperNames têm que bater com o que a fórmula monta.** Confirmados na org:
   `GQLeadsAutos` (012...n8DZYAY), `GQLeadsMotos` (n8FBYAY), `GQLeadsFlotas`
   (n8GnYAI), `GQLeadsRepuestosPA` (n8IPYAY) — todos `SobjectType=Lead`.
3. **O RT tem que ser do objeto certo** (`SobjectType='Lead'`) — o filtro do
   Extract precisa ter `SobjectType = sObject`. RT de outro objeto num Lead é
   descartado sem erro no save.
4. **⚠️ CAUSA RAIZ DESTE CASO — atribuição de Record Type no Profile.** O Id
   chegava no insert (provado no preview do Data Mapper: output `Lead_1` com
   `RecordTypeId=012...n8IPYAY` e `UpsertSuccess:true`) mas salvava branco porque
   **o usuário que roda a IP não tinha o RT `GQLeadsRepuestosPA` atribuído**.
   Salesforce **ignora silenciosamente** um RecordTypeId que o Profile do running
   user não tem e cai no default. Autos funcionava (profile tinha), RepuestosPA não.

**Correção (padrão para produção):** Permission Set `GQ_Lead_RecordTypes` com os
**4** Record Types de Lead habilitados, atribuído (a) ao usuário de teste e (b) ao
**usuário automático do web-to-lead** (Integration User / guest do site). Sem isso,
leads de Repuestos/Motos/Flotas entram sempre com RT errado, mesmo com a IP correta.
**Não desligar o "Field Level Security" do Data Mapper** para "resolver" — mascara
o problema; a correção é a atribuição de RT.

**Regra reutilizável:** sempre que uma automação (IP/Flow/Apex) setar `RecordTypeId`
por um usuário não-admin, garantir que TODOS os RTs possíveis estejam atribuídos ao
running user (Profile ou Permission Set). RecordType assignment **não** é FLS — não
adianta CRUD/FLS, é permissão separada.

**Nuance "admin" (validar ANTES de atribuir):** "usuário é admin" só garante
acesso a **todos** os Record Types se for o profile-padrão **System Administrator**.
Profile admin **customizado/clonado** NÃO herda RTs automaticamente → cai no mesmo
drop silencioso. Teste discriminador rápido: criar Lead na UI como o usuário e ver
se o RT aparece no seletor.
- Aparece → usuário tem o RT; se ainda salvar branco, a causa é outra
  (before-save Flow/trigger/assignment sobrescrevendo) → conferir por **Debug Log**.
- Não aparece → profile sem o RT → aplicar Permission Set `GQ_Lead_RecordTypes`.

**Regra de go-live:** teste como admin NÃO prova produção. Para cada usuário real
(não-admin) e para o **usuário de integração** que dispara a IP, validar ANTES:
(a) qual profile; (b) profile tem os 4 RTs OU o PS `GQ_Lead_RecordTypes`;
(c) teste real (businessLine Repuestos/Motos/Flotas) salvou o RT correto. Só marcar
pronto quando os três estiverem ✅ para o usuário de integração real.

**STATUS: RESOLVIDO (23/06)** — Davi confirmou funcionamento após acertar o
Record Type. Validado com o **user dele (System Administrator)** e **no preview**
do OmniStudio. A lógica da IP está correta e o RT flui até o insert.

**Pendências de GO-LIVE (não testadas ainda — validação foi só admin+preview):**
1. Rodar com o **usuário de integração real** (o que dispara o `GrupoQ_LeadUpsert`
   no web-to-lead), não o admin. Esse user NÃO herda RTs → precisa do Permission
   Set `GQ_Lead_RecordTypes` (os 4 RTs de Lead) atribuído.
2. Conferir o **Lead salvo no banco** (não só o preview) com
   `SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Lead ORDER BY CreatedDate DESC LIMIT 1`,
   testando businessLine de Repuestos, Motos e Flotas (cobrir os 4 RTs).
Só marcar pronto pra produção quando (1) e (2) passarem com o usuário de integração.

---

## Lead Routing — Fix do re-roteamento (bounce) no update (Marcelo/Davi)

**Sintoma:** criar Lead → distribui a um usuário; atualizar Lead → volta pra
fila → redistribui. Não é "assim mesmo".

**Arquitetura real (2 estágios — NÃO é conflito):**
- `Lead_Routing_GrupoQ` (Assignment Rule, ativa) → atribui a **FILAS** por
  Industry/Sociedad (9 entradas). Estágio 1.
- `Lead_TriggerOmniRouting` (record-triggered CreateAndUpdate) → chama
  `LeadRouting_OmniFlow` (Active = **V8**) → Omni tira da fila e roteia pro
  **agente** (afinidade vendedor preferido / skills / presença). Estágio 2.
- Correção de registro anterior: eu havia dito "dois mecanismos brigando, escolha
  um". Com as regras atribuindo a FILAS, é um 2-estágios válido.

**Causa do bounce:** o gatilho re-invoca o Omni sempre que um campo de critério
(Brand__c, CompanyCode__c, Industry) muda no update; `routeWork` recria a
solicitação e puxa o Lead de volta pra fila. Sem trava de "já atribuído".

**Fix (nativo, sem campo custom):** Decision `Deve_Rotear` no início do caminho
assíncrono — **só rotear se `OwnerId` começa com `00G` (Fila)** (fórmula
`fOwnerEsFila = BEGINS($Record.OwnerId,"00G")`). Owner `005` (vendedor) → não
roteia. Arquivo: `deploy/lead-routing-fix/`.

**Decisão de negócio confirmada:** Lead criado na UI que fica com o criador
(owner = usuário) → **mantém com o criador** (Omni não roteia). "Estar numa fila"
é o sinal de que precisa de roteamento.

**Regra reutilizável:** roteamento Omni por record-triggered flow deve travar em
`OwnerId` = Fila (00G) pra nunca re-rotear Lead já atribuído a um agente.

**Pendências:** (1) simplificar — o gatilho recalcula a própria fila (5) que não
bate com as 9 das Assignment Rules → consolidar o mapa num lugar só; (2) confirmar
que updates via API/DataRaptor não re-rodam Assignment Rules (assignmentRulesUsed
só no create).
