/**
 * All countries. Unified material search for every sales flow, one single
 * no-result behavior: local search (SOSL over Product2) -> SAP verification by
 * sociedad/centro -> upsert by ProductCode -> automatic extension -> hand-off
 * to the material request (Product Management domain, outside the sales flow).
 *
 * INTEGRATION MAP (read me first — where each call happens and why):
 *  1. LOCAL leg (IMPLEMENTED below): SOSL over active Product2. Zero callouts;
 *     answers instantly for every material already replicated by MuleSoft.
 *  2. SAP leg (PENDING — MuleSoft Experience API contract with Flavio):
 *     fires ONLY when the local search misses. One GET through the Named
 *     Credential (never a hardcoded URL):
 *       callout:MuleGateway/api/v1/materials/search
 *         ?term={searchTerm}&companyCode={sociedad}&plant={centro}
 *         &page={n}&pageSize=50
 *     Response page: [{ productCode, name, brand, group, stock:[{plant,qty}] }]
 *     with filter, pagination and catalog cache handled SERVER-SIDE by Mule.
 *     On hit: upsert Product2 by ProductCode (external id) and return the
 *     matches flagged fromSap=true.
 *  3. SAP miss: surface the "solicitar material" option (Product Management
 *     HU) — the sales flow never creates materials by itself.
 *  Price is NEVER returned here: price/stock is SapInventoryService's job
 *  (continuation), and reference pricing rules live in PricingService/BRE.
 */
public with sharing class MaterialSearchService {

    private static final Integer MAX_RESULTS = 50;
    private static final Integer MIN_TERM_LENGTH = 3;

    /**
     * Searches materials for the quote UI.
     * @param searchTerm free text or part code (minimum 3 characters)
     * @param companyCode sociedad
     * @param plant centro/sucursal
     * @return matches found locally or brought from SAP
     */
    public static List<MaterialMatch> search(String searchTerm, String companyCode, String plant) {
        List<MaterialMatch> matches = new List<MaterialMatch>();
        if (String.isBlank(searchTerm) || searchTerm.trim().length() < MIN_TERM_LENGTH) {
            return matches;
        }

        // Leg 1 — LOCAL: materials already replicated (SAP -> Mule -> Product2).
        String sanitized = String.escapeSingleQuotes(searchTerm.trim());
        List<List<SObject>> results = [
            FIND :sanitized IN ALL FIELDS
            RETURNING Product2(Id, ProductCode, Name
                WHERE IsActive = true
                LIMIT :MAX_RESULTS)
        ];
        for (Product2 product : (List<Product2>) results[0]) {
            MaterialMatch match = new MaterialMatch();
            match.productId = product.Id;
            match.productCode = product.ProductCode;
            match.name = product.Name;
            match.fromSap = false;
            matches.add(match);
        }

        // Leg 2 — SAP (PENDING Mule contract): only on local miss.
        // HOW IT WILL WORK (Davi):
        //   if (matches.isEmpty()) {
        //       HttpRequest req = new HttpRequest();
        //       req.setEndpoint('callout:MuleGateway/api/v1/materials/search'
        //           + '?term=' + EncodingUtil.urlEncode(sanitized, 'UTF-8')
        //           + '&companyCode=' + companyCode + '&plant=' + plant
        //           + '&page=1&pageSize=50');
        //       req.setMethod('GET');
        //       // send via new Http().send(req) from an @AuraEnabled entry that
        //       // is NOT cacheable (callouts are forbidden in cacheable=true),
        //       // or reuse the Continuation pattern from SapInventoryService if
        //       // the UI must stay responsive during the lookup.
        //       // Parse page -> upsert Product2 by ProductCode (external id)
        //       // -> add matches with fromSap = true.
        //   }
        // Leg 3 — SAP miss: return empty and let the UI offer the material
        // request hand-off (Product Management HU). No material creation here.

        return matches;
    }

    public class MaterialMatch {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productCode;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean fromSap;
    }
}
