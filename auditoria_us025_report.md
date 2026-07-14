# AUDITORIA READ-ONLY — US-025 (Procesos Comerciales) — DevSales
**Data:** 2026-07-14 · **Sessão:** Claude Code remoto · **Modo:** 100% leitura (nenhuma alteração feita)

---

## 0. ESCOPO REALMENTE EXECUTADO (declaração de bloqueio — Regra 1)

Evidência literal da tentativa de acesso à org:

```
$ sf org list
/bin/bash: line 1: sf: command not found
$ ls ~/.sfdx ~/.sf
(diretórios inexistentes — nenhuma credencial DevSales no container)
```

Pela Regra 1 ("alias DevSales autenticado ou PARAR"), a auditoria **live** (describes,
queries, retrieve) está **BLOQUEADA** nesta sessão. O que foi auditado é o pacote
enviado pelo usuário durante a sessão (`metadata_40.zip`, retrieve `unpackaged/`,
package API 62.0), que contém **apenas 2 componentes**:

| Arquivo | apiVersion | status no XML |
|---|---|---|
| `flows/Opp_AS_EvaluarDescuento.flow` | 65.0 | **Obsolete** |
| `flows/Opp_RT_Discount_Approval.flow` | 67.0 | Active |

Portanto: **item D (H6 — Descontos) foi auditado em profundidade** sobre metadata real;
itens A, B, C, E, F, G, H ficam **BLOQUEADO — sem evidência** (não emito veredicto sem
evidência, Regra 2). A boa notícia: os dois flows do zip são exatamente os que Santiago
citou no Teams ("Opp_AS_EvaluarDescuento… às vezes envia e às vezes não"), e o XML
**explica a falha intermitente** — ver §2.

---

## 1. TABELA DE VEREDICTOS

