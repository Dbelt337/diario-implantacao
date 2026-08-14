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

### A conclusão honesta

Eu te disse há pouco que dava para simplificar tirando o objeto. **Fiz a conta e estava errado.** O objeto não é a complexidade, ele é o que remove a complexidade. A restrição de zero objetos custom, tomada em 12/08, foi correta com a informação daquele dia e não sobrevive à conta.

**É um objeto. Não é uma família de objetos.**

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

### Camada 2, a solicitação de mudança

Um objeto, `PriceChangeRequest__c`, um registro por produto, sociedade e moeda, com os valores propostos, o estado, o solicitante, o aprovador, a data e o arquivo.

Não é invenção. A RN3 descreve exatamente esse registro: *"Toda solicitud de cambio de precio queda registrada dentro del sistema: quién la pidió, quién la aprobó, cuándo y con qué archivo."*

O custo e a margem vivem aqui, não na entrada de preço. Assim a RN10 se cumpre sozinha: *"nunca en la lista comercial que consultan los asesores"*, porque simplesmente não estão lá.

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

## 6. O que fica em aberto e precisa de decisão do negócio

1. **A marca multiplica listas oficiais?** A RN2 diz que não e diz que sim em parágrafos seguidos. Se o responsável da marca não pode ver preço de outra marca nem na lista oficial, as oficiais também multiplicam;
2. **Flotas é canal ou é campo?** O Annex trata como canal e a RN1 cria o campo de preço de flotas na entrada. Os dois juntos duplicam o dado;
3. **Costa Rica em dólares.** A RN6 diz que se administra e exibe em USD, e o dado da org está em colones, inclusive na oportunidade da demo;
4. **Gastos vêm do SAP** pela RN5. Confirmar se é por serviço em tempo de cotização ou carga periódica.
