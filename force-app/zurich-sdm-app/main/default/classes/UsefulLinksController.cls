/**
 * @description       : Clase controlador del componente 'usefulLinks'.
 * @author            : amiranda
 * @date              : 15-12-2022
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   13-12-2022   amiranda   Initial Version
 **/
public with sharing class UsefulLinksController
{
    private static final String CLASS_NAME = 'UsefulLinksController';
    private static final String FILE_TYPE = 'LINK';


    /**
     * @description Método que recupera el Id de la librería en base al nombre de la misma.
     * @author amiranda | 15-12-2022
     * @param String contentWorkspaceName Nombre de la librería
     * @return String Id de la librería
     **/
    @AuraEnabled
    public static String getLibraryId(String contentWorkspaceName)
    {
        String libraryId;

        try
        {
            libraryId = [SELECT Id FROM ContentWorkspace WHERE Name =: contentWorkspaceName LIMIT 1].Id;
        }
        catch (Exception ex)
        {
            ErrorLogUtil.commitError(ex, CLASS_NAME);
            throw new AuraHandledException('');
        }

        return libraryId;
    }

    /**
     * @description Método que recupera archivos de tipo 'LINK' en una biblioteca determinada.
     * @author amiranda
     * @date 13-12-2022
     * @param Id contentWorkspaceId Id de la librería
     * @param Id userId Id de usuario
     * @param Integer recordsLimit Límite de registros
     * @return List<ContentVersion> Lista con los archivos de tipo 'LINK' recuperados
     * @see usefulLinks.js
     **/
    @Auraenabled
    public static List<ContentVersion> getLinks(Id contentWorkspaceId, Integer recordsLimit)
    {
        List <ContentVersion> links = new List<ContentVersion>();

        // Se comprueba que hay documentos en la librería
        List<ContentWorkspaceDoc> cwDocs = [SELECT ContentDocumentId FROM ContentWorkspaceDoc
                                            WHERE ContentWorkspaceId =: contentWorkspaceId];

        if( !cwDocs.isEmpty() )
        {
            // Se comprueba que hay algún documento de tipo LINK
            Set<Id> contentDocumentIds = new Set<Id>();

            for (ContentWorkspaceDoc cwDoc : cwDocs)
            {
                contentDocumentIds.add(cwDoc.ContentDocumentId);
            }

            List<ContentVersion> contentVersion = [SELECT ContentUrl, Title, ContentDocumentId
                                                   FROM ContentVersion
                                                   WHERE ContentDocumentId IN :contentDocumentIds
                                                   AND FileType =: FILE_TYPE AND IsLatest = true
                                                                                            ORDER BY Title ASC
                                                                                            LIMIT :recordsLimit];

            links.addAll(contentVersion);
        }

        return links;
    }

    /**
     * @description Método que recupera el tipo de permisos de un usuario en una biblioteca dada.
     * @author amiranda
     * @date 13-12-2022
     * @param Id contentWorkspaceId Biblioteca sobre la que comprobar el tipo de permisos del usuario
     * @param Id userId Id de usuario
     * @return String Tipo de permiso
     * @see usefulLinks.js
     **/
    @AuraEnabled
    public static String getContentWorkspacePermissionType(Id contentWorkspaceId, Id userId)
    {
        String contentWorkspacePermissionType;

        List<GroupMember> groupMembers = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId =: userId];

        // Conjunto 'polimórfico'. Almacena el Id del usuario y los Ids de los grupos en los que es miembro
        Set<Id> memberIds = new Set<Id> {userId};

        for (GroupMember groupMember : groupMembers)
        {
            memberIds.add(groupMember.GroupId);
        }

        // Se recupera la representación de un miembro en una biblioteca de 'Archivos' de Salesforce
        List<ContentWorkspaceMember> contentWorkspaceMembers = [SELECT ContentWorkspacePermissionId FROM ContentWorkspaceMember
                                                                WHERE ContentWorkspaceId =: contentWorkspaceId AND MemberId =: memberIds];

        // Se comprueba el tipo de permiso que tiene el miembro sobre la biblioteca
        if ( !contentWorkspaceMembers.isEmpty() )
        {
            ContentWorkspacePermission contentWorkspacePermission = [SELECT Type FROM ContentWorkspacePermission
                                                                     WHERE Id =: contentWorkspaceMembers.get(0).ContentWorkspacePermissionId];

            contentWorkspacePermissionType = contentWorkspacePermission.Type;
        }

        return contentWorkspacePermissionType;
    }
}