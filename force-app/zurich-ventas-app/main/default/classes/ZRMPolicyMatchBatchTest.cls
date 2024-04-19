@isTest
public with sharing class ZRMPolicyMatchBatchTest {

    @TestSetup
    private static void makeData(){
        // insertar mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 2);
        intermediaryAccounts.get(0).INFOIntermediaryCode__c = '0000012345';
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        intermediaryAccounts.get(1).Name = 'MediadorTest2';
        intermediaryAccounts.get(1).INFOIntermediaryCode__c = '0000067890';
        insert intermediaryAccounts;

        // insertar cliente
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        // insertar oferta
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Legit Lead', Date.today().addDays(10), 1);

        for (Opportunity opp: opportunities) {
            opp.InfoQuoteNumber__c = null;
            opp.IntermediaryId__c = intermediaryAccounts.get(0).Id;
            opp.ProductBranch__c = '0000000001'; // auto
        }

        insert opportunities;
    }


    @isTest
    private static void testMatchClient() { 

        List<Account> intermediary = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Intermediary' AND Name = 'MediadorTest']);

        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Customer']);

        // Insertar producto
        List<Product2> products = TestDataFactory.generateProducts(1);
        for (Product2 product : products) {
            product.GroupDescription__c = '0000000001'; // auto
        }

        insert products;


        // Insertar pólizas
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        for (Policy__c pol: policies) {
            pol.IntermediaryId__c = intermediary.get(0).Id;
            pol.PotentialMatch__c = true;
            pol.ProductId__c = products.get(0).Id;
        }

        insert policies;

        Test.startTest();
        Database.executeBatch(new ZRMPolicyMatchBatch());
        Test.stopTest();

        Policy__c policyAfter = [SELECT Id, OpportunityName__c FROM Policy__c WHERE Id = :policies.get(0).Id];

        Assert.isTrue(String.isNotEmpty(policyAfter.OpportunityName__c), 'Se debe haber informado el valor OpportunityName__c de la poliza');
    }
}