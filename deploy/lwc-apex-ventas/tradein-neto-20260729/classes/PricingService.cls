/**
 * All countries. Reference price and tax orchestration for NEW vehicles:
 * reads the price data from the PricebookEntry (list price, expenses, minimum)
 * and asks the BRE (Decision Matrix / Expression Set) for the reference tax rate.
 * The rules live in the BRE and are maintained by the business — never in Apex.
 * SAP remains the fiscal authority: this result is the negotiation reference.
 * Trade-in: exposed as an OPERAND (frozen appraisal value); the net is simple
 * arithmetic done by the UI and re-done by SAP, so both always match.
 */
public with sharing class PricingService {

    /**
     * Returns the reference pricing block for a vehicle in a quote context.
     * @param pricebookEntryId price data source for the vehicle/sociedad
     * @param accountId customer (feeds exoneration rules by customer type)
     * @return PricingResult with base, expenses and reference tax
     */
    public static PricingResult getReferencePricing(Id pricebookEntryId, Id accountId) {
        return getReferencePricing(pricebookEntryId, accountId, null);
    }

    /**
     * Overload with opportunity context: adds the trade-in operand so the
     * price screen can render the payment composition (precio - retoma -
     * anticipo = neto) without a second call.
     * @param pricebookEntryId price data source for the vehicle/sociedad
     * @param accountId customer (feeds exoneration rules by customer type)
     * @param opportunityId current opportunity (source of the trade-in value)
     * @return PricingResult with base, expenses, reference tax and trade-in
     */
    public static PricingResult getReferencePricing(Id pricebookEntryId, Id accountId,
            Id opportunityId) {
        PricingResult result = new PricingResult();
        // TODO: query PricebookEntry (+ custom price fields) with security enforced
        // TODO: invoke the BRE decision matrix for the tax rate
        //       (country + sociedad + propulsion + customer type as inputs)

        if (opportunityId != null) {
            List<Opportunity> opps = [
                SELECT TradeInValue__c
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!opps.isEmpty()) {
                result.tradeInValue = opps[0].TradeInValue__c;
            }
        }
        return result;
    }

    public class PricingResult {
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal expenses;
        @AuraEnabled public Decimal minimumPrice;
        @AuraEnabled public Decimal referenceTaxRate;
        @AuraEnabled public Decimal referenceTaxAmount;
        @AuraEnabled public Decimal referenceTotal;
        // Operand only: accepted appraisal value from the opportunity.
        // The UI computes the displayed net; SAP recomputes the real one.
        @AuraEnabled public Decimal tradeInValue;
    }
}
