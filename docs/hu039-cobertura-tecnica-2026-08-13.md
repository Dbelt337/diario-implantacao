# HU-039 — Gestión de Solicitud de Creación de Material: cobertura técnica

**Data:** 13/08/2026 · **Base:** V3 da HU-039, código já implantado em DEV Sales (US-021 / HU-043), verificação de licenças e objetos do dia 13/08, documentação oficial de Salesforce.

---

## 1. Fica no fluxo de venda guiada? Metade sim, metade não

**Tiempo 1 fica dentro do fluxo. Tiempo 2 fica fora, no registro Product2.**

Não é preferência de desenho, é o que a própria HU pede. O Tiempo 1 nasce de uma busca sem resultado durante o atendimento (RN-17, RN-18, RN-23) e tem que resolver em segundos sem travar a venda (RN-02, RN-03, CA-03). Isso é exatamente o gatilho que o modal de venda guiada já tem hoje.

O Tiempo 2 pede List Views filtradas por Record Type (RN-62), Follow (RN-56), Salesforce Files (RN-57), Field History (RN-58) e aprovações (RN-45). Nenhuma dessas coisas existe dentro de um modal, e nenhuma delas pertence ao assessor que está atendendo. São do registro.

| Momento | Onde vive | Quem opera |
|---|---|---|
| Tiempo 1: busca sem resultado, consulta SAP, upsert ou extensão, e se falhar cria a solicitação prellenada | LWC `lineasRepuestos` dentro do fluxo guiado | Assessor de Repuestos y PA |
| Tiempo 2: triagem, dados mestres, aprovações de PA, retorno do MATNR, ativação | Registro Product2, com layout, List Views, Files, Chatter e aprovação | Gestión de Inventarios, Catman, Director e VP de PA |

O elo entre os dois é um registro Product2 inativo. O fluxo cria e solta. Ele não acompanha, não espera e não bloqueia.

---

## 2. Dois conflitos entre o que está no ar e a V3 da HU

Isso não é gap de escopo, é código já implantado que contraria a versão nova do documento. Tem que ser corrigido antes de qualquer coisa nova.

### Conflito 1: o caminho de falha abre Case, e a V3 proíbe Case

`MaterialCreationService.abrirCaso()` levanta um `Case` quando o SAP rejeita a criação. A RN-56 da V3 é explícita: *"Esta historia no contempla notificaciones customizadas entre áreas ni apertura de casos (objeto Case / Mesa de Servicios Interna) en Salesforce."*

O que a RN-23 pede no lugar: criar automaticamente uma **solicitação prellenada**, ou seja um Product2 com Record Type de solicitação e `IsActive = false`, registrando sociedade, centro e sucursal, e a venda continua sem o item.

Ação: substituir `abrirCaso()` por `crearSolicitud()`. É o mesmo ponto de código, muda o objeto de destino.

### Conflito 2: o caminho de sucesso ativa o produto na hora

`upsertProducto()` grava `IsActive = true` assim que o SAP responde OK. Isso está **certo** para os cenários RN-20 (catálogo desatualizado, upsert) e RN-21 (extensão automática bem sucedida), porque nesses casos o material já existe no Maestro de Materiales. Está **errado** como caminho único, porque na RN-42 a ativação só pode acontecer quando chega a confirmação de carga do SAP no Tiempo 2.

Ação: separar os dois caminhos explicitamente. Sucesso de consulta ou extensão ativa. Falha cria solicitação inativa. Retorno do Tiempo 2 ativa.

---

## 2bis. O fluxograma "Creación de Códigos — Repuestos" contra o texto da V3

O fluxograma traz três coisas que **não estão no texto da V3** e uma delas resolve o maior risco técnico da HU. Onde os dois divergem, é preciso decidir qual vale antes de construir.

### Divergência 1: o fluxograma tem uma integração de saída que a V3 apagou

