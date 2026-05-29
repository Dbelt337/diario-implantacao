# IP_Lead_Upsert — GrupoQ Sales Automotive

Integration Procedure (OmniStudio Standard Runtime) para criação/upsert de Leads
vindos de canais externos (MuleSoft, formulários web, etc.).

> ✅ **STATUS: PACOTE COMPLETO VALIDADO (Check-Only Succeeded, 0 erros, 9 componentes — 2026-05-29).**
> Fonte da verdade para deploy: **[`final/`](./final/)** (`Deploy_IP_Lead_Upsert_COMPLETO.zip`).
> Formatos MDAPI reais (descobertos via retrieve de moldes da org):
> - Data Mapper: `omniDataTransforms/<Nome>_<versão>.rpt` (root `OmniDataTransform`, `globalKey` por item; **não** precisa dos Ids de servidor).
> - Integration Procedure: `omniIntegrationProcedures/<Type>_<SubType>_<Lang>_<versão>.oip` (root `OmniIntegrationProcedure`, elementos via `omniProcessElements` + `propertySetConfig`).
> - `package.xml` em API **66.0**; tipo da IP é **`OmniIntegrationProcedure`** (não `OmniProcess`).
>
> Os arquivos `omniDataTransforms/*.omniDataTransform` e `omniProcesses/*.omniProcess`
> deste diretório foram a tentativa inicial em formato errado — ficam só como
> **especificação de design** (mapeamentos). Os moldes reais da org estão em
> [`moldes/`](./moldes/). Pós-deploy: ativar a IP no Designer (vem `isActive=false`)
> e conferir 2 pontos de runtime (encadeamento `leadResult:Id` e lookup de `ProductId`).

## Conteúdo do pacote

| Componente | Tipo | Papel |
|---|---|---|
| `GrupoQ_LeadUpsert` | OmniProcess (Integration Procedure) | Orquestra validação → idempotência → criação → resposta |
| `DRLeadGetByExternalRequestId` | OmniDataTransform (Extract) | Idempotência por `ExternalRequestId__c` |
| `DRBusinessProfileGetByCode` | OmniDataTransform (Extract) | Resolve `AccountId` do dealer pelo `dealerCode` |
| `DRLeadInsert` | OmniDataTransform (Load) | Insere o Lead |
| `DRLeadLineItemInsert` | OmniDataTransform (Load) | Insere os `LeadLineItem` |
| `DRLeadPreferredSellerInsert` | OmniDataTransform (Load) | Insere os `LeadPreferredSeller` |
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

## Pré-requisito obrigatório: OmniStudio Metadata API Support

`OmniDataTransform`/`OmniProcess` **só deployam via Metadata API se o setting
"Omnistudio Metadata" estiver habilitado** (Setup → OmniStudio Settings). Enquanto
estiver OFF, o deploy falha com *"named in package.xml, but was not found in zipped
directory"* (sintoma observado no Check-Only de 2026-05-29, `State Detail:
Processing Type: OmniDataTransform`).

Atenção ao ligar:
- **É irreversível** ("After enabling, this setting can't be disabled").
- Ao habilitar, a org **valida o nome único de todos os componentes OmniStudio
  existentes**; nomes com espaço/caractere especial/**underscore** impedem o enable.
- As config tables (`OmniDataTransformConfig`, `OmniScriptConfig`, etc.) precisam
  estar sem registros conflitantes.

### Regra de nomes (motivo do rename dos DataRaptors)

O nome único é gerado por: Data Mapper → campo `Name`; Integration Procedure →
`Type + SubType`. Esses campos **não podem conter underscore**. Por isso os
DataRaptors foram renomeados de `DR_Lead_Insert` → `DRLeadInsert` etc. A IP
permanece `GrupoQ_LeadUpsert` (Type `GrupoQ` + SubType `LeadUpsert`; o `_` é só
separador do fullName).

## Deploy (Workbench / Metadata API)

1. Habilitar **Omnistudio Metadata** (ver pré-requisito acima).
2. **Deploy em Check-Only** primeiro (Single Package + Rollback On Error).
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
