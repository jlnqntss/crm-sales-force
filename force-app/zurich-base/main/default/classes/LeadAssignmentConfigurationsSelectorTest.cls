@IsTest
public with sharing class LeadAssignmentConfigurationsSelectorTest {
    @TestSetup
    public static void createScenario(){
        TestDataFactory.insertAccountLeadAssignmentCriterias();
    }

    @IsTest
    static void test_getLeadAssignmentConfiguratioByRT(){
        Test.startTest();
        LeadAssignmentConfigurationsSelector leadAssignmentConfigurationsSelector = new LeadAssignmentConfigurationsSelector(); 

        List<LeadAssignmentConfiguration__c> forumOrigins = leadAssignmentConfigurationsSelector.getForumOriginAssignments();

        List<LeadAssignmentConfiguration__c> languages = leadAssignmentConfigurationsSelector.getLanguageAssignments();

        List<LeadAssignmentConfiguration__c> municipalities = leadAssignmentConfigurationsSelector.getMunicipalityAssignments();

        List<LeadAssignmentConfiguration__c> provinces = leadAssignmentConfigurationsSelector.getProvinceAssignments();
        Test.stopTest();
    }
}