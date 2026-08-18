# Cotizador, revisão do protótipo do Gastón e arquitetura da tela

Revisão de 18/08 sobre os oito quadros enviados, mais a decisão de arquitetura da
tela, o momento de habilitar o cotizador na Oportunidade, e o ciclo da cotização
até o pedido.

---

## 1. O que o protótipo já acerta

O fluxo em cinco passos, Acessórios, Preço, Avalúo, Forma de pago e Resumo, está
coerente com o que já existe construído e com as HUs:

- a **composição do preço de referência** mapeia direto para a HU-038, com
  `PrecioMinimoAsesor__c`, `Gastos__c` e o cashback que já estão na
  `PricebookEntry`;
- o **avalúo** aponta para o objeto `Appraisal` padrão, que o Santi já construiu;
- os **estados de estoque** Disponible, En tránsito e Sin stock são a HU-043;
- o **Solicitar descuento** é a HU-064 mais a HU-065;
- o **financiamento** em três vias, contado, CrediQ e terceiros, casa com a
  `FinancingService` que já existe no pacote do Cotizador;
- o **Precio de lista (sociedad C101)** já nasce ciente de sociedade, o que é
  exatamente o que o multi país exige.

---

## 2. Onze pontos de revisão, em ordem de custo

### 2.1 Ticket quebrado por veículo, e é a maior decisão do desenho

O quadro final mostra um ticket por veículo, e existe um botão **Unificar todos
los tickets**. Isso decide o modelo de dados e não é reversível de graça.

A recomendação, com o motivo técnico:

- **Autos, Motos e Usados: uma `Quote` por veículo.** Porque aprovação em
  Salesforce é **por registro**, não por linha. Se quatro veículos vivem numa só
  cotização e um deles precisa de autorização de desconto, o processo de
  aprovação trava o documento inteiro. E a HU-064 diz que em Autos o desconto é
  por negócio, não por linha;
- **Repuestos e PA: uma `Quote` com muitas linhas**, porque ali o desconto é por
  SKU e a HU-064 Escenario 16 pede avaliação linha a linha;
- **Unificar tickets é agrupamento de impressão**, não fusão de dados.

E um detalhe que morde: **só uma `Quote` pode estar sincronizada com a
Oportunidade por vez**. Com quatro tickets, o `Opportunity.Amount` só reflete um.
Ou não se usa a sincronização nativa e o valor da Oportunidade sai de roll up, ou
se aceita que o Amount é o do ticket principal. Precisa estar decidido antes de
construir.

### 2.2 A ordem da composição do preço está errada do ponto de vista fiscal

O quadro mostra, nesta ordem: Precio de lista, Gastos, **Impuesto 13%**,
Cashback negativo, Valor de trade in negativo, Total de accesorios.

Três problemas:

- a HU-105 diz que o desconto se aplica **antes do IVA**, e a HU-064 RN11 diz que
  o **cashback soma ao desconto** e entra na escala de autorização. Então
  cashback e desconto vêm **antes** da linha de imposto, não depois;
- **trade in não reduz a base tributável.** É forma de pagamento, e o avalúo
  aceitado abate o valor a pagar, não o preço do veículo. Colocá lo antes do
  imposto muda o imposto e é erro fiscal;
- os acessórios aparecem no fim, mas a HU-105 RN12 diz que **acessório mantém a
  tasa geral quando a unidade é exonerada**. Então acessório tem linha de imposto
  própria e não pode ser um total solto no rodapé.

Ordem correta sugerida: Precio de lista, Gastos, Acessórios, Descontos e
cashback, base tributável, Impuesto por linha, Total, e só então Trade in e forma
de pagamento.

### 2.3 O 13% está cravado na tela

`Impuesto de referencia 13%` é Costa Rica. A tasa vem da matriz por sociedade da
HU-105, e nas outras sociedades é 12, 15 ou 7. O rótulo tem que ser dinâmico, e
tem que continuar dizendo **de referencia**, porque o imposto definitivo é
calculado no SAP.

### 2.4 A tela mistura duas moedas

