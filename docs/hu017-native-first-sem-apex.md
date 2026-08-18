# HU-017 sem Apex e sem LWC

Como cobrir a HU-017, Gobernanza del Cliente Maestro, sem escrever uma linha de
Apex e sem um componente LWC. Pesquisa de 18/08 na documentação oficial, nas
últimas releases e em fóruns.

Três itens da planilha eram código: o compartilhamento por sociedade, a tela de
extensão do cliente e as classes de teste. Os três saem.

---

## 1. Visibilidade por sociedade, sem Apex

Era a maior peça de código da história, a T27, compartilhamento gerido por Apex
sobre `AccountShare`. O problema que a criou é real e continua de pé:

- a **RN-05** proíbe campo de sociedade na conta, porque a extensão vive em
  `AccountAccountRelation`;
- a **RN-25** exige que o usuário veja só os clientes da sua sociedade;
- **Sharing Rule por critério só lê campo da própria conta**;
- **Restriction Rules não cobrem `Account`**, só objetos custom, external,
  contratos, eventos, tarefas e time sheets.

### O contorno é oficial

A documentação de criteria-based sharing rules diz textualmente, para campos que
o critério não aceita:

> You can use a field that's not supported by criteria-based sharing rules.
> Create a workflow rule or Apex trigger to copy the value of the field into a
> text or numeric field. Then use that field as the criterion.

Ou seja, o padrão que a plataforma indica é exatamente **automação mantém um
campo, sharing rule lê o campo**. Hoje a automação é Flow, não workflow rule.

### O desenho

1. **Flow acionado por registro em `AccountAccountRelation`**, nos gatilhos de
   criação, atualização e exclusão, que estampa na `Account` a marca das
   sociedades onde aquele cliente está habilitado.
2. **Uma criteria-based sharing rule por sociedade**, concedendo acesso ao
   public group daquela sociedade.
3. **OWD de `Account` privada**, senão nada disso restringe nada.

### Duas variantes, e a diferença é uma verificação

| Variante | Campos | Regras | Risco |
|---|---|---|---|
| A, um campo texto com a lista das sociedades | 1 | 14, operador **contains** | Depende de o operador `contains` existir no critério de sharing rule |
| B, um checkbox por sociedade | 14 | 14, operador **equals true** | Nenhum. `equals true` é inquestionável |

O limite é **300 sharing rules por objeto, das quais até 50 por critério**.
Quatorze sociedades cabem nas duas variantes com folga.

Comece pela **B**, que é feia e funciona. Se a verificação mostrar que
`contains` está disponível, migre para a **A**, que é uma linha de manutenção em
vez de quatorze.

### Por que não Flow criando `AccountShare` direto

Flow **consegue** criar registro de compartilhamento, é declarativo e a
comunidade usa. Mas de fora do Apex só se escreve share com
`RowCause = Manual`, e **share manual é apagado quando o dono do registro
muda**. Um motivo de compartilhamento próprio, que sobrevive à troca de dono,
exige Apex Sharing Reason, que é exatamente o Apex que estamos removendo.

Na HU-017 a **RN-06** diz que a conta não tem vendedor proprietário e fica com o
usuário de dados maestros, então troca de dono deveria ser rara. Rara não é
nunca, e perda silenciosa de visibilidade é o tipo de defeito que só aparece em
UAT. Por isso sharing rule ganha de share por Flow: a plataforma recalcula e
mantém, e não há registro nosso para se perder.

### O que declarar como consequência

- **Sharing rule concede acesso, nunca restringe.** A RN-25 só se sustenta com
  OWD privada e sem nada mais amplo por cima, como View All.
- **Recalcular compartilhamento tem custo.** Atualizar o campo em volume grande
  dispara recálculo assíncrono. Vale medir antes da carga inicial de clientes.
- **A leitura da RN-05.** Ela proíbe "un campo único de sociedad en la cuenta,
  que entraría en conflicto con la unicidad del maestro". Um campo que lista
  **todas** as sociedades onde o cliente está estendido não conflita com
  unicidade nenhuma: é derivado da `AccountAccountRelation` e não é a chave
  maestra. Mesmo assim toca uma frase explícita de arquitetura da HU, então
  confirmar com a Melisa antes de empacotar.

---

## 2. Tela de extensão do cliente, sem LWC

A T09 estava como Flow ou LWC. É Screen Flow, e as últimas releases tiraram o
último motivo de escrever componente para formulário.

