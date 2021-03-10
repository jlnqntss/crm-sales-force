public without sharing class ContentVersionUtil
{
    public static Map<String, Case> hashToCaseMap;
    public static List<ContentDocumentLink> contentDocumentLinksToCreate;

    /**
     * Recupera todos los casos relacionados con los ContentVersion que se están insertando.
     * Sí el registro de ContentVersion tiene valor en el campo Guest_Record_fileupload__c, buscamos
     * el caso que tenga el mismo valor en el campo DocumentationHashId__c y así poder crear la relación
     * entre ambos.
     *
     * @author rlopez
     * @date 09/03/2021
     */
    public static void getRelatedCasesByHash(List<ContentVersion> newList, Map<Id, ContentVersion> oldMap)
    {
        //Inicializamos variables
        hashToCaseMap = new Map<String, Case>();
        contentDocumentLinksToCreate = new List<ContentDocumentLink>();

        //Solo continuamos si se tratan de nuevos ContentVersion
        if(newList != null && !newList.isEmpty() && oldMap == null)
        {
            //Creamos un mapa con el hash (generado al solicitar la información) y su ContentVersion
            Map<String, ContentVersion> hashToContentVersion = new Map<String, ContentVersion>();
            for(ContentVersion version: newList)
            {
                if( String.isNotBlank(version.Guest_Record_fileupload__c) )
                {
                    hashToContentVersion.put(version.Guest_Record_fileupload__c, version);
                }
            }

            if( !hashToContentVersion.isEmpty() )
            {
                //Recuperamos los casos relacionados con ese hash para crear el ContentDocumentLink y relacionar el documento con el caso
                List<Case> relatedCases = [SELECT Id, OwnerId, DocumentationHashId__c FROM Case WHERE DocumentationHashId__c IN: hashToContentVersion.keySet()];
                if( !relatedCases.isEmpty() )
                {
                    for(Case related: relatedCases)
                    {
                        hashToCaseMap.put(related.DocumentationHashId__c, related);
                    }
                }
            }
        }
    }

    /**
     * Si el registro de ContentVersion tiene valor en Guest_Record_fileupload__c y además
     * hemos recuperado previamente un caso con ese mismo valor en DocumentationHashId__c,
     * generamos un nuevo ContentDocumentLink para relacionar el documento con el caso
     *
     * @author rlopez
     * @date 09/03/2021
     */
    public static void generateContentDocumentLinks(List<ContentVersion> newList, Map<Id, ContentVersion> oldMap)
    {
        if(newList != null && !newList.isEmpty() && oldMap == null)
        {
            for(ContentVersion version: newList)
            {
                if( hashToCaseMap.containsKey(version.Guest_Record_fileupload__c) )
                {
                    contentDocumentLinksToCreate.add(
                        new ContentDocumentLink(
                            LinkedEntityId = hashToCaseMap.get(version.Guest_Record_fileupload__c).Id,
                            ContentDocumentId = version.ContentDocumentId
                            )
                        );
                }
            }
        }
    }

    /**
     * Insertamos los registros de ContentDocumentLink generados en pasos anteriores
     *
     * @author rlopez
     * @date 09/03/2021
     */
    public static void insertRelatedRecords()
    {
        if( contentDocumentLinksToCreate != null && !contentDocumentLinksToCreate.isEmpty() )
        {
            try
            {
                insert contentDocumentLinksToCreate;
            }
            catch (Exception ex)
            {
                ErrorLogUtil.commitError(ex,'ContentVersionUtil', 'insertRelatedRecords');
            }
        }
    }
}