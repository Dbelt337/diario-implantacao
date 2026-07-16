# HU-025 — Cobertura Nativa (Automotive Cloud) para direcionar o cliente

**Princípio (acordado):** *native-first*. Cada requisito é coberto por um recurso
**nativo** do Automotive Cloud / Sales Cloud, modelado conforme a **Object
Reference** da Salesforce. Guided selling via **OmniStudio Standard Runtime**
(on-core) — o runtime que o projeto usa. Só se cai para custom (campo/flow/
integração) quando não há nativo que cubra.

> Docs oficiais citadas ao final. Onde eu marquei **[confirmar no Object
> Reference]**, preciso dos campos exatos do PDF que você tem — me manda o
> conteúdo da seção do objeto.

---

## Princípio de modelagem (o que dizer ao cliente)

1. **Tipo de venda** = **Record Type + Sales Process** (não campo custom solto).
   Autos/Motos/Flotas/Mayorista já são Record Types. Cada um tem seu conjunto
   de etapas (Sales Process) — é assim que se modela "fluxo mais ágil de Motos".
2. **Momento de validação** = **Path (obrigatoriedade por etapa) + Validation
   Rules** ancoradas em `RecordType` + `StageName`. Guia = **Path Guidance** e,
   para decisões, **OmniScript** (Standard Runtime).
3. **Dados de veículo/marca/parceiro** = objetos nativos do Automotive Cloud
   (Vehicle, Vehicle Definition, Business Brand, Party Relationship Group…),
   não objetos custom.

---

## Pilar A — Processos diferenciados + validações por tipo e etapa

| Requisito (HU) | Recurso NATIVO | Doc oficial | Obs. |
|---|---|---|---|
| Tipos de venda (Retail/Mayorista/Fleet/Motos) | **Record Types + Sales Process** por tipo | Sales Cloud – Sales Processes | Já existe (Autos/Motos/Flotas) |
| "Fluxo de Motos mais ágil" | **Sales Process** com menos etapas no RT Motos | Sales Processes | Config, não custom |
| Guia passo a passo por etapa | **Path** (Lead e Opportunity) + Key Fields + Guidance | Path / Guidance for Success | Nativo, Lead **e** Opp |
| Validação obrigatória por etapa+tipo | **Validation Rules** (`RecordType.DeveloperName` + `ISPICKVAL(StageName)`) | Validation Rules | Ver MATRIZ-VALIDACAO.md |
| "Tem produto/cotação" | Campo standard **`HasOpportunityLineItem`** | Opportunity Object Reference | Sem contar filhos |
| Busca de duplicados | **Duplicate & Matching Rules** | Duplicate Management | Nativo (HU-016) |
| Marca de interesse | Objeto **Business Brand** (nativo AC) | Automotive Cloud Standard Objects | [confirmar no Object Reference] |
| Modelo/versão de interesse | **Product2 / OpportunityLineItem** | Automotive Cloud – LeadLineItem/OLI | Já implementado |
| Dados do veículo | **Vehicle / Vehicle Definition** (nativos AC) | Vehicle / VehicleDefinition | [confirmar campos] |
| Motivo de cierre (perdido/anulado) | **Validation Rule** em Closed Lost (campo motivo obrigatório) | Validation Rules | Construir |

## Pilar B — Preços / Descontos / Catálogo

| Requisito | Recurso NATIVO | Doc oficial | Obs. |
|---|---|---|---|
| Preço varia por país | **Multimoeda + Price Book por sociedade/país** | Price Books / Multicurrency | Já em uso (CRC/C101) |
| Preço/catálogo por marca/linha/tipo de venda | **Price Books segmentados** (retail/frota/motos) + PricebookEntry | Price Book Object Reference | H7 adiado — direcionar p/ price books, não custom |
| Desconto parametrizável (marca/país/modelo/ano/sociedade) | **Custom Metadata** (matriz) → dirige regra/aprovação | Custom Metadata Types | Config declarativo (best practice) |
| Impedir desconto fora de faixa sem aprovação | **Approval Process** + Validation Rule de faixa | Approval Processes | H6 parcial |
| Aprovadores diferentes retail vs frota | **Approval Processes separados por Record Type** (ou steps dinâmicos) | Approval Processes | Fecha o gap do H6 |

## Pilar C — Guided Selling (Lead e Oportunidade, todas as etapas)

