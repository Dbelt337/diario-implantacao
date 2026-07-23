# HU-036 — Modelagem do Avalúo (Trade-in de veículo usado)

Base: família nativa **Vehicle and Asset Appraisals** (Automotive Cloud) +
arquitetura registrada em `DECISOES-ARQUITETURA.md` (Scheduler p/ agendamento,
Appraisal p/ resultado, PRU como dado mestre).

> ⚠️ **Fonte das colunas:** os hosts de doc da Salesforce estão bloqueados pela
> política de egress desta sessão (403). A lista abaixo é o **modelo funcional**;
> os **API names reais** devem ser travados rodando `DESCRIBE-appraisal.apex`
> no ambiente (é a verdade da org/versão do cliente). Object Reference oficial
> para o cliente ver as colunas no navegador dele:
> - https://developer.salesforce.com/docs/platform/data-models/guide/vehicle-and-asset-appraisals.html
> - https://developer.salesforce.com/docs/atlas.en-us.automotive_cloud.meta/automotive_cloud/automotive_objects.htm
> - PDF: https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/automotive_cloud.pdf

## 1. Objetos e colunas (modelo funcional — confirmar no describe)

### `Appraisal` — cabeçalho do avalúo
| Campo (funcional) | Tipo | Nativo/Custom | Observação |
|---|---|---|---|
| Name / Número | Auto Number | N | identificador |
| Status | Picklist | N | Solicitado / Em avaliação / Concluído / Aceito / Rejeitado |
| AppraisalType | Picklist | N | Trade-in |
| Data efetiva / validade | Date | N | |
| **FinalAppraisalValue** | Currency | N (RO) | valor tasado final — **confirmar se é FORMULA no describe** |
| **Parent (registro pai)** | Lookup **polimórfico** | N | **CONFIRMADO no ERD:** UM entre **Opportunity, Account, Lead, Case ou Financial Account** |
| Contact | Lookup(Contact) | N | contato relacionado |
| Appraiser / User | Lookup(User) | N | usuário (avaliador) |
| CurrencyIsoCode | Currency | N | CRC |
| Owner | Lookup(User) | N | |
| **Tem multas/esquelas** | Checkbox+texto | **C** | indicador legal (doc HU-036) |
| **Tem gravames** | Checkbox+texto | **C** | |
| **Processos judiciais** | Checkbox+texto | **C** | |
| **Motivo de rejeição** | Picklist/texto | **C** | quando cliente recusa |

### `AppraisalItem` — o veículo/bem avaliado
| Campo | Tipo | N/C | Observação |
|---|---|---|---|
| Appraisal | Master/Lookup | N | pai |
| **Subject (Vehicle OU Asset)** | Lookup **polimórfico** | N | **CONFIRMADO no ERD:** o item aponta para um **Vehicle** OU um **Asset** |
| VIN, Placa, KM, Cor, Condição | vários | N | do Vehicle / item |
| Valor base | Currency | N | |
| **TotalAdjustmentValue** | Currency | N (RO) | **acumula todos os AppraisalAdjustment do item (rollup nativo)** |
| Fotos | Files | N | Salesforce Files anexados |

### `AppraisalItemAddon` — opcionais/adicionais que somam valor
| Campo | Tipo | N/C |
|---|---|---|
| AppraisalItem | Lookup | N |
| Descrição / valor | texto/currency | N |

### `AppraisalItemProviderVal` — valor de referência (PRU)
| Campo | Tipo | N/C | Observação |
|---|---|---|---|
| AppraisalItem | Lookup | N | |
| Valor de referência (PRU/blue book) | Currency | N | |
| Provedor / origem | Lookup/texto | N | referencia a **tabela mestre do PRU por país** (GQ-CA-01-157) |
| Data da referência | Date | N | |

### `AppraisalAdjustment` — deduções e exceções (uma por uma)
| Campo | Tipo | N/C | Observação |
|---|---|---|---|
| AppraisalItem | Lookup | N | |
| Tipo (dedução/exceção) | Picklist | N | |
| Motivo / descrição | texto | N | |
| Valor do ajuste (±) | Currency | N | rola em `TotalAdjustmentValue` |
| CreatedBy | Lookup(User) | N (RO) | a "traza" de quem ajustou |

### `AppraisalComment` — notas
Comentários nativos (as notas do assessor de piso).

## 2. Fluxo do avalúo — necessidade do GrupoQ (end-to-end)

