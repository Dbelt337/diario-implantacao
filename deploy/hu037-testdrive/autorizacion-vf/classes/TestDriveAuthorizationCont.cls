/**
 * All countries. Controller of the test drive authorization document
 * (HU-037 RN 9): serves the Visualforce render template
 * (TestDriveAuthorizationPdf, headless renderAs=pdf) and exposes the
 * generation service to the LWC quick action on the ServiceAppointment.
 * One generator, many callers: the same @AuraEnabled method can later be
 * invoked from an Integration Procedure (Remote Action wrapper) or a Flow.
 * PDF is produced BEFORE any DML (getContentAsPDF is callout-like and
 * cannot run after DML in the same transaction).
 */
public with sharing class TestDriveAuthorizationCont {

    public ServiceAppointment appointment { get; private set; }
    public String generatedOn { get; private set; }

    /**
     * Visualforce constructor: loads the appointment referenced by the
     * "id" page parameter with every token printed on the document.
     */
    public TestDriveAuthorizationCont() {
        Id saId = (Id) ApexPages.currentPage().getParameters().get('id');
        this.appointment = queryAppointment(saId);
        this.generatedOn = Datetime.now().format('dd/MM/yyyy HH:mm');
    }

    /**
     * Generates the authorization PDF for a service appointment and stores
     * it in the record Files.
     * @param serviceAppointmentId test drive appointment
     * @return ContentDocumentId of the stored PDF (for file preview)
     */
    @AuraEnabled
    public static Id generateAuthorization(Id serviceAppointmentId) {
        try {
            ServiceAppointment sa = queryAppointment(serviceAppointmentId);

            PageReference pdfPage = Page.TestDriveAuthorizationPdf;
            pdfPage.getParameters().put('id', serviceAppointmentId);
            // getContentAsPDF is not allowed in test context: mocked blob
            Blob pdfBlob = Test.isRunningTest()
                ? Blob.valueOf('PDF-TEST')
                : pdfPage.getContentAsPDF();

            ContentVersion version = new ContentVersion(
                Title = 'Autorizacion Test Drive ' + sa.AppointmentNumber,
                PathOnClient = 'AutorizacionTestDrive_' + sa.AppointmentNumber + '.pdf',
                VersionData = pdfBlob,
                FirstPublishLocationId = serviceAppointmentId
            );
            insert version;

            return [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :version.Id
                LIMIT 1
            ].ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Flow-facing wrapper of the same generator, so the trigger surface can
     * be a Screen Flow (quick action type Flow) instead of the headless LWC
     * without touching the service. One generator, many callers.
     * @param serviceAppointmentIds single-element list (Flow contract)
     * @return ContentDocumentIds of the stored PDFs
     */
    @InvocableMethod(label='Generate Test Drive Authorization'
        description='Generates the test drive authorization PDF into the appointment Files and returns the ContentDocumentId.')
    public static List<Id> generateAuthorizationInvocable(List<Id> serviceAppointmentIds) {
        List<Id> results = new List<Id>();
        for (Id saId : serviceAppointmentIds) {
            results.add(generateAuthorization(saId));
        }
        return results;
    }

    /**
     * Single query shared by the page and the service: the document tokens.
     * Vehicle, advisor and license come from the display stamps kept by
     * Assigned Resource After Handler / the booking OmniScript, so the
     * printed document always matches the CURRENT resource assignment.
     */
    private static ServiceAppointment queryAppointment(Id saId) {
        if (saId == null) {
            throw new AuraHandledException('ServiceAppointmentId is required.');
        }
        List<ServiceAppointment> sas = [
            SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime,
                   Street, City, Description,
                   ServiceTerritory.Name,
                   Account.Name,
                   AdvisorName__c, VehicleDescription__c, DriverLicenseNumber__c
            FROM ServiceAppointment
            WHERE Id = :saId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (sas.isEmpty()) {
            throw new AuraHandledException('Service appointment not found.');
        }
        return sas[0];
    }
}
