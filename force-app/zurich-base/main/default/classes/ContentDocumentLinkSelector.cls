/**
 * @description       : Nuevo selector para obtener información de ficheros
 * @author            : dmunoz
 * @group             :
 * @last modified on  : 16-05-2024
 * @last modified by  : dmunoz
 **/
public with sharing class ContentDocumentLinkSelector extends RecordsSelector {

    //#region Contructores

    public ContentDocumentLinkSelector()
    {
        super( ContentDocumentLink.getSObjectType() );
    }
    
    /** Obtener los documentos creados por un mediador
     *                 
     * @return Lista de content document link de un registro para el usuario zrm nominal
     * @author dmunoz
     * @date 16/05/2024
     */
    public List<ContentDocumentLink> getZRMContentDocumentByLinkedEntity(String linkedEntityId, String intermediaryId) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();

        if (linkedEntityId != null && String.isNotEmpty(linkedEntityId) && intermediaryId != null && String.isNotEmpty(intermediaryId)) {


            result = new List<ContentDocumentLink>([SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.VersionDataUrl 
                                                    FROM ContentDocumentLink 
                                                    WHERE LinkedEntityId = :linkedEntityId 
                                                    AND ContentDocument.Owner.Contact.AccountId = :intermediaryId 
                                                    ORDER BY ContentDocument.CreatedDate DESC]);
        }

        return result;
    }

    /**  Obtener los documentos creados por una agrupacion             
     * @return Lista de content document link de un registro para el usuario zrm AGR
     * @author dmunoz
     * @date 16/05/2024
     */
    public List<ContentDocumentLink> getZRMAGRContentDocumentByLinkedEntity(String linkedEntityId, String intermediaryGroupId) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();

        if (linkedEntityId != null && String.isNotEmpty(linkedEntityId) && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId)) {
            result = new List<ContentDocumentLink>([SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.VersionDataUrl 
                                                    FROM ContentDocumentLink 
                                                    WHERE LinkedEntityId = :linkedEntityId 
                                                    AND ContentDocument.Owner.Contact.Account.IntermediaryGroup__c = :intermediaryGroupId 
                                                    ORDER BY ContentDocument.CreatedDate DESC]);
        }

        return result;
    }
}