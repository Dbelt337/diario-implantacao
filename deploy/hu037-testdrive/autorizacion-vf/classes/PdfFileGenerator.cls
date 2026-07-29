/**
 * All countries. Generic Flow action that turns an HTML string into a PDF
 * stored as a Salesforce File, using the Blob.toPdf() Apex capability
 * (enhanced in Spring 26). Same contract as the community "Generate PDF
 * File" action (html, title, recordId), implemented in-house to avoid a
 * third-party package in the customer org. Reusable by ANY document flow:
 * the layout lives in a Flow Text Template (admin-editable, no deploy).
 */
public with sharing class PdfFileGenerator {

    public class Request {
        @InvocableVariable(label='HTML' required=true
            description='HTML markup converted into the PDF content')
        public String html;

        @InvocableVariable(label='Title' required=true
            description='File name without extension')
        public String title;

        @InvocableVariable(label='Record Id'
            description='Optional record to attach the file to (Files related list)')
        public Id recordId;
    }

    public class Result {
        @InvocableVariable(label='Content Version Id')
        public Id contentVersionId;
    }

    /**
     * Converts each request into a ContentVersion (single bulk insert).
     * @param requests html + title + optional recordId per document
     * @return ContentVersion ids in the same order
     */
    @InvocableMethod(label='Generate PDF File'
        description='Generates a PDF from HTML and saves it as a Salesforce File, optionally attached to a record.')
    public static List<Result> generatePdfFiles(List<Request> requests) {
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Request request : requests) {
            ContentVersion version = new ContentVersion(
                Title = request.title,
                PathOnClient = request.title + '.pdf',
                VersionData = Blob.toPdf(request.html)
            );
            if (request.recordId != null) {
                version.FirstPublishLocationId = request.recordId;
            }
            versions.add(version);
        }
        insert versions;

        List<Result> results = new List<Result>();
        for (ContentVersion version : versions) {
            Result result = new Result();
            result.contentVersionId = version.Id;
            results.add(result);
        }
        return results;
    }
}
