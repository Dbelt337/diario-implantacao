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
    }
}