O fluxograma tem a caixa **"Solicitud la manda Salesforce a SAP"**, ou seja Salesforce envia a solicitação para o SAP. O texto da V3 **removeu** isso: o Escenario 8 dizia *"ejecuta la aprobación con la acción de envío a SAP... Salesforce dispara la integración hacia SAP"* e foi reescrito para *"la solicitud queda lista para que el área responsable ejecute la carga del código en SAP"*. A RN-38 reforça que a carga ocorre fora do Salesforce.

**Recomendação: adotar o fluxograma, ou seja manter a perna de saída.** Sem ela, quando o SAP criar o código ele não tem como saber a qual solicitação nossa aquilo corresponde, e a RN-42 e a RN-43, que exigem atualizar **o mesmo registro** e não criar um segundo Product2, ficam sem chave de correlação. Com a perna de saída, o SAP guarda o nosso identificador e devolve com ele. É a diferença entre correlacionar por identidade e correlacionar por adivinhação.

Se o cliente insistir em não ter a saída, a alternativa é correlacionar pela chave natural (código, sociedade e centro), que é o `RequestKey__c` da seção 4.3, e aí a pergunta da seção 4.5 vira obrigatória.

### Divergência 2: quem muda os estados

O fluxograma mostra **"SAP notifica a Salesforce que cambia a estado En Revisión"** e **"SAP notifica a Salesforce que cambia a estado Rechazado"**. Ou seja, os estados chegam por integração, não por edição manual. O texto da RN-15 diz que a atualização dos estados é responsabilidade da área que gere a solicitação.

Os dois estão certos, e a reconciliação é por linha de negócio:

| Linha | Quem muda o estado | Por quê |
|---|---|---|
| **Repuestos** | A integração, vinda do SAP | A RN-38 e a RN-62 dizem que Gestión de Inventarios **não tem usuário Salesforce**. Sem usuário, é fisicamente impossível que eles mudem o estado na tela. Só resta a integração |
| **PA** | O Catman, na tela | A RN-45 diz que Catman, Director e VP **têm usuário Salesforce** |

Isso resolve uma inconsistência interna do próprio texto, e tem consequência direta de construção: em Repuestos o campo `RequestStatus__c` deve ser somente leitura no layout, e em PA editável pelo perfil do Catman.

### Divergência 3: o rejeitado de Repuestos é decidido no SAP

No fluxograma, a decisão **"¿El material aplica crearse?"** acontece depois que a solicitação chega ao SAP, e o "não" volta como Rechazado. Então, em Repuestos, ninguém marca Rechazado no Salesforce. Confirma a divergência 2 e fecha o Escenario 17 para essa linha.

### O que o fluxograma confirma

1. Repuestos **não tem nenhuma aprovação**, exatamente como a RN-36 e o CA-11 dizem. O desenho de aprovação da seção 4.7 vale **só para PA**.
2. A notificação ao vendedor aparece nos dois desfechos, criação e rejeição, o que sustenta o CA-14.
3. O caminho automático também notifica o solicitante, detalhe que o texto não explicita.

### Achado de integração: apareceu um nome de função novo

A nota embutida no fluxograma descreve o comportamento do sistema atual: quando o material não está no catálogo de materiais do SAP ERP mas está numa **tabela Z com os códigos de todos os fabricantes**, chama-se **`ZHYB_DBM_PRECIO_VTA_NO_MAESTRO`**, que *"creará el material, en caso de estar en el maestro de materiales, y le asignará un precio estimado"*.

Isso é o que responde a pergunta **"¿Está disponible para crearse automáticamente?"** do fluxograma, ou seja é o serviço do caminho automático da RN-21. E **não é o mesmo** que o nosso código chama hoje: `SapMuleClient.creacionMateriales` aponta para `ZQEV_DBM_CREACION_MATERIALES`. Ficam três serviços em jogo, e é preciso o time de SAP dizer qual atende cada perna:

| Perna | Serviço candidato |
|---|---|
| Consulta de existência e disponibilidade | `ZHYB_C4C_CONSULTA_MATERIALES` |
| Criação automática a partir da tabela Z de fabricantes, com preço estimado | `ZHYB_DBM_PRECIO_VTA_NO_MAESTRO` |
| Criação e extensão de material | `ZQEV_DBM_CREACION_MATERIALES` |

