# HU-025 — Matriz de Validação por Tipo de Venda e Etapa

Fonte: planilha HU-025 (Procesos diferenciados / validaciones obligatorias por
tipo de venta y por etapa; precios/descuentos/catálogos; Guided Selling).

**Como ler:** cada linha = um "momento de validação" = um checkpoint que trava o
avanço se a condição não for cumprida. Coluna **Mecanismo** = como se constrói
no Salesforce. Coluna **Status**: ✅ existe · 🟡 parcial · ❌ falta.

> ⚠️ SUPUESTO: os nomes de etapa (StageName) abaixo são um pipeline lógico. É
> preciso mapear para as StageNames REAIS do Grupo Q antes de escrever as
> validation rules (a lógica não muda, só o valor do `ISPICKVAL`).

Record Types já existentes: `GQOpportunitiesAutos`, `GQOpportunitiesMotos`,
`GQOpportunitiesFlotas` (carimbados na conversão pelo Opp_BS/Lead_AS).

---

## 0. Mecanismos-base (glossário rápido)

| Necessidade | Mecanismo Salesforce |
|---|---|
| Campo obrigatório numa etapa/tipo | **Validation Rule** `RecordType.DeveloperName` + `ISPICKVAL(StageName,...)` + `ISBLANK(campo)` |
| "Tem produto?" | Campo standard **`HasOpportunityLineItem`** (boolean) — sem contar filhos |
| Não pular etapas | Comparar índice da StageName (`CASE(StageName,...)`) atual vs `PRIORVALUE` |
| Regra só ao AVANÇAR | `ISCHANGED(StageName)` + comparação de índice |
| Condição cross-object / doc externa | **Before-save Flow** ou integração seta um **checkbox de controle**; a VR exige o checkbox |
| Guia passo a passo | **Path** (Lead e Opportunity) + Key Fields + Guidance; Flow embutido p/ decisão |
| Desconto fora de faixa | **Approval Process** + matriz de descontos (**Custom Metadata**) |

---

## 1. GERAL (aplica a todos os tipos) — regra `r10`

| Validação | Mecanismo | Status |
|---|---|---|
| Tipo de venta / Record Type carimbado | Opp_BS_EstampaRT / Lead_AS_EstampaRTOpp | ✅ |
| Dados mínimos do prospecto + ≥1 contato | Required fields no layout do Lead + VR (HU-016) | ✅ |
| Busca de duplicados | Matching/Duplicate Rules (outro HU) | ✅ |
| Marca de interesse | `Brand__c` (existe); modelo/versão = produto (OLI) | 🟡 |
| Price Book / catálogo aplicável | Price book por sociedade (H7 adiado) | 🟡 |
| Disponibilidade de inventário | Depende de integração estoque/SAP | ❌ |
| Descontos + aprovações | Approval Process H6 (não distingue retail/frota) | 🟡 |
| Documentação obrigatória | SharePoint (r14) → checkbox de controle + VR | ❌ |
| Motivo de cierre ao perder/anular | Required-on-stage (Closed Lost) via VR | ⬜ construir |

---

## 2. RETAIL AUTOS (`GQOpportunitiesAutos`) — regra `r11`/`r9`

Fluxo lógico: Prospecção → Cotização → Reserva → Aprovações → Pedido/Facturação → Fechado.

| Etapa | Validação obrigatória | Mecanismo | Status |
|---|---|---|---|
| Prospecção | Dados obrigatórios do cliente + ≥1 contato | VR (RT Autos, stage inicial) | ✅ base |
| Prospecção | Marca/modelo/versão de interesse | VR: `Brand__c` + produto | 🟡 |
| Cotização | Cotação criada (quantidade por etapa) | VR: `HasOpportunityLineItem = true` | ✅ mecanismo |
| Cotização | Preço por marca/modelo/versão/sociedade | Price book da sociedade (H7) | ❌ (adiado) |
| Reserva | Veículo reservado + vigência da reserva | Campos `FechaReserva__c`/`VigenciaReserva__c` + VR | ❌ construir |
| Reserva | Anticipo quando aplicável | Campo + VR condicional | ❌ construir |
| Aprovações | Aprovação de desconto acima do autorizado | Approval Process H6 | ✅ (H6) |
| Aprovações | Pré-aprovação / aprovação de crédito | Integração CrediQ/FSC (H3 / D-US025-04) | ❌ (contrato) |
| Pedido/Fact. | Expediente completo (docs) antes de faturar | Checkbox controle (SharePoint) + VR | ❌ construir |
| Fechado | Disponibilidade de inventário | Integração estoque/SAP | ❌ |
| Fechado (Perdido) | Motivo de cierre perdido/anulação | VR: campo motivo obrigatório em Closed Lost | ⬜ construir |

---

## 3. MOTOS (`GQOpportunitiesMotos`) — regra `r13` — fluxo MAIS ÁGIL

