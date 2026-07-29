/**
 * All countries. Sends the order to SAP asynchronously (the seller never waits):
 * Queueable with callout through the MuleSoft Named Credential. On confirmation,
 * publishes the SapOrderResponse__e platform event so the open UI (empApi,
 * scoped subscription) can react. Invoicing returns later by inbound update
 * from MuleSoft (record update + custom notification, never empApi).
 */
public with sharing class SapOrderService implements Queueable, Database.AllowsCallouts {

    private final Id orderId;

    public SapOrderService(Id orderId) {
        this.orderId = orderId;
    }

    public void execute(QueueableContext context) {
        // TODO: build order payload, POST to MuleSoft via Named Credential
        // TODO: update Order state Borrador -> Enviado a SAP -> (callback) Confirmado SAP
        // TODO: publish SapOrderResponse__e with order Id, SAP number and status
        // TODO: fill OrderPayload.tradeIn from Quote.TradeInValue__c when the
        //       quote carries a retoma. CONTRACT GATE: the tradeIn block does
        //       not exist yet in the MuleSoft order contract (Annex) - it must
        //       be added there BEFORE this leg goes live. SF sends operands
        //       (appraisal reference + frozen value); SAP nets financially at
        //       invoicing. Never send a calculated net.
    }

    /**
     * Order payload contract (mirror of the MuleSoft order service). The
     * tradeIn block is optional: absent when the deal has no retoma.
     */
    public class OrderPayload {
        public String orderId;
        public String sociedad;
        public String currencyIsoCode;
        public List<OrderLine> lines;
        public TradeInBlock tradeIn;
    }

    public class OrderLine {
        public String materialCode;
        public Decimal quantity;
        public Decimal unitPrice;
    }

    /**
     * Operands of the payment composition, never results: SAP recomputes the
     * net so both systems match by construction.
     */
    public class TradeInBlock {
        public String appraisalId;      // VehicleAppraisal Id (trazabilidad SF)
        public Decimal value;           // frozen Quote.TradeInValue__c
        public String currencyIsoCode;
    }
}
