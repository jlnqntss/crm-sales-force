@isTest
public with sharing class UserSelectorTest {
    
    @isTest
    static void getIdsValidUserTest_Ok() {

        List<User> userList = new List<User>([SELECT Id, Email FROM User WHERE IsActive = TRUE LIMIT 1]);

        if (!userList.isEmpty()) {
            List<String> emailList = new List<String>();

            for (User u: userList) {
                emailList.add(u.Email);
            }

            Test.startTest();

            List<User> userQuery = (new UserSelector()).getIdsValidUser(emailList);
            
            Test.stopTest();

            System.assertEquals(true, userQuery.size() != 0, 'Debe haber resultados');
        }
    }


    @isTest
    static void getIdsValidUserTest_KO() {
        List<String> emailList = new List<String>();

        Test.startTest();

        List<User> userQuery = (new UserSelector()).getIdsValidUser(emailList);
        
        Test.stopTest();
        
        System.assertEquals(0, userQuery.size(), 'No debe haber resultados');
        
    }

    @isTest
    static void getSDMUserId() {

        Test.startTest();
        List<User> userQuery = (new UserSelector()).getSDMUserId();        
        Test.stopTest();
        
        System.assertEquals(1, userQuery.size(), 'Debe encontrar uno');
        
    }
}