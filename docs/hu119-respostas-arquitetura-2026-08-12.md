# HU-119 (Integración SAP ↔ Salesforce) — respostas de arquitetura aos 8 blocos da Melisa

**Data:** 12/08/2026 · Fundamentação: Automotive Cloud Standard Objects (lista oficial completa — NÃO existe objeto nativo de devolução/integração no Automotive; a integração usa a plataforma), Object Reference (Order/reduction orders, Platform Events), nossa arquitetura já deployada (SapOrderResponse__e + flows handler, SapMuleClient, chaves External ID).

---

## 1. Devolución y anulación (RN-22) — prioridade máxima

**(a) Direção: a solicitação NASCE no Salesforce e o SAP executa.** É a única leitura coerente com o desenho do programa (Salesforce é a origem de todos os fluxos comerciais; SAP executa fiscal/logístico) e com o pedido do Emmanuel (motivo obrigatório + notificação a Logística — ambos vivem naturalmente no SF: campo obrigatório + fila/Custom Notification). O SAP devolve o resultado pelo mesmo canal dos pedidos (evento via Mule).

**Modelagem nativa (o Automotive não tem objeto de devolução — a lista oficial confirma; a plataforma tem o mecanismo exato):** **Reduction Orders** — a Order padrão suporta pedido de redução vinculado à Order original (`OriginalOrderId` + flag de redução), **por linha**: devolve/anula posições específicas referenciando as OrderItems originais. É literalmente "devolución y anulación por línea" nativo. A solicitação = reduction order em rascunho com `MotivoDevolucion__c` obrigatório; aprovada → Mule → documento SAP; retorno → status no reduction order. Veículos, Peças (Z111) e PA usam o MESMO modelo com record types distintos — o que muda é o documento SAP de destino.

**(b) OMS:** não existe decisão registrada que eu possa citar — e é exatamente por isso que não devemos citar. Ação: levar à Technical Weekly a formalização "OMS descartado para devoluções: sim/não" e registrar em ADR (ver bloco 7d). Até lá, a HU segue como está (necessidade registrada, sem compromisso).

**(c) Conflito de códigos Z300/Z301:** a leitura do Escopo/Vane é a que bate com o metadata real da org e com as fases 1–4 (**Z301 = pedido de venda que bloqueia estoque**; é o que nosso pipeline gera). Os códigos do Emmanuel provavelmente são **classes de documento do processo de devolução, ainda não definido no SAP** — e como o próprio fluxo nunca foi definido lá, a regra NÃO deve fixar códigos. Escrever a RN por função ("documento de devolución de vehículos — código a confirmar pelo time SAP"; "Z111 — devoluções de peças, confirmado pela Isabella") e cobrar o catálogo por domínio (bloco 8b).

**(d) Dono do fluxo: história própria.** Devolução é um processo completo (solicitação, aprovação, logística reversa, financeiro) — não cabe numa HU de integração. A HU-119 fica com o TRANSPORTE (contrato do serviço, evento de retorno, estados). Recomendação: criar "HU-Devoluciones y Anulaciones" (uma por linha de negócio se os fluxos divergirem) e a RN-22 vira remissão.

**(e) Impacto:** se o fluxo inteiro entrar: novo objeto de processo não é preciso (reduction orders), mas há UI de solicitação, aprovação, notificações, 1 interface Mule nova por domínio e o desenho SAP inexistente — é escopo novo relevante. Sinalizar como change/nova história, não absorver na 119.

## 2. Vigência de reserva (RN-21)

**(a)** Eu levo as três perguntas ao Emmanuel — são de arquitetura de integração (parâmetro de vigência na Z301; rota da liberação antecipada / se a ZQEV_SSA_MOD_ORD_VEH cobre; notificação de retorno do job).