Detalhe que vale registrar: a nota descreve a tela do sistema legado, com o botão "Consultar Existencias" e o diálogo *"No se encontraron materiales con el criterio de búsqueda. ¿Desea realizar la búsqueda en maestro de materiales de SAP?"*. Ou seja, a RN-18 (perguntar ao assessor se deseja gerar o código) é a réplica de um comportamento que o usuário **já conhece hoje**. Vale manter o mesmo texto e a mesma cadência no modal, porque reduz curva de adoção a custo zero.

---

## 3. O que já existe e serve sem mudança

1. `SapMaterialCode__c` em Product2, único e External ID, já implantado em DEV Sales e INT. É a chave que impede o Product2 duplicado (RN-43) por construção do banco, não por checagem em Apex.
2. `MaterialSearchService.search()`, a busca SOSL que filtra `IsActive = true`. Isso já entrega a RN-07 e o CA-04 de graça: uma solicitação inativa nunca aparece na busca do fluxo, logo não pode entrar na cotização.
3. `SapMuleClient`, a fachada com mock. É onde entra a chamada síncrona da RN-19.
4. LWC `lineasRepuestos` com o banner de busca sem resultado e o botão "Solicitar creación de material". É o gatilho da RN-18.
5. Barreira nativa adicional: toda `QuoteLineItem` exige `PricebookEntry`, e o Salesforce não sustenta PricebookEntry ativa para produto inativo. Reforça o CA-04 em nível de plataforma.

---

## 4. O que falta construir

### 4.1 Record Types em Product2

Três Record Types, não dois. A HU nomeia dois de solicitação (RN-06), mas o material definitivo precisa do seu próprio, senão as List Views da RN-62 não filtram e o layout de solicitação vaza para o catálogo inteiro.

| Record Type | Uso |
|---|---|
| `Solicitud_Repuesto_Original` | Solicitação com código de parte (RN-30) |
| `Solicitud_Codigo_Comodin` | Solicitação com código próprio local (RN-31) |
| `Material` | Material definitivo, o catálogo replicado do SAP |

**A sutileza que costuma escapar:** a RN-09 diz que o mesmo registro vira o material definitivo. Então o retorno do MATNR precisa trocar o `RecordTypeId` de solicitação para `Material`, na mesma transação em que grava o código e ativa. Se isso não for feito, o material definitivo continua aparecendo nas List Views de solicitações pendentes para sempre.

Layouts por Record Type cobrem o CA-07, com obrigatoriedade diferente em cada um.

### 4.2 Campos em Product2

A HU diz "sem objetos custom", o que não significa sem campos custom. Sem eles a HU não fecha.

| Campo | Tipo | Regra que atende |
|---|---|---|
| `RequestStatus__c` | Picklist: Pendiente, En revisión, Material Creado, Rechazado | RN-10 a RN-15 |
| `RequestKey__c` | Text 80, **único**, External ID | RN-33, RN-35 e o retorno do SAP. Ver 4.3 e 4.5 |
| `RequestedMaterialCode__c` | Text | Código de parte no Original, código local no Comodín (RN-30, RN-31) |
| `RequestBrand__c` | Lookup a `BusinessBrand` | RN-30. `BusinessBrand` está disponível na org, verificado 13/08 |
| `RequestCompany__c` | Lookup a `InternalOrganizationUnit` | Sociedade (RN-28) |
| `RequestPlant__c` | Lookup a `Location` | Centro (RN-28). `Location` disponível |
| `RequestBranch__c` | Lookup a `Location` | Sucursal solicitante (RN-28) |
| `RequestedBy__c` | Lookup a User, default `$User.Id` | RN-55, CA-14. Não usar CreatedById, porque quando a integração cria o registro o CreatedBy é o usuário de integração |
| `RequestFob__c`, `RequestOrigin__c`, `RequestVehicleModel__c`, `RequestVin__c`, `RequestNotes__c` | Currency, Text, Text, Text, Long Text | Dados desejáveis da RN-30 |
| `RejectionReason__c` | Long Text | RN-14, Escenario 17 |
| `SapLastError__c`, `SapRetryCount__c`, `SapLastAttempt__c` | Long Text, Number, DateTime | RN-51, RN-53, CA-16 |
| `TurnoverClass__c` | Picklist ou Text | "Rotación" do retorno da RN-49 |
| `SupersededByProduct__c` | Lookup ao próprio Product2 | "Cadena de Sucesión" da RN-49. Autorrelacionamento é o modelo natural de peça substituída |

