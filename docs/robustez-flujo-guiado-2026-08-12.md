# Robustez do fluxo de venda guiada — criação de material DENTRO do fluxo, locks e concorrência

**Data:** 12/08/2026
**Contexto:** revisão pedida pelo Diego após o deploy da US-021: "precisa ser dentro do fluxo de vendas guiada — não encontrou o material, ele solicita que seja criado? Essa modelagem é correta? Está bem construído o fluxo? Podemos ter problemas com múltiplos acessos?"
**Pacote:** `deploy/deploy-robustez-flujo-guiado.zip` (mesmo conteúdo em `deploy/deploy-robustez-flujo-guiado/`)

---

## 1. A modelagem correta: criação a partir do *search-miss*, dentro do fluxo

A modelagem que o Diego descreveu **é a correta** e agora está implementada:

1. O assessor digita o código/nome no grid de Repuestos & PA (`lineasRepuestos`).
2. O componente busca o catálogo **enquanto digita** — novo entry `GuidedSellingController.searchMaterials` delegando em `MaterialSearchService.search` (SOSL local, perna já implementada).
3. **Encontrou** → sugestões em dropdown; um clique preenche a linha.
4. **Não encontrou** → aviso inline *"«termo» no está en el catálogo"* com botão **"Solicitar creación de material"** que abre o painel da US-021 já pré-preenchido — sem sair da venda guiada.
5. Confirmada a criação (ZQEV_DBM_CREACION_MATERIALES via SapMuleClient), a linha **entra no grid automaticamente** e segue o caminho normal: consultar disponibilidade → guardar na cotização.
6. Rejeição SAP continua abrindo Case à área com a MENSAJE crua (regra da US-021).

O botão "Crear material" na linha `sinCatalogo` do grid continua existindo — é a mesma porta da US-021 para o caminho da **carga masiva** (GQ-PV-02-001-4), que não passa pela busca-enquanto-digita.

> **Decisão de escopo (Diego, 12/08/2026):** a action de Flow
> (`CreateSapMaterialAction`) foi **removida** — estava além do que a HU pede
> ("só quero o que realmente vamos usar"). Pacote de remoção:
> `deploy/deploy-remocao-action-material.zip` (teste atualizado +
> `destructiveChangesPost.xml`). A capa de negócio (`MaterialCreationService`)
> segue intacta; se um dia o domínio de catálogo precisar de porta
> declarativa, a action se reconstrói em minutos sobre o mesmo serviço.

### Práticas de LWC enterprise aplicadas (documentação Salesforce)

| Prática | Onde |
|---|---|
| **Debounce** de 300 ms + mínimo 3 caracteres antes de chamar Apex | `handleCodigo` → `buscarCatalogo` — evita uma chamada por tecla |
| **Token de sequência** descartando respostas fora de ordem | `busquedaSeq` — o assessor continua digitando enquanto uma busca velha viaja |
| `cacheable=true` **só** na perna local (sem callout, sem stock) | `searchMaterials`; a disponibilidade continua em `checkRepuestosAvailability`, NÃO cacheable |
| Erros para o usuário via toast, nunca stack trace cru | `mensaje(error)` + `AuraHandledException` no controller |
| Responsivo: dropdown flutuante SLDS (não empurra o layout), grid SLDS | `.lista-sugerencias` (`position:absolute`), classes `slds-grid`/`slds-listbox` |
| `disconnectedCallback` limpando o timer | evita callback depois do unmount |
| Erro de busca ≠ "não existe": **não** oferece criar material se a busca falhou | `buscarCatalogo` catch — só o miss real abre a porta da US-021 |

Fontes: LWC Developer Guide (debounce/imperative Apex, `cacheable=true` proíbe callouts e DML), Apex Developer Guide (SOSL em teste exige `Test.setFixedSearchResults`).

---

## 2. Múltiplos acessos: SIM, tínhamos dois furos reais — corrigidos

### Furo 1 — pedido duplicado (dois Z301 no SAP)
`QuoteOrderService.createOrderFromQuote` fazia *query-then-insert*: checava se já existia Order para a Quote e, se não, criava. **Duas transações simultâneas** (duplo clique no botão, ou dois usuários) passavam **juntas** pelo cheque de idempotência e nasciam **dois pedidos** — dois Z301 no SAP.

**Correção:** `SELECT Id FROM Quote WHERE Id = :quoteId FOR UPDATE` antes do cheque. O lock serializa as transações: a segunda espera a primeira commitar e aí o cheque de idempotência a vê e devolve o pedido existente. É o mecanismo oficial — *Locking Statements* do Apex Developer Guide:
<https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_locking_statements.htm>

