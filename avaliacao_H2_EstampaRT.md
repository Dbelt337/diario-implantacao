# Avaliação READ-ONLY — Flow `Lead_AS_EstampaRTOpp` vs spec GQ.AUT.US025.H2.ADM

**Data:** 2026-07-10 · **Avaliador:** arquitetura (sessão diario-implantacao)
**Input:** `metadata_39.zip` → `flows/Lead_AS_EstampaRTOpp.flow` (XML íntegro, api 63.0, status **Active**, triggerOrder **60**)

## Conformidade com as regras duras
| Regra | Estado |
|---|---|
| 1. 100% read-only | ✅ Cumprida — nenhuma escrita na org; análise apenas do XML entregue |
| 2. `sf org list` primeiro | ⚠️ **`sf` CLI inexistente neste ambiente → DevSales NÃO autenticado.** Conforme a regra, os passos dependentes de org foram **PARADOS**: retrieve dos demais flows record-triggered (Lead/Opportunity), describes de campos e confirmação de API names na org. Itens afetados marcados **BLOQUEADO** abaixo. |
| 3. Nenhum API name de memória | ✅ Tudo citado vem confirmado **pelo XML recuperado** (permitido pela regra); o que exigiria describe está marcado BLOQUEADO |
| 4. Não implementar nada | ✅ Entregável = este relatório; esqueleto de reconstrução descrito, não construído |

---

## A. Superfície vs Spec — **NÃO CONFORME**

| Aspecto | Spec H2 | Flow real (XML) |
|---|---|---|
| Objeto do trigger | **Opportunity** | **Lead** (`<object>Lead</object>`, linha 164) |
| Momento | **before-save** | **after-save** (`RecordAfterSave`, linha 166) |
| Evento | create (da Opp) | **Update** do Lead, filtro `ISCHANGED(IsConverted) && IsConverted && NOT(ISBLANK(ConvertedOpportunityId))` |
| Banda | **10** | **60** (e em Lead — a banda 10 da spec é inaplicável a este trigger) |

**Lacunas de cobertura concretas** (Opps que nascem SEM conversão — citadas na spec — e ficam **sem estampa**):
1. **SFCC checkout** (Sec 33.1) — Opp criada por integração: flow nunca dispara.
2. **Criação manual account-first (Flotas)** — idem.
3. **Qualquer criação via API/data load** — idem.

**Efeitos colaterais da abordagem after-save-de-Lead** (mesmo no caminho coberto):
- **Segundo save na Opp**: a Opp nasce com RT default do perfil e recebe `recordUpdate` em seguida (linhas 123–152) → segundo DML, re-execução de automações e VRs.
- **Janela de RT errado**: no CREATE da Opp, todas as automações/VRs keyed por RecordType (ex.: **VR Motos do H4**) rodam com o **RT default incorreto**; só no update chega o RT real. VR que bloqueie por RT pode **quebrar a conversão inteira**.
- **Path/layout** renderizam errado se o registro for aberto entre create e update (mitigado por ser mesma transação, mas o histórico de campo registra a troca).

*Atenuante registrado:* a `description` do flow (linha 27) documenta o racional do autor — `Lead.Industry` é standard e o mapeamento de conversão não o carrega a campo custom da Opp; um before-save de Opp "não tinha forma de conhecer a línea". É uma tensão real de design (ver F), mas não elimina as lacunas SFCC/manual/API que a spec exige cobrir.

## B. Mecânica Lead-based — corretamente implementada (dentro da abordagem errada)

| Item | Achado (XML) | Avaliação |
|---|---|---|
| Localização da Opp | `$Record.ConvertedOpportunityId` (update filtrado por Id, linha 136) | ✅ correto |
| Condição de conversão | `ISCHANGED(IsConverted) && IsConverted && NOT(ISBLANK(ConvertedOpportunityId))` | ✅ guarda conversão sem Opp; ✅ dispara também em conversão via API (qualquer flip de `IsConverted`) |
| Transformations API | mesmo flip de `IsConverted` → coberto | ✅ (confirmação em org: BLOQUEADO) |
| Bulk-safety | 1 Get + 1 Update por registro, sem loops; bulkificação da plataforma | ✅ |
| Fault handling | faultConnector → `recordCreate` de **Task** com `$Flow.FaultMessage` e `WhatId=ConvertedOpportunityId` | ✅ existe; ver risco R5 |

