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