**(b) São o MESMO prazo com duas fontes — e isso se corrige tornando uma derivada da outra:** o prazo de pagamento por marca/sociedade parametrizado no SAP é a FONTE; ele se replica como configuração no Salesforce (Custom Metadata `PlazoReserva__mdt` por marca+sociedad) e o `ExpirationDate` da cotização é **calculado** a partir dele na criação. RN-21 e Cenário 17 passam a apontar para a mesma origem: parâmetro SAP → config SF → ExpirationDate. Sem dupla fonte.

**(c) Discurso para o JJ (aceite, não negação):** *"Exatamente como você pediu: o processo diário roda no Salesforce — um scheduled job que detecta as cotizações vencidas e dispara a liberação. O que mantivemos no SAP é só o que já é dele hoje: a autoridade final sobre o estoque (a Z301 é quem bloqueia, então é ela quem libera). O Salesforce passa a ser o gatilho comercial — inclusive ANTECIPANDO a liberação no vencimento, sem esperar janela batch — e o job diário do SAP vira rede de segurança para o caso de o aviso não chegar. O benefício que você pediu (liberação rápida, governada pelo CRM) está integral."*

## 3. Pedidos modificados no SAP → Salesforce (RN-06)

**(a) Push do SAP — confirmado, e o canal já existe deployado:** o padrão das fases 1–4 é o SAP/Mule **publicar Platform Event** (`SapOrderResponse__e` + flow `SAP_Order_Response_Handler`) para eventos de ciclo, e **update inbound via API** na Order para dados (é como a fatura entra hoje — `Order_Facturado_Handler`). Modificação de posições = mesmo padrão: SAP dispara ZQEV_DBMPOSICIONES → Mule normaliza → evento/update no SF. Nada de polling.
**(b) Mule sempre no meio** — gateway único é decisão registrada do programa (Named Credential `MuleGateway`, um só ponto de credencial/monitoramento). Chamada direta SAP→SF criaria segundo canal de segurança e mataria o monitoramento centralizado que o próprio JJ pediu (bloco 7).
**(c) PA continua exceção** (já é bidirecional) — unificar agora é retrabalho sem benefício; reavaliar no Release 2.
**(d) Botão manual FICA** — é o nível 3 do nosso padrão de reprocesso (automático → redisparo na correção → manual). Custa quase nada e salva o dia quando o evento se perde.

## 4. Reintentos e reprocessamento (RN-08/RN-09) — defaults de referência (proposta OSF)

| Tipo de interface | Reintento automático | Intervalo | Imediato? | Manual |
|---|---|---|---|---|
| **Síncrona com usuário esperando** (disponibilidade, consulta preço) | 0 — falha rápida com mensagem clara (Esc.7 da HU-043) | n/a | Não (usuário decide re-consultar) | Botão re-consultar |
| **Asíncrona de negócio** (pedido→SAP, cliente→SAP) | 3 tentativas | Backoff exponencial: 2 → 4 → 8 min | 1 imediato SÓ para timeout de rede | Fila de reprocesso + botão (RN-09) |
| **Réplicas massivas** (catálogo, preços) | 3 por lote | 5 → 15 → 45 min | Não | Reprocesso por arquivo/lote |
| **Eventos inbound** (SapOrderResponse__e) | Replay nativo do Platform Event (ReplayId, 72h de retenção) | n/a | n/a | Reconciliação noturna |

Pré-condição que torna QUALQUER reintento seguro: **idempotência por chave externa** (SapMaterialCode__c no catálogo, deudor por sociedad no cliente, número de pedido SAP na Order) — reintento duplicado converge no mesmo registro, nunca duplica. Já é o nosso padrão.

## 5. Lista de campos relevantes (RN-02)