```
[Opportunity venda c/ trade-in]
        │
        ▼
1. AGENDAMENTO (Scheduler)
   - Assessor/recepcionista cria Service Appointment (sem Experience Cloud = GAP autoagenda)
   - Valuador INTERNO  = User + Service Resource (Operating Hours / Territory)
   - Valuador EXTERNO  = provedor como Account/Contact (NÃO Service Resource) + Flow notifica (correo/WhatsApp)
   - Sucursal = Service Territory; se em outra filial: Owner da Opp NÃO muda, valuador entra via Opportunity Team
        │
        ▼
2. INÍCIO ("Request an Appraisal" / Create Appraisal)
   - Cria Appraisal ligado à Opportunity (+ Account + Vehicle/Asset)
        │
        ▼
3. DADOS DO USADO (AppraisalItem)
   - Vehicle/VehicleDefinition, VIN, placa, km, cor, condição
   - Fotos via Salesforce Files
   - Add-ons → AppraisalItemAddon
        │
        ▼
4. REFERÊNCIA (AppraisalItemProviderVal)
   - PRU da tabela mestre por país → valor sugerido
        │
        ▼
5. DEDUÇÕES/EXCEÇÕES (AppraisalAdjustment, N registros)
   - cada dedução do valuador e exceção do gerente, com CreatedBy (traza, sem aprovação formal)
   - acumulam em AppraisalItem.TotalAdjustmentValue
        │
        ▼
6. INDICADORES LEGAIS (campos custom no Appraisal)
   - multas/esquelas, gravames, processos judiciais + notas (AppraisalComment)
        │
        ▼
7. VALOR FINAL (FinalAppraisalValue) — calculado, valuador NÃO digita
        │
        ▼
8. FECHAMENTO (Flow record-triggered no Appraisal: Status=Concluído/Aceito)
   - carimba valor aceito na Opportunity → recalcula valor neto
   - proposta enviada por correo (O365) / WhatsApp
   - trazabilidade permanece em Service Appointment + Appraisal
        │
        ├── Cliente ACEITA → trade-in consumido na cotização
        └── Cliente RECUSA → registra Motivo; renegocia OU segue venda sem usado
        │
        ▼
9. VISIBILIDADE — avalúo e resultado no 360 do prospecto (related list)
```

## 3. Pontos a confirmar antes de construir (não deixar como fato)
1. **Como o `FinalAppraisalValue` é calculado** — formula nativa vs regra/rollup
   configurável (rodar describe; olhar flag `[FORMULA]`).
2. ~~Vínculo Appraisal ↔ Opportunity~~ **RESOLVIDO no ERD oficial: o pai do
   Appraisal é um lookup POLIMÓRFICO — UM entre Opportunity, Account, Lead, Case
   ou Financial Account (+ lookups Contact e User).** Para o GrupoQ: parent =
   Opportunity (venda) ou Account (cliente). O AppraisalItem aponta para Vehicle
   OU Asset (também polimórfico).
5. **AppraisalAdjustment** não aparece neste recorte do ERD (que mostra Item,
   ProviderVal e Addon). O campo `AppraisalItem.TotalAdjustmentValue` confirma
   que os adjustments existem e rolam para o item — **confirmar no describe** se
   AppraisalAdjustment é filho de AppraisalItem nesta versão.
3. **Campos custom mínimos** a criar no Appraisal: multas, gravames, judiciais,
   motivo de rejeição (o resto é nativo).
4. **PRU** — objeto mestre (custom até integração OEM) referenciado por
   AppraisalItemProviderVal; dimensão por país.

## 4. Dependências / GAPs (fases futuras — do doc HU-036)
- Autoagendamento do cliente (Experience Cloud) = **GAP** (hoje assessor agenda).
- Scheduler REST APIs / Portal de autogestão = fase futura.
- Integração de preço/estoque (SAP) não participa da agenda nem do valor de
  referência do avalúo.

---

## CONFIRMACOES OFICIAIS — Object Reference do Appraisal (23/07, conteudo enviado pelo Diego)

- **FinalAppraisalValue e CALCULADO** (= TotalItemFinalValue + TotalAdjustmentValue,
  ambos tambem calculados). Confirmada a regra "o valuador nao digita o valor final".
- **ReferenceRecordId** (parent) polimorfico oficial: Account, Case, Lead ou
  **Opportunity** (GrupoQ usa Opportunity). Relationship Name: ReferenceRecord.
- **PurposeType** picklist RESTRITO: Sale | **Trade-In** (usar Trade-In; nao ha como
  adicionar valores). **UsageType** = Automotive.
