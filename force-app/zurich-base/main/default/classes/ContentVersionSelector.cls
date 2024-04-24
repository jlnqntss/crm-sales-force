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