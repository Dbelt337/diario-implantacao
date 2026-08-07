# Arquitetura E2E da Venta Guiada — como a solução ficou (07/08/2026)

Base: **código real da suíte** (retrieve DevSales 07/08, fonte em `deploy/retrieve_venta_guiada/src/`) + pacote do pedido (`deploy/venta_guiada_pedido.zip`) + doc oficial LWC/Apex (fontes no fim). Org enterprise, SAP SEMPRE via MuleSoft (gateway único `MuleGateway`).

## 1. A cadeia de entrada (o que o botão faz hoje — e já é o padrão moderno)
1. Quick Action `Opportunity.VentaGuiadaModal` é **headless** (`lightning__RecordAction` sem tela): o `ventaGuiadaLauncher` expõe `@api invoke()` — padrão recomendado da doc de quick actions LWC.
2. `invoke()` abre `ventaGuiadaModal` via **`LightningModal.open({size:'large'})`** (`lightning/modal`, componente nativo desde Winter '23 — não é markup SLDS manual, ganha foco/teclado/acessibilidade de graça).
3. O modal descobre a linha de negócio com `@wire(getRecord)` lendo `Opportunity.RecordType.DeveloperName` (**imune a tradução de label**) e roteia: `GQOpportunitiesAutos/Motos → nuevo`, `GQOpportunitiesUsados → usado`, `GQOpportunitiesRepuestosPA → repuestos`. Tipo não mapeado = **bloqueio amigável** (não cai em "nuevo" por engano).
4. Ao fechar com cotización criada, o launcher dispara **`RefreshEvent` (RefreshView API)** — a página da Opportunity e as related lists atualizam sem F5. Detalhe fino já resolvido no código: o evento é disparado do launcher (não do modal) porque o modal renderiza em overlay fora do DOM da record page.

**Veredito: a cadeia de entrada não precisa mudar.** É exatamente o trio que a doc atual recomenda (headless action + LightningModal + RefreshView API).

## 2. Linhas de negócio — 1 experiência por RT, mesma espinha de serviços
| Linha | RT (router) | Experiência/steps | Serviços Apex | SAP via Mule |
|---|---|---|---|---|
| **Autos novos** | GQOpportunitiesAutos → `nuevo` | Busca→Seleção→Accesorios→Precio→Pago→Confirmación | MaterialSearch (catálogo) + SapInventory (preço/stock, Continuation) + Pricing (BRE ref.) + Financing + QuoteOrder | preço `cod_salesorder_simulate`; pedido família **ZQEV: Z301 (Reserva Confirmada) → Z300 (venta)** |
| **Motos** | GQOpportunitiesMotos → `nuevo` | MESMA experiência de autos (mesmo código, zero fork) | idem | idem (confirmar c/ SAP se motos rodam na ZQEV) |
| **Usados** | GQOpportunitiesUsados → `usado` | Seleção no **inventário PRÓPRIO** (`Vehicle` SOQL, sem SAP na busca) + ficha do usado | QuoteOrder (mesma quote nativa) | pergunta ABERTA: usados na ZQEV ou doc type próprio |
| **Repuestos** | GQOpportunitiesRepuestosPA → `repuestos` | Seleção de repuestos (sem step de acessórios — repuestos SÃO as linhas), multi-material | MaterialSearch (SOSL local → SAP massivo) + SapInventory | **DBM**: CONSULTA_MATERIALES (massivo), TDET_SALDOS, COTIZA_REP_RFC |
| **PA** | mesmo RT de repuestos (canal distingue lista de preço) | idem repuestos | idem + `canal` no BFF de preço | SD standard: simulate + IDoc SALESORDER_CREATEFROMDAT2 |
| **Flotas (R2)** | linha COMENTADA no router (decisão 04/08) | ver §5 "meio pronto" | — | — |
| **Mayorista** | sem definição de negócio | bloqueio amigável do router | — | — |

**Princípio estrutural**: `ventaGuiadaModal` é o **shell** (stepper, estado, roteamento); `ventaVehiculo`/`ventaUsados`/`contraventaRepuestos`/`ventaPA` são as **cascas por linha** (hoje finas, propósito documentado no próprio código). Evolução recomendada: à medida que o mock vira real, o conteúdo de cada step migra do shell (985 linhas) para a casca da sua linha — o shell não deve crescer mais; componente por responsabilidade é o que mantém a suíte testável e o diff de cada HU pequeno.

## 3. Camadas Apex — enterprise por construção (Well-Architected / SoC)
```
LWC (shell + cascas)
   ↓ 1 chamada por tela (BFF)
GuidedSellingController        ← thin @AuraEnabled: validação, DTO, AuraHandledException
   ↓
Serviços (UI-agnostic, reusáveis por Flow/batch/teste)
   QuoteOrderService · SapInventoryService · MaterialSearchService
   PricingService (BRE) · FinancingService · SapOrderService
   ↓
Integração: Named Credential MuleGateway + External Credential MuleSoft_EC (OAuth CC)
   + PS_Mule_Integration — endpoint/segredo NUNCA em código, troca por ambiente no Setup
```
É o **Service Layer dos Apex Enterprise Patterns** (separation of concerns: controller orquestra a UI, serviço orquestra o processo). Padrões já presentes no código e que valem como régua para toda evolução:
- `with sharing` + **`WITH USER_MODE`** em toda SOQL (FLS/CRUD/sharing aplicados pela plataforma — recomendação atual, substitui checagem manual);
- bulkified, zero SOQL/DML em loop;
- **Continuation** para leitura síncrona longa (preço/estoque) — não segura thread do servidor;
- **Queueable + `Database.AllowsCallouts`** para escrita assíncrona (pedido) — o vendedor nunca espera o SAP;
- **Platform event `SapOrderResponse__e`** HighVolume + `PublishAfterCommit` (o assinante só recebe se a transação commitou);
- degradação elegante: `safeQuoteStatus` (picklist), approval guardado (`NO_APPLICABLE_PROCESS`), `errorMessage` em espanhol para a UI (nunca stack trace);
- **Invocable action** (`GenerateSapOrderAction`) para o mundo declarativo disparar o pipeline sem tocar LWC.

**Upgrade enterprise recomendado (curto, alto valor): Transaction Finalizer no `SapOrderService`.** Finalizer permite callout pós-job e re-enfileiramento com contador de tentativas (a plataforma corta a corrente em 5 falhas seguidas — anti-loop nativo). Com isso, timeout do Mule vira retry automático com backoff em vez de `Error SAP` na primeira falha. Segundo item: objeto de log de integração (payload/response/correlação) — SAP não re-tenta sozinho; a tarefa técnica do Mule precisa de trilha.

## 4. O pipeline do pedido (pacote 07/08) — estados e donos
```
Cotización Confirmada (gate OLI, só SF)
  → [gate Reserva Confirmada, HU-025] GenerateSapOrderAction / controller
  → Order nativo Draft + OrderItems (cópia das QuoteLineItems) · SapStatus__c=Borrador   [idempotente: 1 pedido/quote]
  → Queueable SapOrderService: POST callout:MuleGateway/api/v1/orders
       payload: moeda + código composto do dealer (AccountNumber; Mule extrai CENTRO) + linhas
  → Enviado a SAP (ack) | Confirmado SAP (ack já com número) | Error SAP
  → SapOrderResponse__e p/ UI aberta (empApi) + flow SAP_Order_Response_Handler escreve no pedido
  → confirmação assíncrona (IDoc): Mule publica o MESMO evento → mesmo flow
  → FATURAMENTO: Mule faz UPDATE inbound no Order (Facturado + nº/data fatura) — NUNCA por evento
  → flow Order_Facturado_Handler: notificação (SapOrderAlert) + Task [Entrega] → assetização pluga aqui
```
Status nativo do Order (Draft/Activated) fica intocado; o ciclo SAP vive em `SapStatus__c` com history tracking. Os gates HU-025 mapeiam 1:1 nos documentos SAP (Cotización = só SF; Reserva = Z301; venta = Z300).

## 5. Flotas "meio pronto" (R2) — o que já está preparado e o que falta
Já preparado por construção:
1. o router bloqueia RT não mapeado com aviso (nada quebra se alguém abrir);
2. a linha `GQOpportunitiesFlotas: 'nuevo'` está **comentada no mapa** — reativar é 1 linha;
3. `createQuotesSingleVehicle` já itera N veículos → N quotes (o comentário "one quote per vehicle" é exatamente o modelo de frota);
4. os campos/pipeline do pedido são agnósticos de linha.
Falta para a R2: criar o RT `GQOpportunitiesFlotas` + business process; decidir a experiência (mesma tela `nuevo` com multi-seleção liberada vs. tela de carga em lote); volumetria (frota grande = pedido com N unidades → avaliar 1 Order por unidade vs. Order multi-linha, e o impacto na Z301 — pergunta para o time SAP).

## 6. Checklist "LWC moderno" para toda tela nova da suíte (fundamentado na doc)
- **`lwc:if|elseif|else`** — `if:true/if:false` está deprecado (API 58+); o shell deve migrar onde ainda usar o antigo.
- **`LightningModal`** para qualquer diálogo (aprovação de desconto, confirmação) — nunca SLDS manual.
- **RefreshView API** (`lightning/refresh`) após criar/alterar registros — sem reload manual.
- **`lightning-record-picker`** para busca de registro único (ex.: cliente/conta) — GraphQL por baixo, debounce e cache nativos.
- **GraphQL wire adapter** (`lightning/uiGraphQLApi`) para listas filtradas/paginadas de dados SF (ex.: usados do inventário próprio) — filtro/paginação no servidor, menos Apex.
- **empApi com assinatura escopada**: assinar `SapOrderResponse__e` SÓ com pedido em voo, filtrar por `OrderId__c`, `unsubscribe` no disconnect — já é o desenho documentado na casca `ventaVehiculo`.
- Busca com **debounce** (~300ms) antes de chamar Apex; spinner em Continuation; erro de serviço = mensagem amigável do payload (`errorMessage`), nunca stack.
- Responsividade: SLDS grid (`slds-grid slds-wrap slds-col`) nos steps; `lightning-datatable` com `column-widths-mode="auto"` para as tabelas de veículos/repuestos; modal `size=large` já se adapta.
- Sem DOM manual, sem bibliotecas externas no modal (LWS-safe).

## 7. Mock → real, por etapa (o banner amarelo da tela)
| Etapa | O que conecta | Depende de |
|---|---|---|
| P0 (entregue 07/08) | Perna do PEDIDO (pacote `venta_guiada_pedido.zip`) | deploy + notification type + ativar flows |
| P1 | BFFs reais (`getSelectionPageData`/`getPricePageData`) — catálogo local + usados SOQL substituem a lista hardcoded do shell | nada externo (dados replicados) |
| P2 | Perna SAP do MaterialSearch + endpoint orders no Mule | contrato Experience API c/ Flavio |
| P3 | PricingService → BRE (Decision Matrix/Expression Set) | POC pricing (HU-028) |
| P4 | FinancingService real (CrediQ) | frente financeira (contrato já documentado na classe) |
| P5 | Fiação do pedido no modal (`cotizacionConfirmModal` → `createOrderFromQuote` + empApi) | P0 estável |

## Fontes (doc oficial consultada 07/08/2026)
- Headless quick actions / `invoke()`: developer.salesforce.com/docs/platform/lwc/guide/use-quick-actions-headless.html
- Quick actions LWC (GA, tipos): .../use-quick-actions.html
- Template directives (`lwc:if`, deprecação de `if:true`): .../reference-directives.html
- GraphQL wire adapter: .../reference-graphql.html
- `lightning-record-picker` (GraphQL por baixo): developer.salesforce.com/docs/component-library/bundle/lightning-record-picker
- Service Layer / SoC (Apex Enterprise Patterns): trailhead.salesforce.com/content/learn/modules/apex_patterns_sl
- Well-Architected (composable): architect.salesforce.com/well-architected/adaptable/composable
- Finalizers em Queueable (retry, limite de 5): salesforceben.com/apex-finalizers-introductory-guide + docs Apex Transaction Finalizers
- empApi / platform events (PublishAfterCommit, filtros de canal): doc lightning/empApi + Platform Events Developer Guide
