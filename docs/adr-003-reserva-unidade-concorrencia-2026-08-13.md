# ADR-003 — Como impedir que dois assessores peguem o mesmo veículo (reserva de unidade no fluxo guiado)

**Data:** 13/08/2026 · **Pergunta do Davi:** *"como a gente vai reservar o item pra outro usuário não pegar o mesmo veículo?"*
**Status:** desenho fechado — 3 limites oficiais de plataforma obrigam esta forma.

---

## A solução: retenção em DOIS níveis

| Nível | Onde | Quando | Duração | Autoridade |
|---|---|---|---|---|
| **1. Retenção temporal (soft hold)** | **Salesforce** — campos na `Vehicle` | O assessor **seleciona** a unidade no modal | 15 min retail / 45 min flotas (US-SAL-03-01B/C) | Salesforce (a unidade nem chegou ao SAP) |
| **2. Reserva firme (bloqueio de estoque)** | **SAP** — Z301 | A cotização é confirmada/aceita | Prazo por marca/sociedade (HU-119 RN-21) | **SAP** (é ele quem bloqueia e libera o estoque) |

O nível 1 protege exatamente a janela perigosa: os minutos entre **escolher** a unidade e **confirmar** a cotização. O nível 2 é o que já existe no fluxo (`ZQEV_SSA_CREA_ORD_VEH` cria a Z301 = oferta/reserva — confirmado no doc SAP de 22/07).

## O mecanismo anti-colisão: `FOR UPDATE` na linha da unidade

Sem lock, dois assessores leem "livre" no mesmo instante e **os dois** escrevem: ambos acreditam ter reservado. É a mesma classe de bug que já corrigimos no pedido duplicado.

```apex
/**
 * Retención temporal de la unidad. Transacción CORTA a propósito:
 * lock + DML, sin callouts ni lógica pesada (ver TRAMPA 1 y 2).
 */
public static RetencionResult tomarRetencion(Id vehicleId, Id quoteId, Integer minutos) {
    // LOCK: serializa a los asesores que compiten por la MISMA unidad.
    // El segundo espera y luego LEE el estado ya actualizado por el primero.
    List<Vehicle> filas = [
        SELECT Id, Name, ReservationExpiry__c, ReservationBy__c, ReservationBy__r.Name, Status
        FROM Vehicle WHERE Id = :vehicleId FOR UPDATE
    ];
    if (filas.isEmpty()) { throw new ReservaException('Unidad no encontrada.'); }
    Vehicle v = filas[0];

    Boolean retenidaPorOtro = v.ReservationExpiry__c != null
        && v.ReservationExpiry__c > System.now()
        && v.ReservationBy__c != UserInfo.getUserId();

    if (retenidaPorOtro) {
        // NO lanza excepción: devuelve para que la UI muestre un mensaje claro
        return RetencionResult.rechazada(v.ReservationBy__r.Name, v.ReservationExpiry__c);
    }
    // libre, expirada, o es MI propia retención (renovar es válido)
    v.ReservationExpiry__c = System.now().addMinutes(minutos);
    v.ReservationBy__c = UserInfo.getUserId();
    v.ReservationQuoteId__c = quoteId;
    update v;                       // el lock se libera al terminar la transacción
    return RetencionResult.tomada(v.ReservationExpiry__c);
}
```

**Liberação:** (a) automática — Scheduled Flow a cada 5 min limpa `ReservationExpiry__c < now`; (b) explícita — ao cancelar/fechar o modal ou trocar de unidade; (c) natural — ao virar reserva firme no SAP (nível 2), o estado da unidade passa a vir do SAP por INT-SAL-06.

## As três armadilhas oficiais que obrigam este desenho

**1. O lock espera no máximo 10 segundos** e depois falha com `UNABLE_TO_LOCK_ROW` / `QueryException`. O timeout **não é configurável**. Consequência de desenho: a transação que pega a retenção precisa ser **curta** — lock + DML e nada mais. Nunca segurar o lock enquanto se faz processamento pesado ou espera de terceiros.

**2. Callout depois de DML é proibido** — `"You have uncommitted work pending. Please commit or rollback before calling out"`. Isso **prova** que os dois níveis não podem viver na mesma transação: a retenção (DML no Vehicle) e a chamada ao SAP (callout da Z301) **têm** que ser transações separadas. A Z301 sai depois — na confirmação do usuário ou por Queueable/evento. Não é escolha de estilo: é regra da plataforma.

**3. `cacheable=true` na busca de unidades serviria dados de cache** — um assessor veria como livre uma unidade já retida há um minuto. A consulta de disponibilidade de unidades **não pode ser cacheable** (ou precisa de `refreshApex` antes de exibir). Mesmo raciocínio que aplicamos em `checkRepuestosAvailability`.

## O que o outro assessor vê (LWC)

- **Autoridade = servidor.** A verificação real acontece no `tomarRetencion`: a UI nunca decide sozinha. Se perdeu a corrida, o retorno traz *quem* retém e *até quando*.
- **Tempo real (recomendado):** publicar um Platform Event ao reter/liberar e o modal assinar com **`lightning/empApi`**. É o padrão oficial para "outro usuário mudou o registro" — `refreshApex` só resolve quando a mudança foi do próprio usuário. As tarjetas dos outros assessores passam a mostrar *"Reservado por Ana hasta 11:29"* e o botão desabilita sem ninguém recarregar a página.
- **UX:** nunca erro cru. Card marcado, contador de expiração, e ao expirar volta a ficar selecionável sozinho.

## Estado atual e o que falta

- ✅ O padrão de lock já está em produção no fluxo (pedido duplicado e sync de linhas) — é o mesmo mecanismo, mesma fundamentação.
- ❌ Os campos `ReservationExpiry__c`, `ReservationBy__c` (e `ReservationQuoteId__c`) **ainda não existem na org** — não apareceram no GAPCHECK. É o primeiro passo do pacote.
- ❌ Scheduled Flow de liberação + Platform Event de retenção: a construir.
- **Escopo:** retenção temporal aplica-se a **unidades** (veículos, com VIN). **Não** se aplica a repuestos — peça não é unidade única e o saldo é do SAP (HU-043 RN4).
- **Alternativa considerada e descartada:** objeto de reserva separado com VIN único (a unicidade do banco também resolveria). Descartado por não precisar de objeto novo: o lock na própria `Vehicle` resolve com menos peças.

## Fontes

- SOQL `FOR UPDATE` / Locking Statements — Apex Developer Guide; timeout de bloqueio de 10 s não configurável e `UNABLE_TO_LOCK_ROW` (documentação e prática consolidada da plataforma).
- "You have uncommitted work pending" — regra de callout após DML; padrão de separar DML e callout em transações (Queueable).
- `lightning/empApi` — Platform Events Developer Guide, "Subscribe to Platform Event Notifications in a Lightning Component" (API 44+).
- US-SAL-03-01B/C (15 min retail / 45 min flotas, "lógica 100% Salesforce — STAR no cubre") e HU-050/051.
- Doc SAP 22/07: `ZQEV_SSA_CREA_ORD_VEH` cria a Z301 (oferta/reserva) — o bloqueio real de estoque.
