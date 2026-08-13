# HU-039 — O que construir no Salesforce, peça por peça

Lista de construção. Cada item diz o que é, o que faz, onde vive e o detalhe de implementação que costuma dar errado se ninguém avisar.

Legenda de estado: **PRONTO** já está empacotado, **CONSTRUIR** falta fazer, **AJUSTAR** existe e precisa mudar.

---

## 1. Metadados, sem código

### 1.1 Record Types em Product2 — PRONTO

Três: `Material`, `MaterialRequestOriginalPart`, `MaterialRequestWildcardCode`. Estão em `deploy-hu039-solicitud-material.zip`.

**Detalhe:** Product2 não tinha nenhum Record Type, então depois do deploy é obrigatório rodar `post-deploy-hu039-asignar-recordtype.apex` para colocar os 281 produtos existentes no Record Type Material. Sem isso o catálogo some das List Views.

### 1.2 Campos em Product2 — PRONTO

19 campos no mesmo pacote, mais o `RequestBrand__c` no pacote 2.

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

**Ordem importa:** habilitar Field History Tracking em Product2 no Setup **antes** de deployar o pacote 1, porque cinco campos vêm com histórico ligado e o deploy recusa se o objeto não tiver o rastreamento ativo.

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

---

## 6. Ordem de construção

**Bloco A, não depende de ninguém, começa hoje.**

1. Habilitar Field History em Product2 no Setup;
2. Deploy do pacote 1, depois o script de reatribuição, depois atribuir Record Types aos perfis;
3. Deploy do pacote 2;
4. Page Layouts, List Views e Feed Tracking;
5. Permission Sets;
6. `MaterialRequestService` e o Flow de duplicados;
7. Ajuste do `MaterialCreationService`, tirar o Case e inverter a ordem para callout antes de DML.

**Bloco B, depende de uma definição pequena.**

8. Modal `solicitudMaterial` e ajuste do `lineasRepuestos`. Pode ser construído já, deixando canal e serie como campos do formulário, e depois automatizado quando vier a definição;
9. Custom Notification e o Flow de notificação;
10. `FollowRecordAction`.

**Bloco C, depende de definição externa.**

11. Aprovação de PA, depois da verificação em Setup;
12. Flow de travadas, depois do destinatário e do prazo;
13. Automatizar canal e serie, depois da definição;
14. Campos adicionais de dado mestre, depois da lista da RN-49.

O Bloco A é a maior parte do esforço e não espera ninguém.