| Requisito | Recurso NATIVO | Doc oficial | Obs. |
|---|---|---|---|
| Guia amigável por etapa | **Path** (Lead + Opp) | Path | Base nativa |
| Passo a passo com decisões (financiamento, acessórios, desconto, docs) | **OmniScript** (OmniStudio) | OmniStudio for Automotive Cloud | **Standard Runtime** ✔ |
| Cards/resumo em tela | **FlexCards** (OmniStudio) | OmniStudio | Standard Runtime |
| Orquestração de dados / callouts na guia | **Integration Procedures + Data Mapper** | OmniStudio | Standard Runtime |
| Próxima ação recomendada | **Einstein Next Best Action** | Next Best Action | Nativo |

> Nota Standard Runtime: OmniScript, FlexCards, Integration Procedures e Data
> Mapper rodam **on-core (Standard Runtime)** — nenhuma recomendação acima
> depende do managed package. É o runtime recomendado atual da Salesforce.

## Pilar D — Documentação obrigatória

| Requisito | Recurso NATIVO | Doc oficial | Obs. |
|---|---|---|---|
| Anexos/expediente | **Files / ContentDocument** | Files | Nativo |
| Checklist de documentos obrigatórios | **Document Checklist Item** (Industries) | Document Checklist | [confirmar disponibilidade na licença AC] |
| Validar docs do SharePoint | Integração + **checkbox de controle** + VR | — | Externo (r14) |

## Fleet / Frotas — recursos nativos específicos (a área mais fraca hoje)

| Requisito | Recurso NATIVO | Doc oficial | Obs. |
|---|---|---|---|
| Classificação B2B / frota / governo | **Business Profile** (nativo AC) ou campo no Account | Automotive Cloud Standard Objects | [confirmar no Object Reference] em vez de `FleetSegment__c` custom |
| Grupo econômico / holding | **Party Relationship Group** (nativo AC) | Party Relationship Group | Substitui hierarquia custom |
| Unidades em operação (frota do cliente) | **Asset / Vehicle** (veículos do cliente) | Asset / Vehicle | Nativo |
| Contato/responsável principal | **Account Contact Relationship** (papel principal) | ACR | Nativo |
| Carteira por vendedor / zona | **Actionable Segmentation / Actionable List** + Ownership/Territory | Actionable Segmentation | Nativo (Seção 31) |
| Visibilidade por marca | **Sharing / Restriction Rules** por Business Brand | Sharing | Nativo |
| Cotação de frota (múltiplas unidades) | **OpportunityLineItem múltiplos**; (volume) **Sales Agreement** (Manufacturing) | Sales Agreements | Sales Agreement exige licença MFG — validar |
| Reserva multi-veículos | **OmniScript** batch (Standard Runtime) | OmniStudio | Outro escopo |

## Dependências externas (não nativas — deixar explícito ao cliente)

| Requisito | Por quê | Caminho |
|---|---|---|
| Disponibilidade de inventário | Estoque vive no SAP | **Integration Procedure** (OmniStudio) + MuleSoft. **Decisão (Felipe Pajon):** status básico (Disponível/Não) cacheado 1x/dia no SF para relatório/regra + **validação exata em tempo real via MuleSoft pouco antes do fechamento**. Reusar aceleradores Mule. |
| Validação de crédito no início | Motor externo (CrediQ/FSC) | **Integration Procedure** callout (Standard Runtime) — D-US025-04 |
| Docs do SharePoint | Repositório externo | Integração + checkbox de controle |

---

## Docs oficiais (referências)

- Automotive Cloud – Standard Objects: https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm
- Automotive Cloud – Fields on Standard Objects: https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/platform_objects.htm
- Vehicle (Object Reference): https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehicle.htm
- Automotive Cloud – Data Model Gallery: https://developer.salesforce.com/docs/platform/data-models/guide/automotive-cloud.html
- OmniStudio for Automotive Cloud: https://help.salesforce.com/s/articleView?id=sf.auto_omnistudio_package.htm
- OmniStudio (on-core / Standard): https://www.salesforce.com/industries/omnistudio/omnistudio-on-core-guide/
- Industries Common Resources – OmniStudio: https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/omnistudio_overview.htm

## Conteúdo que preciso que você me mande (os docs bloquearam meu acesso — 403)

