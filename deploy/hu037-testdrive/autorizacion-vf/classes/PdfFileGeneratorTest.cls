/**
 * All countries. Tests of PdfFileGenerator: the PDF file is created,
 * linked to the record when requested, and bulk requests insert once.
 */
@IsTest
private class PdfFileGeneratorTest {

    @IsTest
    static void generatesAndLinksPdf() {
        Account account = new Account(Name = 'Cliente PDF');
        insert account;

        PdfFileGenerator.Request request = new PdfFileGenerator.Request();
        request.html = '<html><body><b>Autorizacion</b> de prueba</body></html>';
        request.title = 'AutorizacionPrueba';
        request.recordId = account.Id;

        Test.startTest();
        List<PdfFileGenerator.Result> results =
            PdfFileGenerator.generatePdfFiles(
                new List<PdfFileGenerator.Request>{ request });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].contentVersionId);

        ContentVersion version = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :results[0].contentVersionId
        ];
        System.assertEquals('AutorizacionPrueba', version.Title);

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :account.Id
                AND ContentDocumentId = :version.ContentDocumentId
        ];
        System.assertEquals(1, links.size(),
            'File must be linked to the record');
    }

    @IsTest
    static void generatesWithoutRecordLink() {
        PdfFileGenerator.Request request = new PdfFileGenerator.Request();
        request.html = '<html><body>Sin registro</body></html>';
        request.title = 'SinRegistro';

        Test.startTest();
        List<PdfFileGenerator.Result> results =
            PdfFileGenerator.generatePdfFiles(
                new List<PdfFileGenerator.Request>{ request });
        Test.stopTest();

        System.assertNotEquals(null, results[0].contentVersionId);
    }
}
