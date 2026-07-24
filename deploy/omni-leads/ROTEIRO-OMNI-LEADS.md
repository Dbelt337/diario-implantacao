# Roteamento de Leads via Omni-Channel — roteiro de configuracao por ambiente

Objetivo: deixar o lead criado (integracao ou manual) caindo automaticamente
no assessor online via fila da Costa Rica + Omni-Channel. Perfil alvo:
Name real no org = "Agente BDC / AVO" (codigo do glossario: AC_BDC_Ag).
Atencao: existe tambem um perfil chamado so "Agente" — nao confundir.
Aplicavel a qualquer ambiente (QA/UAT/PROD); escrito na sequencia de
dependencias — executar na ordem. Itens ja existentes: verificar e pular.

Cadeia completa (se qualquer elo faltar, o lead fica parado):
lead criado -> entra na fila CR -> fila tem routing config -> routing config
aponta ao service channel de Lead -> assessor e membro da fila -> assessor
online num presence status que inclui o canal -> tem capacidade -> tem o
widget Omni no app.

## Passo 0 — Diagnostico: o que ja existe no ambiente

Rodar no Workbench (SOQL) e anotar os resultados:

    SELECT Id, MasterLabel, DeveloperName, RelatedEntity FROM ServiceChannel

    SELECT Id, Name, DeveloperName, RoutingPriority, RoutingModel,
           CapacityWeight FROM QueueRoutingConfig

    SELECT Id, Name, DeveloperName, QueueRoutingConfigId, Type
    FROM Group WHERE Type = 'Queue'

    SELECT QueueId, Queue.Name, SobjectType FROM QueueSobject
    WHERE SobjectType = 'Lead'

    SELECT Id, MasterLabel, DeveloperName FROM ServicePresenceStatus

    SELECT Id, MasterLabel, DeveloperName FROM PresenceUserConfig

Leitura: se o ServiceChannel de Lead, a routing config e a fila com
QueueRoutingConfigId preenchido ja existirem, os passos 1-3 estao prontos —
o trabalho e so dos passos 4 em diante (gente, nao estrutura).

## Passo 1 — Service Channel do Lead

Setup > Omni-Channel > Service Channels > New.
- Salesforce Object: Lead. Nome sugerido: canal de leads digitais.
So precisa existir UM por objeto.

## Passo 2 — Routing Configuration

Setup > Omni-Channel > Routing Configurations > New.
- Routing Model: Least Active (equilibra carga) ou Most Available.
- Units of Capacity / Capacity Weight do lead: definir (ex.: 1 unidade).
- Push time-out recomendado (ex.: 30-60s) para o lead nao morrer na tela de
  quem se afastou sem mudar o status.

## Passo 3 — Fila da Costa Rica ligada ao Omni

Setup > Queues > (fila CR de leads).
- Supported Objects: Lead.
- Routing Configuration: a do passo 2. E ESTE vinculo que transforma a fila
  em fila Omni. Fila sem routing config = lead entra e nunca e ofertado.

## Passo 4 — Presence Statuses + permission set

Setup > Omni-Channel > Presence Statuses:
- Status online (ex.: "Disponible Leads") com o Service Channel do passo 1
  incluido. Statuses de ausencia (Almuerzo, Capacitacion...) sem canal.
- Acesso dos usuarios: via permission set (PS_OmniChannel_Ventas ja faz esse
  papel — conferir em Setup > Permission Sets > Service Presence Statuses
  Access que o status de leads esta na lista) ou profile.
- ERRO CLASSICO: usuario online num status que nao inclui o canal de Lead —
  nunca recebe nada.

## Passo 5 — Presence Configuration (capacidade)

Setup > Omni-Channel > Presence Configurations.
- Capacity total do assessor (ex.: 5-10 unidades), se aceita/recusa,
  auto-accept. Usuarios entram na configuration por perfil ou por usuario.
- Lead com peso maior que a capacidade livre nao e ofertado.

## Passo 6 — Membresia da fila (gente)