| Item | Subitem | Veredicto | Evidência literal | Correção sugerida (não executada) |
|---|---|---|---|---|
| A | OpportunityStage global | **BLOQUEADO** | sem acesso à org (`sf: command not found`) | Rodar auditoria com auth DevSales |
| B | Business Processes por RT | **BLOQUEADO** | idem | idem |
| C | H2 Estampa de RT (flows Lead_AS_EstampaRTOpp / Opp_BS_EstampaRT) | **BLOQUEADO** | flows não incluídos no zip | Incluir no próximo retrieve |
| D.1 | Flow invoca `runDecisionMatrix` (não `runExpressionSet` — KI) | **PASS** | `Opp_AS_EvaluarDescuento` linhas 8–9: `<actionName>Discount_Rules_GrupoQ</actionName>` `<actionType>runDecisionMatrix</actionType>` | — |
| D.2 | Inputs Marca/Sociedad/País/TipoVenta | **FAIL (parcial)** | Marca=`UPPER(TEXT(Brand__c))` (fórmula `fMarca`), Sociedad=`$Record.CompanyCode__c`, Pais=`$Record.Pais__c` OK; porém TipoVenta é **hardcoded** `<stringValue>Autos</stringValue>` (l.35) | Passar TipoVenta derivado do RecordType da Opp (Autos/Motos/Flotas…) |
| D.3 | Decision null-safe: sem fila na matrix ⇒ requiere aprobación + default | **FAIL** | Decisão `Evaluar_Nivel` (l.271–340): se matrix não retorna fila, todos `vMax*` ficam null, todas as comparações `LessThanOrEqualTo` falham e o **default é `A_NoPermitido`** (`vDecision=NoPermitido`, `vRol=NINGUNO`) — ou seja, sem fila ⇒ **bloqueia** em vez de "requiere aprobación" | Default de `Evaluar_Nivel` deve rotear para RequiereNivel1 + aprobador default (comportamento fail-safe da spec) |
| D.4 | Null-safe do aprobador (sem CMDT/sem User ⇒ default + alerta) | **PASS (com ressalva)** | Decisão `Aprobador_Resuelto` (l.246–270): default → `Set_Default` estampa `DiscountApprover__c` + `Alert_Task`. Ressalva: o default é **ID hardcoded** `005WK00000MzRGSYA3` (l.532) — quebra em qualquer outra org e é ilegível | Substituir por Get Records (username default em CMDT/Custom Setting) |
| D.5 | Flow de avaliação ATIVO | **FAIL (provável)** | `<status>Obsolete</status>` (l.552). O Metadata API devolve a versão **ativa** quando existe; receber `Obsolete` indica que **não havia versão ativa no momento do retrieve** (flow desativado). Confirmar na org | Reativar a versão correta de `Opp_AS_EvaluarDescuento` (após corrigir D.2/D.3/D.7) |
| D.6 | Re-avaliação ao MUDAR o % ("fluxo que revaloriza o desconto") | **FAIL** | Start (l.537–551): `doesRequireRecordChangedToMeetCriteria=true` + filtro `DiscountRequested__c > 0`. Com essa flag, o flow só dispara quando o registro **passa** de não-cumprir para cumprir. Mudar 5%→15% (já >0 antes) **não re-executa** — o nível/aprobador ficam velhos. Contradiz a própria description do flow ("al cambiar el %") | Trocar para "run every time updated to meet conditions" (`doesRequireRecordChangedToMeetCriteria=false`) ou condição de fórmula com `ISCHANGED(DiscountRequested__c)` |
| D.7 | Ordem interna: estampar aprobador vs notificação | **FAIL** | Caminho (l.423–485, 69–112): `Get_NotifType` → `Add_Recipient` → `Notificar_Aprobador` → **só então** `Set_Aprobador`. Não há **nenhum fault connector**. Se o `CustomNotificationType` `Opp_Discount_Approver` não existir ou a notificação falhar, o flow morre **antes** de gravar `DiscountApprover__c` ⇒ a aprovação nunca dispara | Mover `Set_Aprobador` para antes da notificação e adicionar fault paths |
| D.8 | Approval (orquestração) existe e roteia pelo aprobador do CMDT | **PASS (indireto)** | `Opp_RT_Discount_Approval` (ApprovalWorkflow, Active): assignee `$Record.DiscountApprover__r.Username` (l.19–24) — o campo é resolvido do `Aprobador_Config__mdt` pelo flow de avaliação. Roteamento **indireto** via campo, não re-consulta o CMDT | — (aceitável; documentar dependência) |
| D.9 | Entry conditions da orquestração coerentes | **FAIL** | Start (l.86–107): exige `DiscountApprovalDecision__c StartsWith "Requiere"` AND `DiscountApprover__c != null` AND `DiscountRequested__c >= 1.0`. O flow de avaliação dispara com `> 0`: descontos entre 0% e 1% ganham decisão "Requiere…" mas a aprovação **nunca é lançada**. Nota: o print do Santiago mostra exatamente 1,00% (borda) | Alinhar o limiar (>0 nos dois, ou >=1 nos dois) |
| D.10 | Re-solicitação (mesmo nível/aprobador) relança aprovação | **FAIL** | Start da orquestração também tem `doesRequireRecordChangedToMeetCriteria=true` (l.85). Se a Opp **já cumpria** as condições (decisão "RequiereNivel1" e aprobador estampados de tentativa anterior), uma nova edição do % **não relança** a aprovação — não há transição não-cumpre→cumpre | Definir campo de "solicitud #"/reset dos campos ao reprovar, ou remover a flag com guarda anti-loop |
| D.11 | Pós-aprovação escreve resultado na Opp | **FAIL** | A orquestração tem 1 stage / 1 step (`standard_approvals__ReviewAppvlRqst`, l.15–57) e **nenhum** passo pós-aprovação: `approvalDecision`/`approvalComments` saem `xsi:nil` e nada estampa "Aprobado/Rechazado" na Opportunity | Adicionar step pós-approval que atualize `DiscountApprovalDecision__c` |
| D.12 | Decision Matrix `Discount_Rules_GrupoQ` ativa; versões | **BLOQUEADO** | referenciada pelo flow (l.8), mas a matrix em si não veio no zip | Retrieve `DecisionMatrixDefinition` + versões |
| D.13 | Expression Set desativado com descrição do KI | **BLOQUEADO** | não incluído no zip | Retrieve `ExpressionSetDefinition` |
| D.14 | CMDT `Aprobador_Config__mdt` ~18 filas, campos, placeholders, tokens VP_*/país órfãos | **BLOQUEADO (com nota)** | Flow consome `DeveloperName`=token e `Username__c` (l.433–439, 475–481). **Nota:** o flow TEM braço Nivel3 usando `vRolVP` (l.184–206) — se a escada oficial termina em Gerente Marca, os tokens VP_* **não são órfãos para o flow**, e sim para o CMDT; conferir na org | Query `Aprobador_Config__mdt` na org |
| E | H4 VRs por etapa | **BLOQUEADO** | sem acesso | — |
| F | H5 Paths | **BLOQUEADO** | sem acesso | — |
| G | H3 Motos (TipoMoto__c/Cilindrada__c; gate crediticio AUSENTE) | **BLOQUEADO** | sem acesso | — |
| H | H7 Pricebook coherence | **BLOQUEADO** | sem acesso | — |

