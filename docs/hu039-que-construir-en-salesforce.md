# HU-039 — O que construir no Salesforce, peça por peça

Lista de construção. Cada item diz o que é, o que faz, onde vive e o detalhe de implementação que costuma dar errado se ninguém avisar.

Legenda de estado: **PRONTO** já está empacotado, **CONSTRUIR** falta fazer, **AJUSTAR** existe e precisa mudar.

---

## 1. Metadados, sem código

### 1.1 Record Types em Product2 — PRONTO

Três: `Material`, `MaterialRequestOriginalPart`, `MaterialRequestWildcardCode`. Estão em **`deploy-hu039-solicitud-material-v2.zip`**, que substitui o pacote original de 18 campos. O pacote antigo não deve mais ser usado.

**Detalhe:** Product2 não tinha nenhum Record Type, então depois do deploy é obrigatório rodar `post-deploy-hu039-asignar-recordtype.apex` para colocar os 281 produtos existentes no Record Type Material. Sem isso o catálogo some das List Views.

### 1.2 Campos em Product2 — REVISAR ANTES DE DEPLOYAR

O pacote traz 18 campos, mais o `RequestBrand__c` no pacote 2. **Foi montado
sem verificar o que já existe**, e o describe de 14/08
(`check-product2-campos-existentes.apex`) mostrou que `Product2` hoje só tem
dois campos custom, `Version__c` e `SapMaterialCode__c`, e uma lista grande de
campos padrão do Automotive que ninguém tinha olhado.

**Seis dos 19 propostos saem, e um deles é o pacote 2 inteiro:**

| Proposto | Substituto padrão | Nota |
|---|---|---|
| `RequestBrand__c` | **`BusinessBrandId`** | Lookup padrão do Automotive. **Elimina o pacote 2** |
| `RequestedMaterialCode__c` | `ProductCode` | Está livre, porque o código do SAP vive em `SapMaterialCode__c`. Como a solicitação e o material são o mesmo registro, `ProductCode` leva o código solicitado desde o início |
| `RequestedBy__c` | `CreatedById` | Só precisa de campo próprio se quem solicita puder diferir de quem cria |
| `RequestVin__c` | nenhum, e é o objeto errado | VIN é contexto de uma venda. O material fica no catálogo para todos e arrastaria o VIN da primeira solicitação para sempre. Pertence à linha da cotização |
| `RequestVehicleModel__c` | idem | Existe `ModelName` padrão, mas ele descreve o que o produto **é**, não para que veículo serve. Usar seria pior que criar |
| `SapLastError__c` e `SapRetryCount__c` | Nebula Logger | Já instalado. No produto basta estado e `SapLastAttempt__c`, que é o que a list view de travadas filtra |

**Ficam 12 campos**, e nenhum deles tem equivalente padrão: `RequestKey__c`,
`RequestStatus__c`, `RequestCompany__c`, `RequestPlant__c`, `RequestBranch__c`,
`RequestFob__c`, `RequestOrigin__c`, `RequestNotes__c`, `RejectionReason__c`,
`SapLastAttempt__c`, `TurnoverClass__c`, `SupersededByProduct__c`.

### 1.2bis Campos padrão que a HU precisa e ninguém tinha mapeado

O describe revelou campos do Automotive que resolvem requisitos da própria
HU-039 sem criar nada:

- **`HarmonizedTariffSchedCode` e `HarmonizedSystemCode`**: a partida
  arancelária. A RFC `ZQEV_DBM_CREACION_MATERIALES` **rejeita a criação quando
  ela falta**, e isso estava mapeado como bloqueio sem dono. Os campos já
  existem;
- **`BusinessBrandId`**: a marca, como lookup a `BusinessBrand`. Exige que os
  registros de marca existam, o que é carga de dado e não metadado;
- `ManufacturerPartNumber`, `ProductLineCode`, `ProductCategoryCode` e
  `UniversalProductCode`: candidatos naturais para os "todos los datos de la
  consulta rápida" da RN-49, que é um dos bloqueios abertos. Vale cruzar a
  lista da RN-49 contra esses antes de criar campo nenhum.

### 1.3 Validation rule — PRONTO

`Request_Cannot_Be_Active_Before_SAP`. Impede ativar uma solicitação na mão. Só dispara nos dois Record Types de solicitação, então a réplica de catálogo nunca a toca.

### 1.4 Page Layouts, três — CONSTRUIR