Os assessores (ou o grupo publico de AVOs) precisam ser MEMBROS da fila CR.
Manual: Setup > Queues > fila CR > Queue Members.
Em massa via Apex anonimo (idempotente):

    // Adiciona todos os usuarios ativos do perfil na fila (via GroupMember)
    String queueDevName = 'NOME_DEV_DA_FILA_CR';   // ajustar
    // Name real do perfil no org (o codigo AC_BDC_Ag e so do glossario)
    List<String> profileNames = new List<String>{ 'Agente BDC / AVO' };
    Group fila = [SELECT Id FROM Group
                  WHERE Type = 'Queue' AND DeveloperName = :queueDevName LIMIT 1];
    List<User> users = [SELECT Id FROM User
                        WHERE IsActive = true AND Profile.Name IN :profileNames];
    Set<Id> existentes = new Set<Id>();
    for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember
                           WHERE GroupId = :fila.Id]) {
        existentes.add(gm.UserOrGroupId);
    }
    List<GroupMember> novos = new List<GroupMember>();
    for (User u : users) {
        if (!existentes.contains(u.Id)) {
            novos.add(new GroupMember(GroupId = fila.Id, UserOrGroupId = u.Id));
        }
    }
    insert novos;
    System.debug('Membros novos: ' + novos.size() + ' | Ja eram: ' + existentes.size());

Se a fila usa grupo publico como membro, rodar o mesmo script trocando a
query do Group (Type = 'Regular' e o DeveloperName do grupo).

## Passo 7 — Widget do Omni no app

Setup > App Manager > (app GrupoQ Ventas) > Edit > Utility Items >
Add Utility Item > Omni-Channel > Save.
Sem o widget na utility bar, o assessor nem consegue ficar online.

## Passo 8 — Entrada do lead na fila

Conferir COMO o lead chega na fila CR (uma das duas):
- Record-triggered flow que seta OwnerId = fila: roda sempre, inclusive
  criacao via API da integracao. Preferido.
- Lead Assignment Rules: so rodam na criacao via API se a chamada enviar o
  header de atribuicao (AssignmentRuleHeader/useDefaultRule). Se a
  integracao nao envia, o lead fica com o usuario de integracao e NUNCA
  entra na fila. Validar com o time do Mule.

## Passo 9 — Supervisor (as Gerentes Online)

Setup > Omni-Channel > Supervisor Configurations: incluir as gerentes
(UAT: Johana Bonilla, Susana Segura; Motos: Alexis Mayorga se aplicar).
Acesso pela aba/app Omni Supervisor: filas, agentes, tempos em tempo real.

## Roteiro de teste (apos os passos)

P1. Assessor de teste: widget visivel no app; consegue selecionar o status
    "Disponible Leads" (se o status nao aparece, falhou o passo 4).
P2. Criar um lead manual e atribuir a fila CR: o lead e ofertado ao unico
    assessor online em segundos. Aceitar: owner vira o assessor.
P3. Criar lead pela integracao (ou simulando o payload): mesmo resultado —
    valida o passo 8 no caminho real.
P4. Dois assessores online: criar 2+ leads e verificar distribuicao
    conforme o routing model.
P5. Visibilidade: antes do aceite, membros da fila veem o lead; depois do
    aceite, apenas o dono + hierarquia acima (OWD Private).
P6. Omni Supervisor: gerente ve filas e agentes.

Diagnostico rapido quando "o lead nao cai": abrir o Omni Supervisor.
- Lead esperando na fila + assessor online = status sem o canal de Lead,
  capacidade cheia, ou assessor nao e membro da fila.
- Lead nem aparece na fila = falhou a entrada (passo 8).

## Governanca
- ServiceChannel, QueueRoutingConfig, Queue, PresenceUserConfig e
  ServicePresenceStatus sao deployaveis via Metadata API — se ja existem no
  ambiente de origem, da para levar por pacote em vez de recriar a mao.
  Membresia de fila/grupo e dado (GroupMember) — sempre por ambiente.
- Registrar na DLG os componentes novos criados por este roteiro no mesmo
  dia, com a HU de origem do roteamento de leads.