| Etapa | Validação obrigatória | Mecanismo | Status |
|---|---|---|---|
| Início | Record Type Motos + tipo de moto + cilindrada | RT + required fields (`TipoMoto__c`, `Cilindrada__c`) | ✅ |
| Início | Fluxo mais curto que Autos | Menos etapas no Sales Process do RT Motos | ✅ (design) |
| Início | Validação crediticia no início (quando aplica) | Integração crédito | ❌ (contrato) |
| Cotização | Price Book dedicado de Motos + modelo de interesse | Price book Motos (D-US025-05 em conflito) | ❌ (conflito) |
| Reserva/Fact. | Disponibilidade de inventário | Integração estoque | ❌ |
| Reserva/Fact. | Forma de pagamento | Campo `FormaPago__c` + VR | ❌ construir |
| Fechamento | Documentação mínima | Checkbox controle + VR | ❌ construir |

---

## 4. FLEET / FROTAS (`GQOpportunitiesFlotas`) — regra `r12` — a mais fraca hoje

| Etapa | Validação obrigatória | Mecanismo | Status |
|---|---|---|---|
| Qualificação | Classificação B2B / frota / governo | `FleetSegment__c` (começado, pausado) | 🟡 |
| Qualificação | Contato / responsável principal da empresa | Campo lookup + VR | ❌ (pausa) |
| Qualificação | Grupo econômico / holding quando aplica | Account hierarchy / campo | ❌ |
| Qualificação | Carteira por vendedor / zona / giro | Ownership + `Zona__c`/`Giro__c` | ❌ (Seção 31, fora) |
| Qualificação | Visibilidade por marca (segurança) | Sharing por marca | ❌ |
| Cotización | Cotação de frota (múltiplas unidades) | OLI múltiplos; quantidade da frota | ❌ (frotas não têm gate de quantidade hoje) |
| Cotización | Unidades em operação | Campo `UnidadesOperacion__c` | ❌ |
| Condições | Descontos diferenciados de frota + aprovadores próprios | Approval Process separado retail vs frota | ❌ (H6 não distingue) |
| Crédito | Aprovação de crédito/financiamento | Integração crédito | ❌ (contrato) |
| Reserva | Reserva de múltiplos veículos | Lote / OmniScript (outro escopo) | ❌ |
| Todo o fluxo | Documentação da empresa | Checkbox + VR | ❌ |
| Todo o fluxo | Rastreabilidade até pedido/faturamento | Path + histórico de etapas | ✅ (SPANCOP) |

---

## 5. PILAR B — Preços / Descontos / Catálogo (transversal)

| Requisito | Mecanismo | Status |
|---|---|---|
| Preço de lista varia por país | Multimoeda + price book por país/sociedade | 🟡 |
| Preço varia por marca/linha/tipo de venda | Price books segmentados (retail/frota/motos) | ❌ (H7 adiado) |
| Desconto parametrizável por marca/país/modelo/ano/sociedade/hierarquia | **Custom Metadata** (matriz de desconto) + Approval Process | 🟡 (H6 parcial) |
| Impedir desconto fora da faixa sem aprovação | VR (desconto > faixa → exige aprovação) + Approval | 🟡 |
| Diferenciar aprovadores retail vs frota | Approval Processes separados por RecordType | ❌ (gap H6) |
| Catálogo diferente por país e por marca | Price book = catálogo por sociedade/marca | ❌ (adiado) |

---

## 6. PILAR C — Guided Selling (Lead E Oportunidade, TODAS as etapas)

| Necessidade | Mecanismo | Status |
|---|---|---|
| Guia passo a passo, mais amigável, todas as etapas | **Path** no Lead e na Opportunity | ⬜ construir |
| Key fields obrigatórios por etapa | Path → Key Fields por etapa | ⬜ construir |
| Orientação por etapa (o que fazer) | Path → Guidance for Success | ⬜ construir |
| Decisões (financiamento, acessórios, desconto, doc, próxima ação) | Flow/Guided Selling embutido | ⬜ construir |

---

## 7. Resumo — o que dá pra construir JÁ vs travado

**Construível agora (não depende de contrato/integração):**
- Validation Rules por etapa+RecordType (motivo de cierre, campos obrigatórios por etapa, `HasOpportunityLineItem` na cotização, não pular etapa).
- Path (Guided Selling) no Lead e na Opportunity com Key Fields + Guidance.
- Classificação de frota `FleetSegment__c` + contato principal (retomar o que estava pausado).
- Aprovadores diferentes retail vs frota (Approval Process por RecordType) — fecha o gap do H6.
- Checkbox de controle "expediente completo" + VR (a validação; o preenchimento pode ser manual até a integração de docs existir).

**Travado por decisão/contrato/integração do cliente:**
- Preço/catálogo por marca/linha/tipo (H7 adiado; Motos PB em conflito D-US025-05).
- Validação de crédito no início (H3 / contrato CrediQ/FSC — D-US025-04).
- Disponibilidade de inventário (integração estoque/SAP).
- Documentação obrigatória automática (SharePoint r14).
- Reserva multi-veículos de frota (lote/OmniScript — outro escopo).

**Recomendação de ordem:** (1) Path/Guided Selling + (2) Validation Rules dos
campos obrigatórios por etapa+tipo + motivo de cierre + `HasOpportunityLineItem`
+ (3) aprovadores retail vs frota + (4) FleetSegment/contato principal. O resto
fica bloqueado aguardando contrato/integração e deve ser marcado como
dependência externa na HU.
