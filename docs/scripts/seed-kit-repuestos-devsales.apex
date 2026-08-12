// ============================================================
// SEED COMPLETO do kit de teste (GQ-PV-02-029) — DevSales · v3
// Quote: 0Q0WK0000059Ke90AE (workflow 3 - Accent Sedan) · CRC
// v2: KIT-001 nasce com Type='Bundle' (pai precisa ser bundle/set/base)
// v3: componentes com IsDefaultComponent=true (bundle estático)
// Idempotente: pode rodar mais de uma vez sem duplicar.
// Execute Anonymous — esperado no fim: "SEED OK" no debug log.
// ============================================================
Quote q = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Id = '0Q0WK0000059Ke90AE'];
Id std = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
Id tipoId = '0yoao0000019FldAAE'; // Bundle -> BundleComponent (tipo existente, GAPCHECK2)

// --- produtos (componentes + kit): cria só os que faltam ---
List<String> codigos = new List<String>{ 'REP-001', 'REP-002', 'KIT-001' };
Map<String, Product2> porCodigo = new Map<String, Product2>();
for (Product2 p : [SELECT Id, ProductCode, Type FROM Product2 WHERE ProductCode IN :codigos]) {
    porCodigo.put(p.ProductCode, p);
}
List<Product2> novos = new List<Product2>();
if (!porCodigo.containsKey('REP-001')) {
    novos.add(new Product2(Name = 'Repuesto demo 1', ProductCode = 'REP-001', IsActive = true));
}
if (!porCodigo.containsKey('REP-002')) {
    novos.add(new Product2(Name = 'Repuesto demo 2', ProductCode = 'REP-002', IsActive = true));
}
if (!porCodigo.containsKey('KIT-001')) {
    // Type='Bundle': exigência do catálogo para ser PAI de componentes
    novos.add(new Product2(Name = 'Kit mantenimiento demo', ProductCode = 'KIT-001',
        IsActive = true, Type = 'Bundle'));
}
insert novos;
for (Product2 p : novos) { porCodigo.put(p.ProductCode, p); }

Product2 kit  = porCodigo.get('KIT-001');
Product2 rep1 = porCodigo.get('REP-001');
Product2 rep2 = porCodigo.get('REP-002');

// kit pré-existente de uma rodada anterior sem tipo: corrige antes do vínculo
if (kit.Type != 'Bundle') {
    kit.Type = 'Bundle';
    update kit;
}

// --- entradas de preço (Standard primeiro; depois a lista da quote): só as que faltam ---
Set<Id> produtoIds = new Set<Id>{ kit.Id, rep1.Id, rep2.Id };
Set<String> jaTem = new Set<String>();
for (PricebookEntry pbe : [SELECT Product2Id, Pricebook2Id FROM PricebookEntry
                           WHERE Product2Id IN :produtoIds
                             AND CurrencyIsoCode = :q.CurrencyIsoCode]) {
    jaTem.add('' + pbe.Product2Id + pbe.Pricebook2Id);
}
List<PricebookEntry> pbes = new List<PricebookEntry>();
for (Id pid : produtoIds) {
    if (!jaTem.contains('' + pid + std)) {
        pbes.add(new PricebookEntry(Pricebook2Id = std, Product2Id = pid,
            UnitPrice = 100, IsActive = true, CurrencyIsoCode = q.CurrencyIsoCode));
    }
}
insert pbes;
if (q.Pricebook2Id != null && q.Pricebook2Id != std) {
    List<PricebookEntry> lista = new List<PricebookEntry>();
    for (Id pid : produtoIds) {
        if (!jaTem.contains('' + pid + q.Pricebook2Id)) {
            lista.add(new PricebookEntry(Pricebook2Id = q.Pricebook2Id, Product2Id = pid,
                UnitPrice = 100, IsActive = true, UseStandardPrice = false,
                CurrencyIsoCode = q.CurrencyIsoCode));
        }
    }
    insert lista;
}

// --- vínculos do kit (só se ainda não existem) ---
// IsDefaultComponent=true: bundle estático exige componentes por padrão
// ("Child component must be added by default for a Static Parent Product")
Integer vinculos = [SELECT COUNT() FROM ProductRelatedComponent WHERE ParentProductId = :kit.Id];
if (vinculos == 0) {
    insert new List<ProductRelatedComponent>{
        new ProductRelatedComponent(ParentProductId = kit.Id, ChildProductId = rep1.Id,
            ProductRelationshipTypeId = tipoId, Quantity = 2,
            IsDefaultComponent = true),   // 2x REP-001 por kit
        new ProductRelatedComponent(ParentProductId = kit.Id, ChildProductId = rep2.Id,
            ProductRelationshipTypeId = tipoId, Quantity = 1,
            IsDefaultComponent = true)    // 1x REP-002 por kit
    };
}
System.debug(LoggingLevel.ERROR, 'SEED OK: KIT-001 = 2x REP-001 + 1x REP-002 (Bundle->BundleComponent)');
