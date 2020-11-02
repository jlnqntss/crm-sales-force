@isTest(SeeAllData = false)
public with sharing class Test_PreferenceCentreProcessController
{
    @isTest
    static void doUpdate_testNull()
    {
        Contact c = new Contact();
        c.LastName = null;

        Test.startTest();
        PreferenceCentreProcessController.doUpdate(c);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorRecords.size() );
    }

    @isTest
    static void doInsert_testNull()
    {
        List<CampaignMember> members = new List<CampaignMember>();
        CampaignMember c = new CampaignMember();
        c.CampaignId = null;
        members.add(c);
        Test.startTest();
        PreferenceCentreProcessController.doInsert(members);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorRecords.size() );
    }

    @isTest
    static void doDelete_testNull()
    {
        List<CampaignMember> members = new List<CampaignMember>();
        CampaignMember c = new CampaignMember();
        c.CampaignId = null;
        members.add(c);

        Test.startTest();
        PreferenceCentreProcessController.doDelete(members);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals(1, errorRecords.size() );
    }
}