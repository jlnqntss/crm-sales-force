@isTest
private with sharing class PoliciesSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 1);
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 10);
        insert policies;
    }

    @isTest
    static void test_selectByHolderAndNumber_matchedRecords()
    {
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c, InfoPolicyNumber__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'List should NOT be empty');

        Set<String> policyNumbers = new Set<String>();
        for(Policy__c policy: policies)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
        }

        Test.startTest();

        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.PolicyHolder__c
            }
        );

        List<Policy__c> matchedRecords = policiesSelector.selectByHolderAndNumber(policies.get(0).PolicyHolder__c, policyNumbers);

        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Policy__c matched: matchedRecords)
        {
            System.assertEquals(true, matched.PolicyHolder__c == policies.get(0).PolicyHolder__c, 'PolicyHolder should be the same');
        }
    }

    @isTest
    static void test_selectByHolderAndNumber_emptySet_matchedRecords()
    {
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'List should NOT be empty');

        Set<String> policyNumbers = new Set<String>();
        Test.startTest();
        List<Policy__c> matchedRecords = new PoliciesSelector().selectByHolderAndNumber(policies.get(0).PolicyHolder__c, policyNumbers);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByHolderAndNumber_nullSet_matchedRecords()
    {
        List<Policy__c> policies = [SELECT Id, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'List should NOT be empty');

        Test.startTest();
        List<Policy__c> matchedRecords = new PoliciesSelector().selectByHolderAndNumber(policies.get(0).PolicyHolder__c, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByOpportunityName_matchedRecords()
    {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
        System.assertEquals(false, opportunities.isEmpty(), 'List should NOT be empty');

        Set<Id> opportunityIds = new Set<Id>();
        for(Opportunity opportunity: opportunities)
        {
            opportunityIds.add(opportunity.Id);
        }

        Test.startTest();

        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.OpportunityName__c
            }
        );

        List<Policy__c> matchedRecords = policiesSelector.selectByOpportunityName(opportunityIds);

        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Policy__c matched: matchedRecords)
        {
            System.assertEquals(true, opportunityIds.contains(matched.OpportunityName__c), 'Set should contain the OpportunityName__c');
        }
    }

    @IsTest
    static void test_selectByHolder_selectByNumber()
    {
        Schema.RecordTypeInfo accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer');
        Id rtId = accountRecordTypeInfo.getRecordTypeId();
        Account customer = [SELECT Id FROM Account WHERE RecordTypeId = : rtId LIMIT 1];
        System.assertEquals(true, customer != null, '[0] Customer should NOT be null');

        // Comprobar obtiene pólizas por tomador
        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.PolicyHolder__c,
                Policy__c.EndDate__c,
                Policy__c.InfoPolicyNumber__c
            }
        );

        List<Policy__c> policies = policiesSelector.selectByHolder(customer.Id);

        System.assertEquals(true, !policies.isEmpty() && policies.size() > 1, '[1] Policies should NOT be empty and greater than one');

        // Actualizar la fecha expiración de una póliza y comprobar que NO recupera esa póliza
        Integer policiesCount = policies.size();
        Policy__c policyToUpdate = policies.get(0);
        // policyToUpdate.EndDate__c = Date.today().addDays(-1);
        policyToUpdate.PolicyStatus__c = 'P';
        update policyToUpdate;

        // Comprobar obtiene pólizas por tomador ACTIVAS
        List<Policy__c> policiesByHolder = new PoliciesSelector().selectByHolder(customer.Id);
        System.assertEquals(true, !policiesByHolder.isEmpty() && policiesByHolder.size() == policiesCount - 1, '[2] Policies should NOT be empty');

        // Comprobar obtiene pólizas por num póliza
        List<Policy__c> policiesByNumber = new PoliciesSelector().selectByNumber(policies.get(0).InfoPolicyNumber__c);
        System.assertEquals(true, !policiesByNumber.isEmpty() && policiesByNumber.size() == 1, '[2] Policies should be just one');
    }

    @IsTest
    static void test_selectByHolder_setScope()
    {
        Schema.RecordTypeInfo accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer');
        Id rtId = accountRecordTypeInfo.getRecordTypeId();
        Account customer = [SELECT Id FROM Account WHERE RecordTypeId = : rtId LIMIT 1];
        System.assertEquals(true, customer != null, '[0] Customer should NOT be null');

        // Comprobar obtiene pólizas por tomador
        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.PolicyHolder__c,
                Policy__c.EndDate__c,
                Policy__c.InfoPolicyNumber__c
            }
        );

        List<Policy__c> policies = policiesSelector.selectByHolder(customer.Id);

        System.assertEquals(true, !policies.isEmpty() && policies.size() > 1, '[1] Policies should NOT be empty and greater than one');

        // Actualizar la fecha expiración de una póliza y comprobar que NO recupera esa póliza
        Integer policiesCount = policies.size();
        Policy__c policyToUpdate = policies.get(0);
        policyToUpdate.EndDate__c = Date.today().addDays(-1);
        policyToUpdate.Scope__c = RecordsSelector.Scope.Z.name();
        policyToUpdate.InfoPolicyNumber__c = '00111222333444';
        update policyToUpdate;

        // Comprobar obtiene pólizas por tomador ACTIVAS
        policiesSelector = new PoliciesSelector();
        policiesSelector.setScope(RecordsSelector.Scope.Z);
        List<Policy__c> policiesByNumber = policiesSelector.selectByNumber('111222333444');
        System.assertEquals(true, !policiesByNumber.isEmpty() && policiesByNumber.size() == 1, '[2] Policies should be just one');

    }

    @IsTest
    static void test_selectByHolder_setLegalEntity()
    {
        Schema.RecordTypeInfo accountRecordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer');
        Id rtId = accountRecordTypeInfo.getRecordTypeId();
        Account customer = [SELECT Id FROM Account WHERE RecordTypeId = : rtId LIMIT 1];
        System.assertEquals(true, customer != null, '[0] Customer should NOT be null');

        // Comprobar obtiene pólizas por tomador
        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.PolicyHolder__c,
                Policy__c.EndDate__c,
                Policy__c.InfoPolicyNumber__c
            }
        );

        List<Policy__c> policies = policiesSelector.selectByHolder(customer.Id);

        System.assertEquals(true, !policies.isEmpty() && policies.size() > 1, '[1] Policies should NOT be empty and greater than one');

        // Actualizar la fecha expiración de una póliza y comprobar que NO recupera esa póliza
        Integer policiesCount = policies.size();
        Policy__c policyToUpdate = policies.get(0);
        policyToUpdate.EndDate__c = Date.today().addDays(-1);
        policyToUpdate.LegalEntity__c = '001';
        policyToUpdate.InfoPolicyNumber__c = '00111222333444';
        update policyToUpdate;

        // Comprobar obtiene pólizas por tomador ACTIVAS
        policiesSelector = new PoliciesSelector();
        policiesSelector.setLegalEntity(RecordsSelector.LegalEntity.GI);
        List<Policy__c> policiesByNumber = policiesSelector.selectByNumber('111222333444');
        System.assertEquals(true, !policiesByNumber.isEmpty() && policiesByNumber.size() == 1, '[2] Policies should be just one');

    }



    @isTest
    static void test_selectByInfoPolicyNumberAndNationalId_matchedRecords()
    {
        List<Policy__c> policies = [SELECT Id, PolicyHolder__r.NationalId__c, InfoPolicyNumber__c FROM Policy__c ORDER BY PolicyHolder__r.NationalId__c];
        System.assertEquals(false, policies.isEmpty(), 'List should NOT be empty');

        List<String> policyNumbers = new List<String>();
        List<String> nationalIds = new List<String>();
        for(Policy__c policy: policies)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
            nationalIds.add(policy.PolicyHolder__r.NationalId__c);
        }

        Test.startTest();

        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Policy__c.Id, 
                Policy__c.PolicyHolder__c
            }
        );

        List<Policy__c> matchedRecords = policiesSelector.selectByInfoPolicyNumberAndNationalId(nationalIds, policyNumbers);

        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
        for (integer i = 0; i<matchedRecords.size();i++)
        {
            System.assertEquals(true, matchedRecords.get(i).PolicyHolder__c == policies.get(i).PolicyHolder__c, 'PolicyHolder should be the same');
        }
    }

    @isTest
    static void test_selectByInfoPolicyNumberAndNationalId_emptySet_matchedRecords()
    {
        List<Policy__c> policies = [SELECT Id, InfoPolicyNumber__c, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'List should NOT be empty');

        List<String> policyNumbers = new List<String>();
        List<String> nationalIds = new List<String>();
        for(Policy__c policy: policies)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
        }

        Test.startTest();
        List<Policy__c> matchedRecords = new PoliciesSelector().selectByInfoPolicyNumberAndNationalId(nationalIds, policyNumbers);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
        
    }

    @isTest
    static void test_selectByInfoPolicyNumberAndNationalId_nullSet_matchedRecords()
    {
        List<Policy__c> policies = [SELECT Id, InfoPolicyNumber__c, PolicyHolder__c FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'List should NOT be empty');
        
        List<String> policyNumbers = new List<String>();
        for(Policy__c policy: policies)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
        }
        Test.startTest();
        List<Policy__c> matchedRecords = new PoliciesSelector().selectByInfoPolicyNumberAndNationalId(policyNumbers, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
        
    }

}