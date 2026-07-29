/**
 * All countries. Tests of TestDriveAuthorizationCont: generation stores the
 * PDF in the appointment Files (blob mocked in test context because
 * getContentAsPDF is callout-like) and the guards reject missing input.
 */
@IsTest
private class TestDriveAuthorizationContTest {

    @TestSetup
    static void makeData() {
        Account account = new Account(Name = 'Cliente Test Drive');
        insert account;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = account.Id,
            Status = 'Scheduled',
            SchedStartTime = Datetime.now().addDays(1),
            SchedEndTime = Datetime.now().addDays(1).addHours(1),
            AdvisorName__c = 'Asesor Prueba',
            VehicleDescription__c = 'Toyota Hilux | Placa ABC123 | VIN X1',
            DriverLicenseNumber__c = 'CR-123456'
        );
        insert sa;
    }

    @IsTest
    static void generatesPdfIntoFiles() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        Id contentDocumentId =
            TestDriveAuthorizationCont.generateAuthorization(sa.Id);
        Test.stopTest();

        System.assertNotEquals(null, contentDocumentId,
            'ContentDocumentId must be returned');
        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :sa.Id
                AND ContentDocumentId = :contentDocumentId
        ];
        System.assertEquals(1, links.size(),
            'PDF must be linked to the appointment Files');
    }

    @IsTest
    static void rejectsMissingId() {
        Boolean threw = false;
        Test.startTest();
        try {
            TestDriveAuthorizationCont.generateAuthorization(null);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Null id must be rejected');
    }
}
