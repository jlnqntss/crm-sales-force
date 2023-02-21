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
}