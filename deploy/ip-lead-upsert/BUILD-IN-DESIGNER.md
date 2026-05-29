# Build no OmniStudio Designer — IP de criar Lead (GrupoQ)

> Por que aqui e não MDAPI manual: o retrieve da org mostrou que Data Mappers são
> gravados como `omniDataTransforms/<Nome>_<versão>.rpt`, com Ids de servidor
> (`omniDataTransformationId`) e `globalKey` (UUID) por item — gerados pela
> plataforma. E não há nenhum `OmniProcess` na org para servir de molde. Montar no
> Designer garante o formato válido. Depois é só **Retrieve** (com o
> `retrieve-package.xml`) para versionar no git no formato correto.

Contrato de entrada da IP (JSON que o canal externo envia):

```json
{
  "lead": {
    "firstName": "Juan", "lastName": "Perez", "email": "juan@x.com",
    "phone": "+50688887777", "company": "Persona Fisica",
    "leadSource": "WEB_FORLAND_LURUCA", "country": "CR",
    "industry": "Automotive", "description": "Interesado en Forland T3",
    "nationalId": "123456789", "linhaNegocio": "Autos"
  },
  "externalRequestId": "550e8400-e29b-41d4-a716-446655440000",
  "channelCode": "MULESOFT_FB",
  "lineItems": [ { "productCode": "FORLAND-T3-2026", "quantity": 1, "vehicleConditionPicklist": "New" } ],
  "preferredSellers": [ { "dealerCode": "C105-LURUCA-FORLAND", "preferredSellerType": "Dealer" } ]
}
```

Regra de nomes (OmniStudio Metadata habilitado): **sem underscore** no Name/Type/SubType.

---

## 1. Data Mappers (Data Mapper Designer → New)

### 1.1 `DRLeadGetByExternalRequestId` — Tipo **Extract**
- **Extraction Object:** `Lead`  ·  **Extract Output Path:** `existingLead`
- **Filtro:** `ExternalRequestId__c`  `Equals`  valor `externalRequestId`
- **Output (Field Mapping):**
  | Campo Lead | Output JSON |
  |---|---|
  | `Id` | `existingLead:Id` |
  | `CreatedDate` | `existingLead:CreatedDate` |
  | `ChannelCode__c` | `existingLead:ChannelCode__c` |
- Preview Input: `{ "externalRequestId": "550e8400-..." }`

### 1.2 `DRBusinessProfileGetByCode` — Tipo **Extract**
- **Extraction Object:** `BusinessProfile`  ·  **Output Path:** `dealer`
- **Filtro:** `ExternalReferenceNumber`  `Equals`  valor `dealerCode`
- **Output:**
  | Campo BusinessProfile | Output JSON |
  |---|---|
  | `AccountId` | `resolvedAccountId` |
  | `Account.Name` | `resolvedDealerName` |
  | `BusinessPartnerCode` | `resolvedBusinessPartnerCode` |
- Preview Input: `{ "dealerCode": "C105-LURUCA-FORLAND" }`

### 1.3 `DRLeadInsert` — Tipo **Load**
- **Output Object:** `Lead` (Output Path sugerido `insertedLead`)
- **Mapeamento (Input JSON → Campo Lead):**
  | Input JSON | Campo Lead |
  |---|---|
  | `lead:firstName` | `FirstName` |
  | `lead:lastName` | `LastName` *(obrigatório)* |
  | `lead:email` | `Email` |
  | `lead:phone` | `Phone` |
  | `lead:company` | `Company` *(obrigatório)* |
  | `lead:leadSource` | `LeadSource` *(obrigatório)* |
  | `lead:country` | `Country` |
  | `lead:industry` | `Industry` |
  | `lead:description` | `Description` |
  | `lead:nationalId` | `NationalId__c` |
  | `lead:linhaNegocio` | `LinhaNegocio__c` |
  | `externalRequestId` | `ExternalRequestId__c` |
  | `channelCode` | `ChannelCode__c` |
- **Não** mapear `Sociedad__c` (derivado pelo Flow Before-Save `Lead_BS_DeriveSociedad`).
- Garanta que o output devolve o `Id` criado (`insertedLead:Id`).

### 1.4 `DRLeadLineItemInsert` — Tipo **Load** (lista)
- **Output Object:** `LeadLineItem`  ·  Input list path: `lineItems`
- **Mapeamento (por item de `lineItems`):**
  | Input JSON | Campo LeadLineItem |
  |---|---|
  | `leadId` | `LeadId` *(obrigatório)* |
  | `lineItems:productCode` | `ProductId` via **lookup** em `Product2.ProductCode` |
  | `lineItems:quantity` | `Quantity` |
  | `lineItems:vehicleConditionPicklist` | `VehicleConditionPicklist` |
