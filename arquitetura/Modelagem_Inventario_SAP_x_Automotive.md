# Modelagem de referência — Inventário de veículos SAP → Salesforce Automotive Cloud (GrupoQ)

Versão 1.0 · 07/08/2026 · aplica a HU-045, HU-046, HU-119, sync de estoque (Flavio) e mapping MuleSoft.

## Princípio (uma frase)
**SAP é o livro-razão do inventário (quantidade, movimentos, bloqueios, contabilidade); Salesforce é a camada de engajamento (unidade individual, estado comercial, pipeline, relacionamento).** Nunca replicar o que pode ser consultado; replicar apenas a identidade e o estado comercial da unidade.

## Mapa SAP → Salesforce (o coração)

| Conceito SAP | Objeto/campo SAP | Salesforce | Chave |
|---|---|---|---|
| Sociedad | BUKRS (company code, ej. C101) | Account nível 3 da hierarquia | AccountNumber (visível) + SAPCode__c External ID (proposto) |
| Centro | WERKS (plant) | — (repete entre sucursais; ex. C011 = todas as C101) | usado SOZINHO só na interface de reserva SAP (confirmado Luis Chavarría 04/06) |
| **Sucursal/patio** | **WERKS+LGORT (composto, ex. C0111200)** | **Account dealer (nível 4) — AccountNumber = composto** | "la llave que identifica el patio"; um patio pode servir 2 sucursais QRM (Lindora+Santa Ana; Uruca+Flotas) → composto NÃO é único entre contas |
| Almacén | LGORT (storage location) | Location (Asset.LocationId) — consignação/T09 | nome/código; de-para completo em integracion/data/sucursales_qrm_completo.csv (596 linhas, todos os países) |
| Material veículo (modelo) | MATNR configurável (MARA) | Product2 → VehicleDefinition (→ BusinessBrand) | ProductCode/MATNR |
| **Unidade física (VIN)** | **VLCVEHICLE (SAP VMS)**: VIN, plant, storage loc., customer | **Par Vehicle + Asset** (master-detail, obrigatório) | **VIN (unique na org)** |
| Nº inventário SAP | nº interno VMS | Vehicle.StockCode | por VIN |
| Dono contábil da unidade | sociedad do estoque | **Asset.AccountId = Account da sociedade** | via código sociedad |
| Posse operacional | centro/dealer | **Vehicle.CurrentOwnerId = Account do dealer** | via código centro |
| Cliente comprador | KUNNR / end customer | transferência: CurrentOwnerId → Account do cliente; histórico em AssetAccountParticipant | — |
| Stock/movimentos/traslados/bloqueios | MM (MARD/MSEG), VMS actions (VELO) | **NÃO replicar** — fica no SAP; SF reflete só Vehicle.Status comercial | — |
| Preço | listas/condições (HU-028) | **NÃO replicar** — RFC on-line (Get_Price_ZGQREF) | — |
| Km | — (não vem do SAP) | Vehicle.LastOdometerReading (capturado em SF, RN2 HU-045) | — |

## Regras de arquitetura (as 6 que não se negociam)
1. **VIN é a identidade** — unique na org; re-ingresso ATUALIZA o mesmo Vehicle (D2 HU-045); o truque do ponto no VIN existe SÓ no SAP.
2. **Todo Vehicle nasce com o par completo**: Asset (AccountId = sociedade, LocationId = almacén, PurchaseDate) + CurrentOwnerId = dealer. O payload precisa dos DOIS códigos (sociedad + centro).
3. **Chaves externas, nunca Ids**: lookups resolvidos por External ID no upsert (`Asset.Account.SAPCode__c = 'C101'`) — zero prefetch, sobrevive a sandbox→prod.
4. **Batch = Bulk API 2.0 com upsert idempotente** (Vehicle por VIN); tempo-real SF→SAP = platform event (padrão RegisterUsedVehicleEvent__e / SapOrderResponse__e, sem callout síncrono em flow).
5. **Estado comercial mora num único campo** (Vehicle.Status) com máquina de estados documentada — 4 atores hoje: HU-046 (demo/exh), HU-045 (consignación), test drive (disponibilidade), oficina (reparación).
6. **Catálogo (modelos) via IDoc MATMAS/accelerator MuleSoft**; unidades via VMS; preços on-line. Três fluxos distintos, três cadências distintas.

## Como a indústria faz (padrão dealer groups)
- ERP/DMS (SAP VMS, CDK, Tekion) = system of record do inventário e da contabilidade; CRM = camada de venda/relacionamento com o ESPELHO mínimo da unidade. Exatamente o texto da HU-045: "el stock, los movimientos, traslados y bloqueos residen en SAP; Salesforce registra y visualiza la unidad y su estado comercial".
- SAP VMS: VLCVEHICLE carrega VIN + plant + storage location + customer — validação de que o payload do estoque TEM os códigos que precisamos (centro e almacén vêm na própria tabela de veículos).
- MuleSoft Automotive accelerator: product sync bidirecional (MATMAS), quote-to-cash — base já citada na arquitetura HU-028/039.

## Fontes
- SAP VMS: help.sap.com "Vehicle Management System (IS-A-VMS)"; SAP Learning "Vehicle Sales Management"; SAP Community "Comprehensive Guideline to SAP VMS" (VLCVEHICLE).
- Salesforce: Automotive Cloud Developer Guide (Vehicle/Asset/VehicleDefinition, sforce_api_objects_vehicle), Data Model Gallery (Automotive, Vehicle & Asset Appraisals), Trailhead "Connect Customer and Vehicle Data".
