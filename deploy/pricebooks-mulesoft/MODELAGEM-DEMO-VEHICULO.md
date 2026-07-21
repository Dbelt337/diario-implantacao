# Modelagem — Veículo demo/exposição (bloqueio → liberação para venda)

Pergunta da Melisa (BA cliente): veículo de demonstração/exposição fica bloqueado
enquanto é demo; ao vender, como funciona — e **quem é responsável por cada etapa,
SAP ou Salesforce?** Resposta native-first, sobre o modelo de inventário do
Automotive Cloud (Vehicle / Asset / ProductItem / SerializedProduct).

## Princípio (fronteira SAP × Salesforce, já decidida na arquitetura)
- **SAP = master do estoque físico e disponibilidade.** (decisão registrada: SAP é
  fonte de materiais/inventário; validação exata real-time no fechamento.)
- **Salesforce = processo comercial + ciclo de uso da unidade** (exposição, test
  drive, cotação, venda, 360).
- **MuleSoft = sincroniza** o estado de estoque do SAP para o SF (lote diário) +
  **callout real-time** no fechamento.

## Objetos nativos envolvidos
- **Vehicle** (VIN) — a unidade física. Campo `ConditionType` (New/Demo/Used —
  confirmar valor "Demo").
- **SerializedProduct** (VIN) — a unidade no inventário. Campo `Status` (confirmar
  valores: Available/Reserved/...).
- **ProductItem** — estoque por Location. `QuantityOnHand`, **`QuantityAllocated`**,
  **`QuantityAvailable`**. **Bloqueado = alocado → sai do QuantityAvailable.**
- **Asset** — ativo/ciclo de vida da unidade.
- **Service Appointment (Scheduler)** — test drives do demo (uso).

## Como o "bloqueio" se modela nativamente
Enquanto demo, a unidade **não conta como vendável**:
- `ProductItem.QuantityAvailable` **exclui** a unidade (ela está **Allocated** para
  demo), e/ou `SerializedProduct.Status` = "Reserved/Demo".
- `Vehicle.ConditionType` = "Demo" (marca a natureza).
- Regra de cotação no SF **não** deixa cotar unidade sem disponibilidade.
Ao **liberar para venda**: de-aloca (volta ao QuantityAvailable) e ConditionType
passa a **Demo/Used** (afeta preço). A venda é uma Opportunity para **aquele VIN**.

## Quem é responsável por cada etapa (a resposta da Melisa)
| Etapa | Responsável | Como / objeto |
|---|---|---|
| Recepção física no estoque | **SAP** | entra no estoque SAP → MuleSoft sincroniza p/ SF (Vehicle + SerializedProduct + ProductItem) |
| **Designar como demo/exposição (bloqueio)** | **ver decisão abaixo** | bloqueio de estoque |
| Manter bloqueado (não vendável) | **SF reflete** | `QuantityAvailable` exclui; regra de cotação bloqueia |
| Uso como demo (test drive/exposição) | **Salesforce** | Service Appointment (Scheduler); Vehicle no 360 |
| Decisão de vender o demo | **Salesforce** | Opportunity para o VIN; condição Demo/Used; preço ajustado |
| **Liberar para venda (desbloqueio)** | **ver decisão abaixo** | movimento de estoque |
| Validação de disponibilidade no fechamento | **SAP (real-time via MuleSoft)** | callout confirma que a unidade pode ser vendida |
| Faturamento / baixa de estoque | **SAP** | a venda efetiva baixa o estoque |

## A decisão que resolve a dúvida: onde NASCE o bloqueio?
Duas opções (recomendo a A, por consistência com "SAP master de estoque"):

**Padrão A — SAP é dono do bloqueio (RECOMENDADO):**
- O SAP marca a unidade como **bloqueada/reservada** (estoque bloqueado — comum no
  SAP). MuleSoft sincroniza → em SF a unidade aparece **não-disponível**.
- SF é dono do **uso** (test drive, exposição) e da **venda**. Para vender o demo,
  a liberação é um movimento de estoque no SAP (SF pode solicitar; o real-time no
  fechamento confirma).
- Vantagem: **uma só fonte de verdade** do estoque (SAP). Sem risco de duas verdades.

**Padrão B — Salesforce é dono da designação demo:**
- A sucursal marca no SF (Vehicle status/flag = Demo) → SF bloqueia a cotação e
  **informa o SAP** para reservar. Para vender, SF muda o status e informa o SAP.
