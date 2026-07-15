# HU-009 — Validação dos flows (pré-demo) — 2026-07-14

> **ATUALIZAÇÃO 2026-07-15 00:05 UTC — ajustes DEPLOYADOS (success: true):**
> VR `HU009_Visita_Requiere_Sucursal` (alerta de Sucursal vazia), Flow B v3.1
> (P0-2 resolvido: estampa `VisitStatus=Pendiente`) e Recibir Cliente v1.2
> (P1-3/P1-4 resolvidos: encerra o Event — Atendida + Owner ao asesor presencial —
> e fault path com tela amigável). Pacote: `deploy/hu009_ajustes/`.
> O aviso *Info* de System Mode without Sharing no deploy é esperado e intencional
> (Escenario 10 + transferência sem permissão de Transfer Records; documentado na
> description do flow). **Pendentes manuais:** P0-1 escopo da list view (All
> Opportunities), Sucursal required no layout da action, VisitStatus no layout do
> Event, checklist pré-demo abaixo.

**Fonte:** `metadata_43.zip` — `Event_AfterSave_ShareBranchHandOff` (Parte B, Active, API 63)
e `Opportunity_Screen_ReceiveCustomer` / "Recibir Cliente" (Parte C, Active, screen flow,
`SystemModeWithoutSharing`). Análise 100% por XML.

## Veredicto por contrato do desenho

| Contrato | Veredicto | Evidência |
|---|---|---|
| Event de Account sai sem fazer nada | ✅ | Entry: `WhatId StartsWith "006"` + `BranchCode__c` not null — nem entra no flow |
| Grupo da sucursal por código canônico | ✅ | textTemplate `GRP_Sucursal_{!$Record.BranchCode__c}` + lookup `Group` Type=Regular (workaround de campo de atividade documentado na description) |
| Share Read/Manual na Opp | ✅ | `OpportunityShare`: AccessLevel Read, RowCause **Manual**, UserOrGroupId = grupo |
| Grupo faltante ⇒ Task de log e segue | ✅ | Default → `LogMissingBranchGroup` (Task) → continua para a estampa |
| Falha no share ⇒ log e segue | ✅ | `faultConnector` → `LogShareFault` com `$Flow.FaultMessage` |
| Asesor Originador imutável | ✅ | Decisão `AdvisorAlreadyStamped`: só estampa se em branco; Recibir não toca no campo |
| Pendiente Recepción estampado | ✅ | Nos dois braços da decisão |
| Sem recursão / não desfaz a recepção | ✅ | `doesRequireRecordChangedToMeetCriteria=true`: o update do Event no Recibir (Atendida) não re-dispara o share nem re-estampa Pendiente |
| Recibir: owner + data + Recibido + Atendida | ✅ | `ReceiveCustomer` + `MarkVisitAttended` |
| System mode justificado (Read-only transfere; walk-in Escenario 10) | ✅ | `runInMode SystemModeWithoutSharing` + braço "No visit (walk-in)" |
| Limpeza nativa do share na troca de Owner | ✅ | RowCause Manual + troca de OwnerId ⇒ plataforma deleta (nada a construir) |

## 🔴 P0 — quebram a demo (corrigir HOJE)

1. **List view "Pendiente Recepción" está com escopo "My opportunities"** (visível no
   print: "Filtered by My opportunities • Estado Hand-Off"). Funciona para o admin dono
   das opps de teste, mas a RECEPCIONISTA verá lista VAZIA — as opps do hand-off nunca
   são dela, chegam por share. **Correção:** escopo → *All Opportunities* (filtros:
   `HandOffStatus__c = Pendiente Recepción`; o sharing cuida do resto).
2. **Nada no pacote estampa `VisitStatus__c = "Pendiente"` no Event.** O Recibir busca
   `VisitStatus__c = 'Pendiente'` para marcar Atendida — se o campo nasce em branco
   (sem default de picklist), a visita NUNCA é encontrada e cai silenciosamente no braço
   walk-in (não marca Atendida). **Correção (uma das duas):** default "Pendiente" no
   campo `Activity.VisitStatus__c`, ou o Flow B estampar Pendiente ao rodar (update do
   $Record é seguro: a flag de entrada impede re-disparo).

## 🟡 P1 — arrumar antes da demo se der tempo

3. **Owner do Event não é transferido no Recibir** ⇒ a visita não aparece no calendário
   do asesor presencial (pedido do item "calendário pronto para o vendedor de piso").
   Correção de 1 campo: em `MarkVisitAttended`, adicionar `OwnerId = PickAdvisor.recordId`.
   Seguro: o Flow B não re-dispara (flag true, critérios já cumpridos antes).
4. **Flow C sem fault path:** se a troca de Owner falhar (usuário inativo, validation
   rule), o cliente vê "unhandled fault" na tela. Adicionar faultConnector do
   `ReceiveCustomer` → tela de erro amigável. Ligado a isto: o lookup de asesor aceita
   QUALQUER usuário (inclusive inativo) — na demo, escolher um asesor ativo conhecido.

## 🟢 P2 — registrar como limitação/backlog (não bloqueia demo)

5. Mudar `BranchCode__c` de um Event já compartilhado (URUCA→AYARCO) **não re-compartilha**
   com a nova sucursal (flag true + impossibilidade de ISCHANGED em campo de atividade).
   Documentar: mudança de sucursal = cancelar e recriar a visita.
6. Tasks de log (`LogMissingBranchGroup`/`LogShareFault`) sem `OwnerId` ⇒ ficam com quem
   criou o Event (asesor digital), não com admin. Mesmo padrão a corrigir do H6.
7. Se houver 2+ visitas Pendientes na mesma Opp, só a primeira encontrada vira Atendida.
8. O gate do botão é só visibilidade (Custom Permission); o flow em si roda para quem
   tiver a URL. Aceito no desenho — registrar.

## Sobre "o alerta está demorando"

O popup "Visita al Showroom" do print é o **reminder nativo do Event** (sino), que a
plataforma entrega por polling — minutos de atraso são normais e NÃO fazem parte da
HU-009. O que a HU garante é síncrono: share + status + list view ficam prontos no
mesmo save do Event. **Na demo: não usar o popup como prova — usar o refresh da list
view da recepcionista.** Se o negócio quiser aviso ativo à sucursal, é um
`customNotificationAction` no Flow B (mesmo padrão do H6) — backlog, não para amanhã.

## Checklist pré-demo (itens fora do zip — conferir na org)

- [ ] List view com escopo All Opportunities (P0-1)
- [ ] `VisitStatus__c` default Pendiente OU estampa no Flow B (P0-2)
- [ ] `PS_Branch_Reception` + Custom Permission `ReceiveCustomer` existem e atribuídos
      (recepcionista, gerente sucursal, admin) — **não vieram no deploy** (só
      `PS_Base_Sales_GrupoQ`); foram criados à mão?
- [ ] Dynamic Action na record page com visibility `$Permission.ReceiveCustomer`
- [ ] Recepcionista dentro do `GRP_Sucursal_*` da demo
- [ ] Campo Sucursal (BranchCode) no layout da Global Action New Event + FLS
- [ ] Usuário asesor presencial ATIVO escolhido de antemão para o clique do Recibir
- [ ] Ensaio completo com login-as na recepcionista (não validar como admin)
