@isTest
public with sharing class ViewAsModalGeneratePlanControllerTest {
    
    @isTest 
    static void testGetSDMUsersList() {

        Test.startTest();
        List<User> sdmUserList = ViewAsModalGeneratePlanController.getSDMUsersList();
        Test.stopTest();

        System.assertEquals(false, sdmUserList.isEmpty(), 'Debe encontrar usuarios SDM');
    }
}