### 4.3 Duplicados: o Flow dá a mensagem, o banco dá a garantia

A RN-34 manda usar Flow e proíbe Duplicate Rules. Correto, e vai ser feito assim. Mas Flow sozinho tem a mesma corrida que já corrigimos duas vezes neste projeto: dois assessores clicam ao mesmo tempo, os dois Gets voltam vazios, os dois criam. O Flow não serializa nada.

**Desenho:** `RequestKey__c` como campo de texto **único**, preenchido na criação com `código + sociedade + centro`. O banco recusa o segundo insert com `DUPLICATE_VALUE`, independentemente de quantos usuários simultâneos existam. O Flow continua sendo quem consulta antes e mostra a mensagem amigável do CA-08. É o mesmo padrão do `SapMaterialCode__c`, e é o único jeito de a RN-35 ser verdadeira sob concorrência.

**Detalhe que faz a RN-14 funcionar:** campo único no Salesforce ignora valores nulos. Então ao marcar Rechazado, o Flow limpa o `RequestKey__c` e uma nova solicitação sobre a mesma combinação passa a ser admissível, exatamente como a regra pede. Sem gambiarra.

**Follow do registro existente (RN-35, CA-08):** Flow não tem ação nativa de seguir registro. Precisa de uma Invocable Apex inserindo `EntitySubscription` com `ParentId` do registro e `SubscriberId` do assessor. Requer Chatter habilitado. **Limite operacional real:** cada usuário segue no máximo 500 registros, e o teto sobe para 2000 só via caso na Salesforce. Um assessor de Repuestos que siga toda solicitação que abre chega lá. Vale prever limpeza periódica dos follows de solicitações já fechadas.

### 4.4 Tiempo 1: a ordem das operações é obrigatória, não é estilo

A RN-20 manda fazer upsert do catálogo e a RN-21 manda tentar a extensão. Se o código fizer upsert (DML) e depois chamar o SAP (callout), a transação morre com *"You have uncommitted work pending. Please commit or rollback before calling out"*. É regra de plataforma.

**Sequência obrigatória em uma transação:**

1. Callout de consulta ao SAP, Maestro de Materiales e Maestro de Fábrica (RN-19);
2. Se precisar de extensão, callout de extensão (RN-21) — ainda sem nenhum DML antes;
3. Só então todo o DML: upsert do Product2, ou criação da solicitação inativa se os passos anteriores falharam (RN-23).

**Timeout:** o limite de plataforma é 120 segundos por callout, mas isso é uma eternidade no meio de um atendimento. Configurar o timeout do `SapMuleClient` na casa de 10 a 15 segundos e tratar o estouro como falha, caindo na criação da solicitação. A RN-02 diz que a venda não espera, então a espera precisa ter um teto curto e explícito.

**Cache:** o método que dispara essa consulta **não pode** ser `cacheable=true`. Métodos cacheable não podem fazer callout, e serviriam dado velho de disponibilidade. A busca local no catálogo continua cacheable; a perna SAP não.

### 4.5 Como o SAP encontra a nossa solicitação de volta

A RN-41 diz que, quando o código é carregado, o SAP comunica ao Salesforce via MuleSoft. A RN-42 e a RN-43 exigem que esse retorno atualize **o mesmo registro**, para o catálogo não criar um segundo Product2 depois. Para isso existir, o retorno precisa de uma chave.

**Com a perna de saída do fluxograma (recomendado):** Salesforce envia a solicitação ao SAP carregando `RequestKey__c`. O SAP guarda e devolve esse mesmo valor nos três eventos de volta, En Revisión, Rechazado e código carregado. Correlação por identidade, sem ambiguidade.

