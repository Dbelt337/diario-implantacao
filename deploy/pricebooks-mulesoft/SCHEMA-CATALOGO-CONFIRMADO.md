# Schema do catálogo — confirmado via describe (org GrupoQ)

Resultado do `DESCRIBE-catalogo.apex`. Trava o de-para (`DePara_Catalogo_Mule.xlsx`).

## Cadeia de dependência (define a ordem de carga)
```
ProductCatalog -> ProductCategory (CatalogId obrig)
BusinessBrand
Product2  (ANCORA)
   └─ VehicleDefinition  (ProductId OBRIG -> Product2)
   └─ PricebookEntry     (Product2Id + Pricebook2Id OBRIG)
   └─ ProductItem        (Product2Id + LocationId + QuantityOnHand OBRIG)
Location  (Name + LocationType OBRIG)
Asset     (pré-requisito do Vehicle)
Vehicle   (AssetId + VehicleDefinitionId + VehicleIdentificationNumber OBRIG)
SerializedProduct (Product2Id + SerialNumber OBRIG)
```

## Descobertas-chave
1. **Preço: os campos custom do QRM JÁ EXISTEM no PricebookEntry** — não criar:
   `PrecioExonerado__c`, `PrecioExoneradoMinimo__c`, `PrecioMinimoAsesor__c`,
   `Gastos__c`, `AplicaCashback__c`, `MontoCashback__c`, `VigenciaDesde__c`.
2. **Product2 carrega as specs do veículo**: `MakeName`, `ModelName`, `ModelYear`,
   `ModelYearVersion`, `VehicleTrimLevel`, `BusinessBrandId`, `ProductCode`,
   `IsSerialized`, `ProductLineCode`, `ProductCategoryCode`.
3. **VehicleDefinition é enxuto e EXIGE `ProductId` (Product2)**: `Name`,
   `VehicleClass`, `ModelCode`, `EngineName`, `EngineCubicCapacity` (**STRING**),
   `GeoCountryId`.
4. **Vehicle EXIGE `AssetId` + `VehicleDefinitionId` + `VehicleIdentificationNumber`**.
   Tem `ExtlSystemVehicleIdentifier` (chave externa SAP), `MarketPrice`,
   `ConditionType`, `VehicleRegistrationNumber`, `StockCode`, `CurrentOwnerId`.
5. **ProductCatalog e ProductCategory ESTÃO disponíveis** (mesmo sem EPC) —
   podem agrupar as linhas.
6. **Inventário**: `ProductItem` (LocationId + Product2Id + QuantityOnHand obrig,
   + QuantityAllocated/Available); `SerializedProduct` (Product2Id + SerialNumber).
7. **Chave de match**: `Product2.ProductCode` = material SAP → marcar External Id.

## A confirmar ainda
- Campos obrigatórios de **Asset** (rodar describe de Asset se for usar Vehicle).
- Novos entram como `ProductItem`/`SerializedProduct` (estoque) e usados como
  `Vehicle`+`Asset` (VIN individual)? (decidir com o negócio/agenda).
- `GeoCountryId`: confirmar o registro de GeoCountry para CR.
