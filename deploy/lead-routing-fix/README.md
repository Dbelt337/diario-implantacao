# Lead Routing — Fix do re-roteamento (bounce) no update

## Problema
`Lead_TriggerOmniRouting` (record-triggered, CreateAndUpdate) re-invocava o
roteamento Omni sempre que um **campo de critério** mudava no update
(Brand__c, CompanyCode__c, Industry). Como `routeWork` sempre cria nova
solicitação, um Lead **já atribuído a um vendedor** voltava pra fila e era
redistribuído (relato do Marcelo).

## Causa
- O gatilho dispara em create E update, sem trava pra Lead já atribuído.
- Não é conflito com as Assignment Rules: `Lead_Routing_GrupoQ` atribui a
  **filas** por Industry/Sociedad (estágio 1). O Omni tira da fila e manda pro
  **agente** (estágio 2). Desenho de 2 estágios válido. O bug é só o re-disparo.

## Correção (nativa, sem campo custom)
Uma Decision `Deve_Rotear` no início do caminho assíncrono:
- **Só rotear quando `OwnerId` começa com `00G` (Fila)** — fórmula `fOwnerEsFila`.
- Owner já é vendedor (`005`) → **não roteia** (elimina o bounce).

### Comportamento por canal (confirmado com o cliente)
- Lead via **API/inbound** → Assignment Rules põem na fila (00G) → roteia. ✅
- Lead via **UI que fica com o criador** (owner = usuário `005`) → **mantém com o
  criador**, Omni não mexe. ✅ (decisão de negócio: "UI mantém com o criador")
- Lead **já aceito por vendedor** e editado → não re-roteia. ✅
- Lead **devolvido pra fila** de propósito → roteia de novo. ✅

## Deploy
```
sf project deploy start -x deploy/lead-routing-fix/package.xml -o <org>
```
(ou via VS Code / Workbench). Testar depois:
1. Criar Lead via API → confirmar que roteia (owner vira agente após aceite).
2. Criar Lead na UI que fica com o usuário → confirmar que NÃO roteia.
3. Editar (Brand/Sociedad/Industry) um Lead já atribuído → confirmar que NÃO
   volta pra fila.

## Pendências / observações
- Versão **Active** do subflow é **`LeadRouting_OmniFlow` V8** (a exportada era a
  V11/Deactivated). O fix é no gatilho, não depende do subflow — mas pegar a V8
  se um dia mexer na lógica de afinidade.
- **Simplificar (opcional):** o gatilho recalcula a própria fila (5 filas) que
  não bate com as 9 filas das Assignment Rules. Consolidar o mapa
  Industry/Sociedad→fila num lugar só pra evitar drift.