**Sem a perna de saída:** só resta a chave natural, `código + sociedade + centro`, que é o mesmo `RequestKey__c` montado dos dados que o SAP naturalmente conhece. Funciona, mas depende de o SAP devolver os três dados exatamente como os enviamos, incluindo formatação e zeros à esquerda do código de parte. É frágil por natureza.

Nos dois casos a mecânica de escrita é a mesma e é a parte segura do desenho: o MuleSoft faz `PATCH /services/data/vXX.X/sobjects/Product2/RequestKey__c/{valor}` gravando MATNR em `ProductCode`, o `SapMaterialCode__c`, os dados mestres, `IsActive = true`, `RequestStatus__c = Material Creado` e o `RecordTypeId` de material. Upsert por External ID é atômico e idempotente, então a RN-43 fica garantida pela plataforma e reprocessos não duplicam nada.

**Pergunta para o time de SAP e Mule:** conseguem transportar e devolver um identificador nosso na solicitação? Se sim, fechamos pela via forte. Se não, precisamos confirmar que a notificação de criação carrega o código de parte original e o centro, sem normalização, senão a RN-42 e a RN-43 não fecham.

### 4.6 Estados e ativação

Regra de ouro a implementar: **só a integração de entrada coloca em Material Creado e ativa**. Um humano nunca marca isso à mão, porque a RN-42 diz que o material só se considera criado quando já está no Maestro de Materiales.

Implementação: validation rule impedindo `IsActive = true` quando o Record Type é de solicitação e o `RequestStatus__c` não é Material Creado. Duas linhas de fórmula, fecha o CA-04 e o CA-13 contra erro humano.

### 4.7 Aprovações de PA

A RN-44 e a RN-45 pedem dois níveis em sequência, Director de PA e depois Vicepresidente de PA, com o Catman iniciando após validar e cotizar.

**Verificação de 1 minuto que precisa acontecer antes de desenhar:** entrar em Setup, Approval Processes, e conferir se **Product2 aparece na lista de objetos**. Nem todo objeto padrão suporta processo de aprovação clássico, e não achei confirmação documental para Product2. Se aparecer, é Approval Process nativo em dois passos. Se não aparecer, o caminho é aprovação por Flow Orchestration, que funciona sobre qualquer objeto.

Ponto operacional: durante a aprovação o registro fica travado para edição. Como o Catman precisa completar cotização **antes** de submeter, a submissão tem que ser o último passo dele, não o primeiro.

Licenças: Catman, Director e VP precisam de usuário Salesforce (RN-45). A org tem 2554 licenças Salesforce com 48 em uso, então não há restrição.

### 4.8 Notificações: são dois mecanismos diferentes, não um

O CA-14 pede notificação ao assessor solicitante **e, de forma diferenciada**, aos seguidores. São duas coisas:

1. **Assessor solicitante:** Custom Notification disparada por Flow para o usuário em `RequestedBy__c` quando o status vira Material Creado ou Rechazado. Chega no sino e no push do app.
2. **Seguidores:** Feed Tracking em Product2 sobre o campo `RequestStatus__c`. Quem segue o registro recebe pelo mecanismo padrão do Chatter, sem código, atendendo a RN-56 que pede justamente a funcionalidade padrão de Follow.

Pré-requisitos: Chatter habilitado e Feed Tracking ativado em Product2.

### 4.9 Permissões, e o limite duro do Product2 que precisa ser dito agora

Product2 passou a ter Organization Wide Default a partir do Spring '22, com Private, Public Read Only ou Public Read Write. **Mas regras de compartilhamento e compartilhamento manual não são suportadas em Product2.**

Consequência prática: **não é possível restringir por registro quem vê qual solicitação.** Se o cliente pedir que a sucursal A não enxergue as solicitações da sucursal B, a resposta técnica em Product2 é não. Esse é o único requisito que poderia derrubar a premissa de "sem objeto custom" da RN-05, e é melhor colocar isso na mesa agora do que no meio da sprint.

