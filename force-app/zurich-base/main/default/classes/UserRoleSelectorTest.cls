@isTest
public with sharing class UserRoleSelectorTest {

    @isTest
    static void testFindUserRoleByDeveloperName() {

        List<UserRole> rolesQuery = new List<UserRole>([SELECT Id, DeveloperName FROM UserRole LIMIT 1]);

        if (!rolesQuery.isEmpty()) {
            UserRole result = new UserRoleSelector().findUserRoleByDeveloperName(rolesQuery.get(0).DeveloperName);

            System.assertEquals(true, result != null, 'Debe encontrar un resultado');
        }
    }
    
}