## C. Lógica de derivação vs Spec — **NÃO CONFORME**

| Ramo esperado (spec) | No flow? |
|---|---|
| B2B-revendedor → `Venta_Mayorista` | ❌ ausente (nenhum critério B2B no XML) |
| Frota → `Venda_Frota` | ⚠️ existe como `"Frotas" → GQOpportunitiesFlotas` — **DevName diverge da spec** |
| Motos (via `User.TipoAutoQueVende__c`) → `Venda_Moto` | ⚠️ existe como `"Motos" → GQOpportunitiesMotos`, porém derivado de `Lead.Industry`, **sem** `TipoAutoQueVende__c` e sem tratar o alerta da spec ($User vs dono) |
| default → `Venda_Veiculo` | ❌ Industry vazio → decisão "No mapea" **sem conector default** → flow termina e a Opp **fica com o RT default do perfil** (não com Venda_Veiculo) |
| **Repuestos gestionado — NÃO deve existir (D-REP-01)** | 🚨 **VIOLADO**: `"Repuestos"/"PA" → GQOpportunitiesRepuestosPA` (linhas 47–48) + etapa `Calificación` — braço construído com D-REP-01 pendente, sem marcação de placeholder |

**Fora de escopo da spec:** o flow também estampa **StageName** (`Open_Stage`, linhas 29–39: Negociación/Sospechoso/Calificación) — comportamento extra não pedido em H2, com valores de picklist **hardcoded em texto localizado** (confirmação dos API values: BLOQUEADO).

**Divergência de nomenclatura de RTs:** spec cita `Venda_Veiculo, Venda_Moto, Venda_Frota, Venta_Mayorista`; o flow usa `GQOpportunitiesAutos/Motos/Flotas/RepuestosPA`. Qual conjunto existe na org: **BLOQUEADO** (exige describe/retrieve). Se os DevNames do flow não existirem, TODO caminho mapeado falha (ver R4).

## D. Qualidade técnica

| Critério | Resultado |
|---|---|
| RecordTypeIds hardcoded | ✅ **Aprovado neste critério** — resolução por `DeveloperName` + `SobjectType='Opportunity'` via Get Records (linhas 104–117); não incide a reprovação automática |
| Null-check pós-Get | ❌ **Ausente**: `assignNullValuesIfNoRecordsFound=false` e nenhuma decisão entre Get e Update; RT não encontrado → update com `RecordTypeId=null` → erro DML → fault→Task. Falha ruidosa, mas sem guard explícito |
| Sobrescrita de escolha explícita de RT | ❌ sem guard — sobrescreve qualquer RT que a conversão tenha definido |
| Null-safety (`TipoAutoQueVende__c` ausente) | n/a — campo nem é lido (violação C); Industry vazio → no-op (≠ default da spec) |
| Trigger order | 60 em Lead; spec pede 10 em Opportunity. Conflitos com `Lead_AS_PostConversion` e outros: **BLOQUEADO** (exige retrieve) |
| Nomenclatura | `Lead_AS_...` coerente com after-save; a spec ordenava artefato `Opp_BS_...` (padrão Objeto_BS_Nome) |
| Descrição / Status | ✅ descrição rica e honesta; ✅ Active |
| Acoplamento de deploy c/ RTs | **BLOQUEADO** — o zip contém só o flow; a spec exige "mesmo pacote que os RTs, jamais separado" (não verificável aqui) |

## E. Interação com o existente — **BLOQUEADO** (org não autenticada)
Não recuperáveis nesta sessão: demais flows record-triggered de Lead/Opportunity (ordem relativa a `Lead_AS_PostConversion`), VR Motos do H4, consumidores de RecordTypeId no create. **Raciocínio possível pelo XML:** enquanto Lead-based, a VR Motos e qualquer automação por RT executam no create da Opp com RT default (janela errada) e re-executam no update — risco de bloqueio de conversão se a VR Motos negar algo no RT default.

---

## Riscos (severidade)