O que a HU pede de fato é compatível: RN-61 fala em controle por perfil, RN-62 em List Views por Record Type e o CA-17 em acesso de visualização para Jefe, Encargado, Gerente e Gerente de canal. Tudo isso se resolve com OWD Public Read Only, CRUD por perfil, atribuição de Record Type por perfil e FLS. Recomendação: manter OWD Public Read Only e não prometer segregação por registro.

### 4.10 Erros, reintento e escalonamento

A RN-51 pede reintento e a RN-52 pede escalonamento, mas admite que o mecanismo de escalonamento não está definido.

**Reintento:** o mecanismo próprio da plataforma é Platform Event com `EventBus.RetryableException` no trigger. O contador fica em `EventBus.TriggerContext.currentContext().retries`, e a plataforma limita o número de reintentos automáticos, então o código precisa **testar o contador e parar explicitamente**, gravando `SapRetryCount__c`, `SapLastError__c` e `SapLastAttempt__c` no registro. Sem esse teto explícito, o evento é descartado silenciosamente e ninguém fica sabendo.

**Escalonamento:** está bloqueado por definição do cliente, e tem uma restrição que precisa ser dita ao levantar a pergunta: **a RN-56 proíbe abrir Case**, então o escalonamento não pode ser um Case. Sobra alerta por e-mail para um grupo público ou fila, mais uma List View de solicitações travadas. Levar como pergunta fechada, com essas duas opções, em vez de pergunta aberta.

### 4.11 Configuração simples

1. Salesforce Files: basta a related list no layout de solicitação (RN-57).
2. Field History Tracking em Product2 (RN-58). Limite de **20 campos por objeto**, então escolher com critério: status, IsActive, ProductCode, e os campos de sociedade e centro.
3. List Views por Record Type para cada área (RN-62).

---

## 5. Pontos que precisam de definição antes de fechar o desenho

| # | Ponto | Quem responde |
|---|---|---|
| 1 | Vale o fluxograma (Salesforce envia a solicitação ao SAP) ou o texto da V3 (sem perna de saída)? Decide toda a estratégia de correlação | Grupo Q, com nossa recomendação pelo fluxograma |
| 2 | O SAP consegue transportar e devolver um identificador nosso? Se não, a notificação carrega código de parte original e centro sem normalização? | Time SAP e Mule |
| 3 | Qual serviço SAP atende cada perna, entre `ZHYB_C4C_CONSULTA_MATERIALES`, `ZHYB_DBM_PRECIO_VTA_NO_MAESTRO` e `ZQEV_DBM_CREACION_MATERIALES` | Time SAP |
| 4 | RN-24: o traslado a nível de pedido na extensão entre centros da mesma sociedade acontece em qual sistema? A própria HU marca como pendente | Grupo Q |
| 5 | RN-52: mecanismo de escalonamento, sabendo que Case está proibido pela RN-56 | Grupo Q |
| 6 | De onde o fluxo guiado tira sociedade, centro e sucursal do assessor: do usuário, da conta ou da cotização | Nós, definição interna |
| 7 | Product2 suporta Approval Process nesta org? Verificação em Setup | Nós, 1 minuto |
| 8 | Alguém vai pedir visibilidade por sucursal? Se sim, Product2 não entrega | Antecipar com o cliente |

---

## 6. Ordem de construção sugerida

1. Corrigir os dois conflitos da seção 2, porque o que está no ar hoje contraria a V3.
2. Metadados: 3 Record Types, campos da 4.2, validation rule da 4.6, Field History e Feed Tracking. Sem código.
3. Flow de duplicados com `RequestKey__c` único, mais a Invocable de Follow.
4. Ajuste do `MaterialCreationService` para a sequência callout antes de DML da 4.4, e criação da solicitação prellenada no lugar do Case.
5. `RequestStatus__c` somente leitura no layout de Repuestos e editável no de PA, conforme a divergência 2 da seção 2bis.
6. Contrato de integração com o Mule, saída e entrada, dependente dos pontos 1 a 3 da seção 5.
7. Notificações, Custom Notification mais Feed Tracking.
8. Aprovações, **só para PA**, depois da verificação do ponto 7 da seção 5.
9. List Views e perfis.

Os passos 1 a 5 não dependem de nenhuma resposta externa e podem começar hoje.

