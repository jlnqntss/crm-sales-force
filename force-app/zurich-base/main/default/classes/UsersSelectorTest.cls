/**
 * @description       : Clase de test para la clase selectora del sobject User
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-20-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class UsersSelectorTest 
{
    @TestSetup
    public static void createScenario()
    {
        List<Profile> profileRN = [SELECT Id FROM Profile WHERE Name = 'SDM RN'];
        List<User> usersRN = TestDataFactory.generateUsersByProfile(profileRN[0].Id, 5);
       
        for( Integer i=0; i<usersRN.size(); i++ ) 
        {
            usersRN[i].FirstName = 'testUser';
        }

        insert usersRN;
    }

     /**
     * Test del metodo que recupera los Usuarios por un conjunto de ids dado
     */
    @isTest
    static void test_findById ()
    {
        List<User> usersBefore = [Select id from User where name like '%testUser%'];
        
        Test.startTest();
        List<User> usersAfter = new UsersSelector().findById(new Map<Id,User>(usersBefore).keySet() );
        Test.stopTest();

        // Comprobamos el resultado
        System.assertEquals(usersAfter.size(), usersBefore.size(), 'El número de usuarios antes y después debería ser el mismo');
    }

    @isTest
    static void test_getUsersByName() {
        Test.startTest();
        List<String> nombresList = new List<String>{'Integrator'};
        Map<Id, User> userMap = (new UsersSelector()).getUsersByName(nombresList);
        Test.stopTest();

        System.assertEquals(1, userMap.size(), 'Debe haber 1 usuario en el mapa');
    }


    @isTest
    static void testFindUserByEmail() {

        List<User> userQuery = new List<User>([SELECT Id, Email FROM User LIMIT 1]);

        if (!userQuery.isEmpty()) {
            User result = new UsersSelector().findUserByEmail(userQuery.get(0).Email);

            System.assertEquals(true, result != null, 'Debe encontrar resultado');

        }
    }

    @isTest
    static void testFindUserByCommunityNickname() {

        List<User> userQuery = new List<User>([SELECT Id, CommunityNickname FROM User WHERE IsActive = TRUE LIMIT 1]);

        if (!userQuery.isEmpty()) {
            User result = new UsersSelector().findUserByCommunityNickname(userQuery.get(0).CommunityNickname);

            System.assertEquals(true, result != null, 'Debe encontrar resultado');

        }
    }


    @isTest
    static void testGetLoginUserToUpdate() {

        List<User> userQuery = new List<User>([SELECT Id, CommunityNickname FROM User WHERE IsActive = TRUE LIMIT 1]);

        if (!userQuery.isEmpty()) {
            User result = new UsersSelector().getLoginUserToUpdate(userQuery.get(0).Id);

            System.assertEquals(true, result != null, 'Debe encontrar resultado');

        }
    }
}