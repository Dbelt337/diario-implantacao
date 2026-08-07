/**
 * Tests for MaterialSearchService local leg (SOSL over Product2).
 * The SAP leg is contract-pending (MuleSoft) and covered by design comments.
 */
@isTest
private class MaterialSearchServiceTest {

    @isTest
    static void searchReturnsActiveLocalMaterials() {
        Product2 material = new Product2(
            Name = 'Filtro de aceite TIGGO',
            ProductCode = 'FIL-001',
            IsActive = true
        );
        insert material;
        Test.setFixedSearchResults(new List<Id>{ material.Id });

        List<MaterialSearchService.MaterialMatch> matches =
            MaterialSearchService.search('Filtro', 'C101', 'C101');

        Assert.areEqual(1, matches.size(), 'Local active material must be found');
        Assert.areEqual('FIL-001', matches[0].productCode, 'Product code must be mapped');
        Assert.isFalse(matches[0].fromSap, 'Local results are not flagged as SAP');
    }

    @isTest
    static void searchRejectsShortTerms() {
        List<MaterialSearchService.MaterialMatch> matches =
            MaterialSearchService.search('ab', 'C101', 'C101');

        Assert.areEqual(0, matches.size(), 'Terms under 3 characters must not search');
    }
}