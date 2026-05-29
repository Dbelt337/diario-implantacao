# IP_Lead_Upsert — GrupoQ Sales Automotive

Integration Procedure (OmniStudio Standard Runtime) para criação/upsert de Leads
vindos de canais externos (MuleSoft, formulários web, etc.).

## Conteúdo do pacote

| Componente | Tipo | Papel |
|---|---|---|
| `GrupoQ_LeadUpsert` | OmniProcess (Integration Procedure) | Orquestra validação → idempotência → criação → resposta |
| `DR_Lead_GetByExternalRequestId` | OmniDataTransform (Extract) | Idempotência por `ExternalRequestId__c` |
| `DR_BusinessProfile_GetByCode` | OmniDataTransform (Extract) | Resolve `AccountId` do dealer pelo `dealerCode` |
| `DR_Lead_Insert` | OmniDataTransform (Load) | Insere o Lead |
| `DR_LeadLineItem_Insert` | OmniDataTransform (Load) | Insere os `LeadLineItem` |
| `DR_LeadPreferredSeller_Insert` | OmniDataTransform (Load) | Insere os `LeadPreferredSeller` |
| `Lead.object` | CustomField | Campos novos: `ExternalRequestId__c`, `ChannelCode__c`, `NationalId__c` |

Endpoint REST nativo (sem Apex):
`POST /services/apexrest/omnistudio/v1/integrationprocedure/GrupoQ_LeadUpsert/`

## Fluxo declarativo

```
[0,1] SV_ValidateRequiredFields      -> isValid + missingFields
[0,2] CB_ValidationFailed            isValid == false        -> RA_ValidationErrorResponse
[0,3] DR_Lead_GetByExternalRequestId só roda se isValid == true
[0,4] CB_IsDuplicate                 existingLead.Id != null -> RA_DuplicateResponse
[0,5] CB_CreateLead                  isValid && sem duplicado
        -> DR_BusinessProfile_Extract -> DPA_Lead_Insert
        -> DPA_LeadLineItem_Insert -> DPA_LeadPreferredSeller_Insert
        -> RA_SuccessResponse
```

Os Conditional Blocks são mutuamente exclusivos: exatamente uma Response Action
dispara por execução.

## Deploy (Workbench / Metadata API)

1. **Deploy em Check-Only** primeiro (Single Package + Rollback On Error).
2. O erro anterior "OmniDataTransform ... was not found in zipped directory" ocorreu
   porque um zip sem a pasta `omniDataTransforms/` foi enviado. Este pacote já inclui
   os 5 `.omniDataTransform`, então esse erro não deve reaparecer.
3. Após o deploy, abrir o `GrupoQ_LeadUpsert` uma vez no OmniStudio Designer para
   recompilar/normalizar o `propertySetConfig` e então **ativar** a versão
   (`isActive` está `false` no metadado).

## Pontos a confirmar na org de destino (DevSales)

- **OmniStudio com Standard Runtime habilitado** (sem namespace `vlocity_cmt`).
- `fullName` do OmniProcess: o canônico costuma ser `Type_SubType_Language`
  (`GrupoQ_LeadUpsert_Procedure`). Aqui o member segue `GrupoQ_LeadUpsert`. Se o
  Check-Only acusar mismatch de fullName, ajustar o `<members>` no `package.xml`.
- Objetos standard do Automotive Cloud: `BusinessProfile`, `LeadLineItem`,
  `LeadPreferredSeller` e seus campos (`ExternalReferenceNumber`,
  `VehicleConditionPicklist`, `PreferredSellerType`).
- Campos já existentes em DevSales não recriados aqui: `Lead.Sociedad__c`,
  `Lead.LinhaNegocio__c` (este último é referenciado por `DR_Lead_Insert`).