**(a) No Salesforce, como Custom Metadata Type** (`IntegrationFieldConfig__mdt`: objeto, campo, interface, ativo, linha de negócio). Motivo: quem DETECTA a mudança e decide disparar é o Salesforce (record-triggered flow/trigger compara campos da lista) — a lista tem que estar onde a decisão roda. O Mule consome o contrato (payload), não a lista. CMDT é versionável, deployável entre ambientes e editável por admin sem código.
**(b)** Artefato técnico separado (o CMDT é o master) + **anexo na HU com o snapshot da primeira versão** — a HU referencia, não governa.
**(c)** Primeira versão: **OSF monta** (a partir dos mapeamentos que já existem nos DTOs do SapMuleClient e do contrato Mule) e **GrupoQ valida por linha de negócio** — validação com dono e data, não workshop aberto.

## 6. Bloqueio de estoque e reconstrução (RN-13/RN-14)

**(a)** Sim — no desenho vigente a reserva É o pedido (Z301 bloqueia estoque no SAP, que é o maestro do inventário); o Salesforce reflete o estado na unidade (Vehicle/Asset status). As HUs de disponibilidade transportam esse estado; **a HU-119 só transporta** — confirmar e fechar.
**(b) Reconstrução = capacidade da HU de cotização/pedido, não da 119.** Nosso desenho já se aproxima: mudança de modelo/condição gera NOVA cotização na MESMA oportunidade (nunca recomeça do zero — cliente, unidade e condições vêm da anterior). O componente de integração é só reenviar o documento resultante (já coberto). Se o negócio quiser "regenerar pedido mantendo agenda", isso é evolução da HU de pedido — entrar em escopo/estimativa lá.

## 7. Rastreabilidade e monitoramento (RN-15/RN-16)

**(a) Traça nos dois, com papéis DIFERENTES — não é duplicação:** MuleSoft = observabilidade técnica (payloads, latência, retry, alertas — Anypoint Monitoring, para operação/TI); Salesforce = trazabilidade FUNCIONAL por registro (estado de sync no registro + log leve de integração, para o usuário de negócio saber "por que meu pedido não foi"). Audiências distintas, custo baixo, os dois já estão no desenho. Posição: manter ambos.
**(b) Monitoramento centralizado no Mule cobrindo interfaces SAP: é GAP de escopo** — o Technical Annex V5 só documenta essa camada para os serviços compartilhados de fábricas. Sinalizar impacto de escopo/estimativa MuleSoft formalmente (a Melisa está certa em não absorver em silêncio).
**(c) Retenção (proposta):** SF: status no registro = permanente; log de integração leve = 90 dias (Big Object se o negócio exigir mais). Mule/Anypoint: o do plano contratado (default 30 dias) — se precisarem de mais, é item do gap (b).
**(d) Formato:** **ADR — Architecture Decision Records** — um documento por decisão, numerado, no repositório do projeto, com seção "Definiciones de Arquitectura" na HU linkando os ADRs pertinentes. Resolve o pedido da Vane de "lugar formal": decisão citável, com data, contexto e alternativas descartadas (o OMS do bloco 1b vira o ADR-001).

## 8. Itens menores

- **Escalonamento de descontos Peças/PA:** posição — calcular NO Salesforce, pelo mesmo motivo da HU-038 (fatores/níveis em Decision Matrix, editável sem deploy, e a aprovação acontece no CRM onde está o fluxo comercial). O SAP segue aplicando o preço final no faturamento. Levar a Isabela/Andrea como recomendação, não imposição.
- **Catálogo de funções SAP:** cobrar como entregável formal com dono e data — "catálogo RFC/BAPI por domínio (Veículos, Peças, PA, Clientes, Devoluções)" na Technical Weekly; sem ele, RN-19 e o bloco 1c ficam abertos. As cinco funções já incorporadas seguem valendo.
- **Get_Price_ZGQREF:** correto remover — o nome real sai do contrato Mule (Flavio); manter remissão à HU-028 com "servicio a confirmar en el contrato MuleSoft".

---

**Resumo do destrave:** bloco 1 → decisão (a) confirmada + modelagem reduction orders + história própria (a 119 só transporta); bloco 3 → push via Platform Event/update inbound, canal já deployado; bloco 4 → tabela de defaults acima como proposta OSF. Com esses três, a HU fecha para desenvolvimento.
