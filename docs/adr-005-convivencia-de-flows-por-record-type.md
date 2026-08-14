# ADR-005 — Convivência de flows no mesmo objeto, por Record Type

**Data:** 14/08/2026 · **Contexto:** o Lead tem **13 flows record-triggered** de equipes diferentes, Sales e Financial entre elas. O objetivo é isolar os fluxos sem obrigar ninguém a reescrever o que já funciona.
**Status:** proposta de regra, aditiva e reversível.

---

## O problema real, em duas frases

Hoje os 13 flows do Lead **rodam todos em todo save**, independentemente de o registro pertencer ou não ao processo daquele flow. E a **ordem entre eles não é garantida**, porque a Trigger Order não está definida, então funciona hoje e pode mudar depois de um deploy sem ninguém ter tocado na lógica.

Não é um problema de qualidade dos flows. É um problema de escopo e de ordem, e os dois se resolvem sem abrir nenhum deles.

---

## Decisão: duas obrigações por flow, nada mais

### 1. Todo flow declara o seu Record Type no critério de entrada

Cada flow record-triggered no Lead passa a ter, no critério de entrada do elemento Start, a condição do seu escopo:

```
$Record > Record Type > Developer Name  igual a  <o Record Type daquele processo>
```

**Por que no Developer Name e não no RecordTypeId:** o Id do Record Type é diferente em cada org, então um critério por Id quebra ao promover de DEV Sales para INT, QA e produção. O Developer Name é o mesmo em todas.

Quando o critério não bate, a plataforma **nem executa o flow**. Isso é isolamento de verdade, não é um `if` no meio da lógica.

**Exceção que precisa existir e ser declarada:** flows que legitimamente valem para **todo** Lead, como deduplicação ou uma normalização geral. Esses não recebem filtro de Record Type, mas ficam marcados como globais na convenção de nome e recebem ordem baixa, para rodarem antes dos específicos.

### 2. Todo flow declara a sua Trigger Order, por faixa reservada

A ordem entre flows do mesmo objeto e do mesmo gatilho só é previsível se cada um tiver a sua Trigger Order. A faixa evita que as equipes precisem se coordenar a cada flow novo:

| Faixa | Dono | Uso |
|---|---|---|
| 1 a 99 | Transversal | Normalização e deduplicação, o que vale para todo Lead e roda antes |
| 100 a 199 | Sales | Fluxo de vendas |
| 200 a 299 | Financial | CrediQ |
| 300 a 399 | Service | |
| 400 a 499 | Marketing e B2C | |

Cada equipe é dona da sua faixa e não precisa pedir licença para usar um número dentro dela.

---

## Por que não consolidar tudo num flow por objeto

É a recomendação genérica de mercado, e aqui ela custa mais do que entrega. Consolidar os 13 num só exigiria abrir a lógica do Financial, do Service e do Sales ao mesmo tempo, com um único dono e um único deploy, criando acoplamento entre equipes que hoje trabalham em paralelo. O ganho seria de desempenho, que não é o problema atual.

As duas obrigações acima entregam o isolamento e a previsibilidade **sem tocar na lógica de ninguém**. Consolidação fica como evolução posterior, se e quando o desempenho virar problema medido.

---

## Ganho secundário que vale olhar depois

Entre os 13, os que apenas **atualizam campos do próprio registro** deveriam ser **before-save** e não after-save. Before-save é mais rápido, não conta como DML separado e **não re-dispara os outros flows**, que é a origem de boa parte da lentidão e da recursão quando há muitos flows no mesmo objeto.

Isso não é pré-requisito da decisão acima, é a próxima melhoria depois que o isolamento estiver de pé.

---

## Consequências

1. **Nenhum flow existente precisa ser reescrito.** Acrescenta-se uma condição de entrada e um número de ordem;
2. As duas mudanças são **reversíveis** e verificáveis pelo Flow Trigger Explorer no Setup;
3. Um flow novo em qualquer objeto compartilhado passa a ter dois requisitos de aceitação: escopo declarado e ordem declarada;
4. A regra vale para qualquer objeto com mais de um dono, não só o Lead. Hoje isso alcança **Lead com 13, Opportunity com 5 e Account com 3**.

---

## Verificação

`docs/scripts/inventario-flows-lead.apex` lista os flows do objeto com tipo de gatilho, para conferir escopo e ordem um a um contra o Flow Trigger Explorer.

