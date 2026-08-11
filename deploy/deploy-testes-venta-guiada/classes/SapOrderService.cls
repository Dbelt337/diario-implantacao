/**
 * All countries. Sends the order to SAP asynchronously (the seller never waits):
 * Queueable through the SapMuleClient facade (MOCKED until the Mule contract
 * closes — flip SapMuleClient.mockMode, this class does not change). Vehicle
 * cycle per the SAP services doc (22/07): paso 0 obligatorio ZQEV_ASIG_CLIENTE
 * + ZQEV_MONEDA_CLIENTE, then ZQEV_SSA_CREA_ORD_VEH creates the Z301
 * (oferta/reserva). Publishes SapOrderResponse__e for the open UI (empApi,
 * scoped subscription); flow SAP_Order_Response_Handler persists async
 * confirmations. Invoicing returns later by inbound update from MuleSoft
 * (record update + custom notification, never empApi) — flow
 * Order_Facturado_Handler owns that leg.
 */
public with sharing class SapOrderService implements Queueable, Database.AllowsCallouts {

    private final Id orderId;

    public SapOrderService(Id orderId) {
        this.orderId = orderId;
    }

    public void execute(QueueableContext context) {
        // pierna asíncrona de integración: corre en modo sistema a propósito
        // — con USER_MODE la query falla para perfiles sin FLS sobre
        // Order.QuoteId, y el envío a SAP no puede depender del perfil de
        // quien disparó el pedido (mismo criterio que el flow inbound)
        List<Order> orders = [
            SELECT Id, OrderNumber, CurrencyIsoCode, OpportunityId, QuoteId,
                   SapStatus__c, AccountId, Account.AccountNumber,
                   (SELECT Id, Quantity, UnitPrice, Product2Id, Product2.ProductCode FROM OrderItems)
            FROM Order
            WHERE Id = :orderId
        ];
        if (orders.isEmpty()) {
            return;
        }
        Order pedido = orders[0];

        SapMuleClient.OrderDocRequest req = new SapMuleClient.OrderDocRequest();
        req.reference = pedido.OrderNumber;
        // cliente = cuenta compradora del pedido (codigo SAP del cliente)
        req.customerCode = pedido.Account == null ? null : pedido.Account.AccountNumber;
        req.currencyIsoCode = pedido.CurrencyIsoCode;
        // TODO (resolución del dealer): companyCode (sociedad C101/C105) y
        // plant (CENTRO — lo que pide la interfaz de reserva, grabación Luis
        // 04/06) salen del dealer de la venta (sucursal del vendedor /
        // OpportunityPreferredSeller), no de la cuenta compradora. Pendiente
        // de la decisión funcional; en mock no bloquea.
        req.companyCode = null;
        req.plant = null;
        req.lines = new List<SapMuleClient.SimulationLine>();
        for (OrderItem item : pedido.OrderItems) {
            SapMuleClient.SimulationLine line = new SapMuleClient.SimulationLine();
            line.productCode = item.Product2.ProductCode;
            line.quantity = item.Quantity;
            line.unitPrice = item.UnitPrice;
            req.lines.add(line);
        }

        String nuevoEstado;
        String numeroSap;
        String error;
        try {
            // paso 0 (pre-requisitos OBLIGATORIOS de la familia ZQEV)
            SapMuleClient.Ack asignacion = SapMuleClient.asigCliente(req.customerCode, req.companyCode);
            if (asignacion == null || asignacion.ok != true) {
                throw new SapMuleClient.SapMuleClientException(
                    'ZQEV_ASIG_CLIENTE falló: ' + (asignacion == null ? 'sin respuesta' : asignacion.message));
            }
            SapMuleClient.CurrencyResult moneda = SapMuleClient.monedaCliente(req.customerCode, req.companyCode);
            if (moneda == null || moneda.ok != true) {
                throw new SapMuleClient.SapMuleClientException('ZQEV_MONEDA_CLIENTE falló.');
            }

            // Z301 = oferta/reserva (Reserva Confirmada ↔ Z301, gates HU-025)
            SapMuleClient.OrderDocResult doc = SapMuleClient.crearOrdenVehiculo(req);
            if (doc != null && doc.ok == true) {
                numeroSap = doc.sapDocNumber;
                nuevoEstado = String.isBlank(numeroSap) ? 'Enviado a SAP' : 'Confirmado SAP';
            } else {
                nuevoEstado = 'Error SAP';
                error = doc == null ? 'Sin respuesta del gateway.' : doc.message;
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
}