| Layout | Para | O que muda |
|---|---|---|
| `Material Layout` | RT Material | Layout de catálogo normal. Os campos de solicitação ficam fora |
| `Material Request Original Part` | RT Repuesto Original | Obrigatórios: `RequestBrand__c`, `RequestedMaterialCode__c`, `Description`, `RequestCompany__c`, `RequestPlant__c`, `RequestBranch__c` |
| `Material Request Wildcard Code` | RT Código Comodín | Obrigatórios: `RequestedMaterialCode__c` e `Description`. Marca vira desejável |

**Detalhe que resolve a divergência de quem escreve o estado:** o `RequestStatus__c` entra como **somente leitura no layout de Repuestos** e editável no de PA. Obrigatoriedade e somente leitura por Record Type se fazem no layout, não em FLS, porque FLS é por perfil e não por Record Type. O layout é atribuído por perfil e Record Type, então o mesmo campo pode ser editável para o Catman e travado para o resto.

### 1.5 List Views — CONSTRUIR

Quatro, todas filtradas por Record Type:

1. `Solicitudes Repuestos abiertas` — RT Original Part ou Wildcard, estado Pending ou InReview;
2. `Solicitudes PA abiertas` — para o Catman;
3. `Solicitudes trabadas` — estado Pending ou InReview com `SapLastAttempt__c` anterior a X horas. É a peça que substitui o Case proibido pela RN-56;
4. `Mis solicitudes` — filtrada por `RequestedBy__c` igual ao usuário atual, para o assessor.

### 1.6 Field History e Feed Tracking — CONSTRUIR

**Ordem importa:** habilitar Field History Tracking em Product2 no Setup **antes** de deployar o pacote 1, porque quatro campos vêm com histórico ligado e o deploy recusa se o objeto não tiver o rastreamento ativo.

**E ligar o histórico de `ProductCode` na mão**, porque ele passou a carregar o código solicitado no lugar do `RequestedMaterialCode__c` que saiu. Campo padrão não vem no pacote, então o rastreamento dele é ação de Setup e é fácil esquecer.

Feed Tracking em Product2 sobre `RequestStatus__c`. É o que faz os seguidores receberem aviso sem uma linha de código (RN-56).

### 1.7 Permission Sets, três — CONSTRUIR

| Permission Set | Quem | O que dá |
|---|---|---|
| `PS_Material_Request_Advisor` | Assessores de Repuestos e PA | Criar e ler solicitações, ler os campos, Record Types de solicitação atribuídos |
| `PS_Material_Request_Manager` | Gestión de Inventarios e Catman | Editar solicitações, mudar estado no caso de PA |
| `PS_Material_Request_Viewer` | Jefe, Encargado, Gerente, Gerente de canal | Somente leitura (CA-17) |

**Detalhe fácil de esquecer:** o usuário de integração precisa de FLS de escrita em `RequestStatus__c`, `SapLastError__c`, `SapRetryCount__c`, `SapLastAttempt__c`, `ProductCode`, `SapMaterialCode__c` e `IsActive`. Sem isso a integração falha em silêncio, sem erro visível.

### 1.8 Custom Notification Type — CONSTRUIR

Um, chamado `Material_Request_Update`. É o que notifica o assessor solicitante, diferente do aviso aos seguidores (CA-14 pede os dois separados).

---

## 2. Apex

### 2.1 `MaterialCreationService` — AJUSTAR

Existe e já chama a RFC com os cinco parâmetros certos. Três mudanças:

1. **Remover `abrirCaso()`** e trocar por chamada ao `MaterialRequestService`. A RN-56 proíbe Case.
2. **Não ativar direto.** Hoje, no sucesso, faz upsert com `IsActive = true`. Passa a ser: sucesso da RFC, depois consulta de materiais para hidratar, depois grava e ativa. A RFC só devolve `MENSAJE`, não devolve dado mestre.
3. **Ordem callout antes de DML.** Todas as chamadas ao SAP acontecem antes de qualquer escrita. Se inverter, a transação morre com *"You have uncommitted work pending"*.

### 2.2 `MaterialRequestService` — CONSTRUIR

A peça nova mais importante. Responsabilidades:

```
Id crearSolicitud(SolicitudRequest req)
```

