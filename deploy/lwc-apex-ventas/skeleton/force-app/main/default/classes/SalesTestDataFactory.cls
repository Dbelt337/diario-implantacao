/**
 * All countries. Test data factory for the sales flow test classes (official
 * test-utility pattern): annotated @isTest so it never counts for coverage,
 * reused via @TestSetup by every test class. One method per object.
 */
@isTest
public class SalesTestDataFactory {

    public static Account createAccount() {
        Account customer = new Account(Name = 'Cliente de Prueba');
        insert customer;
        return customer;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opportunity = new Opportunity(
            Name = 'Oportunidad de Prueba',
            AccountId = accountId,
            StageName = 'Negociación',
            CloseDate = Date.today().addDays(30)
        );
        insert opportunity;
        return opportunity;
    }

    // TODO (per GUIA): createQuoteWithVin(), createUsedVehicle(), createOrderConfirmado()
}
