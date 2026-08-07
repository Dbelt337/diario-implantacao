# HU-047 · Inventario y Disponibilidad — Cobertura técnica (v1, 07/08/2026)

Pesquisado contra: Automotive Cloud dev guide/help (Vehicle Inventory Search, CBSF, inventory objects), object reference, APIs SAP S/4HANA de disponibilidade, e padrões da indústria automotiva. Fontes no rodapé (as bloqueadas pelo proxy estão marcadas — pedir os textos ao Diego).

## 0. A leitura estrutural (RN-02 divide a HU em DUAS arquiteturas)

| | Autos & Motos | Repuestos & PA |
|---|---|---|
| Modelo | **Réplica batch** SAP→SF a cada 15 min; a tela lê o dado replicado | **Consulta on-line** contra SAP via MuleSoft no momento do uso; nada replicado |
| Objeto de verdade em SF | Par **Vehicle+Asset** (modelo HU-046/carga já definido) | Nenhum — resposta transitória do serviço, renderizada na tela |
| Busca | **Vehicle Inventory Search nativo (CBSF / `VehicleSearchableField`)** | LWC de consulta única chamando o Serviço B |
| Momento da verdade | Marca de tempo do último ciclo (RN-03) | A própria chamada (e ATP no compromisso, RN-14/15) |

## 1. AUTOS & MOTOS

