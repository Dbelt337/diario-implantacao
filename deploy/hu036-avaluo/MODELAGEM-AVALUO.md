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
| Account (cliente) | Lookup(Account) | N | |
| Vínculo com Opportunity | Lookup | N | **confirmar se é direto ou via Vehicle/Asset** |
| Vehicle / Asset | Lookup | N | o veículo usado |
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
| Vehicle / VehicleDefinition | Lookup | N | marca/modelo/ano |
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
2. **Vínculo Appraisal ↔ Opportunity** — lookup direto ou via Vehicle/Asset.
3. **Campos custom mínimos** a criar no Appraisal: multas, gravames, judiciais,
   motivo de rejeição (o resto é nativo).
4. **PRU** — objeto mestre (custom até integração OEM) referenciado por
   AppraisalItemProviderVal; dimensão por país.

## 4. Dependências / GAPs (fases futuras — do doc HU-036)
- Autoagendamento do cliente (Experience Cloud) = **GAP** (hoje assessor agenda).
- Scheduler REST APIs / Portal de autogestão = fase futura.
- Integração de preço/estoque (SAP) não participa da agenda nem do valor de
  referência do avalúo.
