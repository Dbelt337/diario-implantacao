# HU-045 — Registro de Vehículo Usado (Inventario y Consignación) × Automotive Cloud

Mapeamento do requisito técnico para os recursos nativos, com base na
documentação oficial (Developer Guide / Data Model Gallery / Trailhead).
Data: 11/08/2026.

## Mapa requisito → recurso nativo

| Requisito da HU | Recurso Automotive/plataforma | Observação |
|---|---|---|
| Ficha da unidade usada (VIN, marca, modelo, ano, versão, cor, km, estado, ubicación) — GQ-CA-01-152 | **`Vehicle`** (+ `VehicleDefinition` para o modelo/versão) | O Vehicle Console nativo exibe VIN, chassi, **odômetro**, registro, preço de mercado e features — a ficha pedida é a aba Details padrão. Odometer é campo nativo (RN2 ✓) |
| Historial / re-vinculação ao registro original (GQ-CA-01-151) | **`AssetMilestone`** + vínculo Vehicle↔`Asset` original | Definição literal do dev guide: "key events in the lifecycle of a vehicle asset, such as manufacturing, registration, **or resale**" — o re-ingresso como usado é um milestone `resale` no MESMO ativo, preservando serviço/manutenção |
| Dueño anterior / propriedade | **`AssetTitle`** + **`AssetTitleParty`**; **`AssetAccountParticipant`** (role `Owner`, com `EffectiveStartDate/EndDate`) | Titularidade legal + histórico de donos com datas — dispensa campo custom de "dueño anterior" |
| Avalúo obrigatório no alta (RN3) | Família **`Appraisal`**: `Appraisal`, `AppraisalItem` (liga ao Vehicle/Asset), `AppraisalItemProviderVal` (valuations de referência — é aqui que Blue Book/PRU entrariam na US-089), `AppraisalItemAddOn` (equipamento), `AppraisalAdjustment` | Data model oficial "Vehicle and Asset Appraisals". A org JÁ usa (flows `AppraisalAfterHandler`/`AppraisalItemAfterHandler` ativos — HU-036). "Ligar à placa vs. ao VIN original" = AppraisalItem apontando para Vehicle novo × Asset original |
| Base de usados filtrável (GQ-CA-01-153) | **`VehicleSearchableField`** + list views | Definição do dev guide: "common dataset... used as the basis for inventory search related to vehicles" |
| Estado "En consignación" (RN4) | Picklist de status do **`Vehicle`** (valor custom) | A HU já assume picklist nativo do Vehicle — correto |
| Almacén/ubicación específica | **`Location`** (standard) referenciada pelo Vehicle | Mesmo objeto que Field Service usa |
| Contrato de consignação (RN4, GQ-CA-01-159) | **`Contract` + Record Type "Consignación"** (plataforma) | O Automotive Cloud NÃO tem objeto nativo de consignação — a decisão da HU (Contract padrão, consignante = Account, comissão = campo no contrato) é o desenho certo. **Já existe na org**: `Contract_BS_ConsignmentDefaultEndDate` (30 dias default ✓) e `Contract_Sched_ConsignmentExpiryAlert` (alerta de vencimento ✓) — GQ-CA-01-158/159 parcialmente construídos |
| Alerta ~5 dias antes do vencimento | Scheduled Flow + Custom Notification ao rol Gerente de Usados | `Contract_Sched_ConsignmentExpiryAlert` já existe — validar destinatário e antecedência |
| Habilitação por sociedade (Escenario 8) | Visibilidade de Record Type por perfil/permission set | Plataforma pura — coerente com HU-017 |
| VIN único (RN1) | Flow before-save anti-duplicado (padrão HU-039) sobre o campo VIN do Vehicle | **Atenção**: duplicate rules NÃO suportam o objeto Vehicle — a unicidade vai por validação em flow/Apex (ou campo custom External ID único espelhando o VIN, que dá unicidade no banco) |
| Fotografias obrigatórias (RN2) | Files (`ContentDocumentLink`) + validação no flow de alta | Não existe "anexo obrigatório" nativo — o flow de tela do alta valida antes de concluir |
| Demo/exhibición → usados (RN5) | Transição de status do Vehicle + mesmo flow de alta | A org já tem `ManageDemoVehicle`/`ExecuteDemoRequest` — a transição sai deles para o flow de alta de usados |
| VIN com ponto (.) em SAP (RN1) | Integração MuleSoft (fora do Automotive) | Regra vive no lado SAP/Mule; Salesforce só re-vincula e conserva o VIN original |

## Fontes oficiais

- [Vehicle | Automotive Cloud Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/sforce_api_objects_vehicle.htm)
- [Vehicle and Asset Appraisals | Data Model Gallery](https://developer.salesforce.com/docs/platform/data-models/guide/vehicle-and-asset-appraisals.html)
- [Automotive Cloud Standard Objects](https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm) (AssetMilestone, AssetTitle, AssetTitleParty, VehicleSearchableField)
- [Automotive Cloud Fields on Standard Objects](https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/platform_objects.htm)
- [Trailhead: Managing Asset and Vehicle Records](https://trailhead.salesforce.com/content/learn/modules/vehicle-and-asset-management-in-automotive-cloud/review-asset-and-vehicle-records)
- [Trailhead: Connect Customer and Vehicle Data](https://trailhead.salesforce.com/content/learn/modules/automotive-cloud-foundations/connect-customer-and-vehicle-data) (Vehicle Console: VIN, chassi, odômetro, registro)

## Riscos/decisões a validar

1. **Unicidade de VIN**: confirmar o nome exato do campo de VIN no objeto
   Vehicle da org e decidir flow anti-duplicado vs. External ID único.
2. **AssetTitle** exige API 60+ e permission set Automotive — conferir
   licenciamento dos perfis de Usados.
3. **Open point Guatemala** (ativo fijo → inventário): depende de SAP;
   Salesforce só reflete — manter como pendente com GrupoQ.
