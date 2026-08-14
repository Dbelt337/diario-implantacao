# HU-038 — Verificação de cobertura, requisito por requisito

**Data:** 14/08/2026 · Leitura integral da HU-038 V3 contra a modelagem da v2 e contra o estado real da org.

---

## 0. Direção do mestre do preço: RESOLVIDA em 14/08

**Confirmado pelo Diego:** apenas o fluxo de **repuestos e PA** tem consulta dinâmica de preço e criação de material contra o SAP. Para **veículos novos, o Salesforce é o mestre**, exatamente como a HU-038 estabelece.

A HU diz isso quatro vezes e agora está confirmado:

1. História de usuário: *"Salesforce es el maestro de estos precios y los precios de vehículos nuevos **no se cargan en SAP**: SAP los recibe con el pedido y vuelve a aplicar el cálculo fiscal al facturar sobre el precio recibido, de modo que ambos resultados deben coincidir."*
2. Evidência do Annex, fila 265: *"Salesforce = Maestro de Precios Comerciales."*
3. Critério de aceitação: *"Salesforce es el maestro de precios comerciales de vehículos nuevos; SAP los consume por integración."*
4. Critério de aceitação: *"Los precios de vehículos nuevos no se cargan en SAP; SAP los recibe con el pedido."*

**A direção do fluxo é Salesforce para SAP, não SAP para Salesforce.**

E a HU explica por que isso não é detalhe: se o SAP recebe o preço com o pedido e reaplica o cálculo fiscal na fatura, **os dois resultados têm que bater**. É daí que vem toda a exigência de arredondamento igual ao do SAP, quatro decimais no pricing e dois nas posições.

### As duas exceções, que são reais e delimitadas

1. **Repuestos e PA**, que a HU exclui explicitamente: *"Repuestos y PA quedan fuera de esta historia (su precio lo calcula SAP)."*
2. **Os gastos**, dentro desta mesma HU. A RN5 diz *"los gastos están parametrizados por sociedad en SAP y el CRM los consume por servicio."* Ou seja, dos onze campos comerciais, **um único** é alimentado por integração com o SAP.

E a carga inicial: a sessão de 22/07 registra que hoje a lista de preços de veículos vive numa **tabela em QRM por sociedade**, que não é o SAP. Isso é migração de partida, não integração permanente, e é exatamente o que a HU chama de eliminar a dependência de planilhas externas.

---

## 0bis. A limitação de plataforma que muda o desenho, e é o achado mais importante

**`PricebookEntry` não admite trigger Apex nem record-triggered flow.** É limitação da plataforma, documentada e com ideia aberta na comunidade há anos. Também não pode ser objeto de Process Builder, e não figura na lista de objetos dos processos de aprovação clássicos.

Isso derruba três pilares do desenho v2 de uma vez:

1. **Escenario 12** exige calcular os três pisos por fator **ao gravar a entrada de preço**. Sem trigger e sem flow, não há como reagir ao save;
2. **RN3** exige que o preço carregado entre em "Pendiente de Aprobación" e dispare aprovação quando algum dos cinco campos baixa. Sem automação no save, nada dispara;
3. **A aprovação precisa de um registro para aprovar**, e a `PricebookEntry` não serve como objeto de aprovação.

### As três saídas, e por que duas não servem

**Saída 1, Apex agendado.** É o contorno documentado: uma classe agendada consulta as entradas modificadas nos últimos minutos e age. Funciona, mas o cálculo dos pisos deixa de ser ao gravar e passa a ter latência, e a aprovação continua sem objeto para viver. **Não resolve a aprovação.**

**Saída 2, todas as escritas passando pelas nossas telas.** Como a HU já diz que *"la administración del precio ocurre en pantallas del sistema"*, dá para tirar a edição direta de `PricebookEntry` dos perfis e fazer tudo por LWC mais serviço Apex, que roda em contexto de sistema. Isso resolve o cálculo dos pisos e o estado. **Mas continua sem objeto de aprovação**, e construir um motor de aprovação à mão é pior do que usar o da plataforma.

**Saída 3, um objeto de solicitação de mudança de preço.** É a única que resolve as três de uma vez. E não é invenção nossa: **a própria HU descreve esse registro**. A RN3 diz *"Toda solicitud de cambio de precio queda registrada dentro del sistema: quién la pidió, quién la aprobó, cuándo y con qué archivo."* Isso é a definição de um registro de solicitação, com solicitante, aprovador, data e arquivo anexo.

### Recomendação: reabrir a restrição de zero objetos custom, com fundamento

A decisão de não criar objeto novo foi tomada em 12/08 e era correta com a informação daquele dia. Com a limitação da `PricebookEntry` na mesa, ela deixa de ser sustentável **para esta HU**.

Um objeto `PriceChangeRequest__c` entrega, tudo nativo:

