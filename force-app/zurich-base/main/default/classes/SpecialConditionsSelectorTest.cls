@IsTest
public with sharing class SpecialConditionsSelectorTest {
    
    @IsTest
    static void test_findAgreements_OK()
    {
        List<Special_Condition__c> agreements = new List<Special_Condition__c>();
        Special_Condition__c agreement = new Special_Condition__c();
        agreement.TerritorialDirection__c =  'DT Madrid';
        agreement.Type__c = 'Agreement';
        agreements.add(agreement);
        insert(agreements);

        List<Special_Condition__c> retrievedAgreements = new SpecialConditionsSelector().findAgreements('235', 'DT Madrid');
        system.assertEquals(agreements.size(), retrievedAgreements.size());
    }
}
