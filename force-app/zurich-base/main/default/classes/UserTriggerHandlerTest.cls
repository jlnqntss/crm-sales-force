/**
 * @description       : Clase test que prueba el trigger UserTrigger que desmarca el campo Active Agent en el caso que se dé de baja el usuario
 * @author            : lgonzalez
 * @group             : Seidor
 * @last modified on  : 05-24-2023
 * @last modified by  : lgonzalez
**/
@isTest
private without sharing class UserTriggerHandlerTest {
    @testSetup
    public static void userSetup(){
        // Create test user
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'Last Name',
            Email = 'Unotestpruega@gmail.com',
            Username = 'testUserUNO@Email.com',
            CompanyName = 'testCompany',
            Title = 'title',
            Alias = 'testt',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true,
            ActiveAgent__c = true
        );
        insert testUser;
    }
    public static void updateUser() {
        User testUserToUpdate = [SELECT Id, IsActive FROM User WHERE Email =: 'Unotestpruega@gmail.com' WITH USER_MODE LIMIT 1];
        testUserToUpdate.IsActive = false;
        testUserToUpdate.ActiveAgent__c = false;
        update testUserToUpdate;
    }
    
    @isTest
    static void testUserDeactivation() {
        //llamamos al método updateUser
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            updateUser();
        }
        Test.stopTest();
    }
}