---

## 2. DIAGNÓSTICO DA QUEIXA DO SANTIAGO ("às vezes envia e às vezes não")

O comportamento intermitente **não é aleatório** — é a interseção de 5 defeitos determinísticos
(D.5, D.6, D.7, D.9, D.10). Cenários concretos:

1. **Nunca envia (flow inativo):** a versão recuperada de `Opp_AS_EvaluarDescuento` está
   `Obsolete` — se o flow está desativado na org, Opps novas nunca ganham
   `DiscountApprover__c`, e sem aprobador a orquestração não entra (filtro l.94–99).
   Opps antigas (estampadas quando o flow estava ativo) ainda disparam ⇒ "às vezes sim".
2. **Envia só na 1ª vez (D.10):** depois de uma primeira solicitação, a Opp já cumpre as
   entry conditions da orquestração. `doesRequireRecordChangedToMeetCriteria=true` exige
   *transição*; re-editar o % com o mesmo nível/aprobador não relança nada.
3. **Não re-avalia (D.6):** mudar o % de um valor >0 para outro >0 não re-executa a
   avaliação — decisão/aprobador ficam do cálculo anterior (ou vazios).
4. **Morre antes de estampar (D.7):** qualquer falha na custom notification
   (`Opp_Discount_Approver` ausente, destinatário inativo) aborta o flow **antes** do
   `Set_Aprobador` — sem fault path. Decisão fica estampada ("RequiereNivel1", como no
   print), aprobador não ⇒ orquestração não entra. Exatamente o estado do screenshot.
5. **Borda de 1% (D.9):** avaliação dispara com >0; orquestração exige ≥1.0. Descontos
   fracionários (<1%) que exijam aprovação ficam presos para sempre.

**Sobre "se hace por Work Guide no por approval process":** correto e esperado —
`Opp_RT_Discount_Approval` é uma **Flow Approval Orchestration** (`processType=ApprovalWorkflow`,
step `standard_approvals__ReviewAppvlRqst`), não um Approval Process clássico. Os work items
aparecem no componente **Work Guide** da record page (e em Approval Requests), não em
"Approval History". O print "You have no assigned work items for this record" significa que
**a orquestração não foi lançada para aquele registro** (pelos motivos 1–4 acima), não que o
Work Guide esteja quebrado. Pré-condição de UX: o componente Work Guide precisa estar na
record page dos perfis aprovadores.

---

## 3. GAP LIST — ORDEM DE EXECUÇÃO PARA FECHAR O US-025/H6

