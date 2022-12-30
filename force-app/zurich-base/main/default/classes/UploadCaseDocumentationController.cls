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
     * Method to delete ContentDocument using ContentVersionId
     * @author jjuaristi
     * @date 26/05/2020
     * @param ContentVersion Id so we can query and get ContentDocumentId
     * @throws AuraHandledException
     */
    @AuraEnabled
    public static void deleteDocumentWithVersion (String id)
    {
        try{
            ContentVersion version = [SELECT ContentDocumentId from ContentVersion where Id = :id LIMIT 1];
            ContentDocument record = new ContentDocument();
            record.Id = version.ContentDocumentId;
            delete record;
        }catch(Exception e)
        {
            throw new AuraHandledException('Unable to delete');
        }
    }

    public class UploadCaseDocumentationControllerException extends Exception
    {}
}