1. Monta o `RequestKey__c` com uma **regra de normalização única e documentada**: `UPPER(TRIM(código)) + '|' + sociedade + '|' + centro`. Essa regra tem que ser a mesma que o Mule usa do outro lado, senão a correlação quebra. Escrever num único método `construirClave()` e nunca duplicar a lógica.
2. Escolhe o Record Type conforme seja Original Part ou Wildcard.
3. Insere com `IsActive = false` e `RequestStatus__c = Pending`.
4. **Trata `DUPLICATE_VALUE`**: se o insert falhar por chave duplicada, não é erro, é a corrida. Busca a solicitação existente, devolve o Id e sinaliza para a UI mostrar a mensagem e oferecer seguir.

```
void marcarCreado(String requestKey, MaterialMaestro datos)
```

Grava MATNR, dados mestres, muda o Record Type para Material, ativa. **Trata `DUPLICATE_VALUE` no `SapMaterialCode__c`**: significa que a réplica de catálogo chegou primeiro e já criou o produto. Nesse caso marca a solicitação como Material Creado, mantém inativa e notifica apontando para o produto que a réplica criou.

```
void liberarClave(Id productId)
```

Limpa o `RequestKey__c` ao rejeitar, para permitir nova solicitação sobre a mesma combinação (RN-14).

### 2.2bis Entradas de preço e o preço da linha — LER ANTES DE CONSTRUIR

Levantado em 14/08 ao cruzar esta HU com a estrutura de listas da HU-038. São
três coisas diferentes e só a terceira é grave.

**Primeira, a que JÁ está resolvida no código.** `MaterialCreationService`
tem `asegurarEntradas(productId, pricebookId, currencyIsoCode)`, chamada dentro
de `crearMaterial`. Ela cria a entrada na Standard Price Book e a entrada na
lista da venda, ativas, e já trata o caso de já existirem. **Não construir peça
nova para isso.** A ordem obrigatória de plataforma, standard antes de lista
custom, já está respeitada, e sem ela a segunda gravação falharia com
`STANDARD_PRICE_NOT_DEFINED`.

**Segunda, o que falta de verdade nessa parte.** `asegurarEntradas` é privada e
só é chamada no caminho síncrono, onde `pricebookId` e `currencyIsoCode` vêm do
contexto da cotização. A HU-039 separa Tiempo 1, a solicitação, de Tiempo 2, a
confirmação que volta pelo Mule. **`marcarCreado` roda sem cotização por
perto**, então não tem nenhum dos dois valores. O que fazer:

1. Tornar `asegurarEntradas` visível ao `MaterialRequestService` e chamá-la de
   `marcarCreado`. Reutilizar, não reescrever, conforme a decisão de governança
   de 14/08;
2. Resolver os dois parâmetros sem inventar campo novo no `Product2`:
   - moeda, a partir de `Sociedad_Config__mdt.Currency_Code__c`, indexado por
     `RequestCompany__c`. Esse Custom Metadata já existe e já é usado pelo
     `Lead_BS_DeriveSociedad`;
   - lista, buscando o `Pricebook2` de repuestos por `PricebookCode__c`, o campo
     do pacote `deploy-pricebookentry-pricekey`.
3. Lembrar que `PricebookEntry` é uma por produto, lista **e moeda**. Material
   criado para uma sociedade em CRC não fica cotizável numa venda em USD.

**Terceira, e é a grave: hoje o repuesto criado é cotizado a ZERO.**

A cadeia, verificada no código que está no ar:

| Passo | O que acontece |
|---|---|
| `asegurarEntradas` | Cria as entradas com `UnitPrice = 0` |
| `RepuestosLineService` | Monta a `QuoteLineItem` com `UnitPrice = pbe.UnitPrice`, ou seja, 0 |
| `SapMuleClient.MaterialSaldo` | Traz `piso`, `reserva`, `saldoDisponible`, `textoExistencia`. **Traz estoque, não traz preço** |
| `simulateSalesOrder` | `SimulationLine.unitPrice` é **entrada**, o Salesforce manda o preço para o SAP. `SimulationResult` devolve só `netAmount`, `taxAmount` e `totalAmount`, nada por linha |

Ou seja, **o preço da linha de repuestos sai da entrada local, não do SAP.** A
decisão de que repuestos e PA têm preço consultado por API por causa do
dinamismo **não está implementada para o preço da linha**. O que está
implementado por API é a consulta de saldo.

Enquanto isso não for fechado, todo material criado por esta HU entra na
cotização valendo zero, e a simulação confirma zero porque foi o Salesforce que
mandou o zero.

**O que construir, e é a peça que faltava de verdade:**

