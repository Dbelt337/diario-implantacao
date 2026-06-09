/**
 * GrupoQ_ProductSearch
 * Busca de catalogo para a IP Lead_SearchActiveProducts (Remote Action).
 * SOQL LIKE em Name/ProductCode/Description, somente IsActive=true, ordenado por Name, com limit.
 * Saida no shape do contrato (ProductSearchResponse): products[], totalFound, warnings[].
 * Invocado por uma Integration Procedure via elemento Remote Action:
 *   Remote Class  = GrupoQ_ProductSearch
 *   Remote Method = searchProducts
 *   Input: searchText (obrigatorio, min 2 chars), limit (opcional, default 20, teto 50).
 */
global with sharing class GrupoQ_ProductSearch implements Callable {

    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input  = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        if (input == null)  { input = new Map<String, Object>(); }
        if (output == null) { return false; }

        if (action == 'searchProducts') {
            return searchProducts(input, output);
        }
        return false;
    }

    private Boolean searchProducts(Map<String, Object> input, Map<String, Object> output) {
        String searchText = input.get('searchText') == null ? '' : String.valueOf(input.get('searchText'));
        // aceita com ou sem curingas vindos do canal; normaliza
        searchText = searchText.replace('%', '').trim();

        Integer lim = 20;
        if (input.get('limit') != null) {
            try { lim = Integer.valueOf(input.get('limit')); } catch (Exception e) { lim = 20; }
        }
        if (lim > 50) { lim = 50; }
        if (lim < 1)  { lim = 20; }

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        List<Object> warnings = new List<Object>();

        if (searchText.length() >= 2) {
            String term = '%' + searchText + '%';
            for (Product2 p : [
                SELECT Id, Name, ProductCode, Family
                FROM Product2
                WHERE IsActive = true
                  AND (Name LIKE :term OR ProductCode LIKE :term OR Description LIKE :term)
                ORDER BY Name
                LIMIT :lim
            ]) {
                String pType = (p.Family == 'Repuestos' || p.Family == 'PA') ? 'SPARE_PART' : 'VEHICLE';
                products.add(new Map<String, Object>{
                    'productId'     => p.Id,
                    'productCode'   => p.ProductCode,
                    'productName'   => p.Name,
                    'productFamily' => p.Family,
                    'productType'   => pType,
                    'isActive'      => true
                });
            }
        }

        if (products.isEmpty()) {
            warnings.add(new Map<String, Object>{
                'code'    => 'NO_PRODUCTS_FOUND',
                'message' => 'Nenhum Product2 ativo casa com o texto de busca.',
                'field'   => 'searchText'
            });
        }

        output.put('products', products);
        output.put('totalFound', products.size());
        output.put('warnings', warnings);
        return true;
    }
}
