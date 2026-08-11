/**
 * All countries. Test data factory for the sales flow test classes (official
 * test-utility pattern): annotated @isTest so it never counts for coverage,
 * reused via @TestSetup by every test class. One method per object.
 *
 * Regras da org respeitadas aqui (para a massa passar nas validações reais):
 *  - Account.Country__c é obrigatório (picklist restrito) -> 'CR'.
 *  - VR Metodo_Preferido_Requerido_Creacion exige PreferredContactMethod__c
 *    ao criar Opportunity com RT Autos/Motos -> sempre setado ('Telefono').
 *  - VR Currency_Matches_Country só dispara com Pais__c (fórmula sobre
 *    CompanyCode__c) -> CompanyCode__c fica em branco nos testes.
 *  - Pricebook: SEMPRE o standard via Test.getStandardPricebookId() (o
 *    standard não é consultável por SOQL em teste sem SeeAllData).
 */
@isTest
public class VentasTestDataFactory {

    public static Account createAccount() {
        Account customer = new Account(
            Name = 'Cliente de Prueba',
            Country__c = 'CR',
            AccountNumber = 'SAP-0000123'
        );
        insert customer;
        return customer;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opportunity = new Opportunity(
            Name = 'Oportunidad de Prueba',
            AccountId = accountId,
            StageName = 'Negociación',
            CloseDate = Date.today().addDays(30),
            PreferredContactMethod__c = 'Telefono',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opportunity;
        return opportunity;
    }

    /** Variante sem pricebook: exercita resolveDefaultPricebookId(). */
    public static Opportunity createOpportunityNoPricebook(Id accountId) {
        Opportunity opportunity = new Opportunity(
            Name = 'Oportunidad Sin Catalogo',
            AccountId = accountId,
            StageName = 'Negociación',
            CloseDate = Date.today().addDays(30),
            PreferredContactMethod__c = 'Telefono'
        );
        insert opportunity;
        return opportunity;
    }

    public static Product2 createProduct(String name, String code) {
        Product2 product = new Product2(Name = name, ProductCode = code, IsActive = true);
        insert product;
        return product;
    }

    /** Entrada do pricebook STANDARD para o produto (moeda default do usuário). */
    public static PricebookEntry createStandardEntry(Id productId, Decimal price) {
        PricebookEntry entry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = price,
            IsActive = true
        );
        insert entry;
        return entry;
    }

    /**
     * Marca o produto como VEÍCULO: QuoteOrderService separa veículos de
     * acessórios pelo subquery em VehicleDefinition (ProductId).
     */
    public static VehicleDefinition createVehicleDefinition(Id productId, String name) {
        VehicleDefinition definition = new VehicleDefinition(
            Name = name,
            ProductId = productId
        );
        insert definition;
        return definition;
    }

    public static OpportunityLineItem addOpportunityLine(Id opportunityId, Id pricebookEntryId,
            Decimal quantity, Decimal unitPrice) {
        OpportunityLineItem line = new OpportunityLineItem(
            OpportunityId = opportunityId,
            PricebookEntryId = pricebookEntryId,
            Quantity = quantity,
            UnitPrice = unitPrice
        );
        insert line;
        return line;
    }

    /** Cotização pronta com UMA linha — insumo de createOrderFromQuote. */
    public static Quote createQuoteWithLine(Opportunity opportunity, PricebookEntry entry) {
        Quote quotation = new Quote(
            Name = 'Cotización de Prueba',
            OpportunityId = opportunity.Id,
            Pricebook2Id = opportunity.Pricebook2Id
        );
        insert quotation;
        insert new QuoteLineItem(
            QuoteId = quotation.Id,
            PricebookEntryId = entry.Id,
            Quantity = 1,
            UnitPrice = entry.UnitPrice,
            Product2Id = entry.Product2Id
        );
        return quotation;
    }

    /** Cenário completo: conta + oportunidade + veículo (com definition) + acessório, com entradas standard. */
    public static Opportunity createGuidedSellingScenario() {
        Account customer = createAccount();
        Opportunity opportunity = createOpportunity(customer.Id);
        Product2 vehicle = createProduct('Hyundai Creta GL 1.5', 'VEH-001');
        createVehicleDefinition(vehicle.Id, 'Hyundai Creta GL 1.5');
        createStandardEntry(vehicle.Id, 16800000);
        Product2 accessory = createProduct('Barra antivuelco', 'ACC-001');
        createStandardEntry(accessory.Id, 250000);
        return opportunity;
    }
}
