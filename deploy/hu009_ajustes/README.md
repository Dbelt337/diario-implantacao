# HU-009 — Pacote de ajustes pré-demo (VR Sucursal + flows v3.1/v1.2)

**Origem:** validação de 2026-07-14 (`tests/HU-009-validacao-flows.md`) + pedidos do teste
(alertar Sucursal vazia; encerrar o Event ao receber).

## Conteúdo

| Componente | Versão | O que muda |
|---|---|---|
| `Event.HU009_Visita_Requiere_Sucursal` (VR, nova) | 1.0 | Bloqueia Event vinculado a Opportunity (`LEFT(WhatId,3)="006"`) sem `BranchCode__c`, com mensagem apontando o campo. Cobre criação por calendário/API, onde o layout da action não protege |
| `Event_AfterSave_ShareBranchHandOff` | v3.1 | Estampa `VisitStatus__c = Pendiente` quando em branco (fecha o P0-2 sem depender de default de picklist). Seguro: flag de entrada impede re-disparo |
| `Opportunity_Screen_ReceiveCustomer` (Recibir Cliente) | v1.2 | (a) Encerra a visita por completo: `Atendida` + **OwnerId do Event → asesor presencial** (a visita cai no calendário dele); (b) faultConnector nos dois DMLs → tela de erro amigável com `$Flow.FaultMessage` (asesor inativo, VR etc. não explodem mais na cara do usuário) |

## Passo manual complementar (2 min, sem deploy)

Setup → Global Actions → **New Event** → Layout → marcar **Sucursal como Required**
(chave inglesa no campo). Primeira linha de defesa com UX nativa; a VR é a rede de segurança.

## Decisões de desenho respondidas

1. **"Encerrar" o Event:** Event não tem fechamento nativo (diferente de Task, não existe
   IsClosed/Status). O encerramento do processo é `VisitStatus = Atendida` + transferência
   do Owner; a hora REAL da recepção já fica em `HandOffDate__c` na Opp. Não re-datamos o
   Event (manter o horário agendado preserva o histórico do compromisso).
2. **Action Recibir Cliente fica na OPPORTUNITY**, não no Event. Motivos: (a) o walk-in
   (Escenario 10) não tem Event — na Opp a recepção atende os dois casos com um botão;
   (b) a bancada da recepção é list view de Opps → abrir → clicar, sem caçar a atividade
   na timeline; (c) o objeto transferido é a Opp — a action mora onde está o efeito;
   (d) record page de Event mal é usada no Lightning (eventos abrem em popover de
   calendário, onde dynamic actions não aparecem).

## Trade-off da VR (registrar com o negócio)

A VR exige Sucursal em **todo** Event ligado a Opportunity. No processo GrupoQ isso é o
desenho (Event sobre Opp = visita). Se algum dia o negócio registrar outros tipos de
compromisso sobre Opps (ex.: reunião virtual), será preciso um marcador de tipo de visita
para condicionar a VR — decisão de negócio, não técnica.

## Deploy

Workbench (zip `hu009_ajustes.zip`) ou
`sf project deploy start --metadata-dir deploy/hu009_ajustes -o DevSales`.
Pós-deploy: testar (1) Event sem sucursal → erro da VR no campo; (2) fluxo completo →
Event vira Atendida e aparece no calendário do asesor presencial; (3) Recibir com
asesor inativo → tela de erro amigável (não unhandled fault).