### 1.1 Réplica (15 min, por sociedade)
- **MuleSoft + Bulk API 2.0, upsert por `VehicleIdentificationNumber`** — exatamente o pipeline do modelo de cargas já desenhado (Modelagem_Inventario_SAP_x_Automotive.md). A HU-047 acrescenta a **frequência** (15 min por sociedade, ponto aberto #1) e o conjunto de atributos.
- **Atributos SAP sem casa standard → campos custom no Vehicle/Asset** (aqui campos custom são LEGÍTIMOS — é dado replicado, não estado comercial): estado de venta SAP (`SapSaleStatus__c`), estado de compra (`SapPurchaseStatus__c`), estado de nacionalización (`SapCustomsStatus__c`), fecha estimada de arribo (`EstimatedArrivalDate__c`), fecha de ingreso (`InventoryEntryDate__c` — base da antigüedad), condición de tránsito (`TransitStatus__c`), paquete (`PackageCode__c`). Já têm casa standard: chasis (`ChassisNumber`), motor (`EngineNumber`), nº inventario (`StockCode`), cores (`ExteriorColor`/`InteriorColor`), combustível/tração (VehicleDefinition), ubicación (composto centro+almacén → `Asset.LocationId`/CurrentOwner), asesor asignado (Task HU-046).
- **REGRA CRÍTICA DE CONVIVÊNCIA com a HU-046**: o "estado de venta" do SAP chega em **campo próprio** (`SapSaleStatus__c`), NUNCA em `Vehicle.Status` — o Status continua sendo a máquina de estados comercial do Salesforce (demo/exhibición/liberación) e a carga não o sobrescreve (regra já registrada 07/08). A reservabilidade (1.3) é quem combina os dois mundos.
- **Marca de tempo (RN-03)**: campo `LastSyncAt__c` no Vehicle (por unidade, atualizado no upsert) + 1 registro de controle por sociedade (objeto simples `SyncRun__c` ou custom setting) com status do ciclo — é o que alimenta a advertência do Esc.14 (ciclo falhou → tela mostra o último timestamp + aviso).

### 1.2 Busca e apresentação — NATIVO, não construir tela própria
- **Vehicle Inventory Search / Criteria-Based Search and Filter (CBSF)** é feature nativa do Automotive Cloud: monta-se uma **Search Criteria Configuration** sobre `VehicleSearchableField`, que combina campos de Vehicle/Asset/VehicleDefinition/Product2 num dataset pesquisável; configura-se quais campos são critério, quais aparecem no resultado, ordenação e agregação. Cobre os filtros do alcance (marca, modelo, versión, año, cores, combustible, tracción, estado, ubicación...) por configuração.
- É o MESMO componente do T01 da HU-046 (filtro de venda excluindo demo/exh) — uma única configuração serve às duas HUs; o esforço é setup + incluir os campos custom novos no dataset.
- Motos: segunda configuração (ou filtro por sucursal do documento) com o mesmo motor.

### 1.3 Reservabilidade (RN-05) — calculada em SF, parametrizada em CMDT
- Padrão HU-046 repetido: **CMDT `ReservabilityConfig__mdt`** por sociedad(+marca/modelo opcional) dizendo quais **ubicaciones** e quais **estados** (SapSaleStatus, Status comercial) permitem reserva. Administrável sem deploy (registro de CMDT via Setup).
- A condição por unidade é **derivável em fórmula/flow** na seleção: reservable = ubicación permitida ∧ SapSaleStatus permitido ∧ Vehicle.Status ∉ {demo, exhibición} ∧ sem asignación a outro asesor (Task "[Demo] Asignación" aberta de OUTRO user — motor da HU-046 reutilizado) ∧ sem reserva de gerencia (estado/flag da HU de reserva) ∧ sem traslado abierto (`TransitStatus__c`). Cada perna gera o **motivo** exigido pela RN-05.
- Sinergia total com a HU-046: "asignada a otro asesor" e "en demo/exhibición" já EXISTEM como dados (Status + Task) — a HU-047 só os apresenta.

### 1.4 Notificações na seleção (RN-06) e antigüedad
- Momento "selecionar unidade" = screen flow/LWC da cotización: 3 checagens síncronas — antigüedad >150 días (`TODAY() - InventoryEntryDate__c`), ubicación não reservável (1.3), en exhibición → mensagem "solicite liberación al gerente" (aponta pro circuito HU-046).

### 1.5 Refresh a demanda (RN-03/Esc.2, ponto aberto #2)
- Quick Action/botão na unidade → flow invoca MuleSoft (endpoint single-VIN) → SAP responde → upsert daquele Vehicle + `LastSyncAt__c`. Permissão via custom permission (mesmo padrão RequestDemoVehicle) para os perfis que o negócio autorizar.
- Alternativa sem callout de flow (padrão org: sem callout síncrono em flow): platform event de solicitação + subscriber MuleSoft + atualização assíncrona com refresh da tela — decidir com o Flavio conforme o SLA da resposta.

### 1.6 Alternativas e continuidade
- **Autos (RN-08)**: consulta sobre o inventário replicado — marca dentro da sociedad, TODAS as ubicaciones (sucursal, almacén fiscal, tránsito, producción), ordenada por `EstimatedArrivalDate__c` ASC. É um segundo resultado do MESMO dataset CBSF (ou SOQL do flow) — sem serviço novo.
- **Motos (RN-09)**: mesma consulta acotada à sucursal do documento + disponibilidade física; unidades de outra sucursal/tránsito visualmente distintas (coluna/badge no resultado).
- **Continuar sem unidade (Esc.5)**: já suportado pelo desenho HU-025/046 — Opportunity RT Autos vive sem `Vehiculo__c` até a Reserva Confirmada (a VR só exige na reserva); + Task de seguimiento agendada (padrão LogDemoActivity).
- **Asignación manual con motivo (RN-10/Esc.8)**: tela pede motivo → Task de traza na unidade (padrão HU-046); nenhuma automação escolhe unidade sozinha.

## 2. REPUESTOS & PA (on-line, sem réplica)

### 2.1 Serviço B — consulta multi-material
- **Uma chamada MuleSoft multi-material por documento** (RN-18 — mesma restrição de 100 callouts/transação da HU-028 pricing; padrão idêntico ao Get_Price: request com lista de materiais, response com tudo).
- Lado SAP, as **duas APIs oficiais** casam com a RN-14:
  - **`API_PRODUCT_AVAILY_INFO`** (S/4HANA 2022+) — "Product Availability Info": informação de disponibilidade SEM simular compromisso → é a **consulta rápida/multiestado/multisucursal** (informativa, não autoriza).
  - **`API_AVAIL_TO_PROMISE_CHECK`** (S/4HANA 2023+, OData V4, aATP) — simula "quanto EU conseguiria?" → é o **ATP do compromisso** (RN-15), única fonte que autoriza a linha. (Se a versão do SAP do GrupoQ for ECC/anterior, o equivalente é função Z sobre `BAPI_MATERIAL_AVAILABILITY` — validar com o time SAP qual stack está disponível; ponto aberto #4 da HU já cobra isso.)
- Desglose em 5 componentes (piso/reservado/tránsito/aduana/bloqueado) + cadeia de sucessão/equivalentes: vêm no payload do serviço (premissa da HU: residem no SAP e se expõem por integração) — Salesforce só renderiza.

### 2.2 Tela única (RN-11)
- **LWC** de consulta (não flow — precisa de grid multi-nível, badges de 4 estados, expandir detalhe de reserva/tránsito numa tela só): chama o Serviço B via Apex `@AuraEnabled` com `Continuation` (callout assíncrono, não bloqueia) — aqui HÁ Apex, e é o lugar certo dele (UI + callout composto; flows não fazem isso bem). Timeout explícito → estado "falla de integración" (RN-19): sem saldos, sem confirmar linha.
- Embutida em: consulta rápida (tab), cotización e pedido (mesmo componente, contexto por record page).
- Material inexistente no SAP → CTA "solicitar creación" disparando o mecanismo da HU-039 (já desenhado: platform event → MuleSoft → worklist SAP).

### 2.3 ATP na linha (RN-15) e alternativas (RN-16)
- Trigger: criar/alterar linha com quantidade → chamada ATP multi-material → resposta comprometible por item → se insuficiente, modal com solicitada/comprometible/faltante + alternativas ANTES de qualquer exclusão. Venta Perdida NÃO se registra aqui (fica na HU de linhas; ponto único = SAP).
- Alternativas: o serviço devolve sucessores/equivalentes com existência; a opção de abastecimento (traslado/intercompany/pedido a fábrica) é derivada do estado (RN-13) + **matriz de restrições de traslado parametrizada** — recomendo CMDT `TransferRestriction__mdt` (origem→destino permitido, incl. aduaneiras), consumida na montagem das opções (ponto aberto #5 pede a matriz ao cliente).

## 3. Respostas propostas aos PONTOS ABERTOS da HU

| # | Pergunta | Recomendação |
|---|---|---|
| 1 | 15 min todas as sociedades? | Escopo CR: só C101/C105. 15 min é viável com Bulk upsert por VIN; delta por timestamp SAP reduz volume |
| 2 | Refresh a demanda? | Sim, com custom permission dedicada (perfis gerência/asesor sênior); implementação conforme SLA (síncrono LWC ou evento) |
| 3 | Ubicaciones visíveis? | **Sincronizar TODAS incl. demo/exhibición/taller como "no reservables"** — coerente com Esc.10 da HU-046 ("visible pero no vendible") e com a RN-04 da própria HU-047 |
| 4 | ATP devolvido ou calculado? | **Devolvido pelo SAP** (aATP API / função Z) — Salesforce nunca calcula ATP (violaria RN-01, SAP é a verdade) |
| 5 | Matriz de traslados? | Pedir ao cliente; guardar como CMDT `TransferRestriction__mdt` |
| 6 | Motos sem stock: traslado? | R1: só informar + alternativas da sucursal (premissa: traslado entre países é manual; traslado nacional de motos → validar, mas o texto aponta que NÃO se oferece como equivalente) |
| 7 | Perfis da asignación manual? | Mesmos PS da HU-046 (Management) + motivo obrigatório em picklist (definir valores com o negócio) |

## 4. Como a indústria faz (referências de padrão)
- **Dealer groups**: DMS/ERP é o system of record do estoque; o CRM mostra o espelho com "aging" (dias em estoque), status pipeline (**in production / in transit / at port-customs / at dealer**) e ETA — exatamente os atributos do alcance Autos. Ferramentas de "locate/dealer trade" (vAuto, OEM locators) fazem a "oferta de alternativas" buscando na rede da marca — o RN-08 é a versão intra-sociedad disso.
- **SAP VMS** (nosso caso): a disponibilidade de veículos nasce das ações VMS sobre `VLCVEHICLE`; réplica periódica + refresh pontual é o padrão de integração recomendado (accelerator MuleSoft Automotive: product/inventory sync).
- **ATP em peças**: padrão universal two-step — consulta informativa barata em lista + ATP transacional no compromisso (é literalmente o par de APIs S/4HANA acima). Cotización não reserva (RN-07) é o comportamento default do aATP.

## 5. Fontes
**Acessadas (via busca):**
- Set Up Vehicle Inventory Search in Automotive Cloud (help.salesforce.com, auto_search_configure_parent)
- Create a Search Criteria Configuration for Vehicle Inventory (auto_search_setupconfigure...)
- How Does Vehicle Inventory Search Work / How Criteria-Based Search and Filter Works (help)
- VehicleSearchableField — Automotive Cloud Developer Guide (API 58+)
- SAP: Two APIs to Retrieve Availability Information (SAP Community, API_PRODUCT_AVAILY_INFO vs API_AVAIL_TO_PROMISE_CHECK); SAP Learning — Running an ATP Check in S/4HANA Sales

**Bloqueadas pelo proxy (403) — PEDIR AO DIEGO para colar o conteúdo:**
1. https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/inventory_dev.htm ("Inventory Objects in Automotive Cloud" — confirmar a lista completa de objetos de inventário e se há algo novo além de VehicleSearchableField)
2. https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehiclesearchablefield.htm (campos do VehicleSearchableField)
3. https://help.salesforce.com/s/articleView?id=release-notes.rn_auto_objects.htm ("New and Changed Objects for Automotive Cloud" — releases recentes)
