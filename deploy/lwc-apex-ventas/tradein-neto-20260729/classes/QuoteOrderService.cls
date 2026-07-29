/**
 * All countries. Creates quotations and orders on the native model
 * (Quote and Order Capture, Standalone Orders) according to the Record Type
 * of the business line (Venta Vehículo / Contraventa Repuestos / PA / Usados).
 * Bulkified DML; no SOQL or DML inside loops. Order lifecycle: Borrador ->
 * Enviado a SAP -> Confirmado SAP -> Facturado (assetization only on Facturado).
 * Trade-in (retoma): payment composition, never a price discount - the frozen
 * appraisal value travels to SAP as an operand and SAP nets it at invoicing.
 */
public with sharing class QuoteOrderService {

    /**
     * Creates a quote with its line items in a single transaction.
     * @param quoteHeader quote fields already validated by the UI
     * @param lineItems lines with product, quantity and reference prices
     * @return created Quote Id
     */
    //(Quote quoteHeader, List<QuoteLineItem> lineItems
    //vehicles are unique quotes here
    // TODO: accessory must map to the correct vehicle quote (consider using a future new field on the OppLineItem)
        //quotePayloadJson not used yet -> map accessory here(?)
        //selectedVehicles not used yet -> map discount here
    public static List<Quote> createQuotesSingleVehicle(Id opportunityId, String quotePayloadJson, String selectedVehicles) {


        // TODO: insert quote + lines (bulk), respecting the minimum price guard
        if (opportunityId == null) {
            throw new QuoteOrderServiceException('OpportunityId is required.');
        }

        //Query Opportunity + OpportunityLineItems
        Opportunity[] opps = [
            SELECT Id, Name, AccountId, Pricebook2Id, CurrencyIsoCode, TradeInValue__c
            FROM Opportunity
            WHERE Id = :opportunityId
        ];

        if (opps.isEmpty()) {
            System.debug('No se encontraron oportunidades con Id: ' + opportunityId);
            throw new QuoteOrderServiceException('No se encontraron oportunidades');
        }

        Opportunity opp = opps[0];

        if (opp.Pricebook2Id == null) {
            System.debug('La oportunidad no tiene Pricebook: ' + opportunityId);
            throw new QuoteOrderServiceException('La oportunidad necesita un Pricebook');
        }

        //include custom field mapping to vehicle here (Vehicle__c) -> accessory X belong to the vehicle Y
        List<OpportunityLineItem> accessories = [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND (NOT Product2Id IN (SELECT ProductId FROM VehicleDefinition))
        ];

        List<OpportunityLineItem> vehicles = [
            SELECT Id, PricebookEntryId, Quantity, UnitPrice, CurrencyIsoCode, Product2Id, Product2.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId AND (Product2Id IN (SELECT ProductId FROM VehicleDefinition))
        ];

        List<VehicleDTO> vehiclesDTO = (List<VehicleDTO>) JSON.deserialize(selectedVehicles, List<VehicleDTO>.class);

        //IMPORTANT: call a method here to update the Opportunity Line Items to match the selected vehicles/accessories (vehiclesDTO) -> a different vehicle might be (un)selected
        //updateOppLineItemsVehiclesAndAccessories();

        //apply discount to the quote using the vehiclesDTO / create a variable and map to the quote(?) Map<>

        //Set quote status to 'pendiente' when discount approval


        Map<String, List<OpportunityLineItem>> mapOppLineItemsByVehicleId = new Map<String, List<OpportunityLineItem>>();


        List<Quote> quotes = new List<Quote>();

        for (OpportunityLineItem vehicle : vehicles) {
            mapOppLineItemsByVehicleId.put(vehicle.Product2Id, new List<OpportunityLineItem>{vehicle});
            //Create Quote
            //change Name to Name + SKU?
            Quote quote = new Quote(
                Name = (opp.Name + ' ' + vehicle.Product2.Name),
                OpportunityId = opp.Id,
                Pricebook2Id = opp.Pricebook2Id
            );
            //substring(0, 80)
            if (quote.name != null && quote.name.length() > 80) {
                quote.name = quote.name.substring(0, 80);
            }

            quotes.add(quote);
        }

        // Retoma: one trade-in per deal, frozen NOW from the opportunity value
        // (Appraisal After Handler keeps Opportunity.TradeInValue__c current;
        // the quote keeps the value the customer actually negotiated with).
        // Multi-vehicle allocation is a pending business rule: until defined,
        // the trade-in applies to the first vehicle quote only, never to all
        // (stamping every quote would double-count the same used vehicle).
        if (!quotes.isEmpty() && opp.TradeInValue__c != null && opp.TradeInValue__c > 0) {
            quotes[0].TradeInValue__c = opp.TradeInValue__c;
        }

        insert quotes;


        /*for (OpportunityLineItem oppLine : accessories) {
            if (mapOppLineItemsByVehicleId.containsKey(oppLine.Vehicle__c)) {
                mapOppLineItemsByVehicleId.get(oppLine.Vehicle__c).add(oppLine);
            }
        }*/


        //MOCK
        List<OpportunityLineItem> allOppLineItems = new List<OpportunityLineItem>(accessories);
        allOppLineItems.addAll(vehicles);

        List<QuoteLineItem> quoteLineItems = createQuoteLineItemsMOCK(allOppLineItems, quotes[0]);
        //Create QuoteLineItem
        //Map<String, QuoteLineItem> quoteLineItems = createQuoteLineItems(mapOppLineItemsByVehicleId);

        //call discount approval process
        //discountApprovalFlow(quoteLineItemsByQuoteId);



        return quotes;
    }

    /**
     * Converts an accepted quote into an order in Borrador state.
     * @param quoteId accepted quote
     * @return created Order Id
     */
    public static Id createOrderFromQuote(Id quoteId) {
        // TODO: native quote-to-order; Record Type from the quote business line
        // TODO: carry Quote.TradeInValue__c into the order context so
        //       SapOrderService can build the tradeIn block of the payload
        return null;
    }

    public static List<QuoteLineItem> createQuoteLineItemsMOCK(List<OpportunityLineItem> oppLineItems, Quote quote) {
        // Create QuoteLineItems (vehicle + accessories from pricebook)
        List<QuoteLineItem> quoteLines = new List<QuoteLineItem>();
        for (OpportunityLineItem oli : oppLineItems) {
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = quote.Id,
                Quantity = oli.Quantity,
                UnitPrice = oli.UnitPrice,
                PricebookEntryId = oli.PricebookEntryId,
                Product2Id = oli.Product2Id
            );
            quoteLines.add(qli);
        }

        if (!quoteLines.isEmpty()) {
            insert quoteLines;
        }
        return quoteLines;
    }

    /* Real scenario must map by vehicle

    public static List<QuoteLineItem> createQuoteLineItems(Map<Id, List<OpportunityLineItem>> mapOppLineItemsByQuoteId) {
        // Create QuoteLineItems (vehicle + accessories from pricebook)
        List<QuoteLineItem> quoteLines = new List<QuoteLineItem>();
        for (Id qId : mapOppLineItemsByQuoteId.keySet()) {

            for (OpportunityLineItem oli : mapOppLineItemsByQuoteId.get(qId)) {
                QuoteLineItem qli = new QuoteLineItem(
                    QuoteId = q.Id,
                    Quantity = oli.Quantity,
                    UnitPrice = oli.UnitPrice
                );
                quoteLines.add(qli);
            }

        }

        if (!quoteLines.isEmpty()) {
            insert quoteLines;
        }
        return quoteLines;
    }*/


    public static void discountApprovalFlow(Map<Id, List<QuoteLineItem>> quoteLineItemsByQuoteId) {
        /*
            //Verify discount amount here -> send for approval if required

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(quote.Id);
            req.setComments('<comments>');
            req.setSubmitterId(UserInfo.getUserId());

            Approval.ProcessResult result = Approval.process(req);

            if (!result.isSuccess()) {
                throw new AuraHandledException('Failed to submit for approval.');
            }
        */
    }

    public class VehicleDTO {

        public String id { get; set; }
        public String modelo { get; set; }
        public String anio { get; set; }
        public String color { get; set; }
        public String precio { get; set; }
        public Integer stockCentral { get; set; }
        public Integer stockDealer { get; set; }

        public Disponibilidad disponibilidad { get; set; }


    }

    public class Disponibilidad {
        public Integer cantidad { get; set; }
        public String eta { get; set; }
        public String fuente { get; set; }
    }


    //custom exception
    public class QuoteOrderServiceException extends Exception {
    }

}
