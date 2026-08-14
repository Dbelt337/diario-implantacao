# HU-038 — A solução recomendada, com a conta de complexidade feita

**Data:** 14/08/2026 · Consolida a v2, a verificação de cobertura e a releitura do catálogo de objetos padrão do Automotive Cloud.

---

## 1. O que a documentação do Automotive estabelece

**O Automotive Cloud não tem objeto de preço.** A lista completa de Standard Objects cobre veículo e definição de veículo, avalúo, ativo e titularidade, frota, garantia e reclamação, telemetria, agendamento, visitas, códigos de indústria e o bloco financeiro. **Nenhum objeto de pricing.**

E há uma confirmação documental melhor que a ausência. O `VehDefSearchableField` é definido como *"multiple fields from objects such as **Product, Price Book**, and Vehicle Definition"*. Ou seja, quando o próprio Automotive precisa citar de onde vêm produto e preço, ele cita **Product e Price Book da plataforma**.

**Conclusão fundamentada:** o preço vive em `Pricebook2` e `PricebookEntry`. Não existe alternativa nativa do Automotive, e a venda guiada já está no modelo certo.

O objeto mais próximo de preço na lista é o `SellerProduct`, API 65, *"products associated with a seller... product availability, production details, and the seller's role for the product"*. Ele associa produto a vendedor e **não carrega preço**, então não substitui nada aqui.

---

## 2. As quatro restrições que desenham a solução

1. **Uma única `PricebookEntry` por produto, lista e moeda.** Preço vigente e preço pendente não cabem na mesma lista;
2. **`PricebookEntry` não admite trigger Apex, nem record-triggered flow, nem Process Builder**, e não está na lista de objetos de aprovação clássica. Nada reage ao gravar;
3. **`PricebookEntry` aceita campos custom**, comprovado, a org já tem sete;
4. **Campo fórmula lê Custom Metadata**, então cálculo sem automação é possível.

---

## 3. A conta de complexidade, que é o que decide

A pergunta não é "com ou sem objeto custom". É **quantas peças cada caminho custa**. Fiz a conta.

### Caminho A, zero objetos custom, com listas de staging

Para o preço pendente conviver com o vigente, ele precisa de outra lista. E há dois requisitos que multiplicam essas listas ao mesmo tempo:

- **Por sociedade**, obrigatório: o mesmo modelo pode ter preço pendente diferente em C101 e em C105, e na mesma lista eles colidem pela restrição 1;
- **Por marca**, obrigatório: a RN2 exige que o responsável *"solo administra **y visualiza** los precios de su marca"*, e não existe forma de restringir acesso por marca **dentro** de uma lista.

Então as listas de staging são **12 sociedades multiplicadas pelo número de marcas**. Com oito marcas, são 96 listas de staging, mais as 12 oficiais, mais as de acessórios. **Mais de 120 price books para manter, nomear, permissionar e replicar em quatro ambientes.**

E mesmo assim dois requisitos ficam sem solução: o acesso por marca **nas listas oficiais**, e a aprovação, que teria de ser construída à mão porque não há objeto para aprovar.

### Caminho B, um objeto de solicitação

O preço pendente vira registro, não entrada de lista. Some a colisão e some a multiplicação.

- Price books: **12 oficiais por sociedade mais as de acessórios**. Nenhuma lista de staging;
- Acesso por marca: regras de compartilhamento no objeto, nativo;
- Aprovação: processo de aprovação nativo, individual e em bloque;
- Cálculo dos pisos ao gravar: record-triggered flow, nativo.

**Um objeto custom elimina mais de noventa price books e resolve dois requisitos que o outro caminho deixa em aberto.**

### A conclusão, depois de verificar o que faltava

**A v2 sem objeto custom fecha.** Os três bloqueios que eu tinha levantado têm saída, e duas delas são simples:

1. **Cálculo dos pisos ao gravar:** resolvido com **campos fórmula** lendo Custom Metadata. Não precisa de automação nenhuma;
2. **Disparo do estado e da aprovação:** resolvido porque **somos donos da porta de escrita**. A carga massiva e a edição individual passam pela nossa LWC e pelo serviço Apex, e é ele que decide, marca o estado e submete. Nada precisa reagir ao save;
3. **Objeto para aprovar:** resolvido pela **Approval Orchestration autolaunched**, que a documentação descreve como podendo ser *"triggered from other processes or even custom buttons"*. Nosso serviço a dispara passando o registro. Não depende de a `PricebookEntry` suportar record-triggered flow.

**Então a recomendação volta a ser a v2, com zero objetos custom.** O que eu tinha dado como impossível era falta de verificação minha, não limite de plataforma.