| O que a HU pede | Como o objeto resolve |
|---|---|
| Preço pendente que não ativa o catálogo (RN3) | O pendente vive na solicitação, não na entrada de preço. **Elimina a necessidade das listas de staging por marca** que a v2 inventou só para contornar a regra de uma entrada por produto, lista e moeda |
| Aprovação individual e em bloque com notificação (RN3, Esc. 4) | Processo de aprovação nativo, que objeto custom suporta |
| Cálculo dos pisos ao gravar (Esc. 12) | Record-triggered flow, que objeto custom suporta |
| Quem pediu, quem aprovou, quando e com que arquivo (RN3) | Campos mais Files mais histórico de campo |
| Acesso por marca (RN2) | Regras de compartilhamento, que objeto custom suporta e `Product2` não |
| Margem visível só ao aprovador (RN10) | Segurança de campo na solicitação, sem expor nada na lista comercial |

A publicação continua sendo o passo controlado: aprovada a solicitação, um flow escreve na `PricebookEntry` oficial. **A `PricebookEntry` volta a ser o que ela é bem, o preço vigente publicado**, e para de ser forçada a acumular estado, aprovação e histórico que ela não sustenta.

**É um objeto, não uma família.** Todo o resto do desenho segue nativo: Decision Matrix para impostos e fatores, Reports para o relatório gerencial, Files para o arquivo, multimoeda nativa para Guatemala e Costa Rica.

---

## 1. Os onze campos comerciais (RN1)

Verificado na org em 14/08.

| # | Campo da HU | Estado |
|---|---|---|
| 1 | Precio de Lista | `UnitPrice` nativo |
| 2 | Precio Mínimo de Asesor | `PrecioMinimoAsesor__c` **já existe** |
| 3 | Monto de Cashback | `MontoCashback__c` **já existe** |
| 3b | Indicador aplica e mostrar no site | `AplicaCashback__c` **já existe** |
| 3c | **Fecha final de vigencia del cashback** | **FALTA** |
| 4 | Precio Exonerado | `PrecioExonerado__c` **já existe** |
| 5 | Precio Exonerado Mínimo | `PrecioExoneradoMinimo__c` **já existe** |
| 6 | Gastos | `Gastos__c` **já existe** |
| 7 | Impuesto de Primera Matrícula (%) | **FALTA** |
| 8 | Precio publicado de Flotas | **FALTA** |
| 9 | Costo estimado del vehículo | **FALTA** |
| 10 | Costo estimado del vehículo exonerado | **FALTA** |
| 11 | Moneda de publicación | **FALTA**, e vai no **Product2**, não no PricebookEntry, porque a HU diz "por modelo" |

Seis dos onze já estão construídos. Faltam cinco campos, mais o de vigência do cashback.

---

## 2. Lacunas do meu desenho v2 que a releitura revelou

### G1. Os três pisos calculados por fator (Escenario 12) — **lacuna real**

A HU diz: *"Cuando guarda la entrada de precio, entonces el sistema calcula el Mínimo de Gerente de Ventas, el Mínimo de Gerente de Marca y el Mínimo de Director aplicando los factores vigentes de la tabla editable, sin intervención manual."*

O meu desenho v2 mandou os fatores para a Decision Matrix e disse que as HU-064 e HU-065 consomem. **Está errado:** a HU-038 exige que o cálculo aconteça **ao gravar a entrada de preço**, aqui. Então faltam **três campos calculados no PricebookEntry**, alimentados pelos fatores.

A RN9 confirma o limite do escopo: esta HU **provê** os pisos, e o escalonamento de aprovação de desconto fica nas outras. Mas o cálculo é aqui.

### G2. Lista de preços de acessórios separada — **não estava na estrutura**

RN1, Escenario 20 e critério de aceitação são explícitos: *"Los accesorios se administran en una lista de precios independiente, separada de la lista de precios de vehículos: el precio del accesorio NO forma parte del precio del vehículo."*

Isso **muda a conta de price books** que discuti hoje com o time de integração. Não é só uma lista por sociedade, é uma lista de veículos **mais** uma de acessórios, por sociedade.

### G3. Registro do respaldo documental da exoneração (Escenario 16)

*"Aplica la tasa reducida... y **deja constancia del respaldo documental exigido**."* Não há lugar para isso no meu desenho. Provavelmente pertence ao cliente ou à cotização e não ao preço, mas precisa ter dono definido.

### G4. Reconstrução do preço histórico (Escenario 10) — **o meu desenho é frágil**

Propus `PricebookEntryHistory`. Duas fragilidades: o histórico de campo é **retido por 18 meses** sem Field Audit Trail, e o limite é de **20 campos rastreados por objeto**, o que com onze campos comerciais mais controles fica apertado.