1. Adicionar `ZHYB_DBM_PRECIO_VTA_NO_MAESTRO` ao `SapMuleClient`, com DTO de
   retorno que tenha preço por material. É o serviço citado no fluxograma da
   própria HU-039, que "creará el material, en caso de estar en el maestro de
   materiales, y le asignará un precio estimado";
2. `RepuestosLineService` passa a gravar `UnitPrice` da linha com o preço
   devolvido pelo SAP, e não com `pbe.UnitPrice`. A entrada local continua
   existindo em zero, porque o modelo nativo exige que toda linha aponte para
   uma `PricebookEntry`, mas ela deixa de ser fonte de preço;
3. Se o serviço não devolver preço para um código, a linha **não pode** ser
   criada valendo zero. Tem que ficar marcada como sem preço, do mesmo jeito que
   hoje fica marcada como `sinCatalogo`.

Manter a entrada local em zero é a decisão certa depois de ver isso: zero é
honestamente vazio, um último preço conhecido pareceria autoritativo e seria
pior, porque ninguém desconfia de um número plausível.

### 2.2ter `SapMuleClient.mockMode` — VERIFICAR ANTES DE QUALQUER DEPLOY

`mockMode` é `public static Boolean mockMode = true`, e **nada no código
deployado o coloca em false**. Numa org real, todas as chamadas devolvem dado
fabricado e determinista, sem nenhum erro visível. O saldo aparece, o preço
fecha, a simulação bate, e nada disso veio do SAP.

Antes de qualquer demonstração ou teste com o cliente, confirmar como esse
valor é desligado no ambiente. Se a resposta for "alguém seta em runtime", isso
precisa virar Custom Metadata com valor por ambiente, não uma variável estática
com default perigoso.

### 2.3 `SapMuleClient` — AJUSTAR

Adicionar o método de consulta de materiais (`ZHYB_C4C_CONSULTA_MATERIALES`) com o DTO de retorno, e configurar timeout curto e explícito, na casa de 10 a 15 segundos. Corrigir também o comentário de cabeçalho que hoje diz que Z301 é pedido de venda, quando é oferta ou reserva.

### 2.4 `GuidedSellingController` — AJUSTAR

Dois métodos novos expostos ao LWC:

1. `verificarYCrearMaterial(...)` — `cacheable = false` obrigatoriamente, porque faz callout e porque dado de disponibilidade não pode vir de cache;
2. `crearSolicitudMaterial(...)` — cria a solicitação prellenada.

### 2.5 `FollowRecordAction` — CONSTRUIR

Invocable de uma linha útil, insere `EntitySubscription` com `ParentId` do registro e `SubscriberId` do usuário. Flow não tem ação nativa para seguir registro, e a RN-35 pede exatamente isso.

**Detalhe operacional:** cada usuário segue no máximo 500 registros. Um assessor que abra muitas solicitações chega lá. Vale prever limpeza dos follows de solicitações fechadas.

### 2.6 Testes — CONSTRUIR

Os que realmente importam, além da cobertura: dois usuários criando a mesma solicitação em paralelo, réplica chegando antes da notificação, RFC devolvendo erro de serie faltante, e RFC não respondendo dentro do timeout.

---

## 3. LWC

### 3.1 `lineasRepuestos` — AJUSTAR

Já tem o banner de busca sem resultado e o botão de solicitar criação. O que muda: o botão passa a abrir o modal novo em vez de chamar a criação direto, e o resultado da RFC passa a ter três desfechos visíveis, criado, solicitação gerada, e já existe solicitação aberta com opção de seguir.

### 3.2 `solicitudMaterial` — CONSTRUIR

Modal com os campos por tipo de solicitação. Três comportamentos que valem código:

1. **Pré-preenche tudo o que dá do contexto**: sociedade, centro, sucursal, o código que o assessor digitou na busca;
2. **Resolve canal e serie** conforme a definição que ainda falta, e enquanto não vier deixa os dois como campos visíveis para o assessor preencher, que é a opção que não bloqueia;
3. **Spinner com texto e teto de espera**. O assessor está com o cliente na frente; se passar do timeout, a tela diz que a solicitação foi registrada e libera.

---

## 4. Flows

### 4.1 Flow de duplicados, disparado por registro, antes de salvar — CONSTRUIR

A RN-34 manda usar Flow e proíbe Duplicate Rules. A forma correta é um **record-triggered flow before save** em Product2 que faz Get Records de solicitação aberta com a mesma chave e usa o elemento **Custom Error** para bloquear.

