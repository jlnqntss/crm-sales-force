/**
 * @description       : Clase selectora del sobject CallCenter
 * @author            : dmunoz
 * @group             : 
 * @last modified on  : 12/06/2023
 * @last modified by  : dmunoz
**/
public with sharing class PermissionSetGroupSelector {
    
    /**
     * Método que recupera los permission set group cuyo nombre coincida con el developername
     * 
     * @author dmunoz
     * @date 12/06/2023
     * 
     * @param {String developerName} nombre del permission set group a filtrar
     */
    public Map<Id, PermissionSetGroup> findPermissionSetGroupFromDeveloperName(List<String> developerName) {

        Map<Id, PermissionSetGroup> result = new Map<Id, PermissionSetGroup>();
        if (developerName != null && !developerName.isEmpty()) {
            result = new Map<Id, PermissionSetGroup>([            
                    SELECT Id FROM PermissionSetGroup WHERE DeveloperName IN :developerName
            ]);

        }
        return result;
    }


    /**
     * Método que recupera los permission set group asignados al usuario
     * 
     * @author dmunoz
     * @date 12/06/2023
     * 
     * @param {String userId} User Id
     */
    public List<PermissionSetAssignment> findUserPermissionSetGroupFromUserId(Id userId) {

        List<PermissionSetAssignment> result = new List<PermissionSetAssignment>();
        if (userId != null) {
            result = new List<PermissionSetAssignment>([
                        SELECT Id, PermissionSetGroupId FROM PermissionSetAssignment
                        WHERE PermissionSetGroupId != null AND AssigneeId = :userId
                    ]);

        }
        return result;
    }

    /**
     * Método que recupera los permission set group asignados al usuario los cuales se han de borrar
     * 
     * @author dmunoz
     * @date 12/06/2023
     * 
     * @param {String userId} User Id
     */
    public List<PermissionSetAssignment> findUserPermissionSetGroupFromUserIdNotInMetadata(Id userId, List<Id> mtdPSGIds) {

        List<PermissionSetAssignment> result = new List<PermissionSetAssignment>();
        if (userId != null) {
            result = new List<PermissionSetAssignment>([
                        SELECT Id, PermissionSetGroupId FROM PermissionSetAssignment
                        WHERE PermissionSetGroupId != null 
                        AND AssigneeId = :userId
                        AND PermissionSetGroupId NOT IN :mtdPSGIds
                    ]);

        }
        return result;
    }
}