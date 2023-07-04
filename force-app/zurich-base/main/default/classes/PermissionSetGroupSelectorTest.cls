@isTest
public with sharing class PermissionSetGroupSelectorTest {
    
    @isTest
    static void testFindPermissionSetGroupFromDeveloperName() {

        List<String> developerName = new List<String>();
        developerName.add('Ventas_Advisor');

        Map<Id, PermissionSetGroup> result = new PermissionSetGroupSelector().findPermissionSetGroupFromDeveloperName(developerName);

        System.assertEquals(true, !result.isEmpty(), 'Debe encontrar registros');
    }


    @isTest
    static void testFindUserPermissionSetGroupFromUserId() {
        

        List<PermissionSetAssignment> permissionSetQuery = new List<PermissionSetAssignment>([SELECT Id, AssigneeId FROM PermissionSetAssignment
                        WHERE PermissionSetGroupId != null AND AssigneeId != null LIMIT 1]);

        if (!permissionSetQuery.isEmpty()) {
            List<PermissionSetAssignment> result = new PermissionSetGroupSelector().findUserPermissionSetGroupFromUserId(permissionSetQuery.get(0).AssigneeId);
    
            System.assertEquals(true, !result.isEmpty(), 'Debe encontrar registros');
        }
    }

    @isTest
    static void testFindUserPermissionSetGroupFromUserIdNotInMetadata() {
        List<PermissionSetAssignment> permissionSetQuery = new List<PermissionSetAssignment>([SELECT Id, AssigneeId FROM PermissionSetAssignment
                        WHERE PermissionSetGroupId != null AND AssigneeId != null LIMIT 1]);

        if (!permissionSetQuery.isEmpty()) {
            List<PermissionSetAssignment> result = new PermissionSetGroupSelector().findUserPermissionSetGroupFromUserIdNotInMetadata(permissionSetQuery.get(0).AssigneeId, new List<String>());
    
            System.assertEquals(true, !result.isEmpty(), 'Debe encontrar registros');
        }
    }
}