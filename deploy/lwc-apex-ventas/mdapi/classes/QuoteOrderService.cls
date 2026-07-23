/**
 * All countries. Creates quotations and orders on the native model
 * (Quote and Order Capture, Standalone Orders) according to the Record Type
 * of the business line (Venta Vehículo / Contraventa Repuestos / PA / Usados).
 * Bulkified DML; no SOQL or DML inside loops. Order lifecycle: Borrador ->
 * Enviado a SAP -> Confirmado SAP -> Facturado (assetization only on Facturado).
 */
public with sharing class QuoteOrderService {

    /**
     * Creates a quote with its line items in a single transaction.
     * @param quoteHeader quote fields already validated by the UI
     * @param lineItems lines with product, quantity and reference prices
     * @return created Quote Id
     */
    public static Id createQuote(Quote quoteHeader, List<QuoteLineItem> lineItems) {
        // TODO: insert quote + lines (bulk), respecting the minimum price guard
        return null;
    }

    /**
     * Converts an accepted quote into an order in Borrador state.
     * @param quoteId accepted quote
     * @return created Order Id
     */
    public static Id createOrderFromQuote(Id quoteId) {
        // TODO: native quote-to-order; Record Type from the quote business line
        return null;
    }
}