### A única coisa que ainda precisa ser verificada na org

Se a **Approval Orchestration aceita `PricebookEntry` como objeto alvo**. Verificação de dois minutos: Setup, Approvals, criar um Flow Approval Process e ver se `PricebookEntry` aparece no seletor de objeto.

Se aparecer, a v2 está completa e não se cria nada.

Se **não** aparecer, aí sim a aprovação precisa de um registro que a suporte, e nesse caso a decisão volta à mesa, com as duas opções da seção 5.

### Sobre a multiplicação de listas de staging

O meu alerta de que as listas de staging multiplicariam por sociedade **depende de um fato do GrupoQ que eu não sei**: se o mesmo modelo é vendido por **mais de uma sociedade na mesma moeda**.

Se C101 e C105 forem sociedades segmentadas por marca ou por linha, como o nome da lista existente sugere, um produto pertence a uma sociedade só e **não há colisão nenhuma**. A v2 funciona exatamente como escrita, com **uma lista de staging por marca**.

Se houver sobreposição real, a saída não é objeto custom, é staging por marca e sociedade **apenas nas combinações que existem de fato**, que é bem menos que o produto cartesiano.

**Pergunta a confirmar com o negócio:** um mesmo modelo é vendido por duas sociedades do mesmo país, com preços diferentes e na mesma moeda?

---

## 4. A solução recomendada

### Camada 1, o preço publicado

`PricebookEntry` na lista oficial da sociedade, ativa. É a única coisa que o processo comercial lê.

Onze campos comerciais, dos quais **seis já existem na org**. Faltam `ImpuestoPrimeraMatricula__c`, `PrecioFlotas__c`, `CostoEstimado__c`, `CostoEstimadoExonerado__c` e a vigência final do cashback.

Os **três pisos por fator do Escenario 12 são campos fórmula** lendo Custom Metadata, sem nenhuma automação:

```
MinimoGerenteVentas__c = PrecioMinimoAsesor__c * $CustomMetadata.FactorNivel__mdt.GerenteVentas.Factor__c
```

Atende *"aplicando los factores vigentes de la tabla editable, sin intervención manual"* e a tabela é editável sem deploy, como a RN9 exige.

No `Product2` entra a moeda de publicação, porque a RN6 diz **por modelo**.

### Camada 2, o preço pendente

`PricebookEntry` na **lista de staging da marca**, com `IsActive = false`. Mesma estrutura, mesmos campos, mesma carga. A publicação é uma cópia.

`IsActive = false` é o que faz o *"no se activan en el catálogo"* da RN3 ser garantido **pela plataforma** e não por uma marca que a gente inventou: entrada inativa não entra em cotização, ponto.

Campos de controle na entrada de staging: `Estado__c`, `MotivoRechazo__c`, e o `VigenciaDesde__c` que já existe.

Na lista de staging, dois campos no `Pricebook2`: `MarcaPropietaria__c` e `AprobadorMarca__c`, que é o aprovador dinâmico por marca **sem objeto novo**, atendendo a RN3 quando ela diz que o aprovador se determina por marca e não por hierarquia.

O acesso por marca sai do **compartilhamento de `Pricebook2`**, que a lista suporta: o responsável de uma marca só enxerga a staging da sua marca.

**Custo e margem:** ficam na entrada de staging, com segurança de campo pelo permission set `PS_Precios_Margen`. A RN10 exige que o asesor não veja, e FLS resolve. Como a entrada de staging não é lida pelo processo comercial, o dado nem chega perto da lista que o asesor consulta.

### Camada 3, a porta de escrita

Uma LWC mais um serviço Apex para a carga massiva e para a edição individual. Não é preferência: como a `PricebookEntry` não tem automação, se não formos donos da porta, nada reage.

O serviço compara os cinco campos disparadores contra a entrada oficial vigente e decide: baixou, vai para aprovação; subiu ou mudou só gastos ou percentual de primeira matrícula, publica direto, que é o Escenario 2.

Tirar a edição direta de `PricebookEntry` dos perfis administrativos fecha a porta dos fundos. É uma configuração de perfil.

### Camada 4, aprovação

Processo de aprovação nativo sobre a solicitação. Aprovador determinado **por marca** e não por hierarquia, que é o que a RN3 exige e que o processo nativo resolve com aprovador dinâmico. Aprovação em bloque pela list view. Notificação nativa ao solicitante.

### Camada 5, publicação

Ao aprovar, escreve na `PricebookEntry` oficial. Se a vigência for futura, um Apex agendado diário publica quando a data chega, que é o Escenario 14.

### Camada 6, o que já estava certo na v2 e não muda

