# HU-038, validação da arquitetura de listas de preço contra limites e prática de mercado

Data: 14/08/2026. Motivo: o Flavio Medeiros levantou no Teams que a RN2 diz
"Se configuran Pricebooks separados por marca" e perguntou se há conflito com a
regra estrutural de lista por sociedade, e se vai existir price book por marca.
Antes de responder, verifiquei os limites de plataforma e a prática de mercado,
porque a resposta define quantas listas vão existir e isso não pode voltar atrás
depois de construído.

---

## 1. O conflito aparente não existe, e o texto da HU resolve sozinho

RN2 tem dois parágrafos e cada um tem um sujeito diferente.

> "Como regla **estructural**, la marca es un atributo del producto y no
> multiplica listas: los productos se asocian a la lista de su sociedad."

> "La **administración** de precios es centralizada por MARCA: cada marca es
> dueña de sus precios. Se configuran Pricebooks separados por marca con
> accesos restringidos."

O primeiro governa a estrutura que o processo comercial consome. O segundo
governa quem carrega, aprova e enxerga. São duas camadas, não duas versões da
mesma regra, e é exatamente o desenho de duas camadas: listas oficiais por
sociedade para cotizar, listas de administração por marca para carregar e
aprovar. Publicar é copiar da administração para a oficial.

A camada de administração não é preferência de desenho, é obrigação de
plataforma. A RN2 exige que o responsável da marca "solo administra **y
visualiza** los precios de su marca". `Pricebook2` admite compartilhamento por
registro, então é possível restringir acesso **por lista**. Não existe forma de
restringir acesso **por marca dentro de uma lista**. Logo a administração tem
que ser lista separada.

---

## 2. Limites verificados

### 2.1 Quantidade de price books, não há teto em Sales Cloud, há em Commerce

Não existe limite documentado de quantidade de `Pricebook2` numa org de Sales
Cloud. Os limites publicados são da tabela **Price Book Data Limits do B2B
Commerce**, e passam a valer no momento em que Commerce entrar no desenho, que é
exatamente o que o Flavio levantou ao falar de B2C:

| Limite | Valor | Tipo |
|---|---|---|
| Price Books por org | 300.000 | Suave, ampliável via Suporte |
| Price Book Entries por org | 50 milhões | Suave |
| Price Book Entries por lista | 350.000 | Suave |
| Price Books por Buyer Group | 50 | Suave |
| **Price Books por chamada de preço** | **25** | **Rígido, não se amplia** |

O 25 é o único **rígido**, e é o que importa. A definição é "o número de listas
**válidas** que o sistema avalia numa chamada de preço", e válida é lista ativa
cuja moeda casa com a do comprador. Listas acima de 25 **não entram na avaliação
e são ignoradas em silêncio**, que é o pior tipo de falha.

Para o nosso desenho: as listas oficiais em USD são as de El Salvador, Costa
Rica por causa da RN6, e Panamá. Sete ou oito, com folga confortável. Mas se
alguém multiplicar as listas de administração por marca e sociedade e deixá-las
ativas na mesma moeda, entrar em Commerce passa a ser um risco concreto.

**Em Sales Cloud puro a quantidade não é o risco.** O risco é o que se tem que
manter em volta de cada lista, item 3.2, e é o que muda se Commerce entrar.

### 2.2 Entrada em lista custom exige entrada ativa na lista padrão

Documentado: "Custom price book entries can be created only for products with
active standard price book entries."

Isso é contrato de integração, não detalhe. A carga do Mule tem que criar
primeiro a entrada na **Standard Price Book** e só depois a entrada na lista da
sociedade ou de administração. Produto novo sem entrada padrão ativa faz a
segunda gravação falhar com `STANDARD_PRICE_NOT_DEFINED`.

### 2.3 Uma entrada por produto, lista e moeda

Continua valendo, e é o motivo de Costa Rica precisar das entradas criadas em
USD e não convertidas a partir de CRC.

### 2.4 Compartilhamento

Acesso a price book se concede por compartilhamento manual no próprio registro,
para usuário, grupo público, papel, ou papel e subordinados. O teto de regras de
compartilhamento por objeto é 300, das quais no máximo 50 podem ser por
critério, e a recomendação de performance é ficar abaixo de 100 por proprietário
e 50 por critério. Compartilhamento manual não consome esse teto, mas ver 3.2.

### 2.5 Armazenamento

Registro consome cerca de 2 KB. Vale registrar uma precisão que muda a
conversa: **multiplicar as listas de administração por sociedade não multiplica
o número de linhas.** Uma staging de marca e sociedade guarda só os produtos
daquela marca naquela sociedade, então o total de entradas é praticamente o
mesmo com 8 listas ou com 96. O custo do produto cartesiano é administrativo,
não volumétrico. Quem argumentar contra o cartesiano com armazenamento vai
perder o argumento.

---

## 3. Os dois riscos reais

### 3.1 Uma oportunidade usa UMA lista, e trocar a lista apaga as linhas