Os totais estão em `$ USD` e os campos de entrada em `Prima (CRC)` e `Descuento
solicitado (CRC)`. Costa Rica opera com CRC e USD, as duas ativas na org, mas o
documento tem **um** `CurrencyIsoCode`. Definir qual é a moeda do documento e se
a outra é apenas exibição.

### 2.5 O Path da Oportunidade não fecha

O caminho no quadro é Nuevo, Calificado, Transferir, Completo, **Incompleto**.
Incompleto depois de Completo não é avanço, e não há Cerrado Ganado nem Cerrado
Perdido. A HU-024 já definiu nove motivos de perda e seis Record Types. O Path
do protótipo precisa ser reconciliado com isso.

### 2.6 Não existe nenhum estado de erro no protótipo

Este é o ponto mais importante para um protótipo de UX, e é o que o Diego pediu:
se a consulta falhar, mostrar na tela. Hoje não há desenho para:

1. **SAP não responde**, Escenario 22 da HU-064 e Escenario 3 da HU-119;
2. **preço não construível** para o material ou o veículo, Escenario 23;
3. **cliente sem grupo ou canal**, Escenario 21, onde o desconto automático não
   resolve e o sistema informa sem assumir padrão;
4. **desconto excede o range do rol**, com o aviso que **não bloqueia** o
   trabalho mas bloqueia o envio e a impressão, Flujo 7 da HU-064;
5. **disponibilidade perdida entre cotização e pedido**, Escenario 13.

São cinco estados de tela que precisam existir antes de o protótipo ser aprovado,
senão o desenvolvimento inventa cada um por conta.

### 2.7 Falta o estado requiere autorización

O passo de preço tem o toggle **Solicitar descuento**, mas não tem o retorno.
Falta mostrar o escalão que corresponde ao valor pedido, e mostrar que o
documento ficou pendente. E em Autos e Motos a HU-064 RN4 é explícita: **não se
expõe o montante limite ao vendedor**, só o aviso de excesso.

### 2.8 Sin stock aparece selecionável

Um dos veículos em Seleccionados está como **Sin stock**. Cotizar sem estoque
pode ser legítimo, reservar não é. A regra tem que estar na tela: cotizável sim,
reservável não, e com o aviso.

### 2.9 Servicontratos já mostram desconto

A lista de servicontratos traz `Dto:` em cada linha. Isso significa que o motor
de desconto se aplica a serviço também, e a HU-064 não cobre serviço. É escopo a
declarar.

### 2.10 Lista negra na ficha da Oportunidade

O campo `Lista negra: No registra` aparece no detalhe. AML, listas negras e PEP
estão **fora do escopo** da HU-017 e vivem nas HU-033, HU-058, HU-066 e HU-127,
de Finance. Se está na tela, alguém tem que ser dono da fonte do dado.

### 2.11 Os números do protótipo não somam

`Total de referencia` está igual ao `Total de accesorios`, e `Importe` aparece
como 150.000 no cabeçalho e como Sin importe no detalhe. É mock, mas vale
corrigir para o QA não herdar o número errado como esperado.

---

## 3. A arquitetura da tela, e por que aqui LWC se justifica

Em HU-017 tiramos LWC e Apex por princípio de native first. Aqui **não**, e o
motivo é objetivo: assistente de cinco passos, com quatro veículos em paralelo,
consulta de preço em linha ao SAP, seleção de acessórios com recálculo,
simulação de financiamento e quebra de ticket. Screen Flow não sustenta isso com
conforto, principalmente porque **Choice Option não é reativa** e o catálogo
compatível depende do veículo escolhido na mesma tela.

Native first não é nunca usar código. É usar código onde o declarativo não
alcança, e aqui não alcança.

### 3.1 O BFF é uma Continuation, não uma cadeia de chamadas

O que o Diego descreveu, carregar a tela já fazendo as consultas, tem nome e tem
mecanismo nativo: **Apex Continuation**.

- **timeout de 120 segundos**, contra 10 segundos de um callout síncrono
  invocado por componente;
