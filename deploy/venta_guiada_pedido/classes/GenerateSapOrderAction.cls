/**
 * All countries. Declarative entry of the pedido leg: exposes "create order
 * from quote + send to SAP" as ONE invocable action, so a screen flow /
 * quick action on the Quote triggers the pipeline without touching the
 * guided-selling LWCs (org pattern: Flow for back-office screens). Bulk-safe;
 * idempotent through QuoteOrderService (one order per quote, ever).
 */
public with sharing class GenerateSapOrderAction {

    @InvocableMethod(label='Generar pedido SAP desde cotización'
        description='Crea el pedido nativo desde la cotización (Borrador) y lo envía a SAP vía MuleGateway en segundo plano.'
        category='Venta Guiada')
    public static List<Result> generate(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request r : requests) {
            Result res = new Result();
            try {
                res.orderId = QuoteOrderService.createOrderFromQuote(r.quoteId);
                QuoteOrderService.sendOrderToSap(res.orderId);
                res.success = true;
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(label='Id de la cotización' required=true)
        public Id quoteId;
    }

    public class Result {
        @InvocableVariable(label='Id del pedido creado')
        public Id orderId;
        @InvocableVariable(label='Éxito')
        public Boolean success;
        @InvocableVariable(label='Mensaje de error')
        public String errorMessage;
    }
}