- **AppraisedById** polimorfico: **User** (valuador interno) ou **Contact** (valuador
  externo) — ancora nativa para o modelo de provedor externo (Contact da Cuenta).
- **Status** e picklist NAO restrito — os estados do fluxo (agendado/realizado/
  aceito/recusado) podem ser definidos; gatilho dos Flows de fechamento.
- **ValidityEndDate** nativo — vigencia do avaluo sem campo custom.
- **AppraisalHistory** disponivel — rastreio nativo de campos.
- Regra de acesso oficial: **"Automotive and Appraisal Management must be enabled"**
  (API v63.0+). E o T01.
- Decision Matrices (doc oficial): versoes com start/end date + rank — a atualizacao
  trimestral/mensal do PRU e uma versao nova com vigencia; consider Grouped Matrix
  com Pais como group key e ranges numericos para faixas de ano.

**Pendente de confirmacao de campos:** AppraisalItem e AppraisalItemProviderVal
(paginas do Object Reference ainda nao enviadas; ou rodar o describe T02).

## AppraisalItem — Object Reference oficial (23/07): a ficha e quase toda nativa

| Dado da ficha (HU-036 V2) | Campo NATIVO do AppraisalItem |
|---|---|
| VIN | IdentificationNumber |
| Placa | LicensePlateNumber |
| Quilometragem | **Usage (double) + UsageUnitOfMeasureId** (criar registro UnitOfMeasure "Kilometros") |
| Cor | ExteriorColor (picklist) |
| Marca / Modelo / Ano / Versao | MakeName / ModelName / ModelYear / Trim (picklists) |
| Condicao | ConditionType (RESTRITO: Best/Better/Good — 3 niveis) |
| Valor pedido pelo cliente | CustomerAskingValue |
| **Valor preliminar do PRU** | **InitialValue** ("preliminary value based on provider estimates" — e o campo onde o Flow grava o valor buscado na Decision Matrix) |
| Valor final do item | FinalValue (CALCULADO) + TotalAdjustmentValue (calculado) |
| Data compra / fabricacao / fim garantia | PurchaseDate / ManufacturedDate / WarrantyEndDate |
| Veiculo existente (re-vinculo) | ReferenceRecordId polimorfico = **Asset ou Vehicle** (o elo com a HU-045: VIN ja vendido pelo GQ re-vincula aqui) |

- AppraisalId e MASTER-DETAIL com Appraisal. Type = Vehicle | Asset.
- **ALERTA de verificacao (T02):** MakeName/ModelName/ModelYear/Trim/ExteriorColor/
  ConditionType aparecem como RESTRICTED picklists com valores de exemplo (Make 1,
  Maruti, 2023-2025...). Confirmar no Setup/describe se aceitam valores proprios
  (quase certo que sim — sao placeholders de doc), MAS validar CEDO: se ConditionType
  nao aceitar valores, a escala de condicao do GrupoQ tera que mapear em
  Best/Better/Good (3 niveis) — pergunta de negocio.
- Zero campo custom na ficha; os unicos customs da HU seguem sendo os indicadores
  legais no Appraisal (multas/gravames/judicial).
- Pendente: pagina do AppraisalItemProviderValuation (papel: registrar a avaliacao
  por provedor; o valor operacional preliminar ja tem casa no InitialValue).

## AppraisalAdjustment — Object Reference oficial (23/07)

- **AdjustedById polimorfico: Contact ou User** — a traça de "quem ajustou" e nativa
  (deducao do valuador = User; se um dia o externo ajustar, Contact).
- **AdjustmentValue: currency positivo OU negativo** — cobre deducoes (negativas) e
  excecoes do gerente para cima (positivas). Type restrito: Negative | Positive.
- **Master-detail com Appraisal + lookup opcional a AppraisalItem** — ajuste pode ser
  do avaluo inteiro ou de um item; alimenta os TotalAdjustmentValue calculados.
- **Status RESTRITO nativo: Approved | InReview | Rejected** — a HU diz "sem
  aprovacao formal", entao os ajustes nascem Approved; MAS se o GrupoQ um dia
  quiser aprovacao do gerente para excecoes acima de um teto, o workflow ja existe
  de fabrica (so adicionar um Flow que poe InReview) — future-proof sem custo.
- Description livre para o motivo de cada deducao.

Familia confirmada: Appraisal (ok) + AppraisalItem (ok) + AppraisalAdjustment (ok).
Pendentes: AppraisalItemProviderVal e AppraisalItemAddOn (paginas ou describe T02).
