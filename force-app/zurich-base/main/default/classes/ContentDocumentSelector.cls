/**
 * @description       : Nuevo selector para obtener información sobre Content Document
 * @author            : lrodriguez
 * @group             :
 * @last modified on  : 09-07-2024
 **/
public with sharing class ContentDocumentSelector extends RecordsSelector {

    //#region Contructores

    public ContentDocumentSelector()
    {
        super(ContentDocument.getSObjectType());
    }
    
    /** Obtener los documentos creados por un mediador
     * 
     * [SELECT Id, Title, FileExtension, LatestPublishedVersion.VersionData
                     FROM ContentDocument
                            WHERE Title = 'HEGEO-CLASIFICACION'AND Id IN: listIds]
     *               
     * @return Lista de content document con titulo HEGEO-CLASIFICACION y relacionada con id Content Document Link
     * @author lrodriguez
     * @date 09/07/2024
     */
    public List<ContentDocument> getContentDocumentHegeoClasificacion(String titleHegeo, List<Id> idsRelated) 
    {
        List<ContentDocument> result = new List<ContentDocument>();

        if (!idsRelated.isEmpty()) 
        {
            Set<String> fieldsToRetrieve = new Set<String>
            {
                 'ContentDocument.Id',
                 'ContentDocument.Title',
                 'ContentDocument.FileExtension',
                 'ContentDocument.LatestPublishedVersion.VersionData'
            };

            this.baseQuery.selectFields(fieldsToRetrieve);
            
            this.baseQuery.addConditionIn(ContentDocumentLink.Id,idsRelated)
            .addConditionEq(ContentDocument.Title, titleHegeo);

            result = (List<ContentDocument>) this.baseQuery.run();
            return result;
        }
        else
        {
            return new List<ContentDocument>();
        }
    }
}