/**
 * Clase selectora para los objetos ContentVersion
 *
 * @author mario.navarro@seidor.com
 * @date 23/04/2024
 */
public with sharing class ContentVersionSelector extends RecordsSelector
{
    public ContentVersionSelector()
    {
        super( ContentVersion.getSObjectType() );
    }

    /**
     * Obtiene los objetos ContentVersion a partir de la lista de identificadores de contentDocument proporcionados. Los campos
     * informados en el objeto son:
     * Title
     * PathOnClient
     * Description
     * ContentDocumentId
     * VersionData
     * FileExtension
     *
     * @author mario.navarro@seidor.com
     * @date 23/04/2024
     * @param contentDocumentIdList Set que debe contener una lista de contentDocumentId a obtener
     * @return NULL si la lista proporcionada es nula o esta vacia, en caso contrario, retorna la lista de objetos encontrados
     */
    public List<ContentVersion> findByContentDocumentId(Set<Id> contentDocumentIdList)
    {
        if ( contentDocumentIdList == null || contentDocumentIdList.isEmpty() )
        {
            return new List<ContentVersion>();
        }

        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            ContentVersion.Title,
            ContentVersion.PathOnClient,
            ContentVersion.Description,
            ContentVersion.ContentDocumentId,
            ContentVersion.VersionData,
            ContentVersion.FileExtension
        })
        .addConditionIn(ContentVersion.ContentDocumentId, contentDocumentIdList);

        return (List<ContentVersion>) this.baseQuery.run();
    }

}