Para fechar os campos exatos e citar a Object Reference com precisão, me cole o
conteúdo destas seções do PDF/doc que você tem:
1. **Business Brand** (campos) — para "marca de interesse".
2. **Business Profile** (campos) — para classificação B2B/frota/governo (evitar `FleetSegment__c` custom).
3. **Party Relationship Group** — para grupo econômico/holding de frota.
4. **Vehicle / Vehicle Definition** (campos) — inventário e dados do veículo.
5. **OmniStudio Standard Runtime** — limitações/pré-reqs, se o PDF trouxer.

---

## Modelagem nativa CONFIRMADA (Object Reference recebido)

**Business Brand** — marca. Campos: Name, Org ID, Parent Brand (hierarquia).
`Product2.BusinessBrandId` liga produto à marca. Sharing rules permitem
compartilhar info **por marca**.
> Uso: "marca de interesse" = **lookup a BusinessBrand** (não campo texto).
> Cobre tambem "visibilidade por marca" da frota via sharing.

**Business Profile** — dealer/stakeholder (por Account). Campos: Business
Partner Type (Customer / Financier / Sales Dealer / Service Dealer), Service
Type (Spare Parts Sales / Sales / Repair & Maintenance / Consultation),
Business Partner Code, Business Partner Registered Name, Business Operating
Name, Business Tax Identifier, Region, Service Territory, External Reference
Number. Picklists extensiveis pelo admin.
> Uso: classificacao de parceiro/dealer + dados da empresa. B2B/frota/governo
> pode entrar aqui (estender picklist), evitando FleetSegment__c custom.

**Party Relationship Group** — grupo economico / holding / frota. Account +
Category, Type, Subtype, Group Size, Group Income, Lifetime Vehicle/Service/
Accessory Purchase Count e Value. Exemplo OFICIAL e uma frota (Acme). Guided
workflow "New Group" para montar membros/relacoes.
> Uso: grupo economico/holding de frota = NATIVO, com lifetime value.
> Substitui hierarquia custom.

**Vehicle** — VIN e placa. Campos: VehicleIdentificationNumber (**VIN**),
VehicleRegistrationNumber (**Placa / RegistrationID**), ChassisNumber,
EngineNumber, ConditionType, CylinderCount, ExteriorColor, StockCode,
RegistrationRegionCode, VehicleDefinitionId, AssetId.
> Uso: a busca por VIN / Placa / Nome (tela do Santiago) = **campos nativos**
> do Vehicle. CylinderCount pode cobrir "cilindrada".

**VehicleDefinition** — modelo/versao, POR PAIS. Campos: BodyType, DoorCount,
DrivetrainType, EmissionStandard, **EngineCubicCapacity**, FuelType, dimensoes,
ModelCode, TransmissionType, VehicleClass, VariantName, **GeoCountryId** (pais).
`VehicleDefinition.Id = Product2.Id`.
> Uso: catalogo POR PAIS e nativo (GeoCountryId). EngineCubicCapacity pode
> substituir Cilindrada__c custom (Motos). Confirmar no org.

**Asset + Asset Account Participant** — veiculo <-> cliente. Asset.Product2Id,
Asset.AccountId; Vehicle.AssetId = Asset.Id. Asset Account Participant: Account +
Stakeholder Role (Sales Dealer / Customer-Preferred Dealer / Customer /
Financier) + Asset + Vehicle + Status + datas + Usage Type = Automotive.
> Uso: ao identificar o cliente, os VINs dele aparecem via Asset Account
> Participant (Role = Customer). Multiplos stakeholders por veiculo. Confirma
> HU-030 Q3 com campos exatos.

**Inventario NATIVO — Location + ProductItem + SerializedProduct** (ACHADO):
- `Location` = filial / centro / armazem.
- `ProductItem` (Product2Id + LocationId) = **estoque do produto numa localizacao** (quantidade).
- `SerializedProduct` (Product2Id + ProductItemId + AssetId) = **unidade serializada** (um veiculo especifico em estoque).
> Uso: "disponibilidade de inventario" tem MODELO NATIVO. Sincronizavel do SAP
> pelo mapeamento **Vehicle Inventory (BOD)**. Em vez de objeto de inventario
> 100% custom, usar ProductItem / SerializedProduct. Visibilidade cross-sociedade
> (HU-030 Q4) = OWD/sharing do ProductItem (read-only amplo).
