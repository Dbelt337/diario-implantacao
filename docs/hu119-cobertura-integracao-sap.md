# HU-119, cobertura técnica

Integração SAP e MuleSoft, sincronização automática ante mudanças. Pesquisa de
18/08 na documentação oficial e nas últimas releases, com native first.

Esta HU é um **padrão**, não uma funcionalidade. Ela mesma diz que não define
regra de negócio, define como a informação viaja. Duas consequências práticas:

1. **A maior parte dela não é Salesforce.** Fila, reintento, correlação,
   monitoramento e contrato de serviço vivem na camada de integração;
2. **Boa parte do lado Salesforce já existe**, construída no Cotizador.

---

## 1. Onde cada regra mora, e essa é a conversa mais importante

| Regra | Dono |
|---|---|
| RN-01 sistema maestro por domínio | Arquitetura, decisão conjunta |
| RN-02 quais campos disparam | **GrupoQ**, parâmetro de negócio. Sem ele a HU não é implementável, e a própria HU diz isso |
| RN-03 eventos de negócio nas HUs donas | As HUs de reserva, pedido e faturação |
| RN-04 modo por tipo de dado | Arquitetura |
| RN-05 frequência dos programados | **MuleSoft**, o scheduler é dele. E o valor é do GrupoQ, hoje com três respostas diferentes |
| RN-06 atualização a demanda | **Salesforce** |
| RN-07 estado visível no registro | **Salesforce** |
| RN-08 erro técnico contra funcional | **MuleSoft** classifica, Salesforce exibe |
| RN-09 escalonamento e reprocesso | **MuleSoft** guarda a fila, Salesforce dispara o reprocesso |
| RN-10 continuidade da operação | Salesforce, e é desenho de tela |
| RN-11 idempotência | **MuleSoft e SAP**. Salesforce só carrega o correlation id |
| RN-12 concorrência e ordem | **MuleSoft**, a fila é dele |
| RN-13 matriz de etapas que permitem alterar | **GrupoQ**, definição pendente |
| RN-14 perda de disponibilidade | HU de disponibilidade |
| RN-15 traçabilidade por transação | **Decisão pendente**: Salesforce, MuleSoft ou os dois |
| RN-16 monitor e alerta | **MuleSoft** monitora a interface, Salesforce notifica o dono do documento |
| RN-17 multi país e multi sociedade | **MuleSoft**, uma interface por país |
| RN-18 modelo de visibilidade | Salesforce, e depende da HU-017 |
| RN-19 contrato único por serviço | **MuleSoft com o foco SAP do GrupoQ** |
| RN-20 sem replicar maestros | Arquitetura |

Contando: das vinte regras, **seis são construção Salesforce**, seis são
MuleSoft, três são definição pendente do GrupoQ e o resto é arquitetura ou vive
em outra HU. Isso precisa estar escrito antes da estimativa, senão a HU chega
inteira para o lado errado.

---

## 2. O que já está construído

Do pacote do Cotizador, já em DEV:

| Componente | Cobre |
|---|---|
| `SapOrderResponse__e`, Platform Event | O canal de entrada SAP para Salesforce |
| `SAP_Order_Response_Handler`, Flow | O consumidor do evento, já declarativo |
| `Order_Facturado_Handler`, Flow | Escenario 18, faturado dispara entrega e milestone |
| `Order.SapStatus__c`, `SapOrderNumber__c`, `SapInvoiceNumber__c`, `SapInvoiceDate__c` | Parte da RN-07 |
| `QuoteLineItem.AvailabilityStatus__c` e `AvailabilityDetail__c` | O padrão de persistir o que o SAP devolve |
| `MuleGateway` e `MuleSoft_EC` | Named Credential e External Credential |
| `PS_Mule_Integration` | Permissão de integração |
| `SapOrderAlert`, Custom Notification Type | O canal de notificação da RN-16 |
| `Generar_Pedido_SAP` e `Quote_Aceptada_Genera_Pedido`, Flows | A ida do pedido, automática e por botão |

Ou seja, o padrão de ida e volta do pedido já roda. **A HU-119 é generalizar
isso para os outros domínios**, não inventar. Vale dizer isso em voz alta,
porque muda a estimativa e muda quem tem que fazer o quê.

---

## 3. O lado Salesforce, sem Apex novo

### Detecção de mudança, RN-02 e Escenario 1

**Change Data Capture.** Nativo, publica evento de alteração por objeto, e o
MuleSoft assina. Zero código do lado Salesforce, e o filtro de campos relevantes
fica no Mule, que é onde a lista da RN-02 tem que ser parametrizável de qualquer
jeito.

Se o negócio preferir controlar a decisão dentro do Salesforce, a alternativa é
um Platform Event próprio publicado por **record triggered Flow**, também sem
Apex, com a lista de campos relevantes num Custom Metadata Type. Mais controle,
mais manutenção.

O consumo do lado do Mule deve usar **Pub/Sub API**, que é gRPC e é onde a
Salesforce investe. O CometD continua suportado para integração existente, mas
não é onde o produto está indo. Vale fixar isso no contrato com o time de Mule.

### Chamada de saída sem Apex, RN-06 e a consulta em linha

**HTTP Callout em Flow** e **External Services**. O Flow Builder gera a ação
invocável a partir da descrição do endpoint, com Named Credential fazendo a
autenticação. Já temos o `MuleGateway`.

Duas restrições que decidem o desenho:

