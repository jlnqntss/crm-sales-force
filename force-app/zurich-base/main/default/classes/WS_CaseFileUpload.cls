@RestResource(urlMapping='/cases/*/filename/*')
global with sharing class WS_CaseFileUpload
{

    public class CaseFileUploadException extends Exception
    {}

    /**
        @description Inserta un archivo relacionado con un caso
        @author jbarcelo
        @date 14/06/2020
     */
    @HttpPost
    global static String uploadFile()
    {
        System.debug('uploadFile');
        ContentVersion cv;
        Database.SaveResult sr;

        try
        {
            RestRequest request = RestContext.request;

            String caseId = request.requestURI.substringBeforeLast('/filename/').substringAfterLast('/cases/');
            String fileName = request.requestURI.substringAfterLast('/filename/');

            cv = new ContentVersion(
                Title = fileName,
                PathOnCLient = '/' + fileName,
                VersionData = request.requestBody,
                IsMajorVersion = true,
                FirstPublishLocationId = caseId
                );

            insert cv;

            ContentVersion createdContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = createdContentVersion.ContentDocumentId;
            cdl.LinkedEntityId = caseId;
            cdl.ShareType = 'V';

            insert cdl;
        }
        catch(Exception err)
        {
            throw new CaseFileUploadException( 'Error: ' + err.getMessage() );
        }

        if( !sr.isSuccess() )
        {
            throw new CaseFileUploadException( 'Error: ' + sr.getErrors()[0].getMessage() );
        }

        return cv.Id;
    }
}