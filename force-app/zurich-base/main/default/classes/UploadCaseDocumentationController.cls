/**
 * Class that is invoked by the LWC UploadCaseDocumentation.
 *
 * The client (Personal Account -> Case) arrives through the case documentation link (email or SMS) to the site.
 *
 * From there, the client can upload documentation directly to the specified case, only if the case is still open.
 *
 * @author nts (rlopez)
 * @date 23/02/2021
 *
 */
public without sharing class UploadCaseDocumentationController
{
    //#Region public classes

    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data)
    {
        try
        {
            //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

            ContentVersion cv = new ContentVersion();
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.Title = fileName;
            cv.PathOnClient = filename;

            insert cv;

            ContentVersion createdContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = createdContentVersion.ContentDocumentId;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V';

            insert cdl;

            return cv.Id;
        }
        catch (Exception e)
        {
            //ErrorLogUtil.commitError(e, 'UploadCaseDocumentationController', parentId);
            throw new AuraHandledException( e.getMessage() );
        }
    }

    @AuraEnabled
    public static Case getCase(String hashId)
    {
        if( String.isNotBlank(hashId) )
        {
            List<Case> caseFromUrl = [SELECT Id, Subject, CaseNumber, Status, CreatedDate FROM Case WHERE DocumentationHashId__c =: hashId LIMIT 1];
            if( caseFromUrl != null && !caseFromUrl.isEmpty() )
            {
                return caseFromUrl.get(0);
            }
            else
            {
                ErrorLogUtil.commitError('warning', 'El Id especificado no pertenece a un caso.', 'UploadCaseDocumentationController');
                throw new AuraHandledException('El Id especificado no pertenece a un caso.');
            }
        }
        else
        {
            ErrorLogUtil.commitError('warning', 'El Id del Caso está vacío.', 'UploadCaseDocumentationController');
            throw new AuraHandledException('El Id del Caso está vacío.');
        }
    }

    /**
     * @description Mensaje que se envia al servidor de Desigual
     * @param {String} body - Cuerpo del mensaje a enviar
     * @author jbarcelo
     * @date 02/06/2020
     */
    @AuraEnabled
    public static String getUrlToUploadFiles(Boolean community)
    {
        return URL.getOrgDomainUrl().toExternalForm();
    }

    @AuraEnabled
    public static void createContentDocumentLink(String guestHash)
    {
        System.debug( 'User: ' + UserInfo.getUserName() );
        System.debug('guestHash: ' + guestHash);
        ContentVersion createdContentVersion = [SELECT Id, ContentDocumentId, Guest_Record_fileupload__c FROM ContentVersion WHERE Guest_Record_fileupload__c =: guestHash LIMIT 1];
        System.debug('createdContentVersion: ' + createdContentVersion);

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = createdContentVersion.ContentDocumentId;
        cdl.LinkedEntityId = createdContentVersion.Guest_Record_fileupload__c;
        cdl.ShareType = 'V';

        insert cdl;
    }

    public class UploadCaseDocumentationControllerException extends Exception
    {}
}