**Resposta mais robusta:** o preço que valeu numa cotização é o preço **gravado na própria cotização**. A `QuoteLineItem` guarda o valor no momento em que se cotizou. Reconstruir a partir da cotização é exato e não depende de retenção. O histórico de campo continua útil para auditoria de quem mudou o quê, mas não deve ser a fonte da reconstrução.

---

## 3. Contradições dentro da própria HU, que precisam de decisão

### C1. A marca multiplica listas ou não?

RN2 diz as duas coisas em parágrafos consecutivos:

- *"la marca es un atributo del producto y **no multiplica listas**"*
- *"Se configuran **Pricebooks separados por marca** con accesos restringidos"*

E o critério de aceitação pede segmentação por *"País + Moneda + Canal + Marca + Sociedad"*.

O meu desenho reconcilia com listas oficiais por sociedade e listas de staging por marca, mas há um furo: a RN2 exige que o responsável da marca *"solo administra **y visualiza** los precios de su marca"*. Se a lista oficial da sociedade contém todas as marcas, ele **vê** as outras.

`Pricebook2` admite compartilhamento, então acesso por lista é possível, mas não por marca **dentro** de uma lista. Ou a marca multiplica as listas oficiais, ou o responsável da marca não tem acesso de leitura às oficiais. **Decisão de negócio, e ela muda a quantidade de listas.**

### C2. Flotas é canal ou é campo?

O Annex diz canais *"Retail, Flotas, Intercompany"*, o que sugere lista por canal. Mas a RN1 cria o campo **"Precio publicado de Flotas"** dentro da entrada de preço. Se o preço de flotas é um campo, não precisa de lista própria. Se é canal, precisa. **As duas coisas juntas duplicam o dado.**

### C3. Costa Rica em dólares, e o dado da org está em colones

RN6: *"En Costa Rica los precios se administran y se exhiben en dólares (USD); no se exhiben en colones."*

Na org, a lista é `C101 - Vehiculos y Motos (CR)` e a oportunidade da demo mostra **CRC 436.900,00**. O dado atual contradiz a regra. Vale corrigir antes da demonstração, ou confirmar que a regra mudou.

### C4. O relatório mostra ou não o número de inventário

O Escenario 11 diz *"muestra marca, modelo, número de inventario, fecha, aprobador, país y precios (sin número de inventario)"*, contradizendo a si mesmo na mesma frase. O critério de aceitação e a RN8 dizem **sem**. Fica sem, mas vale corrigir o texto.

---

## 4. O que a HU confirma e que fecha discussões abertas

### As doze sociedades estão nomeadas, e isso encerra o debate de listas por país

RN2 lista: **C101 e C105** (Costa Rica), **S101, S206 e S105** (El Salvador), **G101** (Guatemala), **H101 e H105** (Honduras), **N101 e N105** (Nicarágua), **P103 e P105** (Panamá).

Costa Rica tem **duas** sociedades e El Salvador tem **três**. Como a plataforma admite uma única entrada por produto, lista e moeda, **uma lista por país seria incapaz de representar preços diferentes entre C101 e C105**. Não é preferência, é impossibilidade. É a prova que faltava para a conversa com o time de integração.

E confirma o código da chave de integração: `C101`, `S206`, `G101` e assim por diante, que é o BUKRS.

### Confirmações do desenho

1. A vigência não tem data de fim, e não há restrição de plataforma que obrigue, então fica vazia;
2. O bloqueio comercial só é efetivo quando **não existe nenhum preço vigente aprovado**, e não quando existe um novo pendente. O meu `getPrecioVigente` já implementa isso;
3. A taxa de imposto **nunca** se grava na entrada de preço, vive em tabela editável sem deploy. Decision Matrix confirmado;
4. Aprovação assimétrica pelos cinco campos, aprovador por marca e não por hierarquia;
5. Custo e margem só para Gerente de Marca, Gerente de Vendas, Diretor e Vice, via segurança de campo.

---

## 5. Resumo honesto da cobertura

Dos dez blocos de regra e dos vinte cenários, **o desenho v2 cobre a estrutura de tudo**, com quatro exceções concretas: os três pisos calculados do Escenario 12, a lista separada de acessórios, o campo de vigência do cashback e o registro do respaldo documental da exoneração.

**Mas nenhuma dessas quatro é o risco principal.** O risco principal é a direção do mestre do preço, seção 0. Se ela for decidida ao contrário do que a HU diz, não é uma lacuna a tapar, é uma história diferente.

## 6. O que fazer, em ordem

1. **Fechar a direção do mestre do preço** com a Melisa e com o time de integração, citando os quatro trechos da seção 0;
2. Resolver as três contradições internas da HU, marca multiplica listas, flotas canal ou campo, e Costa Rica em dólares;
3. Só então criar os campos, que são cinco mais três calculados;
4. A estrutura de listas sai da decisão do item 2, e é ela que dimensiona a carga.
