/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 08-10-2021
 * @last modified by  : jjuaristi
**/
@isTest(SeeAllData=false)
public with sharing class TechnicalIncidenceControllerTest
{
    
    @TestSetup
    static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        for(Scope__c s : scopes)
        {
            s.TechnicalIncidence__c = true;
        }

        insert scopes;
    }

    @isTest
    static void test_getScope_ok()
    {
        test.startTest();
        Account account = [SELECT Id FROM Account LIMIT 1];
        Boolean check = TechnicalIncidenceController.getScope(account.Id);
        test.stopTest();
        System.assertEquals(true, check);
    }

    @isTest
    static void test_getScope_ko()
    {
        test.startTest();
        try{
            Boolean check = TechnicalIncidenceController.getScope(null);
        }catch(Exception e) {
            System.assertEquals(true, e.getTypeName().contains('AuraHandledException'), 'AuraException sent to the component');   
        }
        test.stopTest();        
    }
}
