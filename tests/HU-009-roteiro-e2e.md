# HU-009 — Roteiro de teste E2E: Hand-off de visita (Asesor Digital → Sucursal)

**Data:** 2026-07-14 · **Org:** DevSales · **Testador:** Diego

## Ajuste de desenho detectado ANTES do teste

O passo "recepcionista vê a visita na list view" não pode ser list view de **Event**:
Event não tem tab nem list views no Lightning (por isso "Events" não aparece nos
Navigation Items do App Builder). A bancada da recepção deve ser:
- **List view de Opportunity** "Visitas Pendientes de Recepción" — filtro
  `Status de recepción = Pendiente Recepción` + sucursal do usuário; OU
- Relatório de Activities com Opportunities fixado na nav do app.

Do mesmo modo, o "share Read/Manual" do flow só pode ser **OpportunityShare**
(atividades não têm objeto de share). A recepção vê o Event por ter acesso à Opp pai.
O truque nativo (plataforma apaga share Manual na troca de Owner) vale para a Opp.

## Pré-condições (setup — conferir antes de executar)

| # | Item | Como conferir |
|---|---|---|
| P1 | C4: campo `Sucursal` no layout da Global Action "New Event" + FLS (F5) para o perfil do Asesor Digital | Setup → Global Actions → New Event → layout; FLS no PS/perfil |
| P2 | C5: Dynamic Actions na record page da Opp; "Recibir Cliente" com visibility `$Permission.ReceiveCustomer = true` | App Builder → record page da Opp → Highlights/Actions |
| P3 | C7: usuária recepcionista dentro de `GRP_Sucursal_CR_URUCA` | Setup → Public Groups |
| P4 | `PS_Branch_Reception` atribuído: recepcionista ✔, gerente sucursal ✔, vendedor de piso ✘, admin ✔ (recomendado) | Setup → Permission Sets → Manage Assignments |
| P5 | Flow "Recibir Cliente" roda em **System Mode without Sharing** — a recepcionista tem só Read na Opp via share; a troca de Owner falha se rodar no modo do usuário | XML do flow (`runInMode`) |
| P6 | Flow de share ativo e disparando na criação de Event | Setup → Flows |
| P7 | Usuários de teste logáveis: Asesor Digital, Recepcionista (AC_Vend_Veh+PS), Gerente Sucursal, Vendedor sem PS, Asesor presencial (novo owner) | — |

## Cenário 1 — Caminho feliz

| Passo | Ator | Ação | Resultado esperado | Verificação |
|---|---|---|---|---|
| 1 | Asesor Digital | Na Opp, cria Event pela action com `Sucursal = CR_URUCA` | Event criado; nada mais manual | — |
| 2 | (flow share) | automático | Share Manual/Read da **Opp** para `GRP_Sucursal_CR_URUCA`; `Asesor Originador` estampado; status `Pendiente Recepción` | Botão **Sharing** da Opp, ou SOQL: `SELECT UserOrGroupId, OpportunityAccessLevel, RowCause FROM OpportunityShare WHERE OpportunityId='<id>' AND RowCause='Manual'` |
| 3 | Recepcionista | Abre a list view/bancada | Vê a Opp `Pendiente Recepción` da SUA sucursal; consegue abrir e ver o Event na timeline | Login as |
| 4 | Recepcionista | Clica **Recibir Cliente**, escolhe asesor presencial | Owner da Opp = asesor presencial; data + `Recibido` estampados; Event marcado `Atendida` | Campos na Opp/Event |
| 5 | (plataforma) | automático | Share Manual da Opp **sumiu** com a troca de Owner (sem flow de limpeza) | Repetir a SOQL do passo 2 → 0 filas |
| 6 | Recepcionista | Recarrega a bancada | Opp saiu da list view (status mudou e/ou share caiu) | — |

## Cenário 2 — Gate do botão (matriz de visibilidade)

Logar como cada um e abrir a MESMA Opp `Pendiente Recepción`:

| Usuário | Vê "Recibir Cliente"? |
|---|---|
| Recepcionista (AC_Vend_Veh + PS_Branch_Reception) | ✅ |
| Gerente de Sucursal (AC_Ger_Suc + PS) | ✅ |
| Vendedor de piso (AC_Vend_Veh sem PS) | ❌ (e nem vê a Opp, se não for owner/hierarquia) |
| Admin sem PS | ❌ botão (Modify All não dá a Custom Permission) — por isso atribuir o PS |
| Asesor Digital | ❌ |

## Cenário 3 — Desvios previstos no desenho

| # | Estímulo | Esperado |
|---|---|---|
| 3a | Event criado sobre **Account** (WhatId ≠ Opp) | Flow sai sem fazer nada: sem share, sem estampa, sem Task |
| 3b | Event com `Sucursal` sem grupo público correspondente | **Task de log** criada (conferir para QUEM ela fica atribuída — dono definido?) e processo segue sem share |
| 3c | Segundo Event na mesma Opp (outro asesor digital) | `Asesor Originador` **não muda** (imutável — estampa só se em branco) |
| 3d | Event sem valor em `Sucursal` | Definir esperado: hoje o flow trata? (sem grupo → 3b? ou sai?) — registrar comportamento observado |
| 3e | Recibir Cliente numa Opp já `Recibido` | Botão ainda visível? Idempotência — registrar comportamento |

## Riscos a observar durante a execução

1. **P5 é o que mais derruba**: se o flow Recibir Cliente não estiver em system mode,
   a troca de Owner falha para a recepcionista (Read não transfere registro).
2. Visibility rule usa o **API name exato** da Custom Permission (`ReceiveCustomer`);
   typo = botão some para todos.
3. Dynamic Actions + visibility por `$Permission` no **mobile**: testar no app se a
   recepção for usar tablet/celular — comportamento de dynamic actions difere do desktop
   em versões antigas do app.
4. A recepcionista só vê o Event se o acesso à Opp pai estiver de pé ANTES de ela abrir
   (share é criado no after-save do Event — imediato, mas conferir).
5. Grupo público com "Grant Access Using Hierarchies" pode expor a Opp a mais gente que
   o desenho prevê — conferir flag do grupo.

## Resultado (preencher durante o teste)

| Cenário | PASS/FAIL | Observações |
|---|---|---|
| 1 |  |  |
| 2 |  |  |
| 3a–3e |  |  |
