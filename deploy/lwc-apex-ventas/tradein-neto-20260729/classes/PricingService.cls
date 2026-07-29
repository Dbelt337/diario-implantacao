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

    public static PricingResult getReferencePricing(Id pricebookEntryId, Id accountId) {
        return getReferencePricing(pricebookEntryId, accountId, null);
    }

    /**
     * Reference pricing block with opportunity context. Local half only:
     * PricebookEntry reference columns + trade-in operand; the authoritative
     * SAP half (precio ZGQREF, stock) arrives via Continuation.
     * @param pricebookEntryId price data source for the vehicle/sociedad
     * @param accountId customer (feeds exoneration rules by customer type)
     * @param opportunityId current opportunity (trade-in + exonerated flags)
     * @return PricingResult operands for the price screen
     */
    public static PricingResult getReferencePricing(Id pricebookEntryId, Id accountId,
            Id opportunityId) {
        PricingResult result = new PricingResult();

        Boolean exonerated = false;
        if (opportunityId != null) {
            List<Opportunity> opps = [
                SELECT TradeInValue__c, VentaExonerada__c
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!opps.isEmpty()) {
                exonerated = opps[0].VentaExonerada__c == true;
                result.isExoneratedSale = exonerated;
                result.tradeInValue = opps[0].TradeInValue__c;

                // Retoma only counts while an ACCEPTED appraisal is still
                // valid (native ValidityEndDate); expired -> UI must warn
                // and block applying it (HU-036 acceptance rule).
                if (result.tradeInValue != null && result.tradeInValue > 0) {
                    List<Appraisal> vigentes = [
                        SELECT Id
                        FROM Appraisal
                        WHERE ReferenceRecordId = :opportunityId
                            AND Status = 'Aceptado'
                            AND (ValidityEndDate = null OR ValidityEndDate >= TODAY)
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                    ];
                    result.isTradeInExpired = vigentes.isEmpty();
                }
            }
        }

        if (pricebookEntryId != null) {
            List<PricebookEntry> entries = [
                SELECT UnitPrice, Gastos__c, PrecioMinimoAsesor__c,
                       PrecioExonerado__c, PrecioExoneradoMinimo__c,
                       AplicaCashback__c, MontoCashback__c
                FROM PricebookEntry
                WHERE Id = :pricebookEntryId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!entries.isEmpty()) {
                PricebookEntry pbe = entries[0];
                // Venta exonerada swaps the whole reference column set
                result.listPrice = exonerated && pbe.PrecioExonerado__c != null
                    ? pbe.PrecioExonerado__c : pbe.UnitPrice;
                result.minimumPrice = exonerated && pbe.PrecioExoneradoMinimo__c != null
                    ? pbe.PrecioExoneradoMinimo__c : pbe.PrecioMinimoAsesor__c;
                result.expenses = pbe.Gastos__c;
                result.appliesCashback = pbe.AplicaCashback__c == true;
                result.cashbackAmount = pbe.AplicaCashback__c == true
                    ? pbe.MontoCashback__c : null;
            }
        }

        // TODO: invoke the BRE decision matrix for the reference tax rate
        //       (country + sociedad + propulsion + customer type as inputs);
        //       fills referenceTaxRate/referenceTaxAmount/referenceTotal.
        return result;
    }

    public class PricingResult {
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal expenses;
        @AuraEnabled public Decimal minimumPrice;
        @AuraEnabled public Decimal referenceTaxRate;
        @AuraEnabled public Decimal referenceTaxAmount;
        @AuraEnabled public Decimal referenceTotal;
        // Operands only: the UI (resumenFinanciero) does the arithmetic and
        // SAP recomputes the real net - never ship a calculated net from here.
        @AuraEnabled public Decimal tradeInValue;
        @AuraEnabled public Boolean isTradeInExpired = false;
        @AuraEnabled public Boolean isExoneratedSale = false;
        @AuraEnabled public Boolean appliesCashback = false;
        @AuraEnabled public Decimal cashbackAmount;
    }
}