Confirmado ao pé da letra em Considerations for Creating and Maintaining Price
Books:

> "You can add products, quote line items, or order products from a **single
> price book only**."

> "If you change the price book for an opportunity that has products, **all
> products are deleted** from the Products related list, but the value in the
> opportunity's Amount field remains."

O segundo é pior do que parece: as linhas somem e o **Amount fica**, então o
registro passa a mostrar um valor que nenhuma linha sustenta. Não é erro
visível, é dado inconsistente e silencioso.

Consequências que precisam ser confirmadas antes de construir:

1. Tudo que o vendedor precisa cotizar **na mesma oportunidade** tem que estar
   na **mesma lista**. Veículo, acessórios e repuestos numa venda só significa
   uma lista, não três;
2. Se acessórios ficarem em lista separada, ou entram na lista da sociedade, ou
   viram oportunidade separada. Não existe meio termo nativo;
3. Confirma que publicar copiando da administração para a oficial é o desenho
   certo, porque o vendedor nunca seleciona a lista de administração;
4. Se alguma automação trocar a lista de uma oportunidade em andamento, o
   vendedor perde o que montou. Qualquer flow que escreva `Pricebook2Id` em
   oportunidade com linhas é um defeito esperando acontecer.

**Este é o ponto número um a validar com o negócio**, e vale mais do que a
discussão de quantas listas existem.

### 3.2 O compartilhamento de price book é dado, não metadado

O compartilhamento manual de um price book **não viaja em deploy**. É registro,
não configuração. Cada lista de administração precisa ter o acesso reconfigurado
à mão em DEV, INT, QA e Produção. A documentação ainda indica que essa tela é do
Salesforce Classic.

Isso dá o custo real do produto cartesiano, e é um argumento muito melhor do que
"são muitas listas":

| Cenário | Listas de administração | Configurações de acesso em 4 ambientes |
|---|---|---|
| Uma por marca, 8 marcas | 8 | 32 |
| Por marca e sociedade | até 96 | até 384 |

---

## 3bis. A estrutura não é uma hierarquia de quatro níveis

O Flavio propôs no Teams uma leitura em quatro níveis: standard, sociedade,
categoria Autos e Motos, marca. É intuitivo e está errado num ponto que muda
tudo: **price book não tem hierarquia e não tem herança.** Cada lista é uma
lista plana, e a oportunidade escolhe **uma**. Não existe lista que herde de
outra, nem lista pai.

Então não são quatro níveis, são **duas camadas e dois eixos**:

| O que | Quantas | Quem seleciona |
|---|---|---|
| Standard Price Book | 1 | Ninguém, é pré-requisito técnico |
| Listas oficiais por sociedade | 12, mais acessórios | O vendedor, uma por oportunidade |
| Listas de administração por marca | uma por marca | Ninguém no comercial, só carga e aprovação |

Categoria, Autos e Motos, e marca **não são níveis de lista.** São atributos do
produto, e é literalmente o que a RN2 diz na frase estrutural: "la marca es un
atributo del producto y no multiplica listas". Segmentar por categoria criaria
listas separadas de Autos e Motos, e como a oportunidade escolhe uma só, uma
venda de auto com moto junto ficaria impossível.

---

## 4. Prática de mercado

O critério corrente para separar listas é este, e coincide com o que a HU-038
descreve: quando o preço de um produto muda entre países mas a moeda é a mesma,
a separação se faz por lista, não por conversão de moeda. Multimoeda com taxa de
conversão só serve quando o preço é o mesmo e muda apenas a expressão.

É exatamente o caso do GrupoQ. Costa Rica tem C101 e C105, El Salvador tem
S101, S105 e S206. Mesma moeda, sociedades diferentes, preços que podem diferir.
Uma lista por país não representa isso. A lista por sociedade não é excesso, é o
mínimo que representa o negócio.

---

## 5. Conclusão

O desenho está correto e dentro de limites, com duas condições:

1. Confirmar que veículo, acessórios e repuestos que se cotizam juntos estão na
   mesma lista, por causa de 3.1;
2. Manter as listas de administração em **uma por marca**, subindo para marca e
   sociedade **apenas nas combinações que a lista de preços mensal do GrupoQ
   provar que existem**, por causa de 3.2.

A pergunta que fecha o item 2 continua sendo factual e não se resolve em
reunião: na lista mensal de hoje, o mesmo modelo aparece com preço diferente em
duas sociedades do mesmo país e mesma moeda?

---

## Fontes

- Considerations for Creating and Maintaining Price Books, Salesforce Help
- Guidelines for Sharing Price Books, Salesforce Help
- Price Book Data Limits, B2B Commerce Developer Guide, para deixar claro o que
  NÃO se aplica
- Best Practices for Deployments with Large Data Volumes, Salesforce Developers
- Salesforce record size overview, Salesforce Help
- Salesforce Price Books, Best Practices for Effective Sales, ScienceSoft
- Using Multiple Price Books in a single Opportunity, IdeaExchange, para o
  comportamento nativo de uma lista por oportunidade
