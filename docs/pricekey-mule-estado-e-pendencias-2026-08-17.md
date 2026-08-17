# Chave de upsert de preço para o Mule: estado real e o que falta

Data: 17/08/2026. Contexto: resposta ao Pablo Brito no Teams em 15/08, três pontos
sobre External Id em `PricebookEntry`, e a confirmação dele de que já usa
`SapMaterialCode__c`.

## O furo

O desenho que eu passei ao Pablo **já existe empacotado neste repositório**, em
`deploy/deploy-pricebookentry-pricekey.zip`, com exatamente a mesma lógica, inclusive a
âncora em `SapMaterialCode__c` e não em `ProductCode`.

**E nunca foi deployado.** O retrieve completo de 14/08 provou:

> Não existem `PricebookEntry.PriceKey__c` nem `Pricebook2.PricebookCode__c` (...) e
> `Pricebook2` não tem nenhum campo custom.

Ou seja, o Pablo está construindo o CSV contra **dois campos que não existem em nenhuma
org**. `SapMaterialCode__c` existe, e é o que ele disse que já usa, mas a chave do
`PricebookEntry` e o código da lista não.

Isso precisa ser dito a ele hoje, senão ele monta o mapeamento, testa, toma
`INVALID_FIELD` e a conta cai no nosso lado.

## O contrato da chave, exato

O que eu escrevi no Teams estava incompleto: falei "código do material + código da lista
+ moeda" sem dizer o separador. O pacote define, e tem que ser idêntico dos dois lados,
porque o Apex de `asegurarEntradas` vai montar a mesma string:

```
PriceKey__c = SapMaterialCode__c + '|' + PricebookCode__c + '|' + CurrencyIsoCode
```

Separador **barra vertical**. Sem espaços.

Comprimento confere, e vale registrar porque estourar silenciosamente seria pior:

| Parte | Tamanho |
|---|---|
| `SapMaterialCode__c` | Text(18) |
| separador | 1 |
| `PricebookCode__c` | Text(40) |
| separador | 1 |
| `CurrencyIsoCode` | 3 |
| **total máximo** | **63** |

`PriceKey__c` é Text(80). Cabe com folga.

Os três campos são `unique` e `externalId`, `caseSensitive` false.

## Por que a referência do CSV do Pablo funciona

`Product2.SapMaterialCode__c` é Text(18), `unique` e `externalId`. Marcar único mais
External Id é o que liga a propriedade **idLookup**, e é ela, não o External Id sozinho,
que permite referenciar o pai pelo cabeçalho `Product2.SapMaterialCode__c` no CSV e usar
o campo como chave de upsert. Então o ponto que passei está certo, mas por um motivo que
vale ele saber, para não criar um External Id não único e achar que basta.

Mesma coisa em `Pricebook2.PricebookCode__c`, que por isso nasce único no pacote.

## Três coisas que vão dar erro no primeiro teste dele, se ninguém avisar

1. **Entrada padrão antes da entrada da lista.** `PricebookEntry` em lista custom exige
   uma entrada ativa no price book padrão para o mesmo produto, senão vem
   `STANDARD_PRICE_NOT_DEFINED`. Numa carga em massa isso significa **duas passadas**,
   primeiro o padrão, depois as listas, não um arquivo só;
2. **`CurrencyIsoCode` é fixo na criação.** Não se atualiza. Trocar moeda é apagar e
   recriar a entrada. Como a moeda está dentro da chave, o comportamento fica coerente:
   moeda diferente é chave diferente, entrada diferente;
3. **Upsert por `PriceKey__c` atualiza, mas para criar o payload ainda tem que trazer as
   referências de produto e de lista.** A chave não substitui os dois relacionamentos, ela
   só evita a consulta prévia para saber se a entrada já existe.

## Pendências, em ordem

1. **Deployar `deploy-pricebookentry-pricekey.zip`** em DEV Sales, INT e QA. A verificação
   prévia que a regra dura exige já está feita, o retrieve de 14/08 provou que os dois
   campos não existem e que `Pricebook2` não tem campo custom nenhum, então não há
   duplicidade a evitar;
2. **Rodar `docs/scripts/check-pricebookentry-upsert.apex`** depois do deploy. Ele imprime
   `isIdLookup` de cada campo. É o flag que decide se a API aceita `PriceKey__c` como
   chave de upsert. Enquanto ninguém rodar isso, a viabilidade é aposta, não fato;
3. **Preencher `PricebookCode__c` com `docs/scripts/set-pricebook-code.apex`**, nas quatro
   orgs, com os mesmos códigos. O mapa hoje tem só `STANDARD` e `C101`. **Falta o Pablo
   dizer quais códigos o Mule vai enviar**, porque se não coincidirem o upsert não
   encontra a lista e cria entrada em lugar nenhum;
4. Confirmar que `SapMaterialCode__c` existe também em **INT e QA**, não só em DEV Sales.
   O retrieve foi de DEV Sales.

## Mensagem para o Pablo

Em português, pronta para colar no Teams. Vale mandar dividida, o Teams corta.

> Pablo, um complemento importante antes de você fechar o mapeamento.
>
> Os dois campos que eu te passei, `PricebookEntry.PriceKey__c` e
> `Pricebook2.PricebookCode__c`, **ainda não existem na org**. Estão empacotados do nosso
> lado e vão para DEV, INT e QA. Eu te aviso quando subirem. O `SapMaterialCode__c` que
> você já usa existe e não muda.
>
> O formato da chave, para os dois lados montarem igual, separador barra vertical, sem
> espaços:
>
> `SapMaterialCode__c|PricebookCode__c|CurrencyIsoCode`
>
> E três coisas que vão te aparecer no primeiro teste:
>
> 1. entrada de preço em lista custom exige entrada ativa no price book padrão para o
> mesmo produto, senão vem `STANDARD_PRICE_NOT_DEFINED`. Então são duas passadas, primeiro
> o padrão e depois as listas, não um arquivo só;
> 2. `CurrencyIsoCode` não se atualiza depois de criada a entrada. Trocar moeda é apagar e
> recriar. Como a moeda está na chave, moeda diferente já é entrada diferente;
> 3. o upsert por `PriceKey__c` te livra da consulta prévia, mas na criação o payload ainda
> precisa trazer produto e lista.
>
> E preciso de uma coisa tua: **a lista de códigos de price book que o Mule vai enviar**.
> Eu preencho o `PricebookCode__c` nas quatro orgs com exatamente esses valores. Se não
> coincidirem, o upsert não acha a lista.