- **External Services só funciona com REST descrito em OpenAPI 2.0 ou 3.0.** Se
  o Mule expuser SOAP ou não publicar spec, cai em Apex. Isso vira **requisito
  de contrato da RN-19**, e é negociável porque o time de Mule é da casa;
- **Record triggered Flow não faz callout no caminho síncrono.** A plataforma
  bloqueia callout enquanto o registro salva. Tem que ser o **caminho
  assíncrono**, disponível só em flow after save. Isso não é contorno, é
  exatamente a RN-04, que pede transação assíncrona sem travar o usuário.

Limites a respeitar: o callout roda dentro dos governor limits, com teto de 120
segundos e número limitado de callouts por transação. Serve para o refresco a
demanda e para a consulta de preço em linha. **Não** serve para propagação em
volume, que é assíncrona por evento.

### Estado da integração no registro, RN-07

Picklist com os sete estados que a HU lista, mais o estado geral do documento no
SAP, a etapa operativa e a data e hora da última sincronização com sucesso. Já
existe parte disso em `Order`. Exibição em **Dynamic Forms** e Highlights Panel,
sem componente próprio. Campo é picklist e não texto, para ser filtrável e
reportável como a RN-07 exige.

### Refresco a demanda, RN-06

**Quick Action** chamando Flow, no documento comercial e na unidade de
inventário. Sem LWC. Cada execução grava na traça com usuário, data, hora e
resultado.

### Reprocesso manual, RN-09 e Escenario 7

Quick Action visível só com um Custom Permission, chamando o Flow que pede ao
Mule o reenvio **com o correlation id original**. O Salesforce não remonta o
payload, só pede reenvio. Assim a idempotência continua sendo do Mule e do SAP,
que é onde ela pode ser garantida.

### Traçabilidade, RN-15

A decisão de onde persistir está pendente na HU. As três opções, honestamente:

- **Nebula Logger**, já instalado e com ação invocável de Flow. Zero
  construção, e é a resposta certa se o volume for moderado;
- **Big Object**, se a traça tiver que guardar milhões de transações por muito
  tempo. Barato em armazenamento, limitado em consulta;
- **só no MuleSoft**, com o Salesforce guardando apenas o correlation id e o
  último resultado no registro.

A terceira é a mais limpa e a mais defensável: **a traça técnica pertence à
camada de integração**. O Salesforce guarda o que o usuário precisa ver.
Duplicar a traça nos dois lados é o caminho para elas divergirem.

### Visibilidade, RN-18 e Escenario 21

Registro criado pela integração herda o compartilhamento normal. O que fecha
isso é o desenho da HU-017: OWD privada mais as sharing rules por sociedade. O
usuário de integração precisa de acesso, e é aí que mora o risco real de elusão,
não na interface.

E atenção ao acoplamento: se o usuário de integração for dono das contas
criadas, ele precisa ter papel, senão a opção de incluir registros de dono sem
papel na sharing rule passa a ser obrigatória, e essa opção não pode ser editada
depois de salva.

---

## 4. O que não se constrói no Salesforce, e vale recusar por escrito

- **Fila e ordem cronológica**, RN-12. Platform Event não garante ordenação
  entre publicações diferentes. Quem ordena é o Mule;
- **Política de reintento**, RN-08 e RN-09. Número, intervalo e estratégia de
  espera são do Mule, e a própria HU diz que ainda são definição pendente;
- **Idempotência**, RN-11. Só o SAP pode garantir que não cria documento
  duplicado. O Salesforce carrega o identificador, não a garantia;
- **Monitor de integrações**, RN-16. Anypoint Monitoring existe para isso.
  Construir monitor em Salesforce é reconstruir o que já se paga;
- **Carga massiva de maestros**, RN-20. A própria regra proíbe.

---

## 5. Os cinco bloqueios reais

1. **A lista de campos relevantes por objeto e linha de negócio**, RN-02. A HU
   declara que sem ela não é implementável, e está certa;
2. **A frequência por interface**, RN-05, hoje com três valores diferentes na
   mesma fonte, dez minutos, dez a quinze por sociedade, e quinze;
3. **A matriz de etapas do documento que permitem alterar**, RN-13;
4. **A política de reintento**, RN-08, declarada pendente;
5. **Onde persiste a traça e por quanto tempo**, RN-15, declarada pendente.

Nenhum é técnico. Os cinco são decisão, e três são do GrupoQ.

---

## 6. Uma brecha que a própria HU aponta e ninguém vai lembrar

A RN-16 diz textualmente que o Technical Annex documenta normalização,
autenticação, tratamento de erro, cache, log e monitoramento centralizado
**apenas para a camada de serviços compartilhados de fábricas**, e que **não
existe definição equivalente para as interfaces com SAP**.

Isso significa que a fundação técnica que esta HU pressupõe não está estimada em
lugar nenhum. É a brecha mais cara do documento e está escrita nele.

---

## Fontes

- Pub/Sub API, guia oficial, e a recomendação de usá la em integração nova
- Configure an HTTP Callout Action, Salesforce Help
- Connecting to an API Without a Connector Using HTTP Callout, Salesforce Help
- Record-Triggered Flow Considerations, e o bloqueio de callout no caminho
  síncrono
- Connect a Record-Triggered Flow to an External System Using an Asynchronous
  Path, release notes
- Using Salesforce External Services in Flow, incluindo a exigência de OpenAPI
  2.0 ou 3.0
