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

    // Constants
    private static final Boolean showDebug = true;
    private static final String UNSUBSCRIBED_SOURCE = 'Centro de preferencias';

    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data)
    {
        try
        {
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');

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
            throw new AuraHandledException( e.getMessage() );
        }
    }

    @AuraEnabled
    public static Case getCase(String hashId)
    {
        if( String.isNotBlank(hashId) )
        {
            Case caseFromUrl = [SELECT Id, Subject, CaseNumber, Status, CreatedDate FROM Case WHERE DocumentationHashId__c =: hashId];
            if(caseFromUrl != null)
            {
                return caseFromUrl;
            }
            else
            {
                throw new AuraHandledException('El Id especificado no pertenece a un caso.');
            }
        }
        else
        {
            throw new AuraHandledException('El Id del Caso está vacío.');
        }
    }

    @AuraEnabled
    public static void publishErrorEvent(String errorMessage, String jsFunction, String caseId)
    {
        try
        {
            ErrorLogUtil.commitError(new UploadCaseDocumentationControllerException(errorMessage), jsFunction, caseId);
        }
        catch(Exception e)
        {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    /**
     * This method get the labels for the lwc page.
     *
     * @author Rubén López
     */
    @AuraEnabled(cacheable=true)
    public static String getLabels()
    {
        AppLabels labels = new AppLabels();

        labels.PreferenceCentreTitleLabel = Label.PreferenceCentreTitle;
        labels.PreferenceCentreSubtitleLabel = Label.PreferenceCentreSubtitle;
        labels.EmailOptOutCheckboxLabel = Label.EmailOptOutCheckboxOCS;
        labels.EmailOptOutTextLabel = Label.EmailOptOutTextOCS;
        labels.EmailOptOutButtonLabel = Label.EmailOptOutButton;
        labels.PreferenceCentreSaveLabel = Label.PreferenceCentreSave;
        labels.PreferenceCentreRedirect = Label.PreferenceCentreRedirect;

        return JSON.serialize(labels);
    }

    //#endregion

    //#Region private classes

    /**
     * Helper class for the labels used by the lwc
     *
     * @author nts (rlopez)
     */
    public class AppLabels
    {
        String PreferenceCentreTitleLabel;
        String PreferenceCentreSubtitleLabel;
        String EmailOptOutCheckboxLabel;
        String EmailOptOutTextLabel;
        String EmailOptOutButtonLabel;
        String PreferenceCentreSaveLabel;
        String PreferenceCentreRedirect;

        public AppLabels()
        {
            PreferenceCentreTitleLabel = 'label not found';
            PreferenceCentreSubtitleLabel = 'label not found';
            EmailOptOutCheckboxLabel = 'label not found';
            EmailOptOutTextLabel = 'label not found';
            EmailOptOutButtonLabel = 'label not found';
            PreferenceCentreSaveLabel = 'label not found';
            PreferenceCentreRedirect = '';
        }
    }
    //#endregion

    public class UploadCaseDocumentationControllerException extends Exception
    {}
}