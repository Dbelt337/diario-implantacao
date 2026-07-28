import { LightningElement, api } from 'lwc';

/**
 * All countries. Thin business-line UI (Contraventa de Repuestos). Reuses the Apex service
 * layer (SapInventoryService / PricingService / QuoteOrderService /
 * MaterialSearchService); subscribes to SapOrderResponse__e only while the
 * order is in flight (scoped subscription, channel filters).
 */
export default class PartsCounterSale extends LightningElement {
    @api recordId;

    // TODO: search with debounce (MaterialSearchService)
    // TODO: price/stock via SapInventoryService (continuation; spinner while waiting)
    // TODO: quote creation via QuoteOrderService
}