---

## 7. O que o Automotive Cloud já tem de nativo para esta HU

Revisão objeto a objeto do catálogo padrão do Automotive Cloud contra os requisitos da HU-039. Três achados mudam decisões, um confirma a premissa da HU e dois são descartados com motivo.

### 7.1 Confirma a premissa: `ProductRequest` **não** serve, e Product2 com Record Types está certo

O primeiro reflexo de quem lê "solicitação de material" é procurar um objeto de solicitação. Ele existe: `ProductRequest` e `ProductRequestLineItem`, documentados como *"an order for a part or parts"*. Mas a semântica é outra. `ProductRequest` pede **peças que já existem** para serem transferidas ou pedidas, e suas linhas apontam para um `Product2` existente.

Na HU-039 o produto **ainda não existe**, é justamente isso que se está pedindo criar. Usar `ProductRequest` exigiria criar antes o Product2 que a solicitação pretende criar, o que é circular.

**Conclusão: a RN-05 está tecnicamente correta.** Product2 com Record Types é o modelo certo, e agora com fundamento e não por ausência de alternativa.

### 7.2 Muda o desenho: `ProductItem` é o lugar nativo do "creado para el centro"

A RN-29 diz que *"un material puede existir para una sociedad y no para otra; la disponibilidad se evalúa por sociedad/centro y no de forma global"*. Isso é o coração funcional da HU, e hoje não tem nenhum modelo no Salesforce: Product2 é global por natureza, não tem noção de centro.

O Automotive Cloud documenta `ProductItem` entre seus objetos de inventário, e ele é exatamente *"o estoque de um produto determinado numa localização determinada"*. Ou seja, a existência de um material **por Location** é um registro nativo, não um campo inventado.

**Decisão recomendada, e ela é conservadora:** não replicar saldo. A HU-043 já decidiu que o saldo vem do SAP ao vivo (RN4) e isso não muda. O que `ProductItem` resolve é diferente de saldo: é o fato persistido de que **o material está criado para aquele centro**, que é o que a RN-21 e a RN-24 consultam. Duas opções:

1. **Não persistir nada** e perguntar ao SAP toda vez. É o que o desenho atual faz. Simples, mas cada busca do assessor vira um callout, e a RN-19 já é síncrona no meio do atendimento.
2. **Persistir a extensão por centro** em `ProductItem` quando o SAP confirma. A segunda consulta pelo mesmo material e centro não sai da org. Sem objeto custom.

Recomendo a opção 2 se o volume de consultas for alto, que é o caso de um balcão de repuestos. Mas é decisão a tomar com número na mão, não por gosto.

### 7.3 Responde uma pergunta que a HU deixou aberta: `ProductTransfer`

A RN-24 diz que, na extensão entre centros da mesma sociedade, *"se genera un traslado a nivel de pedido. El sistema en el que se ejecuta y registra ese traslado requiere validación"*. Ou seja, a própria HU não sabe onde isso acontece.

O Salesforce tem objeto padrão para isso: `ProductTransfer`, *"the transfer of inventory between locations"*, documentado pelo Automotive Cloud entre seus objetos de inventário. Então a resposta técnica para a pergunta em aberto é: **se o traslado precisar ficar registrado no Salesforce, existe objeto nativo e não precisa de nada custom.** Se ficar só no SAP, também está resolvido, mas aí o Salesforce não mostra o traslado em lugar nenhum e isso precisa ser dito ao negócio.

Isso transforma uma pergunta aberta em uma escolha binária com as duas pontas já respondidas.

### 7.4 A verificar, pode simplificar muito: `SellerProduct`

`SellerProduct` (API 65) é *"information about the products associated with a seller. Provides insight into product availability, production details, and the seller's role for the product, such as for sales or for service"*.

Lido junto com a RN-29, é o modelo mais próximo que existe de "este material está habilitado para esta sociedade, neste papel". Se estiver disponível na org, vale avaliar como alternativa ou complemento ao `ProductItem` do item 7.2, porque fala de **habilitação comercial** e não de estoque.

