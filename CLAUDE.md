# Contexto permanente — GrupoQ · Automotive Cloud (Diego Beltrão)

**Memória de trabalho: `STATUS.md`** (fonte da verdade das sessões — ler SEMPRE primeiro). Este arquivo guarda só o mapa estável da org.

## O FLUXO DE VENDAS GUIADO ("Venta Guiada") — NÃO é OmniScript, NÃO é Flow
Suíte **LWC + Apex custom**, disparada da Opportunity via Quick Action `Opportunity.VentaGuiadaModal`:
- **LWCs**: `ventaGuiadaLauncher` → `ventaGuiadaModal` (router por RecordType.DeveloperName: Autos/Motos=nuevo, Usados=usado, RepuestosPA=repuestos; Flotas=R2 comentado; Mayorista pendente) → `ventaVehiculo` / `ventaUsados` / `contraventaRepuestos` / `ventaPA` + `aprobacionDescuentoModal`, `cotizacionConfirmModal`.
- **Apex**: `GuidedSellingController` + serviços `SapInventoryService`, `PricingService`, `QuoteOrderService`, `SapOrderService`, `MaterialSearchService`, `FinancingService` (+ Tests, `VentasTestDataFactory`, `SapCalloutMockFactory`).
- **Integração**: gateway único MuleSoft — Named Credential `MuleGateway` + External Credential `MuleSoft_EC` + PS `PS_Mule_Integration`; retorno assíncrono via platform event `SapOrderResponse__e`.
- **Config**: `CountryCurrency__mdt` (moedas por país) + VR `Opportunity.Currency_Matches_Country`; `RequestedParts__c` em Lead/Opportunity (form web → lead → opp).
- **RecordTypes**: Opportunity `GQOpportunitiesAutos` / `GQOpportunitiesMotos` / `GQOpportunitiesUsados` / `GQOpportunitiesRepuestosPA`; Lead `GQLeadsRepuestosPA`.
- Manifest de retrieve: `deploy/retrieve_venta_guiada/package.xml`. Qualquer HU de inventário/pricing/pedido PLUGA nesta suíte (evoluir serviço existente), não cria tela paralela.

## Padrões imutáveis da org
- **OmniStudio existe e é usado** (família GrupoQ: CrearCotizacion OmniScript, LeadDedup/LeadUpsert/CustomerSearch IPs; GQAutoCloudScheduler test drive) — mas a jornada de VENDA é a suíte LWC acima. Padrão híbrido: LWC/Apex p/ venda guiada, OmniScript p/ jornadas específicas, Flow p/ automação de registro e telas back-office (HU-046).
- **Modelo de veículo**: unidade = par Vehicle+Asset; identidade = `Vehicle.VehicleIdentificationNumber` (unique); estado comercial = `Vehicle.Status` (máquina única: En ubicación de concesionario → En demostración/En exhibicion → Demo venta...); Vehicle NÃO tem OwnerId; SerializedProduct/ProductItem FORA do modelo (Field Service, PSL extra). Posse: `Asset.AccountId` = sociedade, `Vehicle.CurrentOwnerId` = dealer.
- **Hierarquia de Accounts (4 níveis via ParentId)**: Holding → país → sociedade (C101/C105/N105) → dealer. Três mecanismos complementares: ParentId = posição; **BusinessProfile SÓ nos dealers** (BusinessPartnerType=Sales Dealer; sociedades não têm — são entidades contábeis); **Sociedad__c no dealer** = pertencimento consultável em 1 nível (dealers CR carregam C101 ou C105; a "sucursal física" pode ter pé nas duas sociedades, ex. Liberia). AccountLevel__c materializa o nível (SOQL não navega profundidade). Listagem de sociedades p/ integração: filhas da conta-país (ParentId indexado) hoje; RT GQEstructura + AccountLevel quando criados (fix5). CMDT p/ sociedades foi DESCARTADO (inventário associa a dados).
- **Código de sucursal SAP = composto Centro+Almacén** (WERKS+LGORT, ex. C0111200) — validado pelo cliente; centro sozinho não é único; composto compartilhável entre 2 sucursais QRM. De-para mestre: `integracion/data/sucursales_qrm_completo.csv`.
- **Cargas SAP**: upsert por VIN; status inicial "En ubicación de concesionario"; update NUNCA sobrescreve Vehicle.Status; SAP = razão do estoque, SF = estado comercial.
- **Gates HU-025** (VR `Opp_Retail_Vehiculo_Cotizacion`): Cotización Confirmada exige OLI (nível modelo); Reserva Confirmada exige `Vehiculo__c` (unidade). Bypass padrão org: `Bypass_Gates_Automacao`.
- **HU-046 (pronta, ver STATUS)**: cupos CMDT, telas Flow, guarda `OpportunityBeforeHandler` v4.1 (exceção do asesor via Task "[Demo] Asignación" com vencimento em tempo real), scheduled housekeeping.
- Deploys: sempre rollbackOnError (sucessos parciais são revertidos); deploy de flow nunca ativa; PS description ≤255; escopo rollout = **Costa Rica** (C101/C105).
- Regras de trabalho: registrar TUDO no STATUS.md + commit/push a cada marco; conversas pessoais/liderança FORA do repo; docs Salesforce dão 403 no proxy — pedir ao Diego para colar.
