@isTest
public with sharing class ZRMPolicyMatchBatchTest {

    @TestSetup
    private static void makeData(){
        
        List<Opportunity> oppsToInsert = new List<Opportunity>();

        // insertar mediadores
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance,'Intermediary', 1);
        intermediaryAccounts.get(0).INFOIntermediaryCode__c = '0000012345';
        intermediaryAccounts.get(0).Name = 'MediadorTest';
        insert intermediaryAccounts;

        // Insertar cliente
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        // Insertar contact point phone
        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 1);
        insert contactPointPhones;

        // insertar oferta cliente
        List<Opportunity> clientOpportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'Legit Lead', Date.today().addDays(10), 1);

        for (Opportunity opp: clientOpportunities) {
            opp.InfoQuoteNumber__c = null;
            opp.IntermediaryId__c = intermediaryAccounts.get(0).Id;
            opp.ProductBranch__c = '0000000001'; // auto
        }
        oppsToInsert.addAll(clientOpportunities);

        
        // Insertar Lead y le añadimos el teléfono
        List<Account> leadAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 1);
        
        for (Account lead: leadAccounts) {
            lead.phone = contactPointPhones.get(0).TelephoneNumber;
        }
        
        insert leadAccounts;


        // Insertar oferta Lead
        List<Opportunity> leadOpportunities = TestDataFactory.generateOpportunitiesForEachAccount(leadAccounts, 'Ventas', 'Legit Lead', Date.today().addDays(10), 2);

        for (Opportunity opp: leadOpportunities) {
            opp.InfoQuoteNumber__c = null;
            opp.IntermediaryId__c = intermediaryAccounts.get(0).Id;
            opp.ProductBranch__c = '0000000002'; // hogar
            opp.ZRM__c = true;
        }
        oppsToInsert.addAll(leadOpportunities);        
        
        
        
        
        // Inserts Finales-----------------------------------------------------
        insert oppsToInsert;
    }


    @isTest
    private static void testMatchClient() { 

        List<Account> intermediary = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Intermediary' AND Name = 'MediadorTest']);

        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Customer']);

        // Insertar producto
        List<Product2> products = TestDataFactory.generateProducts(1);
        for (Product2 product : products) {
            product.GroupCode__c = '0000000001'; // auto
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
    

    @isTest
    private static void testMatchLead() {

        List<Account> intermediary = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Intermediary' AND Name = 'MediadorTest']);

        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Customer']);        

        // Insertar producto
        List<Product2> products = TestDataFactory.generateProducts(1);
        for (Product2 product : products) {
            product.GroupCode__c = '0000000002'; // hogar
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

    @isTest
    private static void testNoMatchLead() {

        List<Account> intermediary = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Intermediary' AND Name = 'MediadorTest']);

        List<Account> accounts = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Customer']);

        List<Opportunity> oppToDelete = new List<Opportunity>([SELECT Id FROM Opportunity]);
        delete oppToDelete;

        // Insertar producto
        List<Product2> products = TestDataFactory.generateProducts(1);
        for (Product2 product : products) {
            product.GroupCode__c = '0000000002'; // hogar
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

        List<Account> leads = new List<Account>([SELECT Id FROM Account WHERE recordtype.DeveloperName = 'Lead']);
        Assert.isTrue(leads.size() == 0, 'Se debe haber eliminado todos los leads');

    }
}