Por que assim e não só no Apex: o Flow cobre **todos** os caminhos de entrada, o LWC, a criação manual na tela e o data loader. O Apex só cobre o caminho do LWC.

**A divisão de responsabilidades entre as três camadas:**

| Camada | Papel |
|---|---|
| LWC e Apex | Consulta antes, mostra a mensagem amigável e oferece seguir a solicitação existente |
| Flow | A regra formal, cobre todos os caminhos de entrada (RN-34) |
| Campo único no banco | A garantia sob concorrência. É a única das três que não tem janela de corrida |

### 4.2 Flow de notificação, disparado por registro, depois de salvar — CONSTRUIR

Quando `RequestStatus__c` muda para Material Creado ou Rejected, dispara a Custom Notification para o usuário de `RequestedBy__c`. Os seguidores já recebem pelo Feed Tracking, sem flow.

### 4.3 Flow agendado de solicitações travadas — CONSTRUIR

Roda a cada X horas, busca solicitações abertas com `SapLastAttempt__c` antigo e manda alerta por e-mail a um grupo público. É o escalonamento da RN-52 sem abrir Case. O destinatário e o prazo são configuração, não código.

### 4.4 Aprovação de PA — CONSTRUIR

Verificação de um minuto primeiro: Setup, Approval Processes, ver se Product2 aparece na lista de objetos. Se aparecer, Approval Process nativo de dois passos, Director e depois VP. Se não aparecer, Flow Orchestration com dois estágios de aprovação.

**Detalhe operacional:** durante a aprovação o registro fica travado para edição, então o Catman carrega a cotização **antes** de submeter.

---

## 5. Integração

| Perna | Estado | Observação |
|---|---|---|
| Saída, criação e extensão | Existe, `ZQEV_DBM_CREACION_MATERIALES` | Síncrona. Falta resolver de onde saem `CANAL` e `SERIE` |
| Saída, consulta de materiais | Existe, `ZHYB_C4C_CONSULTA_MATERIALES` | Traz os dados mestres para hidratar |
| Entrada, notificação com MATNR | **Só é necessária se o caminho de exceção for completado dentro do SAP.** Se a solicitação completada for reenviada pela mesma RFC desde o Salesforce, não precisa | Decisão, não dependência |
| Réplica de catálogo | Existe, MATMAS | É o vetor de duplicidade tratado no item 2.2 |
| **Saída, preço de venda do material** | **NÃO existe no `SapMuleClient`** | `ZHYB_DBM_PRECIO_VTA_NO_MAESTRO`. Sem ela o repuesto criado é cotizado a zero, item 2.2bis |

---

## 6. Ordem de construção

**Bloco A, não depende de ninguém, começa hoje.**

1. Habilitar Field History em Product2 no Setup;
2. Deploy do pacote 1, depois o script de reatribuição, depois atribuir Record Types aos perfis;
3. Deploy do pacote 2;
4. Page Layouts, List Views e Feed Tracking;
5. Permission Sets;
6. `MaterialRequestService` e o Flow de duplicados;
7. Ajuste do `MaterialCreationService`, tirar o Case e inverter a ordem para callout antes de DML;
8. Chamar `asegurarEntradas` a partir de `marcarCreado`, resolvendo moeda por `Sociedad_Config__mdt` e lista por `PricebookCode__c`. É reuso, não peça nova;
9. **Verificar `SapMuleClient.mockMode` antes de qualquer teste com dado real.** Item 2.2ter.

**Bloco B, depende de uma definição pequena.**

10. Modal `solicitudMaterial` e ajuste do `lineasRepuestos`. Pode ser construído já, deixando canal e serie como campos do formulário, e depois automatizado quando vier a definição;
11. Custom Notification e o Flow de notificação;
12. `FollowRecordAction`;
13. **Preço da linha de repuestos vindo do SAP**, item 2.2bis terceira parte. Depende do time de Mule expor `ZHYB_DBM_PRECIO_VTA_NO_MAESTRO` com preço por material. Enquanto não existir, o repuesto criado é cotizado a zero.

**Bloco C, depende de definição externa.**

14. Aprovação de PA, depois da verificação em Setup;
15. Flow de travadas, depois do destinatário e do prazo;
16. Automatizar canal e serie, depois da definição;
17. Campos adicionais de dado mestre, depois da lista da RN-49.

O Bloco A é a maior parte do esforço e não espera ninguém.