- Vantagem: operação comercial 100% no SF. Risco: sincronizar o bloqueio nos dois
  lados (dupla verdade se não houver disciplina de integração).

**Recomendação:** **Padrão A** — o bloqueio físico é do SAP; o Salesforce é dono do
processo comercial e do ciclo de uso. A validação real-time no fechamento garante
que não se venda uma unidade ainda bloqueada. Confirmar com o cliente qual sistema
a operação usa hoje para bloquear a unidade fisicamente (isso define A vs B).

## A confirmar (native-first, sobre a org)
- Rodar `DESCRIBE-vehicle-status.apex` → confirmar valores de `Vehicle.ConditionType`
  (tem "Demo"?), `SerializedProduct.Status`, campos de `ProductItem` (Allocated/
  Available) e de `Asset`. Se não houver valor nativo "Demo", decidir entre um valor
  de picklist novo ou um campo `UsageType__c` (Demo/Loaner/Exhibition).
- Confirmar com o cliente: o bloqueio físico da unidade hoje é feito no **SAP** ou
  na operação (que iria para o **Salesforce**)? → define Padrão A ou B.

## Docs oficiais (para fundamentar / o cliente abrir)
- Automotive Cloud — Vehicle object (fields): developer.salesforce.com Automotive Cloud.
- Manage Vehicle Inventory / Location-ProductItem-SerializedProduct.
- Automotive Cloud Data Model.

---

## ATUALIZAÇÃO — modelo DEFINITIVO (describe + doc oficial)

### Valores nativos confirmados na org
- **`SerializedProduct.AllocationStatus`** = `Allocated` | `Deallocated` →
  **mecanismo NATIVO de bloqueio.** Demo/exposição = **Allocated**; ao liberar
  para venda = **Deallocated**. (+ `ProductItem.QuantityAllocated` / `QuantityAvailable`.)
- `SerializedProduct.Status` = Available | Sent | Consumed | Damaged | Lost.
- `Vehicle.Status` = "En ubicación de concesionario | En servicio | En reparación |
  En fabricación" (é **onde** está — não o bloqueio).
- `Vehicle.ConditionType` = Nuevo | Antiguo | Chatarra (**sem "Demo"**). Um demo
  vendido vira **Antiguo** (Used) para efeito de preço.
- `Asset.Status` = Purchased | Shipped | Installed | Registered | Obsolete.

### Modelo definitivo (native-first)
- **Bloqueio = `SerializedProduct.AllocationStatus = Allocated`** (nativo). Sai do
  `QuantityAvailable`; regra de cotação no SF não deixa cotar unidade Allocated.
- **Motivo do bloqueio = 1 campo custom `UsageType__c`** (Demo / Exhibition /
  Loaner / TestDrive) — **não há valor nativo "Demo"**. É o único custom e é
  justificado (native-first: bloqueio é nativo; só o "porquê" é custom).
- **Location** de showroom guarda a unidade; **Vehicle Inventory Search** (nativo,
  via DPE + Vehicle Searchable Field) e **Vehicle Transfer** (nativo) para achar e
  mover unidades entre locations.
- Ao vender o demo: `AllocationStatus = Deallocated`, `ConditionType = Antiguo`,
  Opportunity para o VIN, preço de demo/usado.

### Responsabilidade — refinada com o mecanismo nativo
- **SAP** = master da **quantidade física** (`QuantityOnHand`), recepção, baixa na
  venda, faturamento.
- **Salesforce** = **reserva/bloqueio comercial** via `AllocationStatus=Allocated`
  + `UsageType__c=Demo` (a designação demo é decisão comercial/da sucursal), uso
  (test drive/exposição via Scheduler), cotação e venda. A regra de cotação bloqueia
  unidades Allocated.
- **MuleSoft** = sincroniza `QuantityOnHand` do SAP; **callout real-time no
  fechamento** confirma disponibilidade antes de fechar.
- **Ponto a alinhar:** como o bloqueio nativo (`AllocationStatus`) é um campo do
  Salesforce, o natural é o **Salesforce ser dono da alocação demo** (Padrão B com
  o mecanismo nativo), mantendo o SAP como dono da quantidade física. Se o SAP
  também precisa saber do bloqueio, MuleSoft informa. Confirmar com o cliente se a
  reserva demo pode viver só no Salesforce ou precisa refletir no SAP.
