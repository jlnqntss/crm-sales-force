@isTest
public with sharing class ClaimsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 1);
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 1);
        insert policies;

        List<Asset> insuredObjects = TestDataFactory.generateInsuredObjectsForEachPolicy('Motor', policies, 1);
        insert insuredObjects;

        List<Claim__c> claims = TestDataFactory.generateClaimsForEachPolicyInsuredObject(policies, insuredObjects, 1);
        insert claims;
    }

    @IsTest
    static void test_selectByHolder()
    {
        // Comprobaciones iniciales
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), '[0] Policies list should NOT be empty');
        List<Asset> insuredObjects = [SELECT Id, Name, RegistrationNumber__c, AccountId, INFOInsuredObjectCode__c, RecordTypeId FROM Asset];
        System.assertEquals(false, insuredObjects.isEmpty(), '[1] Insured Objets list should NOT be empty');
        List<Claim__c> claims = [SELECT Id, Name, PolicyHolder__c, InsuredObject__c, INFOClaimNumber__c FROM Claim__c];
        System.assertEquals(false, claims.isEmpty(), '[2] Claims list should NOT be empty');

        Test.startTest();
        List<Claim__c> matchedRecords = new ClaimsSelector(new Set<String> {'Id'}).selectByHolder(policies.get(0).PolicyHolder__c);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), '[3] List should NOT be empty');
    }

    @IsTest
    static void test_selectByPlate()
    {
        // Comprobaciones iniciales
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), '[0] Policies list should NOT be empty');
        List<Asset> insuredObjects = [SELECT Id, Name, RegistrationNumber__c, AccountId, INFOInsuredObjectCode__c, RecordTypeId FROM Asset];
        System.assertEquals(false, insuredObjects.isEmpty(), '[1] Insured Objets list should NOT be empty');
        List<Claim__c> claims = [SELECT Id, Name, PolicyHolder__c, InsuredObject__c, INFOClaimNumber__c FROM Claim__c];
        System.assertEquals(false, claims.isEmpty(), '[2] Claims list should NOT be empty');

        Test.startTest();
        List<Claim__c> matchedRecords = new ClaimsSelector(new Set<String> {'Id', 'InsuredObject__r.RegistrationNumber__c', 'Status__c'}).selectByPlate(insuredObjects.get(0).RegistrationNumber__c);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), '[3] List should NOT be empty');
    }

    @IsTest
    static void test_selectByNumber()
    {
        // Comprobaciones iniciales
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), '[0] Policies list should NOT be empty');
        List<Asset> insuredObjects = [SELECT Id, Name, RegistrationNumber__c, AccountId, INFOInsuredObjectCode__c, RecordTypeId FROM Asset];
        System.assertEquals(false, insuredObjects.isEmpty(), '[1] Insured Objets list should NOT be empty');
        List<Claim__c> claims = [SELECT Id, Name, PolicyHolder__c, InsuredObject__c, INFOClaimNumber__c FROM Claim__c];
        System.assertEquals(false, claims.isEmpty(), '[2] Claims list should NOT be empty');

        Test.startTest();
        List<Claim__c> matchedRecords = new ClaimsSelector(new Set<String> {'Id', 'INFOClaimNumber__c'}).selectByNumber(claims.get(0).INFOClaimNumber__c);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), '[3] List should NOT be empty');
    }
}