| # | Ação | Dono provável | Dependência |
|---|---|---|---|
| 1 | Confirmar/reativar `Opp_AS_EvaluarDescuento` (versão correta) — hoje retrieve devolve `Obsolete` | Santiago | — |
| 2 | Corrigir gatilho de re-avaliação (D.6): disparar a cada mudança de `DiscountRequested__c` | Santiago | 1 |
| 3 | Reordenar `Set_Aprobador` antes de `Notificar_Aprobador` + fault connectors (D.7); confirmar que o `CustomNotificationType` `Opp_Discount_Approver` existe na org | Santiago | 1 |
| 4 | Alinhar limiar >0 vs ≥1.0 entre os dois flows (D.9) | Santiago | — |
| 5 | Corrigir default do `Evaluar_Nivel` para fail-safe "requiere aprobación" quando a matrix não retornar fila (D.3) | Santiago | — |
| 6 | Derivar `TipoVenta` do RecordType em vez de hardcode "Autos" (D.2) — senão Motos/Flotas avaliam com caps de Autos | Santiago | Matrix ter filas por TipoVenta (verificar — bloqueado) |
| 7 | Remover ID hardcoded `005WK00000MzRGSYA3` do aprobador default (D.4) | Santiago | — |
| 8 | Definir mecânica de re-solicitação (D.10): reset de `DiscountApprovalDecision__c`/`DiscountApprover__c` ao rejeitar, ou contador de solicitação | Arquiteto (decisão de desenho) + Santiago | — |
| 9 | Adicionar passo pós-aprovação estampando resultado na Opp (D.11) | Santiago | 8 |
| 10 | Garantir componente **Work Guide** na record page de Opportunity para os perfis aprovadores | Santiago | — |
| 11 | Auditoria live dos itens A–C, E–H (stages, BPs, estampa RT, VRs, Paths, Motos, pricebook) + CMDT/Matrix/Expression Set | Diego (rodar com auth DevSales) | Credencial DevSales |

---

## 4. ACHADOS FORA DE SPEC

1. **`Opp_AS_EvaluarDescuento` retrieve = `Obsolete`** — flow central do H6 aparentemente sem versão ativa (D.5).
2. **ID de usuário hardcoded** no flow (`005WK00000MzRGSYA3`) — não portável entre orgs.
3. **Braço Nivel3/VP ativo no flow** (`A_N3`/`vRolVP`/`vMaxVP`) enquanto o critério define a escada terminando em Gerente Marca — ou a spec está desatualizada ou o flow tem um nível a mais; os tokens VP_* não podem ser tratados como órfãos sem essa decisão.
4. **`Alert_Task` sem OwnerId** (l.404–422) — a Task de alerta fica com o usuário que editou a Opp (o vendedor), não com quem mantém o CMDT; o alerta provavelmente nunca é visto por quem pode corrigir.
5. **Nenhum fault connector em todo o flow de avaliação** — qualquer erro é silencioso para o processo (só flow error email).
6. **Descrição do flow contradiz a implementação** — description diz "al cambiar el %", mas a flag `doesRequireRecordChangedToMeetCriteria` impede exatamente isso.

---

## 5. PRONTIDÃO PARA O E2E (H9) — pré-condições dos 8 passos

| Passo do roteiro | Pré-condição | Estado |
|---|---|---|
| 1. Criar Opp por RT (estampa automática de RT) | `Opp_BS_EstampaRT` ativo, `Lead_AS_EstampaRTOpp` inativo | ✗ não verificável (bloqueado) |
| 2. Percorrer etapas do BP por RT | Tabela A implantada + BPs por RT | ✗ não verificável (bloqueado) |
| 3. VRs bloqueando avanço sem campos | H4 ativo | ✗ não verificável (bloqueado) |
| 4. Path com guidance por RT | H5 implantado | ✗ não verificável (bloqueado) |
| 5. Solicitar desconto ⇒ avaliação de nível | `Opp_AS_EvaluarDescuento` **ativo** e re-avaliando a cada mudança | ✗ **FALHA CONHECIDA** (D.5/D.6) |
| 6. Aprobador nominal estampado via CMDT | D.7 corrigido + CMDT com filas reais (sem placeholder) | ✗ **FALHA CONHECIDA** (D.7) / CMDT bloqueado |
| 7. Aprovação chega ao aprobador (Work Guide) | Orquestração entra (D.9/D.10) + Work Guide na página | ✗ **FALHA CONHECIDA** (intermitente — §2) |
| 8. Resultado da aprovação refletido na Opp | Passo pós-aprovação existir | ✗ **AUSENTE** (D.11) |

**Conclusão:** o E2E do H9 **não está pronto**. Do que é observável, o H6 tem 6 defeitos
concretos (D.3, D.5, D.6, D.7, D.9, D.10, D.11) que explicam integralmente o comportamento
relatado por Santiago. Os passos 1–4 dependem de nova sessão com autenticação na DevSales.
