# venta_guiada_pedido.zip — pipeline cotización → pedido → SAP → faturamento → entrega

Base: retrieve REAL da suíte (07/08, zip `retrieve_09SWK00000Rhvul2AB`). As 2 classes existentes (QuoteOrderService, GuidedSellingController) são as versões da org + a evolução — nada do que funciona hoje foi alterado.

## O que o pacote contém
| Componente | O quê |
|---|---|
| `QuoteOrderService` | `createOrderFromQuote` IMPLEMENTADO (era stub `return null`): Order nativo Draft + OrderItems das QuoteLineItems, `SapStatus__c=Borrador`, idempotente (1 pedido por cotización, nunca duplica). Novo `sendOrderToSap` (enfileira o Queueable). |
| `SapOrderService` | Queueable IMPLEMENTADO (era 100% TODO): payload (moeda, código composto do dealer via Account.AccountNumber, linhas) → POST `callout:MuleGateway/api/v1/orders` → `Enviado a SAP` (ou `Confirmado SAP` se o ack já traz número) / `Error SAP` → publica `SapOrderResponse__e`. |
| `GenerateSapOrderAction` | Invocable "Generar pedido SAP desde cotización" — para Screen Flow/Quick Action na Quote SEM mexer no LWC. |
| `GuidedSellingController` | + `createOrderFromQuote` @AuraEnabled (fiação futura do `cotizacionConfirmModal`). |
| Order: `SapStatus__c` (picklist: Borrador/Enviado a SAP/Confirmado SAP/Facturado/Error SAP, history), `SapOrderNumber__c` (External ID — chave do update inbound do Mule), `SapInvoiceNumber__c`, `SapInvoiceDate__c` | Ciclo SAP fora do Status nativo (Draft/Activated fica intocado). |
| Flow `SAP_Order_Response_Handler` (Draft) | Platform event → escreve estado/número no pedido (do ack Apex e da confirmação IDoc publicada pelo Mule). |
| Flow `Order_Facturado_Handler` (Draft) | Order vira `Facturado` → notificação ao dueño (tipo `SapOrderAlert`, cai em só-tarefa se não existir) + Task `[Entrega] Pedido facturado — {OrderNumber}`. Assetização pluga aqui depois. |

## Deploy (Workbench > Migration > Deploy)
1. `venta_guiada_pedido.zip`, marcar **Single Package** + **Rollback On Error**.
2. Setup > Custom Notifications > New: `SapOrderAlert` (Desktop+Mobile) — igual ao DemoDesignationAlert do HU-046.
3. Ativar os 2 flows (deploy nunca ativa, regra da org).
4. FLS: dar visibilidade aos 4 campos novos da Order para os perfis de vendas + usuário de integração (o Mule escreve `SapStatus__c/SapInvoiceNumber__c/SapInvoiceDate__c` no update inbound).

## Teste rápido (sem Mule configurado)
1. Numa Quote da venta guiada (com linhas), rodar anônimo: `GenerateSapOrderAction.generate(...)` ou montar a Quick Action com Screen Flow chamando a ação "Generar pedido SAP desde cotización".
2. Esperado: Order criado (Draft/`Borrador`) com as linhas da cotización → Queueable roda → callout falha (endpoint Mule não configurado) → `SapStatus__c='Error SAP'` + evento com a mensagem. Isso PROVA o pipeline; com o Named Credential apontado pro Mule, o mesmo caminho vira `Enviado a SAP`.
3. Simular faturamento: editar o pedido (como admin) `SapStatus__c='Facturado'` + nº de fatura → notificação + task `[Entrega]` devem nascer.

## O que fica com o Mule/SAP (tarefa técnica, fora da HU)
- Endpoint `POST /api/v1/orders` atrás do MuleGateway roteando por família (veículos: ASIG_CLIENTE+MONEDA → ZQEV_SSA_CREA_ORD_VEH Z301; PA: IDoc SALESORDER_CREATEFROMDAT2; repuestos: DBM). Contrato = `SapOrderService.OrderPayload`.
- Confirmação assíncrona: Mule publica `SapOrderResponse__e` (OrderId__c + SapOrderNumber__c + Status__c='Confirmado SAP').
- Faturamento: Mule faz UPDATE no Order (`SapStatus__c='Facturado'`, `SapInvoiceNumber__c`, `SapInvoiceDate__c`) — **pergunta aberta ao Luis/SAP: qual evento o SAP emite ao faturar (IDoc INVOIC?) e com quais chaves**.

## Gates HU-025 (não mudam)
Cotización Confirmada = documento só SF; **Reserva Confirmada = momento de gerar o pedido** (Z301 nos veículos). O gatilho do `GenerateSapOrderAction` deve ser plugado nesse gate — quem chama (Quick Action manual ou flow no estágio) é decisão funcional tua.