### Furo 2 — Product2 duplicado na criação de material
`MaterialCreationService.upsertProducto` também era *query-then-insert* por ProductCode. Dois assessores criando o mesmo código ao mesmo tempo → dois Product2 do mesmo material (e o ProductCode padrão **não é único** no Salesforce).

**Correção em duas camadas:**
- Campo novo **`Product2.SapMaterialCode__c`** — Text(18) **único + External ID** (MATNR). A unicidade passa a ser garantida pela **base de dados**, não por código.
- `Database.upsert(producto, Product2.SapMaterialCode__c, false)` — o upsert por external ID é atômico; quem perde a corrida recebe DUPLICATE_VALUE e **reutiliza** o registro vencedor (re-query). Produtos legados da réplica (só ProductCode) são reutilizados e recebem *backfill* do código SAP.

### Furo 3 — sincronização de linhas concorrente
`RepuestosLineService.guardarLineas` lê as QuoteLineItems vigentes e calcula criar/atualizar/eliminar. Dois "Guardar" simultâneos na mesma cotização intercalavam os cálculos e **perdiam linhas**. Mesmo remédio: `FOR UPDATE` na Quote no início do método — os saves se serializam.

### O que já estava certo
- Idempotência do pedido por Quote (agora protegida pelo lock).
- Uma chamada massiva por lote na consulta de disponibilidade (não N chamadas).
- SAP como mestre do inventário — o componente nunca calcula stock.

### Alerta de plataforma (para quando o mock virar integração real)
`checkRepuestosAvailability` hoje é um callout **síncrono** (em mock). Com Mule real, cada consulta segura uma transação Apex durante o round-trip; o limite de **transações longas concorrentes** da org (Concurrent Long-Running Apex) vira risco com muitos assessores consultando ao mesmo tempo. A migração é conhecida e já tem padrão na base: **Continuation**, igual a `SapInventoryService.getPricesAndInventory`. Fica registrado como tarefa obrigatória do go-live da integração.

---

## 3. O fluxo guiado está bem construído? Avaliação honesta

**Pontos fortes (mantidos de propósito):**
- Padrão BFF: o LWC fala com **um** controller fino; toda regra vive na camada de serviço (reutilizável por Flow, batch, testes).
- Fachada `SapMuleClient` com mock determinístico — o front evolui sem esperar o contrato Mule; trocar mock→real é um flag.
- Continuation já implementada para preço/estoque de veículos.
- Suíte de testes verde (41 testes) que já pegou 3 bugs de produção + os 2 furos de concorrência desta revisão.

**Lacunas conhecidas (não tocadas antes da demo de quinta):**
- `getSelectionPageData` / `getPricePageData` / `searchVehicles` seguem como stubs (`Not implemented`) — o modal usa catálogo simulado; a integração da tela de seleção é o próximo passo do roadmap.
- Preço 0 placeholder nas PricebookEntries criadas pela US-021 — o preço real de repuestos vem do SAP na consulta (catálogo de preços é US-024/US-025).
- Venta Perdida trazada na cotização; modelo completo em US-040/US-057.

---

## 4. Conteúdo do pacote

| Componente | Mudança |
|---|---|
| `QuoteOrderService` | lock `FOR UPDATE` em `createOrderFromQuote` (anti pedido duplicado) |
| `RepuestosLineService` | lock `FOR UPDATE` em `guardarLineas` (saves serializados) |
| `MaterialCreationService` | upsert atômico por `SapMaterialCode__c` + reutilização/backfill de legados |
| `MaterialCreationServiceTest` | +2 testes: legado com backfill; busca do fluxo (`Test.setFixedSearchResults`) e regra dos 3 caracteres |
| `GuidedSellingController` | novo `searchMaterials` (cacheable — perna local; nota no código: ao cablear a perna SAP, deixa de ser cacheable ou vira Continuation) |
| `Product2.SapMaterialCode__c` | Text(18), único, External ID |
| `lineasRepuestos` (LWC) | busca com debounce + sugestões + "Solicitar creación" no miss; linha criada entra no grid e consulta disponibilidade |

**Deploy:** Workbench → migration → Deploy do zip (Single Package, Rollback on Error). Depois rodar `MaterialCreationServiceTest` — os testes existentes continuam valendo.

**Manifest mestre atualizado:** `retrieve/package-venta-guiada-completo.xml` (+ `Product2.SapMaterialCode__c`).