---

# Aplicação ao Lead, com os dados reais de 14/08

O inventário mudou o diagnóstico e a regra se aplica menos do que a versão inicial deste ADR supunha. Vale registrar o número correto.

## O problema é menor do que parecia

Os 13 flows não competem entre si. **Um é Scheduled e não roda no save**, então sobram 12. E esses 12 estão em **duas filas independentes**: 7 before-save e 5 after-save. Ordem só importa dentro da mesma fila.

| Fila | Quantos |
|---|---|
| RecordBeforeSave | 7 |
| RecordAfterSave | 5 |
| Scheduled, fora da discussão | 1 |

## O filtro por Record Type resolve pouco, e isso é importante

Os cinco Record Types do Lead são `GQLeadsAutos`, `GQLeadsFlotas`, `GQLeadsMotos`, `GQLeadsRepuestosPA` e `GQLeadsUsados`.

Ao classificar os 12 flows pelo nome, **apenas dois são específicos de um Record Type**:

1. `Lead_BeforeSave_EnforceMotoRequiredFields`, que é de Motos;
2. `GQ_Lead_Repuestos_Reasignacion_y_Cotizacion`, que é de Repuestos.

**Os outros dez são transversais por natureza**: derivar sociedade, aplicar valor padrão, carimbar atribuição, calcular prazo de SLA, validar transição de estado, alertar duplicidade, roteirizar. Nenhum deles deveria ser filtrado por Record Type, e filtrá-los seria errado.

**Correção da regra:** a obrigação não é "filtrar por Record Type", é **declarar o escopo**. Para dez destes doze o escopo declarado é "todos os Record Types", e isso é legítimo e deve ficar explícito. Só os dois específicos ganham filtro.

## Então a alavanca de verdade é a ordem, e existe uma dependência visível

`Lead_BS_DeriveSociedad` deriva a sociedade. Vários dos outros provavelmente leem esse valor, a começar pelo cálculo de prazo de SLA e pela atribuição. **Se ele não rodar primeiro, os que dependem dele trabalham com o campo vazio**, e o sintoma disso não é erro, é dado errado em silêncio.

Ordem proposta, para ser validada com quem é dono de cada flow. **Isto é inferência a partir dos nomes, não é verdade estabelecida**, e cada linha precisa de confirmação:

### Fila before-save

| Ordem | Flow | Escopo | Motivo |
|---|---|---|---|
| 10 | `Lead_BS_DeriveSociedad` | Todos | Tudo que depende de sociedade precisa dela preenchida |
| 20 | `Lead_BeforeSave_DefaultPreferredContactMethod` | Todos | Valor padrão puro, sem dependência |
| 30 | `Lead_BS_EstampaAsignado` | Todos | Atribuição, base para roteamento |
| 40 | `Lead_BS_SetSLADeadline` | Todos | Prazo tende a depender de sociedade e de atribuição |
| 50 | `Lead_SetStatusOnConversion` | Todos | |
| 60 | `Lead_BeforeSave_EnforceStatusTransitions` | Todos | É guarda, roda por último para validar o estado final |
| 110 | `Lead_BeforeSave_EnforceMotoRequiredFields` | `GQLeadsMotos` | Faixa de Sales, único com filtro nesta fila |

### Fila after-save

| Ordem | Flow | Escopo | Motivo |
|---|---|---|---|
| 10 | `Lead_AS_CrossFieldDuplicateAlert` | Todos | Alerta antes de qualquer ação sobre o registro |
| 20 | `Lead_AS_EstampaRTOpp` | Todos | Conversão |
| 30 | `Lead_TriggerOmniRouting` | Todos | Roteia depois de atribuição e carimbos |
| 40 | `Lead_SLA_Escalation` | Todos | Depende do prazo calculado no before-save |
| 110 | `GQ_Lead_Repuestos_Reasignacion_y_Cotizacion` | `GQLeadsRepuestosPA` | Faixa de Sales, único com filtro nesta fila |

## Um ponto a verificar antes de levar isso ao Financial

**Nenhum dos cinco Record Types do Lead é do Financial**, e nenhum dos 12 flows tem nome que sugira CrediQ. É possível que a automação do Financial não viva no Lead, e sim em outro objeto. Vale confirmar onde ela está antes de abrir a conversa, para não discutir convivência num objeto onde eles não estão.
