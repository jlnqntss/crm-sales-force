public without sharing class ContentVersionUtil
{
    public static Map<String, Case> hashToCaseMap;
    public static List<ContentDocumentLink> contentDocumentLinksToCreate;
    public static List<Task> tasksToCreate;
    public static List<Case> casesToUpdate;

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
        tasksToCreate = new List<Task>();
        casesToUpdate = new List<Case>();

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
                List<Case> relatedCases = [SELECT Id, Status, DocumentationHashId__c FROM Case WHERE DocumentationHashId__c IN: hashToContentVersion.keySet()];
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

                    Case relatedCase = hashToCaseMap.get(version.Guest_Record_fileupload__c);
                    relatedCase.Status = 'Respondido';
                    relatedCase.PendingBy__c = null;
                    casesToUpdate.add(relatedCase);

                    tasksToCreate.add(
                        new Task(
                            RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Activity').getRecordTypeId(),
                            Priority = 'Normal',
                            Status = 'Cerrada',
                            Subject = Label.documentacionAnadida,
                            Description = 'Archivo añadido: ' + Url.getOrgDomainUrl().toExternalForm() + '/' + version.ContentDocumentId,
                            Type = 'Other',
                            WhatId = hashToCaseMap.get(version.Guest_Record_fileupload__c).Id
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
        try
        {
            if( tasksToCreate != null && !tasksToCreate.isEmpty() )
            {
                insert tasksToCreate;
            }

            if( casesToUpdate != null && !casesToUpdate.isEmpty() )
            {
                update casesToUpdate;
            }

            if( contentDocumentLinksToCreate != null && !contentDocumentLinksToCreate.isEmpty() )
            {
                insert contentDocumentLinksToCreate;
            }
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ex, 'ContentVersionUtil', 'insertRelatedRecords');
        }
    }
}