- **até três callouts em paralelo** numa mesma Continuation;
- funciona em LWC desde Summer '19;
- o método que devolve a Continuation se anota
  `@AuraEnabled(continuation=true cacheable=true)`, com **espaço e não vírgula**
  entre os dois.

Então o passo de Preço abre disparando, em paralelo: disponibilidade, preço
construído e condições fiscais. Um método, um retorno, um wrapper. Não três
chamadas em sequência, que é o que gera a tela lenta.

### 3.2 Um wrapper por passo, não um por objeto

O contrato do BFF devolve um único DTO com o que o passo precisa, mais uma
**lista de erros por domínio**. Assim a tela desenha o que veio e mostra o aviso
do que faltou, em vez de morrer inteira porque um serviço caiu. É isso que
resolve o ponto 2.6.

Estrutura do retorno, por passo:

```
{ dados: {...}, avisos: [ {dominio, codigo, mensagem, bloqueante} ] }
```

`bloqueante` é o que decide se o botão Confirmar y avanzar fica habilitado. A
HU-119 RN-10 diz que falha de integração não impede continuar operando, **salvo**
disponibilidade antes de reservar, preço antes de cotizar e validação de
obrigatórios antes de enviar o pedido. Esses três são bloqueantes, o resto é
aviso.

### 3.3 O que NÃO passa por Apex

- **Ler o registro em contexto** usa Lightning Data Service, `getRecord` e
  `getRecords`, que trazem cache compartilhado entre componentes e invalidação
  automática. A recomendação oficial é preferir LDS a Apex para registro único;
- **listar catálogo com paginação** pode usar o wire adapter de **GraphQL**, que
  faz uma requisição em vez de várias;
- **Apex fica para o que LDS não faz**: múltiplos registros numa transação,
  callout ao Mule, e a lógica de composição de preço.

### 3.4 Segurança do Apex, do jeito atual

- **SOQL com `WITH USER_MODE`** e DML com `AccessLevel.USER_MODE`. É a forma
  recomendada hoje e cobre CRUD, FLS e compartilhamento, resolvendo o que o
  antigo `WITH SECURITY_ENFORCED` deixava passar;
- **`Security.stripInaccessible`** onde não se quer exceção e sim remoção
  silenciosa do campo inacessível, tipicamente antes de devolver o DTO;
- **`with sharing`** na classe, e `without sharing` só num inner class explícito
  e comentado, como já fizemos no controller da agenda;
- **custo e margem nunca entram no DTO** do assessor. A HU-064 RN10 exige FLS, e
  campo escondido na tela não é segurança.

### 3.5 Desempenho, o que evita a tela lenta

- uma chamada por passo, nunca uma por card;
- `cacheable=true` em tudo que só lê, inclusive na Continuation;
- catálogo e acessórios com paginação, nunca lista inteira;
- nada de SOQL dentro de loop no lado Apex, e nenhum `getRecord` por linha no
  lado LWC;
- **Debug Mode desligado** antes de qualquer demo. Já medimos 6,84 s de EPT com
  ele ligado.

---

## 4. Cobertura das quatro linhas de negócio

O assistente é o mesmo casco, com conjunto de passos diferente. O protótipo hoje
só desenha Autos.

| Linha | Passos | Diferença que muda a tela |
|---|---|---|
| **Autos** | Acessórios, Preço, Avalúo, Forma de pago, Resumo | Como está no protótipo. Desconto por negócio, cashback, trade in |
| **Motos** | Os mesmos cinco | Mesma estrutura, escala de desconto própria. O fluxo corre automático da reserva à faturação, então o estado de integração é mais crítico |
| **Repuestos e PA** | Busca de material, Linhas, Preço, Forma de pago, Resumo | **Não tem Acessórios nem Avalúo.** Preço vem construído do SAP, desconto por SKU, avaliação linha a linha. Precisa de busca de material com estoque por centro |
| **Flotas** | Acessórios, Preço por volume, Forma de pago, Resumo | Múltiplas unidades do mesmo modelo, desconto por volume, e é Release 2 |