- **Reactive Screen Components**, GA no Winter '24. O campo reage ao que o
  usuário digita na mesma tela, sem passar para a próxima. Era o motivo número
  um de se escrever LWC para captura.
- **Repeater**, Spring '24, com pré-carga de dados no Winter '25 e opção de
  permitir ou não que o usuário acrescente e remova itens. Serve para estender o
  cliente a mais de uma sociedade na mesma passagem.
- **Dynamic Forms**, que desde o Winter '23 suporta Person Account, com
  comportamento **Required** condicional. É a RN-11, obrigatoriedade por país,
  sociedade, área e tipo, sem desenvolvimento.

Uma limitação para o desenho, e não é pequena: **componente reativo não funciona
dentro do Repeater**. Se a tela precisar de reatividade, ela não usa Repeater, e
a extensão passa a ser uma sociedade por vez.

E uma armadilha das Dynamic Forms: regra de visibilidade em **seção** só é
avaliada depois de salvar, regra em **campo** reage enquanto o usuário digita.
Condicionar campo a campo, nunca seção.

---

## 3. Testes, sem classe de teste

Sem Apex não há classe de teste. O que substitui é **Flow Test** para os flows
acionados por registro, que é declarativo, versiona com o flow e roda no deploy.

Cobrir, como mínimo:

- criar relação em sociedade nova e conferir que a marca aparece na conta;
- apagar a relação e conferir que a marca sai;
- duas sociedades no mesmo cliente ao mesmo tempo;
- gravação de documento fora do formato do país, que tem que falhar;
- cliente estrangeiro com documento de origem e passaporte complementar.

Os três escenarios que a RN-05 e a RN-25 tornam fáceis de errar são o 1, o 2 e o
7, e são os que precisam de teste com usuário de sociedade diferente, não com
administrador.

---

## 4. O resto já era declarativo

| Requisito | Como fica |
|---|---|
| RN-02, chave única | Campo único e External ID, preenchido por Flow before save |
| RN-15, normalização | Flow before save, sem Apex |
| RN-12, RN-14, regras por país | Custom Metadata Type mais validação |
| RN-32, atributos fiscais derivados | Flow, ou passo em Expression Set se for junto do preço |
| RN-26, RN-27, erro de replicação | Campo de estado mais Nebula Logger, que tem ação invocável de Flow. Já instalado, e não se escreve Apex para logar |
| RN-23, aprovação de dado sensível | Os dois processos que já estão ativos em `Account` |

Se algum dia precisar de chamada REST sem Mule, existe **HTTP Callout em Flow**,
declarativo, então nem integração obriga Apex. Aqui não se aplica porque o SAP
vai por MuleSoft.

---

## 5. O que muda na planilha

Saem três tarefas de código e entram cinco declarativas:

- `T27` Apex managed sharing sobre `AccountShare` **sai**;
- entram: Flow que estampa a marca de sociedade, os public groups por sociedade,
  as criteria-based sharing rules, a OWD privada e a verificação do operador;
- `T09` deixa de ser Flow ou LWC e passa a ser **Screen Flow** com componentes
  reativos;
- `T39` deixa de ser classe de teste e passa a ser **Flow Test**.

Resultado: **zero Apex e zero LWC na HU-017.**

---

## 6. O que ainda não é nativo

Duas coisas continuam de fora, e nenhuma se resolve com esforço técnico:

- **cifra at rest**, que exige Shield Platform Encryption, não licenciado. FLS e
  masking cobrem visibilidade e não substituem cifra;
- **retenção e anonimização**, que exigem Privacy Center, add on pago. A versão
  nativa da plataforma faz retenção e mascaramento com cópia para store externo,
  mas é licença.

As duas já estão declaradas nos Pendientes da própria HU. Ficam como premissa e
não como tarefa.

---

## Fontes

- Create Criteria-Based Sharing Rules, Salesforce Security Guide
- Sharing Rules limits, 300 por objeto e 50 por critério
- Programmatic sharing using Flow, e a limitação de `RowCause = Manual`
- Reactive Screen Components GA, Winter '24
- Flow Repeater, Spring '24, e pré-carga no Winter '25
- Dynamic Forms Tips and Considerations, incluindo suporte a Person Account e o
  aviso de que campo escondido não é segurança
- Restriction Rule Considerations, lista de objetos suportados