Decision Matrix para taxas de imposto e para os fatores, editável sem deploy, e a taxa **nunca** gravada na entrada de preço, como a RN5 exige. Reports padrão para o relatório gerencial da RN8. Multimoeda nativa, com Guatemala tendo duas entradas por produto. Regra de arredondamento por sociedade e moeda em Custom Metadata, espelhando os quatro decimais do pricing do SAP e os dois das posições.

**Sobre a reconstrução do preço histórico, Escenario 10:** a fonte é a **própria cotização**, que grava o preço no momento em que cotizou. O histórico de campo serve para auditar quem mudou o quê, mas não deve ser a fonte da reconstrução, porque é retido por tempo limitado e tem teto de vinte campos rastreados por objeto.

---

## 5. Se ainda assim o objeto for vetado

Existe um caminho, e é a divisão em vez do corte.

**R1 sem objeto e sem aprovação:** as camadas 1, 3 e 6. Preço, campos, fórmulas, carga, impostos, moeda, arredondamento e relatório. Doze listas oficiais mais acessórios. A venda guiada cotiza. O controle de quem mudou o preço fica no histórico de campo e no arquivo anexo, procedimental.

**R2 com o objeto:** as camadas 2, 4 e 5, o circuito de aprovação, que é o `GQ-CA-01-106`.

Isso entrega o R1 sem nenhuma peça nova além de campos, e adia exatamente a parte que carrega o custo. E se encaixa no exercício de repriorização que a Melisa abriu.

---

## 6. As perguntas abertas, revisadas em 14/08

### 6.1 A marca multiplica listas? RESOLVIDO pelo próprio texto da HU

Eu tinha marcado isso como contradição. **Não é.** Os dois parágrafos da RN2 falam de coisas diferentes, e isso fica claro ao olhar o sujeito de cada frase:

> *"Como regla **estructural**, la marca es un atributo del producto y no multiplica listas: los productos se asocian a la lista de su sociedad."*

> *"La **administración** de precios es centralizada por MARCA... Se configuran Pricebooks separados por marca con accesos restringidos."*

O primeiro governa a **estrutura** das listas que o processo comercial consome: por sociedade, e a marca é atributo do produto.
O segundo governa a **administração**: listas separadas por marca, com acesso restrito.

**São duas camadas, não duas versões da mesma coisa.** E é exatamente o desenho de duas camadas da v2: listas oficiais por sociedade para cotizar, listas de administração por marca para carregar e aprovar. A HU descreve a solução sem nomeá-la.

**Conclusão: as listas oficiais NÃO multiplicam por marca.** Ficam doze, mais as de acessórios.

### 6.2 O que resta não é decisão, é um fato verificável no dado atual

A única pergunta que sobra sobre a estrutura é se as listas de administração por marca precisam ser também por sociedade. E ela **não se resolve em reunião**, se resolve olhando a lista de preços que o GrupoQ mantém hoje.

**A verificação, que leva cinco minutos numa planilha:** na lista mensal atual, o mesmo código de modelo aparece para **mais de uma sociedade do mesmo país, com preços diferentes e na mesma moeda**?

- **Não aparece:** uma lista de administração por marca resolve, sem nenhuma multiplicação. É o caso provável se as sociedades do mesmo país forem segmentadas por marca ou por linha, que é o padrão em grupos de distribuição;
- **Aparece:** as listas de administração passam a ser por marca e sociedade, **mas apenas nas combinações que existem de fato**, que é muito menos que o produto cartesiano.

Nos dois casos a estrutura oficial não muda. É a de administração que se dimensiona pelo dado.

### 6.3 Flotas é canal ou campo? Interpretação a confirmar

O Annex, fila 265, cita canais Retail, Flotas e Intercompany. A RN1 cria o campo **"Precio publicado de Flotas, que se digita y no se calcula"** dentro da entrada de preço.

**Nossa leitura:** o Annex descreve a capacidade geral de segmentação, e a RN1 toma a decisão concreta e mais recente, porque veio do refinamento. **Prevalece o campo.** Flotas não gera lista própria, e isso evita duplicar o mesmo dado em dois lugares.

É interpretação, não fato, e vale uma linha de confirmação.

### 6.4 As duas que continuam sendo do negócio

1. **Costa Rica em dólares.** A RN6 diz que os preços se administram e exibem em USD e que não se exibem em colones. O dado da org está em colones, inclusive na oportunidade da demonstração. Ou o dado corrige, ou a regra mudou;
2. **Gastos vêm do SAP** pela RN5, *"parametrizados por sociedad en SAP y el CRM los consume por servicio"*. Confirmar se é consulta em tempo de cotização ou carga periódica, porque muda quem escreve o campo.
