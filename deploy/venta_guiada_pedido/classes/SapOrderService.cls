/**
 * All countries. Sends the order to SAP asynchronously (the seller never waits):
 * Queueable with callout through the MuleSoft Named Credential. On the
 * synchronous acknowledge it moves SapStatus__c Borrador -> Enviado a SAP
 * (or straight to Confirmado SAP when Mule already answers the SAP number)
 * and publishes the SapOrderResponse__e platform event so the open UI
 * (empApi, scoped subscription) can react. The asynchronous SAP confirmation
 * (IDoc) comes back as a SapOrderResponse__e published by MuleSoft — flow
 * SAP_Order_Response_Handler writes it on the order. Invoicing returns later
 * by inbound update from MuleSoft (record update + custom notification,
 * never empApi) — flow Order_Facturado_Handler owns that leg.
 */
public with sharing class SapOrderService implements Queueable, Database.AllowsCallouts {

    // Named Credential configured per environment; single orders endpoint —
    // Mule routes by family behind the gateway (vehiculos: ZQEV_ASIG_CLIENTE +
    // ZQEV_MONEDA_CLIENTE -> ZQEV_SSA_CREA_ORD_VEH Z301; PA: IDoc
    // SALESORDER_CREATEFROMDAT2; repuestos: DBM). Contract with Flavio.
    private static final String ORDERS_ENDPOINT = 'callout:MuleGateway/api/v1/orders';
    private static final Integer TIMEOUT_MILLIS = 60000;

    private final Id orderId;

    public SapOrderService(Id orderId) {
        this.orderId = orderId;
    }

    public void execute(QueueableContext context) {
        List<Order> orders = [
            SELECT Id, OrderNumber, CurrencyIsoCode, OpportunityId, QuoteId,
                   SapStatus__c, Account.AccountNumber,
                   (SELECT Id, Quantity, UnitPrice, Product2Id, Product2.ProductCode FROM OrderItems)
            FROM Order
            WHERE Id = :orderId
            WITH USER_MODE
        ];
        if (orders.isEmpty()) {
            return;
        }
        Order pedido = orders[0];

        OrderPayload payload = new OrderPayload();
        payload.orderId = pedido.Id;
        payload.orderNumber = pedido.OrderNumber;
        payload.currencyIsoCode = pedido.CurrencyIsoCode;
        // codigo de sucursal SAP = composto Centro+Almacen (WERKS+LGORT)
        // cargado en el AccountNumber del dealer (convencion org); la
        // interfaz de reserva de vehiculos pide CENTRO — Mule toma los 4
        // primeros caracteres (grabacion Luis 04/06)
        payload.branchCode = pedido.Account == null ? null : pedido.Account.AccountNumber;
        payload.lines = new List<OrderLinePayload>();
        for (OrderItem item : pedido.OrderItems) {
            OrderLinePayload line = new OrderLinePayload();
            line.productCode = item.Product2.ProductCode;
            line.quantity = item.Quantity;
            line.unitPrice = item.UnitPrice;
            payload.lines.add(line);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ORDERS_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TIMEOUT_MILLIS);
        req.setBody(JSON.serialize(payload));

        String nuevoEstado;
        String numeroSap;
        String error;
        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                // ack sincrono del gateway; el numero SAP puede venir ya
                // (respuesta sincrona) o despues via IDoc -> evento de Mule
                numeroSap = parseSapNumber(res.getBody());
                nuevoEstado = String.isBlank(numeroSap) ? 'Enviado a SAP' : 'Confirmado SAP';
            } else {
                nuevoEstado = 'Error SAP';
                error = 'HTTP ' + res.getStatusCode() + ' del gateway MuleSoft.';
            }
        } catch (Exception e) {
            nuevoEstado = 'Error SAP';
            error = e.getMessage();
        }

        Order actualizacion = new Order(Id = pedido.Id, SapStatus__c = nuevoEstado);
        if (String.isNotBlank(numeroSap)) {
            actualizacion.SapOrderNumber__c = numeroSap;
        }
        update actualizacion;

        // evento para la UI abierta (empApi filtrado por OrderId__c); el
        // retorno de factura NO usa este evento (llega por actualizacion
        // inbound del pedido)
        EventBus.publish(new SapOrderResponse__e(
            OrderId__c = pedido.Id,
            Status__c = nuevoEstado,
            SapOrderNumber__c = numeroSap,
            ErrorMessage__c = error == null ? null : error.abbreviate(255)
        ));
    }

    /** Numero de pedido SAP en el ack sincrono, cuando el gateway lo devuelve. */
    private static String parseSapNumber(String body) {
        if (String.isBlank(body)) {
            return null;
        }
        try {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
            Object numero = parsed.get('sapOrderNumber');
            return numero == null ? null : String.valueOf(numero);
        } catch (Exception e) {
            return null;
        }
    }

    /** Request payload: contract with the MuleSoft orders endpoint. */
    public class OrderPayload {
        public Id orderId;
        public String orderNumber;
        public String currencyIsoCode;
        public String branchCode;
        public List<OrderLinePayload> lines;
    }

    public class OrderLinePayload {
        public String productCode;
        public Decimal quantity;
        public Decimal unitPrice;
    }
}
