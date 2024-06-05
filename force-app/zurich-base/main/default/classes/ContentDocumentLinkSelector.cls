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
     * SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.OwnerId, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.VersionDataUrl 
                                                    FROM ContentDocumentLink 
                                                    WHERE LinkedEntityId = :linkedEntityId 
                                                    AND ContentDocument.Owner.Contact.AccountId = :intermediaryId 
                                                    ORDER BY ContentDocument.CreatedDate DESC
     *                 
     * @return Lista de content document link de un registro para el usuario zrm nominal
     * @author dmunoz
     * @date 16/05/2024
     */
    public List<ContentDocumentLink> getZRMContentDocumentByLinkedEntity(String linkedEntityId, String intermediaryId) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();

        if (linkedEntityId != null && String.isNotEmpty(linkedEntityId) && intermediaryId != null && String.isNotEmpty(intermediaryId)) {

            Set<String> fieldsToRetrieve = new Set<String>
            {
                 'ContentDocument.Id',
                 'ContentDocument.Title',
                 'ContentDocument.OwnerId',
                 'ContentDocument.FileExtension',
                 'ContentDocument.LatestPublishedVersion.VersionDataUrl'
            };

            this.baseQuery.selectFields(fieldsToRetrieve);
            
            this.baseQuery.addConditionEq(ContentDocumentLink.LinkedEntityId, linkedEntityId)
            .addConditionEq('ContentDocument.Owner.Contact.AccountId', intermediaryId)
            .orderBy('ContentDocument.CreatedDate', 'DESC'); 

            result = (List<ContentDocumentLink>) this.baseQuery.run();
        }

        return result;
    }

    /**  Obtener los documentos creados por una agrupacion    
     * SELECT ContentDocument.Id, ContentDocument.OwnerId, ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.VersionDataUrl 
                                                    FROM ContentDocumentLink 
                                                    WHERE LinkedEntityId = :linkedEntityId 
                                                    AND ContentDocument.Owner.Contact.Account.IntermediaryGroup__c = :intermediaryGroupId 
                                                    ORDER BY ContentDocument.CreatedDate DESC
     * 
     *          
     * @return Lista de content document link de un registro para el usuario zrm AGR
     * @author dmunoz
     * @date 16/05/2024
     */
    public List<ContentDocumentLink> getZRMAGRContentDocumentByLinkedEntity(String linkedEntityId, String intermediaryGroupId) {
        List<ContentDocumentLink> result = new List<ContentDocumentLink>();

        if (linkedEntityId != null && String.isNotEmpty(linkedEntityId) && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId)) {

            Set<String> fieldsToRetrieve = new Set<String>
            {
                 'ContentDocument.Id',
                 'ContentDocument.Title',
                 'ContentDocument.OwnerId',
                 'ContentDocument.FileExtension',
                 'ContentDocument.LatestPublishedVersion.VersionDataUrl'
            };

            this.baseQuery.selectFields(fieldsToRetrieve);
            
            this.baseQuery.addConditionEq(ContentDocumentLink.LinkedEntityId, linkedEntityId)
            .addConditionEq('ContentDocument.Owner.Contact.Account.IntermediaryGroup__c', intermediaryGroupId)
            .orderBy('ContentDocument.CreatedDate', 'DESC'); 

            result = (List<ContentDocumentLink>) this.baseQuery.run();
        }

        return result;
    }
}