- Output: `insertedLineItems` (lista de Ids).

### 1.5 `DRLeadPreferredSellerInsert` — Tipo **Load** (lista)
- **Output Object:** `LeadPreferredSeller`  ·  Input list path: `preferredSellers`
- **Mapeamento:**
  | Input JSON | Campo LeadPreferredSeller |
  |---|---|
  | `leadId` | `LeadId` *(obrigatório)* |
  | `resolvedAccountId` | `AccountId` |
  | `preferredSellers:preferredSellerType` | `PreferredSellerType` |
- Output: `insertedPreferredSellers`.

> **Ative** cada Data Mapper após salvar.

---

## 2. Integration Procedure (Integration Procedure Designer → New)

- **Type:** `GrupoQ`  ·  **SubType:** `LeadUpsert`  (sem underscore nos campos)
- Procedure Configuration: **Rollback on Error = true**.

Elementos, na ordem:

| # | Elemento | Tipo | Configuração |
|---|---|---|---|
| 1 | `ValidateRequiredFields` | **Set Values** | `isValid` = `=AND(NOT(ISBLANK(%lead:lastName%)),NOT(ISBLANK(%lead:company%)),NOT(ISBLANK(%lead:leadSource%)),NOT(ISBLANK(%externalRequestId%)),NOT(ISBLANK(%channelCode%)))` · `missingFields` = concat dos campos vazios |
| 2 | `ValidationFailed` | **Conditional Block** | Condição: `%ValidateRequiredFields:isValid% == false` |
| 2a | `ValidationErrorResponse` | **Response Action** (dentro de 2) | JSON: `status=error`, `errorCode=VALIDATION_FAILED`, `errorMessage` com `%ValidateRequiredFields:missingFields%` |
| 3 | `GetByExternalRequestId` | **DataRaptor Extract Action** | Bundle: `DRLeadGetByExternalRequestId` · Input `externalRequestId` = `%externalRequestId%` · Condição: `%ValidateRequiredFields:isValid% == true` |
| 4 | `IsDuplicate` | **Conditional Block** | Condição: `%GetByExternalRequestId:existingLead:Id% != null` |
| 4a | `DuplicateResponse` | **Response Action** (dentro de 4) | JSON: `status=duplicate`, `duplicateLeadId=%GetByExternalRequestId:existingLead:Id%` |
| 5 | `CreateLead` | **Conditional Block** | Condição: `%ValidateRequiredFields:isValid% == true AND %GetByExternalRequestId:existingLead:Id% == null` |
| 5a | `BusinessProfileExtract` | **DataRaptor Extract Action** (em 5) | Bundle: `DRBusinessProfileGetByCode` · Input `dealerCode` = `%preferredSellers:0:dealerCode%` · Condição: `COUNT(%preferredSellers%) > 0` |
| 5b | `LeadInsert` | **DataRaptor Post Action** (em 5) | Bundle: `DRLeadInsert` · Input: `lead=%lead%`, `externalRequestId=%externalRequestId%`, `channelCode=%channelCode%` |
| 5c | `LineItemInsert` | **DataRaptor Post Action** (em 5) | Bundle: `DRLeadLineItemInsert` · Input: `leadId=%LeadInsert:insertedLead:Id%`, `lineItems=%lineItems%` · Condição: `COUNT(%lineItems%) > 0` |
| 5d | `PreferredSellerInsert` | **DataRaptor Post Action** (em 5) | Bundle: `DRLeadPreferredSellerInsert` · Input: `leadId=%LeadInsert:insertedLead:Id%`, `resolvedAccountId=%BusinessProfileExtract:resolvedAccountId%`, `preferredSellers=%preferredSellers%` · Condição: `COUNT(%preferredSellers%) > 0` |
| 5e | `SuccessResponse` | **Response Action** (em 5) | JSON: `status=success`, `leadId=%LeadInsert:insertedLead:Id%`, `externalRequestId=%externalRequestId%`, `isDuplicate=false` |

> Os 3 Conditional Blocks são mutuamente exclusivos → exatamente uma Response Action
> dispara por execução. **Ative** a IP ao final.

Endpoint REST nativo (sem Apex):
`POST /services/apexrest/omnistudio/v1/integrationprocedure/GrupoQ_LeadUpsert/`

---

## 3. Versionar no git depois de pronto

1. Workbench → Migration → **Retrieve** com o `retrieve-package.xml` (já inclui
   `OmniDataTransform` e `OmniProcess` wildcard).
2. Baixar o ZIP e commitar o conteúdo (`omniDataTransforms/*.rpt` e
   `omniProcesses/*`) — aí teremos o formato real, válido para futuros deploys.
