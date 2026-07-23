/**
 * All countries. Unified material search for every sales flow, one single
 * no-result behavior: local search (SOSL over Product2) -> SAP verification by
 * sociedad/centro -> upsert by ProductCode -> automatic extension -> hand-off
 * to the material request (Product Management domain, outside the sales flow).
 */
public with sharing class MaterialSearchService {

    /**
     * Searches materials for the quote UI.
     * @param searchTerm free text or part code
     * @param companyCode sociedad
     * @param plant centro/sucursal
     * @return matches found locally or brought from SAP
     */
    public static List<MaterialMatch> search(String searchTerm, String companyCode, String plant) {
        // TODO: SOSL on Product2 (active, by Record Type of the line)
        // TODO: on miss, verify in SAP (SapInventoryService), upsert by ProductCode
        // TODO: on SAP miss, surface the request option (HU of Product Management)
        return new List<MaterialMatch>();
    }

    public class MaterialMatch {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productCode;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean fromSap;
    }
}