O `ventaGuiadaModal` já roteia por Record Type e já tem
`contraventaRepuestos` e `ventaPA` como componentes. O protótipo precisa de um
quadro por linha, senão Repuestos entra sem desenho.

---

## 5. Quando habilitar o cotizador na Oportunidade

Cinco pré requisitos, e nenhum é opinião:

1. **Cliente identificado** com a chave maestra da HU-017;
2. **Sociedade definida** no documento, porque preço, imposto e desconto são por
   sociedade;
3. **Cliente estendido àquela sociedade**, HU-017 RN-05, senão o desconto
   automático não resolve, Escenario 21;
4. **Price Book vigente e aprovado** atribuído, HU-038;
5. **Moeda do documento definida**.

Recomendação de momento: a partir de **Calificado**. Em Nuevo o cliente ainda
pode não ter sociedade.

E uma escolha de UX que vale defender com o Gastón: **não esconder o botão,
mostrar desabilitado com o motivo**. Botão que desaparece gera ticket de suporte,
botão desabilitado que diz "falta extender el cliente a la sociedad C101" ensina
o usuário. Tecnicamente é visibilidade de Quick Action por Record Type mais um
aviso na tela com a lista do que falta.

---

## 6. O ciclo da cotização, stages, Record Types e aceitação

### 6.1 Record Types de Quote

Espelhar os da Oportunidade, porque conjunto de campos, passos do assistente e
regras fiscais mudam por linha: **Autos, Motos, Usados, RepuestosPA**, e Flotas
no Release 2. Sem Record Type na Quote, o assistente não sabe qual conjunto de
passos abrir.

### 6.2 O ciclo de estado

A picklist `Quote.Status` da org hoje tem: `Draft` como padrão, `Pendiente`,
`Pedido futuro`, `En tránsito`, `Approved`, `Rejected`, `Accepted`, `Denied`. Ela
**não é restrita**, então dá para acrescentar valor.

Dois eixos que hoje estão misturados nessa picklist:

- **aprovação interna**: `Approved` e `Rejected`;
- **decisão do cliente**: `Accepted` e `Denied`.

E `Pedido futuro` e `En tránsito` são conceito de **pedido** dentro do status da
**cotização**, o que é dívida a levantar antes de acrescentar mais um valor.

Ciclo sugerido:

```
Draft
  -> Requiere autorización   (desconto acima do piso do rol, HU-064)
  -> Approved                (aprovado internamente, HU-065)
  -> Presentada              (enviada e impressa ao cliente)
  -> Accepted                (cliente aceitou)  -> gera Reserva e Pedido
  -> Denied | Expirada       (terminais)
```

`Rejected` sai do caminho principal e volta para `Draft` com o motivo, porque
rejeição de aprovação não é fim de cotização.

### 6.3 A cotização precisa ser aceita antes do pedido

**Autos, Motos e Usados: sim.** O pedido consome inventário e compromete unidade
física. É o que o `Quote_Aceptada_Genera_Pedido` já implementa, e está certo.

**Repuestos e PA: não obrigatoriamente.** A HU-064 Escenario 17 é explícita, o
pedido se cria **com ou sem cotização prévia**, e nas duas etapas se permite
aplicar desconto e gerar solicitação de aprovação.

Então o gatilho é por Record Type, não global. O flow atual dispara em aceitação
e serve para Autos e Motos. Para Repuestos precisa de um segundo caminho que
crie pedido direto.

E o que **bloqueia** até a aprovação, pela HU-064 Flujo 7, é o **envio e a
impressão** ao cliente, não o trabalho na cotização. O botão `Imprimir` que
aparece no Resumo tem que respeitar isso.

---

## 7. O que ainda não sei e não vou supor

- se a `Quote` tem Record Type hoje e quais, e se `Quote.Status` já foi mexido
  além dos três valores em espanhol;
- se o `Appraisal` do Santi expõe o valor aceito de forma consultável pelo
  assistente, ou se é preciso um campo;
- se o Mule publica OpenAPI, porque isso decide se o callout pode sair sem Apex
  nos serviços novos;
- qual é a moeda do documento em Costa Rica.