Ressalva honesta: é API 65, recente, e a documentação de campo é escassa fora da referência oficial. Entra como verificação, não como decisão. O script `gapcheck7` testa.

### 7.5 Candidato natural para dois pontos soltos: `Codeset` e `CodesetRelationship`

`Codeset` é *"various industry defined codes in the context of their systems and versions of those systems"* e `CodesetRelationship` é *"a relationship between a codeset and its related codeset"*.

Dois encaixes:

1. A nota do fluxograma fala de uma **tabela Z com os códigos de todos os fabricantes**, consultada quando o material não está no catálogo. Isso é literalmente um conjunto de códigos de sistemas externos com versão, que é a definição de `Codeset`. Se um dia essa tabela precisar existir no Salesforce, já tem objeto.
2. A **Cadena de Sucesión** da RN-49 é uma relação entre códigos, que é a definição de `CodesetRelationship`.

Ressalva: para a cadeia de sucessão, um autorrelacionamento simples em Product2 (`SupersededByProduct__c`, seção 4.2) resolve com muito menos peça. `CodesetRelationship` só compensa se a cadeia tiver versões, sistemas de origem distintos e histórico. Fica registrado como caminho, não como recomendação imediata.

### 7.6 Existe mas não compensa aqui: Actionable Event Orchestration

O framework de `ActionableEventType`, `ActionableEventSubtype`, `ActionableEventOrchestration` e `ActionableOrchSourceEvent` é o mecanismo nativo do Automotive para **processar eventos externos e decidir o que fazer com eles**. À primeira vista é o candidato óbvio para receber as notificações do SAP da RN-41.

Na prática não compensa nesta HU. O framework foi desenhado para eventos de ativo conectado e telemetria, e cobra uma camada de configuração inteira: tipo de evento, subtipo, context definition com a estrutura do payload, e expression set com as regras de roteamento. O que a HU-039 precisa do lado de entrada é **uma escrita idempotente num registro conhecido**, que o MuleSoft faz com um `PATCH` por External ID em uma chamada.

**Veredito: usar o `PATCH` direto por `RequestKey__c`.** Guardar o Actionable Event Orchestration para quando as notificações do SAP virarem uma família com roteamento condicional, aí ele passa a valer o custo.

### 7.7 Resumo das decisões

| Objeto nativo | Veredito | Efeito na HU |
|---|---|---|
| `ProductRequest` / `ProductRequestLineItem` | **Descartado**, semântica errada | Confirma a RN-05: Product2 com Record Types |
| `ProductItem` | **Avaliar com volume**, opção 2 recomendada | Persiste "creado para el centro" sem objeto custom (RN-29) |
| `ProductTransfer` | **Responde a RN-24** | Vira escolha binária, não pergunta aberta |
| `SellerProduct` | **Verificar disponibilidade** | Pode substituir ou complementar o `ProductItem` |
| `Codeset` / `CodesetRelationship` | **Registrado, não adotado agora** | Tabela Z de fabricantes e cadeia de sucessão |
| Actionable Event Orchestration | **Descartado por custo**, não por capacidade | Entrada do SAP fica no `PATCH` por External ID |

Verificação de disponibilidade dos seis: `docs/scripts/gapcheck7-hu039-inventario.apex`.

---

## 8. Fontes

1. Regra de callout após DML, "You have uncommitted work pending", Apex Developer Guide.
2. `cacheable=true` não permite callout e serve dado de cache, Lightning Web Components Developer Guide.
3. Campos únicos ignoram valores nulos, e upsert por External ID é atômico, Object Reference e REST API Developer Guide.
4. `EventBus.RetryableException` e `EventBus.TriggerContext.currentContext().retries`, Platform Events Developer Guide, "Retry Event Triggers".
5. `EntitySubscription` como registro de Follow, com limite de 500 registros seguidos por usuário, elevável a 2000 por caso na Salesforce.
6. Organization Wide Default para Products a partir do Spring '22, com regras de compartilhamento e compartilhamento manual **não suportadas** em Product2, Salesforce Help.
7. Limite de 20 campos por objeto em Field History Tracking, Salesforce Help.
