/**
 * Class that is invoked by the LWC PreferenceCentreZE.
 *
 * The client (Personal Account -> Scope) arrives through the unsubscribe link to the site.
 *
 * From there, the client can subscribe or unsubscribe from
 * device and mobility communications or life communications.
 *
 * This Class started from a copy of PreferenceCentreController class developed for Klinc
 *
 * @author nts (agonzalezisasi)
 * @date 15/12/2020
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
            //cv.ContentDocumentId = contentDocumentId;
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
    public static Case getCase(Id caseId)
    {
        if(caseId != null)
        {
            Case caseFromUrl = [SELECT Id, Status FROM Case WHERE Id =: caseId];
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

    /**
     * This method get the labels for the lwc page.
     *
     * @author Enara Etxaniz
     */
    @AuraEnabled(cacheable=true)
    public static String getLabels()
    {
        System.debug('- - - - - UploadCaseDocumentationController.getLabels - - - - - ');

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
     * @author nts (agonzalezisasi)
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
}