| # | Risco | Sev. |
|---|---|---|
| R1 | Superfície errada (Lead AS vs Opp BS): Opps SFCC/manual/API **nunca** estampadas | **ALTA** |
| R2 | Braço Repuestos/PA construído com **D-REP-01 pendente** (proibido pela spec) | **ALTA** |
| R3 | Janela de RT default no create → VRs/automações por RT (VR Motos H4) rodam com RT errado; VR pode derrubar a conversão | **ALTA** |
| R4 | DevNames `GQOpportunities*` divergem dos RTs da spec (`Venda_*`/`Venta_*`) — se não existirem, todo ramo falha em runtime (fault→Task) | **ALTA** (confirmação BLOQUEADA) |
| R5 | Estampa de StageName fora de escopo, com labels localizados hardcoded; sobrescreve etapa definida na conversão | MÉDIA |
| R6 | Sem branch Mayorista/B2B e sem `TipoAutoQueVende__c` → Mayorista e a diferenciação Autos/Motos do perfil AC_Vend_Veh não atendidas | MÉDIA |
| R7 | Sem null-check pós-Get; sem guard de RT explícito; Industry vazio ≠ default Venda_Veiculo | MÉDIA |
| R8 | Segundo save na Opp (re-execução de automações, histórico com troca de RT) | BAIXA (consequência de R1) |

## F. VEREDICTO: **RECONSTRUIR CONFORME SPEC**

Reprovação motivada por R1+R2 (superfície e braço proibido — ambos itens de spec, não de estilo), com R3/R4 como agravantes. A resolução por DeveloperName (D) e o fault-handling (B) são bons e devem ser preservados na reconstrução.

### Esqueleto do flow correto (NÃO construído — especificação)
**`Opp_BS_EstampaRT` — Opportunity · before-save · create · triggerOrder 10 · MESMO PACOTE dos RTs**

1. **Entry (start):** `Opportunity`, `RecordBeforeSave`, `Create`.
2. **Guard de RT explícito (decisão 1):** se `$Record.RecordType.DeveloperName` já for um dos RTs-alvo → **sair** (não sobrescrever escolha explícita/integração já correta).
3. **Get owner (1 Get Records):** `User` por `$Record.OwnerId` → `TipoAutoQueVende__c` (**não** usar `$User`, que é quem dispara — alerta da spec).
4. **Decisão de linha (ordem de precedência):**
   a. **critério B2B-revendedor** *(fonte do critério a confirmar com a spec/Melisa — placeholder MARCADO)* → DevName alvo `Venta_Mayorista`;
   b. linha **Frota** → `Venda_Frota`;
   c. `TipoAutoQueVende__c = Motos` (null-safe: campo vazio cai em d) → `Venda_Moto`;
   d. **default → `Venda_Veiculo`** (nunca no-op);
   e. **SEM braço Repuestos** (D-REP-01) — comentário no flow apontando a decisão.
5. **Get RecordType** por `DeveloperName` (fórmula) + `SobjectType='Opportunity'` → **decisão null-check**: não achou → sair sem atribuir (e opcional: log).
6. **Assignment** `$Record.RecordTypeId = Get.Id` (before-save: **sem DML extra**, sem janela de RT errado, cobre conversão + SFCC + manual + API).
7. **Fora de escopo:** não estampar StageName neste flow (se o negócio confirmar a necessidade, tarefa própria com os API values reais da picklist).

**Tensão de design a resolver com o dono da spec (herdada do flow atual):** no before-save da Opp convertida não há acesso a `Lead.Industry`. Fontes candidatas no momento do create: `Account.Industry` (travessia `$Record.Account.Industry` — confirmar preenchimento no fluxo de conversão), o `TipoAutoQueVende__c` do owner, e o critério B2B. Se `Account.Industry` não for confiável na conversão, a spec precisa nomear a fonte da "línea" — **decisão de spec, não de implementação**.

### Pendências BLOQUEADAS (exigem org autenticada)
1. Confirmar quais RT DevNames existem (`GQOpportunities*` vs `Venda_*`/`Venta_*`).
2. Retrieve dos flows record-triggered de Lead/Opportunity ativos (ordem/conflitos, `Lead_AS_PostConversion`).
3. Describe de `User.TipoAutoQueVende__c` e da fonte do critério B2B.
4. Verificar VR Motos (H4) e demais consumidores de RecordTypeId no create.
